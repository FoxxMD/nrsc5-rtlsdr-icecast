#!/bin/sh

PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"

ACTUAL_CHANNEL="${CHANNEL:-1}"
INDEXED_CHANNEL="$(($ACTUAL_CHANNEL - 1))"

while :
do
	echo "------ Starting stream ------"
	lame --version | head -n 1
	echo "-----------------------------"
	nrsc5 -v
	echo "-----------------------------"
	echo "Listening on $RADIO_STATION Channel ${CHANNEL:-1} and encoding to ${AUDIO_FORMAT:-MP3}";
	echo "-----------------------------"
	case $AUDIO_FORMAT in
	  OGG)
	    nrsc5 -q -o - "$RADIO_STATION" "$INDEXED_CHANNEL" | ffmpeg -i - -vn -content_type audio/ogg -f ogg -c:a -aq 4 libvorbis icecast://source:"$ICECAST_PWD"@"$ICECAST_URL"
	    ;;
	  WAV)
	    nrsc5 -q -o - "$RADIO_STATION" "$INDEXED_CHANNEL" | ffmpeg -i - -vn -content_type audio/x-wav -f s16le -bitexact -c:a copy icecast://source:"$ICECAST_PWD"@"$ICECAST_URL"
	    ;;
	  MP3|*)
	    nrsc5 -q -o - "$RADIO_STATION" "$INDEXED_CHANNEL" | ffmpeg -i - -vn -content_type audio/mp3 -f mp3 -q:a 3 -c:a libmp3lame icecast://source:"$ICECAST_PWD"@"$ICECAST_URL"
	    ;;
	esac
	echo "------ Stream exited --------"
done