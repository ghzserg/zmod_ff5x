#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod

source /opt/config/mod/.shell/0.sh

unset LD_PRELOAD

if [ "$1" == "test" ] && [ -f /opt/config/mod_data/klipper_data.json ]; then
    if [ ${ZLANG} != 'ru' ]; then
        echo "!! Found unfinished print, use ZRESTORE to recover !!"
        echo "To delete recovery data: ZRESTORE TEST=2"
    else
        echo "!! Найдена незаконченная печать, используйте ZRESTORE для восстановления !!"
        echo "Для удаления данных восстановления ZRESTORE TEST=2"
    fi
    echo _ZRESTORE >/tmp/printer
    exit
fi

if [ -f /opt/config/mod_data/klipper_data.json ]; then
    if ! [ -f /ZMOD ]; then
        chroot ${MOD} /opt/config/mod/.shell/root/restore_gcode /opt/config/mod_data/klipper_data.json /tmp/uds ${DATA_GCODES} ${ZLANG}
    else
        /opt/config/mod/.shell/root/restore_gcode /opt/config/mod_data/klipper_data.json /tmp/uds ${DATA_GCODES} ${ZLANG}
    fi
else
    [ ${ZLANG} != 'ru' ] && echo "Print recovery file not found" || echo "Файл восстановления печати не найден"
fi
