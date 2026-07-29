#!/bin/bash
# /etc/keepalived/notify.sh
# 节点 2 在 state 切换时执行：接管 SIP 监听（master）/ 退回（backup）
# 节点 1 一般不需要此脚本，但保留 backup/fault 钩子

LOCAL_CFG="/etc/opensips/local.cfg"
LOCAL_IP="20.20.136.67"   # 节点 2 物理 IP；节点 1 部署时改成 20.20.136.66
VIP="20.20.136.100"
LOGFILE="/var/log/keepalived.log"

ts() { date "+%Y-%m-%d %H:%M:%S"; }

case "$1" in
    master)
        # 成为 master：去掉 local.cfg 中 SIP listen 行的注释，restart opensips
        sed -i "s|^# listen=udp:${LOCAL_IP}:5060 AS ${VIP}:5060$|listen=udp:${LOCAL_IP}:5060 AS ${VIP}:5060|" "$LOCAL_CFG"
        systemctl restart opensips
        echo "$(ts) [notify] became MASTER, opensips restarted" >> "$LOGFILE"
        ;;
    backup)
        # 退回 backup：注释掉 SIP listen 行，restart opensips
        sed -i "s|^listen=udp:${LOCAL_IP}:5060 AS ${VIP}:5060$|# listen=udp:${LOCAL_IP}:5060 AS ${VIP}:5060|" "$LOCAL_CFG"
        systemctl restart opensips
        echo "$(ts) [notify] became BACKUP, opensips restarted" >> "$LOGFILE"
        ;;
    fault)
        echo "$(ts) [notify] FAULT state" >> "$LOGFILE"
        ;;
    *)
        echo "$(ts) [notify] unknown arg: $1" >> "$LOGFILE"
        ;;
esac
