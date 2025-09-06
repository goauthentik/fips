.PHONY: all push test debian-fips python-fips xmlsec1-fips
.SHELLFLAGS += ${SHELLFLAGS} -e

DOCKER_BUILDX_FLAGS =

PWD = $(shell pwd)

IMAGE_REPO = ghcr.io/goauthentik
IMAGE_PREFIX = fips
IMAGE_SUFFIX =
ARCH =

COMMIT = $(shell git --git-dir ${PWD}/.git rev-parse --short HEAD)

DEBIAN_CODENAME = trixie
# This version refers to the debian package version
OPENSSL_VERSION = 3.5.1
# https://openssl-library.org/source/
OPENSSL_FIPS_MODULE_VERSION = 3.1.2
OPENSSL_VERSION_SUFFIX = ak-fips
# https://www.python.org/doc/versions/
PYTHON_VERSION = 3.13.7
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

debian-fips-name:
	$(eval image := ${IMAGE_REPO}/${IMAGE_PREFIX}-debian)
	$(eval full := ${image}:${DEBIAN_CODENAME}-slim-fips${IMAGE_SUFFIX}${ARCH})
ifdef GITHUB_OUTPUT
	@echo image=$(image) >> ${GITHUB_OUTPUT}
	@echo full=$(full) >> ${GITHUB_OUTPUT}
endif

debian-fips: debian-fips-name ## Build base image (debian with fips-enabled OpenSSL)
	docker build ${DOCKER_BUILDX_FLAGS} $@/ \
		-t ${full} \
		--build-arg="DEBIAN_CODENAME=${DEBIAN_CODENAME}" \
		--build-arg="OPENSSL_VERSION=${OPENSSL_VERSION}" \
		--build-arg="OPENSSL_FIPS_MODULE_VERSION=${OPENSSL_FIPS_MODULE_VERSION}" \
		--build-arg="OPENSSL_VERSION_SUFFIX=${OPENSSL_VERSION_SUFFIX}"

debian-fips-test: debian-fips-name
	@echo "Debian version"
	docker run --rm ${full} \
		cat /etc/debian_version
	@echo "Test that base images has OpenSSL with FIPS enabled"
	docker run --rm ${full} \
		openssl list -providers -provider default -provider base -provider fips

xmlsec1-fips-name:
	$(eval image := ${IMAGE_REPO}/${IMAGE_PREFIX}-xmlsec1)
	$(eval full := ${image}:${XMLSEC_VERSION}-slim-${DEBIAN_CODENAME}-fips${IMAGE_SUFFIX}${ARCH})
ifdef GITHUB_OUTPUT
	@echo image=$(image) >> ${GITHUB_OUTPUT}
	@echo full=$(full) >> ${GITHUB_OUTPUT}
endif

xmlsec1-fips: xmlsec1-fips-name ## Build image with xmlsec1 (on top of debian)
	docker build ${DOCKER_BUILDX_FLAGS} $@/ \
		-t ${full} \
		--build-arg="BUILD_IMAGE=${IMAGE_REPO}/${IMAGE_PREFIX}-debian:${DEBIAN_CODENAME}-slim-fips${IMAGE_SUFFIX}" \
		--build-arg="XMLSEC_VERSION=${XMLSEC_VERSION}"

xmlsec1-fips-test: xmlsec1-fips-name
	@echo "Test that base images has OpenSSL with FIPS enabled"
	docker run --rm ${full} \
		openssl list -providers -provider default -provider base -provider fips
	@echo "xmlsec1 version"
	docker run --rm ${full} \
		xmlsec1 --version

python-fips-name:
	$(eval image := ${IMAGE_REPO}/${IMAGE_PREFIX}-python)
	$(eval full := ${image}:${PYTHON_VERSION}-slim-${DEBIAN_CODENAME}-fips${IMAGE_SUFFIX}${ARCH})
ifdef GITHUB_OUTPUT
	@echo image=$(image) >> ${GITHUB_OUTPUT}
	@echo full=$(full) >> ${GITHUB_OUTPUT}
endif

python-fips: python-fips-name ## Build python on top of fips OpenSSL with xmlsec1
	docker build ${DOCKER_BUILDX_FLAGS} $@/ \
		-t ${full} \
		--build-arg="BUILD_IMAGE=${IMAGE_REPO}/${IMAGE_PREFIX}-xmlsec1:${XMLSEC_VERSION}-slim-${DEBIAN_CODENAME}-fips${IMAGE_SUFFIX}" \
		--build-arg="PYTHON_VERSION=${PYTHON_VERSION}" \
		--build-arg="PYTHON_VERSION_TAG=${PYTHON_VERSION_TAG}"

python-fips-test: python-fips-name
	@echo "Python version"
	docker run --rm ${full} \
		python --version
	@echo "Python SSL version"
	docker run --rm ${full} \
		python -c "from ssl import OPENSSL_VERSION; print(OPENSSL_VERSION)"

test: debian-fips-test xmlsec1-fips-test python-fips-test
