# golang parameters
ARG GO_VERSION
FROM golang:${GO_VERSION}-trixie⁠ AS base

ENV OSX_CROSS_PATH=/osxcross

FROM base AS osx-sdk
ARG OSX_SDK
ARG OSX_SDK_SUM

COPY tars/${OSX_SDK} "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}"
RUN echo "${OSX_SDK_SUM}" "${OSX_CROSS_PATH}/tarballs/${OSX_SDK}" | sha256sum -c -

FROM base AS osx-cross-base
ARG DEBIAN_FRONTEND=noninteractive

# Install deps
RUN \
    set -x; \
    echo "Starting image build for Debian Trixie" \
    && dpkg --add-architecture arm64 \
    && dpkg --add-architecture armel \
    && dpkg --add-architecture armhf \
    && dpkg --add-architecture i386 \
    && dpkg --add-architecture ppc64el \
    && apt-get update                  \
    && apt-get install --no-install-recommends -y -q \
    autoconf \
    automake \
    autotools-dev \
    bc \
    binfmt-support \
    binutils-multiarch \
    binutils-multiarch-dev \
    build-essential \
    clang \
    cmake \
    crossbuild-essential-arm64 \
    crossbuild-essential-armel \
    crossbuild-essential-armhf \
    crossbuild-essential-ppc64el \
    devscripts \
    gcc \
    gcc-aarch64-linux-gnu \
    gcc-arm-linux-gnueabi \
    gcc-arm-linux-gnueabihf \
    gcc-powerpc64le-linux-gnu  \
    libgmp-dev \
    libmpc-dev \
    libmpfr-dev \
    libssl-dev \
    libtool \
    libxml2-dev \
    llvm \
    lzma-dev \
    mingw-w64 \
    multistrap \
    patch \
    qemu-user-static \
    xz-utils \
    zlib1g-dev \
    && apt -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

FROM osx-cross-base AS osx-cross
ARG OSX_CROSS_COMMIT
WORKDIR "${OSX_CROSS_PATH}"
# install osxcross:
RUN git clone https://github.com/tpoechtrager/osxcross.git . \
    && git checkout -q "${OSX_CROSS_COMMIT}" \
    && rm -rf ./.git
COPY --from=osx-sdk "${OSX_CROSS_PATH}/." "${OSX_CROSS_PATH}/"
ARG OSX_VERSION_MIN
RUN UNATTENDED=yes OSX_VERSION_MIN=${OSX_VERSION_MIN} ./build.sh

FROM osx-cross-base AS final
LABEL maintainer="Prachya Saechua<blackb1rd@blackb1rd.dev>"
ARG DEBIAN_FRONTEND=noninteractive

COPY --from=osx-cross "${OSX_CROSS_PATH}/." "${OSX_CROSS_PATH}/"
ENV PATH=${OSX_CROSS_PATH}/target/bin:$PATH
