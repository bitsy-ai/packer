#!/usr/env/bin bash

set +ueo pipfail


BASE_NAME="${BASE_NAME:-printnanny-desktop}"
DIST_DIR="dist"

find_latest_env(){
    # get the latest datestamp
    ls "$DIST_DIR/$BASE_NAME" | sort | tail -n 1
}

BASE_IMAGE_ENV="${BASE_IMAGE:-find_latest_env}"

# detect latest $IMAGE_NAME build
# export $PACKER_VAR environment variables needed to build from latest base

