ARG BUILD_IMAGE

FROM ${BUILD_IMAGE} as build

ARG XMLSEC_VERSION
ARG CRYPTOGRAPHY_VERSION

ENV wheel_output_dir /wheels

WORKDIR /build/cryptography
RUN pip install --no-cache cffi && \
    apt-get update && \
    apt-get install -y --no-install-recommends build-essential ca-certificates rustc cargo pkg-config libxslt-dev && \
    pip wheel -w ${wheel_output_dir} --no-cache --no-binary cryptography cryptography==${CRYPTOGRAPHY_VERSION} && \
    pip wheel -w ${wheel_output_dir} --no-cache --no-binary :all: xmlsec lxml && \
    apt-get remove --purge -y rustc cargo pkg-config build-essential && \
    apt-get autoremove --purge

FROM ${BUILD_IMAGE}

COPY --from=build /wheels /wheels

RUN pip install /wheels/* && \
    rm -rf /wheels
