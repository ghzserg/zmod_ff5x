#!/bin/bash

rm -rf ../stock
mkdir -p ../stock

cat << 'EOF' > list.link
#!/bin/sh

source /opt/config/mod/.shell/0.sh

if [ ${ZLANG} == 'en' ]; then
    A1="Incorrect access rights"
    FIXED_STR="Fixed"
    NOT_FIXED_STR="Error fix"
    DIR_STR="Checking directory permissions..."
    LINK_STR="Checking symbolic links..."
    FILE_STR="Checking file permissions..."
    ERROR_LINK="Incorrect link"
    ERROR_FILE="Erroneous rights"
else
    A1="Ошибочные права"
    FIXED_STR="Исправлено"
    NOT_FIXED_STR="Ошибка исправления"
    DIR_STR="Проверка прав на каталоги..."
    LINK_STR="Проверка символических ссылок..."
    FILE_STR="Проверка прав на файлы..."
    ERROR_LINK="Ошибочная ссылка"
    ERROR_FILE="Ошибочные права"
fi

check_dir()
{
    a=$(/opt/config/mod/.shell/stat-coreutils -c '%a' "$1" 2>/dev/null)
    if [ "$a" != "$2" ]; then
        /bin/echo -n "$1 - ${A1} ($a!=$2): "|| /bin/echo -n "$1 - ${A1} ($a!=$2): "
        mkdir -p "$1" && chmod "$2" "$1" 2>/dev/null && echo "${FIXED_STR}" || echo "${NOT_FIXED_STR}"
    fi
}

check_link()
{
    a=$(readlink "$1" 2>/dev/null)
    if [ "$a" != "$2" ]; then
        /bin/echo -n "$1 - ${ERROR_LINK} ($a!=$2): "
        rm -f "$1" 2>/dev/null
        ln -s "$2" "$1" 2>/dev/null && echo "${FIXED_STR}"  || echo "${NOT_FIXED_STR}"
    fi
}

check_file()
{
    a=$(/opt/config/mod/.shell/stat-coreutils -c '%a' "$1" 2>/dev/null)
    if [ "$a" != "$2" ]; then
        /bin/echo -n "$1 - ${ERROR_FILE} ($a!=$2): "
        chmod "$2" "$1" 2>/dev/null && echo "${FIXED_STR}" || echo "${NOT_FIXED_STR}"
    fi
}
EOF
chmod +x list.link

excludes=(
    -not -name "*.pyc"
    -and -not -path "./dev*"
    -and -not -path "./run*"
    -and -not -path "*__pycache__*"
    -and -not -name "md5sum.list"
    -and -not -name "md5.sh"
    -and -not -name "link.sh"
    -and -not -name "list.link"
    -and -not -path "./.rnd"
    -and -not -path "./.wpa_cli_history"
    -and -not -path "./root/printer_data/version.txt"
    -and -not -path "./etc/dropbear/*"
    -and -not -path "./etc/timezone"
    -and -not -path "./etc/localtime"
    -and -not -path "./opt/config/*"
    -and -not -path "./opt/PROGRAM/control/*"
    -and -not -path "./opt/PROGRAM/kernel/*"
    -and -not -path "./opt/PROGRAM/library/*"
    -and -not -path "./opt/PROGRAM/software/*"
    -and -not -path "./opt/auto_run.sh"
    -and -not -path "./root/version"
    -and -not -path "./root/.viminfo"
    -and -not -path "./opt/klipper/klippy/extras/spi_temperature.py"
    -and -not -path "./opt/klipper/klippy/extras/gcode_shell_command.py"
    -and -not -path "./opt/klipper/klippy/extras/buttons.py"
    -and -not -path "./opt/klipper/klippy/extras/save_variables.py"
    -and -not -path "./opt/klipper/klippy/mcu.py"
    -and -not -path "./opt/klipper/klippy/toolhead.py"
    -and -not -path "./opt/klipper/klippy/webhooks.py"
    -and -not -path "./opt/key.priv"
    -and -not -path "./opt/private.pem"
    -and -not -path "./opt/key.pub"
    -and -not -path "./etc/shadow-"
    -and -not -path "./etc/shadow"
    -and -not -path "./etc/rtl_hostapd_2G.conf"
    -and -not -path "./etc/hosts"
    -and -not -path "./etc/random-seed"
    -and -not -path "./etc/MAC"
    -and -not -path "./etc/wpa_supplicant.conf"
    -and -not -path "./opt/tslib-1.12/etc/pointercal"
    -and -not -path "./Settings/Trolltech.conf"
)

find . \
    -type d \
    "${excludes[@]}" \
    -print0 | sort -z | while IFS= read -r -d '' fn; do
        mkdir -p "../stock/${fn}"
    done

find .  \
    -type f \
    "${excludes[@]}" \
    -exec cp -a {} ../stock/{} \;

echo 'echo ${DIR_STR}'>>list.link
find .  \
    -type d \
    "${excludes[@]}" \
    -print0 | sort -z | while IFS= read -r -d '' fn; do
        ./link.sh "$fn" "dir"
    done >>list.link

echo 'echo ${LINK_STR}' >>list.link
find .  \
    -type l \
    "${excludes[@]}" \
    -print0 | sort -z | while IFS= read -r -d '' fn; do
        ./link.sh "$fn" "link"
    done >>list.link

echo 'echo ${FILE_STR}'>>list.link
find .  \
    -type f \
    "${excludes[@]}" \
    -print0 | sort -z | while IFS= read -r -d '' fn; do
        ./link.sh "$fn" "file"
    done >>list.link

>md5sum.list
find .  \
    -type f \
    "${excludes[@]}" \
    -print0 | sort -z | while IFS= read -r -d '' fn; do
        md5sum "$fn"
    done >>md5sum.list
