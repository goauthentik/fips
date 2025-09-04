#!/bin/bash
set -e -u -o pipefail

fips_module_conf="/etc/ssl/fipsmodule.cnf"
openssl_conf="/etc/ssl/openssl.cnf"

apt-get install -y --no-install-recommends openssl openssl-provider-fips
openssl fipsinstall -out /etc/ssl/fipsmodule.cnf -module $(find /usr/lib -name fips.so)

sed -i "s:# .include fipsmodule.cnf:.include ${fips_module_conf}:" ${openssl_conf}
sed -i 's:# fips = fips_sect:fips = fips_sect:' ${openssl_conf}
sed -i 's:# \[provider_sect\]:\[provider_sect\]:' ${openssl_conf}

# https://stackoverflow.com/questions/76049736/ee-certificate-key-too-weak-error-in-openssl-3-1-0-fips-enabled
sed -i 's:# activate = 1:activate = 1:' ${openssl_conf}
echo "\n[algorithm_sect]\ndefault_properties = fips=yes" >> ${openssl_conf}
