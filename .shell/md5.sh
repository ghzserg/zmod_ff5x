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
    -and -not -path "./.rnd" \
    -and -not -path "./.wpa_cli_history" \
    -and -not -path "./root/printer_data/version.txt" \
    -and -not -path "./etc/dropbear/*" \
    -and -not -path "./etc/timezone" \
    -and -not -path "./etc/localtime" \
    -and -not -path "./opt/config/*" \
    -and -not -path "./opt/PROGRAM/control/*" \
    -and -not -path "./opt/PROGRAM/kernel/*" \
    -and -not -path "./opt/PROGRAM/library/*" \
    -and -not -path "./opt/PROGRAM/software/*" \
    -and -not -path "./opt/auto_run.sh" \
    -and -not -path "./root/version" \
    -and -not -path "./root/.viminfo" \
    -and -not -path "./opt/klipper/klippy/extras/spi_temperature.py" \
    -and -not -path "./opt/klipper/klippy/extras/gcode_shell_command.py" \
    -and -not -path "./opt/klipper/klippy/extras/buttons.py" \
    -and -not -path "./opt/klipper/klippy/extras/save_variables.py" \
    -and -not -path "./opt/klipper/klippy/mcu.py" \
    -and -not -path "./opt/klipper/klippy/toolhead.py" \
    -and -not -path "./opt/klipper/klippy/webhooks.py" \
    -and -not -path "./opt/key.priv" \
    -and -not -path "./opt/private.pem" \
    -and -not -path "./opt/key.pub" \
    -and -not -path "./etc/shadow-" \
    -and -not -path "./etc/shadow" \
    -and -not -path "./etc/rtl_hostapd_2G.conf" \
    -and -not -path "./etc/hosts" \
    -and -not -path "./etc/random-seed" \
    -and -not -path "./etc/MAC" \
    -and -not -path "./etc/wpa_supplicant.conf" \
    -and -not -path "./opt/tslib-1.12/etc/pointercal" \
    -and -not -path "./Settings/Trolltech.conf" \
    -exec mkdir -p ../stock/{} \;

echo "#!/bin/sh

