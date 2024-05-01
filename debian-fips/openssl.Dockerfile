FROM debian:bookworm-slim

ENV build_ssl_dir="/ak-root/ssl"
ENV wheel_output_dir="/ak-root/wheels"
ENV openssl_version="3.0.11"

RUN mkdir -p $build_ssl_dir $wheel_output_dir && \
    apt-get update && \
    apt-get install -y --no-install-recommends build-essential wget ca-certificates && \
    cd ${build_ssl_dir} && \
    wget https://www.openssl.org/source/openssl-$openssl_version.tar.gz -O openssl.tgz && \
    tar xvf openssl.tgz && \
    cd $build_ssl_dir/openssl-$openssl_version && \
    ./config fips $cryptography_ssl_options && \
    make depend && \
    make -j$(nproc) && \
    apt-get remove --purge openssl -y && \
    make install_sw install_ssldirs install_fips && \
    openssl fipsinstall -out /usr/local/ssl/fipsmodule.cnf -module /usr/local/lib/ossl-modules/fips.so

ENV OPENSSL_MODULES=/usr/local/lib/ossl-modules/
ENV OPENSSL_CONF=/ak-root/ssl/openssl-3.0.11/test/fips-and-base.cnf
ENV OPENSSL_ENGINES=/usr/local/lib/ossl-modules/
ENV OPENSSL_CONF_INCLUDE=/usr/local/lib/ossl-modules/
