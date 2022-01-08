#!/bin/bash

# The following script should be run from the packer build host

set -xue

tmpimg="loopbackfile.img"
volumegroup="printnanny.vg"
rootlv="root.lv"
rootsize="4GiB"
homelv="home.lv"
homesize="1GiB"
mnt="/mnt/rpi"

dd if=/dev/zero of="$tmpimg" bs=100M count=60

loopback="$(losetup -P $(losetup -f) --show $tmpimg)"
echo "Mounted $tmpimg to $loopback"
loopbackp1="${loopback}p1"
loopbackp2="${loopback}p2"

parted "$loopback" mktable msdos
parted "$loopback" mkpart primary fat32 2048s 257MiB
parted "$loopback" mkpart primary ext4 257MiB 100%
parted "$loopback" set 2 lvm on
echo "Finished partioning $loopback"

wipefs --all "$loopbackp2"
pvcreate "$loopbackp2"
vgcreate "$volumegroup" "$loopbackp2"
lvcreate "$volumegroup" -Zn --name "$rootlv" --size "$rootsize"
lvcreate "$volumegroup" -Zn --name "$homelv" --size "$homesize"
echo "Created logical volumes: $rootlv $homelv"

rootfs_mapper="/dev/mapper/$volumegroup-$rootlv"
homefs_mapper="/dev/mapper/$volumegroup-$homelv"
mkfs.vfat -F 32 -n BOOT "$loopbackp1"
mkfs.ext4 -L rootfs "$rootfs_mapper"
mkfs.ext4 -L home "$homefs_mapper"

mkdir -p "$mnt"
mount "$rootfs_mapper" "$mnt"
mkdir -p "$mnt/boot"
mount "${loopback}p1" "$mnt/boot"
tar -xvf "$IMAGE_TARBALL" -C "${loopback}p2"

sed -i 's/root=PARTUUID=[a-z0-9]*-02/root=\/dev\/mapper\/$volumegroup-$rootlv/' "$mnt/boot/cmdline.txt"
sed -i 's/^PARTUUID=[a-z0-9]*-01/\/dev\/mmcblk0p1/' "$mnt/etc/fstab"
sed -i 's/^PARTUUID=[a-z0-9]*-02/\/dev\/mapper\/$volumegroup-$rootlv/' "$mnt/etc/fstab"

losetup --detatch "$loopback"