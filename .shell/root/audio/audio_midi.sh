#!/bin/sh

source /opt/config/mod/.shell/0.sh

unset LD_PRELOAD
unset LD_LIBRARY_PATH

if ! [ -f "/opt/config/mod_data/midi/$1" ]; then #&& ! [ -f "/opt/config/mod_data/midi/$1.wav" ]
    echo "Файл mod_data/midi/$1 не найден"
    #[ ${FF5X} -eq 1 ] && echo "FF5X воспроизводит wav файлы"
    exit 1
fi

if [ ${FF5X} -eq 1 ]; then
#    [ -f "/opt/config/mod_data/midi/$1.wav" ] && chroot $MOD aplay /opt/config/mod_data/midi/$1.wav &
#    [ -f "/opt/config/mod_data/midi/$1" ] && chroot $MOD aplay /opt/config/mod_data/midi/$1 &
    export PATH=$PATH:/usr/prog/Python-3.8.2/bin
    export LD_LIBRARY_PATH=/usr/prog/Python-3.8.2/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/openssl-1.0.2d/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/libffi-3.4.4/lib:$LD_LIBRARY_PATH

    python3.8 /opt/config/mod/.shell/root/audio/audio -x midi -m "/opt/config/mod_data/midi/$1" &
else
    /opt/config/mod/.shell/root/audio/audio midi -m "/opt/config/mod_data/midi/$1" &
fi
