#!/bin/sh

set -x

unset LD_LIBRARY_PATH
unset LD_PRELOAD

if [ -f /opt/config/mod/.shell/0.sh ]; then
    source /opt/config/mod/.shell/0.sh
else if [ -f /usr/data/config/mod/.shell/0.sh ]; then
    source /usr/data/config/mod/.shell/0.sh
fi
fi

if [ -f /ZMOD ]; then
    /opt/config/mod/.shell/zremote.sh /opt/config/mod/.shell/wifi_prepare.sh
    exit
fi

wifi_fix()
{
    INTERFACE=wlan0
    if ! grep -q "wifi = 1" /opt/config/mod_data/variables.cfg; then
        echo "Wi-Fi disabled in zmod. Use SAVE_ZMOD_DATA WIFI=1"
        return 0
    fi


    if [ ! -f "$FFCONFIG" ]; then
        echo "Config file not found: $FFCONFIG"
        return 0
    fi

    if grep -q display_off.cfg /opt/config/printer.cfg; then
        grep -q '"wifiStationStatus" *: *true' "$FFCONFIG" && sed -i 's/"wifiStationStatus" : true/"wifiStationStatus" : false/' "$FFCONFIG"
    else
        grep -q '"wifiStationStatus" *: *false' "$FFCONFIG" && sed -i 's/"wifiStationStatus" : false/"wifiStationStatus" : true/' "$FFCONFIG"
    fi

    if grep -q '"wifiStationStatus" *: *true' "$FFCONFIG"; then
        echo "WiFi station enabled on original screen — skipping network restart."
        return 0
    fi

    echo "WiFi station enabled — restarting network..."

    [ ${FF5X} -eq 0 ] && insmod /lib/modules/8821cu.ko || insmod /usr/prog/modules/8821cu.ko power_on=PB07

    echo "Waiting for interface $INTERFACE to appear..."

    TIMEOUT=30
    COUNT=0
    while [ $COUNT -lt $TIMEOUT ]; do
        if ip link show "$INTERFACE" >/dev/null 2>&1; then
            echo "Interface $INTERFACE is now available."
            break
        fi
        sleep 1
        COUNT=$((COUNT + 1))
    done

    if [ $COUNT -ge $TIMEOUT ]; then
        echo "Timeout: Interface $INTERFACE did not appear within $TIMEOUT seconds." >&2
        return 1
    fi

    ip addr flush dev "$INTERFACE" 2>/dev/null || ifconfig "$INTERFACE" 0.0.0.0 2>/dev/null
    ifconfig "$INTERFACE" down
    sleep 1
    ifconfig "$INTERFACE" up

    killall wpa_supplicant 2>/dev/null || true
    killall wpa_cli        2>/dev/null || true
    killall udhcpc         2>/dev/null || true

    sleep 1
    rm -f /var/run/wpa_supplicant/wlan0

    echo "wpa_supplicant"
    wpa_supplicant -i$INTERFACE -B -d -Dnl80211 -c${WPA_CONFIG}
    for i in $(seq 1 10); do
        if wpa_cli -i "$INTERFACE" status >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done

    echo "Enabling all networks..."
    wpa_cli -i "$INTERFACE" enable_network all

    killall wpa_cli
    killall -9 wpa_cli

    start-stop-daemon --start --oknodo --background --exec /usr/sbin/wpa_cli -- -i $INTERFACE -a ${MOD_CONF}/mod/.shell/wifi_reconnect.sh
    echo "Wi-Fi restart initiated. DHCP will start automatically on connection."
}

mv ${MOD_CONF}/mod_data/log/wifi.4.log ${MOD_CONF}/mod_data/log/wifi.5.log
mv ${MOD_CONF}/mod_data/log/wifi.3.log ${MOD_CONF}/mod_data/log/wifi.4.log
mv ${MOD_CONF}/mod_data/log/wifi.2.log ${MOD_CONF}/mod_data/log/wifi.3.log
mv ${MOD_CONF}/mod_data/log/wifi.1.log ${MOD_CONF}/mod_data/log/wifi.2.log
mv ${MOD_CONF}/mod_data/log/wifi.log ${MOD_CONF}/mod_data/log/wifi.1.log
wifi_fix &>${MOD_CONF}/mod_data/log/wifi.log
