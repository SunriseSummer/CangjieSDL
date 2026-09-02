"""Canonical repository paths used by development tools."""

from pathlib import Path


DEV_ROOT = Path(__file__).resolve().parents[2]
REPOSITORY_ROOT = DEV_ROOT.parent
DEV_TARGET_ROOT = REPOSITORY_ROOT / "target" / "dev"
