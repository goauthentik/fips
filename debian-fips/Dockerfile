ARG DEBIAN_CODENAME

FROM docker.io/library/debian:${DEBIAN_CODENAME}-slim

ARG OPENSSL_VERSION
ENV build_root="/build"

RUN mkdir -p $build_root && \
    apt-get update && \
    apt-get install -y --no-install-recommends build-essential wget ca-certificates && \
    cd ${build_root} && \
    wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -O openssl.tgz && \
    tar xvf openssl.tgz && \
    apt-get remove --purge -y wget ca-certificates openssl && \
    cd $build_root/openssl-${OPENSSL_VERSION} && \
    sed -i "s:BUILD_METADATA=:BUILD_METADATA=ak-fips:" VERSION.dat && \
    ./config fips $cryptography_ssl_options && \
    make depend && \
    make -j$(nproc) && \
    make install_sw install_ssldirs install_fips && \
    openssl fipsinstall -out /usr/local/ssl/fipsmodule.cnf -module /usr/local/lib/ossl-modules/fips.so && \
    sed -i "s:# .include fipsmodule.cnf:.include /usr/local/ssl/fipsmodule.cnf:" /usr/local/ssl/openssl.cnf && \
    sed -i 's:# fips = fips_sect:fips = fips_sect:' /usr/local/ssl/openssl.cnf && \
    sed -i 's:# \[provider_sect\]:\[provider_sect\]:' /usr/local/ssl/openssl.cnf && \
    rm -rf ${build_root} && \
    apt-get remove --purge -y build-essential && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/*
