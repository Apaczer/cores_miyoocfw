SHELL := /bin/bash
.SHELLFLAGS := -O extglob -c

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

print_info = echo -e "\033[34m $1\033[0m"
print_error = echo -e "\033[31m $1\033[0m"

default: build

patch-super:
	@if ! test -f $(BUILD_SUPER_DIR)/libretro-build.sh; then \
		$(call print_error, libretro-super is missing -> run 'git submodule update --init --recursive'); \
		exit 1 ;\
	fi
	@for patch in $(sort $(wildcard patches/$(PATCH_SUPER_DIR)/*.patch)); do \
		$(call print_info, Applying $$patch); \
		patch -d $(BUILD_SUPER_DIR) -p1 < $$patch; \
	done
	touch patch-super

fetch:
	./$(BUILD_SUPER_DIR)/libretro-fetch.sh ${CORES}

build: patch-super fetch
	ARCH=$(ARCH) CC=$(CC) CXX=$(CXX) STRIP=$(STRIP) \
	platform=$(PLATFORM) ./$(BUILD_SUPER_DIR)/libretro-build.sh ${CORES}
	$(STRIP) --strip-unneeded ./dist/$(PLATFORM)/*

release: default
	@echo "Zip compress generated cores"
	@cd ./dist/$(PLATFORM); \
	for f in *; \
		do [ -f "$$f" ] && \
		zip -m "$$f.zip" "$$f" && \
		echo "$$(stat -c '%y' $$f.zip | cut -f 1 -d ' ') $$(crc32 $$f.zip) $$f.zip" | tee -a .core-updater-list; \
	done
	@mkdir -p cores/$(target_libc)/latest
	mv ./dist/$(PLATFORM)/* cores/$(target_libc)/latest/
	@echo "Update \"cores_list\" in .index-extended"
	@cat ./dist/$(PLATFORM)/.core-updater-list > cores/$(target_libc)/latest/.index-extended
	@rm ./dist/$(PLATFORM)/.core-updater-list
	@sort cores/$(target_libc)/latest/.index-extended -o cores/$(target_libc)/latest/.index-extended

clean:
	rm -rf libretro-!(super)
	rm -rf dist/*
	rm -rf log

clean-all: clean
	rm -rf libretro-super
	-rm patch-super