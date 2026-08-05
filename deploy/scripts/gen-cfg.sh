#!/bin/bash
# gen-cfg.sh - Generate OpenSIPS config via m4

set -e

INSTALL_PREFIX="/opt/zfnproxy/opensips"
DB_PATH="$INSTALL_PREFIX/data/opensips.db"

NODE_ID=0
LOCAL_IP="127.0.0.1"
PEER_IP="127.0.0.1"
VIP=""
SOCKET_PORT="5060"
BIN_PORT="5566"
UPSTREAM=

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOY_DIR="$INSTALL_PREFIX/etc"
TEMPLATE_DIR="$SCRIPT_DIR/../cfg"

usage() {
    echo "Usage: $0 [OPTIONS...]"
    echo "  -l, --local-ip      Local IP"
    echo "  -p, --peer-ip       Peer IP (cluster mode)"
    echo "  -v, --vip           Virtual IP (default: local-ip)"
    echo "  -s, --socket-port   SIP port (default: 5060)"
    echo "  -b, --bin-port      BIN port (default: 5566)"
    echo "  -n, --node-id       Node ID: 1=MASTER, 2=BACKUP (default: 1)"
    echo "  -u, --upstream      Upstream address IP:PORT (required)"
    echo ""
    echo "Examples:"
    echo "  $0 -l 20.20.136.66 -u 1.2.3.4:5060"
    echo "  $0 -l 20.20.136.66 -p 20.20.136.67 -v 20.20.136.100 -n 1 -u 1.2.3.4:5060"
    exit 1
}

while getopts ":l:p:v:s:b:n:u:h" opt; do
    case $opt in
        l) LOCAL_IP="$OPTARG" ;;
        p) PEER_IP="$OPTARG" ;;
        v) VIP="$OPTARG" ;;
        s) SOCKET_PORT="$OPTARG" ;;
        b) BIN_PORT="$OPTARG" ;;
        n) NODE_ID="$OPTARG" ;;
        u) UPSTREAM="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

VIP="${VIP:-$LOCAL_IP}"
[ -n "$UPSTREAM" ] || { echo "Error: -u/--upstream is required"; usage; }

echo "Generating: node_id=$NODE_ID local_ip=$LOCAL_IP upstream=$UPSTREAM"

M4_DEFS="-DNODE_ID=$NODE_ID -DLOCAL_IP=$LOCAL_IP -DPEER_IP=$PEER_IP -D VIP=$VIP -DSOCKET_PORT=$SOCKET_PORT -DBIN_PORT=$BIN_PORT -DMPATH=$INSTALL_PREFIX/lib64/opensips/modules/ -DDB_PATH=$DB_PATH"

mkdir -p "$DEPLOY_DIR/cluster"
mkdir -p "$(dirname "$DB_PATH")"

# Pre-create SQLite DB (dispatcher checks version table at module init time)
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
INSERT OR REPLACE INTO version VALUES ('location', 1013);
DELETE FROM dispatcher;
INSERT INTO dispatcher (setid, destination, state, probe_mode, weight, priority)
VALUES (1, 'sip:$UPSTREAM', 0, 0, 1, 1);
"

m4 $M4_DEFS "$TEMPLATE_DIR/opensips_proxy.cfg.m4" > "$DEPLOY_DIR/opensips_proxy.cfg"
m4 $M4_DEFS "$TEMPLATE_DIR/cluster/node_a.cfg.m4" > "$DEPLOY_DIR/cluster/node_a.cfg"
m4 $M4_DEFS "$TEMPLATE_DIR/cluster/node_b.cfg.m4" > "$DEPLOY_DIR/cluster/node_b.cfg"

echo "Generated in $DEPLOY_DIR/"
