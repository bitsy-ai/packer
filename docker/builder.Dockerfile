FROM bitsyai/packer-builder-arm

RUN apt-get update -qq \
    && apt-get install -qqy --no-install-recommends \
    python3 \
    python3-dev \
    python3-pip \
    git

RUN pip install --no-cache ansible