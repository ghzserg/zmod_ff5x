#!/bin/sh
#
# Web config
#

unset LD_PRELOAD

source /opt/config/mod/.shell/0.sh

WEB="fluidd"
grep -q "CLIENT=$WEB" /opt/config/mod_data/web.conf && WEB="mainsail"

echo "# Не редактируйте этот файл
# Используйте макрос
#
# WEB

# Веб интерфейс (fluidd|mainsail)
CLIENT=$WEB
" >/opt/config/mod_data/web.conf

sync

if [ -f /ZMOD ]; then
    /opt/config/mod/.shell/root/S70httpd restart
else
    NEED_MOUNT=0
    [ ${FF5X} -eq 0 ] && umount ${UMOUNT_MOD} && NEED_MOUNT=1
    chroot ${MOD} /opt/config/mod/.shell/root/S70httpd restart
    [ ${NEED_MOUNT} -eq 1 ] && mount --bind ${REMOUNT_MOD} ${UMOUNT_MOD}
fi
