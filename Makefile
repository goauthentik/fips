.PHONY: all debian-fips python-fips xmlsec1-fips
.SHELLFLAGS += ${SHELLFLAGS} -e

DOCKER_BUILDX_FLAGS =

IMAGE_REPO = ghcr.io/beryju
IMAGE_PREFIX = fips

DEBIAN_CODENAME = bookworm
OPENSSL_VERSION = 3.0.11
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
		--build-arg="OPENSSL_VERSION=${OPENSSL_VERSION}"

xmlsec1-fips: ## Build image with xmlsec1 (on top of debian)
	docker build ${DOCKER_BUILDX_FLAGS} xmlsec1-fips/ \
		-t ${IMAGE_REPO}/${IMAGE_PREFIX}-xmlsec1:${XMLSEC_VERSION}-slim-${DEBIAN_CODENAME}-fips \
		--build-arg="BUILD_IMAGE=${IMAGE_REPO}/${IMAGE_PREFIX}-debian:${DEBIAN_CODENAME}-slim-fips" \
		--build-arg="XMLSEC_VERSION=${XMLSEC_VERSION}"

python-fips:
	docker build ${DOCKER_BUILDX_FLAGS} python-fips/ \
		-t ${IMAGE_REPO}/${IMAGE_PREFIX}-python:${PYTHON_VERSION}-slim-${DEBIAN_CODENAME}-fips \
		--build-arg="BUILD_IMAGE=${IMAGE_REPO}/${IMAGE_PREFIX}-debian:${DEBIAN_CODENAME}-slim-fips" \
		--build-arg="PYTHON_VERSION=${PYTHON_VERSION}"

test: all
	# Test that both images have OpenSSL with FIPS enabled
	docker run -it --rm ${IMAGE_REPO}/${IMAGE_PREFIX}-debian:${DEBIAN_CODENAME}-slim-fips \
		bash -c "openssl list -providers | grep fips"
	docker run -it --rm ${IMAGE_REPO}/${IMAGE_PREFIX}-python:${PYTHON_VERSION}-slim-${DEBIAN_CODENAME}-fips \
		bash -c "openssl list -providers | grep fips"
	# Test Python imported version
	docker run -it --rm ${IMAGE_REPO}/${IMAGE_PREFIX}-python:${PYTHON_VERSION}-slim-${DEBIAN_CODENAME}-fips \
		python -c "from ssl import OPENSSL_VERSION; print(OPENSSL_VERSION)"
