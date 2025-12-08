#!/bin/sh

if ! [ -f /ZMOD ]; then
    sync
    "$@"
else
    sync
    cmd=""
    for arg in "$@"; do
        escaped=$(printf '%s' "$arg" | sed "s/'/'\\\\''/g")
        cmd="$cmd '$escaped'"
    done
    dbclient -y -p 22 -l root -i /opt/config/mod_data/ssh.local.key 127.0.0.1 "$cmd"
fi
