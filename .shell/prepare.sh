#!/bin/sh

set -x

source /opt/config/mod/.shell/0.sh

remove_base()
{
    rm -rf ${UMOUNT_MOD}
    rm /etc/init.d/S00fix
    rm /etc/init.d/S99moon
    rm /etc/init.d/S98camera
    rm /etc/init.d/S99camera
    rm /etc/init.d/S98zssh
    rm /etc/init.d/K99moon
    # REMOVE SCRIPTS
    rm -rf /root/printer_data/scripts
    # REMOVE ENTWARE
    rm -rf /opt/bin
    rm -rf /opt/etc
    rm -rf /opt/home
    rm -rf /opt/lib
    rm -rf /opt/libexec
    rm -rf /opt/root
    rm -rf /opt/sbin
    rm -rf /opt/share
    rm -rf /opt/tmp
    rm -rf /opt/usr
    rm -rf /opt/var
    # Remove ROOT
    rm -rf /etc/init.d/S50sshd /etc/init.d/S55date /bin/dropbearmulti /bin/dropbear /bin/dropbearkey /bin/scp /etc/dropbear /etc/init.d/S60dropbear
    # Remove BEEP
    rm -f /usr/bin/audio.py /usr/bin/audio /usr/lib/python3.7/site-packages/audio.py /usr/bin/audio_midi.sh ${KLIPPER_DIR}/klippy/extras/gcode_shell_command.py
    rm -rf /usr/lib/python3.7/site-packages/mido/
    sync

    [ -f ${MOD_CONF}/mod/FULL_REMOVE ] && rm -rf ${MOD_CONF}/mod_data/
    sync

    rm -f /etc/init.d/prepare.sh
    sync
    rm -rf ${MOD_CONF}/mod/
    sync
    reboot
    exit
}

start_moon()
{
    SWAP="/root/swap"
    if grep -q "use_swap = 2" ${MOD_CONF}/mod_data/variables.cfg && [ ${FF5X} -eq 0 ]; then
        for i in `seq 1 6`; do mount |grep /media && break; echo $i; sleep 10; done;

        if mount |grep /media; then
            FREE_SPACE=$(df /media 2>/dev/null|grep -v /dev/root|grep -v Filesystem| tail -1 | tr -s ' ' | cut -d' ' -f4)
            MIN_SPACE=$((128*1024))
            mount
            df /media

            if [ "$FREE_SPACE" != "" ] && [ "$FREE_SPACE" -ge "$MIN_SPACE" ]; then
                SWAP="/media/swap"
                if ! [ -f $SWAP ]; then dd if=/dev/zero of=$SWAP bs=1024 count=131072; mkswap $SWAP; fi;
                swapon $SWAP
            fi
        fi
    fi

    MACHINE="Неизвестная машина"
    grep -q '^MACHINE=Adventurer5MPro$' /opt/auto_run.sh && MACHINE=Adventurer5MPro
    grep -q '^MACHINE=Adventurer5M$' /opt/auto_run.sh && MACHINE=Adventurer5M
    grep -q "^MACHINE=AD5X" /usr/prog/app_startup.sh && MACHINE=AD5X
    [ ${FF5X} -eq 0 ] && VER=$(cat /root/version)
    [ ${FF5X} -eq 1 ] && VER=$(cat ${MOD}/root/printer_data/version.txt)
    chroot ${MOD} /opt/config/mod/.shell/root/start.sh "$SWAP" "$VER" "$MACHINE" &

    [ ${FF5X} -eq 0 ] && mkdir -p ${REMOUNT_MOD}
    sleep 10
    [ ${FF5X} -eq 0 ] && mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
    mount
    ps
    #sleep 60
    #umount ${KLIPPER_DIR}/start.sh
}

