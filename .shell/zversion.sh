#!/bin/sh

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

echo "Установлено с флешки: ${VER_MOD_FULL}. Обновление с Fluidd/Mainsaill: ${VER_FF_FULL}"
if [ "${VER_FF}" != "${VER_MOD}" ] || [ "${VER_MOD_FULL}" == "1.4.0" ]; then
    echo "RESPOND TYPE=error MSG=\"Обновите ZMOD с флешки, последняя версия ${VER_FF_FULL}, текущая версия ${VER_MOD_FULL}\"" >/tmp/printer
    echo 'RESPOND TYPE=echo MSG="https://github.com/ghzserg/zmod/wiki/Setup"' >/tmp/printer
fi
