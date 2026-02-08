#!/bin/sh
# (C) 2024-2026 ghzserg https://github.com/ghzserg/zmod

source /opt/config/mod/.shell/0.sh

set -x


start_moonraker() {
    /opt/config/mod/.shell/root/S65moonraker start
    /opt/config/mod/.shell/root/S70httpd start
}

start_klipper() {
    if [ ${AD5X} -eq 0 ]; then
        if grep -q "klipper13 = 1" /opt/config/mod_data/variables.cfg; then
            /opt/config/mod/.shell/root/S60klipper start
        fi
    fi
}

get_origin_from_config() {
  local config_file="$1"
  local section="[update_manager $2]"

  awk -v section="$section" '
    BEGIN { in_section = 0 }
    /^\[.*\]$/ {
      if ($0 == section) {
        in_section = 1
      } else if (in_section) {
        exit
      }
      next
    }
    in_section && /^origin[[:space:]]*:/ {
      gsub(/^[[:space:]]*origin[[:space:]]*:[[:space:]]*/, "")
      gsub(/[[:space:]]+$/, "")
      print
      exit
    }
  ' "$config_file"
}

get_branch_from_config() {
  local config_file="$1"
  local section_name="$2"
  local section="[update_manager $section_name]"

  awk -v section="$section" '
    BEGIN { in_section = 0 }
    /^\[.*\]$/ {
      if ($0 == section) {
        in_section = 1
      } else if (in_section) {
        exit
      }
      next
    }
    in_section && (/^primary_branch[[:space:]]*:/ || /^branch[[:space:]]*:/) {
      sub(/^[^:]*:[[:space:]]*/, "")
      gsub(/[[:space:]]+$/, "")
      print
      exit
    }
  ' "$config_file"
}

update_plugins() {
    grep '/root/printer_data/config/mod_data/plugins/' "$1" | sed 's|/$||' | sed 's|.*/||' | \
    while read a; do
        echo "Plugin $a"
        if ! [ -f "${MOD_CONF}/mod_data/plugins/$a/.git/config" ]; then
            url=$(get_origin_from_config "$1" "$a")
            branch=$(get_branch_from_config "$1" "$a")
            if [ "$url" != "" ] && [ "$branch" != "" ]; then
                echo "Инициализирую репозиторий"
                mkdir -p "${MOD_CONF}/mod_data/plugins/$a/"
                sqlite3 /opt/config/mod_data/database/moonraker-sql.db \
                "DELETE FROM namespace_store WHERE namespace = 'update_manager' AND key = '$a'; \
                 INSERT INTO namespace_store (namespace, key, value) VALUES ('update_manager', '$a', '{\"last_config_hash\":\"?\",\"last_refresh_time\":0.0,\"is_valid\":false,\"pip_version_info\":null,\"repo_valid\":false,\"git_owner\":\"none\",\"git_repo_name\":\"$a\",\"git_remote\":\"origin\",\"git_branch\":\"$branch\",\"current_version\":\"0.0.0.0\",\"upstream_version\":\"0.0.0.0\",\"current_commit\":\"?\",\"upstream_commit\":\"?\",\"rollback_commit\":\"?\",\"rollback_branch\":\"$branch\",\"rollback_version\":\"0.0.0.0\",\"upstream_url\":\"$url\",\"recovery_url\":\"$url\",\"branches\":[\"$branch\"],\"head_detached\":false,\"git_messages\":[],\"commits_behind\":[],\"cbh_count\":0,\"diverged\":false,\"corrupt\":true,\"modified_files\":[],\"untracked_files\":[],\"pinned_commit_valid\":true}');"
            else
                echo "Не найден url=$url или branch=$branh для $a. Пропускаю."
            fi
        else
            echo "Репозиторий $a уже  существует, пропускаю."
        fi
    done
}


check_link()
{
    a=$(readlink "$1" 2>/dev/null)
    if [ "$a" != "$2" ]; then
        /bin/echo -n "$1 - Incorrect link ($a!=$2): "
        rm -f "$1" 2>/dev/null
        ln -s "$2" "$1" 2>/dev/null && echo "Исправлено"  || echo "Ошибка исправления"
    fi
}

