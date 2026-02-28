SHELL := /bin/bash
.SHELLFLAGS := -O extglob -c

.DEFAULT:
	@echo "No rule for '$@'."
	@echo "Run 'make help'";
	@exit 1

# General variables
CORES ?= $(shell cat cores_list)
BUILD_SUPER_DIR = libretro-super
PATCH_SUPER_DIR = super
PLATFORM ?= miyoo
SKIP_UNCHANGED ?= "" #ifdef will skip builds with the same git revisions
BUILD_REVISIONS_DIR ?= cores/$(target_libc)/build-revisions-latest #dir for build_save_revision
WORKDIR= $(shell realpath .)

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

INDEX = cores/$(target_libc)/latest/.index-extended

print_info = printf "\033[34m $1\033[0m\n"
print_error = printf "\033[31m $1\033[0m\n"

default: build
	@mkdir -p cores/$(target_libc)/latest

patch-super:
	@if ! test -f $(BUILD_SUPER_DIR)/libretro-build.sh; then \
		$(call print_error, libretro-super is missing -> run 'git submodule update --init --recursive'); \
		exit 1 ;\
	fi
	@for patch in $(sort $(wildcard patches/$(PATCH_SUPER_DIR)/*.patch)); do \
		$(call print_info, Applying $$patch); \
		patch -d $(BUILD_SUPER_DIR) -p1 < $$patch; \
	done
	@touch patch-super

fetch:
	./$(BUILD_SUPER_DIR)/libretro-fetch.sh ${CORES}

build: patch-super fetch
	ARCH=$(ARCH) CC=$(CC) CXX=$(CXX) STRIP=$(STRIP) \
	SKIP_UNCHANGED=$(SKIP_UNCHANGED) BUILD_REVISIONS_DIR=$(WORKDIR)/$(BUILD_REVISIONS_DIR) \
	platform=$(PLATFORM) \
	./$(BUILD_SUPER_DIR)/libretro-build.sh ${CORES}
	@if ! find dist/$(PLATFORM) -maxdepth 1 -type f | read; then \
		$(call print_error, The "dist/" dir is empty = nothing to update -> Exiting...); \
		exit 1 ;\
	fi
	$(STRIP) --strip-unneeded ./dist/$(PLATFORM)/*.so

dist-zip: default
	@echo "Zip compress generated cores"
	@cd ./dist/$(PLATFORM); \
	for f in *.so; \
		do [ -f "$$f" ] && \
		zip -m "$$f.zip" "$$f"; \
	done

index:
	@if ! find dist/$(PLATFORM) -maxdepth 1 -type f -name "*.zip" | read; then \
		$(call print_error, The "dist/$(PLATFORM)" dir has no ZIP'ed cores -> run 'make dist-zip'); \
		exit 1 ;\
	fi
	@echo "Update \"cores_list\" in .index-extended"
	@cd ./dist/$(PLATFORM); \
	for f in *.zip; \
		do [ -f "$$f" ] && \
		echo "$$(stat -c '%y' $$f | cut -f 1 -d ' ') $$(crc32 $$f) $$f" | tee -a .core-updater-list; \
	done
	@cat ./dist/$(PLATFORM)/.core-updater-list >> $(INDEX)
	@rm ./dist/$(PLATFORM)/.core-updater-list
	@sort -r --key=1,1 --key=3,3 $(INDEX) -o $(INDEX); \
	uniq --skip-fields=2 $(INDEX) /tmp/index.temp && \
	mv /tmp/index.temp $(INDEX);
	@sort -r --key=3,3 $(INDEX) -o $(INDEX); \
	uniq --skip-fields=2 $(INDEX) /tmp/index.temp && \
	mv /tmp/index.temp $(INDEX);
	sort -k3,3 $(INDEX) -o $(INDEX)

index-rebuild:
	@echo "Update \"cores_list\" in .index-extended"
	@cd cores/$(target_libc)/latest; \
	rm -f .index-extended; \
	for f in *; \
		do [ -f "$$f" ] && \
		echo "$$(stat -c '%y' $$f | cut -f 1 -d ' ') $$(crc32 $$f) $$f" | tee -a .index-extended; \
	done

release: dist-zip index
	mv ./dist/$(PLATFORM)/* cores/$(target_libc)/latest/

help:
	@echo "  make fetch|build|dist-zip|index|index-rebuild"

clean:
	rm -rf libretro-!(super)
	rm -rf dist/*
	rm -rf log

clean-all: clean
	rm -rf libretro-super
	-rm patch-super