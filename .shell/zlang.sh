#!/bin/sh

source /opt/config/mod/.shell/0.sh

if [ "${ZLANG}" == "en" ]; then
    ZLANG="ru"
else
    ZLANG="en"
fi

echo "[zmod]
language: ${ZLANG}" >${MOD_CONF}/mod_data/lang.cfg

sync
sleep 5
sync
reboot
