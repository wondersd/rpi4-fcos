# Rpi4 FCOS Image builder #

Builds images from matchbox ignition profiles for RPI4 target machines.

[RPI4 ipxe boot chain is not quite working](./docs/ipxe-bootchain-rpi4.md) so this is a work around to prebuild images for target machines as if they had been PXE booted.

## Usage ##

requires:

 * a matchbox instance with valid ignition configuration for target device
 * rpi firmware uploaded to `$MATCHBOX_URL/assets/raspberrypi-firmware/`, see `rpi-firmware-downloader.sh`
 * rpi4 uefi firmware downloaded and extracted to `$MATCHBOX_URL/assets/rpi4-uefi-firmware/`, see `rpi4-uefi-firmware-downloader.sh`

### Build Image ###

The following docker command will use the coreos-installer docker image to build a coreos image with rpi4 bootloader injection along with first boot directives from the target matchbox ignition profile.
```
$ docker run \
    --privileged \
    -v /dev:/dev \
    -v /run/udev:/run/udev \
    -v /sys:/sys \
    -e MATCHBOX_URL=... \
    -e MAC=... \
    -v $(pwd):/opt/rpi-fcos \
    -v $(pwd)/output:/var/lib/rpi-fcos \
    --entrypoint /opt/rpi-fcos/rpi-fcos-image-builder.sh \
    quay.io/coreos/coreos-installer:release

```

### Image Drive ###

The resulting image is to be flashed onto the target device 

```
# gunzip -c output/coreos-$MAC_ADDRESS.img.gz | sudo dd of=/dev/disk3 bs=512
```

UEFI settings on first boot

 * disable 3GB memory limit


## Future Improvements ##

Use this once implemented, https://github.com/coreos/coreos-installer/issues/158, to make a more generic core os loader image

May be able to use `--append-kargs` to implement https://github.com/coreos/coreos-installer/issues/158#issuecomment-622033677

embed nvram variables into distribution, rpi uefi emulates NVRAM in the .fd binary

https://github.com/tianocore/edk2-platforms/tree/master/Platform/RaspberryPi/RPi4#nvram

still need to figure out the structure of this NVRAM so can inject variables to remove the need for first boot uefi settings

 * https://wiki.osdev.org/UEFI#NVRAM_variables

## References ##

* https://fwmotion.com/blog/operating-systems/2020-09-09-coreos-on-raspi4/
* https://github.com/coreos/coreos-installer/blob/master/docs/getting-started.md
* https://github.com/coreos/fedora-coreos-tracker/issues/258
* https://www.raspberrypi.org/forums/viewtopic.php?t=304318