#!/bin/sh

if [ -f /usr/data/config/mod/.shell/fix_config.sh ] && /usr/data/config/mod/.shell/fix_config.sh start

find /opt/PROGRAM/control/ -name NationsCommand| while read a; do $a -r ; done;
exit 0
