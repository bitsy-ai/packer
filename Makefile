RELEASE_CHANNEL ?= nightly
RELEASE_URL ?= https://webapp.sandbox.print-nanny.com/api/releases/$(RELEASE_CHANNEL)/latest
IMAGE_NAME ?= generic-pi-bullseye-arm64
PACKER_EXTRA_ARGS ?=
PACKER_VAR_FILE ?= vars/generic-pi-bullseye-arm64.pkrvars.hcl
PACKER_TEMPLATE_FILE ?= templates/generic-pi.pkr.hcl
DIST_DIR ?= dist
ANSIBLE_EXTRA_VARS ?= vars/generic-pi-arm64.ansiblevars.yml
ENV_FILE ?= vars/generic.env

.PHONY: clean docker-builder-image validate

$(DIST_DIR):
	mkdir -p $(DIST_DIR)
clean:
	rm -rf $(DIST_DIR)
	mkdir -p $(DIST_DIR)

vars/printnanny-pi-arm64.ansiblevars.json: $(DIST_DIR)
	wget $(RELEASE_URL) -O dist/printnanny-release.json
	cat dist/printnanny-release.json | jq .ansible_extra_vars > vars/printnanny-pi-arm64.ansiblevars.json

docker-builder-image:
	DOCKER_BUILDKIT=1 \
	docker build -t bitsyai/packer-plugin-arm-image -f docker/builder.Dockerfile docker

docker-builder-image2:
	DOCKER_BUILDKIT=1 \
	docker build -t bitsyai/packer-builder-arm-ansible -f docker/builder2.Dockerfile docker

dist/$(IMAGE_NAME).img: $(DIST_DIR) docker-builder-image
	docker run \
		--rm --privileged -v /dev:/dev -v ${PWD}:/build \
		--env-file $(ENV_FILE) \
		bitsyai/packer-builder-arm-ansible build \
			-timestamp-ui $(PACKER_EXTRA_ARGS) \
			-var "image_name=$(IMAGE_NAME)" \
			-var-file $(PACKER_VAR_FILE) \
			-var "release_channel=$(RELEASE_CHANNEL)" \
			-var "ansible_extra_vars=$(ANSIBLE_EXTRA_VARS)" \
			$(PACKER_TEMPLATE_FILE)

packer-build: $(DIST_DIR) docker-builder-image2
	docker run \
	--rm \
	--privileged \
	-v /dev:/dev \
	-v ${PWD}:/build \
	bitsyai/packer-builder-arm-ansible build \
		-var "image_name=$(IMAGE_NAME)" \
		-var-file $(PACKER_VAR_FILE) \
		templates/generic-pi-v2.pkr.hcl

validate: $(DIST_DIR) docker-builder-image
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible validate \
			-var "release_channel=$(RELEASE_CHANNEL)" \
			-var "image_name=$(IMAGE_NAME)" \
			-var-file $(PACKER_VAR_FILE) \
			-var "ansible_extra_vars=$(ANSIBLE_EXTRA_VARS)" \
			$(PACKER_TEMPLATE_FILE)