#!/usr/bin/env bash

# converts packer manifest.json into PKR_VAR env file
# which can be used in a downstream build to use manifest.json referenced build as base
set +eu

echo "Creating packer.env from $MANIFEST_FILE"
cat "$MANIFEST_FILE"


echo "Using checksum $CHECKSUM_FILE"
# BASE_IMAGE_CHECKSUM=$(cut -d $'\t' -f 1 < "$CHECKSUM_FILE")
BASE_IMAGE_DATESTAMP=$(jq --raw-output '.builds[-1].custom_data.image_datestamp' < "$MANIFEST_FILE")
BASE_IMAGE_EXT=$(jq --raw-output '.builds[-1].custom_data.image_ext' < "$MANIFEST_FILE")
BASE_IMAGE_FAMILY=$(jq --raw-output '.builds[-1].custom_data.image_family' < "$MANIFEST_FILE")
BASE_IMAGE_FILENAME=$(jq --raw-output '.builds[-1].custom_data.image_filename' < "$MANIFEST_FILE")
BASE_IMAGE_NAME=$(jq --raw-output '.builds[-1].custom_data.image_name' < "$MANIFEST_FILE")
BASE_IMAGE_OS_VERSION=$(jq --raw-output '.builds[-1].custom_data.image_os_version' < "$MANIFEST_FILE")
BASE_IMAGE_URL=$(jq --raw-output '.builds[-1].custom_data.image_url' < "$MANIFEST_FILE")
BASE_IMAGE_VARIANT=$(jq --raw-output '.builds[-1].custom_data.image_variant' < "$MANIFEST_FILE")
# re-as base_image_ vars prefixed with PKR_VAR
cat << EOF > "$OUTPUT"
PKR_VAR_base_image_checksum=$CHECKSUM_FILE
PKR_VAR_base_image_datestamp=$BASE_IMAGE_DATESTAMP
PKR_VAR_base_image_ext=$BASE_IMAGE_EXT
PKR_VAR_base_image_family=$BASE_IMAGE_FAMILY
PKR_VAR_base_image_name=$BASE_IMAGE_NAME
PKR_VAR_base_image_url=$BASE_IMAGE_URL
PKR_VAR_base_image_variant=$BASE_IMAGE_VARIANT
PKR_VAR_base_image_filename=$BASE_IMAGE_FILENAME
PKR_VAR_base_image_os_version=$BASE_IMAGE_OS_VERSION
EOF

echo "Created $OUTPUT"
cat "$OUTPUT"
