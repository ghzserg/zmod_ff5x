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

    CONTROL_DIR=${PROGRAM_DIR}control/
    cd ${CONTROL_DIR}
    if [ ${AD5X} -eq 1 ]; then
        CONTROL_VERSION=`ls -d [0-9]*/ | sort -Vr | head -n 1`
    else
        CONTROL_VERSION=`ls -d [0-9]*/ | sort -t '.' -k1,1n -k2,2n -k3,3n -r | head -n 1`
    fi

    if grep -q "klipper13 = 1" ${MOD_CONF}/mod_data/variables.cfg; then
        echo "Klipper 13"
        KLIPPER13=1
    else
        echo "Родной Klipper"
        KLIPPER13=0
    fi

    CONTRIL_FLAG=${CONTROL_DIR}${CONTROL_VERSION}Update
    CONTRIL_M=${CONTROL_DIR}${CONTROL_VERSION}UpdateM

    if  [ -f "${CONTRIL_M}" ] || [ -f ${CONTRIL_FLAG} ]; then
        [ ${KLIPPER13} -eq 1 ] && mount -o bind ${MOD_CONF}/mod/.shell/update_mcu.sh ${CONTROL_DIR}${CONTROL_VERSION}run.sh
        if [ ${AD5X} -eq 1 ]; then
            cd ${CONTROL_DIR}${CONTROL_VERSION}
            ./run.sh
            reboot -f
        fi
    else
        [ ${KLIPPER13} -eq 1 ] && mount -o bind ${MOD_CONF}/mod/.shell/klipper13.sh ${KLIPPER_DIR}/start.sh
    fi
}

mv ${CONFIG_DIR}/mod_data/log/app_startup_mcu.4.log ${CONFIG_DIR}/mod_data/log/app_startup_mcu.5.log
mv ${CONFIG_DIR}/mod_data/log/app_startup_mcu.3.log ${CONFIG_DIR}/mod_data/log/app_startup_mcu.4.log
mv ${CONFIG_DIR}/mod_data/log/app_startup_mcu.2.log ${CONFIG_DIR}/mod_data/log/app_startup_mcu.3.log
mv ${CONFIG_DIR}/mod_data/log/app_startup_mcu.1.log ${CONFIG_DIR}/mod_data/log/app_startup_mcu.2.log
mv ${CONFIG_DIR}/mod_data/log/app_startup_mcu.log ${CONFIG_DIR}/mod_data/log/app_startup_mcu.1.log

app_startup_mcu &>${CONFIG_DIR}/mod_data/log/app_startup_mcu.log
