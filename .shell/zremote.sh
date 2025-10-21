#!/bin/sh

if ! [ -f /ZMOD ]; then
    sync
    "$@"
else
    sync
    dbclient -y -p 22 -l root -i /opt/config/mod_data/ssh.local.key 127.0.0.1 "$@"
fi
