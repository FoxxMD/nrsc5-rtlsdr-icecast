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

while :
do
	echo "------ Starting stream ------"
	lame --version | head -n 1
	ffmpeg -version | head -n 1
	nrsc5 -v
	echo "-----------------------------"
	echo "Listening on $RADIO_STATION Channel ${CHANNEL:-1} and encoding to ${AUDIO_FORMAT:-MP3}";
	#echo "CMD => nrsc5 -q -t raw -o - $RADIO_STATION $INDEXED_CHANNEL"
	echo "-----------------------------"
	case $AUDIO_FORMAT in
	  OGG)
      nrsc5 -q -t raw -o - "$RADIO_STATION" "$INDEXED_CHANNEL" | ffmpeg -re \
            -hide_banner \
            $STATS_OPT \
            -vn \
            -ac 2 \
            -channel_layout stereo \
            -ar 44100 \
            -f s16le -i - \
            -c:a libvorbis \
            -f fifo \
            -fifo_format ogg \
            -format_opts content_type=audio/ogg \
            -map 0:a \
            -drop_pkts_on_overflow 1 \
            -attempt_recovery 1 \
            -recovery_wait_time 1 \
            -queue_size 100 \
            -aq 4 \
            icecast://source:"$ICECAST_PWD"@"$ICECAST_URL"
	    ;;
	  WAV)
      nrsc5 -q -t raw -o - "$RADIO_STATION" "$INDEXED_CHANNEL" | ffmpeg -re \
            -hide_banner \
            $STATS_OPT \
            -vn \
            -ac 2 \
            -channel_layout stereo \
            -ar 44100 \
            -f s16le -i - \
            -c:a copy \
            -f fifo \
            -fifo_format s16le \
            -format_opts content_type=audio/ogg \
            -map 0:a \
            -drop_pkts_on_overflow 1 \
            -attempt_recovery 1 \
            -recovery_wait_time 1 \
            -queue_size 100 \
            icecast://source:"$ICECAST_PWD"@"$ICECAST_URL"
	    ;;
	  MP3|*)
	    nrsc5 -q -t raw -o - "$RADIO_STATION" "$INDEXED_CHANNEL" | ffmpeg -re \
            -hide_banner \
            $STATS_OPT \
            -vn \
            -ac 2 \
            -channel_layout stereo \
      	    -ar 44100 \
      	    -f s16le -i - \
      	    -q:a 3 -c:a libmp3lame \
      	    -f fifo \
      	    -fifo_format mp3 \
      	    -format_opts content_type=audio/mp3 \
      	    -map 0:a \
      	    -drop_pkts_on_overflow 1 \
      	    -attempt_recovery 1 \
      	    -recovery_wait_time 1 \
      	    -queue_size 100 \
      	    icecast://source:"$ICECAST_PWD"@"$ICECAST_URL"
	    ;;
	esac
	echo "------ Stream exited --------"
done


# example using default (wav) nrsc5 output
#	    nrsc5 -q -o - "$RADIO_STATION" "$INDEXED_CHANNEL" | ffmpeg -i - -vn -re \
#	    -ar 44100 \
#	    -q:a 3 -c:a libmp3lame \
#	    -f fifo \
#	    -fifo_format mp3 \
#	    -format_opts content_type=audio/mp3 \
#	    -map 0:a \
#	    -drop_pkts_on_overflow 1 \
#	    -attempt_recovery 1 \
#	    -recovery_wait_time 1 \
#	    -queue_size 100 \
#	    icecast://source:"$ICECAST_PWD"@"$ICECAST_URL"