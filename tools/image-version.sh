#!/bin/bash

set +eu

DEST=/boot/image_version.txt
echo "Writing $IMAGE_VERSION to $DEST"
echo "$IMAGE_VERSION" > "$DEST"
DEST=/boot/printnanny_os_version.txt
PRINTNANNY_OS_VERSION=$(ansible-galaxy collection list bitsyai.rpi | grep bitsyai.rpi | cut -d" " -f2)
echo "$PRINTNANNY_OS_VERSION" > "$DEST"