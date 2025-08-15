#!/bin/sh

find /opt/PROGRAM/control/ -name NationsCommand| while read a; do $a -r ; done;
exit 0
