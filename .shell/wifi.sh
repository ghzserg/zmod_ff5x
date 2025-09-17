#!/bin/sh

if [ -f /opt/config/mod/.shell/0.sh ]; then
    source /opt/config/mod/.shell/0.sh
else if [ -f /usr/data/config/mod/.shell/0.sh ]; then
    source /usr/data/config/mod/.shell/0.sh
fi
fi
# $1 = interface (wlan0)
# $2 = event (CONNECTED, DISCONNECTED, ...)

case "$2" in
    CONNECTED)
        echo "$(date): Wi-Fi connected, starting DHCP on $1" >>${MOD_CONF}/mod_data/log/wifi.log
        killall udhcpc 2>/dev/null || true
        ip addr flush dev "$1" 
        udhcpc -i "$1" -b -R -T 3 -t 5
        ifconfig "$1" >>${MOD_CONF}/mod_data/log/wifi.log
        ;;
    DISCONNECTED)
        echo "$(date): Wi-Fi disconnected on $1" >>${MOD_CONF}/mod_data/log/wifi.log
        killall udhcpc 2>/dev/null || true
        ;;
esac
