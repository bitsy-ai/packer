RELEASE_CHANNEL ?= nightly
RELEASE_URL ?= https://webapp.sandbox.print-nanny.com/api/releases/$(RELEASE_CHANNEL)/latest
IMAGE_NAME ?= printnanny-pi-buster
VAR_FILE ?= vars/$(IMAGE_NAME).pkrvars.hcl
TEMPLATE_FILE ?= templates/$(IMAGE_NAME).pkr.hcl
DIST_DIR ?= dist


.PHONY: clean docker-builder-image validate

$(DIST_DIR):
	mkdir -p $(DIST_DIR)
clean:
	rm -rf $(DIST_DIR)
	mkdir -p $(DIST_DIR)

dist/release.json:
	wget $(RELEASE_URL) -O dist/release.json

docker-builder-image:
	DOCKER_BUILDKIT=1 \
	docker build -t bitsyai/packer-builder-arm-ansible -f docker/builder.Dockerfile docker

dist/$(IMAGE_NAME).img: $(DIST_DIR) docker-builder-image dist/release.json
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible build \
			-timestamp-ui \
			-debug \
			-var-file $(VAR_FILE) \
			-var "release_channel=$(RELEASE_CHANNEL)" \
			-var "ansible_extra_vars=$(shell cat dist/release.json | jq .ansible_extra_vars)" \
			$(TEMPLATE_FILE)

validate: $(DIST_DIR) docker-builder-image dist/release.json
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible validate \
			-var "release_channel=$(RELEASE_CHANNEL)" \
			-var-file $(VAR_FILE) \
			-var "ansible_extra_vars=$(shell cat dist/release.json | jq .ansible_extra_vars)" \
			$(TEMPLATE_FILE)