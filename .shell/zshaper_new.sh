#!/bin/sh

source /opt/config/mod/.shell/0.sh

unset LD_PRELOAD

if ! [ -f /THIS_IS_NOT_YOUR_ROOT_FILESYSTEM ]; then
    /opt/config/mod/.shell/root/zshaper_new.sh $@
else
    while umount ${UMOUNT_MOD} 2>/dev/null; do a=b; done
    chroot ${MOD} /opt/config/mod/.shell/root/zshaper_new.sh $@
    mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
fi
