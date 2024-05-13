## FIPS Container images

[![Build](https://github.com/goauthentik/fips/actions/workflows/build.yml/badge.svg)](https://github.com/goauthentik/fips/actions/workflows/build.yml)

A collection of container images with a FIPS-enabled OpenSSL build.

### `debian-fips`

Debian Bookworm (slim) with OpenSSL built with FIPS support enabled.

### `xmlsec1-fips`

Built on top of `debian-fips`, with xmlsec1 built and installed.

### `python-fips`

Built on top of `xmlsec1-fips`, with Python 3.12.3 built.

### `python-fips-full`

Built on top of `python-fips` with dependencies like Cryptography and xmlsec built.
