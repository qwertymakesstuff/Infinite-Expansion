"""Made-up files for the custom emote converter's tests (installer/IXEmoteConvert.cs),
none of them the game's art:

  - IW7 animations in x64-zt's dump format (.xab), written and read here from
    the description of IW7's data streams in Greyhound's
    CoDXAnimTranslator::TranslateXAnim (the order of the streams, inline frame
    indices of long animations, 16-bit quaternions, min + size * key
    translations) and x64-zt's xanim_parts::dump (the order of the parts);
  - an IW7-like body model (.xmb) as x64-zt's xmodel::dump writes one: bone
    names, parent list (an offset back per bone), baseMat in model space;
    a small T-posed skeleton with IW7's bone names, Z up, facing +X, and every
    bone turned some odd way, so nothing depends on bones lining up with the
    axes;
  - FBX files, ASCII and binary (as Blender's io_scene_fbx reads them), of a
    humanoid rig with the bone names of the rig DanceMoves.fbx uses, Y up,
    facing -Z, A-posed, under a turned "Root" node, with pre-rotations and
    the ZXY rotation order, and a motion whose bone rotations are known.

Nothing here runs: the tests write these files and give them to the converter.
"""
import math
import random
import struct
import zlib

# ------------------------------------------------------------------ math


def qmul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return (aw * bx + ax * bw + ay * bz - az * by,
            aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw,
            aw * bw - ax * bx - ay * by - az * bz)


def qconj(q):
    return (-q[0], -q[1], -q[2], q[3])


def qnorm(q):
    n = math.sqrt(sum(c * c for c in q))
    return tuple(c / n for c in q)


def qaxis(axis, degrees):
    n = math.sqrt(sum(c * c for c in axis))
    s = math.sin(math.radians(degrees) / 2)
    return (axis[0] / n * s, axis[1] / n * s, axis[2] / n * s, math.cos(math.radians(degrees) / 2))


def qrot(q, v):
    p = qmul(qmul(q, (v[0], v[1], v[2], 0.0)), qconj(q))
    return (p[0], p[1], p[2])


def qangle(a, b):
    """The angle in degrees between two rotations."""
    d = abs(sum(x * y for x, y in zip(qnorm(a), qnorm(b))))
    return math.degrees(2 * math.acos(min(1.0, d)))


