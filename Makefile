RELEASE_CHANNEL ?= nightly
PACKER_EXTRA_ARGS ?=
PACKER_VAR_FILE ?= vars/raspios-bullseye-slim-arm64.pkrvars.hcl
PACKER_TEMPLATE_FILE ?= templates/slim-base.pkr.hcl
DIST_DIR ?= dist
BUILD_DIR ?= build

.PHONY: clean docker-builder-image validate packer-build packer-init

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
$(DIST_DIR):
	mkdir -p $(DIST_DIR)

clean:
	rm -rf $(DIST_DIR)
	rm -rf $(BUILD_DIR)
	mkdir -p $(DIST_DIR)
	mkdir -p $(BUILD_DIR)

docker-builder-image:
	DOCKER_BUILDKIT=1 \
	docker build -t bitsyai/packer-builder-arm-ansible -f docker/builder.Dockerfile docker

packer-build: $(DIST_DIR) $(BUILD_DIR) docker-builder-image
	docker run \
		--rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible build \
			-timestamp-ui $(PACKER_EXTRA_ARGS) \
			-var-file "$(PACKER_VAR_FILE)" \
			-var "release_channel=$(RELEASE_CHANNEL)" \
			$(PACKER_TEMPLATE_FILE)

validate: $(DIST_DIR) $(BUILD_DIR) docker-builder-image
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible validate \
			-var "release_channel=$(RELEASE_CHANNEL)" \
			-var-file $(PACKER_VAR_FILE) \
			$(PACKER_TEMPLATE_FILE)