ARG DEBIAN_CODENAME=trixie

FROM docker.io/library/debian:${DEBIAN_CODENAME}-slim AS builder-openssl

ARG OPENSSL_VERSION
ARG OPENSSL_FIPS_MODULE_VERSION
ARG OPENSSL_VERSION_SUFFIX

RUN --mount=type=bind,target=/build/scripts/common.sh,src=./build/common.sh \
    --mount=type=bind,target=/build/scripts/prepare.sh,src=./build/prepare.sh \
    cd /build/scripts && \
    ./prepare.sh
RUN --mount=type=bind,target=/build/scripts/common.sh,src=./build/common.sh \
    --mount=type=bind,target=/build/scripts/openssl.sh,src=./build/openssl.sh \
    cd /build/scripts && \
    ./openssl.sh

FROM docker.io/library/debian:${DEBIAN_CODENAME}-slim AS builder-openssl-fips

ARG OPENSSL_VERSION
ARG OPENSSL_FIPS_MODULE_VERSION
ARG OPENSSL_VERSION_SUFFIX

RUN --mount=type=bind,target=/build/scripts/common.sh,src=./build/common.sh \
    --mount=type=bind,target=/build/scripts/prepare.sh,src=./build/prepare.sh \
    cd /build/scripts && \
    ./prepare.sh
RUN --mount=type=bind,target=/build/scripts/common.sh,src=./build/common.sh \
    --mount=type=bind,target=/build/scripts/openssl-fips.sh,src=./build/openssl-fips.sh \
    cd /build/scripts && \
    ./openssl-fips.sh

# Stage: runtime
FROM docker.io/library/debian:${DEBIAN_CODENAME}-slim AS runtime

RUN --mount=type=bind,target=/output,from=builder-openssl,src=/output \
    --mount=type=bind,target=/output-fips,from=builder-openssl-fips,src=/output \
    --mount=type=bind,target=/build/fipsinstall.sh,src=./build/fipsinstall.sh \
    dpkg -i /output/libssl3t64_* /output/openssl_* && \
    apt-mark hold libssl3t64 openssl && \
    /build/fipsinstall.sh && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Stage: dev
FROM runtime AS dev

RUN --mount=type=bind,target=/output,from=builder-openssl,src=/output \
    dpkg -i /output/libssl-dev_* && \
    apt-mark hold libssl-dev && \
    apt-get update && \
    apt-get install -y --no-install-recommends wget curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
