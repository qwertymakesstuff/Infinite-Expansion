// Infinite Expansion - custom emote converter: your animation (FBX) onto IW7's
// body rig, as an animation x64-zt builds into the emote pack.
//
// C# 5 (the compiler of .NET Framework 4, which Windows PowerShell 5.1's
// Add-Type uses), loaded by IXEmotes.Core.ps1. Nothing here runs the game or
// x64-zt; it reads and writes files:
//
//   - x64-zt's own dump format (zonetool\utils\io\assetmanager.hpp dumper and
//     reader): each part is a type byte, an "existing" byte and the data;
//     arrays carry their element count, raw blocks their size, strings end
//     with a zero; a part dumped before is written as a reference (type 9:
//     its index among the parts so far and an element offset).
//   - IW7 animations (.xab) in the order xanim_parts::dump writes them
//     (zonetool\iw7\assets\xanim.cpp) with XAnimParts as in
//     zonetool\iw7\structs.hpp (0x88 bytes), and their data streams in the
//     order Greyhound's CoDXAnimTranslator::TranslateXAnim reads IW7's
//     (GameInfiniteWarfare::ReadXAnim: 32-bit bone ids, quaternions as
//     16-bit values / 32768, translations as min + size * key, inline frame
//     indices). x64-zt's own T7-to-IW7 converter (t7\converter\iw7\assets\
//     xanim.cpp) walks the streams the same way and credits Greyhound.
//   - IW7 models (.xmb) in the order xmodel::dump writes them
//     (zonetool\iw7\assets\xmodel.cpp), XModel as in structs.hpp (0x2E0
//     bytes): bone names, parent list (an offset back for each bone after
//     the root bones), and baseMat, each bone's rotation and position in
//     model space (DObjAnimMat; read so by Greyhound's
//     CoDXModelBonesHelper).
//   - FBX, ASCII and binary, as Blender's importer reads it
//     (io_scene_fbx\parse_fbx.py, import_fbx.py, fbx_utils.py): node
//     transforms T * Roff * Rp * Rpre * R * Rpost^-1 * Rp^-1 * Soff * Sp * S
//     * Sp^-1, the rotation order for R only (pre- and post-rotation always
//     XYZ, all of it only when RotationActive), bind pose matrices in global
//     space stored column by column, the time unit chosen by
//     FBXHeaderExtension\OtherFlags\TCDefinition.
//
// Nothing of the game's art is part of this file or the mod: the converter
// reads the rig and a sample animation that x64-zt dumps from the player's
// own game.

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Text;

namespace IXEmotes
{
    public class EmoteException : Exception
    {
        public EmoteException(string message) : base(message)
        {
        }
    }

    // ---------------------------------------------------------------- math

    public struct Vec3
    {
        public double X, Y, Z;

        public Vec3(double x, double y, double z)
        {
            X = x;
            Y = y;
            Z = z;
        }

        public static Vec3 operator +(Vec3 a, Vec3 b) { return new Vec3(a.X + b.X, a.Y + b.Y, a.Z + b.Z); }
        public static Vec3 operator -(Vec3 a, Vec3 b) { return new Vec3(a.X - b.X, a.Y - b.Y, a.Z - b.Z); }
        public static Vec3 operator *(Vec3 a, double s) { return new Vec3(a.X * s, a.Y * s, a.Z * s); }
        public static double Dot(Vec3 a, Vec3 b) { return a.X * b.X + a.Y * b.Y + a.Z * b.Z; }
        public static Vec3 Cross(Vec3 a, Vec3 b) { return new Vec3(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X); }
        public double Length { get { return Math.Sqrt(Dot(this, this)); } }

        public Vec3 Normalized()
        {
            double l = Length;
            return l < 1e-12 ? new Vec3(0, 0, 0) : this * (1.0 / l);
        }
    }

    public struct Quat
    {
        public double X, Y, Z, W;

        public Quat(double x, double y, double z, double w)
        {
            X = x;
            Y = y;
            Z = z;
            W = w;
        }

        public static Quat Identity { get { return new Quat(0, 0, 0, 1); } }

        public static Quat operator *(Quat a, Quat b)
        {
            return new Quat(
                a.W * b.X + a.X * b.W + a.Y * b.Z - a.Z * b.Y,
                a.W * b.Y - a.X * b.Z + a.Y * b.W + a.Z * b.X,
                a.W * b.Z + a.X * b.Y - a.Y * b.X + a.Z * b.W,
                a.W * b.W - a.X * b.X - a.Y * b.Y - a.Z * b.Z);
        }

        public Quat Conjugate() { return new Quat(-X, -Y, -Z, W); }
        public static double Dot(Quat a, Quat b) { return a.X * b.X + a.Y * b.Y + a.Z * b.Z + a.W * b.W; }

        public Quat Normalized()
        {
            double l = Math.Sqrt(Dot(this, this));
            return l < 1e-12 ? Identity : new Quat(X / l, Y / l, Z / l, W / l);
        }

        public Quat Negated() { return new Quat(-X, -Y, -Z, -W); }

        public Vec3 Rotate(Vec3 v)
        {
            Quat p = this * new Quat(v.X, v.Y, v.Z, 0) * Conjugate();
            return new Vec3(p.X, p.Y, p.Z);
        }

        // The shortest rotation that turns direction a into direction b.
        public static Quat FromTo(Vec3 a, Vec3 b)
        {
            a = a.Normalized();
            b = b.Normalized();
            if (a.Length < 0.5 || b.Length < 0.5)
            {
                return Identity;
            }
            double d = Vec3.Dot(a, b);
            if (d < -0.999999)
            {
                Vec3 axis = Vec3.Cross(new Vec3(1, 0, 0), a);
                if (axis.Length < 1e-6)
                {
                    axis = Vec3.Cross(new Vec3(0, 1, 0), a);
                }
                axis = axis.Normalized();
                return new Quat(axis.X, axis.Y, axis.Z, 0);
            }
            Vec3 c = Vec3.Cross(a, b);
            return new Quat(c.X, c.Y, c.Z, 1 + d).Normalized();
        }

        public static Quat Slerp(Quat a, Quat b, double t)
        {
            double d = Dot(a, b);
            if (d < 0)
            {
                b = b.Negated();
                d = -d;
            }
            if (d > 0.9995)
            {
                return new Quat(a.X + (b.X - a.X) * t, a.Y + (b.Y - a.Y) * t, a.Z + (b.Z - a.Z) * t, a.W + (b.W - a.W) * t).Normalized();
            }
            double angle = Math.Acos(d);
            double s = Math.Sin(angle);
            double wa = Math.Sin((1 - t) * angle) / s;
            double wb = Math.Sin(t * angle) / s;
            return new Quat(a.X * wa + b.X * wb, a.Y * wa + b.Y * wb, a.Z * wa + b.Z * wb, a.W * wa + b.W * wb).Normalized();
        }

        // From a rotation matrix given as its three columns (the rotated X, Y
        // and Z axes).
        public static Quat FromColumns(Vec3 c0, Vec3 c1, Vec3 c2)
        {
            double m00 = c0.X, m10 = c0.Y, m20 = c0.Z;
            double m01 = c1.X, m11 = c1.Y, m21 = c1.Z;
            double m02 = c2.X, m12 = c2.Y, m22 = c2.Z;
            double trace = m00 + m11 + m22;
            Quat q;
            if (trace > 0)
            {
                double s = Math.Sqrt(trace + 1.0) * 2;
                q = new Quat((m21 - m12) / s, (m02 - m20) / s, (m10 - m01) / s, 0.25 * s);
            }
            else if (m00 > m11 && m00 > m22)
            {
                double s = Math.Sqrt(1.0 + m00 - m11 - m22) * 2;
                q = new Quat(0.25 * s, (m01 + m10) / s, (m02 + m20) / s, (m21 - m12) / s);
            }
            else if (m11 > m22)
            {
                double s = Math.Sqrt(1.0 + m11 - m00 - m22) * 2;
                q = new Quat((m01 + m10) / s, 0.25 * s, (m12 + m21) / s, (m02 - m20) / s);
            }
            else
            {
                double s = Math.Sqrt(1.0 + m22 - m00 - m11) * 2;
                q = new Quat((m02 + m20) / s, (m12 + m21) / s, 0.25 * s, (m10 - m01) / s);
            }
            return q.Normalized();
        }
    }

    // 4x4 matrices for column vectors, stored column by column as FBX stores
    // them: element (row r, column c) at [c * 4 + r], translation at 12..14.
    public static class Mat4
    {
        public static double[] Identity()
        {
            return new double[] { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 };
        }

        public static double[] Multiply(double[] a, double[] b)
        {
            var r = new double[16];
            for (int c = 0; c < 4; c++)
            {
                for (int row = 0; row < 4; row++)
                {
                    double s = 0;
                    for (int k = 0; k < 4; k++)
                    {
                        s += a[k * 4 + row] * b[c * 4 + k];
                    }
                    r[c * 4 + row] = s;
                }
            }
            return r;
        }

        public static double[] Translation(Vec3 v)
        {
            var m = Identity();
            m[12] = v.X;
            m[13] = v.Y;
            m[14] = v.Z;
            return m;
        }

        public static double[] Scaling(Vec3 v)
        {
            var m = Identity();
            m[0] = v.X;
            m[5] = v.Y;
            m[10] = v.Z;
            return m;
        }

        static double[] Axis(int axis, double degrees)
        {
            double a = degrees * Math.PI / 180.0, c = Math.Cos(a), s = Math.Sin(a);
            var m = Identity();
            if (axis == 0)
            {
                m[5] = c; m[9] = -s; m[6] = s; m[10] = c;
            }
            else if (axis == 1)
            {
                m[0] = c; m[8] = s; m[2] = -s; m[10] = c;
            }
            else
            {
                m[0] = c; m[4] = -s; m[1] = s; m[5] = c;
            }
            return m;
        }

        // Euler angles in degrees. The order names the axis applied first:
        // XYZ = Rz * Ry * Rx, as Blender's Euler(..., order).to_matrix().
        // FBX RotationOrder 0..5 = XYZ, XZY, YZX, YXZ, ZXY, ZYX; 6 (spheric)
        // is read as XYZ, as Blender does.
        public static double[] Rotation(Vec3 degrees, int order)
        {
            var x = Axis(0, degrees.X);
            var y = Axis(1, degrees.Y);
            var z = Axis(2, degrees.Z);
            switch (order)
            {
                case 1: return Multiply(y, Multiply(z, x));
                case 2: return Multiply(x, Multiply(z, y));
                case 3: return Multiply(z, Multiply(x, y));
                case 4: return Multiply(y, Multiply(x, z));
                case 5: return Multiply(x, Multiply(y, z));
                default: return Multiply(z, Multiply(y, x));
            }
        }

        public static double[] Transposed3(double[] m)
        {
            var r = Identity();
            for (int c = 0; c < 3; c++)
            {
                for (int row = 0; row < 3; row++)
                {
                    r[c * 4 + row] = m[row * 4 + c];
                }
            }
            return r;
        }

        public static Vec3 Column(double[] m, int c)
        {
            return new Vec3(m[c * 4], m[c * 4 + 1], m[c * 4 + 2]);
        }

        public static Vec3 Position(double[] m)
        {
            return Column(m, 3);
        }

        // The rotation of a transform, without its scale.
        public static Quat RotationOf(double[] m)
        {
            Vec3 x = Column(m, 0).Normalized();
            Vec3 y = Column(m, 1);
            y = (y - x * Vec3.Dot(x, y)).Normalized();
            Vec3 z = Vec3.Cross(x, y);
            if (Vec3.Dot(z, Column(m, 2)) < 0)
            {
                throw new EmoteException("The animation has a mirrored (negative scale) bone, which the game cannot play.");
            }
            return Quat.FromColumns(x, y, z);
        }

        // The inverse of a transform made of rotation, uniform-free scale and
        // translation (any invertible affine transform).
        public static double[] InverseAffine(double[] m)
        {
            double a = m[0], b = m[4], c = m[8];
            double d = m[1], e = m[5], f = m[9];
            double g = m[2], h = m[6], i = m[10];
            double det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
            if (Math.Abs(det) < 1e-18)
            {
                throw new EmoteException("The animation has a bone scaled to nothing.");
            }
            double inv = 1.0 / det;
            var r = Identity();
            r[0] = (e * i - f * h) * inv;
            r[4] = (c * h - b * i) * inv;
            r[8] = (b * f - c * e) * inv;
            r[1] = (f * g - d * i) * inv;
            r[5] = (a * i - c * g) * inv;
            r[9] = (c * d - a * f) * inv;
            r[2] = (d * h - e * g) * inv;
            r[6] = (b * g - a * h) * inv;
            r[10] = (a * e - b * d) * inv;
            Vec3 t = Position(m);
            r[12] = -(r[0] * t.X + r[4] * t.Y + r[8] * t.Z);
            r[13] = -(r[1] * t.X + r[5] * t.Y + r[9] * t.Z);
            r[14] = -(r[2] * t.X + r[6] * t.Y + r[10] * t.Z);
            return r;
        }

