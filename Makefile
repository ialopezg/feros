CROSS_COMPILE ?= aarch64-elf-

CC      := $(CROSS_COMPILE)gcc
LD      := $(CROSS_COMPILE)ld
OBJCOPY := $(CROSS_COMPILE)objcopy
OBJDUMP := $(CROSS_COMPILE)objdump

# ---------------------------------------------------------------------------
# Platform
# ---------------------------------------------------------------------------

# Platform selected for the current build invocation.
p ?= all

# Root directory containing all generated build artifacts.
BUILD_ROOT := build

# Platform-specific directory containing generated build artifacts.
BUILD_DIR := $(BUILD_ROOT)/$(p)

# Compiler flags required to build freestanding FeROS bootstrap code.
ASFLAGS := \
	-ffreestanding \
	-nostdlib \
	-nostartfiles

ifeq ($(p),x55)

# Linker script used by the PowKiddy X55 Stage 0 bootstrap.
LINKER_SCRIPT := arch/aarch64/boot/linker.ld

# Platform-specific object providing the RK3566 early UART implementation.
PLATFORM_OBJECT := $(BUILD_DIR)/soc/rockchip/rk3566/uart.o

else ifeq ($(p),qemu)

# Linker script used by the QEMU ARM64 virt platform.
LINKER_SCRIPT := boards/qemu/virt/linker.ld

# Platform-specific object providing the QEMU virt early UART implementation.
PLATFORM_OBJECT := $(BUILD_DIR)/boards/qemu/virt/uart.o

endif

# Linked FeROS executable for the selected platform.
FEROS_ELF := $(BUILD_DIR)/feros.elf

# Raw FeROS Stage 0 binary for the selected platform.
FEROS_BIN := $(BUILD_DIR)/feros.bin

# Objects required by the selected platform bootstrap.
OBJECTS := \
	$(BUILD_DIR)/arch/aarch64/boot/start.o \
	$(PLATFORM_OBJECT)

# ---------------------------------------------------------------------------
# Rockchip RK3566 boot image
# ---------------------------------------------------------------------------

# Temporary RK3566 DDR initialization firmware dependency.
RK3566_DDR := soc/rockchip/rk3566/firmware/ddr.bin

# Tool responsible for building and validating RK3566 RKNS images.
RK3566_IMAGE_TOOL := tools/image/rk3566/mkimage.py

# Final boot image prepared for the PowKiddy X55.
X55_BOOT_IMAGE := $(BUILD_ROOT)/x55/boot/feros-x55.img

# ---------------------------------------------------------------------------
# Branding
# ---------------------------------------------------------------------------

# ANSI escape sequence used to produce FeROS terminal branding colors.
ESC := \033

