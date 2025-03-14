#/bin/sh

rm -rf ../stock
mkdir -p ../stock

find .  \
    -type d \
    -and -not -name "*.pyc" \
    -and -not -path "./dev*" \
    -and -not -path "./run*" \
    -and -not -path "*__pycache__*" \
    -and -not -name "md5sum.list" \
    -and -not -name "md5.sh" \
    -and -not -name "link.sh" \
    -and -not -name "list.link" \
    -and -not -path "./usr/data/config/*" \
    -and -not -path "./usr/prog/PROGRAM/control/*" \
    -and -not -path "./usr/prog/PROGRAM/kernel/*" \
    -and -not -path "./usr/prog/PROGRAM/library/*" \
    -and -not -path "./usr/prog/PROGRAM/software/*" \
    -and -not -path "./opt/auto_run.sh" \
    -and -not -path "./usr/prog/klipper/klippy/extras/spi_temperature.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/gcode_shell_command.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/buttons.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/save_variables.py" \
    -and -not -path "./usr/prog/klipper/klippy/mcu.py" \
    -and -not -path "./usr/prog/klipper/klippy/toolhead.py" \
    -and -not -path "./usr/prog/klipper/klippy/webhooks.py" \
    -and -not -path "./etc/shadow-" \
    -and -not -path "./etc/shadow" \
    -and -not -path "./usr/prog/MAC" \
    -and -not -path "./usr/prog/app_startup.sh" \
    -and -not -path "./usr/prog/wifi/wpa_supplicant.conf" \
    -and -not -path "/usr/prog/tslib-1.12/etc/pointercal" \
    -exec mkdir -p ../stock/{} \;

echo "#!/bin/sh

