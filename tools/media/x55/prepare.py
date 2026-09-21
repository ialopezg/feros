#!/usr/bin/env python3
"""Safely write a validated FeROS X55 boot image to removable media."""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import platform
import plistlib
import re
import subprocess
import sys


DEVICE_PATTERN = re.compile(r"^/dev/disk([1-9][0-9]*)$")
RKNS_OFFSET = 0x8000
RKNS_MAGIC = b"RKNS"


class MediaError(RuntimeError):
    """Report a media-preparation failure without a Python traceback."""


def run(command: list[str], *, capture: bool = False) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        command,
        check=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )


def diskutil_plist(*arguments: str) -> dict:
    try:
        result = run(["diskutil", *arguments, "-plist"], capture=True)
    except subprocess.CalledProcessError as error:
        message = error.stderr.decode(errors="replace").strip()
        raise MediaError(message or "diskutil failed") from error

    try:
        return plistlib.loads(result.stdout)
    except plistlib.InvalidFileException as error:
        raise MediaError("diskutil returned invalid property-list data") from error


def root_disk_identifier() -> str:
    info = diskutil_plist("info", "/")
    identifier = info.get("ParentWholeDisk") or info.get("DeviceIdentifier")
    if not isinstance(identifier, str) or not identifier:
        raise MediaError("cannot determine the macOS startup disk")
    return identifier


def external_disks() -> list[dict]:
    listing = diskutil_plist("list", "external", "physical")
    disks: list[dict] = []

    for entry in listing.get("AllDisksAndPartitions", []):
        identifier = entry.get("DeviceIdentifier")
        if not isinstance(identifier, str):
            continue
        info = diskutil_plist("info", f"/dev/{identifier}")
        if info.get("Whole") is True and info.get("Internal") is False:
            disks.append(info)

    return disks


def human_size(size: int) -> str:
    value = float(size)
    for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
        if value < 1024.0 or unit == "TiB":
            return f"{value:.1f} {unit}"
        value /= 1024.0
    raise AssertionError("unreachable")


def choose_disk(disks: list[dict]) -> dict:
    if not disks:
        raise MediaError("no external physical disks were found")

    print("FeROS: external physical disks:\n")
    for index, info in enumerate(disks, start=1):
        identifier = info["DeviceIdentifier"]
        model = info.get("MediaName") or info.get("DeviceModel") or "Unknown media"
        size = human_size(int(info.get("TotalSize", 0)))
        protocol = info.get("BusProtocol") or "unknown protocol"
        print(f"  {index}) /dev/{identifier} — {model} — {size} — {protocol}")

    print("  0) Cancel\n")
    selection = input(f"Select [0-{len(disks)}]: ").strip()
    if selection == "0":
        raise MediaError("operation cancelled; no storage device was modified")
    if not selection.isdigit() or not 1 <= int(selection) <= len(disks):
        raise MediaError("invalid disk selection")
    return disks[int(selection) - 1]


def validate_image(path: Path) -> tuple[int, str]:
    if not path.is_file():
        raise MediaError(f"boot image not found: {path}")

    size = path.stat().st_size
    if size <= RKNS_OFFSET + len(RKNS_MAGIC):
        raise MediaError("boot image is too small to contain an RKNS header")

    with path.open("rb") as image:
        image.seek(RKNS_OFFSET)
        if image.read(len(RKNS_MAGIC)) != RKNS_MAGIC:
            raise MediaError("boot image does not contain RKNS at offset 0x8000")

    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    return size, digest


def validate_selected_disk(info: dict, startup_disk: str) -> tuple[str, str]:
    identifier = info.get("DeviceIdentifier")
    device = f"/dev/{identifier}"

    if not isinstance(identifier, str) or not DEVICE_PATTERN.fullmatch(device):
        raise MediaError("selected device is not a whole macOS disk")
    if info.get("Whole") is not True:
        raise MediaError("selected device is a partition, not a whole disk")
    if info.get("Internal") is not False:
        raise MediaError("refusing to write to a disk that is not explicitly external")
    if identifier == startup_disk:
        raise MediaError("refusing to write to the macOS startup disk")

    raw_device = f"/dev/r{identifier}"
    return device, raw_device


def confirm_write(device: str, info: dict, image: Path, size: int, digest: str) -> None:
    model = info.get("MediaName") or info.get("DeviceModel") or "Unknown media"
    capacity = human_size(int(info.get("TotalSize", 0)))

    print("\nFeROS: destructive media operation\n")
    print(f"  Target:       {device}")
    print(f"  Model:        {model}")
    print(f"  Capacity:     {capacity}")
    print(f"  Image:        {image}")
    print(f"  Write size:   {size} bytes")
    print(f"  Image SHA-256: {digest}")
    print("\nAll existing partition and filesystem metadata in the written region")
    print("will be overwritten. This operation cannot be undone.\n")

    phrase = f"WRITE {device}"
    confirmation = input(f"Type '{phrase}' to continue: ").strip()
    if confirmation != phrase:
        raise MediaError("confirmation did not match; no storage device was modified")


def write_and_verify(image: Path, device: str, raw_device: str, size: int) -> None:
    print(f"\nFeROS: unmounting {device}...")
    run(["diskutil", "unmountDisk", device])

    print(f"FeROS: writing {size} bytes to {raw_device}...")
    run(["sudo", "dd", f"if={image}", f"of={raw_device}", "bs=1m"])
    run(["sync"])

    print("FeROS: verifying written bytes...")
    block_size = 1024 * 1024
    block_count = (size + block_size - 1) // block_size
    result = run(
        ["sudo", "dd", f"if={raw_device}", "bs=1m", f"count={block_count}"],
        capture=True,
    )
    if result.stdout[:size] != image.read_bytes():
        raise MediaError("written media does not match the source image")

    print(f"FeROS: ejecting {device}...")
    run(["diskutil", "eject", device])


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Write and verify a FeROS X55 RKNS image on macOS."
    )
    parser.add_argument("--image", required=True, type=Path)
    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()

    if platform.system() != "Darwin":
        raise MediaError("X55 media preparation currently supports macOS only")
    if os.geteuid() == 0:
        raise MediaError("run this tool as your normal user, not as root")

    image = arguments.image.resolve()
    size, digest = validate_image(image)
    startup_disk = root_disk_identifier()
    info = choose_disk(external_disks())
    device, raw_device = validate_selected_disk(info, startup_disk)

    # Refresh device information immediately before confirmation and writing.
    info = diskutil_plist("info", device)
    device, raw_device = validate_selected_disk(info, startup_disk)
    confirm_write(device, info, image, size, digest)
    write_and_verify(image, device, raw_device, size)

    print("\nFeROS: target media prepared and verified successfully.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (MediaError, subprocess.CalledProcessError) as error:
        print(f"FeROS: {error}", file=sys.stderr)
        sys.exit(1)
