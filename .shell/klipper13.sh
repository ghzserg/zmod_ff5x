#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod

if [ -f /usr/data/config/mod/.shell/fix_config.sh ]; then
    /usr/data/config/mod/.shell/fix_config.sh start

    find /usr/prog/PROGRAM/control/ -name NationsCommand| while read a; do $a -r ; done;

    export PATH=$PATH:/usr/prog/Python-3.8.2/bin
    export LD_LIBRARY_PATH=/usr/prog/Python-3.8.2/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/openssl-1.0.2d/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/libffi-3.4.4/lib:$LD_LIBRARY_PATH

    PYTHON=/usr/prog/Python-3.8.2/bin/python3
    KLIPPER=/usr/data/config/base/klipper/klippy/klippy.py
    KLIPPER_CONF=/usr/data/config/printer.cfg
    KLIPPER_LOG=/usr/data/logs/printer.log
    PID_FILE=/run/klipper.pid
    KLIPPER_UDS=/tmp/uds
    mkdir -p $(dirname $KLIPPER_LOG) # make sure the log directory exists
    start-stop-daemon -S -b -m -p $PID_FILE --exec $PYTHON -- $KLIPPER $KLIPPER_CONF -l $KLIPPER_LOG -a $KLIPPER_UDS
else
    find /opt/PROGRAM/control/ -name NationsCommand| while read a; do $a -r ; done;
fi

exit 0
