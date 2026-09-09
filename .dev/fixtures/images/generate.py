"""Regenerate original, deterministic pixel fixtures (requires Pillow with QOI support)."""
import argparse
from pathlib import Path
from PIL import Image


def generate(destination):
    destination.mkdir(parents=True, exist_ok=True)
    image = Image.new("RGBA", (16, 12))
    colors = [(240, 30, 20, 255), (20, 210, 50, 255),
              (30, 70, 240, 255), (230, 170, 30, 128)]
    image.putdata([colors[(y // 6) * 2 + x // 8] for y in range(12) for x in range(16)])
    for extension in ("png", "bmp", "tga", "qoi"):
        image.save(destination / f"quad.{extension}")
    for extension in ("pcx", "ppm", "gif"):
        image.convert("RGB").save(destination / f"quad.{extension}")
    image.convert("RGB").save(destination / "quad.jpg", quality=95, subsampling=0)
    image.resize((32, 32), Image.Resampling.NEAREST).save(destination / "quad.ico", sizes=[(32, 32)])
    (destination / "mixed.PnG").write_bytes((destination / "quad.png").read_bytes())
    (destination / "quad.data").write_bytes((destination / "quad.png").read_bytes())
    (destination / "broken.png").write_bytes((destination / "quad.png").read_bytes()[:17])
    (destination / "quad.svg").write_text(SVG, encoding="utf-8")
    (destination / "quad.xpm").write_text(XPM, encoding="utf-8")


SVG = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="12" viewBox="0 0 16 12"><path fill="#f01e14" d="M0 0h8v6H0z"/><path fill="#14d232" d="M8 0h8v6H8z"/><path fill="#1e46f0" d="M0 6h8v6H0z"/><path fill="#e6aa1e" fill-opacity=".5" d="M8 6h8v6H8z"/></svg>'
XPM = '/* XPM */\nstatic char * test[] = {"2 2 3 1", "r c #f01e14", "g c #14d232", "n c None", "rg", "rn"};\n'

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parent)
    generate(parser.parse_args().output)
