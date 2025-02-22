.PHONY: all push test debian-fips python-fips xmlsec1-fips
.SHELLFLAGS += ${SHELLFLAGS} -e

DOCKER_BUILDX_FLAGS =

PWD = $(shell pwd)

IMAGE_REPO = ghcr.io/goauthentik
IMAGE_PREFIX = fips
IMAGE_SUFFIX =

COMMIT = $(shell git --git-dir ${PWD}/.git rev-parse --short HEAD)

DEBIAN_CODENAME = bookworm
# https://www.openssl.org/source/
OPENSSL_VERSION = 3.0.9
OPENSSL_VERSION_SUFFIX = ak-fips
# https://www.python.org/doc/versions/
PYTHON_VERSION = 3.13.0
PYTHON_VERSION_TAG = ak-fips-${COMMIT}
# https://www.aleksey.com/xmlsec/
XMLSEC_VERSION = 1.3.7

all: debian-fips xmlsec1-fips python-fips

help:  ## Show this help
	@echo "\nSpecify a command. The choices are:\n"
	@grep -Eh '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[0;36m%-$(HELP_WIDTH)s  \033[m %s\n", $$1, $$2}' | \
		sort
	@echo ""

debian-fips: ## Build base image (debian with fips-enabled OpenSSL)
	docker build ${DOCKER_BUILDX_FLAGS} $@/ \
		-t ${IMAGE_REPO}/${IMAGE_PREFIX}-debian:${DEBIAN_CODENAME}-slim-fips${IMAGE_SUFFIX} \
		--build-arg="DEBIAN_CODENAME=${DEBIAN_CODENAME}" \
		--build-arg="OPENSSL_VERSION=${OPENSSL_VERSION}" \
		--build-arg="OPENSSL_VERSION_SUFFIX=${OPENSSL_VERSION_SUFFIX}"

xmlsec1-fips: ## Build image with xmlsec1 (on top of debian)
	docker build ${DOCKER_BUILDX_FLAGS} $@/ \
		-t ${IMAGE_REPO}/${IMAGE_PREFIX}-xmlsec1:${XMLSEC_VERSION}-slim-${DEBIAN_CODENAME}-fips${IMAGE_SUFFIX} \
		--build-arg="BUILD_IMAGE=${IMAGE_REPO}/${IMAGE_PREFIX}-debian:${DEBIAN_CODENAME}-slim-fips${IMAGE_SUFFIX}" \
		--build-arg="XMLSEC_VERSION=${XMLSEC_VERSION}"

python-fips: ## Build python on top of fips OpenSSL with xmlsec1
	docker build ${DOCKER_BUILDX_FLAGS} $@/ \
		-t ${IMAGE_REPO}/${IMAGE_PREFIX}-python:${PYTHON_VERSION}-slim-${DEBIAN_CODENAME}-fips${IMAGE_SUFFIX} \
		--build-arg="BUILD_IMAGE=${IMAGE_REPO}/${IMAGE_PREFIX}-xmlsec1:${XMLSEC_VERSION}-slim-${DEBIAN_CODENAME}-fips${IMAGE_SUFFIX}" \
		--build-arg="PYTHON_VERSION=${PYTHON_VERSION}" \
		--build-arg="PYTHON_VERSION_TAG=${PYTHON_VERSION_TAG}"

test:
	# Test that base images has OpenSSL with FIPS enabled
	docker run --rm ${IMAGE_REPO}/${IMAGE_PREFIX}-debian:${DEBIAN_CODENAME}-slim-fips${IMAGE_SUFFIX} \
		bash -c "openssl version | grep ${OPENSSL_VERSION_SUFFIX}"
	# Test xmlsec1 image
	docker run --rm ${IMAGE_REPO}/${IMAGE_PREFIX}-xmlsec1:${XMLSEC_VERSION}-slim-${DEBIAN_CODENAME}-fips${IMAGE_SUFFIX} \
		bash -c "openssl version | grep ${OPENSSL_VERSION_SUFFIX}"
	# Test Python image
	docker run --rm ${IMAGE_REPO}/${IMAGE_PREFIX}-python:${PYTHON_VERSION}-slim-${DEBIAN_CODENAME}-fips${IMAGE_SUFFIX} \
		bash -c "openssl version | grep ${OPENSSL_VERSION_SUFFIX}"
	# Test Python imported version
	docker run --rm ${IMAGE_REPO}/${IMAGE_PREFIX}-python:${PYTHON_VERSION}-slim-${DEBIAN_CODENAME}-fips${IMAGE_SUFFIX} \
		bash -c 'python -c "from ssl import OPENSSL_VERSION; print(OPENSSL_VERSION)" | grep ${OPENSSL_VERSION_SUFFIX}'
