#!/bin/bash
# (C)function3d https://github.com/function3d

cd /opt/config/mod_data/plugins/$1

channel=$(curl -s "http://127.0.0.1:7125/machine/update/status" 2>/dev/null | grep -o "\"$1\":{[^}]*}" 2>/dev/null | grep -o '"channel":"[^"]*"' 2>/dev/null | cut -d'"' -f4 | head -n1)

if [ "${channel}" == "stable" ]; then
    latest_tag=$(git describe --tags "$(git rev-list --tags --max-count=1)")
    if [ -n "$latest_tag" ]; then
        git reset --hard "$latest_tag"
    fi
fi
