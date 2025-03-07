#!/bin/sh

source /opt/config/mod/.shell/0.sh

unset LD_PRELOAD

up()
{
    if [ -f /THIS_IS_NOT_YOUR_ROOT_FILESYSTEM ]; then
        umount ${UMOUNT_MOD}
        chroot ${MOD} /etc/init.d/S80guppyscreen start &
        sleep 15
        mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
    else
        /etc/init.d/S80guppyscreen up
    fi
}

stop()
{
    if [ -f /THIS_IS_NOT_YOUR_ROOT_FILESYSTEM ]; then
        umount ${UMOUNT_MOD}
        chroot ${MOD} /etc/init.d/S80guppyscreen stop &
        sleep 15
        mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
    else
        /etc/init.d/S80guppyscreen stop
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
