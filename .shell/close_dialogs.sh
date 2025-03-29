#!/bin/sh

source /opt/config/mod/.shell/0.sh

if [ -f /ZMOD ]; then
    [ ${ZLANG} == 'en' ] && echo "Close dialogs not working. Use FAST_CLOSE_DIALOGS" || echo "Закрытие диалогов не поддерживается. Используйте FAST_CLOSE_DIALOGS"
    exit
fi

unset LD_LIBRARY_PATH
unset LD_PRELOAD
export PATH="$PATH:/opt/bin:/opt/sbin"

# This script will close "Printing Cancelled" or "Printing Finished"
# dialogs shown on FlashForge Adventurer 5M(Pro) screen by
# original QT factory application.

# This script needs working GDB for operation.

# Copyright (c) 2024, Dark Simpson

pid=$(ps | grep [f]irmwareExe | awk '{print $1}')

if [ $pid -ne 0 ]; then

    echo Screen executable PID is $pid, calling GDB to perform manipulations...

    exec gdb -q <<EOF
# All black magic is done in this GDB script.
# Do not modify anything if you don't understand it!!!

# Do not load all symbold from shared libraries, we do not need them all
set auto-solib-add off

# Attach to our process to perform manipulations
attach $pid

# Check that we have instanse of CancelDialog (means it is opened now)
if (_ZN12CancelDialog16instCancelDialogE != 0)
  call _ZN12CancelDialog13setStateClearEv(_ZN12CancelDialog16instCancelDialogE)
end

# Check that we have instanse of CompletePrintDialog (means it is opened now)
if (_ZN19CompletePrintDialog23instCompletePrintDialogE != 0)
  call _ZN19CompletePrintDialog13setStateClearEv(_ZN19CompletePrintDialog23instCompletePrintDialogE)
end

# Detach from our process, leave it run freely
detach

# Quit debugger
quit
EOF

fi
