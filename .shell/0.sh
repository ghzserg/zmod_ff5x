#!/bin/sh

DATA=/usr/data
DATA_GCODES=/usr/data/gcodes/
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
