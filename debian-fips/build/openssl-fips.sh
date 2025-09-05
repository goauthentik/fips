#!/bin/bash
set -e -u -o pipefail

source common.sh

# Build FIPS Module
cd ${build_root}
wget https://www.openssl.org/source/openssl-${OPENSSL_FIPS_MODULE_VERSION}.tar.gz -O openssl.tgz
tar xvf openssl.tgz
cd $build_root/openssl-${OPENSSL_FIPS_MODULE_VERSION}
sed -i "s:BUILD_METADATA=:BUILD_METADATA=${OPENSSL_VERSION_SUFFIX}:" VERSION.dat
./Configure enable-fips
make -j$(nproc)
cp ./providers/fips.so ${output_root}
