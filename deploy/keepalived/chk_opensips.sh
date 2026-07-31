#!/bin/bash
# deploy/keepalived/chk_opensips.sh
# Keepalived 检测脚本

if pgrep -x opensips > /dev/null 2>&1; then
    exit 0
else
    exit 1
fi
