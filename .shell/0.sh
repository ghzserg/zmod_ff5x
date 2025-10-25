#!/bin/sh

DATA=/usr/data
DATA_GCODES=/usr/data/gcodes
REMOUNT_MOD=${DATA}/lost+found
UMOUNT_MOD=${DATA}/.mod
MOD=${UMOUNT_MOD}/.zmod
FF5X=1
KEY_TYPE="ecdsa"
KLIPPER_DIR="/usr/prog/klipper"
TS_LIB="/usr/prog/tslib-1.12/etc"
VIDEO="video3"
V4l2="chroot ${MOD} v4l2-ctl"
LOG_FILES="/usr/data/logs"
MOD_CONF="/usr/data/config"
PYTHON="/usr/prog/Python-3.8.2/bin/python3"
PYTHON_DIR="/usr/prog/Python-3.8.2/lib/python3.8"
CURL="/usr/prog/curl-7.55.1-https/bin/curl"
PROGRAM_DIR="/usr/prog/PROGRAM/"
GLINES=50000
UPDATE_DIR="/usr/data/update/"
FFCONFIG='/usr/data/config/Adventurer5M.json'
WPA_CONFIG="/usr/prog/wifi/wpa_supplicant.conf"
ZLANG="en"
if grep -q "language: en" ${MOD_CONF}/mod_data/lang.cfg; then ZLANG="en";
else if grep -q "language: ru" ${MOD_CONF}/mod_data/lang.cfg; then ZLANG="ru";
else if grep -q "language: de" ${MOD_CONF}/mod_data/lang.cfg; then ZLANG="de";
else if grep -q "language: fr" ${MOD_CONF}/mod_data/lang.cfg; then ZLANG="fr";
else if grep -q "language: it" ${MOD_CONF}/mod_data/lang.cfg; then ZLANG="it";
else if grep -q "language: es" ${MOD_CONF}/mod_data/lang.cfg; then ZLANG="es";
else if grep -q "language: zh" ${MOD_CONF}/mod_data/lang.cfg; then ZLANG="zh";
else if grep -q "language: ja" ${MOD_CONF}/mod_data/lang.cfg; then ZLANG="ja";
else if grep -q "language: ko" ${MOD_CONF}/mod_data/lang.cfg; then ZLANG="ko";
else if grep -q "language: pt" ${MOD_CONF}/mod_data/lang.cfg; then ZLANG="pt";
fi; fi; fi; fi; fi; fi; fi; fi; fi
