#!/bin/sh

if [ ${FF5X} -eq 1 ]; then
    export LD_LIBRARY_PATH=//usr/prog/qt-4.8.6/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/openssl-1.0.2d/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/curl-7.55.1-https/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/ffmpeg-4.0.2/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/x264/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/libffi-3.4.4/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/opencv-4.2.0_mips/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/libzip-1.10.1/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/nim/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/usr/prog/Python-3.8.2/lib:$LD_LIBRARY_PATH
fi
$PYTHON /opt/config/mod/.shell/ps_mem.py -S >/tmp/list.txt
awk '{
    gsub(/python3.7/, "Klipper");
    gsub(/python3.12/, "Moonraker");
    gsub(/firmwareExe/, "Экран");
    gsub(/mjpg_streamer/, "Камера");
    gsub(/dropbear/, "SSH сервер");
    gsub(/wpa_cli/, "Wi-Fi клиент");
    gsub(/console_log/, "Восстановление печати");
    gsub(/ts_uinput/, "Сенсорный ввод");
    gsub(/dbclient/, "SSH клиент");
    gsub(/guppyscreen/, "GuppyScreen");
    gsub(/wpa_supplicant/, "Wi-Fi сервер");
    gsub(/dbus-daemon/, "D-Bus");
    print;
}' /tmp/list.txt
rm -f /tmp/list.txt
free -m| sed 's/             total       used       free     shared    buffers     cached/Память       Всего     Занято   Свободно      Общая     Буферы        Кэш/'
