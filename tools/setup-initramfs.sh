#!/bin/bash

# The following script should be run from a chroot build target

# install lvm and initramfs-tools
DEBIAN_FRONTEND=noninteractive apt update
DEBIAN_FRONTEND=noninteractive apt install -y initramfs-tools lvm2

# initramfs is required to boot Linux from a root filesystem in an LVM volume
# create initramfs image is created from a minimal list of modules, instead of the whole kitchen sink
sed -i 's/^MODULES=most/MODULES=list/' /etc/initramfs-tools/initramfs.conf
# update initrmfs image for current kernel
update-initramfs -u