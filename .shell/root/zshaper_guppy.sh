#!/bin/sh

source /opt/config/mod/.shell/0.sh

ADD=""
json_in_present=false
for arg in "$@"; do
    if [ "$arg" = "--json" ]; then
        ADD="--json"
        continue
    fi
    if [ "$arg" = "--json-in" ]; then
        json_in_present=true
        ADD="--json-in"
        continue
    fi
done

SCV="5.0"
if grep -q "fix_scv = 1" /opt/config/mod_data/variables.cfg; then
    if grep -q '^square_corner_velocity' /opt/config/mod_data/user.cfg; then
        SCV=$(grep '^square_corner_velocity' /opt/config/mod_data/user.cfg| cut -d ":" -f 2 | awk '{print $1}')
        if ! $json_in_present; then [ ${ZLANG} != 'ru' ] && echo "Using SCV (square_corner_velocity) = $SCV from mod_data/user.cfg" || echo "Используется SCV (square_corner_velocity) = $SCV из mod_data/user.cfg"; fi
    else if grep -q '^square_corner_velocity' /opt/config/printer.base.cfg; then
        SCV=$(grep '^square_corner_velocity' /opt/config/printer.base.cfg| cut -d ":" -f 2 | awk '{print $1}')
        if ! $json_in_present; then [ ${ZLANG} != 'ru' ] && echo "Using SCV (square_corner_velocity) = $SCV from printer.base.cfg" || echo "Используется SCV (square_corner_velocity) = $SCV из printer.base.cfg"; fi
    else
        if ! $json_in_present; then [ ${ZLANG} != 'ru' ] && echo "Using default SCV (square_corner_velocity) = $SCV" || echo "Используется стандартный SCV (square_corner_velocity) = $SCV"; fi
    fi
    fi
fi

if [ "$1"  == "/tmp/resonances_x_x.csv" ] && ! json_in_present; then
    sed 's/psd_x/psd_Y/' /tmp/resonances_x_x.csv | sed 's/psd_y/psd_x/' | sed 's/psd_Y/psd_y/' | awk -F ',' '{print $1","$3","$2","$4","$5}' >X
    mv X /tmp/resonances_x_x.csv
fi
if [ "$1"  == "/tmp/resonances_y_y.csv" ] && ! json_in_present; then
    sed 's/psd_x/psd_Y/' /tmp/resonances_y_y.csv | sed 's/psd_y/psd_x/' | sed 's/psd_Y/psd_y/' | awk -F ',' '{print $1","$3","$2","$4","$5}' >Y
    mv Y /tmp/resonances_y_y.csv
fi

python3 /opt/config/mod/.shell/root/zshaper/calibrate_shaper.py $@ --scv=$SCV -r 1 --${ZLANG} "$ADD"
