#!/bin/bash -xe

OUTPUT_DIR=${OUTPUT_DIR:="/var/lib/rpi-fcos"}

RPI_FIRMWARE_VERSION=${RPI_FIRMWARE_VERSION:="1.20210201"}

RPI_UEFI_FIRMWARE_VERSION=${RPI_UEFI_FIRMWARE_VERSION="v1.24"}

mkdir -p $OUTPUT_DIR

for i in $(sudo losetup -a | grep coreos.img | awk -F : '{print $1}'); do
	echo "unmounting $i""p2"
	sudo umount $i"p2" || echo "already unmounted"
	echo "unlooping $i""p2"
	sudo losetup -d $i || echo "already unlooped"
done

IMAGE_DIR=$(mktemp -d)

IMAGE_TARGET="$IMAGE_DIR/coreos.img"

echo "creating image target $IMAGE_TARGET"
dd if=/dev/zero of=$IMAGE_TARGET bs=1 count=0 seek=10G
echo "mounting image on loop"
sudo losetup -fP $IMAGE_TARGET
TARGET_DEVICE=$(sudo losetup -a | grep coreos.img | awk -F : '{print $1}')
echo "mounted to $TARGET_DEVICE"

IMAGE_URL=$(curl $MATCHBOX_URL/ipxe?mac=$MAC 2>/dev/null | tr ' ' '\n' | grep 'coreos.inst.image_url' | awk -F '=' '{print $2}')

coreos-installer \
	install \
	$TARGET_DEVICE \
	--ignition-url $MATCHBOX_URL/ignition?mac=$MAC \
	--image-url $IMAGE_URL \
	--insecure-ignition

BOOT_PARTITION_MOUNT=$(mktemp -d)

mount -o loop "${TARGET_DEVICE}p2" $BOOT_PARTITION_MOUNT

pushd $BOOT_PARTITION_MOUNT

# inject RPI firmware

curl $MATCHBOX_URL/assets/raspberrypi-firmware/raspberrypi-firmware-$RPI_FIRMWARE_VERSION.tar.gz \
	| tar -xvz firmware-$RPI_FIRMWARE_VERSION/boot \
		--strip-components 2 \
		--exclude=firmware-$RPI_FIRMWARE_VERSION/boot/start* \
		--exclude=firmware-$RPI_FIRMWARE_VERSION/boot/fixup* \
		--exclude=firmware-$RPI_FIRMWARE_VERSION/boot/bootcode.bin \
		--exclude=firmware-$RPI_FIRMWARE_VERSION/boot/kernel*

# overlay rpi4 UEFI firmware

curl -O $MATCHBOX_URL/assets/rpi4-uefi-firmware/RPi4_UEFI_Firmware_$RPI_UEFI_FIRMWARE_VERSION/RPI_EFI.fd
curl -O $MATCHBOX_URL/assets/rpi4-uefi-firmware/RPi4_UEFI_Firmware_$RPI_UEFI_FIRMWARE_VERSION/config.txt
curl -O $MATCHBOX_URL/assets/rpi4-uefi-firmware/RPi4_UEFI_Firmware_$RPI_UEFI_FIRMWARE_VERSION/start4.elf
curl -O $MATCHBOX_URL/assets/rpi4-uefi-firmware/RPi4_UEFI_Firmware_$RPI_UEFI_FIRMWARE_VERSION/fixup4.dat

popd

umount "${TARGET_DEVICE}p2" || echo "already unmounted"

SECTOR_SIZE=$(fdisk -l $TARGET_DEVICE 2>/dev/null | grep 'Sector size' | awk '{print $7}')
LAST_SECTOR=$(fdisk -l $TARGET_DEVICE 2>/dev/null | tail -n 1 | awk '{print $3}')

dd if=$TARGET_DEVICE bs=$SECTOR_SIZE count=$LAST_SECTOR | gzip -c > $OUTPUT_DIR/coreos-$MAC.img.gz