#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod

source /opt/config/mod/.shell/0.sh

/opt/config/mod/.shell/root/S70httpd stop
if grep -q "guppy = 1" /opt/config/mod_data/variables.cfg; then
    /opt/config/mod/.shell/root/S80guppyscreen stop
fi
/opt/config/mod/.shell/root/S65moonraker stop
if [ ${AD5X} -eq 0 ]; then
    if grep -q "klipper13 = 1" /opt/config/mod_data/variables.cfg; then
        /opt/config/mod/.shell/root/S60klipper stop
    fi
fi
