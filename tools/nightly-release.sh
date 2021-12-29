#!/bin/bash

set -ue


BODY=$(cat <<EOF
{
  "name": "${IMAGE_FILENAME}",
  "variant": "$IMAGE_VARIANT",
  "image_url": "$IMAGE_URL",
  "manifest_url": "$MANIFEST_URL",
  "sig_url": "$SIG_URL",
  "checksum": "$CHECKSUM",
  "checksum_url": "$CHECKSUM_URL",
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