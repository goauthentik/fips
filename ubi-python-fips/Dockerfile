ARG BUILD_IMAGE
FROM ${BUILD_IMAGE} AS builder

ARG PYTHON_VERSION
ARG PYTHON_VERSION_TAG
ARG GPG_KEY

# Install build dependencies
RUN set -eux; \
	sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/ubi.repo && \
	microdnf update -y && \
	microdnf install -y \
		gcc gcc-c++ make \
		bzip2-devel \
		expat-devel libffi-devel \
		xz-devel \
		sqlite-devel \
		wget xz zlib-devel gnupg2 tar \
	&& microdnf clean all

# Download and verify Python source
RUN set -eux; \
	wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" && \
	wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" && \
	GNUPGHOME="$(mktemp -d)"; export GNUPGHOME && \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$GPG_KEY" && \
	gpg --batch --verify python.tar.xz.asc python.tar.xz && \
	gpgconf --kill all && \
	rm -rf "$GNUPGHOME" python.tar.xz.asc && \
	mkdir -p /usr/src/python && \
	tar --extract --directory /usr/src/python --strip-components=1 --file python.tar.xz && \
	rm python.tar.xz

# Configure Python
WORKDIR /usr/src/python
RUN set -eux; \
	./configure \
		--enable-loadable-sqlite-extensions \
		--enable-optimizations \
		--enable-option-checking=fatal \
		--enable-shared \
		--with-lto \
		--with-system-expat \
		--with-ensurepip \
		--prefix=/usr/local && \
	sed -i 's/^GITTAG=.*/GITTAG=echo ${PYTHON_VERSION_TAG}/g' Makefile && \
	sed -i 's/^GITBRANCH=.*/GITBRANCH=echo ${PYTHON_VERSION_TAG}/g' Makefile

# Build Python
RUN set -eux; \
	nproc="$(nproc)" && \
	LDFLAGS="-Wl,--strip-all" && \
	make -j "$nproc" \
		"LDFLAGS=${LDFLAGS:-}" \
		"PROFILE_TASK=${PROFILE_TASK:-}"

# Install Python
RUN set -eux; \
	rm python && \
	nproc="$(nproc)" && \
	make -j "$nproc" \
		"LDFLAGS=${LDFLAGS:--Wl},-rpath='\$\$ORIGIN/../lib'" \
		"PROFILE_TASK=${PROFILE_TASK:-}" \
		python && \
	make install

# Clean up Python installation
RUN set -eux; \
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
			-o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name 'libpython*.a' \) \) \
		\) -exec rm -rf '{}' + && \
	ldconfig && \
	strip /usr/local/bin/python3* /usr/local/lib/libpython*.so* || true

# Runtime stage
FROM ${BUILD_IMAGE}

ARG PYTHON_VERSION
ARG PYTHON_VERSION_TAG

# Install only runtime dependencies
RUN set -eux; \
	sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/ubi.repo && \
	microdnf update -y && \
	microdnf install -y \
		tzdata \
		expat \
	&& microdnf clean all && rm -rf /var/cache/dnf

# Copy Python from builder
COPY --from=builder /usr/local/bin/python3* /usr/local/bin/
COPY --from=builder /usr/local/lib/python3* /usr/local/lib/
COPY --from=builder /usr/local/lib/libpython*.so* /usr/local/lib/
COPY --from=builder /usr/local/lib/pkgconfig/python*.pc /usr/local/lib/pkgconfig/
COPY --from=builder /usr/local/include/python3* /usr/local/include/

# Set up environment
ENV PATH="/usr/local/bin:${PATH}"
ENV LANG="C.UTF-8"

# Create symlinks and verify installation
RUN set -eux; \
	ldconfig && \
	for src in idle3 pip3 pydoc3 python3 python3-config; do \
		dst="$(echo "$src" | tr -d 3)"; \
		[ -s "/usr/local/bin/$src" ]; \
		[ ! -e "/usr/local/bin/$dst" ]; \
		ln -svT "$src" "/usr/local/bin/$dst"; \
	done && \
	python3 --version && \
	pip3 --version && \
	echo "SUCCESS: Python with FIPS OpenSSL is ready"

CMD ["python3"]
