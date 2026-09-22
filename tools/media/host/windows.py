"""Windows backend placeholder for FeROS target-media preparation."""

from __future__ import annotations

from pathlib import Path


class WindowsMediaError(RuntimeError):
    """Report that Windows media preparation is not available yet."""


def prepare(*, target: str, image: Path) -> int:
    """Reject Windows media writes until the backend is implemented safely."""
    del target, image
    raise WindowsMediaError(
        "Windows target-media preparation is not supported yet; "
        "no storage device was modified"
    )
