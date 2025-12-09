#!/bin/sh

if [ -f /opt/config/mod/.shell/0.sh ]; then
    source /opt/config/mod/.shell/0.sh
else if [ -f /usr/data/config/mod/.shell/0.sh ]; then
    source /usr/data/config/mod/.shell/0.sh
fi
fi

if [ ${FF5X} -eq 1 ]; then
    export LD_LIBRARY_PATH=/usr/prog/qt-4.8.6/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/openssl-1.0.2d/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/curl-7.55.1-https/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/ffmpeg-4.0.2/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/x264/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/libffi-3.4.4/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/opencv-4.2.0_mips/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/libzip-1.10.1/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/nim/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/Python-3.8.2/lib:$LD_LIBRARY_PATH
fi

if [ -f /ZMOD ]; then
    DIR="/opt/config/mod/.shell/root"
    if [ "$2" == "1" ]; then
        /opt/config/mod/.shell/zremote.sh "/opt/config/mod/.shell/zcheckmd5.sh $1"
        exit 0
    fi
else
    DIR="/opt/config/mod/.shell"
fi

if [ ${FF5X} -eq 1 ]; then
    STOCK="stock5x"
    export LD_LIBRARY_PATH=/usr/prog/curl-7.55.1-https/lib:$LD_LIBRARY_PATH
else
    STOCK="stock"
fi

check_link()
{
    a=$(readlink "$1" 2>/dev/null)
    if [ "$a" != "$2" ]; then
        /bin/echo -n "$1 - Incorrect link ($a!=$2): "
        rm -f "$1" 2>/dev/null
        ln -s "$2" "$1" 2>/dev/null && echo "Исправлено"  || echo "Ошибка исправления"
    fi
}

restore_file()
{
    fname="$1"
    [ ${ZLANG} != 'ru' ] && /bin/echo -n "Recovering file" || /bin/echo -n "Восстанавливаю файл $fname: "
    if ${CURL} --create-dirs -s -k -H 'Accept: application/vnd.github.v3.raw' -o "$fname" -L "https://api.github.com/repos/ghzserg/zmod/contents/${STOCK}${fname}"; then
        chmod 777 "$fname"
        [ ${ZLANG} != 'ru' ] && echo "Ok" || echo "Успешно"
    else
        [ ${ZLANG} != 'ru' ] && echo "Recovery error" || echo "Ошибка восстановления"
    fi
}

if ! [ -f /ZMOD ]; then
    [ ${ZLANG} != 'ru' ] && echo "Native system check started. It may take a long time" || echo "Началась проверка родной системы. Она может занять много времени..."
    find ${PROGRAM_DIR} -name md5sum.list | while read a;
    do
        b=$(pwd)
        c=$(echo $a|sed 's/md5sum.list//')
        echo "$c"
        cd "$c"
        if echo $c | grep -q control; then
            touch Update
            [ ${FF5X} -eq 1 ] && touch UpdateM
        fi
        md5sum -c md5sum.list 2>/dev/null | grep -v -e "OK$"
        if echo $c | grep -q control; then
            rm -f Update
            [ ${FF5X} -eq 1 ] && rm -f UpdateM
        fi
        cd "$b"
    done
else
    [ ${ZLANG} != 'ru' ] && echo "ZMOD system check started. It may take a long time" || echo "Началась проверка ZMOD. Она может занять много времени..."
fi

echo "/"
cd /
[ ${FF5X} -eq 0 ] && FF_VERSION=$(cat /root/version 2>/dev/null)
[ ${FF5X} -eq 1 ] && FF_VERSION=$(find /usr/prog/PROGRAM/software/ -type d 2>/dev/null | sed 's|/usr/prog/PROGRAM/software/||' | grep . 2>/dev/null)
MIN_VERSION="3.1.3"
MIN_VERSION_X="1.0.7"
if [ ${FF5X} -eq 0 ] && ! [ -f /ZMOD ] && [ "${FF_VERSION//./}" -lt "${MIN_VERSION//./}" ]; then
    sed '/\/nim\//d' ${DIR}/md5sum.list >${DIR}/md5sum_nim.list
    md5sum -c ${DIR}/md5sum_nim.list 2>/dev/null | grep -v -e "OK$" | tee /opt/config/mod_data/bad.list
    rm -f ${DIR}/md5sum_nim.list
else
    if [ ${FF5X} -eq 1 ] && ! [ -f /ZMOD ] && [ "${FF_VERSION//./}" -ge "${MIN_VERSION_X//./}" ]; then
        sed '/\/moonraker/d' ${DIR}/md5sum.list | sed '/\/mainsail\//d'| sed '/\/dhcpcd.conf/d'| sed '/\/S41dhcpcd/d'| sed '/\/nginx\//d' >${DIR}/md5sum_5x.list
        md5sum -c ${DIR}/md5sum_5x.list 2>/dev/null | grep -v -e "OK$" | tee /opt/config/mod_data/bad.list
        rm -f ${DIR}/md5sum_5x.list
    else
        md5sum -c ${DIR}/md5sum.list 2>/dev/null | grep -v -e "OK$" | tee /opt/config/mod_data/bad.list
    fi
fi

