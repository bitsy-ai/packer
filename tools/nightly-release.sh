#!/bin/bash

set -ue


BODY=$(cat <<EOF
{
  "name": "$IMAGE_FILENAME",
  "variant": "$IMAGE_VARIANT",
  "zip_url": "$ZIP_URL",
  "release_channel": "nightly"
}
EOF
)
curl -X "POST" \
  "${PRINTNANNY_API_URL}/api/releases/" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${PRINTNANNY_API_TOKEN}" \
  -d "$BODY"