prepare_chroot()
{
    echo ZMOD >/ZMOD
    [ ${AD5X} -eq 0 ] && mv /tmp/localtime /etc/localtime

    mv /tmp/pointercal /etc/pointercal
    mv /tmp/ts.conf /etc/ts.conf

    [ -d /root/guppyscreen ] || mkdir -p /root/guppyscreen
    rm -f /root/guppyscreen/guppyscreen
    cp /opt/config/mod/.shell/root/guppyscreen /root/guppyscreen/guppyscreen

    [ -L /root/printer_data/scripts ] || ln -s /opt/config/mod/.shell /root/printer_data/scripts

    [ -d /etc/init.d/ ] || mkdir -p /etc/init.d/

    [ -L /etc/init.d/S98zssh ] || ln -s /opt/config/mod/.shell/S98zssh /etc/init.d/
    [ -L /etc/init.d/S98camera ] && rm -f /etc/init.d/S98camera
    [ -L /etc/init.d/S99camera ] || ln -s /opt/config/mod/.shell/root/S99camera /etc/init.d/
    [ -L /etc/init.d/S60klipper ] || ln -s /opt/config/mod/.shell/root/S60klipper /etc/init.d/

    check_link /root/klipper-env/klippy /opt/config/base/klipper/klippy
    if [ -f /opt/config/base/klipper/klippy/klippy.py ]; then
        check_link ${MOD_CONF}/base/klipper/klippy/extras/gcode_shell_command.py ${MOD_CONF}/mod/.shell/gcode_shell_command.py
        check_link ${MOD_CONF}/base/klipper/klippy/extras/zmod.py ${MOD_CONF}/mod/.shell/zmod.py

        if [ ${AD5X} -eq 0 ]; then
            check_link /opt/config/base/klipper/klippy/chelper/c_helper.so /opt/config/base/klipper/mcu/ff5m/c_helper.so
            check_link ${MOD_CONF}/base/klipper/klippy/extras/ens160.py ${MOD_CONF}/mod/.shell/ens160.py
            check_link ${MOD_CONF}/base/klipper/klippy/extras/flashforge_loadcell.py ${MOD_CONF}/mod/.shell/flashforge_loadcell.py
        else
            check_link ${MOD_CONF}/base/klipper/klippy/chelper/c_helper.so ${MOD_CONF}/base/klipper/mcu/ad5x/c_helper.so
            check_link ${MOD_CONF}/base/klipper/klippy/extras/zmod_color.py ${MOD_CONF}/mod/.shell/zmod_color.py
            check_link ${MOD_CONF}/base/klipper/klippy/extras/zmod_ifs_motion_sensor.py ${MOD_CONF}/mod/.shell/zmod_ifs_motion_sensor.py
            check_link ${MOD_CONF}/base/klipper/klippy/extras/zmod_ifs_switch_sensor.py ${MOD_CONF}/mod/.shell/zmod_ifs_switch_sensor.py
            check_link ${MOD_CONF}/base/klipper/klippy/extras/zmod_ifs.py ${MOD_CONF}/mod/.shell/zmod_ifs.py
            check_link ${MOD_CONF}/base/klipper/klippy/extras/zmod_tenz.py ${MOD_CONF}/mod/.shell/zmod_tenz.py
            check_link ${MOD_CONF}/base/klipper/klippy/extras/virtual_sdcard.py ${MOD_CONF}/mod/.shell/virtual_sdcard.py
        fi
    fi

    check_link /root/moonraker-env/moonraker /opt/config/base/moonraker

    [ -L /etc/init.d/S35tslib ] && rm -f /etc/init.d/S35tslib
    [ -L /etc/init.d/S80guppyscreen ] || ln -s /opt/config/mod/.shell/root/S80guppyscreen /etc/init.d/

    [ -L /etc/init.d/S65moonraker ] || ln -s /opt/config/mod/.shell/root/S65moonraker /etc/init.d/
    [ -L /etc/init.d/S70httpd ] || ln -s /opt/config/mod/.shell/root/S70httpd /etc/init.d/

    [ -L /usr/lib/python3.12/site-packages/mido ] || ln -s /opt/config/mod/.shell/root/mido/ /usr/lib/python3.12/site-packages/
    [ -L /usr/lib/python3.12/site-packages/mido-1.3.3.dist-info ] || ln -s /opt/config/mod/.shell/root/mido-1.3.3.dist-info/ /usr/lib/python3.12/site-packages/
    [ ${AD5X} -eq 0 ] && [ -L /root/klipper-env/lib/python3.12/site-packages/numpy ] || ln -s /usr/lib/python3.12/site-packages/numpy /root/klipper-env/lib/python3.12/site-packages/

    if ! [ -L /bin/sudo ]; then
        rm -f /bin/sudo
        ln -s /opt/config/mod/.shell/root/sudo /bin/sudo
    fi

    if ! [ -L /bin/systemctl ]; then
        rm -f /bin/systemctl
        ln -s /opt/config/mod/.shell/root/sudo /bin/systemctl
    fi

    [ -L /usr/bin/audio ] || ln -s /opt/config/mod/.shell/root/audio/audio /usr/bin/audio
    [ -L /usr/bin/audio_midi.sh ] || ln -s /opt/config/mod/.shell/root/audio/audio_midi.sh /usr/bin/audio_midi.sh
    [ -L /usr/bin/audio.py ] || ln -s /opt/config/mod/.shell/root/audio/audio.py /usr/bin/audio.py

    CUR_DIR=$(pwd)
        cd /opt/config/mod/.shell/midi/
        for i in *.mid; do
            [ -f "/opt/config/mod_data/midi/$i" ] || cp "/opt/config/mod/.shell/midi/$i" /opt/config/mod_data/midi/
        done
    cd ${CUR_DIR}

    if [ -f /opt/config/mod_data/plugins/g28_tenz/update.sh ] && ! [ -f /opt/config/mod_data/plugins/g28_tenz/zstop.cfg ]; then
        cd /opt/config/mod_data/plugins/g28_tenz/
        ./update.sh
        cd ${CUR_DIR}
    fi

    #[ -L /bin/boot_eboard_mcu ] || ln -s /opt/config/mod/.shell/root/mcu/boot_eboard_mcu /bin/boot_eboard_mcu
    [ -L /bin/backlight ] || ln -s /opt/config/mod/.shell/root/backlight /bin/backlight

    rm -rf /root/moonraker-env/lib/python3.12/site-packages/uvloop*  || echo "uvloop уже убит"

    # fix ssh keys
    mkdir -p /root/.ssh/ /.ssh/
    grep -q "zmod.link ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSFHaPS7Ms0PPIEE+E7T0eOZcCP4HZtUv7JJmCDDd9l" /root/.ssh/known_hosts || echo "zmod.link ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSFHaPS7Ms0PPIEE+E7T0eOZcCP4HZtUv7JJmCDDd9l" >>/root/.ssh/known_hosts
    grep -q "zmod.link ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSFHaPS7Ms0PPIEE+E7T0eOZcCP4HZtUv7JJmCDDd9l" /.ssh/known_hosts || echo "zmod.link ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSFHaPS7Ms0PPIEE+E7T0eOZcCP4HZtUv7JJmCDDd9l" >>/.ssh/known_hosts
    if [ ${AD5X} -eq 0 ]; then
        rm -rf /root/moonraker-env/lib/python3.12/site-packages/msgspec* || echo "msgspec уже убит"
    else
        sed -i '/127.0.0.1 /d' /.ssh/known_hosts
        sed -i '/127.0.0.1 /d' /root/.ssh/known_hosts
    fi

    if ! [ -f /root/printer_data/moonraker.secrets ]; then
        if [ -f /opt/config/mod_data/notify.txt ]; then
            cp /opt/config/mod_data/notify.txt /root/printer_data/moonraker.secrets
        else
            echo "[notify]
url: tgram://{bottoken}/{ChatID}
name: {printer_name}
" >/root/printer_data/moonraker.secrets
        fi
    fi
}

