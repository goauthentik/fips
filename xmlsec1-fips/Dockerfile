ARG BUILD_IMAGE=ghcr.io/goauthentik/fips-debian:trixie-slim-fips-dev

FROM ${BUILD_IMAGE}

ARG XMLSEC_VERSION

RUN --mount=type=bind,target=/scripts,src=./build \
    cd /scripts && \
    ./xmlsec.sh
