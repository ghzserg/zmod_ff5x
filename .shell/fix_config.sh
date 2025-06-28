#!/bin/sh

set -x

unset LD_LIBRARY_PATH
unset LD_PRELOAD

if [ -f /opt/config/mod/.shell/0.sh ]; then
    source /opt/config/mod/.shell/0.sh
else if [ -f /usr/data/config/mod/.shell/0.sh ]; then
    source /usr/data/config/mod/.shell/0.sh
fi
fi

# Разблокировка
china_razbl()
{
    grep -q "$1" /etc/hosts && sed -i "/$1/d" /etc/hosts
}

# Блокировка
china_block()
{
    grep -q "$1" /etc/hosts || sed -i "2 i\127.0.0.1 $1" /etc/hosts
}

check_link()
{
    a=$(readlink "$1" 2>/dev/null)
    if [ "$a" != "$2" ]; then
        /bin/echo -n "$1 - Incorrect link ($a!=$2): "
        rm -f "$1" 2>/dev/null
        ln -s "$2" "$1" 2>/dev/null && echo "Исправлено"  || echo "Ошибка исправления"
    fi
}

restore_base()
{
    grep -q '^\[include mod.user.cfg' ${MOD_CONF}/printer.cfg && sed -i '/include mod.user.cfg/d' ${MOD_CONF}/printer.cfg
    grep -q '^\[include ./mod/mod.cfg' ${MOD_CONF}/printer.cfg && sed -i '/mod.cfg/d' ${MOD_CONF}/printer.cfg
    grep -q '^\[include ./mod_data/user.cfg' ${MOD_CONF}/printer.cfg && sed -i '/user.cfg/d' ${MOD_CONF}/printer.cfg
    grep -q '^\[include ./mod/switch_sensor.cfg' ${MOD_CONF}/printer.cfg && sed -i '/switch_sensor.cfg/d' ${MOD_CONF}/printer.cfg
    grep -q '^\[include ./mod/motion_sensor.cfg' ${MOD_CONF}/printer.cfg && sed -i '/motion_sensor.cfg/d' ${MOD_CONF}/printer.cfg
    grep -q '^\[include ./mod/switch_sensor_display_off.cfg' ${MOD_CONF}/printer.cfg && sed -i '/switch_sensor_display_off.cfg/d' ${MOD_CONF}/printer.cfg
    grep -q '^\[include ./mod/display_off.cfg' ${MOD_CONF}/printer.cfg && sed -i '/display_off.cfg/d' ${MOD_CONF}/printer.cfg

    if [ ${FF5X} -eq 0 ]; then
        china_razbl api.cloud.flashforge.com
        china_razbl api.fdmcloud.flashforge.com
        china_razbl cloud.sz3dp.com
        china_razbl hz.sz3dp.com
        china_razbl printer2.polar3d.com
        china_razbl qvs.qiniuapi.com
        china_razbl update.cn.sz3dp.com
        china_razbl update.sz3dp.com
        china_razbl cloud.sz3dp.com
        china_razbl polar3d.com
    else
        sed -i '\|mount --bind /bin/echo /usr/bin/cmd_pwm|d' /usr/prog/app_startup.sh
    fi

    grep -q _output_callback_gcode ${KLIPPER_DIR}/klippy/webhooks.py && cp ${MOD_CONF}/mod/.shell/webhooks.py.orig ${KLIPPER_DIR}/klippy/webhooks.py
    grep -q ZLOAD_VARIABLE ${KLIPPER_DIR}/klippy/extras/save_variables.py && cp ${MOD_CONF}/mod/.shell/save_variables.py.orig ${KLIPPER_DIR}/klippy/extras/save_variables.py
    if [ ${FF5X} -eq 0 ]; then
        grep -q zmod ${KLIPPER_DIR}/klippy/extras/spi_temperature.py && cp ${MOD_CONF}/mod/.shell/spi_temperature.py.orig ${KLIPPER_DIR}/klippy/extras/spi_temperature.py
        grep -q zmod /opt/klipper/start.sh && cp ${MOD_CONF}/mod/.shell/start.sh.orig /opt/klipper/start.sh
    fi
    grep -q receive_time ${KLIPPER_DIR}/klippy/extras/buttons.py && cp ${MOD_CONF}/mod/.shell/buttons.py.orig ${KLIPPER_DIR}/klippy/extras/buttons.py
    rm -f ${KLIPPER_DIR}/klippy/extras/zmod.py
    [ ${FF5X} -eq 1 ] && rm -f ${KLIPPER_DIR}/klippy/extras/zmod_color.py
    [ ${FF5X} -eq 1 ] && rm -f ${KLIPPER_DIR}/klippy/extras/zmod_tenz.py
    [ ${FF5X} -eq 1 ] && rm -f ${KLIPPER_DIR}/klippy/extras/zmod_ifs_switch_sensor.py

    rm -f /etc/profile.d/path.sh

    F="${KLIPPER_DIR}/klippy/toolhead.py"
    grep -q "LOOKAHEAD_FLUSH_TIME = 0.5" $F || sed -i 's|^LOOKAHEAD_FLUSH_TIME.*|LOOKAHEAD_FLUSH_TIME = 0.5|' $F

    F="${KLIPPER_DIR}/klippy/mcu.py"
    grep -q "TRSYNC_TIMEOUT = 0.025" $F || sed -i 's|^TRSYNC_TIMEOUT = .*|TRSYNC_TIMEOUT = 0.025|' $F

    if [ -L ${KLIPPER_DIR}/klippy/extras/load_cell_tare.py ] || [ -f ${KLIPPER_DIR}/klippy/extras/load_cell_tare.py ]; then
        rm -f ${KLIPPER_DIR}/klippy/extras/load_cell_tare.py
    fi

    # Удаляем controller_fan driver_fan
    if grep -q '^\[controller_fan driver_fan' ${MOD_CONF}/printer.base.cfg; then
        cd ${MOD_CONF}
        sed -e '/^\[controller_fan driver_fan/,/^\[/d' printer.base.cfg >printer.base.tmp
        diff -u printer.base.cfg printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
        sed -i '$d' heater_bed.txt
        num=$(wc -l heater_bed.txt|cut  -d " " -f1)
        num=$(($num-1))
        sed -e "/^\[controller_fan driver_fan/,+${num}d;" printer.base.cfg >printer.base.tmp
        mv printer.base.tmp printer.base.cfg
        rm -f heater_bed.txt
    fi


    # Возвращаем fan_generic pcb_fan
    [ ${FF5X} -eq 1 ] && PIN="PA5" || PIN="PB7"
    if ! grep -q '^\[fan_generic pcb_fan' ${MOD_CONF}/printer.base.cfg
        then
            echo "
[fan_generic pcb_fan]
pin:${PIN}
" >>${MOD_CONF}/printer.base.cfg
    fi

    # Возвращаем gcode_button check_level_pin
    if [ ${FF5X} -eq 0 ] && ! grep -q '^\[gcode_button check_level_pin' ${MOD_CONF}/printer.base.cfg
        then
            echo '
[gcode_button check_level_pin]
pin: !PE0
press_gcode:
    M105
' >>${MOD_CONF}/printer.base.cfg
    fi

    if [ ${FF5X} -eq 0 ] && grep -q "motion_sensor = 1" ${MOD_CONF}/mod_data/variables.cfg; then
        # Возвращаем filament_motion_sensor e0_sensor
        if ! grep -q '\[filament_motion_sensor e0_sensor' ${MOD_CONF}/printer.base.cfg
            then
                echo '
[filament_motion_sensor e0_sensor]
detection_length: 8
extruder: extruder
switch_pin: !PB14
pause_on_runout: True
runout_gcode:
  RESPOND TYPE=command MSG="!! Кончился или остановился филамент"
' >>${MOD_CONF}/printer.base.cfg
        fi
    else
        # Возвращаем filament_switch_sensor e0_sensor
        if [ ${FF5X} -eq 0 ] && ! grep -q '\[filament_switch_sensor e0_sensor' ${MOD_CONF}/printer.base.cfg
            then
                echo '
[filament_switch_sensor e0_sensor]
pause_on_runout: False
switch_pin: !PB14
event_delay: 1.0

' >>${MOD_CONF}/printer.base.cfg
        fi
    fi

    grep -q '^minimum_cruise_ratio' ${MOD_CONF}/printer.base.cfg && sed -i 's|^minimum_cruise_ratio.*|max_accel_to_decel:5000|' ${MOD_CONF}/printer.base.cfg
}

