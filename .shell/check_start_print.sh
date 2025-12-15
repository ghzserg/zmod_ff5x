#!/bin/sh

FILE_NAME=${1}
if [ -z "${FILE_NAME}" ]; then
    [ ${ZLANG} == 'ru' ] && echo "RESPOND PREFIX=\"!!\" MSG=\"Не задано имя файла\"">/tmp/printer || echo "RESPOND PREFIX=\"!!\" MSG=\"Filename not found\"">/tmp/printer
    exit 1
elif [ ! -f "${FILE_NAME}" ]; then
    [ ${ZLANG} == 'ru' ] && echo "RESPOND PREFIX=\"!!\" MSG=\"Файл "${FILE_NAME}" не найден\"">/tmp/printer || echo "RESPOND PREFIX=\"!!\" MSG=\"File "${FILE_NAME}" not found\"">/tmp/printer
    exit 2
fi

source /opt/config/mod/.shell/0.sh

if grep -q -e 'END_PRINT' -e 'START_PRINT' "${FILE_NAME}"; then
    [ ${ZLANG} == 'ru' ] && echo 'RESPOND PREFIX="!!" MSG="Макрос START_PRINT или END_PRINT не найден в файле. При работе без родного экрана они должны быть. https://github.com/ghzserg/zmod/wiki/FAQ"' >/tmp/printer || echo 'The START_PRINT or END_PRINT macros were not found in the file. They should be present when working without a native screen. https://github.com/ghzserg/zmod/wiki/FAQ_en' >/tmp/printer
exit 0