def qmat(q):
    """3x3 rotation matrix (rows) of a quaternion."""
    x, y, z, w = q
    return [[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
            [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
            [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]]


def mat_q(m):
    trace = m[0][0] + m[1][1] + m[2][2]
    if trace > 0:
        s = math.sqrt(trace + 1.0) * 2
        q = ((m[2][1] - m[1][2]) / s, (m[0][2] - m[2][0]) / s, (m[1][0] - m[0][1]) / s, 0.25 * s)
    elif m[0][0] > m[1][1] and m[0][0] > m[2][2]:
        s = math.sqrt(1.0 + m[0][0] - m[1][1] - m[2][2]) * 2
        q = (0.25 * s, (m[0][1] + m[1][0]) / s, (m[0][2] + m[2][0]) / s, (m[2][1] - m[1][2]) / s)
    elif m[1][1] > m[2][2]:
        s = math.sqrt(1.0 + m[1][1] - m[0][0] - m[2][2]) * 2
        q = ((m[0][1] + m[1][0]) / s, 0.25 * s, (m[1][2] + m[2][1]) / s, (m[0][2] - m[2][0]) / s)
    else:
        s = math.sqrt(1.0 + m[2][2] - m[0][0] - m[1][1]) * 2
        q = ((m[0][2] + m[2][0]) / s, (m[1][2] + m[2][1]) / s, 0.25 * s, (m[1][0] - m[0][1]) / s)
    return qnorm(q)


def mmul(a, b):
    return [[sum(a[r][k] * b[k][c] for k in range(3)) for c in range(3)] for r in range(3)]


def mT(a):
    return [[a[c][r] for c in range(3)] for r in range(3)]


def euler_matrix(deg, order):
    """FBX/Blender Euler matrix, the first letter applied first: XYZ = Rz Ry Rx."""
    def axis(i, d):
        c, s = math.cos(math.radians(d)), math.sin(math.radians(d))
        if i == 0:
            return [[1, 0, 0], [0, c, -s], [0, s, c]]
        if i == 1:
            return [[c, 0, s], [0, 1, 0], [-s, 0, c]]
        return [[c, -s, 0], [s, c, 0], [0, 0, 1]]
    m = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
    for letter in order:
        m = mmul(axis("XYZ".index(letter), deg["XYZ".index(letter)]), m)
    return m


def euler_zxy(m):
    """Euler angles (x, y, z) in degrees with euler_matrix(..., "ZXY") == m
    (M = Ry Rx Rz)."""
    a = math.asin(max(-1.0, min(1.0, -m[1][2])))
    b = math.atan2(m[0][2], m[2][2])
    c = math.atan2(m[1][0], m[1][1])
    return (math.degrees(a), math.degrees(b), math.degrees(c))


def random_quat(rng):
    q = (rng.gauss(0, 1), rng.gauss(0, 1), rng.gauss(0, 1), rng.gauss(0, 1))
    return qnorm(q)

# ------------------------------------------------------- x64-zt dump format


def part_array(data, count):
    if not data or not count:
        return bytes([8, 0])
    return bytes([8, 1]) + struct.pack("<I", count) + data


def part_string(text):
    return bytes([6, 1]) + text.encode() + b"\0"

# ----------------------------------------------------------- animations


class Track:
    """kind 0 none, 1 2D, 2 3D, 3 2D static, 4 3D static (rotations);
    5 bytes, 6 shorts, 7 static (translations). frames: frame index per key;
    keys: the stored values, flat; minsize / static: floats."""

    def __init__(self, kind, bone=0, frames=None, keys=None, minsize=None, static=None):
        self.kind, self.bone, self.frames, self.keys = kind, bone, frames or [], keys or []
        self.minsize, self.static = minsize, static


def encode_xanim(name, bones, rotations, translations, numframes, framerate=30.0, flags=0,
                 long_indices=False, notify=None, delta=b"", asset_type=0, frequency=None, pad_byte=False):
    """An animation file as x64-zt dumps one. rotations: one Track per bone, in
    the order of the bones, grouped by kind (0..4); translations: Tracks of kind
    5, 6, 7 in that order. Frame indices are bytes below 256 frames, else
    16-bit: inline in dataShort for tracks of fewer than 0x40 keys or without
    long_indices, else in the indices array, with the inline run (ending in
    numframes) Greyhound skips."""
    frame_size = 2 if numframes >= 256 else 1
    db, ds, di, rs, rb, ix = bytearray(), bytearray(), bytearray(), bytearray(), bytearray(), bytearray()

    def frames_out(count, frames):
        for f in frames:
            if frame_size == 1:
                db.append(f)
            elif count < 0x40 or not long_indices:
                ds.extend(struct.pack("<H", f))
            else:
                ix.extend(struct.pack("<H", f))

    def inline(count):
        if frame_size == 2 and count >= 0x40:
            for v in (5, 9, numframes):
                ds.extend(struct.pack("<H", v))

    counts = [0] * 10
    for t in rotations:
        counts[t.kind] += 1
        if t.kind in (1, 2):
            count = len(t.frames) - 1
            ds.extend(struct.pack("<H", count))
            inline(count)
            rs.extend(struct.pack("<%dh" % len(t.keys), *t.keys))
            frames_out(count, t.frames)
        elif t.kind in (3, 4):
            ds.extend(struct.pack("<%dh" % len(t.keys), *t.keys))
    for t in translations:
        counts[t.kind] += 1
        if t.kind == 7:
            di.extend(struct.pack("<3f", *t.static))
            db.append(t.bone)
        else:
            db.append(t.bone)
            count = len(t.frames) - 1
            ds.extend(struct.pack("<H", count))
            inline(count)
            di.extend(struct.pack("<6f", *t.minsize))
            if t.kind == 5:
                rb.extend(bytes(t.keys))
            else:
                rs.extend(struct.pack("<%dH" % len(t.keys), *t.keys))
            frames_out(count, t.frames)
    if pad_byte:
        db.append(0)    # a byte no track reads
    counts[8] = len(bones) - counts[5] - counts[6] - counts[7]
    counts[9] = len(bones)

    head = bytearray(0x88)
    pointers = {8: bool(bones), 16: bool(db), 24: bool(ds), 32: bool(di), 40: bool(rs), 48: bool(rb),
                64: bool(ix), 72: bool(notify), 80: bool(delta)}
    for offset, present in pointers.items():
        struct.pack_into("<Q", head, offset, 0x10000 + offset if present else 0)
    struct.pack_into("<III", head, 88, len(rs) // 2, len(rb), len(ix) // frame_size)
    struct.pack_into("<ff", head, 100, framerate, frequency if frequency is not None else framerate / max(1, numframes))
    struct.pack_into("<HHHHH", head, 108, len(db), len(ds) // 2, len(di) // 4, 0, numframes)
    head[118] = flags
    head[119:129] = bytes(counts)
    head[129] = len(notify or [])
    head[130] = asset_type

    out = part_array(bytes(head), 1) + part_string(name)
    seen = [None, name]
    for bone in bones:
        if bone in seen:
            out += bytes([9]) + struct.pack("<II", seen.index(bone), 0)
        else:
            seen.append(bone)
            out += part_string(bone)
    for offset, data, size in ((16, db, 1), (24, ds, 2), (32, di, 4), (40, rs, 2), (48, rb, 1), (64, ix, frame_size)):
        if pointers.get(offset):
            out += part_array(bytes(data), len(data) // size)
    if notify:
        out += part_array(b"".join(struct.pack("<If", 0, t) for _, t in notify), len(notify))
        for n, _ in notify:
            out += part_string(n)
    return bytes(out) + delta


class Decoded:
    pass


def decode_xanim(data):
    """Reads an animation file back: header fields, bone names, and per bone its
    rotation keys (as quaternions, value / 32767) and translation keys."""
    at = 0

    def array(size):
        nonlocal at
        assert data[at] == 8, (at, data[at])
        if data[at + 1] == 0:
            at += 2
            return b"", 0
        count = struct.unpack_from("<I", data, at + 2)[0]
        start = at + 6
        at = start + count * size
        return data[start:at], count

    def string():
        nonlocal at
        if data[at] == 9:
            at += 9
            return None
        assert data[at] == 6 and data[at + 1] == 1
        end = data.index(0, at + 2)
        text = data[at + 2:end].decode()
        at = end + 1
        return text

    head, _ = array(0x88)
    d = Decoded()
    d.name = string()
    ptr = lambda o: struct.unpack_from("<Q", head, o)[0]
    d.framerate, d.frequency = struct.unpack_from("<ff", head, 100)
    d.numframes = struct.unpack_from("<H", head, 116)[0]
    d.flags = head[118]
    d.counts = list(head[119:129])
    d.asset_type = head[130]
    d.bones = [string() for _ in range(d.counts[9])] if ptr(8) else []
    streams = {}
    for offset, key, size in ((16, "db", 1), (24, "ds", 2), (32, "di", 4), (40, "rs", 2), (48, "rb", 1), (56, "ri", 4)):
        streams[key] = array(size)[0] if ptr(offset) else b""
    frame_size = 2 if d.numframes >= 256 else 1
    streams["ix"] = array(frame_size)[0] if ptr(64) else b""
    pos = {k: 0 for k in streams}

    def take(key, fmt):
        n = struct.calcsize(fmt)
        v = struct.unpack_from("<" + fmt, streams[key], pos[key])
        pos[key] += n
        return v

    def frames(count):
        out = []
        for _ in range(count + 1):
            if frame_size == 1:
                out.append(take("db", "B")[0])
            elif count < 0x40 or not ptr(64):
                out.append(take("ds", "H")[0])
            else:
                out.append(take("ix", "H")[0])
        return out

    def skip_inline(count):
        if frame_size == 2 and count >= 0x40:
            while take("ds", "H")[0] != d.numframes:
                pass

    d.rotations, d.translations = {}, {}
    bone = 0
    for kind in range(5):
        for _ in range(d.counts[kind]):
            name = d.bones[bone]
            if kind == 0:
                d.rotations[name] = {0: (0.0, 0.0, 0.0, 1.0)}
            elif kind in (1, 2):
                count = take("ds", "H")[0]
                skip_inline(count)
                per = 2 if kind == 1 else 4
                keys = take("rs", "%dh" % ((count + 1) * per))
                fr = frames(count)
                d.rotations[name] = {}
                for i, f in enumerate(fr):
                    k = [v / 32767.0 for v in keys[i * per:(i + 1) * per]]
                    d.rotations[name][f] = qnorm((0.0, 0.0, k[0], k[1]) if per == 2 else tuple(k))
            else:
                per = 2 if kind == 3 else 4
                k = [v / 32767.0 for v in take("ds", "%dh" % per)]
                d.rotations[name] = {0: qnorm((0.0, 0.0, k[0], k[1]) if per == 2 else tuple(k))}
            bone += 1
    for kind in (5, 6, 7):
        for _ in range(d.counts[kind]):
            if kind == 7:
                v = take("di", "3f")
                b = take("db", "B")[0]
                d.translations[d.bones[b]] = {0: v}
                continue
            b = take("db", "B")[0]
            count = take("ds", "H")[0]
            skip_inline(count)
            mins = take("di", "3f")
            size = take("di", "3f")
            keys = take("rb", "%dB" % ((count + 1) * 3)) if kind == 5 else take("rs", "%dH" % ((count + 1) * 3))
            fr = frames(count)
            d.translations[d.bones[b]] = {f: tuple(mins[k] + size[k] * keys[i * 3 + k] for k in range(3)) for i, f in enumerate(fr)}
    d.unread = {k: len(streams[k]) - pos[k] for k in streams if len(streams[k]) != pos[k]}
    return d


VARIANTS = {"short": (40, False), "long_inline": (300, False), "long_indices": (300, True)}


def sample_animations():
    """Animations with every kind of track, short and long (16-bit frame
    indices, inline and in the indices array), with notetracks and a delta part,
    as the game's own animations may have them; numbers made up."""
    return {"ix_test_" + v: sample_animation("ix_test_" + v, v) for v in VARIANTS}


def sample_animation(name, variant, **options):
    numframes, long_indices = VARIANTS[variant]
    rng = random.Random(7 + numframes + long_indices)

    def rot3(frames):
        keys = []
        for _ in frames:
            keys.extend(int(v * 32767) for v in random_quat(rng))
        return keys

    def rot2(frames):
        keys = []
        for _ in frames:
            a = rng.uniform(-math.pi, math.pi)
            keys.extend((int(math.sin(a / 2) * 32767), int(math.cos(a / 2) * 32767)))
        return keys

    bones = ["tag_origin", "j_mainroot", "j_spinelower", "j_spineupper", "j_spine4", "j_neck", "j_head", "j_hip_le", "j_knee_le"]
    every = list(range(numframes + 1))
    sparse = sorted(set([0, numframes] + rng.sample(range(1, numframes), min(numframes - 1, 70))))
    few = [0, numframes // 2, numframes]
    rotations = [Track(0), Track(1, frames=few, keys=rot2(few)), Track(1, frames=sparse, keys=rot2(sparse)),
                 Track(2, frames=every, keys=rot3(every)), Track(2, frames=few, keys=rot3(few)),
                 Track(3, keys=rot2([0])), Track(4, keys=rot3([0])), Track(4, keys=rot3([0])), Track(4, keys=rot3([0]))]
    translations = [Track(5, bone=1, frames=sparse, keys=[rng.randrange(256) for _ in range(len(sparse) * 3)], minsize=(-1.0, 2.0, 30.0, 0.01, 0.02, 0.03)),
                    Track(6, bone=7, frames=few, keys=[rng.randrange(65536) for _ in range(9)], minsize=(0.5, -0.5, 1.0, 0.0001, 0.0002, 0.0003)),
                    Track(7, bone=8, static=(0.0, 0.0, -17.5)), Track(7, bone=2, static=(3.0, 0.0, 0.0))]
    return encode_xanim(name, bones, rotations, translations, numframes, flags=1,
                        long_indices=long_indices, notify=[("end", 1.0), ("fx", 0.5)],
                        delta=bytes([10, 1]) + struct.pack("<I", 8) + b"deltaXYZ", asset_type=3, **options)

# ---------------------------------------------------------------- the rig


def rig_bones():
    """(name, parent, model-space position) of an IW7-like body, inches, T-pose,
    Z up, facing +X, left at +Y."""
    b = [("tag_origin", None, (0, 0, 0)), ("j_mainroot", "tag_origin", (0, 0, 40)),
         ("j_spinelower", "j_mainroot", (-0.5, 0, 43)), ("j_spineupper", "j_spinelower", (-0.5, 0, 48)),
         ("j_spine4", "j_spineupper", (0, 0, 53)), ("j_chest", "j_spine4", (1.5, 0, 54)),
         ("j_neck", "j_spine4", (0, 0, 60)), ("j_head", "j_neck", (0.5, 0, 64))]
    for s, y in (("le", 1), ("ri", -1)):
        b += [("j_hip_" + s, "j_mainroot", (0, 4 * y, 38)), ("j_knee_" + s, "j_hip_" + s, (0.5, 4 * y, 20)),
              ("j_ankle_" + s, "j_knee_" + s, (0, 4 * y, 3)), ("j_ball_" + s, "j_ankle_" + s, (5, 4 * y, 1)),
              ("j_clavicle_" + s, "j_spine4", (0, 2 * y, 58)), ("j_shoulder_" + s, "j_clavicle_" + s, (0, 7 * y, 58)),
              ("j_elbow_" + s, "j_shoulder_" + s, (-0.5, 18 * y, 58)), ("j_wrist_" + s, "j_elbow_" + s, (0, 28 * y, 58))]
        for f, x in (("index", 1.5), ("mid", 0.5), ("ring", -0.5), ("pinky", -1.5)):
            b += [("j_%s_%s_1" % (f, s), "j_wrist_" + s, (x, 31.5 * y, 58)), ("j_%s_%s_2" % (f, s), "j_%s_%s_1" % (f, s), (x, 33.5 * y, 58)),
                  ("j_%s_%s_3" % (f, s), "j_%s_%s_2" % (f, s), (x, 35 * y, 58))]
        b += [("j_thumb_%s_1" % s, "j_wrist_" + s, (1.5, 29 * y, 57.5)), ("j_thumb_%s_2" % s, "j_thumb_%s_1" % s, (2.5, 30.5 * y, 57)),
              ("j_thumb_%s_3" % s, "j_thumb_%s_2" % s, (3.5, 32 * y, 57))]
    b += [("tag_weapon_right", "j_wrist_ri", (1, -29, 58))]
    return b


def make_rig(name="ix_test_body", seed=3):
    """The body model file, and per bone (parent index, rotation, position)."""
    rng = random.Random(seed)
    bones = rig_bones()
    names = [n for n, _, _ in bones]
    rows = []
    for n, p, pos in bones:
        rot = (0.0, 0.0, 0.0, 1.0) if p is None else random_quat(rng)
        rows.append((None if p is None else names.index(p), rot, tuple(float(v) for v in pos)))
    head = bytearray(0x2E0)
    head[20] = len(bones)       # numBones
    head[21] = 1                # numRootBones
    struct.pack_into("<H", head, 24, 0)   # numClientBones
    out = part_array(bytes(head), 1) + part_string(name)
    for n in names:
        out += part_string(n)
    parents = bytes(i - p for i, (p, _, _) in enumerate(rows) if p is not None)
    out += part_array(parents, len(parents))
    out += part_array(bytes(8 * len(parents)), len(parents))
    out += part_array(bytes(12 * len(parents)), len(parents))
    out += part_array(bytes(len(bones)), len(bones))
    mats = b"".join(struct.pack("<4f3ff", *rot, *pos, 1.0) for _, rot, pos in rows)
    out += part_array(mats, len(bones))
    out += bytes([8, 0]) * 4   # the parts xmodel::dump writes after; not read
    return out, names, rows

# ----------------------------------------------------------------- FBX


SOURCE_BONES = [
    # name, parent, bind position (cm, Y up, facing -Z, left at -X: A-pose)
    ("hips", None, (0, 93, 2)), ("spine", "hips", (0, 109, 1)), ("chest", "spine", (0, 124, 0)),
    ("neck", "chest", (0, 153, 1)), ("head", "neck", (0, 164, -1)),
]
for _s, _x in (("L", -1), ("R", 1)):
    SOURCE_BONES += [
        ("upper_arm_" + _s, "chest", (18 * _x, 143, 1)), ("forearm_" + _s, "upper_arm_" + _s, (41 * _x, 130, 2)),
        ("hand_" + _s, "forearm_" + _s, (59 * _x, 117, 0)),
        ("thigh_" + _s, "hips", (10 * _x, 92, 1)), ("shin_" + _s, "thigh_" + _s, (11 * _x, 50, 0)),
        ("foot_" + _s, "shin_" + _s, (12 * _x, 8, 2)), ("toe_" + _s, "foot_" + _s, (12 * _x, 2, -12)),
        ("thumb_02_" + _s, "hand_" + _s, (61 * _x, 114, -3)), ("thumb_03_" + _s, "thumb_02_" + _s, (63 * _x, 112, -5)),
    ]
    for _f, _z in (("index", -2), ("middle", 0), ("ring", 1.5), ("pinky", 3)):
        SOURCE_BONES += [
            ("f_%s_01_%s" % (_f, _s), "hand_" + _s, (66 * _x, 111, _z)),
            ("f_%s_02_%s" % (_f, _s), "f_%s_01_%s" % (_f, _s), (69 * _x, 108, _z)),
            ("f_%s_03_%s" % (_f, _s), "f_%s_02_%s" % (_f, _s), (71 * _x, 106, _z)),
        ]

# The scene's "Root" (the skeleton's parent): turned as the rig DanceMoves.fbx
# was exported with (Root 270 degrees about X under a node turned 180 about Y).
ROOT_EULER = (270.0, 0.0, 0.0)
SCENE_EULER = (0.0, -180.0, 0.0)


class FbxNode:
    def __init__(self, name, props=(), children=None):
        self.name, self.props, self.children = name, list(props), children or []


class Arr:
    """An FBX array: kind 'd', 'f', 'l' or 'i'; ascii_ints: written in ASCII as
    the integers that share the floats' bits (KeyAttrDataFloat)."""

    def __init__(self, kind, values, ascii_ints=False):
        self.kind, self.values, self.ascii_ints = kind, list(values), ascii_ints


def fbx_ascii(root):
    lines = ["; FBX 7.7.0 project file", "; made up for Infinite Expansion's tests", ""]

    def value(v):
        if isinstance(v, str):
            return '"%s"' % v.replace("\x00\x01", "::")
        if isinstance(v, float):
            return repr(v)
        return str(v)

    def emit(node, depth):
        pad = "\t" * depth
        if len(node.props) == 1 and isinstance(node.props[0], Arr):
            arr = node.props[0]
            vals = arr.values
            if arr.ascii_ints:
                vals = [struct.unpack("<i", struct.pack("<f", v))[0] for v in vals]
            items = [repr(v) if isinstance(v, float) else str(v) for v in vals]
            # Long arrays wrap over lines after a comma, as the FBX SDK writes them.
            chunks = [",".join(items[i:i + 12]) for i in range(0, len(items), 12)]
            chunks = [c + "," for c in chunks[:-1]] + chunks[-1:]
            lines.append("%s%s: *%d {" % (pad, node.name, len(vals)))
            lines.append("%s\ta: %s" % (pad, "\n".join(chunks)))
            lines.append("%s} " % pad)
            return
        head = "%s%s: %s" % (pad, node.name, ", ".join(value(p) for p in node.props))
        if node.children:
            lines.append(head.rstrip() + " {")
            for c in node.children:
                emit(c, depth + 1)
            lines.append("%s}" % pad)
        else:
            lines.append(head)

    for c in root:
        emit(c, 0)
        lines.append("")
    return ("\n".join(lines) + "\n").encode()


def fbx_binary(root, compress=True):
    out = bytearray(b"Kaydara FBX Binary  \x00\x1a\x00" + struct.pack("<I", 7700))

    def prop(v):
        if isinstance(v, Arr):
            fmt = {"d": "d", "f": "f", "l": "q", "i": "i"}[v.kind]
            raw = struct.pack("<%d%s" % (len(v.values), fmt), *v.values)
            if compress and len(v.values) > 4:
                comp = zlib.compress(raw)
                return v.kind.encode() + struct.pack("<III", len(v.values), 1, len(comp)) + comp
            return v.kind.encode() + struct.pack("<III", len(v.values), 0, len(raw)) + raw
        if isinstance(v, str):
            b = v.encode()
            return b"S" + struct.pack("<I", len(b)) + b
        if isinstance(v, float):
            return b"D" + struct.pack("<d", v)
        if isinstance(v, int):
            if -2 ** 31 <= v < 2 ** 31:
                return b"I" + struct.pack("<i", v)
            return b"L" + struct.pack("<q", v)
        raise TypeError(v)

    def node(n, offset):
        props = b"".join(prop(p) for p in n.props)
        name = n.name.encode()
        body = bytearray()
        start = offset + 25 + len(name) + len(props)
        for c in n.children:
            body += node(c, start + len(body))
        if n.children:
            body += bytes(25)
        end = start + len(body)
        return struct.pack("<QQQB", end, len(n.props), len(props), len(name)) + name + props + body

    for n in root:
        out += node(n, len(out))
    out += bytes(25)
    return bytes(out)


def p70(*props):
    return FbxNode("Properties70", (), [FbxNode("P", p) for p in props])


def source_rig(seed=5):
    """Per source bone: bind world rotation (arbitrary, as real rigs have) and
    position, as the bones of SOURCE_BONES; plus the Root's world matrix."""
    rng = random.Random(seed)
    root = mmul(euler_matrix(SCENE_EULER, "XYZ"), euler_matrix(ROOT_EULER, "XYZ"))
    bind = {}
    for name, parent, pos in SOURCE_BONES:
        bind[name] = (random_quat(rng), tuple(float(v) for v in pos))
    return root, bind


def make_fbx(motion, frames=31, fps=30.0, binary=False, user_tangents=False, seed=5, drop=(), compress=True):
    """An FBX of the source rig. motion(name, frame) gives a bone's world
    rotation and position at a frame (None: its bind pose). Returns the file
    and, per bone, per frame, its world rotation and position (the truth the
    converter must reproduce)."""
    rng = random.Random(seed + 1)
    root_m, bind = source_rig(seed)
    bones = [b for b in SOURCE_BONES if b[0] not in drop]
    ids = {}
    next_id = [1000]

    def new_id():
        next_id[0] += 1
        return next_id[0]

    scene_id, root_id = new_id(), new_id()
    for name, _, _ in bones:
        ids[name] = new_id()
    truth = {}
    for name, parent, _ in bones:
        truth[name] = []
        for f in range(frames):
            m = motion(name, f)
            truth[name].append(m if m is not None else bind[name])
    root_q = mat_q(root_m)
    pre = {name: (rng.uniform(-90, 90), rng.uniform(-90, 90), rng.uniform(-90, 90)) for name, _, _ in bones}

    def local(name, parent, f):
        """Lcl Translation and Lcl Rotation (ZXY) for a bone at a frame."""
        q, pos = truth[name][f]
        if parent is None:
            pq, ppos = root_q, (0.0, 0.0, 0.0)
        else:
            pq, ppos = truth[parent][f]
        rel = qmul(qconj(pq), q)
        t = qrot(qconj(pq), tuple(pos[i] - ppos[i] for i in range(3)))
        rpre = euler_matrix(pre[name], "XYZ")
        r = mmul(mT(rpre), qmat(rel))
        return t, euler_zxy(r)

    def keys(values, tangents):
        ktime = 46186158000
        times = [int(round(f / fps * ktime)) for f in range(frames)]
        node = [FbxNode("Default", [float(values[0])]), FbxNode("KeyVer", [4009]),
                FbxNode("KeyTime", [Arr("l", times)]), FbxNode("KeyValueFloat", [Arr("f", values)])]
        if tangents:
            slopes = []
            for i in range(frames):
                a, b = max(0, i - 1), min(frames - 1, i + 1)
                slopes.append((values[b] - values[a]) / ((b - a) / fps))
            data = []
            for i in range(frames):
                data += [slopes[i], slopes[min(frames - 1, i + 1)], struct.unpack("<f", struct.pack("<I", 0x0D050D05))[0], 0.0]
            node += [FbxNode("KeyAttrFlags", [Arr("i", [0x03000C08] * frames)]),
                     FbxNode("KeyAttrDataFloat", [Arr("f", data, ascii_ints=True)]),
                     FbxNode("KeyAttrRefCount", [Arr("i", [1] * frames)])]
        else:
            node += [FbxNode("KeyAttrFlags", [Arr("i", [8456])]),
                     FbxNode("KeyAttrDataFloat", [Arr("f", [0.0, 0.0, struct.unpack("<f", struct.pack("<I", 0x0D050D05))[0], 0.0], ascii_ints=True)]),
                     FbxNode("KeyAttrRefCount", [Arr("i", [frames])])]
        return node

    objects, connections = [], []

    def model(mid, name, kind, t, r, pre_rot=None):
        props = [("RotationOrder", "enum", "", "", 4), ("RotationActive", "bool", "", "", 1),
                 ("Lcl Translation", "Lcl Translation", "", "A+", float(t[0]), float(t[1]), float(t[2])),
                 ("Lcl Rotation", "Lcl Rotation", "", "A+", float(r[0]), float(r[1]), float(r[2]))]
        if pre_rot is not None:
            props.insert(1, ("PreRotation", "Vector3D", "Vector", "", float(pre_rot[0]), float(pre_rot[1]), float(pre_rot[2])))
        sep = "\x00\x01Model" if binary else ""
        label = name + sep if binary else "Model::" + name
        return FbxNode("Model", [mid, label, kind], [FbxNode("Version", [232]), p70(*props)])

    # The scene node and Root: Root = Ry(-180) Rx(270), RotationOrder ZXY with
    # angles that give it (ZXY for (270, -180, 0) is Ry(-180) Rx(270)).
    objects.append(model(scene_id, "BaseMesh_Anim", "Null", (0, 0, 0), (0.0, 0.0, 0.0)))
    objects.append(model(root_id, "Root", "Null", (0, 0, 0), (ROOT_EULER[0], SCENE_EULER[1], 0.0)))
    connections += [FbxNode("C", ["OO", scene_id, 0]), FbxNode("C", ["OO", root_id, scene_id])]
    stack, layer = new_id(), new_id()
    objects_anim = [FbxNode("AnimationStack", [stack, "AnimStack::take" if not binary else "take\x00\x01AnimStack", ""], [p70()]),
                    FbxNode("AnimationLayer", [layer, "AnimLayer::BaseLayer" if not binary else "BaseLayer\x00\x01AnimLayer", ""], [])]
    connections.append(FbxNode("C", ["OO", layer, stack]))
    pose_nodes = []
    for name, parent, _ in bones:
        t0, r0 = local(name, parent, 0)
        objects.append(model(ids[name], name, "LimbNode", t0, r0, pre[name]))
        connections.append(FbxNode("C", ["OO", ids[name], ids[parent] if parent else root_id]))
        q, pos = bind[name]
        m = qmat(q)
        mat = [m[0][0], m[1][0], m[2][0], 0.0, m[0][1], m[1][1], m[2][1], 0.0, m[0][2], m[1][2], m[2][2], 0.0, pos[0], pos[1], pos[2], 1.0]
        pose_nodes.append(FbxNode("PoseNode", [], [FbxNode("Node", [ids[name]]), FbxNode("Matrix", [Arr("d", mat)])]))
        values = [local(name, parent, f) for f in range(frames)]
        for channel, label, index in (("T", "Lcl Translation", 0), ("R", "Lcl Rotation", 1)):
            cn = new_id()
            objects_anim.append(FbxNode("AnimationCurveNode", [cn, ("AnimCurveNode::" + channel) if not binary else channel + "\x00\x01AnimCurveNode", ""], [p70()]))
            connections.append(FbxNode("C", ["OO", cn, layer]))
            connections.append(FbxNode("C", ["OP", cn, ids[name], label]))
            for axis in range(3):
                cv = new_id()
                series = [v[index][axis] for v in values]
                if index == 1:
                    # Unwrapped, as exporters write Euler curves.
                    for i in range(1, len(series)):
                        while series[i] - series[i - 1] > 180:
                            series[i] -= 360
                        while series[i] - series[i - 1] < -180:
                            series[i] += 360
                objects_anim.append(FbxNode("AnimationCurve", [cv, "AnimCurve::" if not binary else "\x00\x01AnimCurve", ""], keys(series, user_tangents)))
                connections.append(FbxNode("C", ["OP", cv, cn, "d|" + "XYZ"[axis]]))
    objects.append(FbxNode("Pose", [new_id(), "Pose::BIND" if not binary else "BIND\x00\x01Pose", "BindPose"],
                           [FbxNode("Type", ["BindPose"]), FbxNode("NbPoseNodes", [len(pose_nodes)])] + pose_nodes))
    root = [FbxNode("FBXHeaderExtension", [], [FbxNode("FBXHeaderVersion", [1004]), FbxNode("FBXVersion", [7700]),
                                               FbxNode("OtherFlags", [], [FbxNode("TCDefinition", [127])])]),
            FbxNode("GlobalSettings", [], [FbxNode("Version", [1000]),
                                           p70(("UpAxis", "int", "Integer", "", 1), ("TimeMode", "enum", "", "", 6))]),
            FbxNode("Objects", [], objects + objects_anim),
            FbxNode("Connections", [], connections)]
    data = fbx_binary(root, compress) if binary else fbx_ascii(root)
    return data, truth, bind


# The turn from the source rig's world (facing -Z, Y up, left -X) to IW7's
# model space (facing +X, Z up, left +Y), as a rotation matrix by columns.
TURN = mat_q([[0, 0, -1], [-1, 0, 0], [0, 1, 0]])


def rig_world(decoded, names, rows, frame):
    """IW7 bones' model-space rotations and positions at a frame: the animation's
    keys where it has them, else the rest pose under the parent (forward
    kinematics, as the game poses a model)."""
    rest_local_r, rest_local_t = [], []
    for i, (p, rot, pos) in enumerate(rows):
        if p is None:
            rest_local_r.append(rot)
            rest_local_t.append(pos)
        else:
            prot, ppos = rows[p][1], rows[p][2]
            rest_local_r.append(qnorm(qmul(qconj(prot), rot)))
            rest_local_t.append(qrot(qconj(prot), tuple(pos[k] - ppos[k] for k in range(3))))
    world_r, world_t = [], []
    for i, (p, _, _) in enumerate(rows):
        name = names[i]
        lr = rest_local_r[i]
        if name in decoded.rotations:
            keys = decoded.rotations[name]
            lr = keys.get(frame, keys[max(k for k in keys if k <= frame)])
        lt = rest_local_t[i]
        if name in decoded.translations:
            keys = decoded.translations[name]
            lt = keys.get(frame, keys[max(k for k in keys if k <= frame)])
        if p is None:
            world_r.append(lr)
            world_t.append(lt)
        else:
            world_r.append(qnorm(qmul(world_r[p], lr)))
            off = qrot(world_r[p], lt)
            world_t.append(tuple(world_t[p][k] + off[k] for k in range(3)))
    return world_r, world_t
