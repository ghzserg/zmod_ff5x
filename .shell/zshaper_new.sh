#!/bin/sh

source /opt/config/mod/.shell/0.sh

unset LD_PRELOAD

if [ "$1" == "SCV" ]; then
    echo "$2" >/opt/config/mod_data/scv.txt
    exit 0
fi

if [ -f /ZMOD ]; then
    /opt/config/mod/.shell/root/zshaper_new.sh $@
else
    if [ ${FF5X} -eq 0 ]; then
        while umount ${UMOUNT_MOD} 2>/dev/null; do a=b; done
        chroot ${MOD} /opt/config/mod/.shell/root/zshaper_new.sh $@
        mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
    else
        export PATH=$PATH:/usr/prog/Python-3.8.2/bin
        export LD_LIBRARY_PATH=/usr/prog/Python-3.8.2/lib:$LD_LIBRARY_PATH
        export LD_LIBRARY_PATH=/usr/prog/openssl-1.0.2d/lib:$LD_LIBRARY_PATH
        export LD_LIBRARY_PATH=/usr/prog/libffi-3.4.4/lib:$LD_LIBRARY_PATH
        /opt/config/mod/.shell/root/zshaper_new.sh $@ --json

        unset LD_LIBRARY_PATH
        export PATH='/bin:/sbin:/usr/bin:/usr/sbin'
        chroot ${MOD} /opt/config/mod/.shell/root/zshaper_new.sh $@ --json-in
    fi
fi
