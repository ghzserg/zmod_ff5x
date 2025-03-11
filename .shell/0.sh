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
