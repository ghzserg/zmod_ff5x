#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod

source /opt/config/mod/.shell/0.sh

VER_FF=$(cat /opt/config/mod/version.txt 2>/dev/null| cut  -d "." -f 1,2)
[ ${AD5X} -eq 0 ] && VER_FF_FULL=$(cat /opt/config/mod/version_5m.txt 2>/dev/null) || VER_FF_FULL=$(cat /opt/config/mod/version_5x.txt 2>/dev/null)

if [ -f /opt/config/base/klipper/klippy/.version ]; then
    KLIPPER_VER=$(cat /opt/config/base/klipper/klippy/.version)
    echo "_CHECK_VERSION VER=${KLIPPER_VER}" >/tmp/printer
fi

VER_MOD="0.0"
if [ -f "/root/printer_data/version.txt" ]; then
    VER_MOD=$(cat /root/printer_data/version.txt 2>/dev/null| cut  -d "." -f 1,2)
    VER_MOD_FULL=$(cat /root/printer_data/version.txt 2>/dev/null| cut  -d "." -f 1,2,3)
else if [ -f "/root/printer_data/scripts/version.txt" ]; then
    VER_MOD=$(cat /root/printer_data/scripts/version.txt 2>/dev/null| cut  -d "." -f 1,2)
    VER_MOD_FULL=$(cat /root/printer_data/version.txt 2>/dev/null| cut  -d "." -f 1,2,3)
else if [ -f "/usr/data/.mod/.zmod/root/printer_data/version.txt" ]; then
    VER_MOD=$(cat /usr/data/.mod/.zmod/root/printer_data/version.txt 2>/dev/null| cut  -d "." -f 1,2)
    VER_MOD_FULL=$(cat /usr/data/.mod/.zmod/root/printer_data/version.txt 2>/dev/null| cut  -d "." -f 1,2,3)
    fi
fi
fi

[ ${ZLANG} != 'ru' ] && echo "Installed from USB: ${VER_MOD_FULL}. Update from Fluidd/Mainsail: ${VER_FF_FULL}" || echo "Установлено с флешки: ${VER_MOD_FULL}. Обновление с Fluidd/Mainsaill: ${VER_FF_FULL}"

content=$(cat /opt/config/mod_data/plugins.cfg 2>/dev/null)
if [ -z "$content" ] || ! echo "$content" | grep -q "include plugins"; then
    plugins=""
else
    plugins=$(echo "$content" | grep "include plugins" | sed 's|\[include plugins/||g' | cut -d "/" -f1 | tr '\n' ',' | sed 's|,$||')
fi

[ ${ZLANG} != 'ru' ] && echo "Enabled Plugins: $plugins" || echo "Активные плагины: $plugins"

if ! echo "$plugins" | grep -q "^recommend$\|,recommend$\|^recommend,\|,recommend," && ! grep -q "no_recommend = 1" /opt/config/mod_data/variables.cfg; then
    [ ${ZLANG} != 'ru' ] && echo "Have you forgotten to enable the recommended parameters? ENABLE_PLUGIN name=recommend" || echo "А вы не забыли включить рекомендуемые параметры? ENABLE_PLUGIN name=recommend"
    [ -f /opt/config/mod_data/plugins/recommend/recommend.cfg ] && ! grep -q "skip_recommend = 1" /opt/config/mod_data/variables.cfg && echo _RECOMMEND >/tmp/printer
fi

if [ "${VER_FF}" != "${VER_MOD}" ]; then
    if [ ${ZLANG} != 'ru' ]; then
        echo "RESPOND TYPE=error MSG=\"Update ZMOD from USB, latest version ${VER_FF_FULL}, current version ${VER_MOD_FULL}\"" >/tmp/printer
        echo "You can use ZFLASH macro to update from USB over network"
        echo 'https://github.com/ghzserg/zmod/wiki/Setup_en'
    else
        echo "RESPOND TYPE=error MSG=\"Обновите ZMOD с флешки, последняя версия ${VER_FF_FULL}, текущая версия ${VER_MOD_FULL}\"" >/tmp/printer
        echo "Можно использовать макрос ZFLASH, для обновления с флешки по сети"
        echo 'https://github.com/ghzserg/zmod/wiki/Setup'
    fi
fi
