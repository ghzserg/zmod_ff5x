#!/bin/sh

source /opt/config/mod/.shell/0.sh

[ ${NEED_REMOUNT} -eq 0 ] && exit 0
[ -f /ZMOD ] && exit 0

F="/opt/klipper/klippy/toolhead.py"

clear_klipper()
{
    find /opt/klipper/ -name __pycache__ -type d -exec rm -r "{}" \; 2>/dev/null
    sync
    find /opt/klipper/ -name *.pyc -exec rm "{}" \; 2>/dev/null
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
