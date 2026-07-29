#!/bin/bash
# =============================================================================
# OpenSIPS GB28181 HA - 节点 2 部署
# 在节点 2（standby / backup）上跑
# 前提：sync_to_node2.sh 已把配置 scp 过来
# 用法: sudo bash deploy_node2.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ -f "${SCRIPT_DIR}/env.sh" ]]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/env.sh"
else
    echo "ERROR: env.sh 不存在。先 cp env.sh.example env.sh 并填好。"
    exit 1
fi

if [[ "$ROLE" != "node2" ]]; then
    echo "ERROR: ROLE=$ROLE 不是 node2。deploy_node2.sh 必须在节点 2 上跑。"
    exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: 需要 root 权限（sudo bash deploy_node2.sh）"
    exit 1
fi

# 检查文件是否已 scp 过来
for f in /etc/opensips/opensips_proxy_ha.cfg \
         /etc/opensips/opensips_ha_routes.cfg \
         /etc/opensips/local.cfg.node2 \
         /etc/opensips/dbtext/dispatcher/dispatcher \
         /etc/keepalived/keepalived.conf \
         /etc/keepalived/chk_opensips.sh \
         /etc/systemd/system/opensips.service; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: $f 不存在。先在节点 1 上跑 sync_to_node2.sh"
        exit 1
    fi
done

echo "==> [1/8] 把 local.cfg.node2 激活为 local.cfg..."
cp /etc/opensips/local.cfg.node2 /etc/opensips/local.cfg
chown opensips:opensips /etc/opensips/local.cfg

echo "==> [2/8] 配置语法检查..."
if ! $OPEN_SIPS_BIN -f "$OPEN_SIPS_CFG" -c > /tmp/opensips_check.log 2>&1; then
    echo "ERROR: opensips 配置语法检查失败："
    cat /tmp/opensips_check.log
    exit 1
fi
echo "    语法 OK"

echo "==> [3/8] 修正 keepalived 角色 (master → backup)..."
# deploy_node1 时推的是 master 配置；节点 2 需要 backup
# sync_to_node2.sh 推的是 backup 配置，但稳妥起见校验一次
if grep -q "state MASTER" "$KEEPALIVED_CFG"; then
    echo "WARNING: keepalived.conf 还是 master，覆盖为 backup"
    install -m 644 "${SCRIPT_DIR}/files/keepalived/keepalived.conf.backup" "$KEEPALIVED_CFG"
fi
# 修正 notify.sh 中的 LOCAL_IP（节点 2 = 20.20.136.67）
sed -i "s|^LOCAL_IP=.*|LOCAL_IP=\"$NODE2_IP\"|" /etc/keepalived/notify.sh 2>/dev/null || \
    install -m 755 "${SCRIPT_DIR}/files/keepalived/notify.sh" /etc/keepalived/notify.sh

# notify.sh 节点 2 默认 LOCAL_IP=20.20.136.67，无需改；这里只确保存在
chmod +x /etc/keepalived/notify.sh

echo "==> [4/8] systemd unit..."
chmod 644 "$SYSTEMD_UNIT"
systemctl daemon-reload
systemctl enable opensips
systemctl enable keepalived

echo "==> [5/8] 启动 OpenSIPS（节点 2）..."
# 节点 2 启动时 clusterer 要等节点 1 邻居就绪
# systemd unit 里 ExecStartPre=sleep 2 已处理
systemctl restart opensips
sleep 5
if ! systemctl is-active --quiet opensips; then
    echo "ERROR: opensips 启动失败"
    journalctl -u opensips --no-pager -n 30
    exit 1
fi
echo "    opensips 进程 PID: $(pgrep -x opensips)"

echo "==> [6/8] 启动 keepalived（节点 2 backup 角色）..."
systemctl restart keepalived
sleep 2
if ! systemctl is-active --quiet keepalived; then
    echo "ERROR: keepalived 启动失败"
    journalctl -u keepalived --no-pager -n 30
    exit 1
fi

echo "==> [7/8] 验证 clusterer 邻居..."
sleep 3
echo "  -- clusterer 邻居状态（应可见 node1）--"
$OPEN_SIPS_BIN -f "$OPEN_SIPS_CFG" -x "clusterer:list" 2>&1 | grep -E "node_id|state" | head -10 || true

echo "==> [8/8] 状态检查..."
echo "  -- VIP 应在节点 1（不应在本机）--"
if ip addr show "$NODE2_IF" 2>/dev/null | grep -qF "$VIP"; then
    echo "  WARNING: VIP 错误地绑在本机！检查 keepalived priority"
else
    echo "  OK: VIP 不在本机（应在节点 1）"
fi
echo "  -- keepalived 角色 --"
systemctl is-active keepalived
echo "  -- opensips 状态 --"
systemctl is-active opensips
echo "  -- 监听端口（应只看到 5566 + 8080，不应有 5060）--"
ss -lnup | grep -E "5060|5566|8080"

echo
echo "==> 节点 2 部署完成。"
echo "    可在任一节点上跑 verify.sh 做端到端验证。"
