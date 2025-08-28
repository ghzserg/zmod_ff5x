#!/bin/sh
# Author:		chenhe
# Date:			2022-01-21

set -x

WORK_DIR=$(pwd)

CHECH_ARCH=`uname -m`
if [ "${CHECH_ARCH}" == "armv7l" ]; then
    CONFIG_DIR="/opt/config"
    EBOARD_TTY="/dev/ttyS1"
else if [ "${CHECH_ARCH}" == "mips" ]; then
    export PATH=/bin:/sbin:/usr/bin:/usr/sbin
    CONFIG_DIR="/usr/data/config"
    EBOARD_TTY="/dev/ttyS5"
else
    echo "Machine architecture error."
    echo ${CHECH_ARCH}
    exit 1
fi
fi

FIRMWARE_Head_M3="${CONFIG_DIR}/mod/.shell/root/mcu/Eboard.hex"
FIRMWARE_Board_M3="${CONFIG_DIR}/mod/.shell/root/mcu/Mainboard.bin"

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

update_mainboard()
{
    mv ${CONFIG_DIR}/mod_data/log/update_mcu_mainboard.4.log ${CONFIG_DIR}/mod_data/log/update_mcu_mainboard.5.log
    mv ${CONFIG_DIR}/mod_data/log/update_mcu_mainboard.3.log ${CONFIG_DIR}/mod_data/log/update_mcu_mainboard.4.log
    mv ${CONFIG_DIR}/mod_data/log/update_mcu_mainboard.2.log ${CONFIG_DIR}/mod_data/log/update_mcu_mainboard.3.log
    mv ${CONFIG_DIR}/mod_data/log/update_mcu_mainboard.1.log ${CONFIG_DIR}/mod_data/log/update_mcu_mainboard.2.log
    mv ${CONFIG_DIR}/mod_data/log/update_mcu_mainboard.log ${CONFIG_DIR}/mod_data/log/update_mcu_mainboard.1.log

    update_mcu_mainboard &>${CONFIG_DIR}/mod_data/log/update_mcu_mainboard.log
}

update_mcu_eboard()
{
    if [ -f $WORK_DIR/IAPCommand ];then
	chmod a+x $WORK_DIR/IAPCommand
	if [ -f $FIRMWARE_Head_M3 ];then
		echo "burn M3 firmware..."
		$WORK_DIR/IAPCommand $FIRMWARE_Head_M3 $EBOARD_TTY
		sync
	fi
    fi
}

update_eboard()
{
    mv ${CONFIG_DIR}/mod_data/log/update_mcu_eboard.4.log ${CONFIG_DIR}/mod_data/log/update_mcu_eboard.5.log
    mv ${CONFIG_DIR}/mod_data/log/update_mcu_eboard.3.log ${CONFIG_DIR}/mod_data/log/update_mcu_eboard.4.log
    mv ${CONFIG_DIR}/mod_data/log/update_mcu_eboard.2.log ${CONFIG_DIR}/mod_data/log/update_mcu_eboard.3.log
    mv ${CONFIG_DIR}/mod_data/log/update_mcu_eboard.1.log ${CONFIG_DIR}/mod_data/log/update_mcu_eboard.2.log
    mv ${CONFIG_DIR}/mod_data/log/update_mcu_eboard.log ${CONFIG_DIR}/mod_data/log/update_mcu_eboard.1.log

    update_mcu_eboard &>${CONFIG_DIR}/mod_data/log/update_mcu_eboard.log
}

update_mcu_ifs()
{
    if [ -f $WORK_DIR/IFSCommand ]; then
        echo "update ifs"
        cp -f $WORK_DIR/IFSCommand  /usr/prog/PROGRAM/control/
        cp -f $WORK_DIR/ifs.hex  /usr/prog/PROGRAM/control/
        chmod a+x $WORK_DIR/ifsF37
        $WORK_DIR/ifsF37 /dev/ttyS4
        $WORK_DIR/IFSCommand $WORK_DIR/ifs.hex /dev/ttyS4
    fi
}

update_ifs()
{
    mv ${CONFIG_DIR}/mod_data/log/update_mcu_ifs.4.log ${CONFIG_DIR}/mod_data/log/update_mcu_ifs.5.log
    mv ${CONFIG_DIR}/mod_data/log/update_mcu_ifs.3.log ${CONFIG_DIR}/mod_data/log/update_mcu_ifs.4.log
    mv ${CONFIG_DIR}/mod_data/log/update_mcu_ifs.2.log ${CONFIG_DIR}/mod_data/log/update_mcu_ifs.3.log
    mv ${CONFIG_DIR}/mod_data/log/update_mcu_ifs.1.log ${CONFIG_DIR}/mod_data/log/update_mcu_ifs.2.log
    mv ${CONFIG_DIR}/mod_data/log/update_mcu_ifs.log ${CONFIG_DIR}/mod_data/log/update_mcu_ifs.1.log

    update_mcu_ifs &>${CONFIG_DIR}/mod_data/log/update_mcu_ifs.log
}

killall python3.7 firmwareExe
kill $(ps|grep klippy.py| grep -v grep| awk '{print $1}')
kill $(ps|grep klippy.py| grep -v grep| awk '{print $1}')

mkdir -p ${CONFIG_DIR}/mod_data/log/

if [ "$1" == "mainboard" ]; then
    if [ "${CHECH_ARCH}" == "armv7l" ]; then
        update_mainboard
    fi
    ${CONFIG_DIR}/mod/.shell/root/audio/audio_midi.sh For_Elise.mid
    sync
    sleep 5
    poweroff
else
    if [ "${CHECH_ARCH}" == "mips" ]; then
        update_ifs
        update_mainboard
    fi

    update_eboard
    ${CONFIG_DIR}/mod/.shell/root/audio/audio_midi.sh For_Elise.mid
    sync
fi

sync
exit 0
