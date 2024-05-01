.PHONY: all debian-fips python-fips
.SHELLFLAGS += ${SHELLFLAGS} -e

DOCKER_BUILDX_FLAGS =

IMAGE_REPO = ghcr.io/beryju
IMAGE_PREFIX = fips

DEBIAN_CODENAME = bookworm
OPENSSL_VERSION = 3.0.11
PYTHON_VERSION = 3.12.3

all: debian-fips python-fips

debian-fips:
	docker build ${DOCKER_BUILDX_FLAGS} debian-fips/ \
		-t ${IMAGE_REPO}/${IMAGE_PREFIX}-debian:${DEBIAN_CODENAME}-slim-fips \
		--build-arg="DEBIAN_CODENAME=${DEBIAN_CODENAME}" \
		--build-arg="OPENSSL_VERSION=${OPENSSL_VERSION}"

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
