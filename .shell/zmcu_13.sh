#!/bin/sh

cd "$1"
start-stop-daemon -S -b -x /opt/config/mod/.shell/update_mcu.sh -- mainboard
