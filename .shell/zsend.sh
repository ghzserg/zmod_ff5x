#!/bin/sh

source /opt/config/mod/.shell/0.sh

unset LD_PRELOAD
unset LD_LIBRARY_PATH

if [ $# -eq 1 ]; then
    RET=$(${PYTHON} /opt/config/mod/.shell/zsend.py "$1" 2>&1)
    [ $? -ne 0 ] && echo "Ошибка передачи сообщения на родной экран. Он у вас работает?"
    echo -e "$RET"
fi

if [ $# -eq 2 ]
    then
        M109=$(head -1000 "${DATA_GCODES}/$2" | grep "^M109" | head -1)
        [ "$M109" == "" ] && M109=$(head -1000 "${DATA_GCODES}/$2" | grep "^M104" | head -1 | sed 's|M104|M109|')
        M190=$(head -1000 "${DATA_GCODES}/$2" | grep "^M190" | head -1)
        [ "$M190" == "" ] && M190=$(head -1000 "${DATA_GCODES}/$2" | grep "^M140" | head -1 | sed 's|M140|M190|')

        if [ "$M190" == "" ] || [ "$M109" == "" ]
            then
                echo "RESPOND TYPE=error MSG=\"В файле $2 не найдены команды нагрева стола(M140/M190) или сопла(M104/M109).\"" >/tmp/printer
                exit 1
            else
                RET=$(${PYTHON} /opt/config/mod/.shell/zsend.py "M23" "$2" 2>&1)
                [ $? -ne 0 ] && echo "Ошибка передачи сообщения на родной экран. Он у вас работает?"
                echo -e "$RET"
        fi
fi
