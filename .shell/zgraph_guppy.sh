#!/bin/sh

source /opt/config/mod/.shell/0.sh

unset LD_PRELOAD

if ! [ -f /THIS_IS_NOT_YOUR_ROOT_FILESYSTEM ]; then
    /opt/config/mod/.shell/root/zshaper/graph_belts.py $@
else
    umount ${UMOUNT_MOD}
    chroot $MOD /opt/config/mod/.shell/root/zshaper/graph_belts.py $@
    mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
fi
