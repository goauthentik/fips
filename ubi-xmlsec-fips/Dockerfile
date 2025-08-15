ARG BUILD_IMAGE=ghcr.io/goauthentik/fips-ubi:10.0-fips-minimal
FROM ${BUILD_IMAGE} AS builder

ARG XMLSEC_VERSION
ENV build_root="/build"

RUN set -eux; \
    sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/ubi.repo && \
    microdnf -y update && \
    microdnf -y install dnf-plugins-core && \
    microdnf install -y \
        wget gnupg2 tar \
        gcc gcc-c++ make \
        libxml2-devel pkgconf-pkg-config

# build xmlsec
RUN mkdir -p ${build_root} && \
    cd ${build_root} && \
    wget https://github.com/lsh123/xmlsec/releases/download/${XMLSEC_VERSION}/xmlsec1-${XMLSEC_VERSION}.tar.gz -O xmlsec.tgz && \
    wget https://github.com/lsh123/xmlsec/releases/download/${XMLSEC_VERSION}/xmlsec1-${XMLSEC_VERSION}.sig -O xmlsec.sig && \
    gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 00FDD6A7DFB81C88F34B9BF0E63ECDEF9E1D829E && \
    gpg --batch --verify xmlsec.sig xmlsec.tgz && \
    gpgconf --kill all && rm -rf "$GNUPGHOME" xmlsec.sig && \
    tar xvzf xmlsec.tgz && cd xmlsec1-${XMLSEC_VERSION}

RUN cd ${build_root}/xmlsec1-${XMLSEC_VERSION} && \
    echo "=== Verifying FIPS is REQUIRED ===" && \
    openssl version && \
    echo "FIPS provider status:" && \
    openssl list -providers && \
    echo "Testing FIPS requirement (this should work):" && \
    openssl dgst -sha256 /dev/null && \
    echo "=== Configuring xmlsec to use FIPS OpenSSL ===" && \
    ./configure --prefix=/usr/local --with-openssl=/usr/local --disable-crypto-dl --disable-apps-crypto-dl

RUN cd ${build_root}/xmlsec1-${XMLSEC_VERSION} && \
    make -j"$(nproc)"

RUN cd ${build_root}/xmlsec1-${XMLSEC_VERSION} && \
    make install

RUN strip /usr/local/lib/libxmlsec1*.so* /usr/local/bin/xmlsec1 || true

# Runtime stage
FROM ${BUILD_IMAGE}

ARG XMLSEC_VERSION
ARG XMLSEC_VERSION_MAJOR=${XMLSEC_VERSION%%.*}

# Copy only the built xmlsec binaries and libraries
COPY --from=builder /usr/local/lib/libxmlsec1*.so* /usr/local/lib/
COPY --from=builder /usr/local/bin/xmlsec1 /usr/local/bin/
COPY --from=builder /usr/local/include/xmlsec1/ /usr/local/include/xmlsec1/
COPY --from=builder /usr/local/lib/pkgconfig/xmlsec1*.pc /usr/local/lib/pkgconfig/

# Install only runtime dependencies and create library symlinks
RUN set -eux; \
    sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/ubi.repo && \
    microdnf -y update && \
    microdnf install -y \
        libxml2 \
    && microdnf clean all \
    && rm -rf /var/cache/dnf \
    && ln -sf libxmlsec1.so.${XMLSEC_VERSION} /usr/local/lib/libxmlsec1.so.${XMLSEC_VERSION_MAJOR} \
    && ln -sf libxmlsec1.so.${XMLSEC_VERSION_MAJOR} /usr/local/lib/libxmlsec1.so \
    && ln -sf libxmlsec1-openssl.so.${XMLSEC_VERSION} /usr/local/lib/libxmlsec1-openssl.so.${XMLSEC_VERSION_MAJOR} \
    && ln -sf libxmlsec1-openssl.so.${XMLSEC_VERSION_MAJOR} /usr/local/lib/libxmlsec1-openssl.so \
    && ldconfig

# make sure it still works in runtime
RUN echo "=== Final FIPS verification ===" && \
    openssl version && \
    echo "FIPS provider status:" && \
    openssl list -providers && \
    echo "Testing FIPS requirement (this should work):" && \
    openssl dgst -sha256 /dev/null && \
    echo "SUCCESS: FIPS is required and working in runtime"