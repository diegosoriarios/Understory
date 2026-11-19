#!/usr/bin/env python3
"""Draws the enemy, boss and moving-platform sprites.

Each creature is a bold silhouette with two-tone shading, glowing eyes and a
few distinguishing features (horns, wings, spikes, crown, staff, bomb).
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "Assets/Sprites/Enemies/Drawn"
S = 128


def canvas():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def ellipse(d, box, fill, outline=None, w=3):
    if outline:
        d.ellipse((box[0] - w, box[1] - w, box[2] + w, box[3] + w), fill=outline)
    d.ellipse(box, fill=fill)


def eye(d, cx, cy, r, color, outline=(10, 8, 14, 255)):
    d.ellipse((cx - r - 3, cy - r - 3, cx + r + 3, cy + r + 3), fill=outline)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=color)
    p = max(2, int(r * 0.42))
    d.ellipse((cx - p, cy - p, cx + p, cy + p), fill=(16, 12, 22, 255))
    hp = max(1, int(r * 0.25))
    d.ellipse((cx - r * 0.55 - hp, cy - r * 0.55 - hp, cx - r * 0.55 + hp, cy - r * 0.55 + hp),
              fill=(255, 255, 255, 220))


def horn(d, bx, by, side, length, fill, outline):
    tipx = bx + side * length * 0.55
    tipy = by - length
    base = 7
    pts = [(bx - base, by + 4), (bx + base, by + 4), (tipx, tipy)]
    d.polygon([(x - 2, y) for x, y in pts], fill=outline)
    d.polygon([(x + side * 2, y + 2) for x, y in pts], fill=outline)
    d.polygon(pts, fill=fill)
    d.polygon([(bx - base + 3, by + 2), (bx + 1, by + 2), (tipx - side * 2, tipy + 5)],
              fill=(min(255, fill[0] + 35), min(255, fill[1] + 35), fill[2], 255))


def leg(d, x0, y0, x1, y1, fill, outline):
    d.rounded_rectangle((x0 - 2, y0 - 2, x1 + 2, y1 + 2), radius=6, fill=outline)
    d.rounded_rectangle((x0, y0, x1, y1), radius=5, fill=fill)


def wing(d, cx, cy, side, fill, outline):
    pts = [
        (cx + side * 14, cy - 6),
        (cx + side * 52, cy - 44),
        (cx + side * 62, cy - 10),
        (cx + side * 46, cy - 12),
        (cx + side * 58, cy + 10),
        (cx + side * 36, cy + 4),
        (cx + side * 42, cy + 22),
        (cx + side * 12, cy + 8),
    ]
    d.polygon([(x + side * 2, y + 2) for x, y in pts], fill=outline)
    d.polygon(pts, fill=fill)
    for a, b in [(1, 3), (3, 5), (5, 7)]:
        d.line([pts[0], pts[a]], fill=outline, width=2)
        d.line([pts[a], pts[b]], fill=outline, width=2)


def spikes(d, cx, cy, rx, ry, count, fill, outline):
    for i in range(count):
        t = (i + 0.5) / count
        ang = 3.35 - t * 2.25
        import math
        bx = cx + rx * 0.92 * math.cos(ang)
        by = cy + ry * math.cos(ang) * 0.25 + ry * 0.55
        px = cx + (rx + 12) * math.cos(ang)
        py = cy - (ry + 14) * abs(math.sin(ang))
        d.polygon([(bx - 6, by), (bx + 6, by), (px, py)], fill=outline)
        d.polygon([(bx - 3, by), (bx + 3, by), (px, py + 3)], fill=fill)


def creature(name, body, belly, outline, eye_color, *, legs=2, horns=2, eyes=2,
             eye_r=8, mouth=True, wings=False, spike_n=0, staff=False, bomb=False,
             crown=False, rx=44, ry=34, cy=76, eye_y=0.0):
    img = canvas()
    d = ImageDraw.Draw(img)
    cx = S // 2
    if wings:
        wing(d, cx, cy, -1, belly, outline)
        wing(d, cx, cy, 1, belly, outline)
    if legs >= 2:
        leg(d, cx - 30, cy + ry - 10, cx - 14, cy + ry + 22, belly, outline)
        leg(d, cx + 14, cy + ry - 10, cx + 30, cy + ry + 22, belly, outline)
    if legs >= 4:
        leg(d, cx - 40, cy + ry - 14, cx - 28, cy + ry + 18, belly, outline)
        leg(d, cx + 28, cy + ry - 14, cx + 40, cy + ry + 18, belly, outline)
    ellipse(d, (cx - rx, cy - ry, cx + rx, cy + ry), body, outline, 4)
    ellipse(d, (cx - int(rx * 0.62), cy + int(ry * 0.02), cx + int(rx * 0.62), cy + int(ry * 0.92)),
            belly, None)
    d.ellipse((cx - int(rx * 0.5), cy - int(ry * 0.75), cx + int(rx * 0.1), cy - int(ry * 0.3)),
              fill=(255, 255, 255, 26))
    if spike_n:
        spikes(d, cx, cy, rx, ry, spike_n, belly, outline)
    if horns:
        horn(d, cx - int(rx * 0.55), cy - int(ry * 0.82), -1, 34, body, outline)
        horn(d, cx + int(rx * 0.55), cy - int(ry * 0.82), 1, 34, body, outline)
    if crown:
        for i, x in enumerate(range(cx - 26, cx + 27, 13)):
            d.polygon([(x - 6, cy - int(ry) - 6), (x + 6, cy - int(ry) - 6), (x, cy - int(ry) - 30)],
                      fill=(228, 186, 54, 255))
            d.polygon([(x - 3, cy - int(ry) - 8), (x + 3, cy - int(ry) - 8), (x, cy - int(ry) - 26)],
                      fill=(255, 230, 130, 255))
    yy = cy + int(ry * 0.12) + int(eye_y)
    if eyes == 1:
        eye(d, cx, yy, eye_r + 4, eye_color)
    elif eyes == 2:
        eye(d, cx - 20, yy, eye_r, eye_color)
        eye(d, cx + 20, yy, eye_r, eye_color)
    else:
        eye(d, cx - 24, yy + 2, eye_r - 2, eye_color)
        eye(d, cx, yy - 4, eye_r, eye_color)
        eye(d, cx + 24, yy + 2, eye_r - 2, eye_color)
    if mouth:
        my = cy + int(ry * 0.55)
        d.rounded_rectangle((cx - 20, my, cx + 20, my + 16), radius=6, fill=(14, 10, 18, 255))
        for tx in range(cx - 14, cx + 15, 9):
            d.polygon([(tx - 3, my + 1), (tx + 3, my + 1), (tx, my + 9)], fill=(236, 232, 214, 255))
    if staff:
        d.line((cx + rx + 12, cy + ry + 10, cx + rx + 24, cy - 34), fill=outline, width=7)
        d.line((cx + rx + 12, cy + ry + 10, cx + rx + 24, cy - 34), fill=(112, 84, 52, 255), width=4)
        ellipse(d, (cx + rx + 12, cy - 50, cx + rx + 36, cy - 26), eye_color, outline, 2)
    if bomb:
        d.ellipse((cx + 22, cy + 22, cx + 58, cy + 58), fill=(28, 26, 32, 255))
        d.ellipse((cx + 30, cy + 30, cx + 38, cy + 38), fill=(70, 70, 82, 255))
        d.line((cx + 52, cy + 24, cx + 58, cy + 12), fill=(150, 110, 60, 255), width=3)
        d.ellipse((cx + 55, cy + 6, cx + 63, cy + 14), fill=(255, 160, 40, 255))
    img.save(OUT / f"{name}.png")


def platform():
    img = canvas()
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((4, 22, 123, 105), radius=10, fill=(44, 48, 58, 255))
    d.rounded_rectangle((8, 26, 119, 101), radius=8, fill=(96, 100, 110, 255))
    d.rectangle((8, 26, 119, 44), fill=(136, 142, 152, 255))
    d.rectangle((8, 26, 119, 31), fill=(168, 174, 184, 255))
    for x in range(20, 112, 22):
        d.rectangle((x, 52, x + 2, 92), fill=(72, 76, 86, 255))
    d.rounded_rectangle((14, 96, 113, 105), radius=4, fill=(58, 62, 72, 255))
    img.save(OUT / "platform.png")


CREATURES = {
    # name: body, belly, outline, eye, kwargs
    "walker": ((91, 70, 50, 255), (125, 101, 73, 255), (36, 26, 16, 255), (255, 210, 87, 255),
               dict(legs=2, horns=2, eyes=2, mouth=True, rx=46, ry=34)),
    "enemy1": ((74, 58, 110, 255), (106, 90, 146, 255), (24, 18, 38, 255), (158, 240, 255, 255),
               dict(legs=2, horns=0, eyes=2, eye_r=6, staff=True, rx=34, ry=28)),
    "enemy2": ((31, 95, 90, 255), (47, 138, 128, 255), (12, 34, 32, 255), (255, 210, 87, 255),
               dict(legs=2, horns=2, eyes=1, eye_r=10, rx=34, ry=28)),
    "enemy3": ((122, 42, 36, 255), (168, 70, 54, 255), (42, 12, 12, 255), (255, 224, 138, 255),
               dict(legs=4, horns=2, eyes=2, eye_r=7, spike_n=3, rx=40, ry=30)),
    "enemy4": ((47, 90, 42, 255), (75, 128, 64, 255), (16, 32, 14, 255), (198, 255, 138, 255),
               dict(legs=2, horns=2, eyes=3, eye_r=6, spike_n=4, rx=38, ry=30)),
    "enemy5": ((107, 95, 31, 255), (148, 134, 56, 255), (36, 32, 10, 255), (255, 251, 176, 255),
               dict(legs=2, horns=0, eyes=2, eye_r=8, rx=46, ry=38)),
    "enemy7": ((90, 35, 70, 255), (134, 52, 95, 255), (30, 10, 24, 255), (255, 179, 230, 255),
               dict(legs=2, horns=2, eyes=2, wings=True, rx=34, ry=30)),
    "enemy9": ((35, 74, 110, 255), (58, 112, 158, 255), (10, 26, 42, 255), (174, 240, 255, 255),
               dict(legs=0, horns=0, eyes=1, eye_r=16, rx=36, ry=36, cy=68, spike_n=0)),
    "enemy11": ((201, 196, 180, 255), (232, 227, 212, 255), (42, 36, 28, 255), (255, 85, 51, 255),
                dict(legs=2, horns=2, eyes=2, eye_r=7, rx=36, ry=32)),
    "enemy12": ((122, 74, 31, 255), (168, 106, 48, 255), (36, 20, 8, 255), (255, 207, 90, 255),
                dict(legs=2, horns=2, eyes=2, bomb=True, rx=38, ry=30)),
    "fly1": ((216, 208, 192, 255), (240, 234, 220, 255), (44, 38, 30, 255), (255, 90, 70, 255),
             dict(legs=0, horns=0, eyes=1, eye_r=12, wings=True, rx=30, ry=28, cy=62)),
    "fly2": ((42, 34, 54, 255), (58, 48, 80, 255), (12, 8, 18, 255), (255, 74, 74, 255),
             dict(legs=0, horns=2, eyes=2, eye_r=7, wings=True, rx=30, ry=26, cy=62)),
    "boss3": ((42, 26, 62, 255), (67, 48, 94, 255), (12, 6, 20, 255), (255, 59, 92, 255),
              dict(legs=2, horns=2, eyes=3, eye_r=10, wings=True, spike_n=6, crown=True,
                   rx=48, ry=38, cy=78)),
}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (body, belly, outline, eye_color, kw) in CREATURES.items():
        creature(name, body, belly, outline, eye_color, **kw)
    platform()
    print(f"wrote {len(CREATURES) + 1} sprites to {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
