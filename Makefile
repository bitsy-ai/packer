PACKER_EXTRA_ARGS ?=
PACKER_VAR_FILE ?= vars/raspios-bullseye-slim-arm64.pkrvars.hcl
PACKER_TEMPLATE_FILE ?= templates/generic-pi.pkr.hcl
PLAYBOOK_FILE ?= playbooks/printnanny/slim.yml
DIST_DIR ?= dist
BUILD_DIR ?= build
DRYRUN ?= false

PACKER_CMD ?= build --timestamp-ui -var "playbook_file=${PLAYBOOK_FILE}" -var "dryrun=${DRYRUN}" -var-file ${PACKER_VAR_FILE} ${PACKER_TEMPLATE_FILE}

.PHONY: clean docker-builder-image validate packer-build packer-init shellcheck

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

packer: $(DIST_DIR) $(BUILD_DIR) docker-builder-image
	docker run \
		--rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible ${PACKER_CMD}

validate: $(DIST_DIR) $(BUILD_DIR) docker-builder-image
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible validate \
			-var-file $(PACKER_VAR_FILE) \
			$(PACKER_TEMPLATE_FILE)

shellcheck:
	shellcheck ./tools/*.sh