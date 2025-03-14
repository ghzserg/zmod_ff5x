#!/bin/sh

source /opt/config/mod/.shell/0.sh

unset LD_PRELOAD

if [ "$1" == "test" ] && [ -f /opt/config/mod_data/klipper_data.json ]; then
    echo "!! Найдена незаконченная печать, используйте ZRESTORE для восстановления !!"
    echo "Для удаления данных восстановления ZRESTORE TEST=2"
    echo _ZRESTORE >/tmp/printer
    exit
fi

if [ -f /opt/config/mod_data/klipper_data.json ]; then
    if ! [ -f /ZMOD ]; then
        [ ${FF5X} -eq 0 ] && umount ${UMOUNT_MOD}
        chroot ${MOD} /opt/config/mod/.shell/root/restore_gcode /opt/config/mod_data/klipper_data.json /tmp/uds ${DATA_GCODES}
        [ ${FF5X} -eq 0 ] && mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
    else
        /opt/config/mod/.shell/root/restore_gcode /opt/config/mod_data/klipper_data.json /tmp/uds ${DATA_GCODES}
    fi
else
    echo "Файл восстановления печати не найден"
fi
