#!/bin/bash
set -e -u -o pipefail

source common.sh

# Build OpenSSL
cd ${build_root}
apt-get source openssl=${OPENSSL_VERSION}
cd openssl-${OPENSSL_VERSION}/

# Add our build tag
sed -i "s:BUILD_METADATA=:BUILD_METADATA=${OPENSSL_VERSION_SUFFIX}:" VERSION.dat
EDITOR=/bin/true dpkg-source -q --commit . $OPENSSL_VERSION_SUFFIX

dpkg-buildpackage -us -uc
cd ${build_root}
cp *.deb ${output_root}
