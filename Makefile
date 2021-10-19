ANSIBLE_COLLECTIONS_PATHS ?= $(HOME)/projects/
RELEASE_CHANNEL ?= main
DIST_DIR ?= dist
BASE_IMAGE_CHECKSUM ?= "https://downloads.raspberrypi.org/raspios_arm64/images/raspios_arm64-2021-05-28/2021-05-07-raspios-buster-arm64.zip.sha256"
BASE_IMAGE_URL ?= "https://downloads.raspberrypi.org/raspios_arm64/images/raspios_arm64-2021-05-28/2021-05-07-raspios-buster-arm64.zip"
BASE_IMAGE_EXT ?= "zip"
BASE_DISTRO_VERSION ?= "2021-05-07-raspios-buster-arm64"
PRINTNANNY_CLI_VERSION ?= "0.1.2"
OCTOPRINT_VERSION ?= "1.6.1"
JANUS_VERSION ?= "v0.11.5"
JANUS_USRSCTP_VERSION ?= "0.9.5.0"
JANUS_LIBNICE_VERSION ?= "0.1.18"
JANUS_WEBSOCKETS_VERSION ?= "v3.2-stable"

.PHONY: clean docker-builder-image validate
clean:
	rm -rf dist/

docker-builder-image:
	DOCKER_BUILDKIT=1 \
	docker build -t bitsyai/packer-builder-arm-ansible -f docker/builder.Dockerfile docker

dist/printnanny-pi.img: docker-builder-image
	mkdir -p $(DIST_DIR)
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible build \
			-timestamp-ui \
			-debug \
			-var "BASE_DISTRO_VERSION=$(BASE_DISTRO_VERSION)" \
			-var "BASE_IMAGE_CHECKSUM=$(BASE_IMAGE_CHECKSUM)" \
			-var "BASE_IMAGE_EXT=$(BASE_IMAGE_EXT)" \
			-var "BASE_IMAGE_URL=$(BASE_IMAGE_URL)" \
			-var "PRINTNANNY_CLI_VERSION=$(PRINTNANNY_CLI_VERSION)" \
			-var "OCTOPRINT_VERSION=$(OCTOPRINT_VERSION)" \
			-var "JANUS_VERSION=$(JANUS_VERSION)" \
			-var "JANUS_USRSCTP_VERSION=$(JANUS_USRSCTP_VERSION)" \
			-var "JANUS_LIBNICE_VERSION=$(JANUS_LIBNICE_VERSION)" \
			-var "JANUS_LIBSRTP_VERSION=$(JANUS_LIBSRTP_VERSION)" \
			-var "JANUS_WEBSOCKETS_VERSION=$(JANUS_WEBSOCKETS_VERSION)" \
			-var "RELEASE_CHANNEL=$(RELEASE_CHANNEL)" \
			templates/print-nanny-base.pkr.hcl

validate: docker-builder-image
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible validate \
			-var "BASE_DISTRO_VERSION=$(BASE_DISTRO_VERSION)" \
			-var "BASE_IMAGE_CHECKSUM=$(BASE_IMAGE_CHECKSUM)" \
			-var "BASE_IMAGE_EXT=$(BASE_IMAGE_EXT)" \
			-var "BASE_IMAGE_URL=$(BASE_IMAGE_URL)" \
			-var "PRINTNANNY_CLI_VERSION=$(PRINTNANNY_CLI_VERSION)" \
			-var "OCTOPRINT_VERSION=$(OCTOPRINT_VERSION)" \
			-var "JANUS_VERSION=$(JANUS_VERSION)" \
			-var "JANUS_USRSCTP_VERSION=$(JANUS_USRSCTP_VERSION)" \
			-var "JANUS_LIBNICE_VERSION=$(JANUS_LIBNICE_VERSION)" \
			-var "JANUS_LIBSRTP_VERSION=$(JANUS_LIBSRTP_VERSION)" \
			-var "JANUS_WEBSOCKETS_VERSION=$(JANUS_WEBSOCKETS_VERSION)" \
			-var "RELEASE_CHANNEL=$(RELEASE_CHANNEL)" \
			templates/print-nanny-base.pkr.hcl