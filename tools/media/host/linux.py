"""Linux backend placeholder for FeROS target-media preparation."""

from __future__ import annotations

from pathlib import Path


class LinuxMediaError(RuntimeError):
    """Report that Linux media preparation is not available yet."""


def prepare(*, target: str, image: Path) -> int:
    """Reject Linux media writes until the backend is implemented safely."""
    del target, image
    raise LinuxMediaError(
        "Linux target-media preparation is not supported yet; "
        "no storage device was modified"
    )
