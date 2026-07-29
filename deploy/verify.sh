#!/bin/bash
# =============================================================================
# OpenSIPS GB28181 HA - 端到端验收
# 在任一节点上跑（建议节点 1）
# 用法: sudo bash verify.sh
# =============================================================================
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ -f "${SCRIPT_DIR}/env.sh" ]]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/env.sh"
fi

[[ "$EUID" -ne 0 ]] && { echo "ERROR: 需要 root"; exit 1; }

PASS=0; FAIL=0; WARN=0
ok()    { echo "  [PASS] $*"; PASS=$((PASS+1)); }
fail()  { echo "  [FAIL] $*"; FAIL=$((FAIL+1)); }
warn()  { echo "  [WARN] $*"; WARN=$((WARN+1)); }

echo "============================================================"
echo "  OpenSIPS GB28181 HA 验收"
echo "  角色: $ROLE  VIP: $VIP"
echo "============================================================"

# [1] 进程
echo; echo "[1] 进程"
pgrep -x opensips >/dev/null && ok "opensips 在" || fail "opensips 不在"
pgrep -x keepalived >/dev/null && ok "keepalived 在" || fail "keepalived 不在"

# [2] VIP 绑定
echo; echo "[2] VIP 绑定"
VIP_NODE=""
for IF in eth0 ens33 enp0s3; do
    ip addr show "$IF" 2>/dev/null | grep -qF "$VIP" && VIP_NODE="$IF" && break
done
if [[ -n "$VIP_NODE" ]]; then
    ok "VIP $VIP 绑在 $VIP_NODE"
else
    fail "VIP $VIP 未绑在任何接口"
fi

# [3] 监听端口
echo; echo "[3] 监听端口"
ss -lnup | grep -E ":${SIP_PORT}\b" >/dev/null && ok "SIP ${SIP_PORT} 监听中" || fail "SIP ${SIP_PORT} 未监听"
ss -lnup | grep -E ":${BIN_PORT}\b" >/dev/null && ok "BIN ${BIN_PORT} 监听中" || fail "BIN ${BIN_PORT} 未监听"
ss -lnup | grep -E ":${HTTP_PORT}\b" >/dev/null && ok "HTTP ${HTTP_PORT} 监听中" || fail "HTTP ${HTTP_PORT} 未监听"

# [4] clusterer 邻居
echo; echo "[4] clusterer"
CLIST=$($OPEN_SIPS_BIN -f "$OPEN_SIPS_CFG" -x "clusterer:list" 2>&1 || true)
if echo "$CLIST" | grep -qE "OK|reachable|node"; then
    ok "clusterer 邻居 reachable"
    echo "$CLIST" | head -4 | sed 's/^/    /'
else
    fail "clusterer 邻居不可达: $CLIST"
fi

# [5] usrloc 同步（仅节点1）
echo; echo "[5] usrloc BIN 同步"
if [[ "$ROLE" == "node1" ]]; then
    TESTU="v_$(date +%s)"
    sqlite3 "${SQLITE_DIR}/opensips.db" \
        "INSERT INTO location (username,domain,contact,expires,q,callid,cseq,last_modified,flags,user_agent,socket,attr) \
         VALUES ('$TESTU','verify','sip:test@$VIP:$SIP_PORT',9999999999,1.0,'$TESTU',1,datetime('now','localtime'),0,'verify','udp:$NODE1_IP:$SIP_PORT','test');" 2>/dev/null
    sleep 3
    REMOTE_CNT=$(ssh -o BatchMode=yes -o ConnectTimeout=5 "$NODE2_SSH" \
        "sqlite3 ${SQLITE_DIR}/opensips.db 'SELECT COUNT(*) FROM location WHERE username=\"$TESTU\";'" 2>/dev/null || echo "ERR")
    if [[ "$REMOTE_CNT" == "1" ]]; then
        ok "BIN 同步: 节点 2 可见 $TESTU"
    else
        fail "BIN 同步: 节点 2 不可见 $TESTU (count=$REMOTE_CNT)"
    fi
    sqlite3 "${SQLITE_DIR}/opensips.db" "DELETE FROM location WHERE username='$TESTU';" 2>/dev/null
else
    warn "跳过（仅节点 1 测试）"
fi

# [6] HTTP 重放（仅节点1）
echo; echo "[6] HTTP 重放"
if [[ "$ROLE" == "node1" ]]; then
    CHAN="vc_$(date +%s)"
    BODY="{\"op\":\"insert\",\"row\":{\"username\":\"$CHAN\",\"domain\":\"verify\",\"contact\":\"sip:test@$VIP:$SIP_PORT\",\"user_agent\":\"vtest\",\"socket\":\"udp:$NODE1_IP:$SIP_PORT\",\"attr\":\"vattr\",\"callid\":\"$CHAN\"}}"
    HCODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" -d "$BODY" \
        "http://$NODE2_IP:$HTTP_PORT/replay/channel" 2>/dev/null || echo "ERR")
    if [[ "$HCODE" == "200" ]]; then
        ok "HTTP 重放: 节点 2 响应 200"
        sleep 1
        RCNT=$(ssh -o BatchMode=yes -o ConnectTimeout=5 "$NODE2_SSH" \
            "sqlite3 ${SQLITE_DIR}/opensips.db 'SELECT COUNT(*) FROM location WHERE username=\"$CHAN\";'" 2>/dev/null || echo "ERR")
        [[ "$RCNT" == "1" ]] && ok "HTTP 重放生效: 节点 2 SQLite 有 $CHAN" \
            || fail "HTTP 重放未生效: count=$RCNT"
        ssh -o BatchMode=yes "$NODE2_SSH" "sqlite3 ${SQLITE_DIR}/opensips.db 'DELETE FROM location WHERE username=\"$CHAN\";'" 2>/dev/null
    else
        fail "HTTP 重放失败: HTTP $HCODE"
    fi
else
    warn "跳过（仅节点 1 测试）"
fi

# [7] SIP 收发（需 sipsak）
echo; echo "[7] SIP 收发"
if command -v sipsak >/dev/null && [[ "$ROLE" == "node1" ]]; then
    OUT=$(sipsak -s "sip:$VERIFY_DEVICE_ID@$VIP" -vv 2>&1 | tail -5 || true)
    echo "$OUT" | sed 's/^/    /'
    echo "$OUT" | grep -qE "200|OK|2[0-9][0-9]" && ok "sipsak 收到 2xx" || warn "sipsak 未收到 2xx"
else
    warn "sipsak 未装或非节点 1，跳过"
fi

# 总结
echo
echo "============================================================"
echo "  PASS=$PASS  FAIL=$FAIL  WARN=$WARN"
echo "============================================================"
[[ $FAIL -gt 0 ]] && exit 1
exit 0
