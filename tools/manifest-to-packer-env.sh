#!/usr/bin/env bash

# converts packer manifest.json into PACKER_VAR env file
# which can be used in a downstream build to use manifest.json referenced build as base
set +eu

echo "Creating packer.env from $MANIFEST_FILE"
cat "$MANIFEST_FILE"


echo "Using checksum $CHECKSUM_FILE"
BASE_IMAGE_CHECKSUM=$(cut -d $'\t' -f 1 < "$CHECKSUM_FILE")
BASE_IMAGE_DATESTAMP=$(jq --raw-output '.builds[-1].custom_data.image_datestamp' < "$MANIFEST_FILE")
BASE_IMAGE_EXT=$(jq --raw-output '.builds[-1].custom_data.image_ext' < "$MANIFEST_FILE")
BASE_IMAGE_FAMILY=$(jq --raw-output '.builds[-1].custom_data.image_family' < "$MANIFEST_FILE")
BASE_IMAGE_FILENAME=$(jq --raw-output '.builds[-1].custom_data.image_filename' < "$MANIFEST_FILE")
BASE_IMAGE_NAME=$(jq --raw-output '.builds[-1].custom_data.image_name' < "$MANIFEST_FILE")
BASE_IMAGE_OS_VERSION=$(jq --raw-output '.builds[-1].custom_data.image_os_verion' < "$MANIFEST_FILE")
BASE_IMAGE_URL=$(jq --raw-output '.builds[-1].custom_data.image_url' < "$MANIFEST_FILE")
BASE_IMAGE_VARIANT=$(jq --raw-output '.builds[-1].custom_data.image_variant' < "$MANIFEST_FILE")
# re-export as base_image_ vars prefixed with PACKER_VAR
cat << EOF > "$OUTPUT"
#!/usr/bin/env bash

export PACKER_VAR_BASE_IMAGE_CHECKSUM="$BASE_IMAGE_CHECKSUM"
export PACKER_VAR_BASE_IMAGE_DATESTAMP="$BASE_IMAGE_DATESTAMP"
export PACKER_VAR_BASE_IMAGE_EXT="$BASE_IMAGE_EXT"
export PACKER_VAR_BASE_IMAGE_FAMILY="$BASE_IMAGE_FAMILY"
export PACKER_VAR_BASE_IMAGE_NAME="$BASE_IMAGE_NAME"
export PACKER_VAR_BASE_IMAGE_URL="$BASE_IMAGE_URL"
export PACKER_VAR_BASE_IMAGE_VARIANT="$BASE_IMAGE_VARIANT"
export PACKER_VAR_BASE_IMAGE_FILENAME="$BASE_IMAGE_FILENAME"
export PACKER_VAR_BASE_IMAGE_OS_VERSION="$BASE_IMAGE_OS_VERSION"
EOF

echo "Created $OUTPUT"
cat "$OUTPUT"
