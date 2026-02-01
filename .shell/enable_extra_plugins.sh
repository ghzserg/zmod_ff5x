#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod

source /opt/config/mod/.shell/0.sh

if [ "$1" == "1" ]; then
    echo "[include ../mod/extra_plugins.moonraker.conf]" >${MOD_CONF}/mod_data/extra_plugins.moonraker.conf
else
    echo "" >${MOD_CONF}/mod_data/extra_plugins.moonraker.conf
fi

echo REBOOT >/tmp/printer
