#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod

up()
{
    if ! [ -f /ZMOD ]; then
        /opt/config/mod/.shell/S99moon up
    else
        /etc/init.d/S65moonraker start
        /etc/init.d/S70httpd start
    fi
}

stop()
{
    if ! [ -f /ZMOD ]; then
        /opt/config/mod/.shell/S99moon stop
    else
        /etc/init.d/S65moonraker stop
        /etc/init.d/S70httpd stop
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
