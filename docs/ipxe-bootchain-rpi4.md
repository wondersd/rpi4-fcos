# Current State of iPXE Bootchain on RPI 4 #

This outlines what I've found to be the current state of using matchbox for core os, and by extension ipxe booting, on the rpi 4.

This is mainly from the viewpoint of a zero storage network boot and self provisioning onto a blank storage media.

## RPI4 PXE Boot Chain ##

As of 2019 firmware update the RPI4 became PXE bootable.

This by itself is not enough for use with matchbox as matchbox is built ontop of ipxe. So we need to get from pxe to ipxe ot then be able to boot from matchbox.

IPXE support for rpi comes the the [UEFI firmware](https://github.com/pftf/RPi4).

So with the following bootchain we should in theory be able to network boot an rpi 4 with no storage requirments (sd card or usb)

 1. PXE bootable rpi4
 2. PXE boot environemnt that will serve RPI UEFI firmware to rpis via PXE boot
 3. Once UEFI is booted it will attempt to IPXE boot
 4. IPXE boot environment that will direct to matchbox for rpies that IPXE boot
 5. matchbox supplies boot configuration, kernel, initramfs to rpi4 and fcos is booted

There are some outstanding issues with this chain:

  * UEFI firmware is stock and needs two settings to be configured
    * update boot order to enable ipxe boot
    * disable 3GB limit (its enabled by default, core os can happily use all 8GB)

Without these the chain stops after the UEFI is booted and the rpi4 will just go into a boot loop.

In order to get past these they will have to be configured manually as the rpi4 is booting.

Its also conceviebly possible to make a custom build of the rpi4 uefi firmware that has these defaults changed, or to modify the area of the canonical build that is reserved to be used instead of nvram (rpi4 has no nvram so the uefi firmware saves settings by modifying a reserved section of the firmware binary)

## PXE Boot Environment Setup ##

The below setup assumes the following setup

 * a home router as the DHCP server running OpenWRT
 * router has a usb drive that is mounted as `/tftp` to serve files from.
 * matchbox host is served at `matchbox.lan` at port `8080`

### Enable dns query logging Open WRT ###

During development it was really useful to turn logging on for dnsmasq so that will be the first edits.

[enable logging openwrt](https://superuser.com/questions/632898/how-to-log-all-dns-requests-made-through-openwrt-router)

in the following file:

`/etc/config/dhcp`

add the block:

```
    config dnsmasq
        ...
        option logdhcp '1'
        option logqueries '1'
        option logfacility '/tmp/dnsmasq.log'
```

restart dnsmasq

`$ /etc/init.d/dnsmasq restart`


### RPi PXE boot network setup ###

In order for the same RPI4 to boot first PXE then IPXE the dhcp is going to need to be able to tell the two states appart and treat them differently. Will be able to create different "networks" one for when an rpi4 is PXE booted, and another when an rpi4 is IPXE booted. This will also help to further distingush other machines that may have other PXE needs.

https://www.raspberrypi.org/forums/viewtopic.php?t=294720

https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/net.md

https://forum.openwrt.org/t/pxe-legacy-efi-co-existence/23856/2


`/etc/config/dhcp`

```
config boot 'rpi4'
        option networkid 'rpi4'
        option filename 'ipxe-arm64.efi'
        list dhcp_option '43,Raspberry Pi Boot'
        option serveraddress '192.168.1.1'
        option servername 'OpenWrt'
```

```
config host
        option networkid 'rpi4'
        option name 'rpi4-test-host'
        option dns '1'
        option mac '...' # mac address for rpi4
        option ip '...'  # target ip address to assign
```

```
config userclass
        option networkid 'set:ipxe'
        option userclass 'iPXE'

config boot 'ipxe'
        option filename 'tag:ipxe,http://matchbox.lan:8080/boot.ipxe'
        option serveraddress '192.168.1.1'
        option servername 'OpenWrt'
```

https://boot.ipxe.org/arm64-efi/
https://github.com/raspberrypi/firmware/
https://github.com/pftf/RPi4

Start with empty dir with serial number of pi

```
/tftp/<pi serial>
```

1. extract contents of boot/ from raspberrypi/firmware
2. extract confix.txt and `RPI_EFI.fd` (this is the UEFI boot)
3. download ipxe.efi arm64 distro of boot.ipxe.org (efi based build for arm64 of ipxe)

* for image based install had to use the start.elf and fixup.dat from the rpi uefi distro. though i think that may have been not strictly required. need to do more testing.

from here pi will boot into uefi, but will have no boot config so will simply restart after timeout, <esc> loads config menu. from here pxe boot ipv4 can be chosen where it will request a pxefilename from dhcp which is configrued to be the efi ipxe. 

once ipxe is loaded it will re-request dhcp options this time with useragent `iPXE` that will match on the boot options `ipxe` to serve up the matchbox generated ipxe boot script.

Need to figure out how to inject uefi config to perform pxe boot, and then the ipxe script to run

probably something to do with dhcp options, https://www.iana.org/assignments/bootp-dhcp-parameters/bootp-dhcp-parameters.xhtml

load uefi onto rpi modify memory limit, save and shutdown

