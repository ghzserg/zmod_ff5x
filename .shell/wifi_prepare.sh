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
    if [ ! -f "$FFCONFIG" ]; then
        echo "Config file not found: $FFCONFIG"
        return 0
    fi

    if ! grep -q '"wifiStationStatus" *: *true' "$FFCONFIG"; then
        echo "WiFi station disabled — skipping network restart."
        return 0
    fi

    echo "WiFi station enabled — restarting network..."

    ip addr flush dev "$INTERFACE" 2>/dev/null || ifconfig "$INTERFACE" 0.0.0.0 2>/dev/null
    ifconfig "$INTERFACE" down
    sleep 1
    ifconfig "$INTERFACE" up

    killall wpa_supplicant 2>/dev/null || true
    killall wpa_cli        2>/dev/null || true
    killall udhcpc         2>/dev/null || true

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

    killall wpa_cli 2>/dev/null || true

    start-stop-daemon --start --background --exec /usr/sbin/wpa_cli -- -i wlan0 -a ${MOD_CONF}/mod/.shell/wifi.sh
    echo "Wi-Fi restart initiated. DHCP will start automatically on connection."
}

mv ${MOD_CONF}/mod_data/log/wifi.4.log ${MOD_CONF}/mod_data/log/wifi.5.log
mv ${MOD_CONF}/mod_data/log/wifi.3.log ${MOD_CONF}/mod_data/log/wifi.4.log
mv ${MOD_CONF}/mod_data/log/wifi.2.log ${MOD_CONF}/mod_data/log/wifi.3.log
mv ${MOD_CONF}/mod_data/log/wifi.1.log ${MOD_CONF}/mod_data/log/wifi.2.log
mv ${MOD_CONF}/mod_data/log/wifi.log ${MOD_CONF}/mod_data/log/wifi.1.log
wifi_fix &>${MOD_CONF}/mod_data/log/wifi.log
