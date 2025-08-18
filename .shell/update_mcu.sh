#!/bin/sh
# Author:		chenhe
# Date:			2022-01-21

set -x

WORK_DIR=$(pwd)

export PATH=/bin:/sbin:/usr/bin:/usr/sbin

FIRMWARE_Board_M3=/opt/config/mod/.shell/root/mcu/Mainboard.bin
FIRMWARE_Head_M3=/opt/config/mod/.shell/root/mcu/Eboard.hex

CHECH_ARCH=`uname -m`
if [ "${CHECH_ARCH}" != "armv7l" ];then
    echo "Machine architecture error."
    echo ${CHECH_ARCH}
    exit 1
fi

cat $WORK_DIR/mcu.img > /dev/fb0

update_mcu_mainboard()
{
    if [ -f $WORK_DIR/NationsCommand ];then
	chmod a+x $WORK_DIR/NationsCommand
	if [ -f $FIRMWARE_Board_M3 ];then
		echo "burn M3 firmware..."
		$WORK_DIR/NationsCommand -c -d --fn $FIRMWARE_Board_M3 --v -r
	fi
    fi

}

update_mcu_eboard()
{
    if [ -f $WORK_DIR/IAPCommand ];then
	chmod a+x $WORK_DIR/IAPCommand
	if [ -f $FIRMWARE_Head_M3 ];then
		echo "burn M3 firmware..."
		$WORK_DIR/IAPCommand $FIRMWARE_Head_M3 /dev/ttyS1
		sync
	fi
    fi
}

killall python3.7 firmwareExe
kill $(ps|grep klippy.py| grep -v grep| awk '{print $1}')

mkdir -p /opt/config/mod_data/log/

if [ "$1" == "mainboard" ]; then
    mv /opt/config/mod_data/log/update_mcu_mainboard.4.log /opt/config/mod_data/log/update_mcu_mainboard.5.log
    mv /opt/config/mod_data/log/update_mcu_mainboard.3.log /opt/config/mod_data/log/update_mcu_mainboard.4.log
    mv /opt/config/mod_data/log/update_mcu_mainboard.2.log /opt/config/mod_data/log/update_mcu_mainboard.3.log
    mv /opt/config/mod_data/log/update_mcu_mainboard.1.log /opt/config/mod_data/log/update_mcu_mainboard.2.log
    mv /opt/config/mod_data/log/update_mcu_mainboard.log /opt/config/mod_data/log/update_mcu_mainboard.1.log

    update_mcu_mainboard &>/opt/config/mod_data/log/update_mcu_mainboard.log
    /opt/config/mod/.shell/root/audio/audio_midi.sh For_Elise.mid
    sync
    sleep 5
    poweroff
else
    mv /opt/config/mod_data/log/update_mcu_eboard.4.log /opt/config/mod_data/log/update_mcu_eboard.5.log
    mv /opt/config/mod_data/log/update_mcu_eboard.3.log /opt/config/mod_data/log/update_mcu_eboard.4.log
    mv /opt/config/mod_data/log/update_mcu_eboard.2.log /opt/config/mod_data/log/update_mcu_eboard.3.log
    mv /opt/config/mod_data/log/update_mcu_eboard.1.log /opt/config/mod_data/log/update_mcu_eboard.2.log
    mv /opt/config/mod_data/log/update_mcu_eboard.log /opt/config/mod_data/log/update_mcu_eboard.1.log

    update_mcu_eboard &>/opt/config/mod_data/log/update_mcu_eboard.log
    /opt/config/mod/.shell/root/audio/audio_midi.sh For_Elise.mid
    sync
fi

sync
exit 0
