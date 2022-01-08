#! /bin/sh -e
# Update reference to $INITRD in $BOOTCFG, making the kernel use the new
# initrd after the next reboot.
# Source: https://raspberrypi.stackexchange.com/a/100261
BOOTLDR_DIR=/boot
BOOTCFG=$BOOTLDR_DIR/config.txt
INITRD_PFX=initrd.img-
INITRD=$INITRD_PFX$version

case $1 in
    prereqs) echo; exit
esac

FROM="^ *\\(initramfs\\) \\+$INITRD_PFX.\\+ \\+\\(followkernel\\) *\$"
INTO="\\1 $INITRD \\2"

T=`umask 077 && mktemp --tmpdir genramfs_XXXXXXXXXX.tmp`
trap "rm -- \"$T\"" 0

sed "s/$FROM/$INTO/" "$BOOTCFG" > "$T"

# Update file only if necessary.
if ! cmp -s "$BOOTCFG" "$T"
then
    cat "$T" > "$BOOTCFG"
fi