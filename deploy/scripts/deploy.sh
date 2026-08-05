#!/bin/bash
# deploy/scripts/deploy.sh - 部署 OpenSIPS GB28181 代理

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_PREFIX="/opt/zfnproxy/opensips"
DEPLOY_DIR="$INSTALL_PREFIX/etc"

# 加载 keepalived 配置模块
source "$SCRIPT_DIR/deploy-keepalived.sh"

usage() {
    echo "Usage: $0 [OPTIONS...]"
    echo "  -l, --local-ip      本机 IP"
    echo "  -p, --peer-ip       集群对端 IP"
    echo "  -v, --vip           虚拟 IP（默认等于 local-ip）"
    echo "  -s, --socket-port   SIP 监听端口（默认 5060）"
    echo "  -b, --bin-port      BIN 监听端口（默认 5566）"
    echo "  -n, --node-id       节点 ID: 0=单机, 1=MASTER, 2=BACKUP（默认 0）"
    echo "  -u, --upstream      上游地址，格式 IP:PORT"
    echo "Examples:"
    echo "  $0 -l 20.20.136.66 -u 1.2.3.4:5060"
    echo "  $0 -l 20.20.136.66 -p 20.20.136.67 -v 20.20.136.100 -n 1 -u 1.2.3.4:5060"
    exit 1
}

deploy() {
    local LOCAL_IP PEER_IP VIP SOCKET_PORT BIN_PORT NODE_ID UPSTREAM
    NODE_ID=0
    while [[ "$1" == -* ]]; do
        case "$1" in
            -l|--local-ip) LOCAL_IP="$2"; shift 2 ;;
            -p|--peer-ip) PEER_IP="$2"; shift 2 ;;
            -v|--vip) VIP="$2"; shift 2 ;;
            -s|--socket-port) SOCKET_PORT="$2"; shift 2 ;;
            -b|--bin-port) BIN_PORT="$2"; shift 2 ;;
            -n|--node-id) NODE_ID="$2"; shift 2 ;;
            -u|--upstream) UPSTREAM="$2"; shift 2 ;;
            *) break ;;
        esac
    done

    echo "=== Deploying OpenSIPS GB28181 Proxy ==="
    echo "  node_id: $NODE_ID"
    echo "  local_ip: $LOCAL_IP"
    echo "  upstream: $UPSTREAM"
    echo "  install_prefix: $INSTALL_PREFIX"

    # 生成配置
    local -a _args=()
    [ -n "$LOCAL_IP" ]    && _args+=(-l "$LOCAL_IP")
    [ -n "$PEER_IP" ]     && _args+=(-p "$PEER_IP")
    [ -n "$VIP" ]         && _args+=(-v "$VIP")
    [ -n "$SOCKET_PORT" ] && _args+=(-s "$SOCKET_PORT")
    [ -n "$BIN_PORT" ]    && _args+=(-b "$BIN_PORT")
    [ -n "$NODE_ID" ]     && _args+=(-n "$NODE_ID")
    [ -n "$UPSTREAM" ]    && _args+=(-u "$UPSTREAM")
    "$SCRIPT_DIR/gen-cfg.sh" "${_args[@]}"

    # 创建必要目录
    mkdir -p "$INSTALL_PREFIX/data"
    mkdir -p "$INSTALL_PREFIX/log"

    # 设置权限
    chown -R opensips:opensips "$DEPLOY_DIR" 2>/dev/null || true
    chown -R opensips:opensips "$INSTALL_PREFIX/data" 2>/dev/null || true
    chown -R opensips:opensips "$INSTALL_PREFIX/log" 2>/dev/null || true

    # 集群模式配置 keepalived（NODE_ID=1 或 2 时启用）
    if [[ "$NODE_ID" != "0" ]] && [[ -n "$VIP" ]]; then
        deploy_keepalived "$NODE_ID" "$VIP"
    fi

    # 验证配置
    "$INSTALL_PREFIX/sbin/opensips" -f "$DEPLOY_DIR/opensips_proxy.cfg"

    echo "=== Deployed (node_id=$NODE_ID) to $INSTALL_PREFIX ==="
}

# 直接调用 deploy，参数校验在 deploy 内部完成
deploy "$@"

