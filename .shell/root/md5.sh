#!/bin/bash

rm -rf ../stock
mkdir -p ../stock

cat << 'EOF' > list.link
#!/bin/sh

source /opt/config/mod/.shell/0.sh

if [ ${ZLANG} != 'ru' ]; then
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
    a=$(stat -c '%a' "$1" 2>/dev/null)
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
    a=$(stat -c '%a' "$1" 2>/dev/null)
    if [ "$a" != "$2" ]; then
        /bin/echo -n "$1 - ${ERROR_FILE} ($a!=$2): "
        chmod "$2" "$1" 2>/dev/null && echo "${FIXED_STR}" || echo "${NOT_FIXED_STR}"
    fi
}
EOF
chmod +x list.link

excludes=(
    -and -not -name "md5sum.list"
    -and -not -name "md5.sh"
    -and -not -name "link.sh"
    -and -not -name "list.link"
    -and -not -name "ts.conf"
    -and -not -name "os-release"
    -and -not -path "./tmp"
    -and -not -path "./proc"
    -and -not -path "./root"
    -and -not -path "./sys"
    -and -not -path "./dev/*"
    -and -not -path "./etc/timezone"
    -and -not -path "./etc/localtime"
    -and -not -path "./root/mainsail/*"
    -and -not -path "./root/fluidd/*"
    -and -not -path "./root/printer_data/moonraker.asvc"
)

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
