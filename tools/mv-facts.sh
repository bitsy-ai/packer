#!/bin/bash

ls -ahl /tmp/rpi_chroot
mv "$1" "$2" || echo "Ignoring failed mv ${1} to ${2}" 
