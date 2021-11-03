# Print Nanny Packer

### Testing an Image

1. Install QEMU

```
sudo apt-get install qemu-sytem
```
or package manager of your choice

2. fdisk -l <img-file>

```
$ fdisk -l dist/2021-10-09-0439-print-nanny-main-buster-arm64.img 
Disk dist/2021-10-09-0439-print-nanny-main-buster-arm64.img: 4 GiB, 4294967296 bytes, 8388608 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x053b14ee

Device                                                  Boot  Start     End Sectors  Size Id Type
dist/2021-10-09-0439-print-nanny-main-buster-arm64.img1        8192  532479  524288  256M  c W95 FAT32 (LBA)
dist/2021-10-09-0439-print-nanny-main-buster-arm64.img2      532480 8388607 7856128  3.8G 83 Linux
```

Note start sector number. Partition info can also be found in Packer templates using packer-arm-builder.

```
  image_partitions {
    filesystem   = "vfat"
    mountpoint   = "/boot"
    name         = "boot"
    size         = "256M"
    start_sector = "8192"
    type         = "c"
  }
  image_partitions {
    filesystem   = "ext4"
    mountpoint   = "/"
    name         = "root"
    size         = "0"
    start_sector = "532480"
    type         = "83"
  }
```

3. Mount the rootfs for in-place editing (optional)

```
export START_SECTOR=532480
export IMAGE_FILE="${PWD}/dist/2021-10-09-0439-print-nanny-main-buster-arm64.img"
sudo mkdir -p /mnt/printnanny
sudo mount -v -o offset="${START_SECTOR}" -t ext4 "$IMAGE_FILE" /mnt/printnanny
```

4. Emulate with QEMU

```
qemu-system-arm \
-kernel ~/projects/qemu-rpi-kernel/kernel-qemu-5.4.51-buster \
-cpu arm64 \
-2048m \
-serial stdio \
-redir tcp:8022:22 \
-hda "$IMAGE_FILE" \
-no-reboot
```