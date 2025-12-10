#!/bin/sh

# Загружаем конфигурацию
if [ -f /opt/config/mod/.shell/0.sh ]; then
    . /opt/config/mod/.shell/0.sh
elif [ -f /usr/data/config/mod/.shell/0.sh ]; then
    . /usr/data/config/mod/.shell/0.sh
fi

# Проверяем, нужно ли запускать скрипт
if ! grep -q '^\[include ./mod/display_off\.cfg\]' "${MOD_CONF}/printer.cfg"; then
    exit 0
fi

# Работаем только с блочными устройствами (sda, sda1 и т.д.)
if [ "$SUBSYSTEM" != "block" ]; then
    exit 0
fi

case "$DEVNAME" in
    sd[a-z][0-9]* | sd[a-z])
        ;;
    *)
        exit 0
        ;;
esac

flash="${DATA_GCODES}/flash"
mkdir -p "$flash"

if [ "$ACTION" = "add" ]; then
    # Проверяем, что устройство существует и не смонтировано
    if [ -b "/dev/$DEVNAME" ] && ! grep -q "/dev/$DEVNAME" /proc/mounts; then
        mount_point="${flash}/${DEVNAME}"
        mkdir -p "$mount_point"

        # Обычное монтирование
        if ! mount -t vfat -o rw,relatime,fmask=0022,dmask=0022,codepage=936,iocharset=utf8,shortname=mixed,utf8,errors=remount-ro "/dev/$DEVNAME" "$mount_point"; then
            # Если монтирование не удалось — удаляем папку
            rmdir "$mount_point" 2>/dev/null || rm -rf "$mount_point"
            exit 1
        fi

        target="${MOD}${DATA_GCODES}/flash/${DEVNAME}"
        mkdir -p "$target"
        if ! mount --bind "$mount_point" "$target"; then
            # Если биндинг не удался — отмонтируем основное и удалим папки
            umount "$mount_point"
            rmdir "$mount_point" 2>/dev/null || rm -rf "$mount_point"
            rmdir "$target" 2>/dev/null || rm -rf "$target"
            exit 1
        fi
    fi
elif [ "$ACTION" = "remove" ]; then
    mount_point="${flash}/${DEVNAME}"

    if mountpoint -q "$mount_point" && grep -q " ${mount_point} " /proc/mounts; then
        target="${MOD}${DATA_GCODES}/flash/${DEVNAME}"
        if mountpoint -q "$target" && grep -q " ${target} " /proc/mounts; then
            umount "$target"
        fi
        rm -rf "$target"

        # Размонтируем основное
        umount "$mount_point"

        # Удаляем папки
        rm -rf "$mount_point"
    fi

    # Удаляем пустые папки
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
