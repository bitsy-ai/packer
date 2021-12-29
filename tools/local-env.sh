#!/bin/bash

PRINTNANNY_API_URL=http://aurora:8000
IMAGE_VARIANT="Desktop"
IMAGE_FILENAME=$(jq --raw-output '.builds[-1].custom_data.image_filename' < dist/manifest.json )
IMAGE_STAMP=$(jq --raw-output '.builds[-1].custom_data.image_stamp' < dist/manifest.json)
IMAGE_PATH=$(jq --raw-output '.builds[-1].custom_data.image_path' < dist/manifest.json)
IMAGE_URL="${CDN_BASE_URL}/${IMAGE_PATH}/${IMAGE_FILENAME}"
CHECKSUM_URL="${CDN_BASE_URL}/${IMAGE_PATH}/sha256.checksum"
MANIFEST_URL="${CDN_BASE_URL}/$IMAGE_PATH/manifest.json"
SIG_URL="${CHECKSUM_URL}.sig"
CHECKSUM="1234"

export PRINTNANNY_API_URL=$PRINTNANNY_API_URL
export IMAGE_VARIANT=$IMAGE_VARIANT
export IMAGE_FILENAME=$IMAGE_FILENAME
export IMAGE_STAMP=$IMAGE_STAMP
export IMAGE_URL=$IMAGE_URL
export CHECKSUM_URL=$CHECKSUM_URL
export MANIFEST_URL=$MANIFEST_URL
export SIG_URL=$SIG_URL
export CHECKSUM=$CHECKSUM