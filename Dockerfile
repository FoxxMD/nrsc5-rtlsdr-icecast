FROM ${DOCKER_ARCH}alpine:3.18

ARG USE_SSE=OFF
ARG USE_NEON=OFF
ARG TARGETPLATFORM
ARG DOCKER_ARCH

RUN \
  echo "**** install build packages ****" && \
  apk add \
    --no-cache --virtual .build-deps \
    build-base \
    cmake \
    autoconf \
    automake \
    librtlsdr-dev \
    lame-dev \
    libshout-dev \
    git && \
    apk add --no-cache \
    lame \
    ffmpeg \
    fftw-dev \
    libao-dev \
    libshout \
    libtool \
    rtl-sdr && \
    #
    # Pull nrsc5 source code from GitHub, compile it and install it
    # \
    echo "**** build nrsc5 ****" \
    && export USE_SSE=$USE_SSE \
    && export USE_NEON=$USE_NEON \
    && if [ "$DOCKER_ARCH" = "amd64" ] || [ "$TARGETPLATFORM" = "linux/amd64" ]; then export USE_SSE=ON; echo 'Using SSE'; fi \
    && if [ "$DOCKER_ARCH" = "arm64" ] || [ "$TARGETPLATFORM" = "linux/arm64" ]; then export USE_NEON=ON; echo 'Using NEON'; fi \
    && git clone https://github.com/TheDaChicken/nrsc5.git \
      && cd nrsc5/ \
      && git checkout 7909b87cd0b1281d0a3bf51930cef9ba81fc60f1 \
      && mkdir build \
      && cd build \
      && echo "Build CMD => cmake ../ -DUSE_SSE=$USE_SSE -DUSE_NEON=$USE_NEON" \
      && cmake ../ -DUSE_SSE=$USE_SSE -DUSE_NEON=$USE_NEON \
      && make \
      && make install && \
    echo "**** cleanup ****" && \
    rm -rf /nrsc5 && \
    apk del .build-deps && \
    rm -rf \
      /root/.cache \
      /tmp/*

COPY start_nrsc5.sh /start_nrsc5.sh
RUN chmod +x /start_nrsc5.sh

ENTRYPOINT ["/start_nrsc5.sh"]