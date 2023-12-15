FROM ${DOCKER_ARCH}alpine:3.18

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
    echo "**** build nrsc5 ****" && \
    git clone https://github.com/theori-io/nrsc5.git \
      && cd nrsc5/ \
      && mkdir build \
      && cd build \
      && cmake ../ \
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