        public static Vec3 Apply(double[] m, Vec3 v)
        {
            return new Vec3(
                m[0] * v.X + m[4] * v.Y + m[8] * v.Z + m[12],
                m[1] * v.X + m[5] * v.Y + m[9] * v.Z + m[13],
                m[2] * v.X + m[6] * v.Y + m[10] * v.Z + m[14]);
        }
    }

    // ------------------------------------------------- x64-zt dump format

    // One part of a file in x64-zt's dump format.
    public class DumpPart
    {
        public const byte TypeString = 6;
        public const byte TypeArray = 8;
        public const byte TypeOffset = 9;
        public const byte TypeRaw = 10;

        public byte Type;
        public bool Exists;
        public uint Count;      // arrays: elements
        public byte[] Data;     // arrays and raw blocks: the bytes
        public string Text;     // strings
        public uint RefIndex;   // references
        public uint RefOffset;

        public static DumpPart Array(byte[] data, uint count)
        {
            var p = new DumpPart();
            p.Type = TypeArray;
            p.Exists = data != null && count > 0;
            p.Count = count;
            p.Data = data;
            return p;
        }

        public static DumpPart String(string text)
        {
            var p = new DumpPart();
            p.Type = TypeString;
            p.Exists = text != null;
            p.Text = text;
            return p;
        }
    }

    public class DumpReader
    {
        readonly byte[] bytes;
        int at;
        public readonly List<DumpPart> Parts = new List<DumpPart>();
        readonly string what;

        public DumpReader(byte[] data, string name)
        {
            bytes = data;
            what = name;
        }

        public int Position { get { return at; } }
        public bool AtEnd { get { return at >= bytes.Length; } }

        void Need(int n)
        {
            if (at + n > bytes.Length)
            {
                throw new EmoteException(what + " ends early (byte " + at + ").");
            }
        }

        byte Byte()
        {
            Need(1);
            return bytes[at++];
        }

        uint UInt()
        {
            Need(4);
            uint v = BitConverter.ToUInt32(bytes, at);
            at += 4;
            return v;
        }

        // An array of elements of the given size: present, absent (when the
        // dumper had none) or a reference to an earlier part.
        public DumpPart Array(int elementSize)
        {
            int start = at;
            byte type = Byte();
            var p = new DumpPart();
            p.Type = type;
            if (type == DumpPart.TypeOffset)
            {
                p.RefIndex = UInt();
                p.RefOffset = UInt();
            }
            else if (type == DumpPart.TypeArray)
            {
                p.Exists = Byte() == 1;
                if (p.Exists)
                {
                    p.Count = UInt();
                    long size = (long)p.Count * elementSize;
                    if (size > bytes.Length)
                    {
                        throw new EmoteException(what + " has an array larger than the file (byte " + start + ").");
                    }
                    Need((int)size);
                    p.Data = new byte[size];
                    Buffer.BlockCopy(bytes, at, p.Data, 0, (int)size);
                    at += (int)size;
                }
            }
            else
            {
                throw new EmoteException(what + " has no array where x64-zt writes one (byte " + start + ").");
            }
            Parts.Add(p);
            return p;
        }

        public DumpPart String()
        {
            int start = at;
            byte type = Byte();
            var p = new DumpPart();
            p.Type = type;
            if (type == DumpPart.TypeOffset)
            {
                p.RefIndex = UInt();
                p.RefOffset = UInt();
                if (p.RefIndex >= Parts.Count || Parts[(int)p.RefIndex].Text == null || p.RefOffset > Parts[(int)p.RefIndex].Text.Length)
                {
                    throw new EmoteException(what + " refers to a string it does not have (byte " + start + ").");
                }
                p.Text = Parts[(int)p.RefIndex].Text.Substring((int)p.RefOffset);
            }
            else if (type == DumpPart.TypeString)
            {
                p.Exists = Byte() == 1;
                if (p.Exists)
                {
                    int end = System.Array.IndexOf(bytes, (byte)0, at);
                    if (end < 0)
                    {
                        throw new EmoteException(what + " ends inside a string.");
                    }
                    p.Text = Encoding.ASCII.GetString(bytes, at, end - at);
                    at = end + 1;
                }
            }
            else
            {
                throw new EmoteException(what + " has no string where x64-zt writes one (byte " + start + ").");
            }
            Parts.Add(p);
            return p;
        }

        public byte[] Rest()
        {
            var r = new byte[bytes.Length - at];
            Buffer.BlockCopy(bytes, at, r, 0, r.Length);
            at = bytes.Length;
            return r;
        }
    }

    public class DumpWriter
    {
        readonly MemoryStream stream = new MemoryStream();

        public void Part(DumpPart p)
        {
            stream.WriteByte(p.Type);
            if (p.Type == DumpPart.TypeOffset)
            {
                Write(BitConverter.GetBytes(p.RefIndex));
                Write(BitConverter.GetBytes(p.RefOffset));
                return;
            }
            stream.WriteByte((byte)(p.Exists ? 1 : 0));
            if (!p.Exists)
            {
                return;
            }
            if (p.Type == DumpPart.TypeString)
            {
                Write(Encoding.ASCII.GetBytes(p.Text));
                stream.WriteByte(0);
            }
            else if (p.Type == DumpPart.TypeArray)
            {
                Write(BitConverter.GetBytes(p.Count));
                Write(p.Data);
            }
            else
            {
                Write(BitConverter.GetBytes((uint)p.Data.Length));
                Write(p.Data);
            }
        }

        public void Write(byte[] data)
        {
            stream.Write(data, 0, data.Length);
        }

        public byte[] ToArray()
        {
            return stream.ToArray();
        }
    }

    // ------------------------------------------------------ IW7 animations

    // An animation's data streams, read as Greyhound reads IW7's, kept as the
    // values stored (no conversion), so that writing them again gives the
    // same bytes.
    public class RotationTrack
    {
        public int Kind;          // 0 none, 1 2D, 2 3D, 3 2D static, 4 3D static
        public int Bone;
        public int KeyCount;      // the stored count: keys - 1
        public ushort[] Inline;   // frame indices skipped inline (long animations)
        public int[] Frames;
        public short[] Keys;      // 2 or 4 per key: (z, w) or (x, y, z, w)
    }

    public class TranslationTrack
    {
        public int Kind;          // 5 bytes, 6 shorts, 7 static
        public int Bone;
        public int KeyCount;
        public ushort[] Inline;
        public int[] Frames;
        public int[] MinSize;     // 6 floats as stored: min x y z, size x y z
        public int[] Static;      // 3 floats as stored
        public ushort[] Keys;     // 3 per key
    }

    public class XAnim
    {
        public const int PartsSize = 0x88;

        // XAnimParts (x64-zt zonetool\iw7\structs.hpp).
        public byte[] Header;
        public string Name;
        public List<DumpPart> BoneNameParts = new List<DumpPart>();
        public List<string> Bones = new List<string>();
        public DumpPart DataByte, DataShort, DataInt, RandomDataShort, RandomDataByte, RandomDataInt, Indices, Notify;
        public List<DumpPart> NotifyNames = new List<DumpPart>();
        public byte[] Tail = new byte[0];   // the delta part, kept as dumped

        public List<RotationTrack> Rotations = new List<RotationTrack>();
        public List<TranslationTrack> Translations = new List<TranslationTrack>();
        // The bones without a translation, by index (boneCount[8] of them),
        // after the last translation in dataByte: what the game's own
        // animations hold there (owner's log, 0.14.6: each sample's unread
        // dataByte was exactly that long). Greyhound skips them.
        public int[] Untranslated = new int[0];

        public ulong Pointer(int offset) { return BitConverter.ToUInt64(Header, offset); }
        public float Framerate { get { return BitConverter.ToSingle(Header, 100); } }
        public float Frequency { get { return BitConverter.ToSingle(Header, 104); } }
        public int NumFrames { get { return BitConverter.ToUInt16(Header, 116); } }
        public int Flags { get { return Header[118]; } }
        public int BoneCount(int i) { return Header[119 + i]; }
        public int NotifyCount { get { return Header[129]; } }
        public uint IndexCount { get { return BitConverter.ToUInt32(Header, 96); } }
        public int FrameSize { get { return NumFrames >= 256 ? 2 : 1; } }

        public static XAnim Read(byte[] file, string what)
        {
            var r = new DumpReader(file, what);
            var a = new XAnim();
            var head = r.Array(PartsSize);
            if (head.Type != DumpPart.TypeArray || !head.Exists || head.Count != 1)
            {
                throw new EmoteException(what + " is not an animation as x64-zt dumps it.");
            }
            a.Header = head.Data;
            var name = r.String();
            if (name.Text == null)
            {
                throw new EmoteException(what + " has no name.");
            }
            a.Name = name.Text;
            if (a.Pointer(8) != 0)
            {
                for (int i = 0; i < a.BoneCount(9); i++)
                {
                    var bone = r.String();
                    if (bone.Text == null)
                    {
                        throw new EmoteException(what + " has an empty bone name.");
                    }
                    a.BoneNameParts.Add(bone);
                    a.Bones.Add(bone.Text);
                }
            }
            if (a.Pointer(16) != 0) a.DataByte = r.Array(1);
            if (a.Pointer(24) != 0) a.DataShort = r.Array(2);
            if (a.Pointer(32) != 0) a.DataInt = r.Array(4);
            if (a.Pointer(40) != 0) a.RandomDataShort = r.Array(2);
            if (a.Pointer(48) != 0) a.RandomDataByte = r.Array(1);
            if (a.Pointer(56) != 0) a.RandomDataInt = r.Array(4);
            if (a.Pointer(64) != 0) a.Indices = r.Array(a.FrameSize);
            if (a.Pointer(72) != 0)
            {
                a.Notify = r.Array(8);
                for (int i = 0; i < a.NotifyCount; i++)
                {
                    a.NotifyNames.Add(r.String());
                }
            }
            a.Tail = r.Rest();
            return a;
        }

        public byte[] Write()
        {
            var w = new DumpWriter();
            w.Part(DumpPart.Array(Header, 1));
            w.Part(DumpPart.String(Name));
            foreach (var p in BoneNameParts) w.Part(p);
            if (Pointer(16) != 0) w.Part(DataByte);
            if (Pointer(24) != 0) w.Part(DataShort);
            if (Pointer(32) != 0) w.Part(DataInt);
            if (Pointer(40) != 0) w.Part(RandomDataShort);
            if (Pointer(48) != 0) w.Part(RandomDataByte);
            if (Pointer(56) != 0) w.Part(RandomDataInt);
            if (Pointer(64) != 0) w.Part(Indices);
            if (Pointer(72) != 0)
            {
                w.Part(Notify);
                foreach (var p in NotifyNames) w.Part(p);
            }
            w.Write(Tail);
            return w.ToArray();
        }

        static byte[] Bytes(DumpPart p)
        {
            if (p == null || p.Type == DumpPart.TypeOffset || !p.Exists)
            {
                return new byte[0];
            }
            return p.Data;
        }