# Terminal color representing the Ferrum component of the FeROS name.
FE_COLOR := $(ESC)[38;5;208m

# Terminal color representing the Retro component of the FeROS name.
R_COLOR := $(ESC)[38;5;220m

# Terminal color representing the Operating System component of the FeROS name.
OS_COLOR := $(ESC)[38;5;34m

# Terminal sequence used to restore the default terminal color.
RESET := $(ESC)[0m

# Colored FeROS name used by build-system messages.
FEROS := $(FE_COLOR)Fe$(R_COLOR)R$(OS_COLOR)OS$(RESET)

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

# Width used by build-system section separators.
OUTPUT_WIDTH := 59

# Print a major section separator.
define major_separator
	@printf '%*s\n' $(OUTPUT_WIDTH) '' | tr ' ' '*'
endef

# Print a minor section separator.
define minor_separator
	@printf '%*s\n' $(OUTPUT_WIDTH) '' | tr ' ' '-'
endef

# Print a centered major section header.
define major_header
	$(call major_separator)
	@printf '%*s\n' $$(( ($(OUTPUT_WIDTH) + $(shell printf '%s' '$(1)' | wc -c | tr -d ' ')) / 2 )) '$(1)'
	$(call major_separator)
endef

# Print the header used when building a platform.
define build_header
	@printf '\n$(FEROS): Starting to build: %s ...\n' '$(1)'
	$(call minor_separator)
endef

# Print the header used when inspecting a platform.
define inspect_header
	@printf '\n$(FEROS): Starting to inspect: %s ...\n' '$(1)'
	$(call minor_separator)
endef

# Print the header used when validating a platform.
define validate_header
	@printf '\n$(FEROS): Starting to validate: %s ...\n' '$(1)'
	$(call minor_separator)
endef

# ---------------------------------------------------------------------------
# Public targets
# ---------------------------------------------------------------------------

.PHONY: default menu \
	build-menu inspect-menu validate-menu \
	prepare-image-menu prepare-target-menu \
	x55 qemu all \
	build build-all build-x55 build-qemu \
	inspect-x55 inspect-qemu inspect-all inspect-platform \
	prepare-x55 prepare-target-x55 \
	validate-x55 validate-qemu validate-all validate-platform \
	run run-qemu \
	clean help

default: menu

# ---------------------------------------------------------------------------
# Engineering console
# ---------------------------------------------------------------------------

# Display the main FeROS engineering console.
menu:
	@printf "\n$(FEROS) — Engineering Console\n\n"; \
	printf "  1) Build\n"; \
	printf "  2) Inspect artifacts\n"; \
	printf "  3) Validate artifacts\n"; \
	printf "  4) Prepare boot image\n"; \
	printf "  5) Prepare target media\n"; \
	printf "  6) Run\n"; \
	printf "  7) Help\n"; \
	printf "  8) Quit\n\n"; \
	printf "Select [1-8]: "; \
	read choice; \
	case "$$choice" in \
		1) $(MAKE) --no-print-directory build-menu ;; \
		2) $(MAKE) --no-print-directory inspect-menu ;; \
		3) $(MAKE) --no-print-directory validate-menu ;; \
		4) $(MAKE) --no-print-directory prepare-image-menu ;; \
		5) $(MAKE) --no-print-directory prepare-target-menu ;; \
		6) $(MAKE) --no-print-directory run ;; \
		7) $(MAKE) --no-print-directory help ;; \
		8) printf "\n$(FEROS): quit.\n" ;; \
		*) printf "\nInvalid option\n" ;; \
	esac

# Display the platform selection menu used by build operations.
build-menu:
	@printf "\n$(FEROS): Build\n\n"; \
	printf "  1) All platforms\n"; \
	printf "  2) PowKiddy X55\n"; \
	printf "  3) QEMU ARM64 virt\n"; \
	printf "  4) Back\n\n"; \
	printf "Select [1-4]: "; \
	read choice; \
	case "$$choice" in \
		1) $(MAKE) --no-print-directory all ;; \
		2) $(MAKE) --no-print-directory x55 ;; \
		3) $(MAKE) --no-print-directory qemu ;; \
		4) $(MAKE) --no-print-directory menu ;; \
		*) printf "\nInvalid option\n" ;; \
	esac

# Display the platform selection menu used by artifact inspection.
inspect-menu:
	@printf "\n$(FEROS): Inspect artifacts\n\n"; \
	printf "  1) All platforms\n"; \
	printf "  2) PowKiddy X55\n"; \
	printf "  3) QEMU ARM64 virt\n"; \
	printf "  4) Back\n\n"; \
	printf "Select [1-4]: "; \
	read choice; \
	case "$$choice" in \
		1) $(MAKE) --no-print-directory inspect-all ;; \
		2) $(MAKE) --no-print-directory inspect-x55 ;; \
		3) $(MAKE) --no-print-directory inspect-qemu ;; \
		4) $(MAKE) --no-print-directory menu ;; \
		*) printf "\nInvalid option\n" ;; \
	esac

# Display the platform selection menu used by artifact validation.
validate-menu:
	@printf "\n$(FEROS): Validate artifacts\n\n"; \
	printf "  1) All platforms\n"; \
	printf "  2) PowKiddy X55\n"; \
	printf "  3) QEMU ARM64 virt\n"; \
	printf "  4) Back\n\n"; \
	printf "Select [1-4]: "; \
	read choice; \
	case "$$choice" in \
		1) $(MAKE) --no-print-directory validate-all ;; \
		2) $(MAKE) --no-print-directory validate-x55 ;; \
		3) $(MAKE) --no-print-directory validate-qemu ;; \
		4) $(MAKE) --no-print-directory menu ;; \
		*) printf "\nInvalid option\n" ;; \
	esac

