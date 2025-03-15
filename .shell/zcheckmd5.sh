#!/bin/sh

source /opt/config/mod/.shell/0.sh

if [ -f /ZMOD ]; then
    DIR="/opt/config/mod/.shell/root"
else
    DIR="/opt/config/mod/.shell"
fi

if [ ${FF5X} -eq 1 ]; then
    STOCK="stock5x"
    export LD_LIBRARY_PATH=/usr/prog/curl-7.55.1-https/lib:$LD_LIBRARY_PATH
else
    STOCK="stock"
fi

restore_file()
{
    fname="$1"
    /bin/echo -n "Восстанавливаю файл $fname: "
    if ${CURL} --create-dirs -s -k -H 'Accept: application/vnd.github.v3.raw' -o "$fname" -L "https://api.github.com/repos/ghzserg/zmod/contents/${STOCK}${fname}"; then
        chmod 777 "$fname"
        echo "Успешно"
    else
        echo "Ошибка восстановления"
    fi
}

if ! [ -f /ZMOD ]; then
    echo "Началась проверка родной системы. Она может занять много времени..."
    find ${PROGRAM_DIR} -name md5sum.list | while read a;
    do
        b=$(pwd)
        c=$(echo $a|sed 's/md5sum.list//')
        echo "$c"
        cd "$c"
        if echo $c | grep -q control; then
            touch Update
        fi
        md5sum -c md5sum.list 2>/dev/null | grep -v -e "OK$"
        if echo $c | grep -q control; then
            rm -f Update
        fi
        cd "$b"
    done
else
    echo "Началась проверка ZMOD. Она может занять много времени..."
fi

echo "/"
cd /
FF_VERSION="$(cat /root/version 2>/dev/null)"
MIN_VERSION="3.1.3"
if [ ${FF5X} -eq 0 ] && ! [ -f /ZMOD ] && [ "${FF_VERSION//./}" -lt "${MIN_VERSION//./}" ]; then
    sed '/\/nim\//d' ${DIR}/md5sum.list >${DIR}/md5sum_nim.list
    md5sum -c ${DIR}/md5sum_nim.list 2>/dev/null | grep -v -e "OK$" | tee /opt/config/mod_data/bad.list
    rm -f ${DIR}/md5sum_nim.list
else
    md5sum -c ${DIR}/md5sum.list 2>/dev/null | grep -v -e "OK$" | tee /opt/config/mod_data/bad.list
fi

cnt=$(cat /opt/config/mod_data/bad.list|grep ": FAILED$"| wc -l)
if [ "$cnt" -ne 0 ]; then
    if [ -f /ZMOD ]; then
        echo "Найдены повреждения ZMOD. Переустановите мод с флешки"
    else
        if [ "$1" == "restore" ]; then
            cat /opt/config/mod_data/bad.list|grep ": FAILED$"|sed 's|: FAILED||' | sed 's|^./|/|' | while read a; do restore_file "$a"; done
        else
            echo "Найдены повреждения родной прошивки. Можно попробовать восстановить: CHECK_SYSTEM RESTORE=1"
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
    ${DIR}/list.link 2>/dev/null
fi

if ! [ -f /ZMOD ]; then
    echo "Оригиналы файлов можно найти по ссылке https://github.com/ghzserg/zmod/tree/main/${STOCK}"
    echo "Проверка родной системы окончена"
    [ ${FF5X} -eq 0 ] && [ "$1" != "init" ] && umount ${UMOUNT_MOD}
    unset LD_PRELOAD
    chroot ${MOD} /opt/config/mod/.shell/zcheckmd5.sh
    [ ${FF5X} -eq 0 ] && [ "$1" != "init" ] && mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
else
    cd /opt/config/mod
    git clean -f
    git restore .
    git status --porcelain
    echo "Самопроверка ZMOD окончена"
fi
