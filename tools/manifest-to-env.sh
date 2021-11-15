#!/usr/bin/env bash

set +eu

OUT_DIR=dist

mkdir -p $OUT_DIR

export IMAGE_FILENAME=$(cat dist/manifest.json | jq --raw-output '.builds[-1].custom_data.image_filename')
export IMAGE_NAME=$(cat dist/manifest.json | jq --raw-output '.builds[-1].custom_data.image_name')
export IMAGE_STAMP=$(cat dist/manifest.json | jq --raw-output '.builds[-1].custom_data.image_stamp')
export IMAGE_PATH=$(cat dist/manifest.json | jq --raw-output '.builds[-1].custom_data.image_path')
export IMAGE_URL=${CDN_BASE_URL}/${IMAGE_PATH}/${IMAGE_FILENAME}
export CHECKSUM_URL=${CDN_BASE_URL}/${IMAGE_PATH}/sha256.checksum
export MANIFEST_URL=${CDN_BASE_URL}/$IMAGE_PATH/manifest.json

OUTFILE="$OUT_DIR/$IMAGE_NAME.sh"
cat << EOF > $OUTFILE
#!/usr/bin/env bash
export IMAGE_FILENAME=$IMAGE_FILENAME
export IMAGE_PATH=$IMAGE_PATH
export IMAGE_STAMP=$IMAGE_STAMP
export BASE_IMAGE_NAME=$IMAGE_NAME
export IMAGE_URL=$IMAGE_URL
export CHECKSUM_URL=$CHECKSUM_URL
export MANIFEST_URL=$MANIFEST_URL
EOF

echo "Created $OUTFILE"
cat $OUTFILE

OUTFILE="$OUT_DIR/$IMAGE_NAME.pkr.env"
cat << EOF > $OUTFILE
PKR_VAR_base_image_url="file:$OUT_DIR/$IMAGE_NAME/$IMAGE_FILENAME
PKR_VAR_base_image_checksum="file:$OUT_DIR/$IMAGE_NAME/sha256.checksum"
EOF
