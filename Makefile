CROSS_COMPILE ?= aarch64-elf-

CC      := $(CROSS_COMPILE)gcc
LD      := $(CROSS_COMPILE)ld
OBJCOPY := $(CROSS_COMPILE)objcopy
OBJDUMP := $(CROSS_COMPILE)objdump

# ---------------------------------------------------------------------------
# Platform
# ---------------------------------------------------------------------------

p ?= all

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
# Output
# ---------------------------------------------------------------------------

OUTPUT_WIDTH := 59

define major_separator
	@printf '%*s\n' $(OUTPUT_WIDTH) '' | tr ' ' '*'
endef

define minor_separator
	@printf '%*s\n' $(OUTPUT_WIDTH) '' | tr ' ' '-'
endef

define major_header
	$(call major_separator)
	@printf '%*s\n' $$(( ($(OUTPUT_WIDTH) + $(shell printf '%s' '$(1)' | wc -c | tr -d ' ')) / 2 )) '$(1)'
	$(call major_separator)
endef

define build_header
	@printf '\n$(FEROS): Starting to build: %s ...\n' '$(1)'
	$(call minor_separator)
endef

define inspect_header
	@printf '\n$(FEROS): Starting to inspect: %s ...\n' '$(1)'
	$(call minor_separator)
endef

# ---------------------------------------------------------------------------
# Public targets
# ---------------------------------------------------------------------------

.PHONY: default \
	x55 qemu all \
	build build-all build-x55 build-qemu build-all-public \
	inspect inspect-x55 inspect-qemu inspect-all inspect-platform \
	run run-qemu \
	clean help

default:
	@printf "$(FEROS): choose platform:\n\n"; \
	printf "  1) All\n"; \
	printf "  2) PowKiddy X55 (Rockchip RK3566)\n"; \
	printf "  3) QEMU ARM64 virt\n"; \
	printf "  4) Help\n"; \
	printf "  5) Quit\n\n"; \
	printf "Select [1-5]: "; \
	read choice; \
	case "$$choice" in \
		1) $(MAKE) --no-print-directory all ;; \
		2) $(MAKE) --no-print-directory x55 ;; \
		3) $(MAKE) --no-print-directory qemu ;; \
		4) $(MAKE) --no-print-directory help ;; \
		5) printf "\n$(FEROS): quit.\n" ;; \
		*) printf "\nInvalid option\n" ;; \
	esac

help:
	@printf "$(FEROS) commands:\n\n"
	@printf "  make                  Show platform menu\n\n"
	@printf "  make x55              Build PowKiddy X55\n"
	@printf "  make qemu             Build QEMU ARM64 virt\n"
	@printf "  make all              Build all platforms\n\n"
	@printf "  make inspect x55      Inspect PowKiddy X55\n"
	@printf "  make inspect qemu     Inspect QEMU ARM64 virt\n"
	@printf "  make inspect all      Inspect all platforms\n\n"
	@printf "  make run              Run FeROS on QEMU\n\n"
	@printf "  make clean            Remove build artifacts\n"
	@printf "  make help             Show this help\n"

x55:
	@if echo "$(MAKECMDGOALS)" | grep -qw run; then \
		:; \
	elif echo "$(MAKECMDGOALS)" | grep -qw inspect; then \
		$(MAKE) --no-print-directory inspect-x55; \
	else \
		$(MAKE) --no-print-directory clean; \
		$(MAKE) --no-print-directory p=x55 build-x55; \
		printf '\n$(FEROS): process complete.\n'; \
	fi

qemu:
	@if echo "$(MAKECMDGOALS)" | grep -qw run; then \
		:; \
	elif echo "$(MAKECMDGOALS)" | grep -qw inspect; then \
		$(MAKE) --no-print-directory inspect-qemu; \
	else \
		$(MAKE) --no-print-directory clean; \
		$(MAKE) --no-print-directory p=qemu build-qemu; \
		printf '\n$(FEROS): process complete.\n'; \
	fi

all:
	@if echo "$(MAKECMDGOALS)" | grep -qw run; then \
		:; \
	elif echo "$(MAKECMDGOALS)" | grep -qw inspect; then \
		$(MAKE) --no-print-directory inspect-all; \
	else \
		$(MAKE) --no-print-directory build-all-public; \
	fi

inspect:
	@if [ "$(words $(filter x55 qemu all,$(MAKECMDGOALS)))" -ne 1 ]; then \
		printf "Invalid option\n"; \
	fi

run:
	@if [ "$(words $(MAKECMDGOALS))" -ne 1 ]; then \
		printf "Invalid option\n"; \
	else \
		$(MAKE) --no-print-directory clean; \
		$(MAKE) --no-print-directory p=qemu run-qemu; \
	fi

# ---------------------------------------------------------------------------
# Build orchestration
# ---------------------------------------------------------------------------

build-all-public:
	$(call major_header,Building ALL)
	@$(MAKE) --no-print-directory clean
	@$(MAKE) --no-print-directory build-all
	@printf '\n$(FEROS): process complete.\n'

build-all:
	@$(MAKE) --no-print-directory p=x55 build-x55
	@$(MAKE) --no-print-directory p=qemu build-qemu

build-x55:
	$(call build_header,X55)
	@$(MAKE) --no-print-directory p=x55 build

build-qemu:
	$(call build_header,QEMU)
	@$(MAKE) --no-print-directory p=qemu build

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
# Inspection orchestration
# ---------------------------------------------------------------------------

inspect-x55:
	$(call major_header,Inspecting X55)
	$(call inspect_header,X55)
	@$(MAKE) --no-print-directory p=x55 inspect-platform
	@printf '\n$(FEROS): process complete.\n'

inspect-qemu:
	$(call major_header,Inspecting QEMU)
	$(call inspect_header,QEMU)
	@$(MAKE) --no-print-directory p=qemu inspect-platform
	@printf '\n$(FEROS): process complete.\n'

inspect-all:
	$(call major_header,Inspecting ALL)
	$(call inspect_header,X55)
	@$(MAKE) --no-print-directory p=x55 inspect-platform
	$(call inspect_header,QEMU)
	@$(MAKE) --no-print-directory p=qemu inspect-platform
	@printf '\n$(FEROS): process complete.\n'

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
# Execution
# ---------------------------------------------------------------------------

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

clean:
	@rm -rf $(BUILD_ROOT)