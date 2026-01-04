#!/bin/sh

if [ -f /ZMOD ]; then
    /opt/config/mod/.shell/zremote.sh /opt/config/mod/.shell/screen.sh
    exit
fi

source /opt/config/mod/.shell/0.sh

FB_DEV="/dev/fb0"
OUT_FILE="/opt/config/mod_data/screen.jpg"
WIDTH=800
HEIGHT=480

[ ${AD5X} -eq 0 ] && FFMPEG="/opt/ffmpeg-4.0.2/bin/ffmpeg" || FFMPEG="/usr/prog/ffmpeg-4.0.2/bin/ffmpeg"
export LD_LIBRARY_PATH="/usr/prog/ffmpeg-4.0.2/lib:/usr/prog/x264/lib:/opt/ffmpeg-4.0.2/lib:/opt/x264/lib"

"$FFMPEG" -f rawvideo -pix_fmt bgra \
 -video_size ${WIDTH}x${HEIGHT} \
 -i "$FB_DEV" \
 -vframes 1 \
 -f image2 \
 -q:v 4 \
 "$OUT_FILE" \
 -y 2>/dev/null

[ ${ZLANG} != 'ru' ] && echo "Printer screen shot: mod_data/screen.jpg" || echo "Скриншот экрана принтера: mod_data/screen.jpg"