        // Reads the data streams into tracks, stage by stage as Greyhound's
        // TranslateXAnim does for IW7, and checks that every stream was read
        // to its end and no further. Throws when the animation does not fit.
        public void Decode()
        {
            foreach (var p in new DumpPart[] { DataByte, DataShort, DataInt, RandomDataShort, RandomDataByte, RandomDataInt, Indices })
            {
                if (p != null && p.Type == DumpPart.TypeOffset)
                {
                    throw new EmoteException(Name + " shares a data array with another part; it cannot be checked.");
                }
            }
            var s = new Streams(Bytes(DataByte), Bytes(DataShort), Bytes(DataInt), Bytes(RandomDataShort), Bytes(RandomDataByte), Bytes(Indices), Pointer(64) != 0);
            Rotations.Clear();
            Translations.Clear();
            int frameSize = FrameSize;
            int boneTypeSize = BoneCount(9) > 255 ? 2 : 1;
            int bone = 0;
            for (int kind = 0; kind < 5; kind++)
            {
                for (int i = 0; i < BoneCount(kind); i++, bone++)
                {
                    var t = new RotationTrack();
                    t.Kind = kind;
                    t.Bone = bone;
                    if (kind == 1 || kind == 2)
                    {
                        int per = kind == 1 ? 2 : 4;
                        t.KeyCount = s.Short();
                        t.Inline = ReadInline(s, frameSize, t.KeyCount);
                        t.Keys = s.RandomShorts((t.KeyCount + 1) * per);
                        t.Frames = ReadFrames(s, frameSize, t.KeyCount);
                    }
                    else if (kind == 3 || kind == 4)
                    {
                        t.Keys = s.Shorts(kind == 3 ? 2 : 4);
                    }
                    Rotations.Add(t);
                }
            }
            if (bone != BoneCount(9))
            {
                throw new EmoteException(Name + ": its rotation counts do not add up to its bones.");
            }
            for (int kind = 5; kind < 8; kind++)
            {
                for (int i = 0; i < BoneCount(kind); i++)
                {
                    var t = new TranslationTrack();
                    t.Kind = kind;
                    if (kind == 7)
                    {
                        t.Static = s.Ints(3);
                        t.Bone = boneTypeSize == 1 ? s.Byte() : s.Short();
                    }
                    else
                    {
                        t.Bone = boneTypeSize == 1 ? s.Byte() : s.Short();
                        t.KeyCount = s.Short();
                        t.Inline = ReadInline(s, frameSize, t.KeyCount);
                        t.MinSize = s.Ints(6);
                        if (kind == 5)
                        {
                            var raw = s.RandomBytes((t.KeyCount + 1) * 3);
                            t.Keys = new ushort[raw.Length];
                            for (int k = 0; k < raw.Length; k++) t.Keys[k] = raw[k];
                        }
                        else
                        {
                            var raw = s.RandomShorts((t.KeyCount + 1) * 3);
                            t.Keys = new ushort[raw.Length];
                            for (int k = 0; k < raw.Length; k++) t.Keys[k] = (ushort)raw[k];
                        }
                        t.Frames = ReadFrames(s, frameSize, t.KeyCount);
                    }
                    if (t.Bone >= BoneCount(9))
                    {
                        throw new EmoteException(Name + ": a translation names bone " + t.Bone + " of " + BoneCount(9) + ".");
                    }
                    Translations.Add(t);
                }
            }
            Untranslated = new int[BoneCount(8)];
            for (int i = 0; i < Untranslated.Length; i++)
            {
                Untranslated[i] = boneTypeSize == 1 ? s.Byte() : s.Short();
            }
            string left = s.Leftover();
            if (left != null)
            {
                throw new EmoteException(Name + ": " + left + " " + Counts());
            }
            if (Untranslated.Length > 0)
            {
                // They must be exactly the bones no translation names.
                var seen = new bool[BoneCount(9)];
                foreach (var t in Translations) seen[t.Bone] = true;
                foreach (int b in Untranslated)
                {
                    if (b >= seen.Length || seen[b])
                    {
                        throw new EmoteException(Name + ": the bones listed after its translations are not the bones without one (" + string.Join(" ", Array.ConvertAll(Untranslated, x => x.ToString())) + "). " + Counts());
                    }
                    seen[b] = true;
                }
                foreach (bool b in seen)
                {
                    if (!b) throw new EmoteException(Name + ": some bones have neither a translation nor a place in the list after them. " + Counts());
                }
            }
            if (RandomDataInt != null && Bytes(RandomDataInt).Length > 0)
            {
                throw new EmoteException(Name + " uses randomDataInt, which no IW7 reader reads.");
            }
        }

        public string Counts()
        {
            var c = new string[10];
            for (int i = 0; i < 10; i++) c[i] = BoneCount(i).ToString();
            return "(boneCount " + string.Join(" ", c) + ", numframes " + NumFrames + ")";
        }

        public bool UntranslatedAscending()
        {
            for (int i = 1; i < Untranslated.Length; i++) if (Untranslated[i] <= Untranslated[i - 1]) return false;
            return true;
        }

        ushort[] ReadInline(Streams s, int frameSize, int keyCount)
        {
            if (frameSize != 2 || keyCount < 0x40)
            {
                return null;
            }
            var list = new List<ushort>();
            ushort v;
            do
            {
                v = (ushort)s.Short();
                list.Add(v);
            }
            while (v != NumFrames);
            return list.ToArray();
        }

        int[] ReadFrames(Streams s, int frameSize, int keyCount)
        {
            var frames = new int[keyCount + 1];
            for (int f = 0; f <= keyCount; f++)
            {
                if (frameSize == 1)
                {
                    frames[f] = s.Byte();
                }
                else if (keyCount < 0x40 || !s.HasIndices)
                {
                    frames[f] = s.Short();
                }
                else
                {
                    frames[f] = s.Index();
                }
            }
            return frames;
        }

        // Writes the tracks back into the data streams, in the order Decode
        // reads them. With tracks from Decode the streams are the same bytes.
        public void Encode()
        {
            var s = new StreamWriter2();
            int frameSize = FrameSize;
            int boneTypeSize = BoneCount(9) > 255 ? 2 : 1;
            foreach (var t in Rotations)
            {
                if (t.Kind == 1 || t.Kind == 2)
                {
                    s.Short(t.KeyCount);
                    if (t.Inline != null) foreach (var v in t.Inline) s.Short(v);
                    s.RandomShorts(t.Keys);
                    WriteFrames(s, frameSize, t.KeyCount, t.Frames);
                }
                else if (t.Kind == 3 || t.Kind == 4)
                {
                    foreach (var k in t.Keys) s.Short(k);
                }
            }
            foreach (var t in Translations)
            {
                if (t.Kind == 7)
                {
                    foreach (var v in t.Static) s.Int(v);
                    if (boneTypeSize == 1) s.Byte(t.Bone); else s.Short(t.Bone);
                }
                else
                {
                    if (boneTypeSize == 1) s.Byte(t.Bone); else s.Short(t.Bone);
                    s.Short(t.KeyCount);
                    if (t.Inline != null) foreach (var v in t.Inline) s.Short(v);
                    foreach (var v in t.MinSize) s.Int(v);
                    if (t.Kind == 5)
                    {
                        foreach (var k in t.Keys) s.RandomByte(k);
                    }
                    else
                    {
                        foreach (var k in t.Keys) s.RandomShort(k);
                    }
                    WriteFrames(s, frameSize, t.KeyCount, t.Frames);
                }
            }
            foreach (int b in Untranslated)
            {
                if (boneTypeSize == 1) s.Byte(b); else s.Short(b);
            }
            DataByte = Replace(DataByte, s.DataByte.ToArray(), 1);
            DataShort = Replace(DataShort, s.DataShort.ToArray(), 2);
            DataInt = Replace(DataInt, s.DataInt.ToArray(), 4);
            RandomDataShort = Replace(RandomDataShort, s.RandomDataShort.ToArray(), 2);
            RandomDataByte = Replace(RandomDataByte, s.RandomDataByte.ToArray(), 1);
            Indices = Replace(Indices, s.Indices.ToArray(), frameSize);
        }

        void WriteFrames(StreamWriter2 s, int frameSize, int keyCount, int[] frames)
        {
            foreach (var f in frames)
            {
                if (frameSize == 1) s.Byte(f);
                else if (keyCount < 0x40 || Pointer(64) == 0) s.Short(f);
                else s.Index(f);
            }
        }

        static DumpPart Replace(DumpPart old, byte[] data, int elementSize)
        {
            if (old == null && data.Length == 0)
            {
                return null;
            }
            return DumpPart.Array(data.Length > 0 ? data : null, (uint)(data.Length / elementSize));
        }

        class Streams
        {
            readonly byte[] dataByte, dataShort, dataInt, randomShort, randomByte, indices;
            int pb, ps, pi, prs, prb, px;
            public readonly bool HasIndices;

            public Streams(byte[] db, byte[] ds, byte[] di, byte[] rs, byte[] rb, byte[] ix, bool hasIndices)
            {
                dataByte = db; dataShort = ds; dataInt = di; randomShort = rs; randomByte = rb; indices = ix;
                HasIndices = hasIndices;
            }

            static void Need(byte[] a, int at, int n, string what)
            {
                if (at + n > a.Length)
                {
                    throw new EmoteException("its " + what + " array ends before its tracks do.");
                }
            }

            public int Byte() { Need(dataByte, pb, 1, "dataByte"); return dataByte[pb++]; }
            public int Short() { Need(dataShort, ps, 2, "dataShort"); int v = BitConverter.ToUInt16(dataShort, ps); ps += 2; return v; }
            public int Index() { Need(indices, px, 2, "index"); int v = BitConverter.ToUInt16(indices, px); px += 2; return v; }

            public short[] Shorts(int n)
            {
                Need(dataShort, ps, n * 2, "dataShort");
                var r = new short[n];
                for (int i = 0; i < n; i++) { r[i] = BitConverter.ToInt16(dataShort, ps); ps += 2; }
                return r;
            }

            public int[] Ints(int n)
            {
                Need(dataInt, pi, n * 4, "dataInt");
                var r = new int[n];
                for (int i = 0; i < n; i++) { r[i] = BitConverter.ToInt32(dataInt, pi); pi += 4; }
                return r;
            }

            public short[] RandomShorts(int n)
            {
                Need(randomShort, prs, n * 2, "randomDataShort");
                var r = new short[n];
                for (int i = 0; i < n; i++) { r[i] = BitConverter.ToInt16(randomShort, prs); prs += 2; }
                return r;
            }

            public byte[] RandomBytes(int n)
            {
                Need(randomByte, prb, n, "randomDataByte");
                var r = new byte[n];
                Buffer.BlockCopy(randomByte, prb, r, 0, n);
                prb += n;
                return r;
            }

            public string Leftover()
            {
                var parts = new List<string>();
                if (pb != dataByte.Length) parts.Add("dataByte " + pb + " of " + dataByte.Length);
                if (ps != dataShort.Length) parts.Add("dataShort " + ps + " of " + dataShort.Length);
                if (pi != dataInt.Length) parts.Add("dataInt " + pi + " of " + dataInt.Length);
                if (prs != randomShort.Length) parts.Add("randomDataShort " + prs + " of " + randomShort.Length);
                if (prb != randomByte.Length) parts.Add("randomDataByte " + prb + " of " + randomByte.Length);
                if (px != indices.Length) parts.Add("indices " + px + " of " + indices.Length);
                return parts.Count == 0 ? null : "its tracks do not use all of its data (bytes read: " + string.Join(", ", parts.ToArray()) + ").";
            }
        }

        class StreamWriter2
        {
            public readonly MemoryStream DataByte = new MemoryStream(), DataShort = new MemoryStream(), DataInt = new MemoryStream();
            public readonly MemoryStream RandomDataShort = new MemoryStream(), RandomDataByte = new MemoryStream(), Indices = new MemoryStream();

            public void Byte(int v) { DataByte.WriteByte((byte)v); }
            public void Short(int v) { DataShort.Write(BitConverter.GetBytes((ushort)v), 0, 2); }
            public void Int(int v) { DataInt.Write(BitConverter.GetBytes(v), 0, 4); }
            public void Index(int v) { Indices.Write(BitConverter.GetBytes((ushort)v), 0, 2); }
            public void RandomShort(int v) { RandomDataShort.Write(BitConverter.GetBytes((ushort)v), 0, 2); }
            public void RandomShorts(short[] v) { foreach (var x in v) RandomDataShort.Write(BitConverter.GetBytes(x), 0, 2); }
            public void RandomByte(int v) { RandomDataByte.WriteByte((byte)v); }
        }

        // The last frame each keyed track reaches.
        public int LastKeyedFrame()
        {
            int last = -1;
            foreach (var t in Rotations) if (t.Frames != null && t.Frames.Length > 0) last = Math.Max(last, t.Frames[t.Frames.Length - 1]);
            foreach (var t in Translations) if (t.Frames != null && t.Frames.Length > 0) last = Math.Max(last, t.Frames[t.Frames.Length - 1]);
            return last;
        }

        // A bone's translation at its first key, as Greyhound computes it
        // (min + size * key), or null when the animation does not move it.
        public Vec3? FirstTranslation(string bone)
        {
            int index = Bones.IndexOf(bone);
            foreach (var t in Translations)
            {
                if (t.Bone != index) continue;
                if (t.Kind == 7)
                {
                    return new Vec3(F(t.Static[0]), F(t.Static[1]), F(t.Static[2]));
                }
                return new Vec3(F(t.MinSize[0]) + F(t.MinSize[3]) * t.Keys[0], F(t.MinSize[1]) + F(t.MinSize[4]) * t.Keys[1], F(t.MinSize[2]) + F(t.MinSize[5]) * t.Keys[2]);
            }
            return null;
        }

        static double F(int bits)
        {
            return BitConverter.ToSingle(BitConverter.GetBytes(bits), 0);
        }
    }

    // ---------------------------------------------------------- IW7 models

    public class Rig
    {
        public const int ModelSize = 0x2E0;
        public string Name;
        public string[] Bones;
        public int[] Parents;     // -1 for the root bones
        public Quat[] Rotations;  // model space
        public Vec3[] Positions;  // model space
        public int RootBones;

        public int Find(string bone)
        {
            for (int i = 0; i < Bones.Length; i++)
            {
                if (string.Equals(Bones[i], bone, StringComparison.OrdinalIgnoreCase)) return i;
            }
            return -1;
        }