${MOD_CONF}/mod/.shell/znice.sh

if [ ${AD5X} -eq 0 ]; then
    SWAP="$1"
    echo "SWAP=$SWAP"

    if [ "$SWAP" == "/root/swap" ] && ! grep -q "use_swap = 0" /opt/config/mod_data/variables.cfg; then
        if ! swapon $SWAP; then
            dd if=/dev/zero of=$SWAP bs=1024 count=131072
            mkswap $SWAP
            swapon $SWAP || echo "SWAP не включен!"
        fi
    fi
fi

prepare_chroot

if grep -q display_off.cfg /opt/config/printer.cfg && grep -q "save_restore = 1" /opt/config/mod_data/variables.cfg; then
    /opt/config/mod/.shell/root/console_log --save --${ZLANG}
else
    /opt/config/mod/.shell/root/console_log --not-save --${ZLANG}
fi

rm -f /root/guppyscreen/guppyconfig.json
ln -s /opt/config/mod_data/guppyconfig.json /root/guppyscreen/guppyconfig.json

if [ "$3" == "Adventurer5M" ]; then
    [ -f /opt/config/mod_data/guppyconfig.json ] || cp /opt/config/mod/guppyconfig_${ZLANG}.json /opt/config/mod_data/guppyconfig.json
else if [ "$3" == "Adventurer5MPro" ]; then
    [ -f /opt/config/mod_data/guppyconfig.json ] || cp /opt/config/mod/guppyconfig_${ZLANG}_pro.json /opt/config/mod_data/guppyconfig.json
