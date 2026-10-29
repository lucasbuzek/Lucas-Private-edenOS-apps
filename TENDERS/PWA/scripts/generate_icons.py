"""Generate TENDERS PWA PNG icons with only Python standard library."""
import struct, zlib
from pathlib import Path
OUT = Path(__file__).resolve().parents[1] / "public" / "icons"
def chunk(kind, data):
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xffffffff)
def make(size, target):
    pix = bytearray([23,25,29] * size * size)
    def rect(x0,y0,x1,y1,c):
        for y in range(max(0,y0),min(size,y1)):
            for x in range(max(0,x0),min(size,x1)):
                i=(y*size+x)*3
                pix[i:i+3]=bytes(c)
    rect(size*23//100,size*18//100,size*77//100,size*83//100,(245,245,242))
    rect(size*30//100,size*28//100,size*70//100,size*36//100,(23,25,29))
    rect(size*30//100,size*43//100,size*70//100,size*48//100,(23,25,29))
    rect(size*30//100,size*55//100,size*58//100,size*60//100,(23,25,29))
    def line(x0,y0,x1,y1,c,width):
        dx=x1-x0; dy=y1-y0; steps=max(abs(dx),abs(dy),1)
        for step in range(steps+1):
            x=round(x0+dx*step/steps); y=round(y0+dy*step/steps); r=width//2
            rect(x-r,y-r,x+r+1,y+r+1,c)
    line(size*57//100,size*69//100,size*66//100,size*77//100,(213,180,107),max(2,size*5//100))
    line(size*66//100,size*77//100,size*83//100,size*59//100,(213,180,107),max(2,size*5//100))
    raw=b"".join(b"\x00"+pix[y*size*3:(y+1)*size*3] for y in range(size))
    png=b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack(">2I5B",size,size,8,2,0,0,0))+chunk(b"IDAT",zlib.compress(raw,9))+chunk(b"IEND",b"")
    target.write_bytes(png)
for n in (180,192,512): make(n,OUT/f"tenders-{n}.png")
print("Generated TENDERS PNG icons: 180, 192, 512")

