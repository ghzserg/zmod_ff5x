#!/bin/sh

source /opt/config/mod/.shell/0.sh
set -x

CONTROL_DIR=${PROGRAM_DIR}control/
cd ${CONTROL_DIR}
CONTROL_VERSION=`ls -d [0-9]*/ | sort -Vr | head -n 1`
CONTRIL_FLAG=${CONTROL_DIR}${CONTROL_VERSION}Update
CONTRIL_M=${CONTROL_DIR}${CONTROL_VERSION}UpdateM

[ ${FF5X} -eq 1 ] && echo "">${CONTRIL_M}
echo "">${CONTRIL_FLAG}

if [ -d "${CONTROL_DIR}${CONTROL_VERSION}" ]; then
    cd "${CONTROL_DIR}${CONTROL_VERSION}"
    if [ "$1" -eq 1 ]; then
        if ! [ -f /ZMOD ]; then
            start-stop-daemon -S -b -x /opt/config/mod/.shell/update_mcu.sh -- mainboard
        else
            /opt/config/mod/.shell/zremote.sh /opt/config/mod/.shell/zmcu_13.sh "${CONTROL_DIR}${CONTROL_VERSION}"
        fi
    else
        /opt/config/mod/.shell/root/audio/audio_midi.sh For_Elise.mid
        sync
        sleep 5
        /opt/config/mod/.shell/zremote.sh poweroff
    fi
fi