check_dir()
{
    a=\$(/opt/config/mod/.shell/stat-coreutils -c '%a' \"\$1\" 2>/dev/null)
    if [ \"\$a\" != \"\$2\" ]; then
        echo -n \"\$1 - Ошибочные права (\$a!=\$2): \"
        mkdir -p \"\$1\" && chmod \"\$2\" \"\$1\" 2>/dev/null && echo \"Исправлено\" || echo \"Ошибка исправления\"
    fi
}

check_link()
{
    a=\$(readlink \"\$1\" 2>/dev/null)
    if [ \"\$a\" != \"\$2\" ]; then
        echo -n \"\$1 - Ошибочная ссылка (\$a!=\$2): \"
        rm -f \"\$1\" 2>/dev/null
        ln -s \"\$2\" \"\$1\" 2>/dev/null && echo \"Исправлено\"  || echo \"Ошибка исправления\"
    fi
}

check_file()
{
    a=\$(/opt/config/mod/.shell/stat-coreutils -c '%a' \"\$1\" 2>/dev/null)
    if [ \"\$a\" != \"\$2\" ]; then
        echo -n \"\$1 - Ошибочные права (\$a!=\$2): \"
        chmod \"\$2\" \"\$1\" 2>/dev/null && echo \"Исправлено\" || echo \"Ошибка исправления\"
    fi
}

" >list.link


echo "echo 'Проверка символических ссылок...'" >>list.link
chmod +x list.link
find .  \
    -type l \
    -and -not -name "*.pyc" \
    -and -not -path "./dev*" \
    -and -not -path "./run*" \
    -and -not -path "*__pycache__*" \
    -and -not -name "md5sum.list" \
    -and -not -name "md5.sh" \
    -and -not -name "link.sh" \
    -and -not -name "list.link" \
    -and -not -path "./usr/data/config/*" \
    -and -not -path "./usr/prog/PROGRAM/control/*" \
    -and -not -path "./usr/prog/PROGRAM/kernel/*" \
    -and -not -path "./usr/prog/PROGRAM/library/*" \
    -and -not -path "./usr/prog/PROGRAM/software/*" \
    -and -not -path "./opt/auto_run.sh" \
    -and -not -path "./usr/prog/klipper/klippy/extras/spi_temperature.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/gcode_shell_command.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/buttons.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/save_variables.py" \
    -and -not -path "./usr/prog/klipper/klippy/mcu.py" \
    -and -not -path "./usr/prog/klipper/klippy/toolhead.py" \
    -and -not -path "./usr/prog/klipper/klippy/webhooks.py" \
    -and -not -path "./etc/shadow-" \
    -and -not -path "./etc/shadow" \
    -and -not -path "./usr/prog/MAC" \
    -and -not -path "./usr/prog/app_startup.sh" \
    -and -not -path "./usr/prog/wifi/wpa_supplicant.conf" \
    -and -not -path "/usr/prog/tslib-1.12/etc/pointercal" \
    -exec ./link.sh {} link \; >>list.link

find .  \
    -type f \
    -and -not -name "*.pyc" \
    -and -not -path "./dev*" \
    -and -not -path "./run*" \
    -and -not -path "*__pycache__*" \
    -and -not -name "md5sum.list" \
    -and -not -name "md5.sh" \
    -and -not -name "link.sh" \
    -and -not -name "list.link" \
    -and -not -path "./usr/data/config/*" \
    -and -not -path "./usr/prog/PROGRAM/control/*" \
    -and -not -path "./usr/prog/PROGRAM/kernel/*" \
    -and -not -path "./usr/prog/PROGRAM/library/*" \
    -and -not -path "./usr/prog/PROGRAM/software/*" \
    -and -not -path "./opt/auto_run.sh" \
    -and -not -path "./usr/prog/klipper/klippy/extras/spi_temperature.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/gcode_shell_command.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/buttons.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/save_variables.py" \
    -and -not -path "./usr/prog/klipper/klippy/mcu.py" \
    -and -not -path "./usr/prog/klipper/klippy/toolhead.py" \
    -and -not -path "./usr/prog/klipper/klippy/webhooks.py" \
    -and -not -path "./etc/shadow-" \
    -and -not -path "./etc/shadow" \
    -and -not -path "./usr/prog/MAC" \
    -and -not -path "./usr/prog/app_startup.sh" \
    -and -not -path "./usr/prog/wifi/wpa_supplicant.conf" \
    -and -not -path "/usr/prog/tslib-1.12/etc/pointercal" \
    -exec cp -a {} ../stock/{} \;

find .  \
    -type f \
    -and -not -name "*.pyc" \
    -and -not -path "./dev*" \
    -and -not -path "./run*" \
    -and -not -path "*__pycache__*" \
    -and -not -name "md5sum.list" \
    -and -not -name "md5.sh" \
    -and -not -name "link.sh" \
    -and -not -name "list.link" \
    -and -not -path "./usr/data/config/*" \
    -and -not -path "./usr/prog/PROGRAM/control/*" \
    -and -not -path "./usr/prog/PROGRAM/kernel/*" \
    -and -not -path "./usr/prog/PROGRAM/library/*" \
    -and -not -path "./usr/prog/PROGRAM/software/*" \
    -and -not -path "./opt/auto_run.sh" \
    -and -not -path "./usr/prog/klipper/klippy/extras/spi_temperature.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/gcode_shell_command.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/buttons.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/save_variables.py" \
    -and -not -path "./usr/prog/klipper/klippy/mcu.py" \
    -and -not -path "./usr/prog/klipper/klippy/toolhead.py" \
    -and -not -path "./usr/prog/klipper/klippy/webhooks.py" \
    -and -not -path "./etc/shadow-" \
    -and -not -path "./etc/shadow" \
    -and -not -path "./usr/prog/MAC" \
    -and -not -path "./usr/prog/app_startup.sh" \
    -and -not -path "./usr/prog/wifi/wpa_supplicant.conf" \
    -and -not -path "/usr/prog/tslib-1.12/etc/pointercal" \
    -exec md5sum {} \; >md5sum.list

exit
echo "echo 'Проверка прав на файлы...'">>list.link
find .  \
    -type f \
    -and -not -name "*.pyc" \
    -and -not -path "./dev*" \
    -and -not -path "./run*" \
    -and -not -path "*__pycache__*" \
    -and -not -name "md5sum.list" \
    -and -not -name "md5.sh" \
    -and -not -name "link.sh" \
    -and -not -name "list.link" \
    -and -not -path "./usr/data/config/*" \
    -and -not -path "./usr/prog/PROGRAM/control/*" \
    -and -not -path "./usr/prog/PROGRAM/kernel/*" \
    -and -not -path "./usr/prog/PROGRAM/library/*" \
    -and -not -path "./usr/prog/PROGRAM/software/*" \
    -and -not -path "./opt/auto_run.sh" \
    -and -not -path "./usr/prog/klipper/klippy/extras/spi_temperature.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/gcode_shell_command.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/buttons.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/save_variables.py" \
    -and -not -path "./usr/prog/klipper/klippy/mcu.py" \
    -and -not -path "./usr/prog/klipper/klippy/toolhead.py" \
    -and -not -path "./usr/prog/klipper/klippy/webhooks.py" \
    -and -not -path "./etc/shadow-" \
    -and -not -path "./etc/shadow" \
    -and -not -path "./usr/prog/MAC" \
    -and -not -path "./usr/prog/app_startup.sh" \
    -and -not -path "./usr/prog/wifi/wpa_supplicant.conf" \
    -and -not -path "/usr/prog/tslib-1.12/etc/pointercal" \
    -exec ./link.sh {} "file" \; >>list.link

echo "echo 'Проверка прав на каталоги...'">>list.link
find .  \
    -type d \
    -and -not -name "*.pyc" \
    -and -not -path "./dev*" \
    -and -not -path "./run*" \
    -and -not -path "*__pycache__*" \
    -and -not -name "md5sum.list" \
    -and -not -name "md5.sh" \
    -and -not -name "link.sh" \
    -and -not -name "list.link" \
    -and -not -path "./usr/data/config/*" \
    -and -not -path "./usr/prog/PROGRAM/control/*" \
    -and -not -path "./usr/prog/PROGRAM/kernel/*" \
    -and -not -path "./usr/prog/PROGRAM/library/*" \
    -and -not -path "./usr/prog/PROGRAM/software/*" \
    -and -not -path "./opt/auto_run.sh" \
    -and -not -path "./usr/prog/klipper/klippy/extras/spi_temperature.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/gcode_shell_command.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/buttons.py" \
    -and -not -path "./usr/prog/klipper/klippy/extras/save_variables.py" \
    -and -not -path "./usr/prog/klipper/klippy/mcu.py" \
    -and -not -path "./usr/prog/klipper/klippy/toolhead.py" \
    -and -not -path "./usr/prog/klipper/klippy/webhooks.py" \
    -and -not -path "./etc/shadow-" \
    -and -not -path "./etc/shadow" \
    -and -not -path "./usr/prog/MAC" \
    -and -not -path "./usr/prog/app_startup.sh" \
    -and -not -path "./usr/prog/wifi/wpa_supplicant.conf" \
    -and -not -path "/usr/prog/tslib-1.12/etc/pointercal" \
    -exec ./link.sh {} "dir" \; >>list.link
