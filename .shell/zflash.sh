#!/bin/sh

if ! mount |grep media >/dev/null; then
    [ ${ZLANG} != 'ru' ] && echo "Flash drive not connected. Insert the flash drive and restart the printer." || echo "Флешка не подключена. Вставьте флешку и перезагрузите принтер."
    exit 1
fi

if [ -f /ZMOD ]; then
    /opt/config/mod/.shell/zremote.sh /opt/config/mod/.shell/zflash.sh
    exit 0
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

if [ "${MACHINE}" == "Неизвестная машина" ]; then
    [ ${ZLANG} != 'ru' ] && echo "Failed to determine printer model" || echo "Не удалось определить модель принетра"
    exit 1
fi

ZMOD_VERSION="0.0.0"
rm -f /tmp/version.txt
if ! ${CURL} -k -s -o "/tmp/version.txt" -L "https://github.com/ghzserg/zmod/releases/latest/download/version.txt"; then
    [ ${ZLANG} != 'ru' ] && echo "Failed to retrieve the latest version" || echo "Не удалось получить последнюю версию"
    exit 1
fi

source /tmp/version.txt
[ ${ZLANG} != 'ru' ] && echo "Downloading version ${ZMOD_VERSION} for printer ${MACHINE}. This may take a while..." || echo "Скачиваю версию ${ZMOD_VERSION} для принтера ${MACHINE}. Это займет немало времени..."

rm -f "/media/${MACHINE}-zmod-${ZMOD_VERSION}.tgz"
if ! ${CURL} -k -o "/media/${MACHINE}-zmod-${ZMOD_VERSION}.tgz" -L "https://github.com/ghzserg/zmod/releases/latest/download/${MACHINE}-zmod-${ZMOD_VERSION}.tgz"; then
    rm -f "/media/${MACHINE}-zmod-${ZMOD_VERSION}.tgz"
    [ ${ZLANG} != 'ru' ] && echo "Failed to download version ${ZMOD_VERSION} for printer ${MACHINE}" || echo "Не удалось получить версию ${ZMOD_VERSION} для принтера ${MACHINE}"
    exit 1
fi
sync

rm -f "/media/${MACHINE}.txt"
[ ${ZLANG} != 'ru' ] && echo "Downloading checksum for version ${ZMOD_VERSION} of printer ${MACHINE}. This will be quick." || echo "Скачиваю контрольную сумму ${ZMOD_VERSION} для принтера ${MACHINE}. Это быстро."

if ! ${CURL} -k -s -o "/media/${MACHINE}.txt" -L "https://github.com/ghzserg/zmod/releases/latest/download/${MACHINE}.txt"; then
    rm -f "/media/${MACHINE}-zmod-${ZMOD_VERSION}.tgz"
    rm -f "/media/${MACHINE}.txt"
    [ ${ZLANG} != 'ru' ] && echo "Failed to download checksum for version ${ZMOD_VERSION} of printer ${MACHINE}" || echo "Не удалось получить контрольную сумму версии ${ZMOD_VERSION} для принтера ${MACHINE}"
    exit 1
fi
sync

cd /media
[ ${ZLANG} != 'ru' ] && echo "Verifying checksum for version ${ZMOD_VERSION} of printer ${MACHINE}. This won't take too long." || echo "Проверяю контрольную сумму версии ${ZMOD_VERSION} для принтера ${MACHINE}. Это не очень долго."

if ! md5sum -c ${MACHINE}.txt; then
    rm -f "/media/${MACHINE}-zmod-${ZMOD_VERSION}.tgz"
    rm -f "/media/${MACHINE}.txt"
    [ ${ZLANG} != 'ru' ] && echo "Checksum mismatch. The file is corrupted." || echo "Контрольная сумма не совпала. Файл поврежден."
    exit 1
fi
sync

[ ${ZLANG} != 'ru' ] && echo "All checks passed. The printer will reboot" || echo "Все проверки выполнены. Принтер будет перезагружен"
sync
sleep 20
sync
echo "REBOOT" >/tmp/printer
