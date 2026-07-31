#!/bin/bash
# deploy/scripts/gen-cfg.sh - 使用 m4 预处理器生成 OpenSIPS 配置
# 用法: ./gen-cfg.sh [single|node_a|node_b] [LOCAL_IP] [PEER_IP] [VIP] [SOCKET_PORT] [BIN_PORT]

set -e

INSTALL_PREFIX="/opt/zfnproxy/opensips"
MODE="${1:-single}"
LOCAL_IP="${2:-127.0.0.1}"
PEER_IP="${3:-127.0.0.1}"
VIP="${4:-127.0.0.1}"
SOCKET_PORT="${5:-5060}"
BIN_PORT="${6:-5566}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_PREFIX="/opt/zfnproxy/opensips"
DEPLOY_DIR="$INSTALL_PREFIX/etc/opensips"
TEMPLATE_DIR="$SCRIPT_DIR/../cfg"

# 确定节点 ID
case "$MODE" in
    node_a) NODE_ID=1 ;;
    node_b) NODE_ID=2 ;;
    *) NODE_ID=1 ;;
esac

echo "Generating config: mode=$MODE, node_id=$NODE_ID, local_ip=$LOCAL_IP, prefix=$INSTALL_PREFIX"

# 创建 env.m4 文件（使用单引号heredoc防止shell变量展开）
cat > "$TEMPLATE_DIR/env.m4" << 'ENVEOF'
define(`MODE', `$MODE')
define(`NODE_ID', `$NODE_ID')
define(`LOCAL_IP', `$LOCAL_IP')
define(`PEER_IP', `$PEER_IP')
define(`VIP', `$VIP')
define(`SOCKET_PORT', `$SOCKET_PORT')
define(`BIN_PORT', `$BIN_PORT')
ENVEOF

# 创建目标目录
mkdir -p "$DEPLOY_DIR/cluster"
mkdir -p "$DEPLOY_DIR/dbtext/dispatcher"

# 生成配置（m4 预处理）
m4 "$TEMPLATE_DIR/env.m4" "$TEMPLATE_DIR/opensips_proxy.cfg.m4" > "$DEPLOY_DIR/opensips_proxy.cfg"
m4 "$TEMPLATE_DIR/env.m4" "$TEMPLATE_DIR/local.cfg.m4" > "$DEPLOY_DIR/local.cfg"
m4 "$TEMPLATE_DIR/env.m4" "$TEMPLATE_DIR/ha.cfg.m4" > "$DEPLOY_DIR/ha.cfg"

# 生成集群配置
m4 "$TEMPLATE_DIR/env.m4" "$TEMPLATE_DIR/cluster/node_a.cfg.m4" > "$DEPLOY_DIR/cluster/node_a.cfg"
m4 "$TEMPLATE_DIR/env.m4" "$TEMPLATE_DIR/cluster/node_b.cfg.m4" > "$DEPLOY_DIR/cluster/node_b.cfg"

echo "Generated config in $DEPLOY_DIR/"
