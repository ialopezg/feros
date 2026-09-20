CROSS_COMPILE ?= aarch64-elf-

CC      := $(CROSS_COMPILE)gcc
LD      := $(CROSS_COMPILE)ld
OBJCOPY := $(CROSS_COMPILE)objcopy
OBJDUMP := $(CROSS_COMPILE)objdump

# ---------------------------------------------------------------------------
# Platform
# ---------------------------------------------------------------------------

p ?= x55

BUILD_ROOT := build
BUILD_DIR  := $(BUILD_ROOT)/$(p)

ASFLAGS := \
	-ffreestanding \
	-nostdlib \
	-nostartfiles

ifeq ($(p),x55)
LINKER_SCRIPT   := arch/aarch64/boot/linker.ld
PLATFORM_OBJECT := $(BUILD_DIR)/soc/rockchip/rk3566/uart.o

else ifeq ($(p),qemu)
LINKER_SCRIPT   := boards/qemu/virt/linker.ld
PLATFORM_OBJECT := $(BUILD_DIR)/boards/qemu/virt/uart.o

else
$(error Unsupported platform "$(p)")
endif

FEROS_ELF := $(BUILD_DIR)/feros.elf
FEROS_BIN := $(BUILD_DIR)/feros.bin

OBJECTS := \
	$(BUILD_DIR)/arch/aarch64/boot/start.o \
	$(PLATFORM_OBJECT)

# ---------------------------------------------------------------------------
# Branding
# ---------------------------------------------------------------------------

ESC := \033

FE_COLOR := $(ESC)[38;5;208m
R_COLOR  := $(ESC)[38;5;220m
OS_COLOR := $(ESC)[38;5;34m
RESET    := $(ESC)[0m

FEROS := $(FE_COLOR)Fe$(R_COLOR)R$(OS_COLOR)OS$(RESET)

# ---------------------------------------------------------------------------
# Public targets
# ---------------------------------------------------------------------------

.PHONY: default x55 qemu all build inspect inspect-platform clean

default:
	@printf "$(FEROS): choose platform:\n\n"; \
	printf "  1) PowKiddy X55 (Rockchip RK3566)\n"; \
	printf "  2) QEMU ARM64 virt\n"; \
	printf "  3) All\n\n"; \
	printf "Select [1-3]: "; \
	read choice; \
	case "$$choice" in \
		1) $(MAKE) --no-print-directory x55 ;; \
		2) $(MAKE) --no-print-directory qemu ;; \
		3) $(MAKE) --no-print-directory all ;; \
		*) printf "\nInvalid selection.\n"; exit 1 ;; \
	esac

x55:
	@$(MAKE) --no-print-directory clean
	@$(MAKE) --no-print-directory \
		p=x55 \
		$(if $(filter inspect,$(MAKECMDGOALS)),inspect-platform,build)

qemu:
	@$(MAKE) --no-print-directory clean
	@$(MAKE) --no-print-directory \
		p=qemu \
		$(if $(filter inspect,$(MAKECMDGOALS)),inspect-platform,build)

all:
	@$(MAKE) --no-print-directory clean
	@$(MAKE) --no-print-directory p=x55 build
	@$(MAKE) --no-print-directory p=qemu build

inspect:
	@:

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

build: $(FEROS_ELF) $(FEROS_BIN)
	@printf "$(FEROS): $(p) bootstrap build complete.\n"

# ---------------------------------------------------------------------------
# AArch64 bootstrap
# ---------------------------------------------------------------------------

$(BUILD_DIR)/arch/aarch64/boot/start.o: arch/aarch64/boot/start.S
	@printf "$(FEROS): assembling AArch64 entry point...\n"
	@mkdir -p $(dir $@)
	@$(CC) $(ASFLAGS) -c $< -o $@
	@printf "$(FEROS): generated %s\n" "$@"

# ---------------------------------------------------------------------------
# PowKiddy X55 / Rockchip RK3566
# ---------------------------------------------------------------------------

$(BUILD_DIR)/soc/rockchip/rk3566/uart.o: soc/rockchip/rk3566/uart.S
	@printf "$(FEROS): assembling RK3566 early UART...\n"
	@mkdir -p $(dir $@)
	@$(CC) $(ASFLAGS) -c $< -o $@
	@printf "$(FEROS): generated %s\n" "$@"

# ---------------------------------------------------------------------------
# QEMU ARM64 virt
# ---------------------------------------------------------------------------

$(BUILD_DIR)/boards/qemu/virt/uart.o: boards/qemu/virt/uart.S
	@printf "$(FEROS): assembling QEMU virt early UART...\n"
	@mkdir -p $(dir $@)
	@$(CC) $(ASFLAGS) -c $< -o $@
	@printf "$(FEROS): generated %s\n" "$@"

# ---------------------------------------------------------------------------
# Link
# ---------------------------------------------------------------------------

$(FEROS_ELF): $(OBJECTS) $(LINKER_SCRIPT)
	@printf "$(FEROS): linking $(p) Stage 0...\n"
	@$(LD) -T $(LINKER_SCRIPT) -o $@ $(OBJECTS)
	@printf "$(FEROS): generated %s\n" "$@"

$(FEROS_BIN): $(FEROS_ELF)
	@printf "$(FEROS): generating $(p) Stage 0 binary...\n"
	@$(OBJCOPY) -O binary $< $@
	@printf "$(FEROS): generated %s\n" "$@"

# ---------------------------------------------------------------------------
# Inspection
# ---------------------------------------------------------------------------

inspect-platform: build
	@printf "$(FEROS): inspecting AArch64 entry point...\n\n"
	@$(OBJDUMP) -d $(BUILD_DIR)/arch/aarch64/boot/start.o
	@printf "\n$(FEROS): inspecting $(p) early UART...\n\n"
	@$(OBJDUMP) -d $(PLATFORM_OBJECT)
	@printf "\n$(FEROS): inspecting $(p) Stage 0 ELF...\n\n"
	@$(OBJDUMP) -f $(FEROS_ELF)

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

clean:
	@printf "$(FEROS): cleaning build artifacts...\n"
	@rm -rf $(BUILD_ROOT)