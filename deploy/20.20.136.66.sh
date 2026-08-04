#!/bin/bash
# 20.20.136.66 节点 A 部署脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cd "$SCRIPT_DIR"

# 部署节点 A
./deploy/scripts/deploy.sh node_a \
  -l 20.20.136.66 \
  -p 20.20.136.123 \
  -v 20.20.136.100 \
  -s 5060 \
  -b 5566 \
  -u 20.20.136.66:15060

# 启动 keepalived（deploy.sh 已自动配置）
systemctl enable keepalived
systemctl restart keepalived

echo "=== 节点 A (20.20.136.66) 部署完成 ==="
