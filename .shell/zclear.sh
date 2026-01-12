#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod

LOG_FILES="/data/logFiles"
source /opt/config/mod/.shell/0.sh

if  [ "$1" == 1 ]
    then
        rm -rf ${LOG_FILES}/*
        rm -rf /opt/config/mod_data/log/*
        rm -rf ${UPDATE_DIR}/*
        sync
fi

if  [ "$2" == 1 ]
    then
        find ${DATA_GCODES}/ -type f -not -regex "${REMOUNT_MOD}/.*" -not -regex "${DATA}/\.mod/.*" -not -regex "${LOG_FILES}/.*" -exec rm {} \;
        sync
        find ${DATA_GCODES}/ -type d -not -regex "${DATA}/\.mod.*"  -not -regex "${REMOUNT_MOD}.*" -not -path "${DATA}/" -not -path "${LOG_FILES}/" -exec rm -r {} \;
        sync
fi