else if [ "$3" == "AD5X" ]; then
    [ -f /opt/config/mod_data/guppyconfig.json ] || cp /opt/config/mod/guppyconfig_${ZLANG}_5x.json /opt/config/mod_data/guppyconfig.json
fi
fi
fi

VER="$3 $2"
grep -q VERSION_CODENAME /etc/os-release || echo "VERSION_CODENAME=\"${VER}\"" >>/etc/os-release
grep -q "VERSION_CODENAME=\"${VER}\"" /etc/os-release || sed -i "s|VERSION_CODENAME=.*|VERSION_CODENAME=\"${VER}\"|" /etc/os-release

V1=$(cat /etc/os-release|grep PRETTY_NAME| cut  -d '"' -f2| awk '{print $1" "$2}')
[ ${AD5X} -eq 0 ] && V2=$(cat /opt/config/mod/version_5m.txt) || V2=$(cat /opt/config/mod/version_5x.txt)

grep -q PRETTY_NAME /etc/os-release || echo "VERSION_CODENAME=\"${V1} -> ${V2}\"" >>/etc/os-release
grep -q "PRETTY_NAME=\"${V1} -> ${V2}\"" /etc/os-release || sed -i "s|PRETTY_NAME=.*|PRETTY_NAME=\"${V1} -> ${V2}\"|" /etc/os-release

mkdir -p ${DATA_GCODES}/tmp

KLIPPER=0
if [ -f /opt/config/base/klipper/klippy/klippy.py ]; then
    start_klipper
    KLIPPER=1
fi

# Очищаем данные о старых обновлениях
sqlite3 /opt/config/mod_data/database/moonraker-sql.db "DELETE FROM namespace_store WHERE namespace = 'update_manager';"

# Создаем каталоги под плагины
update_plugins /opt/config/moonraker.conf
grep -q "extra_plugins.moonraker.conf" ${MOD_CONF}/mod_data/extra_plugins.moonraker.conf && update_plugins /opt/config/mod/extra_plugins.moonraker.conf
update_plugins /opt/config/mod_data/user.moonraker.conf

if ! [ -f /root/printer_data/config/base/klipper/klippy/klippy.py ]; then
    branch="main"
    url="https://github.com/ghzserg/zmod_klipper.git"
    a="klippy"
    sqlite3 /opt/config/mod_data/database/moonraker-sql.db \
    "DELETE FROM namespace_store WHERE namespace = 'update_manager' AND key = '$a'; \
     INSERT INTO namespace_store (namespace, key, value) VALUES ('update_manager', '$a', '{\"last_config_hash\":\"?\",\"last_refresh_time\":0.0,\"is_valid\":false,\"pip_version_info\":null,\"repo_valid\":false,\"git_owner\":\"none\",\"git_repo_name\":\"$a\",\"git_remote\":\"origin\",\"git_branch\":\"$branch\",\"current_version\":\"0.0.0.0\",\"upstream_version\":\"0.0.0.0\",\"current_commit\":\"?\",\"upstream_commit\":\"?\",\"rollback_commit\":\"?\",\"rollback_branch\":\"$branch\",\"rollback_version\":\"0.0.0.0\",\"upstream_url\":\"$url\",\"recovery_url\":\"$url\",\"branches\":[\"$branch\"],\"head_detached\":false,\"git_messages\":[],\"commits_behind\":[],\"cbh_count\":0,\"diverged\":false,\"corrupt\":true,\"modified_files\":[],\"untracked_files\":[],\"pinned_commit_valid\":true}');"
else
    CUR_DIR=$(pwd)
    cd /root/printer_data/config/base/klipper
    git update-index --skip-worktree klippy/extras/virtual_sdcard.py
    cd ${CUR_DIR}
fi

if ! [ -f /root/printer_data/config/base/moonraker/moonraker.py ]; then
    branch="main"
    url="https://github.com/ghzserg/zmod_moonraker.git"
    a="moon"
    sqlite3 /opt/config/mod_data/database/moonraker-sql.db \
    "DELETE FROM namespace_store WHERE namespace = 'update_manager' AND key = '$a'; \
     INSERT INTO namespace_store (namespace, key, value) VALUES ('update_manager', '$a', '{\"last_config_hash\":\"?\",\"last_refresh_time\":0.0,\"is_valid\":false,\"pip_version_info\":null,\"repo_valid\":false,\"git_owner\":\"none\",\"git_repo_name\":\"$a\",\"git_remote\":\"origin\",\"git_branch\":\"$branch\",\"current_version\":\"0.0.0.0\",\"upstream_version\":\"0.0.0.0\",\"current_commit\":\"?\",\"upstream_commit\":\"?\",\"rollback_commit\":\"?\",\"rollback_branch\":\"$branch\",\"rollback_version\":\"0.0.0.0\",\"upstream_url\":\"$url\",\"recovery_url\":\"$url\",\"branches\":[\"$branch\"],\"head_detached\":false,\"git_messages\":[],\"commits_behind\":[],\"cbh_count\":0,\"diverged\":false,\"corrupt\":true,\"modified_files\":[],\"untracked_files\":[],\"pinned_commit_valid\":true}');"
