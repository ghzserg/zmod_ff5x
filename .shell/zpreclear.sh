#!/bin/sh

source /opt/config/mod/.shell/0.sh

if [ $# -ne 2 ]; then
    [ ${ZLANG} != 'ru' ] && echo "Use $0 FILE NONE|TEST" || echo "Используйте $0 FILE NONE|TEST"
    exit 1
fi

if ! [ -f "${DATA_GCODES}/$1" ]; then
    [ ${ZLANG} != 'ru' ] && echo "RESPOND TYPE=error MSG=\"File $1 not found.\"" >/tmp/printer || echo "RESPOND TYPE=error MSG=\"Файл $1 не найден.\"" >/tmp/printer
    echo "CANCEL_PRINT" >/tmp/printer
    exit 1
fi

M109=$(head -1300 "${DATA_GCODES}/$1" | grep "^M109" | head -1)
[ "$M109" == "" ] && M109=$(head -1000 "${DATA_GCODES}/$1" | grep "^M104" | head -1 | sed 's|M104|M109|')
M190=$(head -1300 "${DATA_GCODES}/$1" | grep "^M190" | head -1)
[ "$M190" == "" ] && M190=$(head -1000 "${DATA_GCODES}/$1" | grep "^M140" | head -1 | sed 's|M140|M190|')

if [ "$M190" == "" ] || [ "$M109" == "" ]; then
    echo "RESPOND TYPE=command MSG=action:prompt_end" >/tmp/printer
    if [ ${ZLANG} != 'ru' ]; then
        echo "RESPOND TYPE=error MSG=\"File $1 does not contain bed heating commands (M140/M190) or nozzle heating commands (M104/M109). They must be in the first 1300 lines. G-code thumbnails 140x110/PNG\"" >/tmp/printer
        echo "RESPOND TYPE=error MSG=\"Печать отменена\"" >/tmp/printer
    else
        echo "RESPOND TYPE=error MSG=\"В файле $1 не найдены команды нагрева стола(M140/M190) или сопла(M104/M109). Они должны быть в первой 1300 строк. Эскизы G-кода 140x110/PNG\"" >/tmp/printer
        echo "RESPOND TYPE=error MSG=\"Printing cancelled\"" >/tmp/printer
    fi
    echo "CANCEL_PRINT" >/tmp/printer
    exit 1
fi

if [ "$2" == "TEST" ]; then
    echo "$M190" >/tmp/printer
    echo "$M109" >/tmp/printer
    echo "_START_PRECLEAR" >/tmp/printer
fi
exit 0
