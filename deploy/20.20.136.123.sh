#!/bin/bash
# 20.20.136.123 节点 B 部署脚本（BACKUP）

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cd "$SCRIPT_DIR"

# 部署节点 B（BACKUP）
./deploy/scripts/deploy.sh \
  -l 20.20.136.123 \
  -p 20.20.136.66 \
  -v 20.20.136.100 \
  -s 5060 \
  -b 5566 \
  -n 2 \
  -u 20.20.136.66:15060

# 启动 keepalived（deploy.sh 已自动配置）
systemctl enable keepalived
systemctl restart keepalived

echo "=== 节点 B (20.20.136.123) 部署完成 ==="
