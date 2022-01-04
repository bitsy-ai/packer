#!/bin/bash

set +eu

DEST=/boot/image_version.txt
echo "Writing $IMAGE_VERSION to $DEST"
echo "$IMAGE_VERSION" > "$DEST"
