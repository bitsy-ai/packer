#!/usr/bin/env bash

set +eu

OUT_DIR=dist

mkdir -p $OUT_DIR

IMAGE_FILENAME=$(jq --raw-output '.builds[-1].custom_data.image_filename < dist/manifest.json')
IMAGE_NAME=$(jq --raw-output '.builds[-1].custom_data.image_name' < dist/manifest.json)
IMAGE_STAMP=$(jq --raw-output '.builds[-1].custom_data.image_stamp' < dist/manifest.json)
IMAGE_PATH=$(jq --raw-output '.builds[-1].custom_data.image_path' < dist/manifest.json)
IMAGE_URL=${CDN_BASE_URL}/${IMAGE_PATH}/${IMAGE_FILENAME}
CHECKSUM_URL=${CDN_BASE_URL}/${IMAGE_PATH}/sha256.checksum
MANIFEST_URL=${CDN_BASE_URL}/$IMAGE_PATH/manifest.json
SIG_URL="${CDN_BASE_URL}.sig"
CHECKSUM=$(cat dist/sha256.checksum)

OUTFILE="$OUT_DIR/$IMAGE_NAME.sh"
cat << EOF > "$OUTFILE"
#!/usr/bin/env bash
export IMAGE_FILENAME="$IMAGE_FILENAME"
export IMAGE_PATH="$IMAGE_PATH"
export IMAGE_STAMP="$IMAGE_STAMP"
export BASE_IMAGE_NAME="$IMAGE_NAME"
export IMAGE_URL="$IMAGE_URL"
export CHECKSUM_URL="$CHECKSUM_URL"
export MANIFEST_URL="$MANIFEST_URL"
export CHECKSUM="$CHECKSUM"
export SIG_URL="$SIG_URL"
EOF

echo "Created $OUTFILE"
cat "$OUTFILE"