cnt=$(cat /opt/config/mod_data/bad.list|grep ": FAILED$"| wc -l)
if [ "$cnt" -ne 0 ]; then
    if [ -f /ZMOD ]; then
        [ ${ZLANG} != 'ru' ] && echo "Damage to ZMOD found. Reinstall the mod from a flash drive. ZFLASH" || echo "Найдены повреждения ZMOD. Переустановите мод с флешки. ZFLASH"
    else
        if [ "$1" == "restore" ]; then
            cat /opt/config/mod_data/bad.list|grep ": FAILED$"|sed 's|: FAILED||' | sed 's|^./|/|' | while read a; do restore_file "$a"; done
        else
            [ ${ZLANG} != 'ru' ] && echo "Found damage to the original firmware. You can try to restore: CHECK_SYSTEM RESTORE=1" || echo "Найдены повреждения родной прошивки. Можно попробовать восстановить: CHECK_SYSTEM RESTORE=1"
        fi
    fi
fi
rm -f /opt/config/mod_data/bad.list

if [ ${FF5X} -eq 0 ] && ! [ -f /ZMOD ] && [ "${FF_VERSION//./}" -lt "${MIN_VERSION//./}" ]; then
    sed '/\/nim\//d' ${DIR}/list.link >${DIR}/md5sum_nim.list
    chmod +x ${DIR}/md5sum_nim.list
    ${DIR}/md5sum_nim.list 2>/dev/null
    rm -f ${DIR}/md5sum_nim.list
else
    if [ ${FF5X} -eq 1 ] && ! [ -f /ZMOD ] && [ "${FF_VERSION//./}" -ge "${MIN_VERSION_X//./}" ]; then
        sed '/\/moonraker/d' ${DIR}/list.link | sed '/\/mainsail\//d'| sed '/\/nginx\//d' >${DIR}/md5sum_5x.list
        chmod +x ${DIR}/md5sum_5x.list
        ${DIR}/md5sum_5x.list 2>/dev/null
        rm -f ${DIR}/md5sum_5x.list
    else
        ${DIR}/list.link 2>/dev/null
    fi
fi

if ! [ -f /ZMOD ]; then
    [ ${ZLANG} != 'ru' ] && echo "The original files can be found at https://github.com/ghzserg/zmod/tree/main/${STOCK}" || echo "Оригиналы файлов можно найти по ссылке https://github.com/ghzserg/zmod/tree/main/${STOCK}"
    [ ${ZLANG} != 'ru' ] && echo "Native system check completed" || echo "Проверка родной системы окончена"
    [ ${FF5X} -eq 0 ] && [ "$1" != "init" ] && umount ${UMOUNT_MOD}
    unset LD_PRELOAD
    chroot ${MOD} /opt/config/mod/.shell/zcheckmd5.sh
    [ ${FF5X} -eq 0 ] && [ "$1" != "init" ] && mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
else
    cd /opt/config/mod
    git clean -f
    git restore .
    git status --porcelain

    [ ${ZLANG} != 'ru' ] && echo "Restoring the correct ZMOD language" || echo "Восстановление правильного языка ZMOD"
    check_link ${MOD_CONF}/mod/base.cfg ${ZLANG}/base.cfg &>/dev/null
    check_link ${MOD_CONF}/mod/client.cfg ${ZLANG}/client.cfg &>/dev/null
    check_link ${MOD_CONF}/mod/klipper13_base.cfg ${ZLANG}/klipper13_base.cfg &>/dev/null
    if [ ${FF5X} -eq 0 ]; then
        check_link ${MOD_CONF}/mod/klipper13.cfg ${ZLANG}/klipper13_ff5m.cfg &>/dev/null
        check_link ${MOD_CONF}/mod/klipper11_base.cfg ${ZLANG}/klipper11_base.cfg &>/dev/null
        grep -q 'Adventurer5MPro' /etc/os-release && check_link ${MOD_CONF}/mod/klipper11.cfg ${ZLANG}/klipper11_pro.cfg &>/dev/null || check_link ${MOD_CONF}/mod/klipper11.cfg ${ZLANG}/klipper11.cfg &>/dev/null
        check_link ${MOD_CONF}/mod/display_off.cfg ${ZLANG}/display_off.cfg &>/dev/null
        check_link ${MOD_CONF}/mod/ff5.cfg ${ZLANG}/ff5.cfg &>/dev/null
        check_link ${MOD_CONF}/mod/mod.cfg ${ZLANG}/mod.cfg &>/dev/null
    else
        check_link ${MOD_CONF}/mod/klipper13.cfg ${ZLANG}/klipper13_ad5x.cfg &>/dev/null
        check_link ${MOD_CONF}/mod/display_off.cfg ${ZLANG}/ad5x_display_off.cfg &>/dev/null
        check_link ${MOD_CONF}/mod/base_display_off.cfg ${ZLANG}/display_off.cfg &>/dev/null
        check_link ${MOD_CONF}/mod/ad5x.cfg ${ZLANG}/ad5x.cfg &>/dev/null
        check_link ${MOD_CONF}/mod/base_mod.cfg ${ZLANG}/mod.cfg &>/dev/null
    fi
    check_link ${MOD_CONF}/mod/motion_sensor.cfg ${ZLANG}/motion_sensor.cfg &>/dev/null
    check_link ${MOD_CONF}/mod/switch_sensor_display_off.cfg ${ZLANG}/switch_sensor_display_off.cfg &>/dev/null

    [ ${ZLANG} != 'ru' ] && echo "ZMOD self-test completed" || echo "Самопроверка ZMOD окончена"
fi
