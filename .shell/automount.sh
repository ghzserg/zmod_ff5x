#!/bin/sh

# Загружаем конфигурацию
if [ -f /opt/config/mod/.shell/0.sh ]; then
    . /opt/config/mod/.shell/0.sh
elif [ -f /usr/data/config/mod/.shell/0.sh ]; then
    . /usr/data/config/mod/.shell/0.sh
fi

# Проверяем, есть ли строка '[include ./mod/display_off.cfg]' в PRINTER_CFG
if ! grep -q '^\[include ./mod/display_off\.cfg\]' "${PRINTER_CFG}"; then
    exit 0
fi

# Устанавливаем переменную flash
flash="${DATA_GCODES}/flash"

# Создаём папку, если её нет
mkdir -p "$flash"

# Проверка, существует ли устройство или папка
if [ ! -b "/dev/${MDEV}" ]; then
    if [ ! -d "${flash}/${MDEV}" ]; then
        exit 0
    fi
fi

# Флаг: 0 = нет, 1 = да (устройство нужно обработать)
need_mount=0

# Если ACTION=add
if [ "${ACTION}" = "add" ]; then
    if [ "${DEVTYPE}" = "partition" ]; then
        need_mount=1
    elif [ "${DEVTYPE}" = "disk" ]; then
        # Проверяем, есть ли "FAT" в заголовке диска (обычно флешки)
        if dd if="/dev/${MDEV}" bs=512 count=1 2>/dev/null | grep -q "FAT"; then
            need_mount=1
        fi
    fi
fi

# Если ACTION=remove
if [ "${ACTION}" = "remove" ]; then
    if [ "${DEVTYPE}" = "partition" ] || [ "${DEVTYPE}" = "disk" ]; then
        if grep -q "^/dev/${MDEV} ${flash}/" /proc/mounts; then
            need_mount=1
        fi
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

# Если не нужно обрабатывать — выходим
if [ ${need_mount} -ne 1 ]; then
    exit 0
fi

# ACTION=add → монтируем
if [ "${ACTION}" = "add" ]; then
    mkdir -p "${flash}/${MDEV}"
    mount -t vfat -o rw,relatime,fmask=0022,dmask=0022,codepage=936,iocharset=utf8,shortname=mixed,utf8,errors=remount-ro "/dev/${MDEV}" "${flash}/${MDEV}"

# ACTION=remove → размонтируем
elif [ "${ACTION}" = "remove" ]; then
    procmounts=$(grep "^/dev/${MDEV} ${flash}/" /proc/mounts)
    if [ -n "$procmounts" ]; then
        # Извлекаем точку монтирования
        mount_point=$(echo "$procmounts" | awk '{print $2}')
        if [ -n "$mount_point" ]; then
            umount "$mount_point"
            rm -rf "$mount_point"
        fi
    fi
fi
