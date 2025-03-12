#!/bin/sh

# "lanCode"
# "printerSerialNumber"
# Adventurer5M.json

source /opt/config/mod/.shell/0.sh

if [ $# -ne 2 ]; then echo "Используйте $0 PRINT|CLOSE FILE"; exit 1; fi

if [ -f /ZMOD ]; then
    CCURL="/usr/bin/curl"
else
    if [ ${FF5X} -eq 1 ] then
        export LD_LIBRARY_PATH=//usr/prog/qt-4.8.6/lib:$LD_LIBRARY_PATH
        export LD_LIBRARY_PATH=/usr/prog/openssl-1.0.2d/lib:$LD_LIBRARY_PATH
        export LD_LIBRARY_PATH=/usr/prog/curl-7.55.1-https/lib:$LD_LIBRARY_PATH
        export LD_LIBRARY_PATH=/usr/prog/ffmpeg-4.0.2/lib:$LD_LIBRARY_PATH
        export LD_LIBRARY_PATH=/usr/prog/x264/lib:$LD_LIBRARY_PATH
        export LD_LIBRARY_PATH=/usr/prog/libffi-3.4.4/lib:$LD_LIBRARY_PATH
        export LD_LIBRARY_PATH=/usr/prog/opencv-4.2.0_mips/lib:$LD_LIBRARY_PATH
        export LD_LIBRARY_PATH=/usr/prog/libzip-1.10.1/lib:$LD_LIBRARY_PATH
        export LD_LIBRARY_PATH=/usr/prog/nim/lib:$LD_LIBRARY_PATH
        export LD_PRELOAD=/usr/prog/curl-7.55.1-https/lib
    fi
    CCURL="${CURL}"
fi

ip=$(ip addr | grep inet | grep wlan0 | awk -F" " '{print $2}'| sed -e 's/\/.*$//')
if [ "$ip" == "" ]; then ip=$(ip addr | grep inet | grep eth0 | awk -F" " '{print $2}'| sed -e 's/\/.*$//'); fi

serialNumber=$(cat /opt/config/Adventurer5M.json | grep "printerSerialNumber"| cut  -d ":" -f2| awk '{print $1}' | sed 's|[",]||g')
checkCode=$(cat /opt/config/Adventurer5M.json | grep "lanCode"| cut  -d ":" -f2| awk '{print $1}' | sed 's|[",]||g')

if [ "$1" == "CLOSE" ]; then
    ${CCURL} -m 60 -s \
        http://$ip:8898/control \
        -H 'Content-Type: application/json' \
        -d "{\"serialNumber\":\"$serialNumber\",\"checkCode\":\"$checkCode\",\"payload\":{\"cmd\":\"stateCtrl_cmd\",\"args\":{\"action\":\"setClearPlatform\"}}}" || \
    echo "Нет ответа от принтера с IP $ip. Необходимо настроить принтер. На экране принтера: \"Настройки\" -> \"Иконка WiFi\" -> \"Сетевой режим\" -> включить ползунок \"Только локальные сети\""
else
    if [ "$1" == "PRINT" ]; then
        if ! [ -f "${DATA_GCODES}/$2" ]; then
            echo "RESPOND TYPE=error MSG=\"Файл $2 не найден.\"" >/tmp/printer
            echo "CANCEL_PRINT" >/tmp/printer
            exit 1
        fi

        ${CCURL} -m 60 -s \
            http://$ip:8898/printGcode \
            -H 'Content-Type: application/json' \
            -d "{\"serialNumber\":\"$serialNumber\",\"checkCode\":\"$checkCode\",\"fileName\":\"$2\",\"levelingBeforePrint\":true}'" || \
            echo "Нет ответа от принтера с IP $ip. Необходимо настроить принтер. На экране принтера: \"Настройки\" -> \"Иконка WiFi\" -> \"Сетевой режим\" -> включить ползунок \"Только локальные сети\""
    else
        echo "Используйте $0 PRINT|CLOSE FILE [PRECLEAR]"
        exit 1
    fi
fi
