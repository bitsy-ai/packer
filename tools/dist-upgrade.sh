#!/bin/bash

set +eu

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y libfuse2
DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
