.PHONY: all debian-fips
.SHELLFLAGS += ${SHELLFLAGS} -e

IMAGE_REPO = ghcr.io/beryju
IMAGE_PREFIX = fips

all: debian-fips python-fips

debian-fips:
	docker build debian-fips/ -t ${IMAGE_REPO}/${IMAGE_PREFIX}-debian:bookworm-slim-fips

python-fips:
	docker build debian-fips/ -t ${IMAGE_REPO}/${IMAGE_PREFIX}-python:bookworm-slim-fips

test: all
	docker run -it --rm ${IMAGE_REPO}/${IMAGE_PREFIX}-debian:bookworm-slim-fips \
		bash -c "openssl list -providers | grep fips"
