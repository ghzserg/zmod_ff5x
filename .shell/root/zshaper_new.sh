#!/bin/sh

source /opt/config/mod/.shell/0.sh

ADD="$2"
json_present=false
for arg in "$@"; do
    if [ "$arg" = "--json" ]; then
        json_present=true
        break
    fi
done

SCV="$(cat /opt/config/mod_data/scv.txt)"
[ ${ZLANG} != 'ru' ] && echo "Using SCV (square_corner_velocity) = $SCV" || echo "Используется SCV (square_corner_velocity) = $SCV";

SCV_INT="${SCV%%.*}"
if [ "$SCV_INT" -ge 11 ] && ! $json_present; then
    if [ "${ZLANG}" != 'ru' ]; then
        echo "!! SCV($SCV) too high detected // https://github.com/ghzserg/zmod/wiki/Global_en#fix_scv !!"
    else
        echo "!! Обнаружен завышенный SCV($SCV) // https://github.com/ghzserg/zmod/wiki/Global_ru#fix_scv !!"
    fi
fi

DT=$(date '+%Y%m%d_%H%M')

cd /opt/config/mod_data/
mkdir -p shapers

if [ "$1" == "X" ]; then
    b_low="x";
else if [ "$1" == "Y" ]; then
    b_low="y";
else
    echo "Incorrect $1 != X or $1 != Y"
    exit
fi
fi

[ ${ZLANG} != 'ru' ] && echo "Preparing $1-axis image. Please wait..." || echo "Подготовка изображения оси $1. Ждите..."
sed 's/psd_x/psd_Y/' "/tmp/resonances_${b_low}_$1.csv" | sed 's/psd_y/psd_x/' | sed 's/psd_Y/psd_y/' | awk -F ',' '{print $1","$3","$2","$4","$5}' >$1
python3 /opt/config/mod/.shell/root/zshaper/calibrate_shaper.py $1 --scv=$SCV -o resonances_$1.png -w 8 -l 4.8 --send $1 --${ZLANG} ${ADD}
mv $1 shapers/$1_$DT.csv
if ! $json_present; then
    cp resonances_$1.png shapers/calibration_data_$1_$DT.png
    [ ${ZLANG} != 'ru' ] && echo "Images are available in Configuration -> mod_data resonances_$1.png." || echo "Изображения лежат во вкладке Конфигурация -> mod_data resonances_$1.png."
fi
