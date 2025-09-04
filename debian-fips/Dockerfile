ARG DEBIAN_CODENAME=trixie

FROM docker.io/library/debian:${DEBIAN_CODENAME}-slim AS equivs-builder

ENV build_root="/build"

RUN apt-get update && \
    apt-get install -y --no-install-recommends equivs && \
    mkdir -p ${build_root} ${build_root}/output

# libssl3t64
RUN cd ${build_root} && \
    rm -f *deb && \
    apt download libssl3t64 && \
    dpkg -e *deb libssl3t64/ && \
    cd ${build_root}/output && \
    equivs-build ../libssl3t64/control
# openssl
RUN cd ${build_root} && \
    rm -f *deb && \
    apt download openssl && \
    dpkg -e *deb openssl/ && \
    cd ${build_root}/output && \
    equivs-build ../openssl/control
# libssl-dev
RUN cd ${build_root} && \
    rm -f *deb && \
    apt download libssl-dev && \
    dpkg -e *deb libssl-dev/ && \
    cd ${build_root}/output && \
    equivs-build ../libssl-dev/control

FROM docker.io/library/debian:${DEBIAN_CODENAME}-slim

ARG OPENSSL_VERSION
ARG OPENSSL_FIPS_MODULE_VERSION
ARG OPENSSL_VERSION_SUFFIX

COPY --from=equivs-builder /build/output /build/fake-deb
RUN --mount=type=bind,target=/build/build.sh,src=./build.sh \
    /build/build.sh

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ca-certificates wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV SSL_CERT_DIR=/etc/ssl/certs
