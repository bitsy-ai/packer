PACKER_EXTRA_ARGS ?=
PACKER_VAR_FILE ?= vars/printnanny-pi-arm64.pkrvars.hcl
PACKER_TEMPLATE_FILE ?= templates/generic-pi.pkr.hcl
PLAYBOOK_FILE ?= playbooks/printnanny/slim.yml
DIST_DIR ?= dist
BUILD_DIR ?= build

DRYRUN_CMD ?= build --timestamp-ui -var "playbook_file=playbooks/dryrun.yml" -var "dryrun=true" -var-file ${PACKER_VAR_FILE} ${PACKER_TEMPLATE_FILE}
PACKER_CMD ?= build --timestamp-ui -var "playbook_file=${PLAYBOOK_FILE}" -var-file ${PACKER_VAR_FILE} ${PACKER_TEMPLATE_FILE}
VALIDATE_CMD ?= validate -var "playbook_file=${PLAYBOOK_FILE}" -var-file ${PACKER_VAR_FILE} ${PACKER_TEMPLATE_FILE}
.PHONY: clean docker-builder-image validate packer-build packer-init shellcheck

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
	docker push bitsyai/packer-builder-arm-ansible

packer-build: $(DIST_DIR) $(BUILD_DIR)
	docker run \
		--rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible ${PACKER_CMD}

dryrun: $(DIST_DIR) $(BUILD_DIR)
	docker run \
		--rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible ${DRYRUN_CMD}

validate: $(DIST_DIR) $(BUILD_DIR)
	docker run \
		--rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible ${VALIDATE_CMD}

shellcheck:
	shellcheck ./tools/*.sh


printnanny-desktop: $(DIST_DIR)
	mkdir -p $(DIST_DIR)/$@
	docker run -it \
		--rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible \
			build \
			--timestamp-ui \
			-var "output=${DIST_DIR}" \
			-var-file printnanny-desktop-arm64.pkrvars.hcl \
			templates/generic-pi.pkr.hcl

printnanny-slim: $(DIST_DIR)
	mkdir -p $(DIST_DIR)/$@
	docker run -it \
		--rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible \
			build \
			--timestamp-ui \
			-var "output=${DIST_DIR}" \
			-var-file printnanny-slim-arm64.pkrvars.hcl \
			templates/generic-pi.pkr.hcl
