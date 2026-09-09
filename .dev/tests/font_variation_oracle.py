"""Produce local-only static font fixtures with fontTools 4.59.2.

This independent OpenType instancer is used to check FreeType's runtime axis path.
Do not distribute fonts produced from proprietary installed fonts.
"""
import argparse
import json
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

p = argparse.ArgumentParser(__doc__)
p.add_argument('--regular', type=Path, required=True)
p.add_argument('--italic', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
args = p.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
for weight in [200, 350, 400, 600, 625, 700]:
    for style, path in [('regular', args.regular), ('italic', args.italic)]:
        with TTFont(path) as font:
            result = instantiateVariableFont(font, {'wght': weight}, inplace=False)
            result.save(args.output / f'{weight}-{style}.ttf')
(args.output / 'sources.json').write_text(json.dumps({
    'regular': str(args.regular.resolve()), 'italic': str(args.italic.resolve()),
    'weights': [200, 350, 400, 600, 625, 700], 'instancer': 'fontTools 4.59.2'
}, indent=2), encoding='utf8')
print(args.output.resolve())
