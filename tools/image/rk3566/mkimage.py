#!/usr/bin/env python3

"""Build and validate minimal Rockchip RK3566 RKNS boot images for FeROS."""

import argparse
import hashlib
import struct
from pathlib import Path


# Size, in bytes, of one sector used by the Rockchip boot format.
SECTOR_SIZE = 512

# Physical byte offset where the RKNS structure is placed on boot media.
RKNS_OFFSET = 64 * SECTOR_SIZE

# Total size, in bytes, occupied by the RKNS header.
RKNS_HEADER_SIZE = 4 * SECTOR_SIZE

# Number of bytes covered by the RKNS header SHA-256 digest.
RKNS_HASH_DATA_SIZE = 3 * SECTOR_SIZE

# Offset inside the RKNS header where its SHA-256 digest is stored.
RKNS_HASH_OFFSET = RKNS_HASH_DATA_SIZE

# Size, in bytes, of a SHA-256 digest.
SHA256_SIZE = 32

# Expected RKNS structure signature.
RKNS_MAGIC = b"RKNS"

# RKNS flag selecting SHA-256 hashing.
RKNS_SHA256_FLAG = 1

# Control value representing the two-payload layout used by this image.
RKNS_CONTROL = 0x00020180

# Offset inside the RKNS header where the first payload descriptor begins.
DESCRIPTOR_1_OFFSET = 0x78

# Offset inside the RKNS header where the second payload descriptor begins.
DESCRIPTOR_2_OFFSET = 0xD0

# Offset inside each payload descriptor where its SHA-256 digest is stored.
PAYLOAD_HASH_OFFSET = 0x10

# First payload sector relative to the beginning of the RKNS structure.
FIRST_PAYLOAD_SECTOR = 4

# Maximum value representable by each 16-bit descriptor component.
DESCRIPTOR_FIELD_MAX = 0xFFFF


def align(value: int, alignment: int) -> int:
    """Round a byte count upward to the requested alignment boundary."""
    return (value + alignment - 1) // alignment * alignment


def pad_payload(data: bytes) -> bytes:
    """Pad a payload with zero bytes until it occupies complete sectors."""
    padded_size = align(len(data), SECTOR_SIZE)

    return data.ljust(padded_size, b"\0")


def sha256(data: bytes) -> bytes:
    """Calculate and return the binary SHA-256 digest of a byte sequence."""
    return hashlib.sha256(data).digest()


def encode_descriptor(
        header: bytearray,
        descriptor_offset: int,
        payload_sector: int,
        payload: bytes,
) -> None:
    """Encode one RKNS payload descriptor and its SHA-256 digest."""

    # Calculate the number of complete sectors occupied by the payload.
    payload_sector_count = len(payload) // SECTOR_SIZE

    # Ensure the payload offset fits inside the descriptor field.
    if payload_sector > DESCRIPTOR_FIELD_MAX:
        raise ValueError("RKNS payload offset exceeds descriptor limits")

    # Ensure the payload size fits inside the descriptor field.
    if payload_sector_count > DESCRIPTOR_FIELD_MAX:
        raise ValueError("RKNS payload size exceeds descriptor limits")

    # Store the sector count in the upper 16 bits and the starting sector
    # in the lower 16 bits.
    descriptor_word = (
                              payload_sector_count << 16
                      ) | payload_sector

    # Write the descriptor using the little-endian RKNS representation.
    struct.pack_into(
        "<I",
        header,
        descriptor_offset,
        descriptor_word,
    )

    # Calculate the SHA-256 digest over the complete padded payload.
    payload_digest = sha256(payload)

    # Calculate the location of the digest inside this descriptor.
    digest_offset = descriptor_offset + PAYLOAD_HASH_OFFSET

    # Store the payload digest inside the RKNS header.
    header[
        digest_offset:
        digest_offset + SHA256_SIZE
    ] = payload_digest


def decode_descriptor(
        header: bytes,
        descriptor_offset: int,
) -> tuple[int, int, bytes]:
    """Decode one RKNS payload descriptor from an existing header."""

    # Read the packed descriptor word using little-endian byte order.
    descriptor_word = struct.unpack_from(
        "<I",
        header,
        descriptor_offset,
    )[0]

    # Extract the starting sector from the lower 16 bits.
    payload_sector = descriptor_word & 0xFFFF

    # Extract the payload sector count from the upper 16 bits.
    payload_sector_count = descriptor_word >> 16

    # Calculate the location of the stored payload digest.
    digest_offset = descriptor_offset + PAYLOAD_HASH_OFFSET

    # Read the stored SHA-256 digest.
    payload_digest = header[
        digest_offset:
        digest_offset + SHA256_SIZE
    ]

    return payload_sector, payload_sector_count, payload_digest


