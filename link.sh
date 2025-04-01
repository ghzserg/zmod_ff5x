#!/bin/bash

if [ $2 == 'file' ]; then
    stat -c "check_file '%n' '%a'" "$1"
else if [ $2 == 'dir' ]; then
    stat -c "check_dir '%n' '%a'" "$1"
else
    cp -a "$1" "../stock/$1"
    a=$(readlink "$1")
    echo "check_link '$1' '$a'"
fi
fi
