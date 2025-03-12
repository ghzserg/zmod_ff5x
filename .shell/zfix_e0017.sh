#!/bin/sh

source /opt/config/mod/.shell/0.sh

[ ${FF5X} -eq 1 ] && echo "Еще не реализованно" && exit 0

F="${KLIPPER_DIR}/klippy/toolhead.py"

clear_klipper()
{
    find ${KLIPPER_DIR}/ -name __pycache__ -type d -exec rm -r "{}" \; 2>/dev/null
    sync
    find ${KLIPPER_DIR}/ -name *.pyc -exec rm "{}" \; 2>/dev/null
    sync
    echo "Klipper был изменен. Сейчас будет перезагрузка"
    sleep 5
    reboot
}

if [ "$1" == "0" ]
    then
        grep -q "LOOKAHEAD_FLUSH_TIME = 0.5" $F && exit 0
        sed -i 's|^LOOKAHEAD_FLUSH_TIME.*|LOOKAHEAD_FLUSH_TIME = 0.5|' $F
        sync
    else
        grep -q "LOOKAHEAD_FLUSH_TIME = 0.150" $F && exit 0
        sed -i 's|^LOOKAHEAD_FLUSH_TIME.*|LOOKAHEAD_FLUSH_TIME = 0.150|' $F
        sync
fi

clear_klipper
