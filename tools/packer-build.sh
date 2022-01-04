#!/bin/bash

set -eux

find_latest_env(){
    # shellcheck disable=SC2012
    ls "$1" | sort | tail -n 1
}

if [ -n "$BASE" ];
then
    output=$(jq '.output' -r < "$BASE")
    latest=$(find_latest_env "$output")
    envfile="$output/$latest/packer.env"
    echo "Reading vars from $envfile"
    cat "$envfile"
    docker run -it \
        --env-file "$envfile" \
        --rm --privileged -v /dev:/dev -v "${PWD}:/build" \
        bitsyai/packer-builder-arm-ansible \
            build \
            --timestamp-ui \
            -var "datestamp=$DATESTAMP" \
            -var-file "$PACKER_VAR_FILE" \
            templates/generic-pi.pkr.hcl
else
    docker run -it \
        --rm --privileged -v /dev:/dev -v "${PWD}:/build" \
        bitsyai/packer-builder-arm-ansible \
            build \
            --timestamp-ui \
            -var "datestamp=$DATESTAMP" \
            -var-file "$PACKER_VAR_FILE" \
            templates/generic-pi.pkr.hcl
fi