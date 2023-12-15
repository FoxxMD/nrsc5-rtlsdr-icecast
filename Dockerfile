FROM ${DOCKER_ARCH}alpine:3.18

RUN \
  echo "**** install build packages ****" && \
  apk add \
    --no-cache \
    build-base \
    cmake \
    autoconf \
    automake \
    librtlsdr-dev \
    libtool \
    libao-dev \
    fftw-dev \
    libshout \
    lame \
    lame-dev \
    libshout-dev \
    git \
    rtl-sdr \
    ffmpeg && \
    echo "**** cleanup ****" && \
    rm -rf \
      /root/.cache \
      /tmp/*

#
# Pull nrsc5 source code from GitHub, compile it and install it
#
RUN git clone https://github.com/theori-io/nrsc5.git \
  && cd nrsc5/ \
  && mkdir build \
  && cd build \
  && cmake ../ \
  && make \
  && make install 

COPY start_nrsc5.sh /start_nrsc5.sh
RUN chmod +x /start_nrsc5.sh

ENTRYPOINT ["/start_nrsc5.sh"]