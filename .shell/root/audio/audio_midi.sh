#!/bin/sh

source /opt/config/mod/.shell/0.sh

unset LD_PRELOAD
unset LD_LIBRARY_PATH

if ! [ -f "/opt/config/mod_data/midi/$1" ]
    then
        echo "Файл mod_data/midi/$1 не найден"
        exit 1
fi

if [ ${FF5X} -eq 1 ]; then
    export LD_LIBRARY_PATH=/usr/prog/qt-4.8.6/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/openssl-1.0.2d/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/curl-7.55.1-https/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/ffmpeg-4.0.2/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/x264/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/libffi-3.4.4/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/opencv-4.2.0_mips/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/libzip-1.10.1/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/nim/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/Python-3.8.2/lib:$LD_LIBRARY_PATH
    ${PYTHON} /opt/config/mod/.shell/root/audio/audio midi -m "/opt/config/mod_data/midi/$1" &
else
    /opt/config/mod/.shell/root/audio/audio midi -m "/opt/config/mod_data/midi/$1" &
fi
