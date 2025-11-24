#!/bin/sh

source /opt/config/mod/.shell/0.sh

CONF="/opt/config/mod_data/zlink.txt"

start_zlink()
{
    killall zlink 2>/dev/null

    if [ -f /ZMOD ]; then
        /opt/config/mod/.shell/zlink 2>/dev/null
    else
        [ ${FF5X} -eq 0 ] && umount ${UMOUNT_MOD}
        chroot ${MOD} /opt/config/mod/.shell/zlink 2>/dev/null
        [ ${FF5X} -eq 0 ] && mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
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
