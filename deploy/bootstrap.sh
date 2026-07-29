#!/bin/bash
# =============================================================================
# OpenSIPS GB28181 HA - bootstrap.sh
# 安装系统依赖：构建工具 / 运行时库 / keepalived / iptables / sqlite
# 两台机器各跑一次
# 用法: sudo bash bootstrap.sh
# =============================================================================
set -euo pipefail

# ---- 1. 构建工具（仅源码 build 才需要）----
echo "==> [1/5] 安装构建工具..."
apt-get update
apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    flex \
    bison \
    libxml2-dev \
    libpcre3-dev \
    libssl-dev \
    libsqlite3-dev \
    libcurl4-openssl-dev \
    libmicrohttpd-dev \
    pkg-config \
    m4

# ---- 2. 运行时依赖 ----
echo "==> [2/5] 安装运行时库..."
apt-get install -y --no-install-recommends \
    libssl3 \
    libxml2 \
    libpcre3 \
    libsqlite3-0 \
    libcurl4 \
    libmicrohttpd12

# ---- 3. keepalived / iptables / sqlite3 CLI ----
echo "==> [3/5] 安装 keepalived / iptables / sqlite3..."
apt-get install -y --no-install-recommends \
    keepalived \
    iptables \
    iptables-persistent \
    sqlite3 \
    net-tools

# ---- 4. opensips 用户 ----
echo "==> [4/5] 创建 opensips 用户..."
if ! id opensips >/dev/null 2>&1; then
    useradd --system --home /var/lib/opensips --shell /usr/sbin/nologin opensips
fi

# ---- 5. 目录 ----
echo "==> [5/5] 建目录..."
mkdir -p /etc/opensips/dbtext/dispatcher
mkdir -p /var/lib/opensips
mkdir -p /run/opensips
mkdir -p /var/log/opensips
mkdir -p /etc/keepalived
chown -R opensips:opensips /etc/opensips /var/lib/opensips /run/opensips /var/log/opensips

echo "==> bootstrap 完成。建议重启或 source /etc/profile 后继续。"
