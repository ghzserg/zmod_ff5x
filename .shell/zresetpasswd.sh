#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod

if [ -f /ZMOD ]; then
    /opt/config/mod/.shell/zremote.sh /opt/config/mod/.shell/zresetpasswd.sh
else
    yes root | passwd
    echo "New password: root"
fi
