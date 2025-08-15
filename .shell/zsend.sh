#!/bin/sh

source /opt/config/mod/.shell/0.sh

unset LD_PRELOAD
unset LD_LIBRARY_PATH

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

if [ $# -eq 1 ]; then
    RET=$(${PYTHON} /opt/config/mod/.shell/zsend.py "$1" 2>&1)
    if [ $? -ne 0 ]; then
        [ ${ZLANG} != 'ru' ] && echo "Error sending message to native screen. Is it working?" || echo "Ошибка передачи сообщения на родной экран. Он у вас работает?"
    fi
    /bin/echo -e "$RET"
fi

if [ $# -eq 2 ]; then
    M109=$(head -1000 "${DATA_GCODES}/$2" | grep "^M109" | head -1)
    [ "$M109" == "" ] && M109=$(head -1000 "${DATA_GCODES}/$2" | grep "^M104" | head -1 | sed 's|M104|M109|')
    M190=$(head -1000 "${DATA_GCODES}/$2" | grep "^M190" | head -1)
    [ "$M190" == "" ] && M190=$(head -1000 "${DATA_GCODES}/$2" | grep "^M140" | head -1 | sed 's|M140|M190|')

    if [ "$M190" == "" ] || [ "$M109" == "" ]; then
        if [ ${ZLANG} != 'ru' ]; then
            echo "RESPOND TYPE=error MSG=\"File $2 doesn't contain bed heating commands (M140/M190) or nozzle heating commands (M104/M109). They must be in first 1000 lines. G-code thumbnails 140x110/PNG\"" >/tmp/printer
        else
            echo "RESPOND TYPE=error MSG=\"В файле $2 не найдены команды нагрева стола(M140/M190) или сопла(M104/M109). Они должны быть в первой 1000 строк. Эскизы G-кода 140x110/PNG\"" >/tmp/printer
        fi
        exit 1
    else
        RET=$(${PYTHON} /opt/config/mod/.shell/zsend.py "M23" "$2" 2>&1)
        if [ $? -ne 0 ]; then
            [ ${ZLANG} != 'ru' ] && echo "Error sending message to native screen. Is it working?" || echo "Ошибка передачи сообщения на родной экран. Он у вас работает?"
        fi
        /bin/echo -e "$RET"
    fi
fi
