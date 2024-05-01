.PHONY: all debian-fips python-fips xmlsec1-fips
.SHELLFLAGS += ${SHELLFLAGS} -e

DOCKER_BUILDX_FLAGS =

IMAGE_REPO = ghcr.io/beryju
IMAGE_PREFIX = fips

DEBIAN_CODENAME = bookworm
OPENSSL_VERSION = 3.0.11
OPENSSL_VERSION_SUFFIX = ak-fips
PYTHON_VERSION = 3.12.3
XMLSEC_VERSION = 1.3.4

all: debian-fips xmlsec1-fips python-fips

help:  ## Show this help
	@echo "\nSpecify a command. The choices are:\n"
	@grep -Eh '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[0;36m%-$(HELP_WIDTH)s  \033[m %s\n", $$1, $$2}' | \
		sort
	@echo ""

debian-fips: ## Build base image (debian with fips-enabled OpenSSL)
	docker build ${DOCKER_BUILDX_FLAGS} debian-fips/ \
		-t ${IMAGE_REPO}/${IMAGE_PREFIX}-debian:${DEBIAN_CODENAME}-slim-fips \
		--build-arg="DEBIAN_CODENAME=${DEBIAN_CODENAME}" \
		--build-arg="OPENSSL_VERSION=${OPENSSL_VERSION}" \
		--build-arg="OPENSSL_VERSION_SUFFIX=${OPENSSL_VERSION_SUFFIX}"

xmlsec1-fips: ## Build image with xmlsec1 (on top of debian)
	docker build ${DOCKER_BUILDX_FLAGS} xmlsec1-fips/ \
		-t ${IMAGE_REPO}/${IMAGE_PREFIX}-xmlsec1:${XMLSEC_VERSION}-slim-${DEBIAN_CODENAME}-fips \
		--build-arg="BUILD_IMAGE=${IMAGE_REPO}/${IMAGE_PREFIX}-debian:${DEBIAN_CODENAME}-slim-fips" \
		--build-arg="XMLSEC_VERSION=${XMLSEC_VERSION}"

python-fips:
	docker build ${DOCKER_BUILDX_FLAGS} python-fips/ \
		-t ${IMAGE_REPO}/${IMAGE_PREFIX}-python:${PYTHON_VERSION}-slim-${DEBIAN_CODENAME}-fips \
		--build-arg="BUILD_IMAGE=${IMAGE_REPO}/${IMAGE_PREFIX}-xmlsec1:${XMLSEC_VERSION}-slim-${DEBIAN_CODENAME}-fips" \
		--build-arg="PYTHON_VERSION=${PYTHON_VERSION}"

python-fips-deps:
	docker build ${DOCKER_BUILDX_FLAGS} python-fips-deps/ \
		-t ${IMAGE_REPO}/${IMAGE_PREFIX}-python:${PYTHON_VERSION}-slim-${DEBIAN_CODENAME}-fips-deps \
		--build-arg="BUILD_IMAGE=${IMAGE_REPO}/${IMAGE_PREFIX}-python:${PYTHON_VERSION}-slim-${DEBIAN_CODENAME}-fips" \
		--build-arg="CRYPTOGRAPHY_VERSION=${CRYPTOGRAPHY_VERSION}" \
		--build-arg="DEBIAN_CODENAME=${DEBIAN_CODENAME}"

test:
	# Test that base images has OpenSSL with FIPS enabled
	docker run -it --rm ${IMAGE_REPO}/${IMAGE_PREFIX}-debian:${DEBIAN_CODENAME}-slim-fips \
		bash -c "openssl version | grep ${OPENSSL_VERSION_SUFFIX}"
	# Test xmlsec1 image
	docker run -it --rm ${IMAGE_REPO}/${IMAGE_PREFIX}-xmlsec1:${XMLSEC_VERSION}-slim-${DEBIAN_CODENAME}-fips \
		bash -c "openssl version | grep ${OPENSSL_VERSION_SUFFIX}"
	# Test python image
	docker run -it --rm ${IMAGE_REPO}/${IMAGE_PREFIX}-python:${PYTHON_VERSION}-slim-${DEBIAN_CODENAME}-fips \
		bash -c "openssl version | grep ${OPENSSL_VERSION_SUFFIX}"
	# Test Python imported version
	docker run -it --rm ${IMAGE_REPO}/${IMAGE_PREFIX}-python:${PYTHON_VERSION}-slim-${DEBIAN_CODENAME}-fips \
		bash -c 'python -c "from ssl import OPENSSL_VERSION; print(OPENSSL_VERSION)" | grep ${OPENSSL_VERSION_SUFFIX}'
