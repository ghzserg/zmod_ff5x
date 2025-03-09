#!/bin/bash

if [ $2 == 'file' ]; then
    stat -c "check_file '%n' '%a'" "$1"
else if [ $2 == 'dir' ]; then
    stat -c "check_dir '%n' '%a'" "$1"
else
    a=$(readlink "$1")
    echo "check_link '$1' '$a'"
fi
fi
