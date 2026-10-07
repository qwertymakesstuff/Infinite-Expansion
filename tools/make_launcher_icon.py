#!/usr/bin/env python3
"""Writes installer/ix-launcher.ico, the icon the setup builds into
"Infinite Expansion.exe", from installer/ix.ico.

ix.ico stores its images as PNG, which the setup window and Windows Settings
show fine. The C# compiler that comes with Windows (.NET Framework 4, C# 5) is
older and may refuse PNG images in /win32icon, so the launcher's icon stores
the same images as classic 32-bit bitmaps, each with its transparency mask.
The 256 px image is left out: as a bitmap it alone would take 260 KB.

Needs Pillow. Usage: python3 tools/make_launcher_icon.py [source.ico] [target.ico]
tools/tests/test_installer.py checks that the committed file matches.
"""

import io
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "installer" / "ix.ico"
TARGET = ROOT / "installer" / "ix-launcher.ico"
MAX_SIZE = 128


def read_entries(data):
    """(width, height, image bytes) for every image in an .ico file."""
    reserved, kind, count = struct.unpack_from("<HHH", data, 0)
    if reserved != 0 or kind != 1:
        raise ValueError("not an icon file")
    entries = []
    for index in range(count):
        width, height, _, _, _, _, size, offset = struct.unpack_from("<BBBBHHII", data, 6 + 16 * index)
        entries.append((width or 256, height or 256, data[offset:offset + size]))
    return entries


def bitmap(image):
    """An RGBA image as an icon bitmap: header, BGRA rows and the AND mask,
    both bottom-up; the mask marks fully transparent pixels."""
    width, height = image.size
    pixels = image.load()
    header = struct.pack("<IiiHHIIiiII", 40, width, height * 2, 1, 32, 0, 0, 0, 0, 0, 0)
    colour = bytearray()
    mask = bytearray()
    mask_row = ((width + 31) // 32) * 4
    for y in range(height - 1, -1, -1):
        row = bytearray(mask_row)
        for x in range(width):
            red, green, blue, alpha = pixels[x, y]
            colour += bytes((blue, green, red, alpha))
            if alpha == 0:
                row[x // 8] |= 0x80 >> (x % 8)
        mask += row
    return header + bytes(colour) + bytes(mask)


def build(source_bytes):
    from PIL import Image

    images = []
    for width, height, data in read_entries(source_bytes):
        if width > MAX_SIZE or height > MAX_SIZE:
            continue
        image = Image.open(io.BytesIO(data)).convert("RGBA")
        if image.size != (width, height):
            raise ValueError(f"image {width}x{height} decodes as {image.size}")
        images.append((width, height, bitmap(image)))
    images.sort(key=lambda entry: entry[0])

    out = bytearray(struct.pack("<HHH", 0, 1, len(images)))
    offset = 6 + 16 * len(images)
    for width, height, data in images:
        out += struct.pack("<BBBBHHII", width % 256, height % 256, 0, 0, 1, 32, len(data), offset)
        offset += len(data)
    for _, _, data in images:
        out += data
    return bytes(out)


def main(argv):
    source = Path(argv[1]) if len(argv) > 1 else SOURCE
    target = Path(argv[2]) if len(argv) > 2 else TARGET
    data = build(source.read_bytes())
    target.write_bytes(data)
    print(f"{target}: {len(read_entries(data))} images, {len(data)} bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
