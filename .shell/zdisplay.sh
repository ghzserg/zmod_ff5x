#!/bin/sh

if ! [ $# -eq 1 ]; then echo "Use $0 on|off|test"; exit 1; fi

if [ $1 = "test" ] && grep -q display_off.cfg /opt/config/printer.cfg; then
    killall firmwareExe
    grep -q "guppy = 1" /opt/config/mod_data/variables.cfg && /opt/config/mod/.shell/zguppy.sh up || xzcat /opt/config/mod/.shell/screen_off.raw.xz > /dev/fb0
    echo '/opt/config/mod/.shell/automount.sh' > /proc/sys/kernel/hotplug
#    echo /sbin/mdev >/proc/sys/kernel/hotplug
fi

[ $1 = "on" ]   && sed -i 's|\[include ./mod/display_off.cfg\]|\[include ./mod/mod.cfg\]|' /opt/config/printer.cfg && sync && /opt/config/mod/.shell/zremote.sh reboot
[ $1 = "off" ]  && sed -i 's|\[include ./mod/mod.cfg\]|\[include ./mod/display_off.cfg\]|' /opt/config/printer.cfg && sync && killall firmwareExe && xzcat /opt/config/mod/.shell/screen_off.raw.xz > /dev/fb0 #&& echo /sbin/mdev >/proc/sys/kernel/hotplug
[ $1 = "guppy" ]  && sed -i 's|\[include ./mod/mod.cfg\]|\[include ./mod/display_off.cfg\]|' /opt/config/printer.cfg && sync && killall firmwareExe && /opt/config/mod/.shell/zguppy.sh up #&& echo /sbin/mdev >/proc/sys/kernel/hotplug

if [ $1 = "off" ] || [ $1 = "guppy" ]; then
    echo '/opt/config/mod/.shell/automount.sh' > /proc/sys/kernel/hotplug
fi

sync
echo 3 > /proc/sys/vm/drop_caches