        public static Rig Read(byte[] file, string what)
        {
            var r = new DumpReader(file, what);
            var head = r.Array(ModelSize);
            if (head.Type != DumpPart.TypeArray || !head.Exists || head.Count != 1)
            {
                throw new EmoteException(what + " is not a model as x64-zt dumps it.");
            }
            byte[] h = head.Data;
            int numBones = h[20], numRoot = h[21], numClient = BitConverter.ToUInt16(h, 24);
            int total = numBones + numClient;
            var rig = new Rig();
            rig.Name = r.String().Text;
            rig.RootBones = numRoot;
            rig.Bones = new string[total];
            for (int i = 0; i < total; i++)
            {
                rig.Bones[i] = r.String().Text ?? "";
            }
            var parents = r.Array(1);
            r.Array(8);   // tagAngles
            r.Array(12);  // tagPositions
            r.Array(1);   // partClassification
            var baseMat = r.Array(32);
            if (total == 0 || numRoot > total || !parents.Exists && total > numRoot || parents.Exists && parents.Count != total - numRoot || !baseMat.Exists || baseMat.Count != total)
            {
                throw new EmoteException(what + ": its bone lists are not as x64-zt's xmodel::dump writes them.");
            }
            rig.Parents = new int[total];
            rig.Rotations = new Quat[total];
            rig.Positions = new Vec3[total];
            for (int i = 0; i < total; i++)
            {
                if (i < numRoot)
                {
                    rig.Parents[i] = -1;
                }
                else
                {
                    int v = parents.Data[i - numRoot];
                    rig.Parents[i] = i < numBones ? i - v : v;
                    if (rig.Parents[i] < 0 || rig.Parents[i] >= i)
                    {
                        throw new EmoteException(what + ": bone " + rig.Bones[i] + " has no parent before it.");
                    }
                }
                byte[] m = baseMat.Data;
                int o = i * 32;
                rig.Rotations[i] = new Quat(BitConverter.ToSingle(m, o), BitConverter.ToSingle(m, o + 4), BitConverter.ToSingle(m, o + 8), BitConverter.ToSingle(m, o + 12)).Normalized();
                rig.Positions[i] = new Vec3(BitConverter.ToSingle(m, o + 16), BitConverter.ToSingle(m, o + 20), BitConverter.ToSingle(m, o + 24));
            }
            return rig;
        }

        public Vec3 LocalPosition(int bone)
        {
            int p = Parents[bone];
            if (p < 0) return Positions[bone];
            return Rotations[p].Conjugate().Rotate(Positions[bone] - Positions[p]);
        }

        public Quat LocalRotation(int bone)
        {
            int p = Parents[bone];
            if (p < 0) return Rotations[bone];
            return (Rotations[p].Conjugate() * Rotations[bone]).Normalized();
        }
    }

    // ----------------------------------------------------------------- FBX

    public class FbxNode
    {
        public string Name;
        public List<object> Props = new List<object>();
        public List<FbxNode> Children = new List<FbxNode>();

        public FbxNode Child(string name)
        {
            foreach (var c in Children) if (c.Name == name) return c;
            return null;
        }

        public List<FbxNode> All(string name)
        {
            var r = new List<FbxNode>();
            foreach (var c in Children) if (c.Name == name) r.Add(c);
            return r;
        }

        // The values of an array node: an ASCII "*N { a: ... }" or a binary
        // array property.
        public object[] Values()
        {
            var a = Child("a");
            if (a != null) return a.Props.ToArray();
            if (Props.Count == 1 && Props[0] is Array)
            {
                var arr = (Array)Props[0];
                var r = new object[arr.Length];
                for (int i = 0; i < r.Length; i++) r[i] = arr.GetValue(i);
                return r;
            }
            return Props.ToArray();
        }
    }

    // ASCII values stay text until read as a number.
    public class FbxToken
    {
        public readonly string Text;
        public FbxToken(string text) { Text = text; }
        public override string ToString() { return Text; }
    }

    public static class Fbx
    {
        public static double Number(object v)
        {
            if (v is FbxToken)
            {
                double d;
                if (double.TryParse(((FbxToken)v).Text, NumberStyles.Float, CultureInfo.InvariantCulture, out d)) return d;
                throw new EmoteException("The FBX file has \"" + v + "\" where a number belongs.");
            }
            if (v is string)
            {
                throw new EmoteException("The FBX file has text where a number belongs.");
            }
            if (v is bool) return (bool)v ? 1 : 0;
            return Convert.ToDouble(v, CultureInfo.InvariantCulture);
        }

        public static long Long(object v)
        {
            if (v is FbxToken)
            {
                long l;
                if (long.TryParse(((FbxToken)v).Text, NumberStyles.Integer, CultureInfo.InvariantCulture, out l)) return l;
                return (long)Number(v);
            }
            if (v is double || v is float) return (long)Number(v);
            return Convert.ToInt64(v, CultureInfo.InvariantCulture);
        }

        // KeyAttrDataFloat: the FBX SDK writes these floats in ASCII files as
        // the integers that share their bits (its own comment line next to
        // each array spells them out), and as floats in binary files.
        public static float FloatBits(object v)
        {
            if (v is FbxToken)
            {
                string t = ((FbxToken)v).Text;
                if (t.IndexOf('.') < 0 && t.IndexOf('e') < 0 && t.IndexOf('E') < 0)
                {
                    int bits = (int)Long(v);
                    return BitConverter.ToSingle(BitConverter.GetBytes(bits), 0);
                }
            }
            return (float)Number(v);
        }

        public static string Text(object v)
        {
            if (v is string) return (string)v;
            if (v is byte[]) return Encoding.UTF8.GetString((byte[])v);
            return v == null ? "" : v.ToString();
        }

        public static FbxNode Load(byte[] data)
        {
            byte[] magic = Encoding.ASCII.GetBytes("Kaydara FBX Binary  ");
            bool binary = data.Length > 27;
            for (int i = 0; binary && i < magic.Length; i++) binary = data[i] == magic[i];
            return binary ? LoadBinary(data) : LoadAscii(Encoding.UTF8.GetString(data));
        }

        // ---- binary (parse_fbx.py)

        static FbxNode LoadBinary(byte[] d)
        {
            int at = 23;
            uint version = BitConverter.ToUInt32(d, at);
            at += 4;
            bool wide = version >= 7500;
            var root = new FbxNode();
            root.Name = "";
            root.Props.Add((long)version);
            while (true)
            {
                var node = ReadBinaryNode(d, ref at, wide);
                if (node == null) break;
                root.Children.Add(node);
            }
            return root;
        }

        static FbxNode ReadBinaryNode(byte[] d, ref int at, bool wide)
        {
            int header = wide ? 25 : 13;
            if (at + header > d.Length) throw new EmoteException("The FBX file ends early.");
            long end = wide ? (long)BitConverter.ToUInt64(d, at) : BitConverter.ToUInt32(d, at);
            long count = wide ? (long)BitConverter.ToUInt64(d, at + 8) : BitConverter.ToUInt32(d, at + 4);
            int nameLength = d[at + header - 1];
            at += header;
            if (end == 0) return null;
            if (end > d.Length) throw new EmoteException("The FBX file has a node past its end.");
            var node = new FbxNode();
            node.Name = Encoding.ASCII.GetString(d, at, nameLength);
            at += nameLength;
            for (long i = 0; i < count; i++)
            {
                node.Props.Add(ReadBinaryProp(d, ref at));
            }
            if (at < end)
            {
                while (at < end - header)
                {
                    var child = ReadBinaryNode(d, ref at, wide);
                    if (child == null) break;
                    node.Children.Add(child);
                }
                at = (int)end;
            }
            return node;
        }

        static object ReadBinaryProp(byte[] d, ref int at)
        {
            char type = (char)d[at++];
            object v;
            switch (type)
            {
                case 'Z': v = (long)(sbyte)d[at]; at += 1; break;
                case 'C': v = d[at] != 0; at += 1; break;
                case 'B': v = d[at] != 0; at += 1; break;
                case 'Y': v = (long)BitConverter.ToInt16(d, at); at += 2; break;
                case 'I': v = (long)BitConverter.ToInt32(d, at); at += 4; break;
                case 'F': v = (double)BitConverter.ToSingle(d, at); at += 4; break;
                case 'D': v = BitConverter.ToDouble(d, at); at += 8; break;
                case 'L': v = BitConverter.ToInt64(d, at); at += 8; break;
                case 'S':
                case 'R':
                    {
                        int n = (int)BitConverter.ToUInt32(d, at);
                        at += 4;
                        var b = new byte[n];
                        Buffer.BlockCopy(d, at, b, 0, n);
                        at += n;
                        v = type == 'S' ? (object)Encoding.UTF8.GetString(b) : b;
                        break;
                    }
                case 'f':
                case 'd':
                case 'l':
                case 'i':
                case 'b':
                case 'c':
                    {
                        int length = (int)BitConverter.ToUInt32(d, at);
                        int encoding = (int)BitConverter.ToUInt32(d, at + 4);
                        int size = (int)BitConverter.ToUInt32(d, at + 8);
                        at += 12;
                        byte[] raw = new byte[size];
                        Buffer.BlockCopy(d, at, raw, 0, size);
                        at += size;
                        if (encoding == 1)
                        {
                            raw = Inflate(raw);
                        }
                        int stride = type == 'd' || type == 'l' ? 8 : type == 'f' || type == 'i' ? 4 : 1;
                        if (raw.Length != length * stride) throw new EmoteException("The FBX file has an array of the wrong size.");
                        if (type == 'f') { var a = new float[length]; Buffer.BlockCopy(raw, 0, a, 0, raw.Length); v = a; }
                        else if (type == 'd') { var a = new double[length]; Buffer.BlockCopy(raw, 0, a, 0, raw.Length); v = a; }
                        else if (type == 'l') { var a = new long[length]; Buffer.BlockCopy(raw, 0, a, 0, raw.Length); v = a; }
                        else if (type == 'i') { var a = new int[length]; Buffer.BlockCopy(raw, 0, a, 0, raw.Length); v = a; }
                        else { v = raw; }
                        break;
                    }
                default:
                    throw new EmoteException("The FBX file has a value of unknown type '" + type + "'.");
            }
            return v;
        }

        // zlib: a 2-byte header, deflate data, a 4-byte checksum.
        static byte[] Inflate(byte[] z)
        {
            if (z.Length < 2) throw new EmoteException("The FBX file has a broken compressed array.");
            using (var input = new MemoryStream(z, 2, z.Length - 2))
            using (var inflater = new DeflateStream(input, CompressionMode.Decompress))
            using (var output = new MemoryStream())
            {
                inflater.CopyTo(output);
                return output.ToArray();
            }
        }

        // ---- ASCII: "Name: value, value {" ... "}", ";" comments.

        static FbxNode LoadAscii(string text)
        {
            var root = new FbxNode();
            root.Name = "";
            var stack = new List<FbxNode>();
            stack.Add(root);
            FbxNode current = null;
            int i = 0, n = text.Length;
            while (i < n)
            {
                char c = text[i];
                if (c == ';')
                {
                    while (i < n && text[i] != '\n') i++;
                    continue;
                }
                if (char.IsWhiteSpace(c) || c == ',')
                {
                    i++;
                    continue;
                }
                if (c == '{')
                {
                    if (current == null) throw new EmoteException("The FBX file has a '{' with no name before it.");
                    stack.Add(current);
                    current = null;
                    i++;
                    continue;
                }
                if (c == '}')
                {
                    if (stack.Count < 2) throw new EmoteException("The FBX file closes more '}' than it opens.");
                    stack.RemoveAt(stack.Count - 1);
                    current = null;
                    i++;
                    continue;
                }
                if (c == '"')
                {
                    int end = text.IndexOf('"', i + 1);
                    if (end < 0) throw new EmoteException("The FBX file ends inside a string.");
                    if (current == null) throw new EmoteException("The FBX file has a value with no name before it.");
                    current.Props.Add(text.Substring(i + 1, end - i - 1));
                    i = end + 1;
                    continue;
                }
                int start = i;
                while (i < n && !char.IsWhiteSpace(text[i]) && text[i] != ',' && text[i] != '{' && text[i] != '}' && text[i] != '"' && text[i] != ':') i++;
                string word = text.Substring(start, i - start);
                if (i < n && text[i] == ':')
                {
                    var node = new FbxNode();
                    node.Name = word;
                    stack[stack.Count - 1].Children.Add(node);
                    current = node;
                    i++;
                    continue;
                }
                if (word.Length == 0)
                {
                    i++;
                    continue;
                }
                if (current == null) throw new EmoteException("The FBX file has \"" + word + "\" outside any node.");
                if (word[0] == '*') continue;   // an array's length; its values follow in "a:"
                current.Props.Add(new FbxToken(word));
            }
            return root;
        }
    }

