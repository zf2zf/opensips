#!/bin/bash
# 20.20.136.66 节点 A 部署脚本（MASTER）

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cd "$SCRIPT_DIR"

# 部署节点 A（MASTER）
./deploy/scripts/deploy.sh \
  -l 20.20.136.66 \
  -p 20.20.136.205 \
  -v 20.20.136.100 \
  -s 5060 \
  -b 5566 \
  -n 1 \
  -u 20.20.136.66:15060

# 启动 keepalived（deploy.sh 已自动配置）
systemctl enable keepalived
systemctl restart keepalived

echo "=== 节点 A (20.20.136.66) 部署完成 ==="
