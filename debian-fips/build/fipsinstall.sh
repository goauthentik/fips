#!/bin/bash
set -e -u -o pipefail

modules_dir=$(openssl version -m | sed 's/MODULESDIR: //g' | sed 's/"//g')
mkdir -p ${modules_dir}
fips_module_path="${modules_dir}/fips.so"

cp /output-fips/fips.so ${fips_module_path}

openssl fipsinstall -out /etc/ssl/fipsmodule.cnf -module ${fips_module_path}

apt-get update
apt-get install -y --no-install-recommends patch

patch -b /etc/ssl/openssl.cnf <<EOF
51c51
< # .include fipsmodule.cnf
---
> .include /etc/ssl/fipsmodule.cnf
54a55
> alg_section = algorithm_sect
61c62,63
< # fips = fips_sect
---
> fips = fips_sect
> base = base_sect
73a76,79
> [base_sect]
> activate = 1
> [algorithm_sect]
> default_properties = fips=yes
EOF

apt-get remove --purge patch
apt-get dist-clean

# Test that FIPS provider loads
openssl list -providers -provider default -provider base -provider fips

# Test that OpenSSL is in FIPS mode
openssl md5
if [ $? -ne 1 ]; then
    echo "openssl md5 call succeeded"
    exit 1
else
    echo "openssl md5 fails as expected"
    exit 0
fi
