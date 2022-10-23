#!/bin/bash

RPI_UEFI_VERSION=${RPI_UEFI_VERSION:="v1.24"}

wget https://github.com/pftf/RPi4/releases/download/$RPI_UEFI_VERSION/RPi4_UEFI_Firmware_$RPI_UEFI_VERSION.zip -O RPi4_UEFI_Firmware_$RPI_UEFI_VERSION.zip

# explode the zip as coreos-installer image doesnt have unzip
mkdir RPi4_UEFI_Firmware_$RPI_UEFI_VERSION
cd RPi4_UEFI_Firmware_$RPI_UEFI_VERSION
unzip RPi4_UEFI_Firmware_$RPI_UEFI_VERSION.zip