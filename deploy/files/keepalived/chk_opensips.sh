#!/bin/bash
# /etc/keepalived/chk_opensips.sh
# Keepalived 调用：检查 OpenSIPS 进程是否存活
# 返回 0 = OK，1 = FAIL

if pgrep -x opensips > /dev/null 2>&1; then
    exit 0
else
    exit 1
fi
