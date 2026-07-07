#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

# Generates a solid color wallpaper PNG using only Python stdlib (struct + zlib).
# Usage: gen-wallpaper.sh [output-path] [width] [height] [r] [g] [b]
# Defaults: themes/tokyonight/wallpaper.png, 1920x1080, #1a1b26 (26, 27, 38)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

OUTPUT="${1:-$REPO_ROOT/themes/tokyonight/wallpaper.png}"
WIDTH="${2:-1920}"
HEIGHT="${3:-1080}"
R="${4:-26}"
G="${5:-27}"
B="${6:-38}"

python3 - "$OUTPUT" "$WIDTH" "$HEIGHT" "$R" "$G" "$B" <<'PYEOF'
import sys, struct, zlib

output = sys.argv[1]
width  = int(sys.argv[2])
height = int(sys.argv[3])
r      = int(sys.argv[4])
g      = int(sys.argv[5])
b      = int(sys.argv[6])

def chunk(name, data):
    c = zlib.crc32(name + data) & 0xffffffff
    return struct.pack('>I', len(data)) + name + data + struct.pack('>I', c)

sig  = b'\x89PNG\r\n\x1a\n'
ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0))
row  = b'\x00' + bytes([r, g, b] * width)
raw  = row * height
idat = chunk(b'IDAT', zlib.compress(raw, 9))
iend = chunk(b'IEND', b'')

with open(output, 'wb') as f:
    f.write(sig + ihdr + idat + iend)

print(f"Created {output} ({width}x{height}, rgb={r},{g},{b})")
PYEOF
