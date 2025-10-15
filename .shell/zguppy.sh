#!/bin/sh

source /opt/config/mod/.shell/0.sh

unset LD_PRELOAD

up()
{
    echo '/opt/config/mod/.shell/automount.sh' > /proc/sys/kernel/hotplug
    if [ -f /ZMOD ]; then
        /etc/init.d/S80guppyscreen start
    else
        [ ${FF5X} -eq 0 ] && umount ${UMOUNT_MOD}
        chroot ${MOD} /etc/init.d/S80guppyscreen start &
        sleep 15
        [ ${FF5X} -eq 0 ] && mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
    fi
    echo '/opt/config/mod/.shell/automount.sh' > /proc/sys/kernel/hotplug
}

stop()
{
    if [ -f /ZMOD ]; then
        /etc/init.d/S80guppyscreen stop
    else
        [ ${FF5X} -eq 0 ] && umount ${UMOUNT_MOD}
        chroot ${MOD} /etc/init.d/S80guppyscreen stop &
        sleep 15
        [ ${FF5X} -eq 0 ] && mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
    fi
}

case "$1" in
    up)
        up
        ;;
    stop)
        stop
        ;;
    *)
        echo "Usage: $0 {stop|up}"
        exit 1
esac
sync
echo 3 > /proc/sys/vm/drop_caches
exit $?
