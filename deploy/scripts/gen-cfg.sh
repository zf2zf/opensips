#!/bin/bash
# deploy/scripts/gen-cfg.sh - 使用 m4 预处理器生成 OpenSIPS 配置
# 用法: ./gen-cfg.sh [single|node_a|node_b] [LOCAL_IP] [PEER_IP] [VIP] [SOCKET_PORT] [BIN_PORT]

set -e

INSTALL_PREFIX="/opt/zfnproxy/opensips"
DB_PATH="$INSTALL_PREFIX/data/opensips/opensips.db"
MODE="${1:-single}"
LOCAL_IP="${2:-127.0.0.1}"
PEER_IP="${3:-127.0.0.1}"
VIP="${4:-}"  # 空时默认等于 LOCAL_IP
SOCKET_PORT="${5:-5060}"
BIN_PORT="${6:-5566}"

# VIP 默认为 LOCAL_IP
if [ -z "$VIP" ]; then
    VIP="$LOCAL_IP"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOY_DIR="$INSTALL_PREFIX/etc/opensips"
TEMPLATE_DIR="$SCRIPT_DIR/../cfg"

# 确定节点 ID
case "$MODE" in
    node_a) NODE_ID=1 ;;
    node_b) NODE_ID=2 ;;
    *) NODE_ID=1 ;;
esac

echo "Generating config: mode=$MODE, node_id=$NODE_ID, local_ip=$LOCAL_IP, prefix=$INSTALL_PREFIX"

# 构建 m4 -D 参数列表（直接用 Shell 变量展开的值，无须 env.m4）
M4_DEFS="-DMODE=$MODE -DNODE_ID=$NODE_ID -DLOCAL_IP=$LOCAL_IP -DPEER_IP=$PEER_IP -DVIP=$VIP -DSOCKET_PORT=$SOCKET_PORT -DBIN_PORT=$BIN_PORT -DMPATH=$INSTALL_PREFIX/lib64/opensips/modules/ -DDB_PATH=$DB_PATH"

# 创建目标目录
mkdir -p "$DEPLOY_DIR/cluster"

# 预创建 SQLite 数据库（模块在 init 阶段就查 version 表）
mkdir -p "$(dirname "$DB_PATH")"
sqlite3 "$DB_PATH" "
CREATE TABLE IF NOT EXISTS version (
    table_name CHAR(64) PRIMARY KEY NOT NULL,
    table_version INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS dispatcher (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    setid INTEGER DEFAULT 0 NOT NULL,
    destination CHAR(192) DEFAULT '' NOT NULL,
    socket CHAR(128) DEFAULT NULL,
    state INTEGER DEFAULT 0 NOT NULL,
    probe_mode INTEGER DEFAULT 0 NOT NULL,
    weight CHAR(64) DEFAULT '1' NOT NULL,
    priority INTEGER DEFAULT 0 NOT NULL,
    attrs CHAR(128) DEFAULT NULL,
    description CHAR(64) DEFAULT NULL
);
CREATE TABLE IF NOT EXISTS location (
    contact_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    username CHAR(64) DEFAULT '' NOT NULL,
    domain CHAR(64) DEFAULT NULL,
    contact TEXT NOT NULL,
    received CHAR(255) DEFAULT NULL,
    path CHAR(255) DEFAULT NULL,
    expires INTEGER NOT NULL,
    q FLOAT(10,2) DEFAULT 1.0 NOT NULL,
    callid CHAR(255) DEFAULT 'Default-Call-ID' NOT NULL,
    cseq INTEGER DEFAULT 13 NOT NULL,
    last_modified DATETIME DEFAULT '1900-01-01 00:00:01' NOT NULL,
    flags INTEGER DEFAULT 0 NOT NULL,
    cflags CHAR(255) DEFAULT NULL,
    user_agent CHAR(255) DEFAULT '' NOT NULL,
    socket CHAR(64) DEFAULT NULL,
    methods INTEGER DEFAULT NULL,
    sip_instance CHAR(255) DEFAULT NULL,
    kv_store TEXT(512) DEFAULT NULL,
    attr CHAR(255) DEFAULT NULL
);
INSERT OR IGNORE INTO version VALUES ('dispatcher', 9);
INSERT OR IGNORE INTO dispatcher (setid, destination, state, probe_mode, weight, priority)
VALUES (0, 'sip:$PEER_IP:$SOCKET_PORT', 0, 0, 1, 1);
"

# 生成配置（m4 预处理，直接传入变量定义）
m4 $M4_DEFS "$TEMPLATE_DIR/opensips_proxy.cfg.m4" > "$DEPLOY_DIR/opensips_proxy.cfg"
m4 $M4_DEFS "$TEMPLATE_DIR/local.cfg.m4" > "$DEPLOY_DIR/local.cfg"
m4 $M4_DEFS "$TEMPLATE_DIR/ha.cfg.m4" > "$DEPLOY_DIR/ha.cfg"

# 生成集群配置
m4 $M4_DEFS "$TEMPLATE_DIR/cluster/node_a.cfg.m4" > "$DEPLOY_DIR/cluster/node_a.cfg"
m4 $M4_DEFS "$TEMPLATE_DIR/cluster/node_b.cfg.m4" > "$DEPLOY_DIR/cluster/node_b.cfg"

echo "Generated config in $DEPLOY_DIR/"
