ARG BUILD_IMAGE

FROM ${BUILD_IMAGE} AS build

COPY ./requirements.txt /build/requirements.txt
ENV wheel_output_dir=/wheels

WORKDIR /build/cryptography
RUN pip install --no-cache cffi && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential libffi-dev \
        # Required for cryptography
        rustc cargo pkg-config \
        # Required for lxml
        libxslt-dev zlib1g-dev \
        # Required for xmlsec
        libltdl-dev && \
    pip wheel -w ${wheel_output_dir} --no-cache --no-binary :all: -r /build/requirements.txt && \
    apt-get remove --purge -y rustc cargo pkg-config build-essential && \
    apt-get autoremove --purge -y

FROM ${BUILD_IMAGE}

COPY --from=build /wheels /wheels

RUN apt-get update && \
    apt-get install -y --no-install-recommends libltdl7 libxslt1.1 && \
    pip install /wheels/* && \
    rm -rf /var/lib/apt/lists/*
