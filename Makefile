
nightly-base:
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		mkaczanowski/packer-builder-arm build \
			-timestamp-ui \
			-debug \
			templates/nightly-base.json
