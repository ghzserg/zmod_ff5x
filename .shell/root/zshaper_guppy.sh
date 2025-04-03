#!/bin/sh

source /opt/config/mod/.shell/0.sh

SCV="5.0"
if grep -q "fix_scv = 1" /opt/config/mod_data/variables.cfg; then
    if grep -q '^square_corner_velocity' /opt/config/mod_data/user.cfg; then
        SCV=$(grep '^square_corner_velocity' /opt/config/mod_data/user.cfg| cut -d ":" -f 2 | awk '{print $1}')
        [ ${ZLANG} == 'en' ] && echo "Using SCV (square_corner_velocity) = $SCV from mod_data/user.cfg" || echo "Используется SCV (square_corner_velocity) = $SCV из mod_data/user.cfg"
    else if grep -q '^square_corner_velocity' /opt/config/printer.base.cfg; then
        SCV=$(grep '^square_corner_velocity' /opt/config/printer.base.cfg| cut -d ":" -f 2 | awk '{print $1}')
        [ ${ZLANG} == 'en' ] && echo "Using SCV (square_corner_velocity) = $SCV from printer.base.cfg" || echo "Используется SCV (square_corner_velocity) = $SCV из printer.base.cfg"
    else
        [ ${ZLANG} == 'en' ] && echo "Using default SCV (square_corner_velocity) = $SCV" || echo "Используется стандартный SCV (square_corner_velocity) = $SCV"
    fi
    fi
fi

if [ "$1"  == "/tmp/resonances_x_x.csv" ]; then
    sed 's/psd_x/psd_Y/' /tmp/resonances_x_x.csv | sed 's/psd_y/psd_x/' | sed 's/psd_Y/psd_y/' | awk -F ',' '{print $1","$3","$2","$4","$5}' >X
    mv X /tmp/resonances_x_x.csv
fi
if [ "$1"  == "/tmp/resonances_y_y.csv" ]; then
    sed 's/psd_x/psd_Y/' /tmp/resonances_y_y.csv | sed 's/psd_y/psd_x/' | sed 's/psd_Y/psd_y/' | awk -F ',' '{print $1","$3","$2","$4","$5}' >Y
    mv Y /tmp/resonances_y_y.csv
fi

python3 /opt/config/mod/.shell/root/zshaper/calibrate_shaper.py $@ --scv=$SCV -r 1 --${ZLANG}
