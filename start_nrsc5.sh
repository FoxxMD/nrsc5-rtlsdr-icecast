#!/bin/sh

# --- nrsc5 configuration ---
#
# Using raw output to avoid WAV file limitations for constant streaming
# https://github.com/theori-io/nrsc5/pull/296
# https://github.com/theori-io/nrsc5/issues/279
#
# --- ffmpeg configuration
#
# Improve constant streaming robustness by making decoding/remuxing/output separate threads
# and specifying restart or recovery attempt to output (if it can)
# https://www.reddit.com/r/ffmpeg/comments/ld4zyt/is_it_possiible_to_make_ffmpeg_restart/
# https://ffmpeg.org/ffmpeg-all.html#fifo-1

PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"

ACTUAL_CHANNEL="${CHANNEL:-1}"
INDEXED_CHANNEL="$(($ACTUAL_CHANNEL - 1))"

STATS_INT="${STATS_INTERVAL:-0.5}"

if [ "$STATS_INT" = "0" ]; then
    STATS_OPT="-nostats"
  else
    STATS_OPT="-stats_period $STATS_INT"
fi

RTL_OPT=""
RTL_HUMAN=""
if [ -n "$RTL_TCP" ]; then
    RTL_OPT="-H $RTL_TCP"
    RTL_HUMAN=" through rtl-tcp server $RTL_TCP"
fi

NRSC_CMD="nrsc5 -t raw $RTL_OPT -o - $RADIO_STATION $INDEXED_CHANNEL"

ffmpeg_pipe () {

  AUDIO_ARGS=""
  FORMAT_ARGS=""
  FIFO_ARGS=""
  EXTRA_ARGS=""
  ICECAST_ARGS="icecast://source:$ICECAST_PWD@$ICECAST_URL"
  OUTPUT_ARGS=$ICECAST_ARGS
  if [ -n "${FFMPEG_OUTPUT}" ];then
    OUTPUT_ARGS=FFMPEG_OUTPUT
  fi

  case $AUDIO_FORMAT in
    OGG)
      AUDIO_ARGS="-c:a libvorbis"
      FIFO_ARGS="-fifo_format ogg"
      FORMAT_ARGS="-format_opts content_type=audio/ogg"
      EXTRA_ARGS="-aq 4"
      ;;
    WAV)
      AUDIO_ARGS="-c:a cop"
      FIFO_ARGS="-fifo_format s16le"
      FORMAT_ARGS="-format_opts content_type=audio/ogg"
      ;;
    MP3|*)
      AUDIO_ARGS="-q:a 3 -c:a libmp3lame"
      FIFO_ARGS="-fifo_format mp3"
      FORMAT_ARGS="-format_opts content_type=audio/mp3"
      ;;
  esac

  set -x
  ffmpeg -re \
        -hide_banner \
        $STATS_OPT \
        -vn \
        -ac 2 \
        -channel_layout stereo \
        -ar 44100 \
        -f s16le -i - \
        $AUDIO_ARGS \
        $FORMAT_ARGS \
        -f fifo \
        $FIFO_ARGS \
        $FORMAT_ARGS \
        -map 0:a \
        -drop_pkts_on_overflow 1 \
        -attempt_recovery 1 \
        -recovery_wait_time 1 \
        -queue_size 100 \
        $EXTRA_ARGS \
        $OUTPUT_ARGS
}

nrsc_logging() {

INIT=1
TITLE=""
NEW_TITLE=""
while IFS= read line; do

  if [ "$INIT" = 1 ]; then
    # https://stackoverflow.com/questions/229551/how-to-check-if-a-string-contains-a-substring-in-bash
    case "$line" in
      *Title*)
        # Do stuff
        INIT=0
        ;;
      *)
        echo "${line}"
        ;;
    esac
  else
    case "$line" in
      *Title*)
      # https://stackoverflow.com/a/58379307/1469797
      NEW_TITLE=$(echo "$line" | sed -nr 's/.+ Title: (.+)/\1/p')
      if [ "$TITLE" != "$NEW_TITLE" ]; then
        echo "New Title: $NEW_TITLE"
        TITLE="$NEW_TITLE"
      fi
        ;;
    esac
  fi

done
}

	echo "------ Starting stream ------"
	lame --version | head -n 1
	ffmpeg -version | head -n 1
	nrsc5 -v
	echo "-----------------------------"
	echo "Listening on $RADIO_STATION Channel ${CHANNEL:-1}$RTL_HUMAN and encoding to ${AUDIO_FORMAT:-MP3}";
	echo "CMD => $NRSC_CMD"
	echo "-----------------------------"
	# https://stackoverflow.com/a/27673635/1469797
	{ $NRSC_CMD 2>&3 | ffmpeg_pipe; } 3>&1 1>&2 | nrsc_logging
	echo "------ Stream exited --------"