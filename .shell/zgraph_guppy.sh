#!/bin/sh

source /opt/config/mod/.shell/0.sh

unset LD_PRELOAD

if [ -f /ZMOD ]; then
    /opt/config/mod/.shell/root/zshaper/graph_belts.py $@
else
    chroot ${MOD} /opt/config/mod/.shell/root/zshaper/graph_belts.py $@
fi
