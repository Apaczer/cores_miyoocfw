CORES ?= $(shell cat cores_list)
TARGET_MACHINE=$(shell arm-linux-gcc -dumpmachine)
BUILD_SUPER_DIR = libretro-super
PATCH_SUPER_DIR = super

ifeq ($(TARGET_MACHINE), arm-miyoo-linux-musleabi)
target_libc=musl
else
target_libc=uclibc
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
	platform=miyoo ARCH=arm CC=arm-linux-gcc CXX=arm-linux-g++ STRIP=arm-linux-strip \
		 ./$(BUILD_SUPER_DIR)/libretro-build.sh ${CORES}
	arm-linux-strip --strip-unneeded ./dist/unix/*

release:
	@mkdir -p cores/$(target_libc)/latest
	mv ./dist/unix/* cores/$(target_libc)/latest/