check_dir()
{
    a=\$(/opt/config/mod/.shell/stat-coreutils -c '%a' \"\$1\" 2>/dev/null)
    if [ \"\$a\" != \"\$2\" ]; then
        /bin/echo -n \"\$1 - Ошибочные права (\$a!=\$2): \"
        mkdir -p \"\$1\" && chmod \"\$2\" \"\$1\" 2>/dev/null && echo \"Исправлено\" || echo \"Ошибка исправления\"
    fi
}

check_link()
{
    a=\$(readlink \"\$1\" 2>/dev/null)
    if [ \"\$a\" != \"\$2\" ]; then
        /bin/echo -n \"\$1 - Ошибочная ссылка (\$a!=\$2): \"
        rm -f \"\$1\" 2>/dev/null
        ln -s \"\$2\" \"\$1\" 2>/dev/null && echo \"Исправлено\"  || echo \"Ошибка исправления\"
    fi
}

check_file()
{
    a=\$(/opt/config/mod/.shell/stat-coreutils -c '%a' \"\$1\" 2>/dev/null)
    if [ \"\$a\" != \"\$2\" ]; then
        /bin/echo -n \"\$1 - Ошибочные права (\$a!=\$2): \"
        chmod \"\$2\" \"\$1\" 2>/dev/null && echo \"Исправлено\" || echo \"Ошибка исправления\"
    fi
}

" >list.link

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
    -and -not -path "./.rnd" \
    -and -not -path "./.wpa_cli_history" \
    -and -not -path "./root/printer_data/version.txt" \
    -and -not -path "./etc/dropbear/*" \
    -and -not -path "./etc/timezone" \
    -and -not -path "./etc/localtime" \
    -and -not -path "./opt/config/*" \
    -and -not -path "./opt/PROGRAM/control/*" \
    -and -not -path "./opt/PROGRAM/kernel/*" \
    -and -not -path "./opt/PROGRAM/library/*" \
    -and -not -path "./opt/PROGRAM/software/*" \
    -and -not -path "./opt/auto_run.sh" \
    -and -not -path "./root/version" \
    -and -not -path "./root/.viminfo" \
    -and -not -path "./opt/klipper/klippy/extras/spi_temperature.py" \
    -and -not -path "./opt/klipper/klippy/extras/gcode_shell_command.py" \
    -and -not -path "./opt/klipper/klippy/extras/buttons.py" \
    -and -not -path "./opt/klipper/klippy/extras/save_variables.py" \
    -and -not -path "./opt/klipper/klippy/mcu.py" \
    -and -not -path "./opt/klipper/klippy/toolhead.py" \
    -and -not -path "./opt/klipper/klippy/webhooks.py" \
    -and -not -path "./opt/key.priv" \
    -and -not -path "./opt/private.pem" \
    -and -not -path "./opt/key.pub" \
    -and -not -path "./etc/shadow-" \
    -and -not -path "./etc/shadow" \
    -and -not -path "./etc/rtl_hostapd_2G.conf" \
    -and -not -path "./etc/hosts" \
    -and -not -path "./etc/random-seed" \
    -and -not -path "./etc/MAC" \
    -and -not -path "./etc/wpa_supplicant.conf" \
    -and -not -path "./opt/tslib-1.12/etc/pointercal" \
    -and -not -path "./Settings/Trolltech.conf" \
    -exec ./link.sh {} "dir" \; >>list.link

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
    -and -not -path "./.rnd" \
    -and -not -path "./.wpa_cli_history" \
    -and -not -path "./root/printer_data/version.txt" \
    -and -not -path "./etc/dropbear/*" \
    -and -not -path "./etc/timezone" \
    -and -not -path "./etc/localtime" \
    -and -not -path "./opt/config/*" \
    -and -not -path "./opt/PROGRAM/control/*" \
    -and -not -path "./opt/PROGRAM/kernel/*" \
    -and -not -path "./opt/PROGRAM/library/*" \
    -and -not -path "./opt/PROGRAM/software/*" \
    -and -not -path "./opt/auto_run.sh" \
    -and -not -path "./root/version" \
    -and -not -path "./root/.viminfo" \
    -and -not -path "./opt/klipper/klippy/extras/spi_temperature.py" \
    -and -not -path "./opt/klipper/klippy/extras/gcode_shell_command.py" \
    -and -not -path "./opt/klipper/klippy/extras/buttons.py" \
    -and -not -path "./opt/klipper/klippy/extras/save_variables.py" \
    -and -not -path "./opt/klipper/klippy/mcu.py" \
    -and -not -path "./opt/klipper/klippy/toolhead.py" \
    -and -not -path "./opt/klipper/klippy/webhooks.py" \
    -and -not -path "./opt/key.priv" \
    -and -not -path "./opt/private.pem" \
    -and -not -path "./opt/key.pub" \
    -and -not -path "./etc/shadow-" \
    -and -not -path "./etc/shadow" \
    -and -not -path "./etc/rtl_hostapd_2G.conf" \
    -and -not -path "./etc/hosts" \
    -and -not -path "./etc/random-seed" \
    -and -not -path "./etc/MAC" \
    -and -not -path "./etc/wpa_supplicant.conf" \
    -and -not -path "./opt/tslib-1.12/etc/pointercal" \
    -and -not -path "./Settings/Trolltech.conf" \
    -exec ./link.sh {} link \; >>list.link

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
    -and -not -path "./.rnd" \
    -and -not -path "./.wpa_cli_history" \
    -and -not -path "./root/printer_data/version.txt" \
    -and -not -path "./etc/dropbear/*" \
    -and -not -path "./etc/timezone" \
    -and -not -path "./etc/localtime" \
    -and -not -path "./opt/config/*" \
    -and -not -path "./opt/PROGRAM/control/*" \
    -and -not -path "./opt/PROGRAM/kernel/*" \
    -and -not -path "./opt/PROGRAM/library/*" \
    -and -not -path "./opt/PROGRAM/software/*" \
    -and -not -path "./opt/auto_run.sh" \
    -and -not -path "./root/version" \
    -and -not -path "./root/.viminfo" \
    -and -not -path "./opt/klipper/klippy/extras/spi_temperature.py" \
    -and -not -path "./opt/klipper/klippy/extras/gcode_shell_command.py" \
    -and -not -path "./opt/klipper/klippy/extras/buttons.py" \
    -and -not -path "./opt/klipper/klippy/extras/save_variables.py" \
    -and -not -path "./opt/klipper/klippy/mcu.py" \
    -and -not -path "./opt/klipper/klippy/toolhead.py" \
    -and -not -path "./opt/klipper/klippy/webhooks.py" \
    -and -not -path "./opt/key.priv" \
    -and -not -path "./opt/private.pem" \
    -and -not -path "./opt/key.pub" \
    -and -not -path "./etc/shadow-" \
    -and -not -path "./etc/shadow" \
    -and -not -path "./etc/rtl_hostapd_2G.conf" \
    -and -not -path "./etc/hosts" \
    -and -not -path "./etc/random-seed" \
    -and -not -path "./etc/MAC" \
    -and -not -path "./etc/wpa_supplicant.conf" \
    -and -not -path "./opt/tslib-1.12/etc/pointercal" \
    -and -not -path "./Settings/Trolltech.conf" \
    -exec ./link.sh {} "file" \; >>list.link

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
    -and -not -path "./.rnd" \
    -and -not -path "./.wpa_cli_history" \
    -and -not -path "./root/printer_data/version.txt" \
    -and -not -path "./etc/dropbear/*" \
    -and -not -path "./etc/timezone" \
    -and -not -path "./etc/localtime" \
    -and -not -path "./opt/config/*" \
    -and -not -path "./opt/PROGRAM/control/*" \
    -and -not -path "./opt/PROGRAM/kernel/*" \
    -and -not -path "./opt/PROGRAM/library/*" \
    -and -not -path "./opt/PROGRAM/software/*" \
    -and -not -path "./opt/auto_run.sh" \
    -and -not -path "./root/version" \
    -and -not -path "./root/.viminfo" \
    -and -not -path "./opt/klipper/klippy/extras/spi_temperature.py" \
    -and -not -path "./opt/klipper/klippy/extras/gcode_shell_command.py" \
    -and -not -path "./opt/klipper/klippy/extras/buttons.py" \
    -and -not -path "./opt/klipper/klippy/extras/save_variables.py" \
    -and -not -path "./opt/klipper/klippy/mcu.py" \
    -and -not -path "./opt/klipper/klippy/toolhead.py" \
    -and -not -path "./opt/klipper/klippy/webhooks.py" \
    -and -not -path "./opt/key.priv" \
    -and -not -path "./opt/private.pem" \
    -and -not -path "./opt/key.pub" \
    -and -not -path "./etc/shadow-" \
    -and -not -path "./etc/shadow" \
    -and -not -path "./etc/rtl_hostapd_2G.conf" \
    -and -not -path "./etc/hosts" \
    -and -not -path "./etc/random-seed" \
    -and -not -path "./etc/MAC" \
    -and -not -path "./etc/wpa_supplicant.conf" \
    -and -not -path "./opt/tslib-1.12/etc/pointercal" \
    -and -not -path "./Settings/Trolltech.conf" \
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
    -and -not -path "./.rnd" \
    -and -not -path "./.wpa_cli_history" \
    -and -not -path "./root/printer_data/version.txt" \
    -and -not -path "./etc/dropbear/*" \
    -and -not -path "./etc/timezone" \
    -and -not -path "./etc/localtime" \
    -and -not -path "./opt/config/*" \
    -and -not -path "./opt/PROGRAM/control/*" \
    -and -not -path "./opt/PROGRAM/kernel/*" \
    -and -not -path "./opt/PROGRAM/library/*" \
    -and -not -path "./opt/PROGRAM/software/*" \
    -and -not -path "./opt/auto_run.sh" \
    -and -not -path "./root/version" \
    -and -not -path "./root/.viminfo" \
    -and -not -path "./opt/klipper/klippy/extras/spi_temperature.py" \
    -and -not -path "./opt/klipper/klippy/extras/gcode_shell_command.py" \
    -and -not -path "./opt/klipper/klippy/extras/buttons.py" \
    -and -not -path "./opt/klipper/klippy/extras/save_variables.py" \
    -and -not -path "./opt/klipper/klippy/mcu.py" \
    -and -not -path "./opt/klipper/klippy/toolhead.py" \
    -and -not -path "./opt/klipper/klippy/webhooks.py" \
    -and -not -path "./opt/key.priv" \
    -and -not -path "./opt/private.pem" \
    -and -not -path "./opt/key.pub" \
    -and -not -path "./etc/shadow-" \
    -and -not -path "./etc/shadow" \
    -and -not -path "./etc/rtl_hostapd_2G.conf" \
    -and -not -path "./etc/hosts" \
    -and -not -path "./etc/random-seed" \
    -and -not -path "./etc/MAC" \
    -and -not -path "./etc/wpa_supplicant.conf" \
    -and -not -path "./opt/tslib-1.12/etc/pointercal" \
    -and -not -path "./Settings/Trolltech.conf" \
    -exec md5sum {} \; >md5sum.list
