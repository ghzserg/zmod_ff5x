#!/bin/sh

set -x

if [ -f /opt/config/mod/.shell/0.sh ]; then
    . /opt/config/mod/.shell/0.sh
elif [ -f /usr/data/config/mod/.shell/0.sh ]; then
    . /usr/data/config/mod/.shell/0.sh
fi

# Проверяем, есть ли строка '[include ./mod/display_off.cfg]' в файле ${MOD_CONF}/printer.cfg
if ! grep -q '^\[include ./mod/display_off\.cfg\]' "${MOD_CONF}/printer.cfg"; then
    exit 0
fi

do_hotplug() {
    flash="${DATA_GCODES}/flash"
    mkdir -p "$flash"

    # Проверяем, что это блочное устройство
    if [ "$SUBSYSTEM" != "block" ]; then
        exit 0
    fi

    # Проверяем, начинается ли устройство с "sd" и содержит ли цифру (например, sda1)
    case "$DEVNAME" in
        sd[a-z][0-9]* | sd[a-z])
            ;;
        *)
            # Не подходит — выходим
            exit 0
            ;;
    esac

    # Проверяем, что устройство существует
    if [ ! -b "/dev/$DEVNAME" ]; then
        exit 0
    fi

    # ACTION=add → монтируем
    if [ "$ACTION" = "add" ]; then
        # Проверим, не занята ли точка монтирования
        if ! grep -q "/dev/$DEVNAME" /proc/mounts; then
            mkdir -p "${flash}/${DEVNAME}"
            # Монтируем с твоими параметрами
            mount -t vfat -o rw,relatime,fmask=0022,dmask=0022,codepage=936,iocharset=utf8,shortname=mixed,utf8,errors=remount-ro "/dev/$DEVNAME" "${flash}/${DEVNAME}"
        fi

    # ACTION=remove → размонтируем
    elif [ "$ACTION" = "remove" ]; then
        mount_point="${flash}/${DEVNAME}"
        if mountpoint -q "$mount_point" && grep -q "/dev/$DEVNAME" /proc/mounts; then
            umount "$mount_point"
            rm -rf "$mount_point"
        fi

        # Удаляем папки, которые больше не смонтированы
        if [ -d "${flash}" ]; then
            for dir in "${flash}"/*; do
                if [ -d "$dir" ]; then
                    dirname=$(basename "$dir")
                    if ! grep -q " ${flash}/${dirname} " /proc/mounts; then
                        rm -rf "$dir"
                    fi
                fi
            done
        fi
    fi
}

# Запускаем функцию и перенаправляем весь вывод в лог
do_hotplug &>${MOD_CONF}/mod_data/log/automount.log
