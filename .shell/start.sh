#!/bin/sh

export LD_LIBRARY_PATH=/opt/openssl-1.0.2d/lib:/opt/libffi-3.4.4/lib:$LD_LIBRARY_PATH

export PATH=$PATH:/opt/Python-3.7.11/bin
export LD_LIBRARY_PATH=/opt/Python-3.7.11/lib:$LD_LIBRARY_PATH

#/opt/Python-3.7.11/bin/python3.7 /root/pycmd-1.py

# zmod 1.0
if ! grep -q "zmod 1.0" /opt/klipper/klippy/extras/virtual_sdcard.py; then
    cp /opt/config/mod/.shell/virtual_sdcard.py /opt/klipper/klippy/extras/virtual_sdcard.py
fi

/opt/Python-3.7.11/bin/python3.7 /opt/klipper/klippy/klippy.py /opt/config/printer.cfg -l /data/logFiles/printer.log -a /tmp/uds &