    // A curve of one value over time, evaluated as the FBX SDK's own
    // attributes say: constant, linear, or cubic with the stored slopes
    // (value per second; user and broken tangents) or, for automatic
    // tangents, slopes through the neighbouring keys.
    public class FbxCurve
    {
        public double[] Times;
        public double[] Values;
        public int[] Flags;
        public double[] RightSlope, NextLeftSlope;
        public double Default;

        public double Evaluate(double t)
        {
            int n = Times == null ? 0 : Times.Length;
            if (n == 0) return Default;
            if (t <= Times[0]) return Values[0];
            if (t >= Times[n - 1]) return Values[n - 1];
            int lo = 0, hi = n - 1;
            while (hi - lo > 1)
            {
                int mid = (lo + hi) / 2;
                if (Times[mid] <= t) lo = mid; else hi = mid;
            }
            double t0 = Times[lo], t1 = Times[hi], v0 = Values[lo], v1 = Values[hi];
            double dt = t1 - t0;
            if (dt <= 0) return v1;
            double u = (t - t0) / dt;
            int flags = Flags[lo];
            if ((flags & 0x02) != 0) return v0;
            if ((flags & 0x08) == 0) return v0 + (v1 - v0) * u;
            double m0, m1;
            if ((flags & 0x400) != 0 || (flags & 0x800) != 0)
            {
                m0 = RightSlope[lo];
                m1 = NextLeftSlope[lo];
            }
            else
            {
                m0 = Slope(lo);
                m1 = Slope(hi);
            }
            double u2 = u * u, u3 = u2 * u;
            return (2 * u3 - 3 * u2 + 1) * v0 + (u3 - 2 * u2 + u) * dt * m0 + (-2 * u3 + 3 * u2) * v1 + (u3 - u2) * dt * m1;
        }

        double Slope(int k)
        {
            int a = Math.Max(0, k - 1), b = Math.Min(Times.Length - 1, k + 1);
            double dt = Times[b] - Times[a];
            return dt <= 0 ? 0 : (Values[b] - Values[a]) / dt;
        }
    }

    public class FbxModel
    {
        public long Id;
        public string Name;
        public FbxModel Parent;
        public Vec3 T, R, S = new Vec3(1, 1, 1), PreRotation, PostRotation, RotationOffset, RotationPivot, ScalingOffset, ScalingPivot;
        public int Order;
        public FbxCurve[] Curves = new FbxCurve[9];   // T xyz, R xyz, S xyz
        public double[] Bind;                         // global, from the bind pose

        public double Channel(int index, double fallback, double t)
        {
            var c = Curves[index];
            return c == null ? fallback : c.Evaluate(t);
        }

        public double[] Local(double t)
        {
            var tr = new Vec3(Channel(0, T.X, t), Channel(1, T.Y, t), Channel(2, T.Z, t));
            var ro = new Vec3(Channel(3, R.X, t), Channel(4, R.Y, t), Channel(5, R.Z, t));
            var sc = new Vec3(Channel(6, S.X, t), Channel(7, S.Y, t), Channel(8, S.Z, t));
            double[] m = Mat4.Translation(tr);
            m = Mat4.Multiply(m, Mat4.Translation(RotationOffset));
            m = Mat4.Multiply(m, Mat4.Translation(RotationPivot));
            m = Mat4.Multiply(m, Mat4.Rotation(PreRotation, 0));
            m = Mat4.Multiply(m, Mat4.Rotation(ro, Order));
            m = Mat4.Multiply(m, Mat4.Transposed3(Mat4.Rotation(PostRotation, 0)));
            m = Mat4.Multiply(m, Mat4.Translation(RotationPivot * -1));
            m = Mat4.Multiply(m, Mat4.Translation(ScalingOffset));
            m = Mat4.Multiply(m, Mat4.Translation(ScalingPivot));
            m = Mat4.Multiply(m, Mat4.Scaling(sc));
            m = Mat4.Multiply(m, Mat4.Translation(ScalingPivot * -1));
            return m;
        }

        public double[] World(double t)
        {
            var m = Local(t);
            return Parent == null ? m : Mat4.Multiply(Parent.World(t), m);
        }
    }

    public class FbxScene
    {
        public Dictionary<string, FbxModel> Models = new Dictionary<string, FbxModel>(StringComparer.OrdinalIgnoreCase);
        public double FramesPerSecond;
        public double Start, End;   // seconds, the keys' range
        public string Notes = "";

        public FbxModel Find(string name)
        {
            FbxModel m;
            return Models.TryGetValue(name, out m) ? m : null;
        }

        static string ModelName(object prop)
        {
            string s = Fbx.Text(prop);
            int binary = s.IndexOf("\u0000\u0001", StringComparison.Ordinal);
            if (binary >= 0) return s.Substring(0, binary);
            int ascii = s.IndexOf("::", StringComparison.Ordinal);
            if (ascii >= 0) s = s.Substring(ascii + 2);
            return s;
        }

        static double[] Rates = { 0, 120, 100, 60, 50, 48, 30, 30, 30 / 1.001, 30 / 1.001, 25, 24, 0, 24 / 1.001, 0, 96, 72, 60 / 1.001, 120 / 1.001 };

        public static FbxScene Read(byte[] data)
        {
            var root = Fbx.Load(data);
            var scene = new FbxScene();
            var objects = root.Child("Objects");
            if (objects == null) throw new EmoteException("The FBX file has no objects.");

            // Time unit (fbx_utils.py FBX_KTIME_V7/V8, import_fbx.py).
            long version = 0;
            var headerExt = root.Child("FBXHeaderExtension");
            if (root.Props.Count > 0) version = Fbx.Long(root.Props[0]);
            if (headerExt != null && headerExt.Child("FBXVersion") != null) version = Fbx.Long(headerExt.Child("FBXVersion").Props[0]);
            double ktime = version >= 8000 ? 141120000.0 : 46186158000.0;
            if (headerExt != null && headerExt.Child("FBXHeaderVersion") != null && Fbx.Long(headerExt.Child("FBXHeaderVersion").Props[0]) >= 1004)
            {
                var other = headerExt.Child("OtherFlags");
                if (other != null && other.Child("TCDefinition") != null)
                {
                    ktime = Fbx.Long(other.Child("TCDefinition").Props[0]) == 127 ? 46186158000.0 : 141120000.0;
                }
            }

            // Frame rate (fbx_utils.py FBX_FRAMERATES).
            double fps = 0;
            var global = root.Child("GlobalSettings");
            if (global != null)
            {
                var gp = Properties(global);
                int mode = gp.ContainsKey("TimeMode") ? (int)Fbx.Long(gp["TimeMode"][0]) : 0;
                if (mode == 14 && gp.ContainsKey("CustomFrameRate")) fps = Fbx.Number(gp["CustomFrameRate"][0]);
                else if (mode > 0 && mode < Rates.Length) fps = Rates[mode];
            }

            var byId = new Dictionary<long, FbxModel>();
            foreach (var node in objects.All("Model"))
            {
                var m = new FbxModel();
                m.Id = Fbx.Long(node.Props[0]);
                m.Name = ModelName(node.Props[1]);
                var p = Properties(node);
                m.T = Vector(p, "Lcl Translation", new Vec3(0, 0, 0));
                m.R = Vector(p, "Lcl Rotation", new Vec3(0, 0, 0));
                m.S = Vector(p, "Lcl Scaling", new Vec3(1, 1, 1));
                m.RotationOffset = Vector(p, "RotationOffset", new Vec3(0, 0, 0));
                m.RotationPivot = Vector(p, "RotationPivot", new Vec3(0, 0, 0));
                m.ScalingOffset = Vector(p, "ScalingOffset", new Vec3(0, 0, 0));
                m.ScalingPivot = Vector(p, "ScalingPivot", new Vec3(0, 0, 0));
                bool active = p.ContainsKey("RotationActive") && Fbx.Long(p["RotationActive"][0]) != 0;
                if (active)
                {
                    m.PreRotation = Vector(p, "PreRotation", new Vec3(0, 0, 0));
                    m.PostRotation = Vector(p, "PostRotation", new Vec3(0, 0, 0));
                    m.Order = p.ContainsKey("RotationOrder") ? (int)Fbx.Long(p["RotationOrder"][0]) : 0;
                }
                byId[m.Id] = m;
                if (!scene.Models.ContainsKey(m.Name)) scene.Models[m.Name] = m;
            }

            var curves = new Dictionary<long, FbxCurve>();
            foreach (var node in objects.All("AnimationCurve"))
            {
                curves[Fbx.Long(node.Props[0])] = ReadCurve(node, ktime);
            }
            var curveNodes = new Dictionary<long, FbxCurve[]>();
            foreach (var node in objects.All("AnimationCurveNode"))
            {
                curveNodes[Fbx.Long(node.Props[0])] = new FbxCurve[3];
            }
            var stackOf = new Dictionary<long, long>();
            var stacks = new List<long>();
            foreach (var node in objects.All("AnimationStack")) stacks.Add(Fbx.Long(node.Props[0]));
            var layers = new Dictionary<long, bool>();
            foreach (var node in objects.All("AnimationLayer")) layers[Fbx.Long(node.Props[0])] = true;

            var connections = root.Child("Connections");
            var links = new List<object[]>();
            if (connections != null)
            {
                foreach (var c in connections.All("C"))
                {
                    if (c.Props.Count < 3) continue;
                    links.Add(new object[] { Fbx.Text(c.Props[0]), Fbx.Long(c.Props[1]), Fbx.Long(c.Props[2]), c.Props.Count > 3 ? Fbx.Text(c.Props[3]) : "" });
                }
            }
            // Which stack each layer and curve node belongs to: the first stack only.
            var layerStack = new Dictionary<long, long>();
            foreach (var l in links)
            {
                long child = (long)l[1], parent = (long)l[2];
                if (layers.ContainsKey(child) && stacks.Contains(parent)) layerStack[child] = parent;
            }
            foreach (var l in links)
            {
                long child = (long)l[1], parent = (long)l[2];
                if (curveNodes.ContainsKey(child) && layerStack.ContainsKey(parent)) stackOf[child] = layerStack[parent];
            }
            long firstStack = stacks.Count > 0 ? stacks[0] : 0;
            if (stacks.Count > 1) scene.Notes += "The FBX file has " + stacks.Count + " animations; the first one is used. ";

            foreach (var l in links)
            {
                string kind = (string)l[0];
                long child = (long)l[1], parent = (long)l[2];
                string prop = (string)l[3];
                if (kind == "OO" && byId.ContainsKey(child) && byId.ContainsKey(parent))
                {
                    byId[child].Parent = byId[parent];
                }
                else if (kind == "OP" && curves.ContainsKey(child) && curveNodes.ContainsKey(parent))
                {
                    int axis = prop.EndsWith("X") ? 0 : prop.EndsWith("Y") ? 1 : prop.EndsWith("Z") ? 2 : -1;
                    if (axis >= 0) curveNodes[parent][axis] = curves[child];
                }
            }
            foreach (var l in links)
            {
                string kind = (string)l[0];
                long child = (long)l[1], parent = (long)l[2];
                string prop = (string)l[3];
                if (kind != "OP" || !curveNodes.ContainsKey(child) || !byId.ContainsKey(parent)) continue;
                long stack;
                if (stacks.Count > 1 && (!stackOf.TryGetValue(child, out stack) || stack != firstStack)) continue;
                int channel = prop == "Lcl Translation" ? 0 : prop == "Lcl Rotation" ? 3 : prop == "Lcl Scaling" ? 6 : -1;
                if (channel < 0) continue;
                for (int a = 0; a < 3; a++)
                {
                    if (curveNodes[child][a] != null) byId[parent].Curves[channel + a] = curveNodes[child][a];
                }
            }

            // Bind pose (global matrices), else the skin clusters' TransformLink.
            foreach (var pose in objects.All("Pose"))
            {
                if (pose.Props.Count < 3 || Fbx.Text(pose.Props[2]) != "BindPose") continue;
                foreach (var pn in pose.All("PoseNode"))
                {
                    var nodeRef = pn.Child("Node");
                    var matrix = pn.Child("Matrix");
                    if (nodeRef == null || matrix == null) continue;
                    FbxModel m;
                    if (byId.TryGetValue(Fbx.Long(nodeRef.Props[0]), out m) && m.Bind == null) m.Bind = Matrix(matrix);
                }
            }
            var clusterLinks = new Dictionary<long, double[]>();
            foreach (var node in objects.All("Deformer"))
            {
                if (node.Props.Count < 3 || Fbx.Text(node.Props[2]) != "Cluster") continue;
                var link = node.Child("TransformLink");
                if (link != null) clusterLinks[Fbx.Long(node.Props[0])] = Matrix(link);
            }
            foreach (var l in links)
            {
                long child = (long)l[1], parent = (long)l[2];
                FbxModel m;
                if (clusterLinks.ContainsKey(parent) && byId.TryGetValue(child, out m) && m.Bind == null) m.Bind = clusterLinks[parent];
            }

            // The keys' time range, and the frame rate from their spacing when
            // the file names none.
            double start = double.MaxValue, end = double.MinValue, step = double.MaxValue;
            foreach (var m in byId.Values)
            {
                foreach (var c in m.Curves)
                {
                    if (c == null || c.Times.Length < 2) continue;
                    start = Math.Min(start, c.Times[0]);
                    end = Math.Max(end, c.Times[c.Times.Length - 1]);
                    for (int k = 1; k < c.Times.Length; k++)
                    {
                        double d = c.Times[k] - c.Times[k - 1];
                        if (d > 1e-6) step = Math.Min(step, d);
                    }
                }
            }
            if (start == double.MaxValue) throw new EmoteException("The FBX file has no animation keys.");
            if (fps <= 0) fps = step < double.MaxValue ? Math.Round(1.0 / step) : 30;
            scene.FramesPerSecond = fps;
            scene.Start = start;
            scene.End = end;
            return scene;
        }

