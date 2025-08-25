ARG BUILD_IMAGE=ghcr.io/goauthentik/fips-debian:bookworm-slim-fips

FROM ${BUILD_IMAGE}

ARG XMLSEC_VERSION

ENV build_root="/build"

RUN mkdir -p ${build_root} && \
    cd ${build_root} && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends \
        # Required to fetch
        wget gnupg \
        # Required to run
        libxml2 \
        # Required to build
        build-essential libxml2-dev libltdl-dev && \
    wget https://github.com/lsh123/xmlsec/releases/download/${XMLSEC_VERSION}/xmlsec1-${XMLSEC_VERSION}.tar.gz -O xmlsec.tgz && \
    wget https://github.com/lsh123/xmlsec/releases/download/${XMLSEC_VERSION}/xmlsec1-${XMLSEC_VERSION}.sig -O xmlsec.sig && \
    gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 00FDD6A7DFB81C88F34B9BF0E63ECDEF9E1D829E && \
    # Verify xmlsec1 source
    gpg --batch --verify xmlsec.sig xmlsec.tgz && \
    gpgconf --kill all && \
    rm -rf "$GNUPGHOME" xmlsec.sig && \
    # https://www.aleksey.com/xmlsec/download.html
    tar xvzf xmlsec.tgz && \
    cd xmlsec1-${XMLSEC_VERSION} && \
    mkdir build && \
    cd build && \
    ../configure && \
    make -j $(nproc) && \
    make check && \
    make install && \
    apt-get remove --purge -y wget gnupg build-essential libxml2-dev libltdl-dev && \
    apt-get autoremove --purge -y && \
    apt-get clean && \
    rm -rf ${build_root} && \
    rm -rf /var/lib/apt/lists/*
