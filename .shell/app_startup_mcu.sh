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

CHECH_ARCH=`uname -m`
if [ "${CHECH_ARCH}" == "armv7l" ]; then
    CONFIG_DIR="/opt/config"
else if [ "${CHECH_ARCH}" == "mips" ]; then
    CONFIG_DIR="/usr/data/config"
fi
fi

app_startup_mcu()
{
    if grep -q "klipper13 = 1" ${MOD_CONF}/mod_data/variables.cfg; then
        echo "Klipper 13"
        cnt=$(find ${PROGRAM_DIR}control/ -name Update|wc -l)
        if [ "$cnt" -ne 0 ]; then
            # Если обновляем MCU
            find ${PROGRAM_DIR}control/ -name Update| sed 's/Update//'| while read a; do
                mount -o bind ${MOD_CONF}/mod/.shell/update_mcu.sh ${a}run.sh
                if [ ${FF5X} -eq 1 ]; then
                    cd "${a}"
                    ./run.sh
                    reboot -f
                fi
            done
        else
            # Если обновлений нет
            mount -o bind ${MOD_CONF}/mod/.shell/klipper13.sh ${KLIPPER_DIR}/start.sh
            sync
        fi
    else
        echo "Родной Klipper"
    fi
}

mv ${CONFIG_DIR}/mod_data/log/app_startup_mcu.4.log ${CONFIG_DIR}/mod_data/log/app_startup_mcu.5.log
mv ${CONFIG_DIR}/mod_data/log/app_startup_mcu.3.log ${CONFIG_DIR}/mod_data/log/app_startup_mcu.4.log
mv ${CONFIG_DIR}/mod_data/log/app_startup_mcu.2.log ${CONFIG_DIR}/mod_data/log/app_startup_mcu.3.log
mv ${CONFIG_DIR}/mod_data/log/app_startup_mcu.1.log ${CONFIG_DIR}/mod_data/log/app_startup_mcu.2.log
mv ${CONFIG_DIR}/mod_data/log/app_startup_mcu.log ${CONFIG_DIR}/mod_data/log/app_startup_mcu.1.log

app_startup_mcu &>${CONFIG_DIR}/mod_data/log/app_startup_mcu.log