start_prepare()
{
    ${MOD_CONF}/mod/.shell/znice.sh

    if [ ${FF5X} -eq 0 ] && ! [ -L /etc/init.d/S00fix ]; then ln -s ${MOD_CONF}/mod/.shell/fix_config.sh /etc/init.d/S00fix; fi
    echo "System start" >${MOD_CONF}/mod_data/log/ssh.log

    mount -t proc /proc ${MOD}/proc
    mount --rbind /sys ${MOD}/sys
    mount --rbind /dev ${MOD}/dev
    mount --bind /tmp ${MOD}/tmp
    mount --bind /run ${MOD}/run

    mkdir -p ${MOD}/opt/config
    mount --bind ${MOD_CONF} ${MOD}/opt/config

    if [ ${FF5X} -eq 1 ]
        mkdir -p ${MOD}${MOD_CONF}/config/
        mount --bind ${MOD_CONF}/config/ ${MOD}${MOD_CONF}/config/
        mount --bind ${MOD}/opt/ /opt
        mount --bind /usr/data/config/ /opt/config/

        mkdir -p ${MOD}${LOG_FILES}
        mount --bind ${LOG_FILES}/ ${MOD}${LOG_FILES}/
    else
        mkdir -p ${MOD}/opt/PROGRAM/
        mount --bind /opt/PROGRAM/ ${MOD}/opt/PROGRAM/
    fi

    mkdir -p ${MOD}${KLIPPER_DIR}
    mount --bind ${KLIPPER_DIR}/ ${MOD}${KLIPPER_DIR}/

    mkdir -p ${MOD}${DATA_GCODES}
    mount --bind ${DATA_GCODES} ${MOD}${DATA_GCODES}

    mkdir -p ${MOD}/root/printer_data/misc
    mkdir -p ${MOD}/root/printer_data/tmp
    mkdir -p ${MOD}/root/printer_data/comms
    mkdir -p ${MOD}/root/printer_data/certs


#    if  ! [ -d ${MOD}/opt/klipper/docs ]
#     then
#        mkdir -p ${MOD}/opt/klipper/docs
#        cp ${KLIPPER_DIR}/docs/* ${MOD}/opt/klipper/docs
#    fi
#
#    if ! [ -d ${MOD}/opt/klipper/config ]
#     then
#        mkdir -p ${MOD}/opt/klipper/config
#        cp ${KLIPPER_DIR}/config/* ${MOD}/opt/klipper/config
#    fi

    [ ${FF5X} -eq 0 ] && cat /etc/localtime >/tmp/localtime
    cp ${TS_LIB}/pointercal /tmp/pointercal
    cp ${TS_LIB}/ts.conf /tmp/ts.conf

    # Запуск камеры
    [ ${FF5X} -eq 0 ] && /etc/init.d/S99camera init

    start_moon
}

if [ -f ${MOD_CONF}/mod/SKIP_ZMOD ]
 then
    rm -f ${MOD_CONF}/mod/SKIP_ZMOD
    [ ${FF5X} -eq 0 ] && mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
    exit 0
fi

if [ -f ${MOD_CONF}/mod/REMOVE ] || [ -f ${MOD_CONF}/mod/FULL_REMOVE ]; then
  remove_base
  exit 0
fi

while ! mount |grep /dev/mmcblk0p7; do sleep 10; done

mv ${MOD_CONF}/mod_data/log/zmod.4.log ${MOD_CONF}/mod_data/log/zmod.5.log
mv ${MOD_CONF}/mod_data/log/zmod.3.log ${MOD_CONF}/mod_data/log/zmod.4.log
mv ${MOD_CONF}/mod_data/log/zmod.2.log ${MOD_CONF}/mod_data/log/zmod.3.log
mv ${MOD_CONF}/mod_data/log/zmod.1.log ${MOD_CONF}/mod_data/log/zmod.2.log
mv ${MOD_CONF}/mod_data/log/zmod.log ${MOD_CONF}/mod_data/log/zmod.1.log
start_prepare &>${MOD_CONF}/mod_data/log/zmod.log
