#!/bin/bash
repo="ghcr.io/beryju"
image_prefix="fips"
docker build debian-fips/ -t ${repo}/${image_prefix}-debian:bookworm-slim-fips
