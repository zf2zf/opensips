#!/bin/bash
# deploy/scripts/deploy.sh - 部署 OpenSIPS GB28181 代理

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_PREFIX="/opt/zfnproxy/opensips"
DEPLOY_DIR="$INSTALL_PREFIX/etc"
BACKUP_DIR="$INSTALL_PREFIX/etc.bak.$(date +%Y%m%d_%H%M%S)"

usage() {
    echo "Usage: $0 [single|node_a|node_b] [OPTIONS...]"
    echo "  -l, --local-ip      本机 IP"
    echo "  -p, --peer-ip       集群对端 IP"
    echo "  -v, --vip           虚拟 IP（默认等于 local-ip）"
    echo "  -s, --socket-port   SIP 监听端口（默认 5060）"
    echo "  -b, --bin-port      BIN 监听端口（默认 5566）"
    echo "  -u, --upstream      上游地址，格式 IP:PORT（默认等于 peer-ip:socket-port）"
    echo "Examples:"
    echo "  $0 single -l 20.20.136.66 -u 1.2.3.4:5060"
    echo "  $0 node_a -l 20.20.136.66 -p 20.20.136.67 -v 20.20.136.100 -u 1.2.3.4:5060"
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
    shift
    local LOCAL_IP PEER_IP VIP SOCKET_PORT BIN_PORT UPSTREAM
    while [[ "$1" == -* ]]; do
        case "$1" in
            -l|--local-ip) LOCAL_IP="$2"; shift 2 ;;
            -p|--peer-ip) PEER_IP="$2"; shift 2 ;;
            -v|--vip) VIP="$2"; shift 2 ;;
            -s|--socket-port) SOCKET_PORT="$2"; shift 2 ;;
            -b|--bin-port) BIN_PORT="$2"; shift 2 ;;
            -u|--upstream) UPSTREAM="$2"; shift 2 ;;
            *) break ;;
        esac
    done

    echo "=== Deploying OpenSIPS GB28181 Proxy ==="
    echo "  mode: $MODE"
    echo "  local_ip: $LOCAL_IP"
    echo "  upstream: $UPSTREAM"
    echo "  install_prefix: $INSTALL_PREFIX"

    backup_config

    # 生成配置
    # 只传递有值的参数（数组避免 colon 被 IFS 分割）
    local -a _args=("$MODE")
    [ -n "$LOCAL_IP" ]    && _args+=(-l "$LOCAL_IP")
    [ -n "$PEER_IP" ]     && _args+=(-p "$PEER_IP")
    [ -n "$VIP" ]         && _args+=(-v "$VIP")
    [ -n "$SOCKET_PORT" ] && _args+=(-s "$SOCKET_PORT")
    [ -n "$BIN_PORT" ]    && _args+=(-b "$BIN_PORT")
    [ -n "$UPSTREAM" ]    && _args+=(-u "$UPSTREAM")
    "$SCRIPT_DIR/gen-cfg.sh" "${_args[@]}"

    # 创建必要目录
    mkdir -p "$INSTALL_PREFIX/data"
    mkdir -p "$INSTALL_PREFIX/log"

    # 设置权限
    chown -R opensips:opensips "$DEPLOY_DIR" 2>/dev/null || true
    chown -R opensips:opensips "$INSTALL_PREFIX/data" 2>/dev/null || true
    chown -R opensips:opensips "$INSTALL_PREFIX/log" 2>/dev/null || true

    # 验证配置
    "$INSTALL_PREFIX/sbin/opensips" -f "$DEPLOY_DIR/opensips_proxy.cfg"

    echo "=== Deployed ($MODE mode) to $INSTALL_PREFIX ==="
}

case "${1:-}" in
    single|node_a|node_b) deploy "$@" ;;
    *) usage ;;
esac
