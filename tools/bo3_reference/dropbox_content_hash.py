"""Compute the Dropbox content_hash of a local file.

Dropbox content_hash = SHA-256 over the concatenated SHA-256 digests of each
4 MiB block of the file.  Usage: python3 -I dropbox_content_hash.py <file>
"""
import hashlib
import sys

BLOCK = 4 * 1024 * 1024


def content_hash(path):
    overall = hashlib.sha256()
    with open(path, "rb") as handle:
        while True:
            block = handle.read(BLOCK)
            if not block:
                break
            overall.update(hashlib.sha256(block).digest())
    return overall.hexdigest()


if __name__ == "__main__":
    print(content_hash(sys.argv[1]))
