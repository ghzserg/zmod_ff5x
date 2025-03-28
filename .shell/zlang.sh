#!/bin/sh

source /opt/config/mod/.shell/0.sh

if [ grep -q "language: en" ${MOD_CONF}/mod_data/lang.cfg ]; then
    LANG="ru"
else
    LANG="en"
fi

echo "[zmod]
language: '${LANG}'" >${MOD_CONF}/mod_data/lang.cfg

sync
sleep 5
sync
reboot
