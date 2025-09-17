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

wifi_fix()
{
    if [ ! -f "$FFCONFIG" ]; then
        echo "Config file not found: $FFCONFIG"
        return 0
    fi

    if ! grep -q '"wifiStationStatus" *: *true' "$FFCONFIG"; then
        echo "WiFi station disabled — skipping network restart."
        return 0
    fi

    echo "WiFi station enabled — restarting network..."

    killall wpa_supplicant 2>/dev/null || true
    killall wpa_cli        2>/dev/null || true
    killall udhcpc         2>/dev/null || true

    echo "wpa_supplicant"
    wpa_supplicant -d -Dnl80211 -iwlan0 -c${WPA_CONFIG} -B
    echo "/usr/bin/wpa_cli"
    start-stop-daemon --start --background --exec /usr/bin/wpa_cli -- -i wlan0 -a ${MOD_CONF}/mod/.shell/wifi.sh
    echo "Wi-Fi restart initiated. DHCP will start automatically on connection."
}

remove_base()
{
    rm -rf ${UMOUNT_MOD}

    [ -f ${MOD_CONF}/mod/FULL_REMOVE ] && rm -rf ${MOD_CONF}/mod_data/
    sync

    if [ ${FF5X} -eq 0 ]; then
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
        rm -f /etc/init.d/prepare.sh
    else
        rm -f /usr/data/zmod_install.log
        sed -i '/fix_config.sh/d' /usr/prog/app_startup.sh
        sed -i '/prepare.sh/d' /usr/prog/app_startup.sh
    fi
    sync

    rm -f ${LOG_FILES}/zmod
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
    [ ${FF5X} -eq 1 ] && VER=$(find /usr/prog/PROGRAM/software/ -type d | sed 's|/usr/prog/PROGRAM/software/||' | grep .)

    # Запуск камеры
    [ ${FF5X} -eq 0 ] && ${MOD_CONF}/mod/.shell/S99camera init

    chroot ${MOD} /opt/config/mod/.shell/root/start.sh "$SWAP" "$VER" "$MACHINE" &

    [ ${FF5X} -eq 0 ] && mkdir -p ${REMOUNT_MOD}
    sleep 10
    [ ${FF5X} -eq 0 ] && mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
    mount
    ps w
    sleep 30
    echo "Start User power_on script"
    [ -f ${MOD_CONF}/mod_data/power_on.sh ] && ${MOD_CONF}/mod_data/power_on.sh
    echo "End User power_on script"
    #sleep 60
    #umount ${KLIPPER_DIR}/start.sh
}

start_prepare()
{
    if [ ${FF5X} -eq 0 ] && ! [ -L /etc/init.d/S00fix ]; then ln -s ${MOD_CONF}/mod/.shell/fix_config.sh /etc/init.d/S00fix; fi
    echo "System start" >${MOD_CONF}/mod_data/log/ssh.log

    mount -t proc /proc ${MOD}/proc
    mount --rbind /sys ${MOD}/sys
    mount --rbind /dev ${MOD}/dev
    mount --bind /tmp ${MOD}/tmp
    mount --bind /run ${MOD}/run

    mkdir -p ${MOD}/opt/config
    mount --bind ${MOD_CONF} ${MOD}/opt/config

    if [ ${FF5X} -eq 1 ]; then
        mkdir -p ${MOD}${MOD_CONF} ${MOD}/usr/prog/config
        mount --bind ${MOD_CONF} ${MOD}${MOD_CONF}
        mount --bind ${MOD}/opt/ /opt
        mount --bind ${MOD_CONF} /opt/config/
        [ -d /usr/prog/config ] && mount --bind /usr/prog/config ${MOD}/usr/prog/config
        mkdir -p ${MOD_CONF}/mod_data/
        mount --bind ${MOD_CONF}/mod_data/ /root

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

    [ ${FF5X} -eq 0 ] && cat /etc/localtime >/tmp/localtime
    cp ${TS_LIB}/pointercal /tmp/pointercal
    cp ${TS_LIB}/ts.conf /tmp/ts.conf

    mv ${MOD_CONF}/mod_data/log/wifi.4.log ${MOD_CONF}/mod_data/log/wifi.5.log
    mv ${MOD_CONF}/mod_data/log/wifi.3.log ${MOD_CONF}/mod_data/log/wifi.4.log
    mv ${MOD_CONF}/mod_data/log/wifi.2.log ${MOD_CONF}/mod_data/log/wifi.3.log
    mv ${MOD_CONF}/mod_data/log/wifi.1.log ${MOD_CONF}/mod_data/log/wifi.2.log
    mv ${MOD_CONF}/mod_data/log/wifi.log ${MOD_CONF}/mod_data/log/wifi.1.log
    wifi_fix &>${MOD_CONF}/mod_data/log/wifi.log

    start_moon
}

if [ -f ${MOD_CONF}/mod/SKIP_ZMOD ]; then
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
