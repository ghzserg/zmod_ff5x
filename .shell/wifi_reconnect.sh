#!/bin/sh

if [ -f /opt/config/mod/.shell/0.sh ]; then
    source /opt/config/mod/.shell/0.sh
else if [ -f /usr/data/config/mod/.shell/0.sh ]; then
    source /usr/data/config/mod/.shell/0.sh
fi
fi

case "$2" in
    CONNECTED)
        echo "connection established"
        echo "$(date): Wi-Fi connected, starting DHCP on $1" >>${MOD_CONF}/mod_data/log/wifi.log
        killall udhcpc 2>&1 >>${MOD_CONF}/mod_data/log/wifi.log
        ip addr flush dev "$1" 2>&1  >>${MOD_CONF}/mod_data/log/wifi.log
        udhcpc -i "$1" -b -R -T 3 -t 5 2>&1 >>${MOD_CONF}/mod_data/log/wifi.log
        ifconfig "$1" 2>&1 >>${MOD_CONF}/mod_data/log/wifi.log
        ;;
    DISCONNECTED)
        echo "connection lost"
        echo "$(date): Wi-Fi disconnected on $1" >>${MOD_CONF}/mod_data/log/wifi.log
        killall udhcpc 2>&1 >>${MOD_CONF}/mod_data/log/wifi.log
        ;;
esac
