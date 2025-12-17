#!/bin/sh

set -x

unset LD_LIBRARY_PATH
unset LD_PRELOAD

if [ -f /opt/config/mod/.shell/0.sh ]; then
    source /opt/config/mod/.shell/0.sh
else if [ -f /usr/data/config/mod/.shell/0.sh ]; then
    source /usr/data/config/mod/.shell/0.sh
fi
fi

if grep -q "klipper13 = 1" ${MOD_CONF}/mod_data/variables.cfg; then
    cnt=$(find ${PROGRAM_DIR}/control/ -name Update|wc -l)
    if [ "$cnt" -ne 0 ]; then
        # Если обновляем MCU
        find ${PROGRAM_DIR}/control/ -name Update| sed 's/Update//'| while read a; do
            mount -o bind ${MOD_CONF}/mod/.shell/update_mcu.sh ${a}run.sh
        done
    else
        # Если обновлений нет
        mount -o bind ${MOD_CONF}/mod/.shell/klipper13.sh ${KLIPPER_DIR}/start.sh
        sync
    fi
fi
