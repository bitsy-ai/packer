export PRINTNANNY_API_URL=http://aurora:8000
export IMAGE_VARIANT="Desktop"
export IMAGE_FILENAME=$(cat dist/manifest.json | jq --raw-output '.builds[-1].custom_data.image_filename')
export IMAGE_STAMP=$(cat dist/manifest.json | jq --raw-output '.builds[-1].custom_data.image_stamp')
export IMAGE_PATH=$(cat dist/manifest.json | jq --raw-output '.builds[-1].custom_data.image_path')
export IMAGE_URL="${CDN_BASE_URL}/${IMAGE_PATH}/${IMAGE_FILENAME}"
export CHECKSUM_URL="${CDN_BASE_URL}/${IMAGE_PATH}/sha256.checksum"
export MANIFEST_URL="${CDN_BASE_URL}/$IMAGE_PATH/manifest.json"
export SIG_URL="${CHECKSUM_URL}.sig"
export CHECKSUM="1234"