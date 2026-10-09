#!/usr/bin/env python3
"""Generate BIFROST spectral PWA icon PNGs using Python stdlib only.

This is a build-time development utility, not a service/runtime dependency.
All raster assets derive from the same vector-like pixel geometry and palette.
"""
from __future__ import annotations
import math
import pathlib
import struct
import sys
import zlib

PALETTE = (
    (66, 193, 246),  # sky
    (54, 128, 242),  # blue
    (95, 92, 230),   # indigo
    (171, 104, 237), # violet
    (246, 111, 171), # rose
    (252, 181, 86),  # amber
)


def png(size: int) -> bytes:
    out = bytearray()
    for yy in range(size):
        out.append(0)  # PNG "none" row filter
        for xx in range(size):
            x = (xx + 0.5) / size
            y = (yy + 0.5) / size
            # Midnight slate backdrop with barely perceptible vertical tint.
            base = [int(13 + 5 * (1-y)), int(18 + 5 * (1-y)), int(33 + 7 * (1-y))]
            # The spectral bands form an elevated, connected bridge.
            cx, cy = 0.5, 0.725
            r = math.hypot(x-cx,y-cy)
            band_width = 0.027
            if y < cy:
                for idx, col in enumerate(PALETTE):
                    radius = 0.344 - idx * 0.044
                    d = abs(r-radius)
                    aa = min(1, max(0, ((band_width*0.5 + (1/size)) - d) * size))
                    if aa > 0:
                        base = [round(a*(1-aa) + b*aa) for a,b in zip(base,col)]
                        break
            # Two soft terminal "nodes" under the arch visually represent links.
            for px in (0.168,0.832):
                radius=math.hypot(x-px,y-0.724)
                if radius<0.023:
                    base = [209,231,255]
            # The bridge deck; deliberately restrained, not another status signal.
            if 0.23 < x < 0.77 and abs(y-0.765) < 0.007:
                base = [96,121,167]
            out.extend((*base,255))

    def chunk(tag, data):
        return struct.pack(">I",len(data)) + tag + data + struct.pack(">I",zlib.crc32(tag+data)&0xffffffff)

    return (b"\x89PNG\r\n\x1a\n" +
            chunk(b"IHDR",struct.pack(">IIBBBBB",size,size,8,6,0,0,0)) +
            chunk(b"IDAT",zlib.compress(bytes(out),9)) +
            chunk(b"IEND",b""))


def main():
    if len(sys.argv)<2:
        raise SystemExit("Usage: build_pwa_icons.py <one-or-more-output-root-dirs>")
    for dirname in sys.argv[1:]:
        folder = pathlib.Path(dirname)/"icons"
        folder.mkdir(parents=True,exist_ok=True)
        for size in (192,512):
            path=folder/f"icon-{size}.png"
            path.write_bytes(png(size))
            print("PWA_ICON",path,size,path.stat().st_size)


if __name__=="__main__":
    main()
