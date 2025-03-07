#!/bin/bash

source /opt/config/mod/.shell/0.sh

if  [ "$1" == 1 ]
    then
        rm -rf ${DATA}/logFiles/*
        rm -rf /opt/config/mod_data/log/*
        sync
fi

if  [ "$2" == 1 ]
    then
        find ${DATA_GCODES}/ -type f -not -regex "${REMOUNT_MOD}/.*" -not -regex "${DATA}/\.mod/.*" -not -regex "${DATA}/logFiles.*" -exec rm {} \;
        sync
        find ${DATA_GCODES}/ -type d -not -regex "${DATA}/\.mod.*"  -not -regex "${REMOUNT_MOD}.*" -not -path "${DATA}/" -not -path "${DATA}/logFiles" -exec rm -r {} \;
        sync
fi