        static double[] Matrix(FbxNode node)
        {
            var v = node.Values();
            if (v.Length != 16) throw new EmoteException("The FBX file has a matrix without 16 values.");
            var m = new double[16];
            for (int i = 0; i < 16; i++) m[i] = Fbx.Number(v[i]);
            return m;
        }

        static FbxCurve ReadCurve(FbxNode node, double ktime)
        {
            var c = new FbxCurve();
            var def = node.Child("Default");
            c.Default = def != null && def.Props.Count > 0 ? Fbx.Number(def.Props[0]) : 0;
            var times = node.Child("KeyTime");
            var values = node.Child("KeyValueFloat");
            if (times == null || values == null)
            {
                c.Times = new double[0];
                c.Values = new double[0];
                return c;
            }
            var tv = times.Values();
            var vv = values.Values();
            int n = Math.Min(tv.Length, vv.Length);
            c.Times = new double[n];
            c.Values = new double[n];
            for (int i = 0; i < n; i++)
            {
                c.Times[i] = Fbx.Long(tv[i]) / ktime;
                c.Values[i] = Fbx.Number(vv[i]);
            }
            c.Flags = new int[n];
            c.RightSlope = new double[n];
            c.NextLeftSlope = new double[n];
            for (int i = 0; i < n; i++) c.Flags[i] = 0x08 | 0x100;
            var flags = node.Child("KeyAttrFlags");
            var attrData = node.Child("KeyAttrDataFloat");
            var refs = node.Child("KeyAttrRefCount");
            if (flags != null && attrData != null && refs != null)
            {
                var fv = flags.Values();
                var dv = attrData.Values();
                var rv = refs.Values();
                int key = 0;
                for (int a = 0; a < fv.Length && a < rv.Length; a++)
                {
                    int f = (int)Fbx.Long(fv[a]);
                    double right = 4 * a < dv.Length ? Fbx.FloatBits(dv[4 * a]) : 0;
                    double nextLeft = 4 * a + 1 < dv.Length ? Fbx.FloatBits(dv[4 * a + 1]) : 0;
                    long count = Fbx.Long(rv[a]);
                    for (long k = 0; k < count && key < n; k++, key++)
                    {
                        c.Flags[key] = f;
                        c.RightSlope[key] = right;
                        c.NextLeftSlope[key] = nextLeft;
                    }
                }
            }
            return c;
        }

        static Dictionary<string, List<object>> Properties(FbxNode node)
        {
            var r = new Dictionary<string, List<object>>();
            var p70 = node.Child("Properties70");
            if (p70 == null) return r;
            foreach (var p in p70.All("P"))
            {
                if (p.Props.Count < 4) continue;
                r[Fbx.Text(p.Props[0])] = p.Props.GetRange(4, p.Props.Count - 4);
            }
            return r;
        }

        static Vec3 Vector(Dictionary<string, List<object>> p, string name, Vec3 fallback)
        {
            List<object> v;
            if (!p.TryGetValue(name, out v) || v.Count < 3) return fallback;
            return new Vec3(Fbx.Number(v[0]), Fbx.Number(v[1]), Fbx.Number(v[2]));
        }
    }

    // ------------------------------------------------------------ the map

    // An IW7 bone, the bone of your rig that drives it, and a pair of child
    // bones (IW7's, yours) whose direction lines the two rest poses up.
    public class BoneLink
    {
        public string Iw, Source, IwChild, SourceChild;
        public string BlendA, BlendB;   // or: halfway between two of your bones

        public BoneLink(string iw, string source, string iwChild, string sourceChild)
        {
            Iw = iw;
            Source = source;
            IwChild = iwChild;
            SourceChild = sourceChild;
        }
    }

    public static class BoneMap
    {
        // Your rig: the names of the humanoid rig DanceMoves.fbx was exported
        // with (Unity, Human_BaseMesh). IW7's names: the bones of the game's
        // own body animations (the Hoff's, as Build Custom Emotes lists
        // them) and of the body model it reads.
        public static List<BoneLink> Humanoid()
        {
            var l = new List<BoneLink>();
            l.Add(new BoneLink("j_mainroot", "hips", null, null));
            l.Add(new BoneLink("j_spinelower", "spine", "j_spine4", "chest"));
            var upper = new BoneLink("j_spineupper", null, null, null);
            upper.BlendA = "spine";
            upper.BlendB = "chest";
            l.Add(upper);
            l.Add(new BoneLink("j_spine4", "chest", "j_neck", "neck"));
            l.Add(new BoneLink("j_neck", "neck", "j_head", "head"));
            l.Add(new BoneLink("j_head", "head", null, null));
            foreach (var side in new string[][] { new string[] { "le", "L" }, new string[] { "ri", "R" } })
            {
                string i = side[0], s = side[1];
                l.Add(new BoneLink("j_shoulder_" + i, "upper_arm_" + s, "j_elbow_" + i, "forearm_" + s));
                l.Add(new BoneLink("j_elbow_" + i, "forearm_" + s, "j_wrist_" + i, "hand_" + s));
                l.Add(new BoneLink("j_wrist_" + i, "hand_" + s, "j_mid_" + i + "_1", "f_middle_01_" + s));
                foreach (var finger in new string[][] { new string[] { "index", "index" }, new string[] { "mid", "middle" }, new string[] { "ring", "ring" }, new string[] { "pinky", "pinky" } })
                {
                    string fi = "j_" + finger[0] + "_" + i + "_", fs = "f_" + finger[1] + "_0";
                    l.Add(new BoneLink(fi + "1", fs + "1_" + s, fi + "2", fs + "2_" + s));
                    l.Add(new BoneLink(fi + "2", fs + "2_" + s, fi + "3", fs + "3_" + s));
                    l.Add(new BoneLink(fi + "3", fs + "3_" + s, null, null));
                }
                l.Add(new BoneLink("j_thumb_" + i + "_2", "thumb_02_" + s, "j_thumb_" + i + "_3", "thumb_03_" + s));
                l.Add(new BoneLink("j_thumb_" + i + "_3", "thumb_03_" + s, null, null));
                l.Add(new BoneLink("j_hip_" + i, "thigh_" + s, "j_knee_" + i, "shin_" + s));
                l.Add(new BoneLink("j_knee_" + i, "shin_" + s, "j_ankle_" + i, "foot_" + s));
                l.Add(new BoneLink("j_ankle_" + i, "foot_" + s, "j_ball_" + i, "toe_" + s));
                l.Add(new BoneLink("j_ball_" + i, "toe_" + s, null, null));
            }
            return l;
        }

        public static readonly string[] Required = {
            "hips", "spine", "chest", "neck", "head",
            "upper_arm_L", "forearm_L", "hand_L", "thigh_L", "shin_L", "foot_L",
            "upper_arm_R", "forearm_R", "hand_R", "thigh_R", "shin_R", "foot_R" };
    }

    // ------------------------------------------------------ the converter

    // What the game's own animations showed about fields this file sets
    // (Build Custom Emotes reads them from the samples x64-zt dumps).
    public class XAnimRules
    {
        public bool LastFrameIsNumFrames = true;     // numframes = keys - 1
        public bool FrequencyPerNumFrames = true;    // frequency = framerate / numframes
        public bool NoneTranslatedCounted = true;    // boneCount[8] = bones without a translation
        public string Notes = "";

        // Learns the rules from sample animations (already decoded); throws
        // when they disagree or match none of the known forms.
        public static XAnimRules Learn(IList<XAnim> samples)
        {
            var r = new XAnimRules();
            int last = 0, lastMinus = 0, freqA = 0, freqB = 0, timed = 0, noneA = 0, noneB = 0, keyed = 0, unordered = 0;
            foreach (var a in samples)
            {
                int n = a.NumFrames;
                int lk = a.LastKeyedFrame();
                if (lk >= 0)
                {
                    keyed++;
                    if (lk == n) last++;
                    else if (lk == n - 1) lastMinus++;
                }
                if (n > 0 && a.Framerate > 0)
                {
                    timed++;
                    double f = a.Frequency;
                    if (Math.Abs(f - a.Framerate / n) <= 1e-4 * Math.Max(1, Math.Abs(f))) freqA++;
                    else if (Math.Abs(f - a.Framerate / (n + 1.0)) <= 1e-4 * Math.Max(1, Math.Abs(f))) freqB++;
                }
                int moved = a.BoneCount(5) + a.BoneCount(6) + a.BoneCount(7);
                if (!a.UntranslatedAscending()) unordered++;
                if (a.BoneCount(8) == a.BoneCount(9) - moved) noneA++;
                else if (a.BoneCount(8) == 0) noneB++;
            }
            int total = samples.Count;
            if (keyed == 0 || last + lastMinus != keyed || last > 0 && lastMinus > 0)
            {
                throw new EmoteException("The game's animations do not agree on where their last frame is (" + last + " end at numframes, " + lastMinus + " one before, of " + keyed + ").");
            }
            r.LastFrameIsNumFrames = last > 0;
            if (timed == 0 || freqA != timed && freqB != timed)
            {
                throw new EmoteException("The game's animations do not show how their frequency is set (" + freqA + " framerate/numframes, " + freqB + " framerate/(numframes+1), of " + timed + ").");
            }
            r.FrequencyPerNumFrames = freqA > 0;
            if (noneA + noneB != total || noneA > 0 && noneB > 0)
            {
                throw new EmoteException("The game's animations do not show how they count bones without a translation.");
            }
            r.NoneTranslatedCounted = noneA > 0;
            if (unordered > 0)
            {
                throw new EmoteException(unordered + " of the game's animations list their bones without a translation out of order; the converter writes them in order.");
            }
            r.Notes = "last frame " + (r.LastFrameIsNumFrames ? "= numframes" : "= numframes - 1") + " (" + keyed + " of " + total + " samples keyed); frequency = framerate / " + (r.FrequencyPerNumFrames ? "numframes" : "(numframes + 1)") + "; boneCount[8] " + (r.NoneTranslatedCounted ? "= bones without a translation, listed in order after the translations" : "= 0");
            return r;
        }
    }

    public class EmoteResult
    {
        public byte[] Xab;
        public int Frames;
        public double Framerate;
        public double Seconds;
        public string[] Mapped;
        public string[] Unused;     // your bones that drive nothing
        public string[] MissingInRig;
        public string Report;
    }

    public static class Converter
    {
        // Byte-for-byte check of the reader and writer on one of the game's
        // animations: null when it reads and writes back identically, else
        // the reason.
        public static string RoundTrip(byte[] file, string what)
        {
            XAnim a;
            try
            {
                a = XAnim.Read(file, what);
                if (!new DumpWriterCheck(a, file).Same) return "the file does not write back as it was read";
                a.Decode();
                a.Encode();
            }
            catch (EmoteException e)
            {
                return e.Message;
            }
            byte[] again = a.Write();
            if (again.Length != file.Length) return "written back it has " + again.Length + " bytes instead of " + file.Length;
            for (int i = 0; i < file.Length; i++)
            {
                if (again[i] != file[i]) return "written back it differs at byte " + i;
            }
            return null;
        }

        class DumpWriterCheck
        {
            public readonly bool Same;

            public DumpWriterCheck(XAnim a, byte[] file)
            {
                byte[] w = a.Write();
                Same = w.Length == file.Length;
                for (int i = 0; Same && i < w.Length; i++) Same = w[i] == file[i];
            }
        }

        public static XAnim ReadDecoded(byte[] file, string what)
        {
            var a = XAnim.Read(file, what);
            a.Decode();
            return a;
        }

