#!/usr/bin/env python3
"""Prepare FeROS target media using the backend for the current host."""

from __future__ import annotations

import argparse
import importlib
from pathlib import Path
import platform
import sys


HOST_BACKENDS = {
    "Darwin": "host.darwin",
    "Linux": "host.linux",
    "Windows": "host.windows",
}


class MediaPreparationError(RuntimeError):
    """Report a target-media preparation failure without a traceback."""


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Prepare physical media for a FeROS target."
    )
    parser.add_argument("--target", required=True)
    parser.add_argument("--image", required=True, type=Path)
    return parser.parse_args()


def load_backend(host_system: str):
    module_name = HOST_BACKENDS.get(host_system)
    if module_name is None:
        available = ", ".join(sorted(HOST_BACKENDS))
        raise MediaPreparationError(
            f"unsupported host system: {host_system}; "
            f"available backends: {available}"
        )

    try:
        return importlib.import_module(module_name)
    except ImportError as error:
        raise MediaPreparationError(
            f"cannot load media backend for {host_system}: {error}"
        ) from error


def validate_image(path: Path) -> Path:
    image = path.resolve()

    if not image.is_file():
        raise MediaPreparationError(f"boot image not found: {image}")

    if image.stat().st_size == 0:
        raise MediaPreparationError(f"boot image is empty: {image}")

    return image


def main() -> int:
    arguments = parse_arguments()
    image = validate_image(arguments.image)
    backend = load_backend(platform.system())

    return backend.prepare(
        target=arguments.target,
        image=image,
    )


if __name__ == "__main__":
    try:
        sys.exit(main())
    except RuntimeError as error:
        print(f"FeROS: {error}", file=sys.stderr)
        sys.exit(1)