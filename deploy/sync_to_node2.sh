#!/bin/bash
# =============================================================================
# OpenSIPS GB28181 HA - 把配置 scp 到节点 2
# 在节点 1 上跑。前提：deploy_node1.sh 已完成
# 用法: bash sync_to_node2.sh
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ -f "${SCRIPT_DIR}/env.sh" ]]; then
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/env.sh"
else
    echo "ERROR: env.sh 不存在。"
    exit 1
fi

if [[ "$ROLE" != "node1" ]]; then
    echo "ERROR: sync_to_node2.sh 必须在节点 1 上跑（ROLE=node1）"
    exit 1
fi

# 检查 ssh 可达
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$NODE2_SSH" true 2>/dev/null; then
    echo "ERROR: 无法 ssh 到 $NODE2_SSH（请配置免密 ssh 或手动跑）"
    exit 1
fi

# 节点 1 已部署，节点 2 应是空目录状态；用 rsync 保持一致
RSYNC_OPTS=(-avz --delete)

echo "==> 同步 opensips 配置..."
rsync "${RSYNC_OPTS[@]}" \
    /etc/opensips/opensips_proxy_ha.cfg \
    /etc/opensips/opensips_ha_routes.cfg \
    /etc/opensips/local.cfg.node2 \
    /etc/opensips/dbtext/ \
    "$NODE2_SSH:/etc/opensips/"

echo "==> 同步 keepalived 配置..."
# 节点 2 用 backup 配置
ssh "$NODE2_SSH" "test -f /etc/keepalived/keepalived.conf || true"
rsync "${RSYNC_OPTS[@]}" \
    "$SCRIPT_DIR/files/keepalived/keepalived.conf.backup" \
    "$NODE2_SSH:$KEEPALIVED_CFG"
rsync "${RSYNC_OPTS[@]}" \
    "$SCRIPT_DIR/files/keepalived/chk_opensips.sh" \
    "$SCRIPT_DIR/files/keepalived/notify.sh" \
    "$NODE2_SSH:/etc/keepalived/"

echo "==> 同步 systemd unit..."
rsync "${RSYNC_OPTS[@]}" \
    "$SYSTEMD_UNIT" \
    "$NODE2_SSH:$SYSTEMD_UNIT"

# 修正节点 2 notify.sh 的 LOCAL_IP（保险起见）
echo "==> 修正节点 2 notify.sh 的 LOCAL_IP..."
ssh "$NODE2_SSH" "sed -i 's|^LOCAL_IP=.*|LOCAL_IP=\"$NODE2_IP\"|' /etc/keepalived/notify.sh"
ssh "$NODE2_SSH" "chmod +x /etc/keepalived/chk_opensips.sh /etc/keepalived/notify.sh"

echo "==> 同步完成。在节点 2 上跑："
echo "    sudo bash deploy_node2.sh"