# Display the platforms that currently support boot-image preparation.
prepare-image-menu:
	@printf "\n$(FEROS): Prepare boot image\n\n"; \
	printf "  1) PowKiddy X55 — RK3566 / RKNS\n"; \
	printf "  2) Back\n\n"; \
	printf "Select [1-2]: "; \
	read choice; \
	case "$$choice" in \
		1) $(MAKE) --no-print-directory prepare-x55 ;; \
		2) $(MAKE) --no-print-directory menu ;; \
		*) printf "\nInvalid option\n" ;; \
	esac

# Display the physical media targets currently supported by FeROS tooling.
prepare-target-menu:
	@printf "\n$(FEROS): Prepare target media\n\n"; \
	printf "  1) PowKiddy X55 — microSD\n"; \
	printf "  2) Back\n\n"; \
	printf "Select [1-2]: "; \
	read choice; \
	case "$$choice" in \
		1) $(MAKE) --no-print-directory prepare-target-x55 ;; \
		2) $(MAKE) --no-print-directory menu ;; \
		*) printf "\nInvalid option\n" ;; \
	esac

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

# Display the FeROS engineering workflow and direct Make targets.
help:
	@printf "\n$(FEROS) — Engineering Console\n\n"
	@printf "Workflow:\n\n"
	@printf "  Build                  Build platform ELF and binary artifacts\n"
	@printf "  Inspect artifacts      Inspect generated platform artifacts\n"
	@printf "  Validate artifacts     Validate existing generated artifacts\n"
	@printf "  Prepare boot image     Build and validate a platform boot image\n"
	@printf "  Prepare target media   Prepare physical boot media for a target\n"
	@printf "  Run                    Run FeROS on QEMU ARM64 virt\n\n"
	@printf "Direct commands:\n\n"
	@printf "  make x55               Build PowKiddy X55\n"
	@printf "  make qemu              Build QEMU ARM64 virt\n"
	@printf "  make all               Build all platforms\n\n"
	@printf "  make inspect-x55       Inspect PowKiddy X55 artifacts\n"
	@printf "  make inspect-qemu      Inspect QEMU ARM64 virt artifacts\n"
	@printf "  make inspect-all       Inspect all platform artifacts\n\n"
	@printf "  make validate-x55      Validate PowKiddy X55 artifacts\n"
	@printf "  make validate-qemu     Validate QEMU ARM64 virt artifacts\n"
	@printf "  make validate-all      Validate all platform artifacts\n\n"
	@printf "  make prepare-x55       Prepare and validate the X55 RKNS image\n"
	@printf "  make prepare-target-x55\n"
	@printf "                         Prepare X55 target media\n\n"
	@printf "  make run               Build and run FeROS on QEMU ARM64 virt\n"
	@printf "  make clean             Remove generated build artifacts\n"
	@printf "  make help              Show this help\n"

# ---------------------------------------------------------------------------
# Build orchestration
# ---------------------------------------------------------------------------

# Clean and build the PowKiddy X55 bootstrap artifacts.
x55:
	@$(MAKE) --no-print-directory clean
	$(call build_header,X55)
	@$(MAKE) --no-print-directory p=x55 build
	@printf '\n$(FEROS): process complete.\n'

# Clean and build the QEMU ARM64 virt bootstrap artifacts.
qemu:
	@$(MAKE) --no-print-directory clean
	$(call build_header,QEMU)
	@$(MAKE) --no-print-directory p=qemu build
	@printf '\n$(FEROS): process complete.\n'

# Clean and build every currently supported platform.
all:
	$(call major_header,Building ALL)
	@$(MAKE) --no-print-directory clean
	@$(MAKE) --no-print-directory build-all
	@printf '\n$(FEROS): process complete.\n'

# Build every platform without performing another global cleanup.
build-all:
	@$(MAKE) --no-print-directory p=x55 build-x55
	@$(MAKE) --no-print-directory p=qemu build-qemu

# Build the PowKiddy X55 bootstrap artifacts.
build-x55:
	$(call build_header,X55)
	@$(MAKE) --no-print-directory p=x55 build

# Build the QEMU ARM64 virt bootstrap artifacts.
build-qemu:
	$(call build_header,QEMU)
	@$(MAKE) --no-print-directory p=qemu build

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

# Build the ELF executable and raw Stage 0 binary for the selected platform.
build: $(FEROS_ELF) $(FEROS_BIN)
	@printf "$(FEROS): $(p) bootstrap build complete.\n"

