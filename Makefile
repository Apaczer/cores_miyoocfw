MIYOO_CORES=$(shell cat cores_list)
TARGET_MACHINE=$(shell arm-linux-gcc -dumpmachine)

ifeq ($(TARGET_MACHINE), arm-miyoo-linux-musleabi)
mgba_platform=unix
else
mgba_platform=miyoo
endif

default: fetch build

fetch:
	./libretro-super/libretro-fetch.sh ${MIYOO_CORES}
	./libretro-super/libretro-fetch.sh mgba

build:
	platform=miyoo ARCH=arm CC=arm-linux-gcc CXX=arm-linux-g++ STRIP=arm-linux-strip \
		 ./libretro-super/libretro-build.sh ${MIYOO_CORES}
	platform=$(mgba_platform) ARCH=arm CC=arm-linux-gcc CXX=arm-linux-g++ STRIP=arm-linux-strip \
		./libretro-super/libretro-build.sh mgba
	arm-linux-strip --strip-unneeded ./dist/unix/*
