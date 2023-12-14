FROM ${DOCKER_ARCH}alpine:3.12

RUN \
  apk add \
    --no-cache \
    --repository 'http://dl-cdn.alpinelinux.org/alpine/edge/main' \
    build-base \
    cmake \
    autoconf \
    automake \
    librtlsdr-dev \
    libtool \
    libao-dev \
    fftw-dev \
    libshout=2.4.3-r1 \
    lame \
    lame-dev \
    libshout-dev \
    git \
    rtl-sdr \
    ffmpeg

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