def build_image(ddr_payload: bytes, stage0_payload: bytes) -> bytes:
    """Build an RKNS image containing DDR initialization and FeROS Stage 0."""

    # Pad both payloads because RKNS describes them in complete sectors.
    padded_ddr = pad_payload(ddr_payload)
    padded_stage0 = pad_payload(stage0_payload)

    # Place DDR initialization immediately after the RKNS header.
    ddr_sector = FIRST_PAYLOAD_SECTOR

    # Place FeROS Stage 0 immediately after the DDR initialization payload.
    stage0_sector = (
            ddr_sector
            + len(padded_ddr) // SECTOR_SIZE
    )

    # Initialize the complete RKNS header with zero bytes.
    header = bytearray(RKNS_HEADER_SIZE)

    # Write the RKNS signature.
    header[0:4] = RKNS_MAGIC

    # Select SHA-256 as the hashing algorithm.
    struct.pack_into(
        "<I",
        header,
        0x04,
        RKNS_SHA256_FLAG,
    )

    # Declare the two-payload RKNS layout.
    struct.pack_into(
        "<I",
        header,
        0x08,
        RKNS_CONTROL,
    )

    # Encode the DDR initialization payload descriptor.
    encode_descriptor(
        header=header,
        descriptor_offset=DESCRIPTOR_1_OFFSET,
        payload_sector=ddr_sector,
        payload=padded_ddr,
    )

    # Encode the FeROS Stage 0 payload descriptor.
    encode_descriptor(
        header=header,
        descriptor_offset=DESCRIPTOR_2_OFFSET,
        payload_sector=stage0_sector,
        payload=padded_stage0,
    )

    # Calculate the RKNS header digest over the first three header sectors.
    header_digest = sha256(
        header[:RKNS_HASH_DATA_SIZE]
    )

    # Store the RKNS header digest in the fourth header sector.
    header[
        RKNS_HASH_OFFSET:
        RKNS_HASH_OFFSET + SHA256_SIZE
    ] = header_digest

    # Calculate the exact physical size required by the final payload.
    image_size = (
            RKNS_OFFSET
            + stage0_sector * SECTOR_SIZE
            + len(padded_stage0)
    )

    # Initialize the complete image with zero bytes.
    image = bytearray(image_size)

    # Copy the RKNS header into its physical boot-media location.
    image[
        RKNS_OFFSET:
        RKNS_OFFSET + RKNS_HEADER_SIZE
    ] = header

    # Calculate the physical DDR payload offset.
    ddr_offset = (
            RKNS_OFFSET
            + ddr_sector * SECTOR_SIZE
    )

    # Copy the DDR initialization payload into the image.
    image[
        ddr_offset:
        ddr_offset + len(padded_ddr)
    ] = padded_ddr

    # Calculate the physical FeROS Stage 0 payload offset.
    stage0_offset = (
            RKNS_OFFSET
            + stage0_sector * SECTOR_SIZE
    )

    # Copy FeROS Stage 0 into the image.
    image[
        stage0_offset:
        stage0_offset + len(padded_stage0)
    ] = padded_stage0

    return bytes(image)


def validate_payload(
        image: bytes,
        header: bytes,
        descriptor_offset: int,
        payload_name: str,
) -> None:
    """Validate one RKNS payload location, bounds, and SHA-256 digest."""

    # Decode the payload location, size, and expected digest.
    payload_sector, payload_sector_count, expected_digest = (
        decode_descriptor(
            header=header,
            descriptor_offset=descriptor_offset,
        )
    )

    # Reject descriptors that contain an empty payload.
    if payload_sector_count == 0:
        raise ValueError(f"{payload_name} payload has zero sectors")

    # Calculate the physical payload location inside the image.
    payload_offset = (
            RKNS_OFFSET
            + payload_sector * SECTOR_SIZE
    )

    # Calculate the complete payload size in bytes.
    payload_size = payload_sector_count * SECTOR_SIZE

    # Calculate the physical end of the payload.
    payload_end = payload_offset + payload_size

    # Reject payload descriptors that extend beyond the image.
    if payload_end > len(image):
        raise ValueError(
            f"{payload_name} payload exceeds image bounds"
        )

    # Read the complete padded payload from the image.
    payload = image[payload_offset:payload_end]

    # Calculate the digest of the payload stored in the image.
    actual_digest = sha256(payload)

    # Reject the image when the stored and calculated hashes differ.
    if actual_digest != expected_digest:
        raise ValueError(
            f"{payload_name} payload SHA-256 mismatch"
        )

    print(
        f"{payload_name}: "
        f"sector={payload_sector} "
        f"sectors={payload_sector_count} "
        f"offset=0x{payload_offset:x} "
        f"SHA-256 OK"
    )


