#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod
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
    chroot ${MOD} /opt/config/mod/.shell/root/S70httpd restart
fi
