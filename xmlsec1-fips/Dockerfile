ARG BUILD_IMAGE

FROM ${BUILD_IMAGE}

ARG XMLSEC_VERSION

ENV build_root="/build"
ENV xmlsec_gpg_key="00FDD6A7DFB81C88F34B9BF0E63ECDEF9E1D829E"

RUN mkdir -p ${build_root} && \
    cd ${build_root} && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        # Required to fetch
        wget ca-certificates gnupg \
        # Required to run
        libxml2 \
        # Required to build
        build-essential libxml2-dev libltdl-dev && \
    wget http://www.aleksey.com/xmlsec/download/xmlsec1-${XMLSEC_VERSION}.tar.gz -O xmlsec.tgz && \
    wget https://www.aleksey.com/xmlsec/download/xmlsec1-${XMLSEC_VERSION}.sig -O xmlsec.sig && \
    wget https://www.aleksey.com/xmlsec/download/aleksey%40aleksey.com.gpg -O gpg.key && \
    # Verify xmlsec1 source
    GNUPGHOME="$(mktemp -d)" && export GNUPGHOME && \
    gpg --batch --import gpg.key && \
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
    apt-get remove --purge -y wget ca-certificates build-essential libxml2-dev libltdl-dev && \
    apt-get autoremove --purge -y && \
    rm -rf ${build_root} && \
    rm -rf /var/lib/apt/lists/*