def validate_image(image: bytes) -> None:
    """Validate the structure and cryptographic integrity of an RKNS image."""

    # Ensure the image is large enough to contain the complete RKNS header.
    minimum_image_size = RKNS_OFFSET + RKNS_HEADER_SIZE

    if len(image) < minimum_image_size:
        raise ValueError("Image is too small to contain an RKNS header")

    # Read the complete RKNS header from its physical image location.
    header = image[
        RKNS_OFFSET:
        RKNS_OFFSET + RKNS_HEADER_SIZE
    ]

    # Verify the RKNS structure signature.
    if header[0:4] != RKNS_MAGIC:
        raise ValueError("Invalid RKNS signature")

    # Read the configured hashing algorithm.
    hash_flag = struct.unpack_from(
        "<I",
        header,
        0x04,
    )[0]

    # Verify that the image declares SHA-256 hashing.
    if hash_flag != RKNS_SHA256_FLAG:
        raise ValueError(
            f"Unsupported RKNS hash flag: 0x{hash_flag:08x}"
        )

    # Read the RKNS control value.
    control = struct.unpack_from(
        "<I",
        header,
        0x08,
    )[0]

    # Verify the expected two-payload RKNS layout.
    if control != RKNS_CONTROL:
        raise ValueError(
            f"Unexpected RKNS control value: 0x{control:08x}"
        )

    # Read the SHA-256 digest stored inside the RKNS header.
    expected_header_digest = header[
        RKNS_HASH_OFFSET:
        RKNS_HASH_OFFSET + SHA256_SIZE
    ]

    # Recalculate the digest over the authenticated header region.
    actual_header_digest = sha256(
        header[:RKNS_HASH_DATA_SIZE]
    )

    # Reject the image if the RKNS header has been modified or corrupted.
    if actual_header_digest != expected_header_digest:
        raise ValueError("RKNS header SHA-256 mismatch")

    print("RKNS header: SHA-256 OK")

    # Validate the DDR initialization payload.
    validate_payload(
        image=image,
        header=header,
        descriptor_offset=DESCRIPTOR_1_OFFSET,
        payload_name="DDR",
    )

    # Validate the FeROS Stage 0 payload.
    validate_payload(
        image=image,
        header=header,
        descriptor_offset=DESCRIPTOR_2_OFFSET,
        payload_name="Stage 0",
    )

    print("RKNS image: VALID")


def build_command(arguments: argparse.Namespace) -> None:
    """Build an RKNS boot image from DDR and FeROS Stage 0 payloads."""

    # Load the RK3566 DDR initialization firmware.
    ddr_payload = arguments.ddr.read_bytes()

    # Load the compiled FeROS Stage 0 binary.
    stage0_payload = arguments.stage0.read_bytes()

    # Refuse to build an image without DDR initialization firmware.
    if not ddr_payload:
        raise ValueError("DDR payload is empty")

    # Refuse to build an image without FeROS Stage 0.
    if not stage0_payload:
        raise ValueError("Stage 0 payload is empty")

    # Construct the complete RKNS boot image.
    image = build_image(
        ddr_payload=ddr_payload,
        stage0_payload=stage0_payload,
    )

    # Ensure the output directory exists.
    arguments.output.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    # Write the generated image to disk.
    arguments.output.write_bytes(image)

    print(f"RKNS offset:  0x{RKNS_OFFSET:x}")
    print(f"DDR size:     {len(ddr_payload)} bytes")
    print(f"Stage 0 size: {len(stage0_payload)} bytes")
    print(f"Image size:   {len(image)} bytes")
    print(f"Output:       {arguments.output}")


def validate_command(arguments: argparse.Namespace) -> None:
    """Load and validate an existing RKNS boot image."""

    # Read the complete boot image from disk.
    image = arguments.image.read_bytes()

    # Validate its structure and cryptographic integrity.
    validate_image(image)


def create_parser() -> argparse.ArgumentParser:
    """Create and configure the FeROS RK3566 image-tool argument parser."""

    # Create the root command-line parser.
    parser = argparse.ArgumentParser(
        description="Build and validate Rockchip RK3566 RKNS images for FeROS."
    )

    # Create the collection of supported image operations.
    commands = parser.add_subparsers(
        dest="command",
        required=True,
    )

    # Define the image build operation.
    build_parser = commands.add_parser(
        "build",
        help="Build an RK3566 RKNS boot image.",
    )

    # Define the DDR firmware input used during image construction.
    build_parser.add_argument(
        "--ddr",
        required=True,
        type=Path,
        help="Path to the RK3566 DDR initialization payload.",
    )

    # Define the FeROS Stage 0 input used during image construction.
    build_parser.add_argument(
        "--stage0",
        required=True,
        type=Path,
        help="Path to the FeROS Stage 0 binary.",
    )

    # Define the destination for the generated RKNS image.
    build_parser.add_argument(
        "--output",
        required=True,
        type=Path,
        help="Path for the generated RK3566 boot image.",
    )

    # Associate the build command with its implementation.
    build_parser.set_defaults(handler=build_command)

    # Define the standalone image validation operation.
    validate_parser = commands.add_parser(
        "validate",
        help="Validate an existing RK3566 RKNS boot image.",
    )

    # Define the image that will be structurally validated.
    validate_parser.add_argument(
        "--image",
        required=True,
        type=Path,
        help="Path to the RK3566 RKNS boot image.",
    )

    # Associate the validation command with its implementation.
    validate_parser.set_defaults(handler=validate_command)

    return parser


def main() -> None:
    """Parse the command line and execute the requested image operation."""

    # Construct the complete command-line interface.
    parser = create_parser()

    # Parse the command-line arguments supplied by the caller.
    arguments = parser.parse_args()

    # Execute the handler associated with the selected operation.
    arguments.handler(arguments)


if __name__ == "__main__":
    # Execute the tool only when invoked directly.
    main()