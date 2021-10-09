ANSIBLE_COLLECTIONS_PATHS ?= $(HOME)/projects/

RELEASE_CHANNEL ?= main
CPU_ARCH ?= arm64
DIST_DIR = ?= dist


clean:
	rm -rf dist/

docker-builder-image:
	DOCKER_BUILDKIT=1 \
	docker build -t bitsyai/packer-builder-arm-ansible -f docker/builder.Dockerfile docker

image: docker-builder-image
	mkdir -p $(DIST_DIR)
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible build \
			-timestamp-ui \
			-debug \
			-var "RELEASE_CHANNEL=$(RELEASE_CHANNEL)" \
			-var "CPU_ARCH=$(CPU_ARCH)" \
			templates/print-nanny-base.pkr.hcl

validate: docker-builder-image
	docker run --rm --privileged -v /dev:/dev -v ${PWD}:/build \
		bitsyai/packer-builder-arm-ansible validate \
			-var "RELEASE_CHANNEL=$(RELEASE_CHANNEL)" \
			-var "CPU_ARCH=$(CPU_ARCH)" \
			templates/print-nanny-base.pkr.hcl