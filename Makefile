RELEASE_CHANNEL ?= nightly
VAR_FILE ?= vars/buster.pkrvars.hcl
TEMPLATE_FILE ?= templates/buster.pkr.hcl
DIST_DIR ?= dist

.PHONY: clean docker-builder-image validate
clean:
	rm -rf $(DIST_DIR)
	mkdir -p $(DIST_DIR)

dist/release.json:
	wget https://webapp.sandbox.print-nanny.com/api/releases/$(RELEASE_CHANNEL)/latest -O dist/release.json

docker-builder-image:
	DOCKER_BUILDKIT=1 \
	docker build -t bitsyai/packer-builder-arm-ansible -f docker/builder.Dockerfile docker

dist/printnanny-pi.img: docker-builder-image dist/release.json
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible build \
			-timestamp-ui \
			-debug \
			-var-file $(VAR_FILE) \
			-var "release_channel=$(RELEASE_CHANNEL)" \
			-var "ansible_extra_vars=$(shell cat dist/release.json | jq .ansible_extra_vars)" \
			$(TEMPLATE_FILE)

validate: docker-builder-image dist/release.json
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible validate \
			-var "RELEASE_CHANNEL=$(release_channel)" \
			-var-file $(VAR_FILE) \
			-var "ansible_extra_vars=$(shell cat dist/release.json | jq .ansible_extra_vars)" \
			$(TEMPLATE_FILE)