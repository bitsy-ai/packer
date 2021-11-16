RELEASE_CHANNEL ?= nightly
PACKER_EXTRA_ARGS ?=
RELEASE_URL ?= https://webapp.sandbox.print-nanny.com/api/releases/$(RELEASE_CHANNEL)/latest
PACKER_VAR_FILE ?= vars/generic-pi-bullseye-arm64.pkrvars.hcl
PACKER_TEMPLATE_FILE ?= templates/generic-pi.pkr.hcl
DIST_DIR ?= dist
PACKER_ENV_FILE ?= vars/generic.env

.PHONY: clean docker-builder-image validate packer-build packer-init

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
	docker build -t bitsyai/packer-builder-arm-ansible -f docker/builder.Dockerfile docker

packer-build: $(DIST_DIR) docker-builder-image
	docker run \
		--rm --privileged -v /dev:/dev -v ${PWD}:/build \
		--env-file $(PACKER_ENV_FILE) \
		bitsyai/packer-builder-arm-ansible build \
			-timestamp-ui $(PACKER_EXTRA_ARGS) \
			-var-file "$(PACKER_VAR_FILE)" \
			-var "release_channel=$(RELEASE_CHANNEL)" \
			$(PACKER_TEMPLATE_FILE)

validate: $(DIST_DIR) docker-builder-image
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible validate \
			-var "release_channel=$(RELEASE_CHANNEL)" \
			-var-file $(PACKER_VAR_FILE) \
			$(PACKER_TEMPLATE_FILE)