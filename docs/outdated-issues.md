# Outdated Issues #

Reference to issues ran into in one point or another for posterity.

## tune2fs failing ##



https://typhoon.psdn.io/advanced/customization/#fedora-coreos

tune2fs fails when date is incorrect

http://patchwork.ozlabs.org/project/linux-ext4/patch/20170823154210.8756-4-tytso@mit.edu/

error is based on modified time

https://github.com/coreos/ignition/issues/870

during ignition phase date is the build time of the UEFI bios

will compensate by shifting the date of the iso builder to before then

in minikube have to disable the vboxservice `systemctl stop vboxservice`

RPIUEFI buld v24 has date of 'feb 26 2021'

set to beginning of 2021 to give it plenty of time 
date +%Y%m%d -s "20210101"

## UEFI DeviceTree Setting ##

**NOTE** This no longer seems to be needed in fcos 35+

 * AHCI + device tree