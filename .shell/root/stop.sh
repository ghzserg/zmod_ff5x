#!/bin/sh

/opt/config/mod/.shell/root/S70httpd stop
if grep -q "guppy = 1" /opt/config/mod_data/variables.cfg; then
    /opt/config/mod/.shell/root/S80guppyscreen stop
fi
/opt/config/mod/.shell/root/S65moonraker stop
if grep -q "klipper13 = 1" /opt/config/mod_data/variables.cfg; then
    /opt/config/mod/.shell/root/S60klipper stop
fi
