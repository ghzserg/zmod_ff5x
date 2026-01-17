#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod

source /opt/config/mod/.shell/0.sh

up()
{
    if ! [ -f /ZMOD ]; then
        #/opt/config/mod/.shell/S99moon up
        [ "$1" -eq 1 ] && chroot ${MOD} /etc/init.d/S80guppyscreen start
        [ "$2" -eq 1 ] && chroot ${MOD} /etc/init.d/S65moonraker start
        [ "$3" -eq 1 ] && chroot ${MOD} /etc/init.d/S70httpd start
    else
        [ "$1" -eq 1 ] && /etc/init.d/S80guppyscreen start
        [ "$2" -eq 1 ] && /etc/init.d/S65moonraker start
        [ "$3" -eq 1 ] && /etc/init.d/S70httpd start
    fi
}

stop()
{
    if ! [ -f /ZMOD ]; then
        #/opt/config/mod/.shell/S99moon stop
        [ "$1" -eq 1 ] && chroot ${MOD} /etc/init.d/S80guppyscreen stop
        [ "$2" -eq 1 ] && chroot ${MOD} /etc/init.d/S65moonraker stop
        [ "$3" -eq 1 ] && chroot ${MOD} /etc/init.d/S70httpd stop
    else
        [ "$1" -eq 1 ] && /etc/init.d/S80guppyscreen stop
        [ "$2" -eq 1 ] && /etc/init.d/S65moonraker stop
        [ "$3" -eq 1 ] && /etc/init.d/S70httpd stop
    fi
}

case "$1" in
    up)
        up "$2" "$3" "$4"
        ;;
    stop)
        stop "$2" "$3" "$4"
        ;;
    *)
        echo "Usage: $0 {stop|up}"
        exit 1
esac
sync
echo 3 > /proc/sys/vm/drop_caches
exit $?
