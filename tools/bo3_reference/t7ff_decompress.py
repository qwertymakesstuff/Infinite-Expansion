"""Decompress a BO3 (T7) PC fastfile to a raw zone stream.

Observed layout (AAE package): a 0x248-byte XFile header, then blocks of
    uint32 compressedSize, uint32 decompressedSize, uint32 alignedSize, uint32 fileOffset
where fileOffset equals the header's own position in the file, followed by a
zlib stream.  Some regions are not framed this way (raw/streamed data); they
are located by scanning for the next self-referencing block header and are
copied through verbatim (and reported).

Usage: python -I t7ff_decompress.py <in.ff> <out.zone>
"""
import struct
import sys
import zlib

HEADER_SIZE = 0x248
BLOCK = struct.Struct("<IIII")


def is_block_header(data, pos):
    if pos + BLOCK.size > len(data):
        return False
    comp, decomp, aligned, offset = BLOCK.unpack_from(data, pos)
    return offset == pos and 0 < comp <= aligned < comp + 64 and aligned < 0x1000000


def next_block_header(data, start):
    for pos in range(start, len(data) - BLOCK.size):
        if is_block_header(data, pos):
            return pos
    return len(data)


def main():
    src, dst = sys.argv[1], sys.argv[2]
    with open(src, "rb") as handle:
        data = handle.read()
    pos = HEADER_SIZE
    zlib_blocks = stored_blocks = 0
    raw_regions = []
    written = 0
    with open(dst, "wb") as out:
        while pos < len(data):
            if not is_block_header(data, pos):
                nxt = next_block_header(data, pos)
                raw_regions.append((pos, nxt - pos))
                out.write(data[pos:nxt])
                written += nxt - pos
                pos = nxt
                continue
            comp, decomp, aligned, _ = BLOCK.unpack_from(data, pos)
            payload = data[pos + BLOCK.size:pos + BLOCK.size + comp]
            if decomp == 0:
                chunk = payload
                stored_blocks += 1
            else:
                chunk = zlib.decompress(payload)
                if len(chunk) != decomp:
                    raise SystemExit(f"block at 0x{pos:X}: size mismatch")
                zlib_blocks += 1
            out.write(chunk)
            written += len(chunk)
            pos += BLOCK.size + aligned
    print(f"{src}: zlib blocks={zlib_blocks} stored blocks={stored_blocks} "
          f"raw regions={len(raw_regions)} ({sum(n for _, n in raw_regions)} bytes) -> {written} bytes")
    for start, size in raw_regions[:8]:
        print(f"  raw region at 0x{start:X}, {size} bytes")


if __name__ == "__main__":
    main()
