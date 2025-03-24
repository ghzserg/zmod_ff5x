#!/bin/sh

if ! mount |grep media >/dev/null; then
    echo "Флешка не подключена. Вставьте флешку и перезагрузите принтер."
    exit 1
fi

source /opt/config/mod/.shell/0.sh

if [ ${FF5X} -eq 1 ]; then
    export LD_LIBRARY_PATH=//usr/prog/qt-4.8.6/lib:$LD_LIBRARY_PATH
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

MACHINE="Неизвестная машина"
[ -f /opt/auto_run.sh ] && grep -q '^MACHINE=Adventurer5MPro$' /opt/auto_run.sh && MACHINE=Adventurer5MPro
[ -f /opt/auto_run.sh ] && grep -q '^MACHINE=Adventurer5M$' /opt/auto_run.sh && MACHINE=Adventurer5M
[ -f /usr/prog/app_startup.sh ] && grep -q "^MACHINE=AD5X" /usr/prog/app_startup.sh && MACHINE=AD5X

if [ "${MACHINE}" == "Неизвестная машина" ]; then echo "Не удалось определить модель принетра"; exit 1; fi

ZMOD_VERSION="0.0.0"
rm -f /tmp/version.txt
if ! ${CURL} -k -s -o "/tmp/version.txt" -L "https://github.com/ghzserg/zmod/releases/latest/download/version.txt"; then echo "Не удалось получить последнюю версию"; exit 1; fi

source /tmp/version.txt
echo "Скачиваю версию ${ZMOD_VERSION} для принтера ${MACHINE}. Это займет немало времени..."
rm -f "/media/${MACHINE}-zmod-${ZMOD_VERSION}.tgz"
if ! ${CURL} -k -o "/media/${MACHINE}-zmod-${ZMOD_VERSION}.tgz" -L "https://github.com/ghzserg/zmod/releases/latest/download/${MACHINE}-zmod-${ZMOD_VERSION}.tgz"; then
    rm -f "/media/${MACHINE}-zmod-${ZMOD_VERSION}.tgz"
    echo "Не удалось получить версию ${ZMOD_VERSION} для принтера ${MACHINE}"
    exit 1
fi
sync

rm -f "/media/${MACHINE}.txt"
echo "Скачиваю контрольную сумму ${ZMOD_VERSION} для принтера ${MACHINE}. Это быстро."
if ! ${CURL} -k -s -o "/media/${MACHINE}.txt" -L "https://github.com/ghzserg/zmod/releases/latest/download/${MACHINE}.txt"; then
    rm -f "/media/${MACHINE}-zmod-${ZMOD_VERSION}.tgz"
    rm -f "/media/${MACHINE}.txt"
    echo "Не удалось получить контрольную сумму версии ${ZMOD_VERSION} для принтера ${MACHINE}"
    exit 1
fi
sync

cd /media
echo "Проверяю контрольную сумму версии ${ZMOD_VERSION} для принтера ${MACHINE}. Это не очень долго."
if ! md5sum -c ${MACHINE}.txt; then
    rm -f "/media/${MACHINE}-zmod-${ZMOD_VERSION}.tgz"
    rm -f "/media/${MACHINE}.txt"
    echo "Контрольная сумма не совпала. Файл поврежден."
    exit 1
fi
sync

echo "Все проверки выполнены. Принтер будет перезагружен"
sync
sleep 20
sync
echo "REBOOT" >/tmp/printer
