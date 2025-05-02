#!/bin/sh

source /opt/config/mod/.shell/0.sh

unset LD_PRELOAD

if ! [ -f "/opt/config/mod_data/config.tar" ]; then
    if [ ${ZLANG} != 'ru' ]; then
        echo "Для восстановления конфига скопировать в 'Конфигурация' -> 'mod_data' -> config.tar и вызвать RESTORE_TAR_CONFIG"
    else
        echo "To restore the config, copy to 'Configuration' -> 'mod_data' -> config.tar and call RESTORE_TAR_CONFIG"
    fi
else
    tar -xvf /opt/config/mod_data/config.tar -C /
    /opt/config/mod/.shell/zclear.sh
    echo REBOOT >/tmp/printer
fi
