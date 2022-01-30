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

DATESTAMP ?= $(shell date +'%Y-%m-%d-%H%M')
OUTPUT ?= dist
LOG_PATH ?= logs

clean:
	rm -rf $(OUTPUT)

docker-builder-image:
	DOCKER_BUILDKIT=1 \
	docker build -t bitsyai/packer-builder-arm-ansible -f docker/builder.Dockerfile docker
	docker push bitsyai/packer-builder-arm-ansible

shellcheck:
	shellcheck ./tools/*.sh

outdir:
	mkdir -p "$(shell cat ${PACKER_VAR_FILE} | jq '.output' -r)/$(DATESTAMP)"

packer-build:
	BASE=$(BASE) PACKER_VAR_FILE=$(PACKER_VAR_FILE) DATESTAMP=$(DATESTAMP) bash -c "tools/packer-build.sh"

printnanny-desktop: PACKER_VAR_FILE=vars/printnanny-desktop-arm64.pkrvars.json
printnanny-desktop: PACKER_LOG=1
printnanny-desktop: PACKER_LOG_PATH=$(LOG_PATH)/$@.log
printnanny-desktop: BASE=
printnanny-desktop: outdir packer-build

printnanny-slim: PACKER_VAR_FILE=vars/printnanny-slim-arm64.pkrvars.json
printnanny-slim: BASE=
printnanny-slim: PACKER_LOG=1
printnanny-slim: PACKER_LOG_PATH=$(LOG_PATH)/$@.log
printnanny-slim: outdir packer-build

octoprint-desktop: PACKER_VAR_FILE=vars/octoprint-desktop.pkrvars.json
octoprint-desktop: BASE="vars/printnanny-desktop-arm64.pkrvars.json"
octoprint-desktop: PACKER_LOG=1
octoprint-desktop: PACKER_LOG_PATH=$(LOG_PATH)/$@.log
octoprint-desktop: outdir packer-build

octoprint-slim: PACKER_VAR_FILE=vars/octoprint-slim.pkrvars.json
octoprint-slim: BASE="vars/printnanny-slim-arm64.pkrvars.json"
octoprint-slim: PACKER_LOG=1
octoprint-slim: PACKER_LOG_PATH=$(LOG_PATH)/$@.log
octoprint-slim: outdir packer-build
