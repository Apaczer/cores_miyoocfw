CORES ?= $(shell cat cores_list)
TARGET_MACHINE=$(shell arm-linux-gcc -dumpmachine)

ifeq ($(TARGET_MACHINE), arm-miyoo-linux-musleabi)
target_libc=musl
else
target_libc=uclibc
endif

default: fetch build

fetch:
	./libretro-super/libretro-fetch.sh ${CORES}

build:
	platform=miyoo ARCH=arm CC=arm-linux-gcc CXX=arm-linux-g++ STRIP=arm-linux-strip \
		 ./libretro-super/libretro-build.sh ${CORES}
	arm-linux-strip --strip-unneeded ./dist/unix/*

release:
	@mkdir -p cores/$(target_libc)/latest
	mv ./dist/unix/* cores/$(target_libc)/latest/
