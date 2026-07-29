#!/bin/bash
# =============================================================================
# OpenSIPS GB28181 HA - 节点 1 部署
# 在节点 1（active / master）上跑
# 用法: sudo bash deploy_node1.sh
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

if [[ "$ROLE" != "node1" ]]; then
    echo "ERROR: ROLE=$ROLE 不是 node1。deploy_node1.sh 必须在节点 1 上跑。"
    exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: 需要 root 权限（sudo bash deploy_node1.sh）"
    exit 1
fi

echo "==> [1/8] 建目录..."
mkdir -p /etc/opensips/dbtext/dispatcher
mkdir -p /var/lib/opensips
mkdir -p /run/opensips
mkdir -p /var/log/opensips
mkdir -p /etc/keepalived

echo "==> [2/8] 推 OpenSIPS 配置..."
install -m 644 -o opensips -g opensips \
    "${SCRIPT_DIR}/files/opensips/opensips_proxy_ha.cfg" "$OPEN_SIPS_CFG"
install -m 644 -o opensips -g opensips \
    "${SCRIPT_DIR}/files/opensips/opensips_ha_routes.cfg" /etc/opensips/opensips_ha_routes.cfg
install -m 644 -o opensips -g opensips \
    "${SCRIPT_DIR}/files/opensips/local.cfg.node1" /etc/opensips/local.cfg
install -m 644 -o opensips -g opensips \
    "${SCRIPT_DIR}/files/dbtext/dispatcher" /etc/opensips/dbtext/dispatcher/dispatcher

echo "==> [3/8] 配置语法检查..."
if ! $OPEN_SIPS_BIN -f "$OPEN_SIPS_CFG" -c > /tmp/opensips_check.log 2>&1; then
    echo "ERROR: opensips 配置语法检查失败："
    cat /tmp/opensips_check.log
    exit 1
fi
echo "    语法 OK"

echo "==> [4/8] 推 keepalived 配置..."
install -m 644 "${SCRIPT_DIR}/files/keepalived/keepalived.conf.master" "$KEEPALIVED_CFG"
install -m 755 "${SCRIPT_DIR}/files/keepalived/chk_opensips.sh" "$KEEPALIVED_CHK"

echo "==> [5/8] 推 systemd unit..."
install -m 644 "${SCRIPT_DIR}/files/systemd/opensips.service" "$SYSTEMD_UNIT"
systemctl daemon-reload
systemctl enable opensips
systemctl enable keepalived

echo "==> [6/8] 启动 OpenSIPS..."
systemctl restart opensips
sleep 3
if ! systemctl is-active --quiet opensips; then
    echo "ERROR: opensips 启动失败，查看 journalctl -u opensips"
    journalctl -u opensips --no-pager -n 30
    exit 1
fi
echo "    opensips 进程 PID: $(pgrep -x opensips)"

echo "==> [7/8] 启动 keepalived..."
systemctl restart keepalived
sleep 2
if ! systemctl is-active --quiet keepalived; then
    echo "ERROR: keepalived 启动失败"
    journalctl -u keepalived --no-pager -n 30
    exit 1
fi

echo "==> [8/8] 状态检查..."
echo "  -- VIP 绑定 --"
ip addr show "$NODE1_IF" 2>/dev/null | grep -F "$VIP" || echo "  VIP 未绑！查看 keepalived 日志"
echo "  -- keepalived --"
systemctl is-active keepalived
echo "  -- opensips --"
systemctl is-active opensips
echo "  -- 监听端口 --"
ss -lnup | grep -E "5060|5566|8080" || echo "  端口未监听"

echo
echo "==> 节点 1 部署完成。"
echo "    接下来：在节点 1 上跑 sync_to_node2.sh 推配置到节点 2，"
echo "    然后在节点 2 上跑 deploy_node2.sh。"
