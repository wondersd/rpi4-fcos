#!/bin/sh

RPI_FIRMWARE_VERSION=${RPI_FIRMWARE_VERSION:="1.20210201"}

wget https://github.com/raspberrypi/firmware/archive/refs/tags/$RPI_FIRMWARE_VERSION.tar.gz -O raspberrypi-firmware-$RPI_FIRMWARE_VERSION.tar.gz