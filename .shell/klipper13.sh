#!/bin/sh

PROG_DIR="/opt"
if [ -f /usr/data/config/mod/.shell/fix_config.sh ]; then
    /usr/data/config/mod/.shell/fix_config.sh start
    PROG_DIR="/usr/prog"
fi

find ${PROG_DIR}/PROGRAM/control/ -name NationsCommand| while read a; do $a -r ; done;
exit 0
