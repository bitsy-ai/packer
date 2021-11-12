#!/usr/bin/env bash

set +eu

OUT_DIR=env

mkdir -p $OUT_DIR

export IMAGE_NAME=$(cat dist/manifest.json | jq --raw-output '.builds[-1].custom_data.image_name')
export IMAGE_STAMP=$(cat dist/manifest.json | jq --raw-output '.builds[-1].custom_data.image_stamp')
export IMAGE_PATH=$(cat dist/manifest.json | jq --raw-output '.builds[-1].custom_data.image_path')
export IMAGE_URL=${CDN_BASE_URL}/${IMAGE_PATH}/${IMAGE_NAME}
export CHECKSUM_URL=${CDN_BASE_URL}/${IMAGE_PATH}/sha256.checksum
export MANIFEST_URL=${CDN_BASE_URL}/$IMAGE_PATH/manifest.json

OUTFILE="$OUT_DIR/$IMAGE_NAME.sh"
cat << EOF > $OUTFILE
#!/usr/bin/env bash
export IMAGE_PATH=$IMAGE_PATH
export IMAGE_STAMP=$IMAGE_STAMP

export BASE_IMAGE_NAME=$IMAGE_NAME
export PKR_VAR_base_image_name=$IMAGE_NAME

export IMAGE_URL=$IMAGE_URL
export PKR_VAR_base_image_url=$IMAGE_URL

export CHECKSUM_URL=$CHECKSUM_URL
export PKR_VAR_base_image_checksum=$CHECKSUM_URL

export MANIFEST_URL=$MANIFEST_URL
export PKR_VAR_base_manifest_url=$MANIFEST_URL
EOF

echo "Created $OUTFILE"
cat $OUTFILE

OUTFILE="$OUT_DIR/$IMAGE_NAME.env"
cat << EOF > $OUTFILE
IMAGE_PATH=$IMAGE_PATH
IMAGE_STAMP=$IMAGE_STAMP

BASE_IMAGE_NAME=$IMAGE_NAME
PKR_VAR_base_image_name=$IMAGE_NAME

IMAGE_URL=$IMAGE_URL
PKR_VAR_base_image_url=$IMAGE_URL

CHECKSUM_URL=$CHECKSUM_URL
PKR_VAR_base_image_checksum=$CHECKSUM_URL

MANIFEST_URL=$MANIFEST_URL
PKR_VAR_base_manifest_url=$MANIFEST_URL
EOF