# ---------------------------------------------------------------------------
# AArch64 bootstrap
# ---------------------------------------------------------------------------

# Assemble the generic AArch64 Stage 0 entry point.
$(BUILD_DIR)/arch/aarch64/boot/start.o: arch/aarch64/boot/start.S
	@printf "$(FEROS): assembling AArch64 entry point...\n"
	@mkdir -p $(dir $@)
	@$(CC) $(ASFLAGS) -c $< -o $@
	@printf "$(FEROS): generated %s\n" "$@"

# ---------------------------------------------------------------------------
# PowKiddy X55 / Rockchip RK3566
# ---------------------------------------------------------------------------

# Assemble the RK3566 platform UART implementation.
$(BUILD_DIR)/soc/rockchip/rk3566/uart.o: soc/rockchip/rk3566/uart.S
	@printf "$(FEROS): assembling RK3566 early UART...\n"
	@mkdir -p $(dir $@)
	@$(CC) $(ASFLAGS) -c $< -o $@
	@printf "$(FEROS): generated %s\n" "$@"

# Build the clean RKNS image required by the RK3566 BootROM.
$(X55_BOOT_IMAGE): $(FEROS_BIN) $(RK3566_DDR) $(RK3566_IMAGE_TOOL)
	@printf "$(FEROS): generating RK3566 RKNS boot image...\n"
	@python3 $(RK3566_IMAGE_TOOL) build \
		--ddr $(RK3566_DDR) \
		--stage0 $(FEROS_BIN) \
		--output $@
	@printf "$(FEROS): generated %s\n" "$@"

# ---------------------------------------------------------------------------
# QEMU ARM64 virt
# ---------------------------------------------------------------------------

# Assemble the QEMU virt platform UART implementation.
$(BUILD_DIR)/boards/qemu/virt/uart.o: boards/qemu/virt/uart.S
	@printf "$(FEROS): assembling QEMU virt early UART...\n"
	@mkdir -p $(dir $@)
	@$(CC) $(ASFLAGS) -c $< -o $@
	@printf "$(FEROS): generated %s\n" "$@"

# ---------------------------------------------------------------------------
# Link
# ---------------------------------------------------------------------------

# Link the selected platform Stage 0 executable.
$(FEROS_ELF): $(OBJECTS) $(LINKER_SCRIPT)
	@printf "$(FEROS): linking $(p) Stage 0...\n"
	@$(LD) -T $(LINKER_SCRIPT) -o $@ $(OBJECTS)
	@printf "$(FEROS): generated %s\n" "$@"

# Convert the linked Stage 0 executable into a raw binary payload.
$(FEROS_BIN): $(FEROS_ELF)
	@printf "$(FEROS): generating $(p) Stage 0 binary...\n"
	@$(OBJCOPY) -O binary $< $@
	@printf "$(FEROS): generated %s\n" "$@"

# ---------------------------------------------------------------------------
# Boot-image preparation
# ---------------------------------------------------------------------------

# Build, package, and validate the PowKiddy X55 RKNS boot image.
prepare-x55:
	$(call major_header,Preparing X55 boot image)
	@$(MAKE) --no-print-directory p=x55 build
	@$(MAKE) --no-print-directory p=x55 $(X55_BOOT_IMAGE)
	$(call validate_header,X55 boot image)
	@python3 $(RK3566_IMAGE_TOOL) validate \
		--image $(X55_BOOT_IMAGE)
	@printf '\n$(FEROS): boot image preparation complete.\n'

# ---------------------------------------------------------------------------
# Target-media preparation
# ---------------------------------------------------------------------------

# Enter X55 target-media preparation without modifying physical media.
#
# Physical-media detection and writing are intentionally not enabled yet.
# This target exists so destructive operations can later be added behind
# explicit device verification and confirmation safeguards.
prepare-target-x55:
	$(call major_header,Preparing X55 target media)
	@printf '\n$(FEROS): target: PowKiddy X55\n'
	@printf '$(FEROS): media:  microSD\n\n'
	@printf '$(FEROS): physical-media writing is not enabled yet.\n'
	@printf '$(FEROS): no storage device has been modified.\n'

# ---------------------------------------------------------------------------
# Inspection
# ---------------------------------------------------------------------------

