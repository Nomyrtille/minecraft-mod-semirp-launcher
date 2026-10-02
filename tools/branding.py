"""Génère les images du launcher Myrtille City (logo, icônes, écran de chargement, fonds).

    pip install pillow
    python tools/branding.py

Tout est dessiné ici, sans asset extérieur : aucune question de licence. Remplacer par les visuels
définitifs de l'équipe quand ils existent, en gardant les mêmes noms de fichiers.
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
IMAGES = ROOT / "app" / "assets" / "images"
NAVY = (20, 22, 48)
BERRY = (74, 63, 168)
BERRY_DARK = (44, 36, 112)
BERRY_LIGHT = (138, 128, 222)
LEAF = (86, 170, 96)
GOLD = (236, 190, 92)


def berry(draw, cx, cy, r):
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=BERRY_DARK)
    draw.ellipse((cx - r * 0.92, cy - r * 0.95, cx + r * 0.86, cy + r * 0.82), fill=BERRY)
    hl = r * 0.28
    draw.ellipse((cx - r * 0.55 - hl, cy - r * 0.55 - hl, cx - r * 0.55 + hl, cy - r * 0.55 + hl), fill=BERRY_LIGHT)
    # Couronne étoilée en haut de la baie.
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rr = r * (0.26 if i % 2 == 0 else 0.11)
        pts.append((cx + rr * math.cos(a) * 1.1, cy - r * 0.62 + rr * math.sin(a)))
    draw.polygon(pts, fill=NAVY)


def leaf(draw, cx, cy, length, angle):
    pts = []
    for t in range(0, 101):
        u = t / 100
        w = math.sin(u * math.pi) * length * 0.32
        x = u * length
        pts.append((x, w))
    pts += [(x, -w) for x, w in reversed(pts)]
    ca, sa = math.cos(angle), math.sin(angle)
    draw.polygon([(cx + x * ca - y * sa, cy + x * sa + y * ca) for x, y in pts], fill=LEAF)


def logo(size):
    scale = 4
    s = size * scale
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse((0, 0, s - 1, s - 1), fill=NAVY)
    ring = s * 0.035
    d.ellipse((ring, ring, s - ring, s - ring), outline=GOLD, width=int(s * 0.025))
    c = s / 2
    leaf(d, c, c - s * 0.12, s * 0.26, -2.4)
    leaf(d, c, c - s * 0.12, s * 0.24, -0.7)
    berry(d, c - s * 0.15, c + s * 0.08, s * 0.16)
    berry(d, c + s * 0.15, c + s * 0.08, s * 0.16)
    berry(d, c, c - s * 0.05, s * 0.17)
    return img.resize((size, size), Image.LANCZOS)


def spinner(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c, r = size / 2, size * 0.47
    for i in range(36):
        a = i * 2 * math.pi / 36
        alpha = int(60 + 195 * (i / 35))
        dot = size * 0.012
        x, y = c + r * math.cos(a), c + r * math.sin(a)
        d.ellipse((x - dot, y - dot, x + dot, y + dot), fill=GOLD + (alpha,))
    return img


def background(index, w=1456, h=819):
    rnd = random.Random(index)
    hue_shift = index * 9
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    top = (18 + hue_shift % 20, 16, 52 + hue_shift % 40)
    bottom = (70 + hue_shift % 30, 52, 140)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=tuple(int(top[k] + (bottom[k] - top[k]) * t) for k in range(3)))
    for _ in range(120):
        x, y = rnd.randrange(w), rnd.randrange(int(h * 0.55))
        d.point((x, y), fill=(230, 230, 255))
    # Silhouette de la ville, en blocs, comme une ville Minecraft.
    x = 0
    while x < w:
        bw = rnd.randrange(40, 110)
        bh = rnd.randrange(int(h * 0.12), int(h * 0.45))
        d.rectangle((x, h - bh, x + bw, h), fill=(16, 14, 34))
        for wy in range(h - bh + 12, h - 10, 22):
            for wx in range(x + 8, x + bw - 12, 18):
                if rnd.random() < 0.35:
                    d.rectangle((wx, wy, wx + 7, wy + 9), fill=GOLD)
        x += bw + rnd.randrange(0, 12)
    return img.filter(ImageFilter.GaussianBlur(1.2))


def main():
    seal = logo(1024)
    seal.save(IMAGES / "SealCircle.png")
    seal.save(IMAGES / "LoadingSeal.png")
    seal.save(ROOT / "build" / "icon.png")
    seal.save(IMAGES / "SealCircle.ico", sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    spinner(1024).save(IMAGES / "LoadingText.png")
    for i in range(8):
        background(i).save(IMAGES / "backgrounds" / f"{i}.jpg", quality=88)
    print("Images Myrtille City générées.")


if __name__ == "__main__":
    main()
