#!/bin/sh

source /opt/config/mod/.shell/0.sh

SCV="5.0"
if grep -q "fix_scv = 1" /opt/config/mod_data/variables.cfg; then
    if grep -q '^square_corner_velocity' /opt/config/mod_data/user.cfg; then
        SCV=$(grep '^square_corner_velocity' /opt/config/mod_data/user.cfg| cut -d ":" -f 2 | awk '{print $1}')
        [ ${ZLANG} != 'ru' ] && echo "Using SCV (square_corner_velocity) = $SCV from mod_data/user.cfg" || echo "Используется SCV (square_corner_velocity) = $SCV из mod_data/user.cfg"
    else if grep -q '^square_corner_velocity' /opt/config/printer.base.cfg; then
        SCV=$(grep '^square_corner_velocity' /opt/config/printer.base.cfg| cut -d ":" -f 2 | awk '{print $1}')
        [ ${ZLANG} != 'ru' ] && echo "Using SCV (square_corner_velocity) = $SCV from printer.base.cfg" || echo "Используется SCV (square_corner_velocity) = $SCV из printer.base.cfg"
    else
        [ ${ZLANG} != 'ru' ] && echo "Using default SCV (square_corner_velocity) = $SCV" || echo "Используется стандартный SCV (square_corner_velocity) = $SCV"
    fi
    fi
fi

if [ $SCV -ge 11 ]; then
    [ ${ZLANG} != 'ru' ] && echo "!! SCV($SCV) too high detected // https://github.com/ghzserg/zmod/wiki/Global_en#fix_scv !!" || echo "!! Обнаружен завышенный SCV($SCV) // https://github.com/ghzserg/zmod/wiki/Global_ru#fix_scv !!"
fi

DT=$(date '+%Y%m%d_%H%M')

cd /opt/config/mod_data/
mkdir -p shapers

[ ${ZLANG} != 'ru' ] && echo "Preparing X-axis image. Please wait..." || echo "Подготовка изображения оси X. Ждите..."
sed 's/psd_x/psd_Y/' /tmp/resonances_x_x.csv | sed 's/psd_y/psd_x/' | sed 's/psd_Y/psd_y/' | awk -F ',' '{print $1","$3","$2","$4","$5}' >X
python3 /opt/config/mod/.shell/root/zshaper/calibrate_shaper.py X --scv=$SCV -o resonances_x.png -w 8 -l 4.8 --send X --${ZLANG}
mv X shapers/X_$DT.csv
cp resonances_x.png shapers/calibration_data_X_$DT.png

[ ${ZLANG} != 'ru' ] && echo "Preparing Y-axis image. Please wait..." || echo "Подготовка изображения оси Y. Ждите..."
sed 's/psd_x/psd_Y/' /tmp/resonances_y_y.csv | sed 's/psd_y/psd_x/' | sed 's/psd_Y/psd_y/' | awk -F ',' '{print $1","$3","$2","$4","$5}' >Y
python3 /opt/config/mod/.shell/root/zshaper/calibrate_shaper.py Y --scv=$SCV -o resonances_y.png -w 8 -l 4.8 --send Y --${ZLANG}
mv Y shapers/Y_$DT.csv
cp resonances_y.png shapers/calibration_data_Y_$DT.png

[ ${ZLANG} != 'ru' ] && echo "Images are available in Configuration -> mod_data resonances_x.png and resonances_y.png." || echo "Изображения лежат во вкладке Конфигурация -> mod_data resonances_x.png и resonances_y.png."
