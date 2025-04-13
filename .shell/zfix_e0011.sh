#!/bin/sh

source /opt/config/mod/.shell/0.sh

[ -f /ZMOD ] && exit 0

F="${KLIPPER_DIR}/klippy/mcu.py"

clear_klipper()
{
    find ${KLIPPER_DIR}/ -name __pycache__ -type d -exec rm -r "{}" \; 2>/dev/null
    sync
    find ${KLIPPER_DIR}/ -name *.pyc -exec rm "{}" \; 2>/dev/null
    sync
    [ ${ZLANG} != 'ru' ] && echo "Klipper changed. There will be a reboot now" || echo "Klipper был изменен. Сейчас будет перезагрузка"
    sleep 5
    reboot
}

if [ "$1" == "0" ]
    then
        grep -q "TRSYNC_TIMEOUT = 0.025" $F && exit 0
        sed -i 's|^TRSYNC_TIMEOUT = .*|TRSYNC_TIMEOUT = 0.025|' $F
        sync
    else
        grep -q "TRSYNC_TIMEOUT = 0.05" $F && exit 0
        sed -i 's|^TRSYNC_TIMEOUT = .*|TRSYNC_TIMEOUT = 0.05|' $F
        sync
fi

clear_klipper
