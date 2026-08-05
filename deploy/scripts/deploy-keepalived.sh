#!/bin/bash
# deploy/scripts/deploy-keepalived.sh - Keepalived 配置管理

# 配置 keepalived
deploy_keepalived() {
    local NODE_ID="$1"
    local VIP="$2"

    echo "=== Configuring Keepalived ==="

    # 获取默认网卡
    local NET_IFACE
    NET_IFACE=$(ip route | awk '/default/ {print $5; exit}')
    if [[ -z "$NET_IFACE" ]]; then
        echo "ERROR: cannot detect default network interface"
        return 1
    fi
    echo "  network interface: $NET_IFACE"

    local KEEPALIVED_DIR="$INSTALL_PREFIX/etc/keepalived"
    mkdir -p "$KEEPALIVED_DIR"

    local CONF_SRC="$SCRIPT_DIR/../keepalived/keepalived.conf.$NODE_ID"
    if [[ -f "$CONF_SRC" ]]; then
        # 复制配置模板
        cp "$CONF_SRC" /etc/keepalived/keepalived.conf
        # 替换 VIP 和网卡
        sed -i "s/VIP/$VIP/g; s/eth0/$NET_IFACE/g" /etc/keepalived/keepalived.conf
        # 复制脚本并设置权限
        cp "$SCRIPT_DIR/../keepalived/notify.sh" "$KEEPALIVED_DIR/"
        cp "$SCRIPT_DIR/../keepalived/chk_opensips.sh" "$KEEPALIVED_DIR/"
        chown root:root "$KEEPALIVED_DIR"/*.sh
        chmod 755 "$KEEPALIVED_DIR"/*.sh
        echo "  keepalived: configured with VIP $VIP"
    fi
}
