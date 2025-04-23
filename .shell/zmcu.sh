#!/bin/sh

source /opt/config/mod/.shell/0.sh
set -x

for i in /opt/PROGRAM/control/*/; do 
    save_dir=$(pwd)
    echo "$i"
    if [ -d "$i" ]; then
        cd "$i"
        echo "">Update
        [ ${FF5X} -eq 1 ] && echo "">UpdateM

        if [ "$1" -eq 1 ] && ! [ -f /ZMOD ]; then
            start-stop-daemon -S -b -x /opt/config/mod/.shell/update_mcu.sh -- mainboard
        else
            /opt/config/mod/.shell/root/audio/audio_midi.sh For_Elise.mid
            sync
            sleep 5
            poweroff
        fi
        cd $save_dir
    fi
done
