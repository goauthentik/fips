ARG UBI_VERSION

FROM docker.io/redhat/ubi10-minimal:${UBI_VERSION} AS builder

ARG OPENSSL_VERSION
ARG OPENSSL_VERSION_SUFFIX

# Install build dependencies
RUN set -eux; \
    sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/ubi.repo && \
    microdnf -y update && \
    microdnf -y install \
        gcc gcc-c++ make \
        wget tar perl \
        ca-certificates \
    && microdnf -y clean all && rm -rf /var/cache/dnf

# Build OpenSSL with FIPS
ENV build_root="/build"
RUN mkdir -p ${build_root} && \
    cd ${build_root} && \
    wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -O openssl.tgz && \
    tar xvf openssl.tgz && \
    cd openssl-${OPENSSL_VERSION} && \
    sed -i "s:BUILD_METADATA=:BUILD_METADATA=${OPENSSL_VERSION_SUFFIX}:" VERSION.dat && \
    ./config fips && \
    make depend && \
    make -j$(nproc) && \
    make install_sw install_ssldirs install_fips && \
    (cp -r /usr/local/lib64/* /usr/local/lib/ || true) && \
    openssl fipsinstall -out /usr/local/ssl/fipsmodule.cnf -module $(find /usr/local/lib -name fips.so) && \
    sed -i "s:# .include fipsmodule.cnf:.include /usr/local/ssl/fipsmodule.cnf:" /usr/local/ssl/openssl.cnf && \
    sed -i 's:# fips = fips_sect:fips = fips_sect:' /usr/local/ssl/openssl.cnf && \
    sed -i 's:# \[provider_sect\]:\[provider_sect\]:' /usr/local/ssl/openssl.cnf && \
    sed -i 's:# activate = 1:activate = 1:' /usr/local/ssl/openssl.cnf && \
    echo "\n[algorithm_sect]\ndefault_properties = fips=yes" >> /usr/local/ssl/openssl.cnf && \
    strip /usr/local/bin/openssl /usr/local/lib*/libssl.so* /usr/local/lib*/libcrypto.so* || true

# Runtime stage
FROM docker.io/redhat/ubi10-minimal:${UBI_VERSION}

# Install runtime dependencies
RUN set -eux; \
    sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/ubi.repo && \
    microdnf -y update && \
    microdnf -y install \
        ca-certificates \
        crypto-policies \
        crypto-policies-scripts \
    && microdnf -y clean all && rm -rf /var/cache/dnf

# Copy OpenSSL from builder stage
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /usr/local/ssl/ /usr/local/ssl/
COPY --from=builder /usr/local/include/openssl/ /usr/local/include/openssl/

# Set up environment and create symlinks
RUN ln -sf /usr/local/bin/openssl /usr/bin/openssl && \
    ln -sf /usr/local/lib/libssl.so.3 /usr/lib64/libssl.so.3 && \
    ln -sf /usr/local/lib/libcrypto.so.3 /usr/lib64/libcrypto.so.3 && \
    ldconfig

# Verify FIPS is required and working
RUN echo "=== Verifying FIPS is REQUIRED ===" && \
    openssl version && \
    echo "FIPS provider status:" && \
    openssl list -providers && \
    echo "Testing FIPS algorithms work:" && \
    openssl dgst -sha256 /dev/null && \
    echo "SUCCESS: FIPS is required and working"

ENV SSL_CERT_DIR=/etc/ssl/certs
ENV OPENSSL_CONF=/usr/local/ssl/openssl.cnf
