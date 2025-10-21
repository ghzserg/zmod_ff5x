#!/bin/sh

source /opt/config/mod/.shell/0.sh

get_origin_from_config() {
  local config_file="$1"
  local section="[update_manager $2]"

  awk -v section="$section" '
    BEGIN { in_section = 0 }
    /^\[.*\]$/ {
      if ($0 == section) {
        in_section = 1
      } else if (in_section) {
        exit
      }
      next
    }
    in_section && /^origin[[:space:]]*:/ {
      gsub(/^[[:space:]]*origin[[:space:]]*:[[:space:]]*/, "")
      gsub(/[[:space:]]+$/, "")
      print
      exit
    }
  ' "$config_file"
}

if grep -q "[update_manager $1]" ${MOD_CONF}/moonraker.conf || grep -q "[update_manager $1]" ${MOD_CONF}/mod_data/user.moonraker.conf; then
    url=$(get_origin_from_config ${MOD_CONF}/moonraker.conf "$1")
    if [ "$url" == "" ]; then
        url=$(get_origin_from_config ${MOD_CONF}/mod_data/user.moonraker.conf "$1")
    fi
    if [ "$url" != "" ]
        if ! [ -d "${MOD_CONF}/mod_data/plugins/$1" ]; then
            if ! [ -f /ZMOD ]; then
                [ ${FF5X} -eq 0 ] && umount ${UMOUNT_MOD}
                unset LD_LIBRARY_PATH
                unset LD_PRELOAD
                chroot ${MOD} git clone "${url}" "${MOD_CONF}/mod_data/plugins/$1"
                [ ${FF5X} -eq 0 ] && mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
            else
                git clone "${url}" "${MOD_CONF}/mod_data/plugins/$1"
            fi
        else
            if ! [ -f /ZMOD ]; then
                [ ${FF5X} -eq 0 ] && umount ${UMOUNT_MOD}
                unset LD_LIBRARY_PATH
                unset LD_PRELOAD
                chroot ${MOD} /bin/bash -c "cd \"${MOD_CONF}/mod_data/plugins/$1\" && git pull"
                [ ${FF5X} -eq 0 ] && mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
            else
                cd "${MOD_CONF}/mod_data/plugins/$1"
                git pull
            fi
        fi
    fi

    if ! [ -f "${MOD_CONF}/mod_data/plugins/$1/$1.cfg" ] && ! [ -f "${MOD_CONF}/mod_data/plugins/$1/${ZLANG}/$1.cfg" ]; then
        if [ ${ZLANG} != 'ru' ]; then
            echo "Plugin $1 not found in mod_data/plugins/$1/$1.cfg and mod_data/plugins/$1/${ZLANG}/$1.cfg"
        else
            echo "Основной файл плагина $1 не найден в mod_data/plugins/$1/$1.cfg и mod_data/plugins/$1/${ZLANG}/$1.cfg"
        fi
        exit 1
    fi
    if [ "$2" == "Enable" ]; then
        if [ ${ZLANG} != 'ru' ]; then
            echo "Enable plugin $1"
        else
            echo "Включаю плагин $1"
        fi

        if [ -f "${MOD_CONF}/mod_data/plugins/$1/${ZLANG}/$1.cfg" ]; then
            echo "[include plugins/$1/${ZLANG}/$1.cfg]" >>${MOD_CONF}/mod_data/plugins.cfg
        else
            echo "[include plugins/$1/$1.cfg]" >>${MOD_CONF}/mod_data/plugins.cfg
        fi
    else
        if [ ${ZLANG} != 'ru' ]; then
            echo "Disable plugin $1"
        else
            echo "Выключаю плагин $1"
        fi
        sed -i "/plugins\/$1\//d" ${MOD_CONF}/mod_data/plugins.cfg
    fi
    echo "FIRMWARE_RESTART" >/tmp/printer
else
    if [ ${ZLANG} != 'ru' ]; then
        echo "Plugin $1 not found in moonraker.conf, mod_data/user.moonraker.conf"
    else
        echo "Плагин $1 не найден в файлах moonraker.conf, mod_data/user.moonraker.conf"
    fi
fi
