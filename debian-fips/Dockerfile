ARG DEBIAN_CODENAME=trixie

FROM docker.io/library/debian:${DEBIAN_CODENAME}-slim AS builder-openssl

ARG OPENSSL_VERSION
ARG OPENSSL_FIPS_MODULE_VERSION
ARG OPENSSL_VERSION_SUFFIX

RUN --mount=type=bind,target=/build/scripts,src=./build \
    cd /build/scripts && \
    ./prepare.sh
RUN --mount=type=bind,target=/build/scripts,src=./build \
    cd /build/scripts && \
    ./openssl.sh

FROM docker.io/library/debian:${DEBIAN_CODENAME}-slim AS builder-openssl-fips

ARG OPENSSL_VERSION
ARG OPENSSL_FIPS_MODULE_VERSION
ARG OPENSSL_VERSION_SUFFIX

RUN --mount=type=bind,target=/build/scripts,src=./build \
    cd /build/scripts && \
    ./prepare.sh
RUN --mount=type=bind,target=/build/scripts,src=./build \
    cd /build/scripts && \
    ./openssl-fips.sh

FROM docker.io/library/debian:${DEBIAN_CODENAME}-slim

RUN --mount=type=bind,target=/output,from=builder-openssl,src=/output \
    --mount=type=bind,target=/output-fips,from=builder-openssl-fips,src=/output \
    --mount=type=bind,target=/build/fipsinstall.sh,src=./build/fipsinstall.sh \
    dpkg -i /output/libssl-dev_* /output/libssl3t64_* /output/openssl_* && \
    apt-mark hold libssl-dev libssl3t64 openssl && \
    /build/fipsinstall.sh

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ca-certificates wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV SSL_CERT_DIR=/etc/ssl/certs
