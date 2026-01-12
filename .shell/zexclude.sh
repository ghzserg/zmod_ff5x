#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod

source /opt/config/mod/.shell/0.sh

if [ $# -ne 1 ]; then echo "Используйте $0 FILE"; exit 1; fi

fname="${DATA_GCODES}/$1"
[ -f "$1" ] && fname="$1"

if ! [ -f "${fname}" ]; then
    [ ${ZLANG} != 'ru' ] && echo "RESPOND TYPE=error MSG=\"File $1 not found.\"" >/tmp/printer || echo "RESPOND TYPE=error MSG=\"Файл $1 не найден.\"" >/tmp/printer 
    echo "CANCEL_PRINT" >/tmp/printer
    exit 1
fi

if ! grep -q -e 'EXCLUDE_OBJECT_DEFINE' "${fname}"; then
    [ ${ZLANG} != 'ru' ] && \
        TXT="No objects detected! Check gcode and make sure it contains EXCLUDE_OBJECT_DEFINE. Using regular mesh. In Orca: 'Process Profile' -> 'Other' -> 'Exclude objects'." || \
        TXT="Объекты не обнаружены! Проверьте gcode и убедитесь, что в нем есть EXCLUDE_OBJECT_DEFINE. Используется обычная сетка. В Orca: 'Профиль процесса' -> 'Прочее' -> 'Исключить модели'."
    echo "RESPOND TYPE=error MSG=\"${TXT}\"" >/tmp/printer
fi

# Igor Polunovskiy code
#grep ^EXCLUDE_OBJECT_DEFINE "${fname}" | \
#awk -F= '{print $4}' | \
#sed 's/\],/\n/g; s/,/=/g; s/\[//g; s/\]//g' | \
#awk -F= '
#BEGIN {
#    maxy = -1000
#    maxx = -1000
#    miny = 1000
#    minx = 1000
#}
#{
#    if (maxx < $1) maxx = $1
#    if (minx > $1) minx = $1
#    if (maxy < $2) maxy = $2
#    if (miny > $2) miny = $2
#}
#END {
#    printf "EXCLUDE_OBJECT_DEFINE NAME=border0 CENTER=%.4f,%.4f POLYGON=[[%.4f,%.4f],[%.4f,%.4f],[%.4f,%.4f],[%.4f,%.4f]]\n",
#        (minx + maxx)/2,    # Центр по X
#        (miny + maxy)/2,    # Центр по Y
#        minx, miny,         # Левый нижний угол
#        minx, maxy,         # Левый верхний угол
#        maxx, maxy,         # Правый верхний угол
#        maxx, miny          # Правый нижний угол
#}' >/tmp/printer
#echo 'RESPOND TYPE=echo MSG="Exclude 1"' >/tmp/printer

sed -n '
    # Замена первой метки слоя на FIRST_LAYER_CHANGE
    1,/;LAYER_CHANGE/s/;LAYER_CHANGE/;FIRST_LAYER_CHANGE/;

    # Замена следующей метки слоя на SECOND_LAYER_CHANGE
    1,/;LAYER_CHANGE/s/;LAYER_CHANGE/;SECOND_LAYER_CHANGE/;

    # Выводим строки между FIRST и SECOND_LAYER_CHANGE
    /;FIRST_LAYER_CHANGE/,/;SECOND_LAYER_CHANGE/p
' "${fname}" | \
awk '
BEGIN {
    maxy = -1000
    maxx = -1000
    miny = 1000
    minx = 1000
}
# Обрабатываем только команды перемещения (G1/G2/G3)
$1 ~ /G[123]/ {
    for (i = 2; i <= NF; i++) {
        # Обработка координаты X
        if ("X" == substr($i, 1, 1)) {
            x = 0 + substr($i, 2)
            maxx = (x > maxx) ? x : maxx
            minx = (x < minx) ? x : minx
        }
        # Обработка координаты Y
        else if ("Y" == substr($i, 1, 1)) {
            y = 0 + substr($i, 2)
            maxy = (y > maxy) ? y : maxy
            miny = (y < miny) ? y : miny
        }
    }
}
END {
    printf "EXCLUDE_OBJECT_DEFINE NAME=border1 CENTER=%.4f,%.4f POLYGON=[[%.4f,%.4f],[%.4f,%.4f],[%.4f,%.4f],[%.4f,%.4f]]\nRESPOND TYPE=echo MSG=\"Exclude 2\"\n",
        (minx + maxx)/2,    # Центр по X
        (miny + maxy)/2,    # Центр по Y
        minx, miny,         # Левый нижний угол
        minx, maxy,         # Левый верхний угол
        maxx, maxy,         # Правый верхний угол
        maxx, miny          # Правый нижний угол
}' > /tmp/printer
exit 0
