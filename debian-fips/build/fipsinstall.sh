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
61c62
< # fips = fips_sect
---
> fips = fips_sect
73a76,79
> [default_sect]
> activate = 1
> [algorithm_sect]
> default_properties = fips=yes
EOF

apt-get remove -y --purge patch
apt-get dist-clean

# Test that FIPS provider loads
openssl list -providers -provider default -provider base -provider fips