# Inspect PowKiddy X55 build artifacts.
inspect-x55:
	$(call major_header,Inspecting X55)
	$(call inspect_header,X55)
	@$(MAKE) --no-print-directory p=x55 inspect-platform
	@printf '\n$(FEROS): process complete.\n'

# Inspect QEMU ARM64 virt build artifacts.
inspect-qemu:
	$(call major_header,Inspecting QEMU)
	$(call inspect_header,QEMU)
	@$(MAKE) --no-print-directory p=qemu inspect-platform
	@printf '\n$(FEROS): process complete.\n'

# Inspect build artifacts for every supported platform.
inspect-all:
	$(call major_header,Inspecting ALL)
	$(call inspect_header,X55)
	@$(MAKE) --no-print-directory p=x55 inspect-platform
	$(call inspect_header,QEMU)
	@$(MAKE) --no-print-directory p=qemu inspect-platform
	@printf '\n$(FEROS): process complete.\n'

# Inspect low-level bootstrap artifacts for the selected platform.
inspect-platform: build
	@printf "$(FEROS): inspecting AArch64 entry point...\n\n"
	@$(OBJDUMP) -d $(BUILD_DIR)/arch/aarch64/boot/start.o
	@printf "\n$(FEROS): inspecting $(p) early UART...\n\n"
	@$(OBJDUMP) -d $(PLATFORM_OBJECT)
	@printf "\n$(FEROS): inspecting $(p) Stage 0 ELF...\n\n"
	@$(OBJDUMP) -f $(FEROS_ELF)

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

# Validate existing PowKiddy X55 artifacts and its RKNS image when present.
validate-x55:
	$(call major_header,Validating X55)
	$(call validate_header,X55)
	@$(MAKE) --no-print-directory p=x55 validate-platform
	@if [ -f "$(X55_BOOT_IMAGE)" ]; then \
		python3 $(RK3566_IMAGE_TOOL) validate \
			--image $(X55_BOOT_IMAGE); \
	else \
		printf "$(FEROS): X55 boot image not present; skipping RKNS validation.\n"; \
	fi
	@printf '\n$(FEROS): process complete.\n'

# Validate existing QEMU ARM64 virt build artifacts.
validate-qemu:
	$(call major_header,Validating QEMU)
	$(call validate_header,QEMU)
	@$(MAKE) --no-print-directory p=qemu validate-platform
	@printf '\n$(FEROS): process complete.\n'

# Validate existing artifacts for every supported platform.
validate-all:
	$(call major_header,Validating ALL)
	$(call validate_header,X55)
	@$(MAKE) --no-print-directory p=x55 validate-platform
	@if [ -f "$(X55_BOOT_IMAGE)" ]; then \
		python3 $(RK3566_IMAGE_TOOL) validate \
			--image $(X55_BOOT_IMAGE); \
	else \
		printf "$(FEROS): X55 boot image not present; skipping RKNS validation.\n"; \
	fi
	$(call validate_header,QEMU)
	@$(MAKE) --no-print-directory p=qemu validate-platform
	@printf '\n$(FEROS): process complete.\n'

# Validate that the selected platform build artifacts exist.
validate-platform:
	@test -f "$(FEROS_ELF)" || { \
		printf "$(FEROS): missing %s\n" "$(FEROS_ELF)"; \
		exit 1; \
	}
	@test -f "$(FEROS_BIN)" || { \
		printf "$(FEROS): missing %s\n" "$(FEROS_BIN)"; \
		exit 1; \
	}
	@printf "$(FEROS): %s ELF: OK\n" "$(p)"
	@printf "$(FEROS): %s binary: OK\n" "$(p)"

# ---------------------------------------------------------------------------
# Execution
# ---------------------------------------------------------------------------

# Build and execute FeROS using the QEMU ARM64 virt platform.
run:
	@$(MAKE) --no-print-directory clean
	@$(MAKE) --no-print-directory p=qemu run-qemu

# Execute the selected QEMU build.
run-qemu: build
	$(call major_header,Running QEMU)
	@printf '\n$(FEROS): Starting QEMU ARM64 virt ...\n\n'
	@qemu-system-aarch64 \
		-machine virt \
		-cpu cortex-a55 \
		-nographic \
		-kernel $(FEROS_ELF)

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

# Remove all generated build artifacts.
clean:
	@rm -rf $(BUILD_ROOT)