
docker-builder-image:
	DOCKER_BUILDKIT=1 \
	docker build -t bitsyai/packer-builder-arm -f docker/builder.Dockerfile docker
nightly-base:
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm build \
			-timestamp-ui \
			-debug \
			templates/nightly-base.json
