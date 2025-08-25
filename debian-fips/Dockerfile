ARG DEBIAN_CODENAME=bookworm

FROM docker.io/library/debian:${DEBIAN_CODENAME}-slim AS equivs-builder

ENV build_root="/build"

RUN apt-get update && \
    apt-get install -y --no-install-recommends equivs && \
    mkdir -p ${build_root} ${build_root}/output

# libssl3
RUN cd ${build_root} && \
    rm -f *deb && \
    apt download libssl3 && \
    dpkg -e *deb libssl3/ && \
    cd ${build_root}/output && \
    equivs-build ../libssl3/control
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
ARG OPENSSL_VERSION_SUFFIX
ENV build_root="/build"

COPY --from=equivs-builder ${build_root}/output ${build_root}/fake-deb
RUN mkdir -p $build_root && \
    apt-get update && \
    apt-get install -y --no-install-recommends build-essential wget ca-certificates && \
    cd ${build_root} && \
    wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -O openssl.tgz && \
    tar xvf openssl.tgz && \
    apt-get remove --purge -y wget openssl && \
    cd $build_root/openssl-${OPENSSL_VERSION} && \
    sed -i "s:BUILD_METADATA=:BUILD_METADATA=${OPENSSL_VERSION_SUFFIX}:" VERSION.dat && \
    ./config fips $cryptography_ssl_options && \
    make depend && \
    make -j$(nproc) && \
    make install_sw install_ssldirs install_fips && \
    (cp -r /usr/local/lib64/* /usr/local/lib/ || true) && \
    openssl fipsinstall -out /usr/local/ssl/fipsmodule.cnf -module $(find /usr/local/lib -name fips.so) && \
    sed -i "s:# .include fipsmodule.cnf:.include /usr/local/ssl/fipsmodule.cnf:" /usr/local/ssl/openssl.cnf && \
    sed -i 's:# fips = fips_sect:fips = fips_sect:' /usr/local/ssl/openssl.cnf && \
    sed -i 's:# \[provider_sect\]:\[provider_sect\]:' /usr/local/ssl/openssl.cnf && \
    apt-get remove --purge -y build-essential && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/* && \
    dpkg -i ${build_root}/fake-deb/*deb && \
    apt-mark hold libssl-dev libssl3 openssl && \
    rm -rf ${build_root} && \
    ln -s /usr/local/bin/openssl /usr/bin/openssl && \
    # https://stackoverflow.com/questions/76049736/ee-certificate-key-too-weak-error-in-openssl-3-1-0-fips-enabled
    sed -i 's:# activate = 1:activate = 1:' /usr/local/ssl/openssl.cnf && \
    echo "\n[algorithm_sect]\ndefault_properties = fips=yes" >> /usr/local/ssl/openssl.cnf

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends ca-certificates wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
ENV SSL_CERT_DIR=/etc/ssl/certs
