## FIPS Container images

[![CI Build status](https://img.shields.io/github/actions/workflow/status/goauthentik/fips/build.yml?branch=main&style=for-the-badge)](https://github.com/goauthentik/fips/actions)

A collection of container images with a FIPS-enabled OpenSSL build.

### `debian-fips`

Debian Trixie (slim) with OpenSSL built with FIPS support enabled.

### `xmlsec1-fips`

Built on top of `debian-fips`, with xmlsec1 built and installed.

### `python-fips`

Built on top of `xmlsec1-fips`, with the latest Python 3.12 and 3.13 version.
