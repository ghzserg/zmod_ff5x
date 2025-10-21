#!/bin/sh

source /opt/config/mod/.shell/0.sh

if grep -q "[update_manager $1]" ${MOD_CONF}/moonraker.conf || grep -q "[update_manager $1]" ${MOD_CONF}/mod_data/user.moonraker.conf; then
    if ! [ -f "${MOD_CONF}/mod_data/plugins/$1/$1.cfg" ]; then
        if [ ${ZLANG} != 'ru' ]; then
            echo "Plugin $1 not found in mod_data/plugins/$1/$1.cfg"
        else
            echo "Основной файл плагина $1 не найден в mod_data/plugins/$1/$1.cfg"
        fi
        exit 1
    fi
    if [ "$2" == "Enable" ]; then
        if [ ${ZLANG} != 'ru' ]; then
            echo "Enable plugin $1"
        else
            echo "Включаю плагин $1"
        fi
        echo "[include plugins/$1/$1.cfg]" >>${MOD_CONF}/mod_data/plugins.cfg
    else
        if [ ${ZLANG} != 'ru' ]; then
            echo "Disable plugin $1"
        else
            echo "Выключаю плагин $1"
        fi
        sed -i "/plugins\/$1\/$1\.cfg/d" ${MOD_CONF}/mod_data/plugins.cfg
    fi
    echo "FIRMWARE_RESTART" >/tmp/printer
else
    if [ ${ZLANG} != 'ru' ]; then
        echo "Plugin $1 not found in moonraker.conf, mod_data/user.moonraker.conf"
    else
        echo "Плагин $1 не найден в файлах moonraker.conf, mod_data/user.moonraker.conf"
    fi
fi
