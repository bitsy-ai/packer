ANSIBLE_COLLECTIONS_PATHS ?= $(HOME)/projects/
docker-builder-image:
	DOCKER_BUILDKIT=1 \
	docker build -t bitsyai/packer-builder-arm-ansible -f docker/builder.Dockerfile docker

nightly-base: docker-builder-image
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible build \
			-timestamp-ui \
			-debug \
			templates/nightly-base.json