        // How a sample animation's translations at its first frame compare
        // with the rig's rest pose: the share of bones whose direction from
        // their parent agrees (within 18 degrees). A check that the two are
        // read the same way; the animation may be of another character.
        public static string CompareWithRig(XAnim a, Rig rig, out double agree)
        {
            int compared = 0, same = 0;
            var ratios = new List<double>();
            foreach (var bone in a.Bones)
            {
                if (!bone.StartsWith("j_") || bone == "j_mainroot") continue;
                int b = rig.Find(bone);
                if (b < 0 || rig.Parents[b] < 0) continue;
                Vec3? t = a.FirstTranslation(bone);
                if (!t.HasValue) continue;
                Vec3 rest = rig.LocalPosition(b);
                if (rest.Length < 0.5 || t.Value.Length < 0.5) continue;
                compared++;
                if (Vec3.Dot(rest.Normalized(), t.Value.Normalized()) > 0.95) same++;
                ratios.Add(t.Value.Length / rest.Length);
            }
            agree = compared == 0 ? 0 : (double)same / compared;
            ratios.Sort();
            string median = ratios.Count == 0 ? "-" : ratios[ratios.Count / 2].ToString("0.000", CultureInfo.InvariantCulture);
            return same + " of " + compared + " bones point the same way, median length ratio " + median;
        }

        // A character frame: forward, left and up of a skeleton in its rest
        // pose, from its hips, head and left and right thighs. Snapped to the
        // file's own axes when it is within 15 degrees of them.
        static Vec3[] Frame(Vec3 hips, Vec3 head, Vec3 leftHip, Vec3 rightHip)
        {
            Vec3 up = (head - hips).Normalized();
            Vec3 left = leftHip - rightHip;
            left = (left - up * Vec3.Dot(left, up)).Normalized();
            Vec3 forward = Vec3.Cross(left, up).Normalized();
            if (up.Length < 0.5 || left.Length < 0.5) throw new EmoteException("The rest pose has no clear up or left (hips, head, thighs).");
            Vec3 su = Snap(up), sl = Snap(left);
            if (su.Length > 0.5 && sl.Length > 0.5 && Math.Abs(Vec3.Dot(su, sl)) < 0.5)
            {
                up = su;
                left = sl;
                forward = Vec3.Cross(left, up);
            }
            return new Vec3[] { forward, left, up };
        }

        static Vec3 Snap(Vec3 v)
        {
            Vec3[] axes = { new Vec3(1, 0, 0), new Vec3(0, 1, 0), new Vec3(0, 0, 1) };
            foreach (var a in axes)
            {
                double d = Vec3.Dot(v, a);
                if (d > 0.9659) return a;
                if (d < -0.9659) return a * -1;
            }
            return new Vec3(0, 0, 0);
        }

        // The rotation that takes a vector from one frame to the other.
        static Quat Between(Vec3[] from, Vec3[] to)
        {
            // R = To * From^T, as columns.
            Vec3 c0 = to[0] * from[0].X + to[1] * from[1].X + to[2] * from[2].X;
            Vec3 c1 = to[0] * from[0].Y + to[1] * from[1].Y + to[2] * from[2].Y;
            Vec3 c2 = to[0] * from[0].Z + to[1] * from[1].Z + to[2] * from[2].Z;
            return Quat.FromColumns(c0, c1, c2);
        }

        public static EmoteResult Convert(byte[] fbx, byte[] rigFile, byte[] templateFile, string assetName, bool loop, XAnimRules rules)
        {
            var scene = FbxScene.Read(fbx);
            var rig = Rig.Read(rigFile, "the body model");
            var template = XAnim.Read(templateFile, "the sample animation");
            return Convert(scene, rig, template, assetName, loop, rules);
        }

        public static EmoteResult Convert(FbxScene scene, Rig rig, XAnim template, string assetName, bool loop, XAnimRules rules)
        {
            var report = new StringBuilder();
            report.Append(scene.Notes);
            var links = BoneMap.Humanoid();

            var missing = new List<string>();
            foreach (var name in BoneMap.Required) if (scene.Find(name) == null) missing.Add(name);
            if (missing.Count > 0)
            {
                throw new EmoteException("The animation's rig lacks " + string.Join(", ", missing.ToArray()) + " (the bone names Build Custom Emotes knows are listed in installer\\IXEmoteConvert.cs BoneMap).");
            }
            var hipsModel = scene.Find("hips");

            // Frames: one per frame of the file, at most 256 (frame indices of
            // one byte, as xanim.cpp writes animations of fewer than 256
            // frames); a longer animation is played at a lower frame rate.
            double fps = scene.FramesPerSecond;
            double length = scene.End - scene.Start;
            int frames = (int)Math.Round(length * fps) + 1;
            if (frames < 2)
            {
                throw new EmoteException("The animation is shorter than two frames.");
            }
            if (frames > 256)
            {
                fps = 255.0 / length;
                frames = 256;
                report.Append("Longer than 256 frames: played at " + fps.ToString("0.###", CultureInfo.InvariantCulture) + " frames per second. ");
            }
            var times = new double[frames];
            for (int f = 0; f < frames; f++) times[f] = scene.Start + f / fps;
            if (times[frames - 1] > scene.End) times[frames - 1] = scene.End;

            // Your skeleton's space: relative to the hips' parent, whose
            // transform is the same at bind time and while animated.
            var skeleton = hipsModel.Parent;
            Func<double, double[]> skeletonAt = t => skeleton == null ? Mat4.Identity() : Mat4.InverseAffine(skeleton.World(t));
            double[] skeletonBind = skeleton == null ? Mat4.Identity() : Mat4.InverseAffine(skeleton.Bind ?? skeleton.World(times[0]));

            var sourceNames = new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase);
            foreach (var link in links)
            {
                if (link.Source != null) sourceNames[link.Source] = true;
                if (link.SourceChild != null) sourceNames[link.SourceChild] = true;
                if (link.BlendA != null) { sourceNames[link.BlendA] = true; sourceNames[link.BlendB] = true; }
            }
            var bindRot = new Dictionary<string, Quat>(StringComparer.OrdinalIgnoreCase);
            var bindPos = new Dictionary<string, Vec3>(StringComparer.OrdinalIgnoreCase);
            var noBind = new List<string>();
            foreach (var name in sourceNames.Keys)
            {
                var m = scene.Find(name);
                if (m == null) continue;
                double[] g = m.Bind;
                if (g == null)
                {
                    noBind.Add(name);
                    g = m.World(times[0]);
                }
                double[] rel = Mat4.Multiply(skeletonBind, g);
                bindRot[name] = Mat4.RotationOf(rel);
                bindPos[name] = Mat4.Position(rel);
            }
            if (noBind.Count > 0) report.Append("No bind pose for " + string.Join(", ", noBind.ToArray()) + ": their first frame is used as rest. ");

            // The two character frames, and the turn from yours to IW7's.
            int iHips = rig.Find("j_mainroot"), iHead = rig.Find("j_head"), iHipL = rig.Find("j_hip_le"), iHipR = rig.Find("j_hip_ri");
            if (iHips < 0 || iHead < 0 || iHipL < 0 || iHipR < 0)
            {
                throw new EmoteException("The body model lacks j_mainroot, j_head, j_hip_le or j_hip_ri.");
            }
            Vec3[] srcFrame = Frame(bindPos["hips"], bindPos["head"], bindPos["thigh_L"], bindPos["thigh_R"]);
            Vec3[] iwFrame = Frame(rig.Positions[iHips], rig.Positions[iHead], rig.Positions[iHipL], rig.Positions[iHipR]);
            Quat turn = Between(srcFrame, iwFrame);
            report.Append("Your rig faces " + Show(srcFrame[0]) + " with up " + Show(srcFrame[2]) + "; the body model faces " + Show(iwFrame[0]) + " with up " + Show(iwFrame[2]) + ". ");
            Vec3 toeL = bindPos.ContainsKey("toe_L") ? bindPos["toe_L"] : bindPos["foot_L"];
            if (bindPos.ContainsKey("toe_L") && Vec3.Dot(toeL - bindPos["foot_L"], srcFrame[0]) <= 0)
            {
                throw new EmoteException("The animation's toes point backwards from where its left side says it faces; its left and right bones may be swapped.");
            }

            // Per IW7 bone: the bone of yours driving it and the rest pose
            // alignment (the turn that points it the way yours points).
            int count = rig.Bones.Length;
            var link0 = new BoneLink[count];
            var align = new Quat[count];
            var driven = new bool[count];
            var mapped = new List<string>();
            var missingInRig = new List<string>();
            foreach (var link in links)
            {
                int b = rig.Find(link.Iw);
                bool present = link.Source != null ? scene.Find(link.Source) != null : scene.Find(link.BlendA) != null && scene.Find(link.BlendB) != null;
                if (!present) continue;
                if (b < 0)
                {
                    missingInRig.Add(link.Iw);
                    continue;
                }
                link0[b] = link;
                driven[b] = true;
                mapped.Add(link.Iw + "<-" + (link.Source ?? (link.BlendA + "+" + link.BlendB)));
            }
            for (int b = 0; b < count; b++)
            {
                align[b] = Quat.Identity;
                var link = link0[b];
                if (link == null) continue;
                int child = link.IwChild == null ? -1 : rig.Find(link.IwChild);
                if (link.Source != null && child >= 0 && bindPos.ContainsKey(link.SourceChild ?? ""))
                {
                    Vec3 iwDir = rig.Positions[child] - rig.Positions[b];
                    Vec3 srcDir = turn.Rotate(bindPos[link.SourceChild] - bindPos[link.Source]);
                    align[b] = Quat.FromTo(iwDir, srcDir);
                }
                else if (link.Source != null && link.Iw != "j_mainroot")
                {
                    // No direction of its own: the alignment of the nearest
                    // driven bone above it, so it keeps its place there.
                    for (int p = rig.Parents[b]; p >= 0; p = rig.Parents[p])
                    {
                        if (driven[p])
                        {
                            align[b] = align[p];
                            break;
                        }
                    }
                }
            }
            for (int b = 0; b < count; b++)
            {
                var link = link0[b];
                if (link == null || link.Source != null) continue;
                int a = FindLinked(rig, link0, link.BlendA), c = FindLinked(rig, link0, link.BlendB);
                align[b] = Quat.Slerp(a >= 0 ? align[a] : Quat.Identity, c >= 0 ? align[c] : Quat.Identity, 0.5);
            }

            // Your bones' rotations over time, as turns from their rest pose,
            // in IW7's model space.
            var delta = new Dictionary<string, Quat[]>(StringComparer.OrdinalIgnoreCase);
            var hipsAt = new Vec3[frames];
            var posAt = new Dictionary<string, Vec3[]>(StringComparer.OrdinalIgnoreCase);
            foreach (var name in bindRot.Keys)
            {
                var m = scene.Find(name);
                var d = new Quat[frames];
                var p = new Vec3[frames];
                posAt[name] = p;
                Quat restInv = bindRot[name].Conjugate();
                for (int f = 0; f < frames; f++)
                {
                    double[] rel = Mat4.Multiply(skeletonAt(times[f]), m.World(times[f]));
                    Quat world = Mat4.RotationOf(rel);
                    d[f] = (turn * (world * restInv) * turn.Conjugate()).Normalized();
                    p[f] = turn.Rotate(Mat4.Position(rel));
                    if (string.Equals(name, "hips", StringComparison.OrdinalIgnoreCase)) hipsAt[f] = p[f];
                }
                delta[name] = d;
            }

            // IW7's bones, parents first: driven bones turn as yours do from
            // their aligned rest pose; the others keep their rest pose under
            // their parent.
            var world0 = new Quat[count][];
            var local = new Quat[count][];
            for (int b = 0; b < count; b++)
            {
                world0[b] = new Quat[frames];
                int p = rig.Parents[b];
                var link = link0[b];
                for (int f = 0; f < frames; f++)
                {
                    Quat parent = p < 0 ? Quat.Identity : world0[p][f];
                    if (link == null)
                    {
                        world0[b][f] = p < 0 ? rig.Rotations[b] : (parent * rig.LocalRotation(b)).Normalized();
                        continue;
                    }
                    Quat d = link.Source != null ? delta[link.Source][f] : Quat.Slerp(delta[link.BlendA][f], delta[link.BlendB][f], 0.5);
                    world0[b][f] = (d * align[b] * rig.Rotations[b]).Normalized();
                }
                if (link == null) continue;
                local[b] = new Quat[frames];
                for (int f = 0; f < frames; f++)
                {
                    Quat parent = p < 0 ? Quat.Identity : world0[p][f];
                    Quat q = (parent.Conjugate() * world0[b][f]).Normalized();
                    if (f == 0 ? q.W < 0 : Quat.Dot(q, local[b][f - 1]) < 0) q = q.Negated();
                    local[b][f] = q;
                }
            }

