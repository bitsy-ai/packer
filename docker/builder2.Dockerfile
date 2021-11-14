FROM ghcr.io/solo-io/packer-plugin-arm-image

RUN apt-get update -qq \
    && apt-get install -qqy --no-install-recommends \
    python3 \
    python3-dev \
    python3-pip \
    git \
    unzip

RUN pip install --no-cache ansible