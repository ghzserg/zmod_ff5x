#!/bin/sh

source /opt/config/mod/.shell/0.sh
set -x

if grep -q bambufy /opt/config/mod_data/plugins.cfg; then
    echo "RESPOND TYPE=command MSG=action:prompt_end" >/tmp/printer
    [ ${ZLANG} != 'ru' ] && echo "RESPOND TYPE=error MSG=\"Отключите плагин Bambufy. DISABLE_PLUGIN name=bambufy\"">/tmp/printer || echo "RESPOND TYPE=error MSG=\"Disable plugin Bambufy. DISABLE_PLUGIN name=bambufy\"">/tmp/printer
    exit 0
fi

CONTROL_DIR=${PROGRAM_DIR}control/
cd ${CONTROL_DIR}
if [ ${FF5X} -eq 1 ]; then
    CONTROL_VERSION=`ls -d [0-9]*/ | sort -Vr | head -n 1`
else
    CONTROL_VERSION=`ls -d [0-9]*/ | sort -t '.' -k1,1n -k2,2n -k3,3n -r | head -n 1`
fi
CONTRIL_FLAG=${CONTROL_DIR}${CONTROL_VERSION}Update
CONTRIL_M=${CONTROL_DIR}${CONTROL_VERSION}UpdateM

[ ${FF5X} -eq 1 ] && echo "">${CONTRIL_M}
echo "">${CONTRIL_FLAG}

if [ -d "${CONTROL_DIR}${CONTROL_VERSION}" ]; then
    cd "${CONTROL_DIR}${CONTROL_VERSION}"
    if [ "$1" -eq 1 ]; then
        echo "SAVE_VARIABLE VARIABLE=klipper13 VALUE=1" >/tmp/printer
        if ! [ -f /ZMOD ]; then
            start-stop-daemon -S -b -x /opt/config/mod/.shell/update_mcu.sh -- mainboard
        else
            /opt/config/mod/.shell/zremote.sh /opt/config/mod/.shell/zmcu_13.sh "${CONTROL_DIR}${CONTROL_VERSION}"
        fi
    else
        echo "SAVE_VARIABLE VARIABLE=klipper13 VALUE=0" >/tmp/printer
        /opt/config/mod/.shell/root/audio/audio_midi.sh For_Elise.mid
        sync
        sleep 5
        /opt/config/mod/.shell/zremote.sh poweroff
    fi
fi
