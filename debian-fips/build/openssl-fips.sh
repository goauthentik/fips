#!/bin/bash
set -e -u -o pipefail

source common.sh

cd ${build_root}
wget https://www.openssl.org/source/openssl-${OPENSSL_FIPS_MODULE_VERSION}.tar.gz \
    -O openssl.tgz
wget https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_FIPS_MODULE_VERSION}/openssl-${OPENSSL_FIPS_MODULE_VERSION}.tar.gz.asc \
    -O openssl.sig

# Validate signature
GNUPGHOME="$(mktemp -d)"
export GNUPGHOME
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys BA5473A2B0587B07FB27CF2D216094DFD0CB81EF
# Legacy key, see https://openssl-library.org/source/
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys EFC0A467D613CB83C7ED6D30D894E2CE8B3D79F5
gpg --batch --verify openssl.sig openssl.tgz
gpgconf --kill all
rm -rf "$GNUPGHOME" openssl.sig

# Start building
tar xvf openssl.tgz
cd $build_root/openssl-${OPENSSL_FIPS_MODULE_VERSION}
sed -i "s:BUILD_METADATA=:BUILD_METADATA=${OPENSSL_VERSION_SUFFIX}:" VERSION.dat
# Build FIPS Module
./Configure enable-fips
make -j$(nproc)
cp ./providers/fips.so ${output_root}
