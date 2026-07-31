#!/bin/bash
# deploy/keepalived/notify.sh
# VIP 状态变更时执行，动态管理 iptables 和 OpenSIPS 配置

INSTALL_PREFIX="/opt/zfnproxy/opensips"
LOCAL_CFG="$INSTALL_PREFIX/etc/opensips/local.cfg"

# 从 local.cfg 读取 VIP 和本机 IP
source "$LOCAL_CFG"

case "$1" in
    master)
        iptables -t nat -A PREROUTING -d $vip -p udp --dport 5060 -j DNAT --to-destination $local_ip:5060 2>/dev/null
        sed -i "s|^socket=.*|socket=udp:$local_ip:5060 AS $vip:5060|" "$LOCAL_CFG"
        systemctl reload opensips
        ;;
    backup)
        iptables -t nat -D PREROUTING -d $vip -p udp --dport 5060 -j DNAT --to-destination $local_ip:5060 2>/dev/null
        sed -i "s| AS $vip:5060||" "$LOCAL_CFG"
        systemctl reload opensips
        ;;
    fault)
        iptables -t nat -D PREROUTING -d $vip -p udp --dport 5060 -j DNAT --to-destination $local_ip:5060 2>/dev/null
        ;;
esac
