#!/usr/bin/env python3
"""Draws the CRESUS seal — the canon's crowned gold coin — as PNG icons.
Pure Python (no Pillow needed), so it runs on any Mac/PC with python3."""
import os, struct, zlib, sys

BG = (14, 13, 11)
GOLD = (201, 164, 92)
INK = (24, 19, 10)
SS = 4  # supersampling for smooth edges

# Seal geometry in a 32x32 design grid (matches the <symbol id="seal"> in index.html)
CROWN = [(9.2, 20.4), (22.8, 20.4), (24.0, 12.2), (19.9, 15.5), (16.0, 10.0), (12.1, 15.5), (8.0, 12.2)]
BAR = (9.2, 21.6, 22.8, 23.4)


def in_poly(x, y, pts):
    inside = False
    j = len(pts) - 1
    for i in range(len(pts)):
        xi, yi = pts[i]; xj, yj = pts[j]
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
            inside = not inside
        j = i
    return inside


def seal_color(u, v):
    """u, v in the 32-unit design grid. Returns (rgb, coverage) or None."""
    d = ((u - 16) ** 2 + (v - 16) ** 2) ** 0.5
    if d > 15:
        return None
    if in_poly(u, v, CROWN) or (BAR[0] <= u <= BAR[2] and BAR[1] <= v <= BAR[3]):
        return INK
    if abs(d - 12.2) <= 0.55:  # engraved ring, 55% ink
        return tuple(round(GOLD[i] + (INK[i] - GOLD[i]) * 0.55) for i in range(3))
    return GOLD


def render(size, coin_fraction):
    span = size * coin_fraction          # pixels covered by the 30-unit coin
    scale = span / 30.0
    off = size / 2 - 16 * scale
    raw = bytearray()
    for py in range(size):
        raw.append(0)
        for px in range(size):
            acc = [0, 0, 0]
            for sy in range(SS):
                for sx in range(SS):
                    u = (px + (sx + 0.5) / SS - off) / scale
                    v = (py + (sy + 0.5) / SS - off) / scale
                    c = seal_color(u, v) or BG
                    for k in range(3):
                        acc[k] += c[k]
            raw += bytes(round(a / (SS * SS)) for a in acc)
    return bytes(raw)


def png(path, size, coin_fraction):
    raw = render(size, coin_fraction)
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    data = (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9))
            + chunk(b"IEND", b""))
    with open(path, "wb") as f:
        f.write(data)


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "public", "icons")
    os.makedirs(out, exist_ok=True)
    for name, size, frac in [("icon-192.png", 192, 0.70), ("icon-512.png", 512, 0.70),
                             ("icon-maskable-512.png", 512, 0.56), ("apple-touch-icon.png", 180, 0.70)]:
        png(os.path.join(out, name), size, frac)
    print("icons written to", os.path.abspath(out))
