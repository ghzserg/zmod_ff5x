#!/bin/sh

source /opt/config/mod/.shell/0.sh

if [ -f /ZMOD ]; then
    [ ${ZLANG} == 'en' ] && echo "Restart klipper no working" || echo "Рестарт KLIPPER не поддерживается"
    exit
fi

unset LD_LIBRARY_PATH
unset LD_PRELOAD
export PATH="$PATH:/opt/bin:/opt/sbin"

# This script will restart Klipper on FlashForge Adventurer 5M(Pro)
# like original QT factory application does it.

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

# Check that we have instanse of MainWindow
if (_ZN10MainWindow14instMainWindowE != 0)
  # Open Settings screen
  call _ZN10MainWindow19on_settings_clickedEv(_ZN10MainWindow14instMainWindowE)

  # Call saveCfg(), it will also perform Klipper restart (will do it in some seconds)
  if (_ZN8Settings12instSettingsE != 0)
    call _ZN8Settings7saveCfgEv(_ZN8Settings12instSettingsE)
  end

  # Open Home screen afterall
  call _ZN10MainWindow15on_home_clickedEv(_ZN10MainWindow14instMainWindowE)
end

# Detach from our process, leave it run freely
detach

# Quit debugger
quit
EOF

fi
