#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod

source /opt/config/mod/.shell/0.sh

up()
{
    if ! [ -f /ZMOD ]; then
        #/opt/config/mod/.shell/S99moon up
        chroot ${MOD} /etc/init.d/S65moonraker start
        chroot ${MOD} /etc/init.d/S70httpd start
        chroot ${MOD} /etc/init.d/S80guppyscreen start
    else
        /etc/init.d/S65moonraker start
        /etc/init.d/S70httpd start
        /etc/init.d/S80guppyscreen start
    fi
}

stop()
{
    if ! [ -f /ZMOD ]; then
        #/opt/config/mod/.shell/S99moon stop
        chroot ${MOD} /etc/init.d/S65moonraker stop
        chroot ${MOD} /etc/init.d/S70httpd stop
        chroot ${MOD} /etc/init.d/S80guppyscreen stop
    else
        /etc/init.d/S65moonraker stop
        /etc/init.d/S70httpd stop
        /etc/init.d/S80guppyscreen stop
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
