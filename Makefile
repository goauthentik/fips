.PHONY: all push test debian-fips python-fips xmlsec1-fips python-fips-full
.SHELLFLAGS += ${SHELLFLAGS} -e

DOCKER_BUILDX_FLAGS =

IMAGE_REPO = ghcr.io/goauthentik
IMAGE_PREFIX = fips
IMAGE_SUFFIX =

DEBIAN_CODENAME = bookworm
# https://www.openssl.org/source/
OPENSSL_VERSION = 3.0.9
OPENSSL_VERSION_SUFFIX = ak-fips
# https://www.python.org/doc/versions/
PYTHON_VERSION = 3.12.5
# https://www.aleksey.com/xmlsec/
XMLSEC_VERSION = 1.3.5

all: debian-fips xmlsec1-fips python-fips python-fips-full

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
		--build-arg="PYTHON_VERSION=${PYTHON_VERSION}"

python-fips-full: ## Build 'final' image which includes cryptography and xmlsec
	docker build ${DOCKER_BUILDX_FLAGS} $@/ \
		-t ${IMAGE_REPO}/${IMAGE_PREFIX}-python:${PYTHON_VERSION}-slim-${DEBIAN_CODENAME}-fips-full${IMAGE_SUFFIX} \
		--build-arg="BUILD_IMAGE=${IMAGE_REPO}/${IMAGE_PREFIX}-python:${PYTHON_VERSION}-slim-${DEBIAN_CODENAME}-fips${IMAGE_SUFFIX}" \
		--build-arg="DEBIAN_CODENAME=${DEBIAN_CODENAME}"

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
	# Test cryptography (enable FIPS)
	docker run --rm ${IMAGE_REPO}/${IMAGE_PREFIX}-python:${PYTHON_VERSION}-slim-${DEBIAN_CODENAME}-fips-full${IMAGE_SUFFIX} \
		python -c "from cryptography.hazmat.backends.openssl.backend import backend; backend._enable_fips(); print(backend._fips_enabled)"
	# Test LXML & xmlsec
	docker run --rm ${IMAGE_REPO}/${IMAGE_PREFIX}-python:${PYTHON_VERSION}-slim-${DEBIAN_CODENAME}-fips-full${IMAGE_SUFFIX} \
		python -c "import xmlsec; from lxml import etree; print(xmlsec.get_libxml_version(), xmlsec.get_libxmlsec_version(), etree.LIBXML_COMPILED_VERSION)"
