ARG BUILD_IMAGE=ghcr.io/goauthentik/fips-debian:trixie-slim-fips

FROM ${BUILD_IMAGE}

ARG XMLSEC_VERSION

RUN --mount=type=bind,target=/build/scripts,src=./build \
    cd /build/scripts && \
    ./xmlsec.sh
