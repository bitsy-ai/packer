#!/bin/bash

set +ue

curl -X 'POST' \
  'http://localhost:8000/api/releases/' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer ${PRINTNANNY_API_TOKEN}' \
  -d '{
  "name": "string",
  "variant": "Desktop",
  "image_url": "string",
  "manifest_url": "string",
  "sig_url": "string",
  "checksum": "string",
  "checksum_url": "string",
  "release_channel": "stable"
}'