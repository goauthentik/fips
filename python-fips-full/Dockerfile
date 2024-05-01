ARG BUILD_IMAGE

FROM ${BUILD_IMAGE} as build

ARG XMLSEC_VERSION
ARG CRYPTOGRAPHY_VERSION

ENV wheel_output_dir /wheels

WORKDIR /build/cryptography
RUN pip install --no-cache cffi && \
    apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates rustc cargo pkg-config && \
    pip wheel -w ${wheel_output_dir} --no-cache --no-binary cryptography cryptography==${CRYPTOGRAPHY_VERSION} && \
    pip wheel -w ${wheel_output_dir} --no-cache --no-binary xmlsec xmlsec

FROM ${BUILD_IMAGE}

COPY --from=build /wheels /wheels

RUN pip install /wheels/* && \
    rm -rf /wheels