fix_config()
{
    echo "START fix_config"
    date
    fstrim ${DATA} -v
    [ ${FF5X} -eq 0 ] && fstrim / -v || fstrim /usr/prog -v

    [ -f /etc/profile.d/path.sh ] || echo "export PATH=\"$PATH:/opt/bin/:/opt/sbin/\"" >/etc/profile.d/path.sh

    mkdir -p ${MOD_CONF}/mod_data/database/
    [ -f ${MOD_CONF}/mod_data/user.cfg ] || echo "" >${MOD_CONF}/mod_data/user.cfg
    [ -f ${MOD_CONF}/mod_data/variables.cfg ] || echo "[Variables]" >${MOD_CONF}/mod_data/variables.cfg

    if [ ${FF5X} -eq 1 ]; then
        [ -f ${MOD_CONF}/mod_data/cmd_pwm ] || cp /usr/bin/cmd_pwm ${MOD_CONF}/mod_data/cmd_pwm
        grep -q "mount --bind /bin/echo /usr/bin/cmd_pwm" /usr/prog/app_startup.sh || sed -i '\#mount /usr/prog/etc /etc#a\mount --bind /bin/echo /usr/bin/cmd_pwm' /usr/prog/app_startup.sh
    fi

    echo "[zmod]
    language: ${ZLANG}" >${MOD_CONF}/mod_data/lang.cfg

    check_link ${MOD_CONF}/mod/base.cfg ${ZLANG}/base.cfg
    check_link ${MOD_CONF}/mod/client.cfg ${ZLANG}/client.cfg
    if [ ${FF5X} -eq 0 ]; then
        check_link ${MOD_CONF}/mod/display_off.cfg ${ZLANG}/display_off.cfg
        check_link ${MOD_CONF}/mod/ff5.cfg ${ZLANG}/ff5.cfg
        check_link ${MOD_CONF}/mod/mod.cfg ${ZLANG}/mod.cfg
    else
        check_link ${MOD_CONF}/mod/base_display_off.cfg ${ZLANG}/display_off.cfg
        check_link ${MOD_CONF}/mod/base_mod.cfg ${ZLANG}/mod.cfg
    fi
    check_link ${MOD_CONF}/mod/motion_sensor.cfg ${ZLANG}/motion_sensor.cfg
    check_link ${MOD_CONF}/mod/switch_sensor_display_off.cfg ${ZLANG}/switch_sensor_display_off.cfg

    if [ ${FF5X} -eq 1 ]; then
        # В Версии 1.0.7 перенесли конфиг в /usr/prog/config/
        [ -d /usr/prog/config/mod ] && rm -rf /usr/prog/config/mod
        [ -d /usr/prog/config/mod_data ] && rm -rf /usr/prog/config/mod_data
        [ -d /usr/prog/config/save ] && rm -rf /usr/prog/config/save
        [ -f /usr/prog/config/Adventurer5M.json ] && check_link ${MOD_CONF}/Adventurer5M.json /usr/prog/config/Adventurer5M.json
        [ -f /usr/prog/config/PowerOff ] && check_link ${MOD_CONF}/PowerOff /usr/prog/config/PowerOff
        [ -f /usr/prog/config/fileSlotId.json ] && check_link ${MOD_CONF}/fileSlotId.json /usr/prog/config/fileSlotId.json
    fi

    if ! [ -f ${MOD_CONF}/mod_data/user.moonraker.conf ]; then
        echo "#Enter user config here
[authorization]
trusted_clients:
  0.0.0.0/0

cors_domains:
  *
" >${MOD_CONF}/mod_data/user.moonraker.conf;
    fi

    # Защита от самонадеянных, кто выклчюает SWAP при 128 мегабайтах оперативной памяти
    if [ ${FF5X} -eq 0 ] && grep -q "use_swap = 0" ${MOD_CONF}/mod_data/variables.cfg; then
        MEM=$(cat /proc/meminfo | grep MemTotal| awk '{print $2}')
        MEM=$(($MEM/1024))
        [ "$MEM" -le 128 ] && sed -i "s/use_swap = 0/use_swap = 1/" ${MOD_CONF}/mod_data/variables.cfg
    fi

    [ -f ${MOD_CONF}/mod_data/nozzle.cfg ] || echo "">${MOD_CONF}/mod_data/nozzle.cfg

    if [ ${FF5X} -eq 0 ]; then
        [ -f /etc/init.d/S50sshd ] && rm -f /etc/init.d/S50sshd
        [ -f /etc/init.d/S55date ] && rm -f /etc/init.d/S55date
        [ -f /bin/dropbearmulti ] && rm -f /bin/dropbearmulti
        [ -L /etc/init.d/S98camera ] && rm -f /etc/init.d/S98camera
        [ -f /etc/init.d/S98camera ] && rm -f /etc/init.d/S98camera

        check_link /bin/dropbearkey /opt/config/mod/.shell/eabi/dropbear
        check_link /bin/dropbear /opt/config/mod/.shell/eabi/dropbear
        check_link /bin/dbclient /opt/config/mod/.shell/eabi/dropbear
        check_link /bin/scp /opt/config/mod/.shell/eabi/dropbear
        check_link /bin/ssh /opt/config/mod/.shell/eabi/dropbear
        check_link /etc/init.d/S60dropbear /opt/config/mod/.shell/S60dropbear
        check_link /etc/init.d/S00fix /opt/config/mod/.shell/fix_config.sh
        check_link /etc/init.d/S99camera /opt/config/mod/.shell/S99camera
    fi

    check_link ${LOG_FILES}/zmod ${MOD_CONF}/mod_data/log/

    rm -f /usr/bin/audio /usr/bin/audio_midi.sh /usr/lib/python3.7/site-packages/audio.py
    [ -d ${PYTHON_DIR}/site-packages/mido ] && rm -rf ${PYTHON_DIR}/site-packages/mido
    [ -d ${PYTHON_DIR}/site-packages/mido-1.3.3.dist-info ] && rm -rf ${PYTHON_DIR}/site-packages/mido-1.3.3.dist-info
    check_link ${PYTHON_DIR}/site-packages/mido /opt/config/mod/.shell/root/mido/
    check_link ${PYTHON_DIR}/site-packages/mido-1.3.3.dist-info /opt/config/mod/.shell/root/mido-1.3.3.dist-info/

    NEED_REBOOT=0
    PRINTER_BASE_ORIG="${MOD_CONF}/printer.base.cfg"
    PRINTER_CFG_ORIG="${MOD_CONF}/printer.cfg"
    PRINTER_BASE="/tmp/printer.base.cfg"
    PRINTER_CFG="/tmp/printer.cfg"

    cp ${PRINTER_BASE_ORIG} ${PRINTER_BASE}
    cp ${PRINTER_CFG_ORIG} ${PRINTER_CFG}
    cat ${PRINTER_BASE}
    cat ${PRINTER_CFG}

    if ! [ -f ${MOD_CONF}/mod_data/power_off.sh ]; then
        echo "#!/bin/sh
unset LD_PRELOAD

#${CURL} -k https://mail.ru" >${MOD_CONF}/mod_data/power_off.sh
    fi
    chmod +x ${MOD_CONF}/mod_data/power_off.sh

    if ! [ -f ${MOD_CONF}/mod_data/power_on.sh ]; then
        echo "#!/bin/sh
#Enter Poweron code here" >${MOD_CONF}/mod_data/power_on.sh
    fi
    chmod +x ${MOD_CONF}/mod_data/power_on.sh

    # Rem стукач
    if grep -q "china_cloud = 0" ${MOD_CONF}/mod_data/variables.cfg; then
        if [ ${FF5X} -eq 0 ]; then
            china_block api.cloud.flashforge.com
            china_block api.fdmcloud.flashforge.com
            china_block cloud.sz3dp.com
            china_block hz.sz3dp.com
            china_block printer2.polar3d.com
            china_block qvs.qiniuapi.com
            china_block update.cn.sz3dp.com
            china_block update.sz3dp.com
            china_block cloud.sz3dp.com
            china_block polar3d.com
        else
            mount --bind /usr/data/config/mod/.shell/hosts /etc/hosts
        fi
    else
        if [ ${FF5X} -eq 0 ]; then
            china_razbl api.cloud.flashforge.com
            china_razbl api.fdmcloud.flashforge.com
            china_razbl cloud.sz3dp.com
            china_razbl hz.sz3dp.com
            china_razbl printer2.polar3d.com
            china_razbl qvs.qiniuapi.com
            china_razbl update.cn.sz3dp.com
            china_razbl update.sz3dp.com
            china_razbl cloud.sz3dp.com
            china_razbl polar3d.com
        fi
    fi

    grep -q "zmod 1.1" ${KLIPPER_DIR}/klippy/webhooks.py || cp ${MOD_CONF}/mod/.shell/webhooks.py ${KLIPPER_DIR}/klippy/webhooks.py
    grep -q ZLOAD_VARIABLE ${KLIPPER_DIR}/klippy/extras/save_variables.py || cp ${MOD_CONF}/mod/.shell/save_variables.py ${KLIPPER_DIR}/klippy/extras/save_variables.py
    if [ ${FF5X} -eq 0 ]; then
        if ! grep -q "Zcontrol 1.17" ${KLIPPER_DIR}/klippy/extras/spi_temperature.py; then
            cp ${MOD_CONF}/mod/.shell/spi_temperature.py ${KLIPPER_DIR}/klippy/extras/spi_temperature.py
        fi
        if ! grep -q "zmod 1.0" /opt/klipper/start.sh; then
            cp ${MOD_CONF}/mod/.shell/start.sh /opt/klipper/start.sh
        fi
    fi
    check_link ${KLIPPER_DIR}/klippy/extras/zmod.py ${MOD_CONF}/mod/.shell/zmod.py
    [ ${FF5X} -eq 1 ] && check_link ${KLIPPER_DIR}/klippy/extras/zmod_color.py ${MOD_CONF}/mod/.shell/zmod_color.py
    [ ${FF5X} -eq 1 ] && check_link ${KLIPPER_DIR}/klippy/extras/zmod_tenz.py ${MOD_CONF}/mod/.shell/zmod_tenz.py
    [ ${FF5X} -eq 1 ] && check_link ${KLIPPER_DIR}/klippy/extras/zmod_ifs_switch_sensor.py ${MOD_CONF}/mod/.shell/zmod_ifs_switch_sensor.py

    if [ ${FF5X} -eq 0 ]; then
        # Fix possible ordering issue if a callback blocks in button handler#6440
        grep -q receive_time ${KLIPPER_DIR}/klippy/extras/buttons.py || cp /opt/config/mod/.shell/buttons.py ${KLIPPER_DIR}/klippy/extras/buttons.py
    fi

    grep -q zmod_1.0 ${KLIPPER_DIR}/klippy/extras/gcode_shell_command.py || cp ${MOD_CONF}/mod/.shell/gcode_shell_command.py ${KLIPPER_DIR}/klippy/extras/gcode_shell_command.py
    if [ -L ${KLIPPER_DIR}/klippy/extras/load_cell_tare.py ] || [ -f ${KLIPPER_DIR}/klippy/extras/load_cell_tare.py ]; then
        rm -f ${KLIPPER_DIR}/klippy/extras/load_cell_tare.py
    fi

    [ "$(tail -c1 ${PRINTER_BASE})" != "" ] && echo >> ${PRINTER_BASE} && NEED_REBOOT=1
    if [ "$(tail -n2 "$PRINTER_BASE" | wc -l)" -lt 2 ] || [ "$(tail -n2 "$PRINTER_BASE" | grep -vc '^$')" -ne 0 ]; then
        echo >> "$PRINTER_BASE"
        NEED_REBOOT=1
    fi

    grep -q '^\[include check_md5.cfg\]' ${PRINTER_CFG} && sed -i '/^\[include check_md5.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1

    grep -q '^\[include ./mod/mod.cfg\]' ${PRINTER_CFG} && grep -q '^\[include ./mod/display_off.cfg\]' ${PRINTER_CFG} && sed -i '/^\[include .\/mod\/display_off.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1

    cnt=$(grep '^\[include ./mod_data/user.cfg\]' ${PRINTER_CFG} |wc -l)
    [ "$cnt" -gt 1 ] && sed -i '/^\[include .\/mod_data\/user.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1

    cnt=$(grep '^\[include ./mod/mod.cfg\]' ${PRINTER_CFG} |wc -l)
    [ "$cnt" -gt 1 ] && sed -i '/^\[include .\/mod\/mod.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1

    ! grep -q '^\[include ./mod/mod.cfg\]' ${PRINTER_CFG} && ! grep -q '^\[include ./mod/display_off.cfg\]' ${PRINTER_CFG} && sed -i '2 i\[include ./mod/mod.cfg]' ${PRINTER_CFG} && NEED_REBOOT=1

    grep -q '^\[include mod.user.cfg\]' ${PRINTER_CFG} && sed -i 's|^\[include mod.user.cfg\]|\[include ./mod_data/user.cfg\]|' ${PRINTER_CFG} && NEED_REBOOT=1

    ! grep -q '^\[include ./mod_data/user.cfg\]'  ${PRINTER_CFG} && sed -i '3 i\[include ./mod_data/user.cfg]' ${PRINTER_CFG} && NEED_REBOOT=1

    # Восстанавливаем настройки
    if grep -q "display_off = 1" ${MOD_CONF}/mod_data/variables.cfg; then
        grep -q '^\[include ./mod_data/user.cfg\]' ${PRINTER_CFG} && sed -i 's|\[include ./mod/mod.cfg\]|\[include ./mod/display_off.cfg\]|' ${PRINTER_CFG} && NEED_REBOOT=1
    fi

    if grep -q "display_off = 0" ${MOD_CONF}/mod_data/variables.cfg; then
        grep -q '^\[include ./mod/display_off.cfg\]' ${PRINTER_CFG} && sed -i 's|\[include ./mod/display_off.cfg\]|\[include ./mod/mod.cfg\]|' ${PRINTER_CFG} && NEED_REBOOT=1
    fi

    if ! grep -q '^\[heater_bed' ${PRINTER_CFG}
        then
            NEED_REBOOT=1
            cd ${MOD_CONF}

            # Copy and remove from printer.base.cfg
            if grep -q '^\[heater_bed' ${PRINTER_BASE}; then
                sed -e '/^\[heater_bed/,/^\[/d' ${PRINTER_BASE} >printer.base.tmp
                diff -u ${PRINTER_BASE} printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
                sed -i '$d' heater_bed.txt
                num=$(wc -l heater_bed.txt|cut  -d " " -f1)
                num=$(($num-1))
                sed -e "/^\[heater_bed/,+${num}d;" ${PRINTER_BASE} >printer.base.tmp
                cat printer.base.tmp >${PRINTER_BASE}
                rm -f printer.base.tmp
            else
                [ ${FF5X} -eq 0 ] && echo "[heater_bed]
heater_pin: PB9
sensor_type: Generic 3950
sensor_pin: PC3
pullup_resistor: 4700
control: pid
pid_Kp: 32.79
pid_Ki: 4.970
pid_Kd: 54.118
#control: watermark
#max_power: 1.0
min_temp: -100
max_temp: 130

" >heater_bed.txt
            [ ${FF5X} -eq 1 ] && echo "[heater_bed]
heater_pin: PB9
sensor_type: Generic 3950
sensor_pin: PA0
pullup_resistor: 4700
control: pid
pid_Kp: 32.79
pid_Ki: 4.970
pid_Kd: 54.118
#control: watermark
max_power: 0.4
min_temp: -100
max_temp: 130

" >heater_bed.txt
            fi

            num=$(cat -n ${PRINTER_CFG} |grep ./mod_data/user.cfg| awk '{print $1}')
            head -n $num ${PRINTER_CFG} >printer.tmp
            echo "" >>printer.tmp
            cat heater_bed.txt >>printer.tmp
            num=$(($num+1))
            tail -n +$num ${PRINTER_CFG} >>printer.tmp
            cat printer.tmp >${PRINTER_CFG}
            rm heater_bed.txt || echo "Not heater_bed.txt"
    fi

    if grep -q '^\[heater_bed' ${PRINTER_BASE}; then
            NEED_REBOOT=1
            cd ${MOD_CONF}

            sed -e '/^\[heater_bed/,/^\[/d' ${PRINTER_BASE} >printer.base.tmp
            diff -u ${PRINTER_BASE} printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
            sed -i '$d' heater_bed.txt
            num=$(wc -l heater_bed.txt|cut  -d " " -f1)
            num=$(($num-1))
            sed -e "/^\[heater_bed/,+${num}d;" ${PRINTER_BASE} >printer.base.tmp
            cat printer.base.tmp >${PRINTER_BASE}
            rm -f heater_bed.txt printer.base.tmp
    fi

    # Удаляем fan_generic pcb_fan
    if grep -q '^\[fan_generic pcb_fan' ${PRINTER_BASE}
        then
            NEED_REBOOT=1
            cd ${MOD_CONF}

            sed -e '/^\[fan_generic pcb_fan/,/^\[/d' ${PRINTER_BASE} >printer.base.tmp
            diff -u ${PRINTER_BASE} printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
            sed -i '$d' heater_bed.txt
            num=$(wc -l heater_bed.txt|cut  -d " " -f1)
            num=$(($num-1))
            sed -e "/^\[fan_generic pcb_fan/,+${num}d;" ${PRINTER_BASE} >printer.base.tmp
            cat printer.base.tmp >${PRINTER_BASE}
            rm -f heater_bed.txt printer.base.tmp
    fi

    # Удаляем controller_fan pcb_fan
    if grep -q '^\[controller_fan pcb_fan' ${PRINTER_BASE}
        then
            NEED_REBOOT=1
            cd ${MOD_CONF}

            sed -e '/^\[controller_fan pcb_fan/,/^\[/d' ${PRINTER_BASE} >printer.base.tmp
            diff -u ${PRINTER_BASE} printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
            sed -i '$d' heater_bed.txt
            num=$(wc -l heater_bed.txt|cut  -d " " -f1)
            num=$(($num-1))
            sed -e "/^\[controller_fan pcb_fan/,+${num}d;" ${PRINTER_BASE} >printer.base.tmp
            cat printer.base.tmp >${PRINTER_BASE}
            rm -f heater_bed.txt printer.base.tmp
    fi

    # Возвращаем gcode_button check_level_pin
    if [ ${FF5X} -eq 0 ] && ! grep -q '^\[gcode_button check_level_pin' ${PRINTER_BASE}
        then
            NEED_REBOOT=1
            cd ${MOD_CONF}

            echo '
[gcode_button check_level_pin]
pin: !PE0
press_gcode:
    M105
' >>${PRINTER_BASE}
    fi

    # Удаляем filament_switch_sensor e0_sensor
    if [ ${FF5X} -eq 0 ] && grep -q '^\[filament_switch_sensor e0_sensor' ${PRINTER_BASE}
        then
            NEED_REBOOT=1
            cd ${MOD_CONF}

            ! grep -q "motion_sensor" ${MOD_CONF}/mod_data/variables.cfg && sed -i '2 i\motion_sensor = 0' ${MOD_CONF}/mod_data/variables.cfg
            #sed -i "s/^motion_sensor.*/motion_sensor = 0/" ${MOD_CONF}/mod_data/variables.cfg

            sed -e '/^\[filament_switch_sensor e0_sensor/,/^\[/d' ${PRINTER_BASE} >printer.base.tmp
            diff -u ${PRINTER_BASE} printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
            sed -i '$d' heater_bed.txt
            num=$(wc -l heater_bed.txt|cut  -d " " -f1)
            num=$(($num-1))
            sed -e "/^\[filament_switch_sensor e0_sensor/,+${num}d;" ${PRINTER_BASE} >printer.base.tmp
            cat printer.base.tmp >${PRINTER_BASE}
            rm -f heater_bed.txt printer.base.tmp
    fi

    # Удаляем filament_motion_sensor e0_sensor
    if [ ${FF5X} -eq 0 ] && grep -q '^\[filament_motion_sensor e0_sensor' ${PRINTER_BASE}
        then
            NEED_REBOOT=1
            cd ${MOD_CONF}

            ! grep -q "motion_sensor" ${MOD_CONF}/mod_data/variables.cfg && sed -i '2 i\motion_sensor = 1' ${MOD_CONF}/mod_data/variables.cfg
            sed -i "s/^motion_sensor.*/motion_sensor = 1/" ${MOD_CONF}/mod_data/variables.cfg

            sed -e '/^\[filament_motion_sensor e0_sensor/,/^\[/d' ${PRINTER_BASE} >printer.base.tmp
            diff -u ${PRINTER_BASE} printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
            sed -i '$d' heater_bed.txt
            num=$(wc -l heater_bed.txt|cut  -d " " -f1)
            num=$(($num-1))
            sed -e "/^\[filament_motion_sensor e0_sensor/,+${num}d;" ${PRINTER_BASE} >printer.base.tmp
            cat printer.base.tmp >${PRINTER_BASE}
            rm -f heater_bed.txt printer.base.tmp
    fi

    # Добавляем controller_fan driver_fan
    [ ${FF5X} -eq 1 ] && PIN="PA5" || PIN="PB7"
    if grep -q '^\[controller_fan driver_fan' ${PRINTER_BASE}; then
        if ! grep -A1 '^\[controller_fan driver_fan' ${PRINTER_BASE} | grep -q "pin:${PIN}"; then
            # Удаляем controller_fan driver_fan
            cd ${MOD_CONF}
            sed -e '/^\[controller_fan driver_fan/,/^\[/d' ${PRINTER_BASE} >printer.base.tmp
            diff -u printer.base.cfg printer.base.tmp | grep -v "printer.base.cfg" |grep "^-" | cut -b 2- >heater_bed.txt
            sed -i '$d' heater_bed.txt
            num=$(wc -l heater_bed.txt|cut  -d " " -f1)
            num=$(($num-1))
            sed -e "/^\[controller_fan driver_fan/,+${num}d;" ${PRINTER_BASE} >printer.base.tmp
            cat printer.base.tmp >${PRINTER_BASE}
            rm -f heater_bed.txt printer.base.tmp
        fi
    fi
    if ! grep -q '^\[controller_fan driver_fan' ${PRINTER_BASE}; then
        NEED_REBOOT=1
        cd ${MOD_CONF}

        echo "
[controller_fan driver_fan]
pin:${PIN}
fan_speed: 1.0
idle_timeout: 30
stepper: stepper_x, stepper_y, stepper_z
" >>${PRINTER_BASE}
    fi

    # Klipper12 FIX
    if grep -q "klipper12 = 1" ${MOD_CONF}/mod_data/variables.cfg || [ ${FF5X} -eq 1 ]; then
        if grep -q '^max_accel_to_decel' ${PRINTER_BASE}; then
            NEED_REBOOT=1
            sed -i 's|^max_accel_to_decel.*|minimum_cruise_ratio: 0.5|' ${PRINTER_BASE}
        fi
    else
        if grep -q '^minimum_cruise_ratio' ${PRINTER_BASE}; then
            NEED_REBOOT=1
            sed -i 's|^minimum_cruise_ratio.*|max_accel_to_decel:5000|' ${PRINTER_BASE}
        fi
    fi

    if [ ${FF5X} -eq 0 ]; then
        ! grep -q "motion_sensor" ${MOD_CONF}/mod_data/variables.cfg && sed -i '2 i\motion_sensor = 0' ${MOD_CONF}/mod_data/variables.cfg

        # Режим с экраном
        if grep -q '^\[include ./mod/mod.cfg\]' ${PRINTER_CFG}; then
            grep -q '^\[include ./mod/switch_sensor_display_off.cfg\]' ${PRINTER_CFG} && sed -i '/^\[include .\/mod\/switch_sensor_display_off.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1
            if grep -q "motion_sensor = 1" ${MOD_CONF}/mod_data/variables.cfg; then
                ! grep -q '^\[include ./mod/motion_sensor.cfg\]'       ${PRINTER_CFG} && sed -i '/^\[include \.\/mod\/mod\.cfg\]/a [include ./mod/motion_sensor.cfg]' ${PRINTER_CFG} && NEED_REBOOT=1
                  grep -q '^\[include ./mod/switch_sensor.cfg\]'       ${PRINTER_CFG} && sed -i '/^\[include .\/mod\/switch_sensor.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1
            else
                ! grep -q '^\[include ./mod/switch_sensor.cfg\]'       ${PRINTER_CFG} && sed -i '/^\[include \.\/mod\/mod\.cfg\]/a [include ./mod/switch_sensor.cfg]' ${PRINTER_CFG} && NEED_REBOOT=1
                  grep -q '^\[include ./mod/motion_sensor.cfg\]'       ${PRINTER_CFG} && sed -i '/^\[include .\/mod\/motion_sensor.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1
            fi
        fi

        # Режим без экрана
        if grep -q '^\[include ./mod/display_off.cfg\]' ${PRINTER_CFG}; then
            grep -q '^\[include ./mod/switch_sensor.cfg\]'                   ${PRINTER_CFG} && sed -i '/^\[include .\/mod\/switch_sensor.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1
            if grep -q "motion_sensor = 1" ${MOD_CONF}/mod_data/variables.cfg; then
                ! grep -q '^\[include ./mod/motion_sensor.cfg\]' ${PRINTER_CFG} && sed -i '/^\[include \.\/mod\/display_off\.cfg\]/a [include ./mod/motion_sensor.cfg]' ${PRINTER_CFG} && NEED_REBOOT=1
                  grep -q '^\[include ./mod/switch_sensor_display_off.cfg\]' ${PRINTER_CFG} && sed -i '/^\[include .\/mod\/switch_sensor_display_off.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1
            else
                ! grep -q '^\[include ./mod/switch_sensor_display_off.cfg\]' ${PRINTER_CFG} && sed -i '/^\[include \.\/mod\/display_off\.cfg\]/a [include ./mod/switch_sensor_display_off.cfg]' ${PRINTER_CFG} && NEED_REBOOT=1
                  grep -q '^\[include ./mod/motion_sensor.cfg\]'             ${PRINTER_CFG} && sed -i '/^\[include .\/mod\/motion_sensor.cfg\]/d' ${PRINTER_CFG} && NEED_REBOOT=1
            fi
        fi
    fi

    [ "$(tail -c1 ${PRINTER_BASE})" != "" ] && echo >> ${PRINTER_BASE} && NEED_REBOOT=1
    if [ "$(tail -n2 "$PRINTER_BASE" | wc -l)" -lt 2 ] || [ "$(tail -n2 "$PRINTER_BASE" | grep -vc '^$')" -ne 0 ]; then
        echo >> "$PRINTER_BASE"
        NEED_REBOOT=1
    fi
    awk 'NF {last = NR} {lines[NR] = $0} END {for (i=1; i<=last; i++) print lines[i]}' ${PRINTER_CFG} >${PRINTER_CFG}.save
    if ! diff ${PRINTER_CFG} ${PRINTER_CFG}.save; then
        mv ${PRINTER_CFG}.save ${PRINTER_CFG}
        NEED_REBOOT=1
    else
        rm ${PRINTER_CFG}.save
    fi

    if [ -f ${MOD_CONF}/mod_data/mesh_data.cfg ]; then
        FIND_STR=$(cat ${MOD_CONF}/mod_data/mesh_data.cfg |grep bed_mesh|sed 's/\[/\\[/g; s/\]/\\]/g')
        if ! grep "$FIND_STR" ${PRINTER_CFG}; then
            NEED_REBOOT=1
            cat ${MOD_CONF}/mod_data/mesh_data.cfg >>${PRINTER_CFG}
        fi
        rm -f ${MOD_CONF}/mod_data/mesh_data.cfg
    fi

    if [ ${NEED_REBOOT} -eq 1 ]
        then
            echo "Kill firmwareExe"
            sync
            [ ${FF5X} -eq 0 ] && killall firmwareExe
            sync
            sync
            diff -u ${PRINTER_BASE_ORIG} ${PRINTER_BASE}
            diff -u ${PRINTER_CFG_ORIG} ${PRINTER_CFG}
            cat ${PRINTER_BASE} >${PRINTER_BASE_ORIG}
            sync
            cat ${PRINTER_CFG} >${PRINTER_CFG_ORIG}
            sync
        else
            diff -u ${PRINTER_BASE_ORIG} ${PRINTER_BASE}
            diff -u ${PRINTER_CFG_ORIG} ${PRINTER_CFG}
    fi
    echo "END fix_config"

#    if [ "$1" == "start" ] && [ ${FF5X} -eq 0 ]; then
#        if grep -q "klipper12 = 1" ${MOD_CONF}/mod_data/variables.cfg; then
#            cnt=$(find /opt/PROGRAM/control/ -name Update|wc -l)
#            if [ "$cnt" -ne 0 ]; then
#                # Если обновляем MCU
#                find /opt/PROGRAM/control/ -name Update| sed 's/Update//'| while read a; do
#                    mount -o bind ${MOD_CONF}/mod/.shell/update_mcu.sh ${a}run.sh
#                done
#            else
#                # Если обновлений нет
#                mount -o bind ${MOD_CONF}/mod/.shell/klipper12.sh ${KLIPPER_DIR}/start.sh
#                sync
#            fi
#        else
#            A=$(find /opt/PROGRAM/control/ -name NationsCommand |head -1)
#            $A -r || $A -r
#        fi
#    fi
    sync
}

mkdir -p ${MOD_CONF}/mod_data/log/

mv ${MOD_CONF}/mod_data/log/fix_config.4.log ${MOD_CONF}/mod_data/log/fix_config.5.log
mv ${MOD_CONF}/mod_data/log/fix_config.3.log ${MOD_CONF}/mod_data/log/fix_config.4.log
mv ${MOD_CONF}/mod_data/log/fix_config.2.log ${MOD_CONF}/mod_data/log/fix_config.3.log
mv ${MOD_CONF}/mod_data/log/fix_config.1.log ${MOD_CONF}/mod_data/log/fix_config.2.log
mv ${MOD_CONF}/mod_data/log/fix_config.log   ${MOD_CONF}/mod_data/log/fix_config.1.log

if [ -f ${MOD_CONF}/mod/SKIP_ZMOD ] || [ -f ${MOD_CONF}/mod/REMOVE ] || [ -f ${MOD_CONF}/mod/FULL_REMOVE ]; then
    restore_base &>${MOD_CONF}/mod_data/log/fix_config.log
else
    fix_config "$1" &>${MOD_CONF}/mod_data/log/fix_config.log
fi

sync
