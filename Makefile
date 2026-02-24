
# General variables
CORES ?= $(shell cat cores_list)
BUILD_SUPER_DIR = libretro-super
PATCH_SUPER_DIR = super
PLATFORM ?= miyoo

# Compiler variables
CHAINPREFIX ?= /opt/miyoo
CROSS_COMPILE ?= $(CHAINPREFIX)/usr/bin/arm-linux-
ARCH ?= arm

CC = $(CROSS_COMPILE)gcc
CXX = $(CROSS_COMPILE)g++
STRIP = $(CROSS_COMPILE)strip
SYSROOT ?= $(shell$(CC) --print-sysroot)
TARGET_MACHINE=$(shell $(CC) -dumpmachine)

ifneq ($(findstring musl, $(TARGET_MACHINE)),)
target_libc=musl
else ifneq ($(findstring uclibc, $(TARGET_MACHINE)),)
target_libc=uclibc
else
target_libc=.
endif

print_status = echo "\033[34m --> $1\033[0m"

default: fetch build

patch-super:
	@for patch in $(sort $(wildcard patches/$(PATCH_SUPER_DIR)/*.patch)); do \
		$(call print_status, Applying $$patch); \
		patch -d $(BUILD_SUPER_DIR) -p1 < $$patch; \
	done

fetch:
	./$(BUILD_SUPER_DIR)/libretro-fetch.sh ${CORES}

build:
	ARCH=$(ARCH) CC=$(CC) CXX=$(CXX) STRIP=$(STRIP) \
	platform=$(PLATFORM) ./$(BUILD_SUPER_DIR)/libretro-build.sh ${CORES}
	$(STRIP) --strip-unneeded ./dist/unix/*

release: default
	@echo "Zip compress generated cores"
	@for f in ./dist/unix/*; \
		do [ -f "$$f" ] && \
		zip -m "$$f.zip" "$$f" && \
		echo "$$(stat -c '%y' $$f.zip | cut -f 1 -d ' ') $$(crc32 $$f.zip) $$f.zip" | tee -a .core-updater-list; \
	done
	@mkdir -p cores/$(target_libc)/latest
	mv ./dist/unix/* cores/$(target_libc)/latest/
	@echo "Update \"cores_list\" in .index-extended"
	@cat .core-updater-list > cores/$(target_libc)/latest/.index-extended
	@rm .core-updater-list
	@sort cores/$(target_libc)/latest/.index-extended -o cores/$(target_libc)/latest/.index-extended
