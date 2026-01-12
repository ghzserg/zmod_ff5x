#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod

send_klipper()
{
    sed -i "s/^check_md5.*/check_md5 = $1/" /opt/config/mod_data/variables.cfg
    sleep 1
}

FILE_NAME=${1}
if [ -z "${FILE_NAME}" ]; then
    send_klipper 1
    exit 1
elif [ ! -f "${FILE_NAME}" ]; then
    send_klipper 2
    exit 2
fi

DELETE_FILE=${2}
if [ -z "${DELETE_FILE}" ]; then
    DELETE_FILE="false"
fi

ORIG_MD5="$(/usr/bin/awk -F: '/; MD5/{printf("%s", $2)}' "${FILE_NAME}"|/usr/bin/tr -d ' \r')"
if [ -z "${ORIG_MD5}" ]; then
    send_klipper 3
    exit 3
fi

LOCAL_MD5="$(/bin/cat "${FILE_NAME}"|/bin/grep -v '^; MD5:'|/usr/bin/md5sum|/usr/bin/tr -d ' -')"

if [ "_${LOCAL_MD5}" = "_${ORIG_MD5}" ]; then
    if grep -q "swap = 0" /opt/config/mod_data/variables.cfg; then
        send_klipper 5
    else
        if grep -q -e 'G2 ' -e 'G3 ' "${FILE_NAME}"; then
            send_klipper 4
        else
            send_klipper 5
        fi
    fi
else
    if [ "true" = "${DELETE_FILE}" ] || [ "True" = "${DELETE_FILE}" ]; then
        /bin/rm -f "${FILE_NAME}"
        send_klipper 6
    else
        send_klipper 7
    fi
fi
exit 0
