#!/bin/bash
# deploy/scripts/deploy.sh - 部署 OpenSIPS GB28181 代理

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_PREFIX="/opt/zfnproxy/opensips"
DEPLOY_DIR="$INSTALL_PREFIX/etc/opensips"
BACKUP_DIR="$INSTALL_PREFIX/etc/opensips.bak.$(date +%Y%m%d_%H%M%S)"

usage() {
    echo "Usage: $0 [single|node_a|node_b] [LOCAL_IP] [PEER_IP] [VIP] [SOCKET_PORT] [BIN_PORT]"
    echo "Example:"
    echo "  $0 single"
    echo "  $0 node_a 20.20.136.66 20.20.136.67 20.20.136.100 5060 5566"
    exit 1
}

backup_config() {
    echo "=== Backing up existing config ==="
    if [ -d "$DEPLOY_DIR" ]; then
        mkdir -p "$(dirname "$BACKUP_DIR")"
        cp -r "$DEPLOY_DIR" "$BACKUP_DIR"
        echo "Backup: $BACKUP_DIR"
    fi
}

deploy() {
    local MODE="${1:-single}"
    local LOCAL_IP="${2:-127.0.0.1}"
    local PEER_IP="${3:-127.0.0.1}"
    local VIP="${4:-127.0.0.1}"
    local SOCKET_PORT="${5:-5060}"
    local BIN_PORT="${6:-5566}"

    echo "=== Deploying OpenSIPS GB28181 Proxy ==="
    echo "  mode: $MODE"
    echo "  local_ip: $LOCAL_IP"
    echo "  install_prefix: $INSTALL_PREFIX"

    backup_config

    # 生成配置
    "$SCRIPT_DIR/gen-cfg.sh" "$MODE" "$LOCAL_IP" "$PEER_IP" "$VIP" "$SOCKET_PORT" "$BIN_PORT"

    # 创建必要目录
    mkdir -p "$INSTALL_PREFIX/data/opensips"
    mkdir -p "$INSTALL_PREFIX/log/opensips"

    # 设置权限
    chown -R opensips:opensips "$DEPLOY_DIR" 2>/dev/null || true
    chown -R opensips:opensips "$INSTALL_PREFIX/data/opensips" 2>/dev/null || true
    chown -R opensips:opensips "$INSTALL_PREFIX/log/opensips" 2>/dev/null || true

    # 验证配置
    "$INSTALL_PREFIX/sbin/opensips" -f "$DEPLOY_DIR/opensips_proxy.cfg"

    echo "=== Deployed ($MODE mode) to $INSTALL_PREFIX ==="
}

case "${1:-}" in
    single|node_a|node_b) deploy "$@" ;;
    *) usage ;;
esac