fi

if grep -q mainsail-crew /root/mainsail/release_info.json; then
    echo '{"project_name":"mainsail","project_owner":"ghzserg","version":"v1.0.0"}' >/root/mainsail/release_info.json
    sqlite3 /opt/config/mod_data/database/moonraker-sql.db "DELETE FROM namespace_store WHERE namespace = 'update_manager' AND key = 'mainsail';"
fi

if grep -q fluidd-core /root/fluidd/release_info.json; then
    echo '{"project_name":"fluidd","project_owner":"ghzserg","version":"v1.0.0"}' >/root/fluidd/release_info.json
    sqlite3 /opt/config/mod_data/database/moonraker-sql.db "DELETE FROM namespace_store WHERE namespace = 'update_manager' AND key = 'fluidd';"
fi

# Rem tmp TIMELapse
[ -d /root/printer_data/gcodes/timelapse/tmp ] && rm -rf /root/printer_data/gcodes/timelapse/tmp/*

MOONRAKER=0
if [ -f /opt/config/base/moonraker/moonraker.py ]; then
    start_moonraker
    MOONRAKER=1
fi

date -s "2026-01-01 00:00:00"

# Пробуем синхронизировать время
ntpd -dd -n -q -p pool.ntp.org || \
ntpd -dd -n -q -p ru.pool.ntp.org || \
ntpd -dd -n -q -p ntp1.vniiftri.ru || \
ntpd -dd -n -q -p ntp2.vniiftri.ru || \
ntpd -dd -n -q -p ntp3.vniiftri.ru || \
ntpd -dd -n -q -p ntp4.vniiftri.ru || \
ntpd -dd -n -q -p ntp5.vniiftri.ru || \
ntpd -dd -n -q -p ntp.sstf.nsk.ru || \
ntpd -dd -n -q -p timesstf.sstf.nsk.ru || \
ntpd -dd -n -q -p ntp.kam.vniiftri.net

test_file()
{
    DIR="/opt/config/mod_data/save"
    DT=$(date '+%Y%m%d_%H%M')

    mkdir -p $DIR

    if ! [ -f "$DIR/$1" ] || ! diff -q /opt/config/$1 "$DIR/$1"; then
        cp /opt/config/$1 "$DIR/$1"
        cp /opt/config/$1 "$DIR/$1.$DT.cfg"
    fi
}

test_file printer.base.cfg
test_file printer.cfg

sleep 15
cd /opt/config/mod/
git log | head -3|grep Date >/opt/config/mod_data/date.txt
echo "ZSSH_RELOAD" >/tmp/printer

# 10 минут пробуем получить время
for i in `seq 0 50`; do 
    ntpd -dd -n -q -p pool.ntp.org && break
    ntpd -dd -n -q -p ru.pool.ntp.org && break
    ntpd -dd -n -q -p ntp1.vniiftri.ru && break
    ntpd -dd -n -q -p ntp2.vniiftri.ru && break
    ntpd -dd -n -q -p ntp3.vniiftri.ru && break
    ntpd -dd -n -q -p ntp4.vniiftri.ru && break
    ntpd -dd -n -q -p ntp5.vniiftri.ru && break
    ntpd -dd -n -q -p ntp.sstf.nsk.ru && break
    ntpd -dd -n -q -p timesstf.sstf.nsk.ru && break
    ntpd -dd -n -q -p ntp.kam.vniiftri.net && break
    sleep 5
done
date

cd /opt/config/base/
# Klipper
if ! [ -f klipper/klippy/klippy.py ]; then
    git clone https://github.com/ghzserg/zmod_klipper klipper
fi
if [ -f klipper/klippy/klippy.py ] && [ "${KLIPPER}" -eq 0 ]; then
    start_klipper
fi

# Moonraker
if ! [ -f moonraker/moonraker.py ]; then
    git clone https://github.com/ghzserg/zmod_moonraker moonraker
fi
if [ -f moonraker/moonraker.py ] && [ "${MOONRAKER}" -eq 0 ]; then
    start_moonraker
fi
echo "Start END"
