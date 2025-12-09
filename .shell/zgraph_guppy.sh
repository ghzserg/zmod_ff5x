#!/bin/sh

source /opt/config/mod/.shell/0.sh

unset LD_PRELOAD

if [ -f /ZMOD ]; then
    /opt/config/mod/.shell/root/zshaper/graph_belts.py $@
else
    NEED_MOUNT=0
    [ ${FF5X} -eq 0 ] && umount ${UMOUNT_MOD} && NEED_MOUNT=1
    chroot ${MOD} /opt/config/mod/.shell/root/zshaper/graph_belts.py $@
    [ ${NEED_MOUNT} -eq 1 ] && mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
fi
