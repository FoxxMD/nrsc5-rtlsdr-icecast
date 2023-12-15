# nrsc5-rtlsdr-icecast

Based on [sample-icecast-nrsc5](https://github.com/zacs/sample-icecast-nrsc5) by [zacs](https://github.com/zacs).

Use an RTL-SDR device to stream HD radio to an Icecast server. If you do not already have an Icecast server setup I would recommend [jeer/docker-icecast](https://github.com/jee-r/docker-icecast).

## Setup

### Docker Image

```
ghcr.io/foxxmd/nrsc5-rtlsdr-icecast
docker.io/foxxmd/nrsc5-rtlsdr-icecast
```

### Local Docker Build

1. Clone this repo
2. Run `docker build -t nrsc5 .`

Substitute `nrsc5` for remote images (docker.io/ghcr.io) in documentation.

## Usage

Minimal run command example:
```
 docker run -e "RADIO_STATION=90.1" -e "ICECAST_URL=192.168.1.10:8000/myradio" -e "ICECAST_PWD=icecastPass" --device /dev/bus/usb/005/006 ghcr.io/foxxmd/nrsc5-rtlsdr-icecast
```
Or use the [docker-compose.yml](/docker-compose.yml) example.

| Environmental Variable | Required | Default |                                                                  Description                                                                  |
|------------------------|----------|---------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| `ICECAST_URL`          | **Yes**  |         | Icecast server and path to stream to IE => 192.168.1.10/myRadio                                                                               |
| `ICECAST_PWD`          | **Yes**  |         | The Icecast server **source** password                                                                                                        |
| `RADIO_STATION`        | **Yes**  |         | The radio station to tune to                                                                                                                  |
| `CHANNEL`              | No       | 1       | The HD channel on the radio station to tune in to                                                                                             |
| `AUDIO_FORMAT`         | No       | MP3     | Encode icecast stream to this format. Options: MP3, OGG, WAV                                                                                  |
| `RTL_TCP`              | No       |         | Connect to rtl-tcp server instead of using hardware device. Syntax [HOST]:[PORT] -- EX 192.168.1.10:1234                                      |
| `STATS_INTERVAL`       | No       | 0.5     | Interval, in seconds, ffmpeg outputs progress stats. Set to a high number to avoid noisy, non-interactive log output OR set to `0` to disable |

### Accessing RTL-SDR USB

#### By rtl_tcp

Connect to a [rtl_tcp server](https://manpages.ubuntu.com/manpages/lunar/en/man1/rtl_tcp.1.html) ([dockerized example]) by using the `RTL_TCP` ENV documented under [usage](#usage).

#### By Device

Run `lsusb` to get a list of USB devices attached to your host. It will look like this:

```
$ lsusb
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 001 Device 002: ID 8087:0032 Intel Corp. AX210 Bluetooth
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
...
Bus 005 Device 006: ID 0bda:2838 Realtek Semiconductor Corp. RTL2838 DVB-T
Bus 006 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
```

Look for your device, it usually has **RTL** or **DVB-T** in the name. Use the `Bus` and `Device` identifiers to build the path to your usb device. EX:

> Bus **005** Device **006**: ID 0bda:2838 Realtek Semiconductor Corp. RTL2838 DVB-T

```
/dev/bus/usb/005/006
```

Pass this into your docker run command like this:

```
--device /dev/bus/usb/005/006
```

#### Privileged

Alternatively, use [`--privileged`](https://docs.docker.com/engine/reference/commandline/run/) to pass all host capabilities (not very secure) which will ensure your USB device is visible regardless of where it is.