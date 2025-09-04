#!/bin/bash
set -e -u -o pipefail

source common.sh

# Prepare for debian source download
sed -i -s 's/Types: deb/Types: deb deb-src/g' /etc/apt/sources.list.d/debian.sources
apt-get update
apt-get install -y dpkg-dev build-essential wget ca-certificates
apt-get build-dep -y openssl=${OPENSSL_VERSION}
