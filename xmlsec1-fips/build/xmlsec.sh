#!/bin/bash
set -e -u -o pipefail

build_root="/build"
build_deps="wget gnupg build-essential libxml2-dev libltdl-dev"
runtime_deps="libltdl7 libxml2"

mkdir -p ${build_root}
cd ${build_root}

apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends ${build_deps} ${runtime_deps}

wget https://github.com/lsh123/xmlsec/releases/download/${XMLSEC_VERSION}/xmlsec1-${XMLSEC_VERSION}.tar.gz -O xmlsec.tgz
wget https://github.com/lsh123/xmlsec/releases/download/${XMLSEC_VERSION}/xmlsec1-${XMLSEC_VERSION}.sig -O xmlsec.sig

# Validate signature
GNUPGHOME="$(mktemp -d)"
export GNUPGHOME
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 00FDD6A7DFB81C88F34B9BF0E63ECDEF9E1D829E
# Verify xmlsec1 source
gpg --batch --verify xmlsec.sig xmlsec.tgz
gpgconf --kill all
rm -rf "$GNUPGHOME" xmlsec.sig

# Start building
tar xvzf xmlsec.tgz
cd xmlsec1-${XMLSEC_VERSION}
mkdir build
cd build
../configure
make -j $(nproc)
make check
make install
apt-get remove --purge -y ${build_deps}
apt-get autoremove --purge -y
apt-get clean
cd
rm -rf ${build_root}
apt-get dist-clean
