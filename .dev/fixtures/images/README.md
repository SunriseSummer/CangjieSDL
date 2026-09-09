# Static image fixtures

Generated in this task with Pillow and original SVG/XPM text; no third-party artwork. Quadrants are red, green, blue, and half-transparent gold (where the format supports alpha). `mixed.PnG` and `quad.data` contain PNG bytes; `broken.png` is intentionally truncated. Optional WebP/TIFF/AVIF/JXL codecs are not required.

Regenerate with `python .dev/fixtures/images/generate.py` (Pillow required); use `--output target/dev/generated-images` for a separate output. Pixel values are fixed; encoded bytes can differ with Pillow versions. The distinct `mixed.PnG` filename also exercises mixed-case hints on case-sensitive filesystems.
