RELEASE_CHANNEL ?= nightly
RELEASE_URL ?= https://webapp.sandbox.print-nanny.com/api/releases/$(RELEASE_CHANNEL)/latest
IMAGE_NAME ?= printnanny-pi-buster-arm64
PACKER_VARS ?=
PACKER_VAR_FILE ?= vars/printnanny-pi-buster-arm64.pkrvars.hcl
PACKER_TEMPLATE_FILE ?= templates/generic-pi.pkr.hcl
DIST_DIR ?= dist
ANSIBLE_EXTRA_VARS ?= vars/printnanny-pi-buster-arm64.ansiblevars.json

.PHONY: clean docker-builder-image validate

$(DIST_DIR):
	mkdir -p $(DIST_DIR)
clean:
	rm -rf $(DIST_DIR)
	mkdir -p $(DIST_DIR)

vars/generic-pi-buster-arm64.ansiblevars.json:

vars/printnanny-pi-buster-arm64.ansiblevars.json: $(DIST_DIR)
	wget $(RELEASE_URL) -O dist/printnanny-release.json
	cat dist/printnanny-release.json | jq .ansible_extra_vars > vars/printnanny-pi-buster-arm64.ansiblevars.json

docker-builder-image:
	DOCKER_BUILDKIT=1 \
	docker build -t bitsyai/packer-builder-arm-ansible -f docker/builder.Dockerfile docker

dist/$(IMAGE_NAME).img: $(DIST_DIR) docker-builder-image
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible build \
			-timestamp-ui -debug $(PACKER_VARS) \
			-var "image_name=$(IMAGE_NAME)" \
			-var-file $(PACKER_VAR_FILE) \
			-var "release_channel=$(RELEASE_CHANNEL)" \
			-var "ansible_extra_vars=$(ANSIBLE_EXTRA_VARS)" \
			$(PACKER_TEMPLATE_FILE)

validate: $(DIST_DIR) docker-builder-image
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible validate \
			-var "release_channel=$(RELEASE_CHANNEL)" \
			-var "image_name=$(IMAGE_NAME)" \
			-var-file $(PACKER_VAR_FILE) \
			-var "ansible_extra_vars=$(ANSIBLE_EXTRA_VARS)" \
			$(PACKER_TEMPLATE_FILE)