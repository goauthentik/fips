ARG BUILD_IMAGE

FROM ${BUILD_IMAGE}

ARG XMLSEC_VERSION

ENV build_root="/build"

RUN mkdir -p ${build_root} && \
    cd ${build_root} && \
    apt-get update && \
    apt-get install -y --no-install-recommends build-essential wget ca-certificates gnupg && \
    wget http://www.aleksey.com/xmlsec/download/xmlsec1-${XMLSEC_VERSION}.tar.gz -O xmlsec.tgz && \
    wget https://www.aleksey.com/xmlsec/download/xmlsec1-1.3.4.sig -O xmlsec.sig && \
    # Verify xmlsec1 source
    GNUPGHOME="$(mktemp -d)" && export GNUPGHOME && \
    gpg --batch --verify xmlsec1-1.3.4.sig xmlsec.tgz && \
    gpgconf --kill all && \
    rm -rf "$GNUPGHOME" xmlsec1-1.3.4.sig && \
    apt-get remove --purge -y wget ca-certificates openssl && \
    # https://www.aleksey.com/xmlsec/download.html
    tar xvzf xmlsec.tgz && \
    cd xmlsec1-${XMLSEC_VERSION} && \
    apt-get update && \
    mkdir build && \
    cd build && \
    ../configure && \
    make && \
    make check && \
    make install && \
    rm -rf ${build_root} && \
    apt-get remove --purge -y build-essential && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/*
    # pip wheel -w ${wheel_output_dir} --no-cache --no-binary xmlsec xmlsec
