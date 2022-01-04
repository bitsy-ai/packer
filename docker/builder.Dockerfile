FROM bitsyai/packer-builder-arm

RUN apt-get update -qq \
    && apt-get install -qqy --no-install-recommends \
    python3 \
    python3-dev \
    python3-pip \
    git \
    unzip \
    jq

RUN pip3 install ansible

WORKDIR /build