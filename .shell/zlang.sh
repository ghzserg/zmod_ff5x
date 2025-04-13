#!/bin/sh

source /opt/config/mod/.shell/0.sh

if [ "$1" == 'en' ]; then ZLANG="en"
else if [ "$1" == 'de' ]; then ZLANG="de"
else if [ "$1" == 'ru' ]; then ZLANG="ru"
else if [ "$1" == 'fr' ]; then ZLANG="fr"
else if [ "$1" == 'es' ]; then ZLANG="es"
else if [ "$1" == 'it' ]; then ZLANG="it"
else ZLANG="en"
fi; fi; fi; fi; fi; fi

echo "[zmod]
language: ${ZLANG}" >${MOD_CONF}/mod_data/lang.cfg
echo "Use lang: ${ZLANG}"
sync
sleep 5
sync
reboot
