.PHONY: all debian-fips
.SHELLFLAGS += ${SHELLFLAGS} -e

IMAGE_REPO = ghcr.io/beryju
IMAGE_PREFIX = fips

DEBIAN_CODENAME = bookworm
OPENSSL_VERSION = 3.0.11

all: debian-fips python-fips

debian-fips:
	docker build debian-fips/ \
		-t ${IMAGE_REPO}/${IMAGE_PREFIX}-debian:${DEBIAN_CODENAME}-slim-fips \
		--build-arg="DEBIAN_CODENAME=${DEBIAN_CODENAME}" \
		--build-arg="OPENSSL_VERSION=${OPENSSL_VERSION}"

python-fips:
	docker build debian-fips/ -t ${IMAGE_REPO}/${IMAGE_PREFIX}-python:bookworm-slim-fips

test: all
	docker run -it --rm ${IMAGE_REPO}/${IMAGE_PREFIX}-debian:${DEBIAN_CODENAME}-slim-fips \
		bash -c "openssl list -providers | grep fips"