            // The hips' height and sway, scaled from your rig to the body
            // model (heights above the lowest driven bone of each), centred
            // on where the animation starts.
            double groundSrc = double.MaxValue, groundIw = double.MaxValue;
            foreach (var v in bindPos.Values) groundSrc = Math.Min(groundSrc, Vec3.Dot(turn.Rotate(v), iwFrame[2]));
            for (int b = 0; b < count; b++) if (driven[b]) groundIw = Math.Min(groundIw, Vec3.Dot(rig.Positions[b], iwFrame[2]));
            Vec3 hipsBind = turn.Rotate(bindPos["hips"]);
            double srcHeight = Vec3.Dot(hipsBind, iwFrame[2]) - groundSrc;
            double iwHeight = Vec3.Dot(rig.Positions[iHips], iwFrame[2]) - groundIw;
            if (srcHeight <= 0.001 || iwHeight <= 0.001) throw new EmoteException("The hips are not above the feet in the rest pose.");
            double scale = iwHeight / srcHeight;
            Vec3 start = (hipsAt[0] - hipsBind) * scale;
            start = start - iwFrame[2] * Vec3.Dot(start, iwFrame[2]);
            int hipsParent = rig.Parents[iHips];
            var hipsLocal = new Vec3[frames];
            for (int f = 0; f < frames; f++)
            {
                Vec3 pos = rig.Positions[iHips] + (hipsAt[f] - hipsBind) * scale - start;
                if (hipsParent >= 0)
                {
                    if (driven[hipsParent]) throw new EmoteException("j_mainroot's parent is animated; its position cannot be set.");
                    pos = rig.Rotations[hipsParent].Conjugate().Rotate(pos - rig.Positions[hipsParent]);
                }
                hipsLocal[f] = pos;
            }

            // Feet on the floor: the hips are raised or lowered on every frame
            // so the lowest foot bone is as high above the body model's floor
            // as yours is above your animation's lowest point (where your feet
            // touch the ground), scaled. Taken from the feet, not the hips'
            // own height, which in game left the body floating (0.14.7 report).
            var srcFeet = new List<string>();
            foreach (var n in new string[] { "foot_L", "toe_L", "foot_R", "toe_R" }) if (posAt.ContainsKey(n)) srcFeet.Add(n);
            var iwFeet = new List<int>();
            foreach (var n in new string[] { "j_ankle_le", "j_ball_le", "j_ankle_ri", "j_ball_ri" })
            {
                int b = rig.Find(n);
                if (b >= 0) iwFeet.Add(b);
            }
            if (srcFeet.Count > 0 && iwFeet.Count > 0)
            {
                var srcLow = new double[frames];
                double srcGround = double.MaxValue;
                for (int f = 0; f < frames; f++)
                {
                    srcLow[f] = double.MaxValue;
                    foreach (var n in srcFeet) srcLow[f] = Math.Min(srcLow[f], Vec3.Dot(posAt[n][f], iwFrame[2]));
                    srcGround = Math.Min(srcGround, srcLow[f]);
                }
                double iwFloor = double.MaxValue;
                foreach (int b in iwFeet) iwFloor = Math.Min(iwFloor, Vec3.Dot(rig.Positions[b], iwFrame[2]));
                double lowest = double.MaxValue, highest = double.MinValue;
                for (int f = 0; f < frames; f++)
                {
                    var world = Positions(rig, world0, iHips, hipsLocal[f], f);
                    double low = double.MaxValue;
                    foreach (int b in iwFeet) low = Math.Min(low, Vec3.Dot(world[b], iwFrame[2]));
                    double lift = iwFloor + scale * (srcLow[f] - srcGround) - low;
                    Vec3 up = hipsParent >= 0 ? rig.Rotations[hipsParent].Conjugate().Rotate(iwFrame[2]) : iwFrame[2];
                    hipsLocal[f] = hipsLocal[f] + up * lift;
                    lowest = Math.Min(lowest, lift);
                    highest = Math.Max(highest, lift);
                }
                report.Append("Feet put on the floor: the hips moved by " + lowest.ToString("0.#", CultureInfo.InvariantCulture) + " to " + highest.ToString("0.#", CultureInfo.InvariantCulture) + " units. ");
            }
            report.Append("Hips scaled by " + scale.ToString("0.###", CultureInfo.InvariantCulture) + ". ");

            // The animation: every driven bone a 3D rotation keyed on every
            // frame, j_mainroot also a precise (16-bit) translation.
            var anim = new XAnim();
            anim.Header = (byte[])template.Header.Clone();
            anim.Name = assetName;
            var order = new List<int>();
            for (int b = 0; b < count; b++) if (local[b] != null) order.Add(b);
            int hipsIndex = order.IndexOf(iHips);
            int numFrames = rules.LastFrameIsNumFrames ? frames - 1 : frames;
            foreach (int b in order)
            {
                anim.BoneNameParts.Add(DumpPart.String(rig.Bones[b]));
                anim.Bones.Add(rig.Bones[b]);
                var t = new RotationTrack();
                t.Kind = 2;
                t.Bone = anim.Bones.Count - 1;
                t.KeyCount = frames - 1;
                t.Frames = new int[frames];
                t.Keys = new short[frames * 4];
                for (int f = 0; f < frames; f++)
                {
                    t.Frames[f] = f;
                    Quat q = local[b][f];
                    t.Keys[f * 4] = Short(q.X);
                    t.Keys[f * 4 + 1] = Short(q.Y);
                    t.Keys[f * 4 + 2] = Short(q.Z);
                    t.Keys[f * 4 + 3] = Short(q.W);
                }
                anim.Rotations.Add(t);
            }
            if (hipsIndex >= 0)
            {
                var t = new TranslationTrack();
                t.Kind = 6;
                t.Bone = hipsIndex;
                t.KeyCount = frames - 1;
                t.Frames = new int[frames];
                t.Keys = new ushort[frames * 3];
                double[] min = { double.MaxValue, double.MaxValue, double.MaxValue }, max = { double.MinValue, double.MinValue, double.MinValue };
                for (int f = 0; f < frames; f++)
                {
                    double[] v = { hipsLocal[f].X, hipsLocal[f].Y, hipsLocal[f].Z };
                    for (int k = 0; k < 3; k++) { min[k] = Math.Min(min[k], v[k]); max[k] = Math.Max(max[k], v[k]); }
                }
                var minF = new float[3];
                var sizeF = new float[3];
                for (int k = 0; k < 3; k++)
                {
                    minF[k] = (float)min[k];
                    sizeF[k] = (float)((max[k] - minF[k]) / 65535.0);
                }
                t.MinSize = new int[6];
                for (int k = 0; k < 3; k++)
                {
                    t.MinSize[k] = BitConverter.ToInt32(BitConverter.GetBytes(minF[k]), 0);
                    t.MinSize[3 + k] = BitConverter.ToInt32(BitConverter.GetBytes(sizeF[k]), 0);
                }
                for (int f = 0; f < frames; f++)
                {
                    t.Frames[f] = f;
                    double[] v = { hipsLocal[f].X, hipsLocal[f].Y, hipsLocal[f].Z };
                    for (int k = 0; k < 3; k++)
                    {
                        double key = sizeF[k] > 0 ? Math.Round((v[k] - minF[k]) / sizeF[k]) : 0;
                        t.Keys[f * 3 + k] = (ushort)Math.Max(0, Math.Min(65535, key));
                    }
                }
                anim.Translations.Add(t);
            }

            if (rules.NoneTranslatedCounted)
            {
                var still = new List<int>();
                for (int i = 0; i < anim.Bones.Count; i++) if (i != hipsIndex) still.Add(i);
                anim.Untranslated = still.ToArray();
            }
            byte[] h = anim.Header;
            int bones = anim.Bones.Count;
            if (bones > 255) throw new EmoteException("More than 255 bones.");
            SetPointer(h, 8, bones > 0);
            anim.Encode();
            SetPointer(h, 16, anim.DataByte != null);
            SetPointer(h, 24, anim.DataShort != null);
            SetPointer(h, 32, anim.DataInt != null);
            SetPointer(h, 40, anim.RandomDataShort != null);
            SetPointer(h, 48, false);
            SetPointer(h, 56, false);
            SetPointer(h, 64, false);
            SetPointer(h, 72, false);
            SetPointer(h, 80, false);
            anim.RandomDataByte = null;
            anim.Indices = null;
            anim.Notify = null;
            anim.Tail = new byte[0];
            Put(h, 88, BitConverter.GetBytes((uint)(anim.RandomDataShort == null ? 0 : anim.RandomDataShort.Count)));
            Put(h, 92, BitConverter.GetBytes((uint)0));
            Put(h, 96, BitConverter.GetBytes((uint)0));
            Put(h, 100, BitConverter.GetBytes((float)fps));
            Put(h, 104, BitConverter.GetBytes((float)(fps / (rules.FrequencyPerNumFrames ? numFrames : numFrames + 1.0))));
            Put(h, 108, BitConverter.GetBytes(Count16(anim.DataByte, "dataByte")));
            Put(h, 110, BitConverter.GetBytes(Count16(anim.DataShort, "dataShort")));
            Put(h, 112, BitConverter.GetBytes(Count16(anim.DataInt, "dataInt")));
            Put(h, 114, BitConverter.GetBytes((ushort)0));
            Put(h, 116, BitConverter.GetBytes((ushort)numFrames));
            h[118] = (byte)(loop ? 1 : 0);
            int moved = anim.Translations.Count;
            byte[] counts = { 0, 0, (byte)bones, 0, 0, 0, (byte)moved, 0, (byte)(rules.NoneTranslatedCounted ? bones - moved : 0), (byte)bones };
            Buffer.BlockCopy(counts, 0, h, 119, 10);
            h[129] = 0;

            // Read back with the same reader the game's animations passed.
            byte[] file = anim.Write();
            var check = ReadDecoded(file, assetName);
            if (check.Bones.Count != bones || check.LastKeyedFrame() != (rules.LastFrameIsNumFrames ? check.NumFrames : check.NumFrames - 1))
            {
                throw new EmoteException("The new animation does not read back as written.");
            }

            // Your animated bones that drive nothing (not the nodes above the
            // hips, which only place the skeleton).
            var above = new Dictionary<FbxModel, bool>();
            for (var m = hipsModel.Parent; m != null; m = m.Parent) above[m] = true;
            var unused = new List<string>();
            foreach (var name in scene.Models.Keys)
            {
                var m = scene.Models[name];
                if (!sourceNames.ContainsKey(name) && !above.ContainsKey(m) && m.Curves[3] != null) unused.Add(name);
            }
            var result = new EmoteResult();
            result.Xab = file;
            result.Frames = frames;
            result.Framerate = fps;
            result.Seconds = (frames - 1) / fps;
            result.Mapped = mapped.ToArray();
            result.Unused = unused.ToArray();
            result.MissingInRig = missingInRig.ToArray();
            result.Report = report.ToString().Trim();
            return result;
        }

        // Every bone's model-space position at a frame: the rig's rest
        // offsets turned by the parents' rotations, j_mainroot at its
        // animated place.
        static Vec3[] Positions(Rig rig, Quat[][] world, int hips, Vec3 hipsLocal, int frame)
        {
            var pos = new Vec3[rig.Bones.Length];
            for (int b = 0; b < pos.Length; b++)
            {
                int p = rig.Parents[b];
                Vec3 offset = b == hips ? hipsLocal : rig.LocalPosition(b);
                if (p < 0)
                {
                    pos[b] = b == hips ? hipsLocal : rig.Positions[b];
                    continue;
                }
                pos[b] = pos[p] + world[p][frame].Rotate(offset);
            }
            return pos;
        }

        static int FindLinked(Rig rig, BoneLink[] links, string source)
        {
            for (int b = 0; b < links.Length; b++)
            {
                if (links[b] != null && string.Equals(links[b].Source, source, StringComparison.OrdinalIgnoreCase)) return b;
            }
            return -1;
        }

        static string Show(Vec3 v)
        {
            return "(" + v.X.ToString("0.##", CultureInfo.InvariantCulture) + ", " + v.Y.ToString("0.##", CultureInfo.InvariantCulture) + ", " + v.Z.ToString("0.##", CultureInfo.InvariantCulture) + ")";
        }

        // Quaternion parts as stored: value * 32767 (x64-zt QuatInt16::ToInt16;
        // Greyhound reads them back / 32768).
        static short Short(double v)
        {
            double s = Math.Round(v * 32767.0);
            return (short)Math.Max(-32767, Math.Min(32767, s));
        }

        static ushort Count16(DumpPart p, string what)
        {
            long n = p == null ? 0 : p.Count;
            if (n > 65535) throw new EmoteException("The animation's " + what + " array is too long for IW7 (" + n + " values).");
            return (ushort)n;
        }

        static void SetPointer(byte[] h, int offset, bool present)
        {
            ulong old = BitConverter.ToUInt64(h, offset);
            ulong v = present ? (old != 0 ? old : 1UL) : 0UL;
            Put(h, offset, BitConverter.GetBytes(v));
        }

        static void Put(byte[] h, int offset, byte[] v)
        {
            Buffer.BlockCopy(v, 0, h, offset, v.Length);
        }
    }
}
