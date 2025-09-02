#!/bin/sh

DATA=/data
DATA_GCODES=${DATA}
REMOUNT_MOD=${DATA}/lost+found
UMOUNT_MOD=${DATA}/.mod
MOD=${UMOUNT_MOD}/.zmod
FF5X=0
KEY_TYPE="ed25519"
KLIPPER_DIR="/opt/klipper"
TS_LIB="/opt/tslib-1.12/etc"
VIDEO="video0"
V4l2="v4l2-ctl"
LOG_FILES="/data/logFiles"
MOD_CONF="/opt/config"
PYTHON="/usr/bin/python"
PYTHON_DIR="/usr/lib/python3.7"
CURL="/opt/cloud/curl-7.55.1-https/bin/curl"
PROGRAM_DIR="/opt/PROGRAM/"
GLINES=1100
UPDATE_DIR=/data/update/
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
fi; fi; fi; fi; fi; fi; fi; fi; fi
