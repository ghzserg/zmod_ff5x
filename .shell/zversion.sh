#!/bin/sh

source /opt/config/mod/.shell/0.sh

VER_FF=$(cat /opt/config/mod/version.txt 2>/dev/null| cut  -d "." -f 1,2)
VER_FF_FULL=$(cat /opt/config/mod/version.txt 2>/dev/null| cut  -d "." -f 1,2,3)

VER_MOD="0.0"
if [ -f "/root/printer_data/version.txt" ]; then
    VER_MOD=$(cat /root/printer_data/version.txt 2>/dev/null| cut  -d "." -f 1,2)
    VER_MOD_FULL=$(cat /root/printer_data/version.txt 2>/dev/null| cut  -d "." -f 1,2,3)
else if [ -f "/root/printer_data/scripts/version.txt" ]; then
    VER_MOD=$(cat /root/printer_data/scripts/version.txt 2>/dev/null| cut  -d "." -f 1,2)
    VER_MOD_FULL=$(cat /root/printer_data/version.txt 2>/dev/null| cut  -d "." -f 1,2,3)
else if [ -f "/usr/data/.mod/.zmod/root/printer_data/version.txt" ]; then
    VER_MOD=$(cat /usr/data/.mod/.zmod/root/printer_data/version.txt 2>/dev/null| cut  -d "." -f 1,2)
    VER_MOD_FULL=$(cat /usr/data/.mod/.zmod/root/printer_data/version.txt 2>/dev/null| cut  -d "." -f 1,2,3)
    fi
fi
fi

[ ${ZLANG} != 'ru' ] && echo "Installed from USB: ${VER_MOD_FULL}. Update from Fluidd/Mainsail: ${VER_FF_FULL}" || echo "Установлено с флешки: ${VER_MOD_FULL}. Обновление с Fluidd/Mainsaill: ${VER_FF_FULL}"

if [ "${VER_FF}" != "${VER_MOD}" ]; then
    if [ ${ZLANG} != 'ru' ]; then
        echo "RESPOND TYPE=error MSG=\"Update ZMOD from USB, latest version ${VER_FF_FULL}, current version ${VER_MOD_FULL}\"" >/tmp/printer
        echo "You can use ZFLASH macro to update from USB over network"
        echo 'https://github.com/ghzserg/zmod/wiki/Setup_en'
    else
        echo "RESPOND TYPE=error MSG=\"Обновите ZMOD с флешки, последняя версия ${VER_FF_FULL}, текущая версия ${VER_MOD_FULL}\"" >/tmp/printer
        echo "Можно использовать макрос ZFLASH, для обновления с флешки по сети"
        echo 'https://github.com/ghzserg/zmod/wiki/Setup'
    fi
fi
