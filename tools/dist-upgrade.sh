#!/usr/bin/env bash

set -eux

# Expects env vars set:
# $IMAGE_VERSION
# $DRYRUN

echo "$IMAGE_VERSION" > /boot/image_version.txt

if [[ $DRYRUN == true ]] 
then
    echo "(DRYRUN) DEBIAN_FRONTEND=noninteractive sudo apt-get update"
    echo "(DRYRUN) DEBIAN_FRONTEND=noninteractive sudo apt-get install -y libfuse2"
    echo "(DRYRUN) DEBIAN_FRONTEND=noninteractive sudo apt-get -y dist-upgrade"

else
    DEBIAN_FRONTEND=noninteractive apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y libfuse2
    DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
fi