#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod

source /opt/config/mod/.shell/0.sh

CONF="/opt/config/mod_data/zlink.txt"

unset LD_PRELOAD
unset LD_LIBRARY_PATH

start_zlink()
{
    killall zlink 2>/dev/null

    mv ${MOD_CONF}/mod_data/log/zlink.4.log ${MOD_CONF}/mod_data/log/zlink.5.log 2>/dev/null
    mv ${MOD_CONF}/mod_data/log/zlink.3.log ${MOD_CONF}/mod_data/log/zlink.4.log 2>/dev/null
    mv ${MOD_CONF}/mod_data/log/zlink.2.log ${MOD_CONF}/mod_data/log/zlink.3.log 2>/dev/null
    mv ${MOD_CONF}/mod_data/log/zlink.1.log ${MOD_CONF}/mod_data/log/zlink.2.log 2>/dev/null
    mv ${MOD_CONF}/mod_data/log/zlink.log   ${MOD_CONF}/mod_data/log/zlink.1.log 2>/dev/null

    if [ -f /ZMOD ]; then
        /opt/config/mod/.shell/zlink 2>/dev/null
    else
        chroot ${MOD} /opt/config/mod/.shell/zlink 2>/dev/null
    fi
}

[ -f "${CONF}" ] || echo "0" >"${CONF}"

if [ "$1" == "get" ]; then
    cat /opt/config/mod_data/ssh.pub.txt | cut -d " " -f 1,2
    exit 0
fi

if [ "$1" == "off" ]; then
    sed -i '1c\0' "${CONF}"
    killall zlink 2>/dev/null
    exit 0
fi

if [ "$1" == "enable" ]; then
    m=$(( $4 + 0 )) 2>/dev/null || m=0
    p=$(( $5 + 0 )) 2>/dev/null || p=0

    if [ "$2" != "" ] && [ "$3" != "" ] && [ $m -eq 0 ] && [ $p -eq 0 ]; then
        echo "Error. Bad param"
    else
        echo "1
$2
$3
$m
$p
" >${CONF}
        start_zlink
        exit 0
    fi
fi

if [ "$1" == "start" ]; then
    start_zlink
    exit 0
fi

echo "Error. Bad run"
