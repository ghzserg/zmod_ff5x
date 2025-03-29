#!/bin/sh

source /opt/config/mod/.shell/0.sh

# Более точный замер времени - Alexander
if [ $# -ne 2 ] && [ $# -ne 3 ] && [ $# -ne 4 ]; then
    [ ${ZLANG} == 'en' ] && echo "Use $0 SIZE [SYNC] [FLASH] [RANDOM]\nhttps://github.com/ghzserg/zmod/wiki/Macros_en#test_emmc" || echo "Используйте $0 SIZE [SYNC] [FLASH] [RANDOM]\nhttps://github.com/ghzserg/zmod/wiki/Macros#test_emmc"
    exit 1
fi

SIZE=$1
FILE="${DATA_GCODES}"
INFILE="/dev/zero"
t3=0

[ "$3" == "1" ] && FILE="/media" && [ ${ZLANG} == 'en' ] && echo "Testing USB FLASH" || echo "Тестирование USB FLASH"
[ "$3" == "2" ] && FILE="/tmp" && [ ${ZLANG} == 'en' ] && echo "Testing RAM" || echo "Тестирование RAM"

if [ "$FILE" == "${DATA_GCODES}" ]; then
    life=$(cat /sys/block/mmcblk0/device/life_time | awk '{print $1}'| while read a; do printf "%d0" $a; done;)
    [ ${ZLANG} == 'en' ] && echo "EMMC wear: $life%" || echo "Износ EMMC: $life%"
fi

if [ "$4" == "1" ]; then
    INFILE="/dev/urandom"
    [ ${ZLANG} == 'en' ] && echo "Testing with random data" || echo "Тестирование случайными данными"
    read up rest </proc/uptime; t1="${up%.*}${up#*.}"
    dd if=$INFILE of=/dev/null bs=1M count=${SIZE} status=none
    read up rest </proc/uptime; t2="${up%.*}${up#*.}"
    dd if=/dev/zero of=/dev/null bs=1M count=${SIZE} status=none
    read up rest </proc/uptime; t0="${up%.*}${up#*.}"
    t3=$(( (2*t2-t1-t0) ))
fi

FREE_SPACE=$(df $FILE 2>/dev/null|grep -v /dev/root|grep -v Filesystem| tail -1 | tr -s ' ' | cut -d' ' -f4)
MIN_SPACE=$(($SIZE*1024))
if [ "$FREE_SPACE" == "" ] || [ "$FREE_SPACE" -lt "$MIN_SPACE" ]; then
    [ ${ZLANG} == 'en' ] && echo "Not enough free space to write $SIZE MB" || echo "Не хватает свободного места на запись $SIZE MB"
    exit 0
fi

FILE="$FILE/test.img"

if [ "$2" == "0" ]; then
    [ ${ZLANG} == 'en' ] && echo "Writing ${SIZE} MB in background" || echo "В фоне будет записано ${SIZE} MB"
    dd if=$INFILE of=$FILE bs=1M count=${SIZE} conv=fsync status=none 2>/dev/null &
else
    [ ${ZLANG} == 'en' ] && echo "Testing write/read of ${SIZE} MB data. Please wait..." || echo "Идет тестирование записи/чтения ${SIZE} MB данных. Ждите..."

    read up rest </proc/uptime; t1="${up%.*}${up#*.}"
    dd if=$INFILE of=$FILE bs=1M count=${SIZE} conv=fsync status=none 2>/dev/null
    read up rest </proc/uptime; t2="${up%.*}${up#*.}"
    TIME_W=$(( 10*(t2-t1-t3) ))

    read up rest </proc/uptime; t1="${up%.*}${up#*.}"
    dd if=$FILE of=/dev/null bs=1M count=${SIZE} conv=fsync status=none 2>/dev/null
    read up rest </proc/uptime; t2="${up%.*}${up#*.}"
    TIME_R=$(( 10*(t2-t1) ))

    rm -f $FILE

    if [ ${ZLANG} == 'en' ]; then
        awk "BEGIN {print \"Written $SIZE MB. Write speed: \" ($SIZE * 1000 / $TIME_W) \" MB/s. Read speed: \" ($SIZE * 1000 / $TIME_R) \" MB/s.\"}"
    else
        awk "BEGIN {print \"Записано $SIZE MB. Запись: \" ($SIZE * 1000 / $TIME_W) \" MB/s. Чтение: \" ($SIZE * 1000 / $TIME_R) \" MB/s.\"}"
    fi
fi
