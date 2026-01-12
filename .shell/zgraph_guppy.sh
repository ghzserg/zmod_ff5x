#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod

source /opt/config/mod/.shell/0.sh

unset LD_PRELOAD

if [ -f /ZMOD ]; then
    /opt/config/mod/.shell/root/zshaper/graph_belts.py $@
else
    chroot ${MOD} /opt/config/mod/.shell/root/zshaper/graph_belts.py $@
fi
