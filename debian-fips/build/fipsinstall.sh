#!/bin/bash
set -e -u -o pipefail

fips_module_path="$(openssl version -e | sed 's/ENGINESDIR: //g')/fips.so"

openssl fipsinstall -out /etc/ssl/fipsmodule.cnf -module ${fips_module_path}

cat >> /etc/ssl/openssl.cnf<< EOF
config_diagnostics = 1
openssl_conf = openssl_init
.include ${fips_module_path}
[openssl_init]
providers = provider_sect
alg_section = algorithm_sect
[provider_sect]
fips = fips_sect
base = base_sect
[base_sect]
activate = 1
[algorithm_sect]
default_properties = fips=yes
EOF

# Test that OpenSSL is in FIPS mode
openssl md5
if [ $? -ne 1 ]; then
    echo "openssl md5 call succeeded"
    exit 1
else
    echo "openssl md5 fails as expected"
    exit 0
fi
