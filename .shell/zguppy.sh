#!/bin/sh

source /opt/config/mod/.shell/0.sh

unset LD_PRELOAD

up()
{
    umount /media 2>/dev/null
    echo '/opt/config/mod/.shell/automount.sh' > /proc/sys/kernel/hotplug
    if [ -f /ZMOD ]; then
        /etc/init.d/S80guppyscreen start
    else
        NEED_MOUNT=0
        [ ${FF5X} -eq 0 ] && umount ${UMOUNT_MOD} && NEED_MOUNT=1
        chroot ${MOD} /etc/init.d/S80guppyscreen start &
        sleep 15
        [ ${NEED_MOUNT} -eq 1 ] && mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
    fi
    echo '/opt/config/mod/.shell/automount.sh' > /proc/sys/kernel/hotplug
    umount /media 2>/dev/null
}

stop()
{
    if [ -f /ZMOD ]; then
        /etc/init.d/S80guppyscreen stop
    else
        NEED_MOUNT=0
        [ ${FF5X} -eq 0 ] && umount ${UMOUNT_MOD} && NEED_MOUNT=1
        chroot ${MOD} /etc/init.d/S80guppyscreen stop &
        sleep 15
        [ ${NEED_MOUNT} -eq 1 ] && mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
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
