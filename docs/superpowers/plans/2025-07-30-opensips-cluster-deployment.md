# OpenSIPS GB28181 代理集群部署实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 OpenSIPS GB28181 代理从单机部署改造为支持单机/集群双模式部署，实现两节点 usrloc 数据集群同步。

**Architecture:** 同一套程序 + 统一编译。使用 m4 预处理器处理条件配置，部署时生成最终配置文件到 `/opt/zfnproxy/opensips/etc/opensips/`。

**Tech Stack:** OpenSIPS 4.0, SQLite, clusterer, proto_bin, mi_script, GNU m4 预处理器

**安装目录:** 所有 OpenSIPS 相关内容安装到 `/opt/zfnproxy/opensips/`
- 主程序：`/opt/zfnproxy/opensips/sbin/`
- 模块：`/opt/zfnproxy/opensips/lib64/opensips/modules/`
- 配置：`/opt/zfnproxy/opensips/etc/opensips/`
- 日志：`/opt/zfnproxy/opensips/log/`
- 数据：`/opt/zfnproxy/opensips/data/opensips/`

---

## 技术可行性确认

### ✅ 已验证可行

| 技术点 | 验证结果 |
|--------|---------|
| `sql-only` 不写 SQLite | 代码确认：`sql_wmode=SQL_NO_WRITE` |
| `full-sharing-cluster` 同步链路 | 代码确认：`insert_ucontact(..., 0)` → `replicate_ucontact_insert()` |
| 子通道 `mi("add")` 触发同步 | 代码确认：`mi_usrloc_add()` 调用 `insert_ucontact(..., 0, ...)` |
| 子通道 `mi("rm_contact")` 触发同步 | 代码确认：`mi_usrloc_rm_contact()` 调用 `delete_ucontact(..., 0)` |
| `mi()` 函数 | 文档确认：`mi_script` 模块提供 `mi()` 函数 |
| OpenSIPS 全局 `if` | **不支持** - OpenSIPS 的 `if` 仅在路由内可用 |
| 预处理器条件 | **支持** - m4/Jinja2 等预处理器的 `if` 在 OpenSIPS 解析前执行 |
| m4 预处理器 | 官方文档确认：使用 `opensips -f config.cfg.m4 -p "m4 env.m4 -"` |

### ⚠️ 关键约束

1. **OpenSIPS 不支持全局级别的 `if` 语句** - 必须用预处理器（m4）的条件宏实现
2. **模板文件使用 `.cfg.m4` 后缀** - m4 预处理器的 `ifelse` 宏处理条件
3. **部署时用 m4 生成最终配置** - `m4 env.m4 config.cfg.m4 > /etc/opensips/config.cfg`

---

## 文件架构

```
deploy/                              # 部署配置目录（独立开发）
├── Makefile.conf                    # 编译模块配置
├── env.m4                           # m4 环境变量文件
├── cfg/
│   ├── opensips_proxy.cfg.m4       # 主配置模板（m4 宏）
│   ├── local.cfg.m4               # 本机配置模板
│   ├── ha.cfg.m4                  # HA 模式模板
│   └── cluster/
│       ├── node_a.cfg.m4           # 节点 A 拓扑模板
│       └── node_b.cfg.m4           # 节点 B 拓扑模板
├── scripts/
│   ├── build.sh                   # 编译脚本
│   ├── gen-cfg.sh                # 配置生成脚本（m4 预处理）
│   ├── deploy.sh                   # 部署脚本
│   └── sync-to-peer.sh             # 节点间同步脚本
├── systemd/
│   └── opensips-gb28181.service
└── keepalived/
    ├── keepalived.conf.node_a
    ├── keepalived.conf.node_b
    └── notify.sh
```

**安装后目录结构**（`--prefix=/opt/zfnproxy/opensips`）：
```
/opt/zfnproxy/opensips/
├── bin/                           # opensips 可执行文件
├── sbin/                          # root 执行文件（opensipsctl 等）
├── lib64/opensips/modules/         # 动态加载模块
├── etc/opensips/                   # 配置文件
│   ├── opensips_proxy.cfg
│   ├── local.cfg
│   ├── ha.cfg
│   └── cluster/
├── data/opensips/                 # SQLite 数据库
│   └── opensips.db
└── log/opensips/                  # 日志文件
```

**m4 模板占位符格式**：` `VARIABLE`` `（m4 宏定义形式）

---

## Task 1: 创建部署配置目录结构

**Files:**
- Create: `deploy/cfg/cluster/`, `deploy/scripts/`, `deploy/systemd/`, `deploy/keepalived/`

- [ ] **Step 1: 创建目录结构**

```bash
mkdir -p deploy/{cfg/cluster,scripts,systemd,keepalived}
```

- [ ] **Step 2: 提交**

```bash
git add deploy/
git commit -m "feat: 创建部署配置目录结构 deploy/"
```

---

## Task 2: 创建 m4 环境文件和 HA 配置模板

**Files:**
- Create: `deploy/env.m4`
- Create: `deploy/cfg/ha.cfg.m4`
- Create: `deploy/cfg/local.cfg.m4`

- [ ] **Step 1: 创建 env.m4（m4 环境变量）**

```m4
# deploy/env.m4 - m4 预处理器环境变量
# 部署时通过 gen-cfg.sh 设置这些变量

define(`MODE', `single')
define(`NODE_ID', `1')
define(`LOCAL_IP', `127.0.0.1')
define(`PEER_IP', `127.0.0.1')
define(`VIP', `127.0.0.1')
define(`SOCKET_PORT', `5060')
define(`BIN_PORT', `5566')
```

- [ ] **Step 2: 创建 ha.cfg.m4**

```m4
# deploy/cfg/ha.cfg.m4
# HA 部署模式：single = 单机部署，cluster = 集群部署
mode=MODE
```

- [ ] **Step 3: 创建 local.cfg.m4**

```m4
# deploy/cfg/local.cfg.m4
# 本机基础配置（所有部署模式共享）

# 节点标识（1 或 2）
node_id=NODE_ID

# 网络配置
local_ip=LOCAL_IP
peer_ip=PEER_IP
vip=VIP
socket_port=SOCKET_PORT

# 集群通信端口（mode=cluster 时使用）
bin_port=BIN_PORT
```

- [ ] **Step 4: 提交**

```bash
git add deploy/env.m4 deploy/cfg/ha.cfg.m4 deploy/cfg/local.cfg.m4
git commit -m "feat: 添加 m4 环境变量和 HA 配置模板"
```

---

## Task 3: 创建集群节点配置模板

**Files:**
- Create: `deploy/cfg/cluster/node_a.cfg.m4`
- Create: `deploy/cfg/cluster/node_b.cfg.m4`

- [ ] **Step 1: 创建 node_a.cfg.m4**

```m4
# deploy/cfg/cluster/node_a.cfg.m4
# 节点 A 配置（node_id=1）

modparam("clusterer", "my_node_info", "cluster_id=1, node_id=1, url=bin:LOCAL_IP:BIN_PORT, flags=seed")
modparam("clusterer", "neighbor_node_info", "cluster_id=1, node_id=2, url=bin:PEER_IP:BIN_PORT")
```

- [ ] **Step 2: 创建 node_b.cfg.m4**

```m4
# deploy/cfg/cluster/node_b.cfg.m4
# 节点 B 配置（node_id=2）

modparam("clusterer", "my_node_info", "cluster_id=1, node_id=2, url=bin:LOCAL_IP:BIN_PORT, flags=seed")
modparam("clusterer", "neighbor_node_info", "cluster_id=1, node_id=1, url=bin:PEER_IP:BIN_PORT")
```

- [ ] **Step 3: 提交**

```bash
git add deploy/cfg/cluster/
git commit -m "feat: 添加集群节点配置模板"
```

---

## Task 4: 创建主配置模板

**Files:**
- Create: `deploy/cfg/opensips_proxy.cfg.m4`

**说明**：在现有 `etc/opensips_proxy.cfg` 基础上，使用 m4 宏处理条件配置。

- [ ] **Step 1: 基于现有配置创建模板**

```bash
cp etc/opensips_proxy.cfg deploy/cfg/opensips_proxy.cfg.m4
```

- [ ] **Step 2: 替换硬编码值为 m4 宏**

主要替换：
- `socket=udp:...` → `socket=udp:LOCAL_IP:SOCKET_PORT AS VIP:SOCKET_PORT`
- `bin_port` 相关配置用 m4 条件包裹

- [ ] **Step 3: 添加 m4 条件配置**

在配置文件中添加集群模式的 m4 条件块：

```m4
# === 集群模式条件配置 ===
ifelse(MODE, `cluster', `
# ---- 集群模式额外模块 ----
loadmodule "proto_bin.so"
loadmodule "proto_bins.so"
loadmodule "clusterer.so"
loadmodule "mi_script.so"

# ---- clusterer 参数 ----
modparam("clusterer", "db_mode", 0)
modparam("clusterer", "ping_interval", 4)
modparam("clusterer", "ping_timeout", 1000)
modparam("clusterer", "node_timeout", 60)
modparam("clusterer", "seed_fallback_interval", 10)

# ---- proto_bin 监听 ----
listen = bin:LOCAL_IP:BIN_PORT

# ---- mi_script 参数 ----
modparam("mi_script", "pretty_printing", 1)

# ---- usrloc 集群模式 ----
modparam("usrloc", "working_mode_preset", "full-sharing-cluster")
modparam("usrloc", "location_cluster", 1)

# ---- 节点拓扑 ----
ifelse(NODE_ID, `1', `
    include_file "cluster/node_a.cfg"
', `
    include_file "cluster/node_b.cfg"
')

xlog("L_INFO", "CLUSTER: starting in cluster mode, node_id=NODE_ID\n");
')
```

**说明**：m4 的 `ifelse(MODE, 'cluster', 'then_clause', 'else_clause')` 在预处理阶段执行，此时 `MODE` 已被定义为 `single` 或 `cluster`。

- [ ] **Step 4: 提交**

```bash
git add deploy/cfg/opensips_proxy.cfg.m4
git commit -m "feat: 添加主配置模板 opensips_proxy.cfg.m4"
```

---

## Task 5: 创建配置生成脚本

**Files:**
- Create: `deploy/scripts/gen-cfg.sh`

**说明**：使用 m4 预处理生成最终配置文件。

- [ ] **Step 1: 创建 gen-cfg.sh**

```bash
#!/bin/bash
# deploy/scripts/gen-cfg.sh - 使用 m4 预处理器生成 OpenSIPS 配置
# 用法: ./gen-cfg.sh [single|node_a|node_b] [LOCAL_IP] [PEER_IP] [VIP] [SOCKET_PORT] [BIN_PORT]

set -e

MODE="${1:-single}"
LOCAL_IP="${2:-127.0.0.1}"
PEER_IP="${3:-127.0.0.1}"
VIP="${4:-127.0.0.1}"
SOCKET_PORT="${5:-5060}"
BIN_PORT="${6:-5566}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_PREFIX="/opt/zfnproxy/opensips"
DEPLOY_DIR="$INSTALL_PREFIX/etc/opensips"
TEMPLATE_DIR="$SCRIPT_DIR/../cfg"

# 确定节点 ID
case "$MODE" in
    node_a) NODE_ID=1 ;;
    node_b) NODE_ID=2 ;;
    *) NODE_ID=1 ;;
esac

echo "Generating config: mode=$MODE, node_id=$NODE_ID, local_ip=$LOCAL_IP, prefix=$INSTALL_PREFIX"

# 创建 env.m4 文件
cat > "$TEMPLATE_DIR/env.m4" << 'ENVEOF'
define(`MODE', `$MODE')
define(`NODE_ID', `$NODE_ID')
define(`LOCAL_IP', `$LOCAL_IP')
define(`PEER_IP', `$PEER_IP')
define(`VIP', `$VIP')
define(`SOCKET_PORT', `$SOCKET_PORT')
define(`BIN_PORT', `$BIN_PORT')
ENVEOF

# 创建目标目录
mkdir -p "$DEPLOY_DIR/cluster"
mkdir -p "$DEPLOY_DIR/dbtext/dispatcher"

# 生成配置（m4 预处理）
m4 "$TEMPLATE_DIR/env.m4" "$TEMPLATE_DIR/opensips_proxy.cfg.m4" > "$DEPLOY_DIR/opensips_proxy.cfg"
m4 "$TEMPLATE_DIR/env.m4" "$TEMPLATE_DIR/local.cfg.m4" > "$DEPLOY_DIR/local.cfg"
m4 "$TEMPLATE_DIR/env.m4" "$TEMPLATE_DIR/ha.cfg.m4" > "$DEPLOY_DIR/ha.cfg"

# 生成集群配置
m4 "$TEMPLATE_DIR/env.m4" "$TEMPLATE_DIR/cluster/node_a.cfg.m4" > "$DEPLOY_DIR/cluster/node_a.cfg"
m4 "$TEMPLATE_DIR/env.m4" "$TEMPLATE_DIR/cluster/node_b.cfg.m4" > "$DEPLOY_DIR/cluster/node_b.cfg"

echo "Generated config in $DEPLOY_DIR/"
```

- [ ] **Step 2: 设置可执行权限**

```bash
chmod +x deploy/scripts/gen-cfg.sh
```

- [ ] **Step 3: 提交**

```bash
git add deploy/scripts/gen-cfg.sh
git commit -m "feat: 添加 m4 配置生成脚本"
```

---

## Task 6: 创建编译配置和构建脚本

**Files:**
- Create: `deploy/Makefile.conf`
- Create: `deploy/scripts/build.sh`

- [ ] **Step 1: 创建 Makefile.conf**

```makefile
# deploy/Makefile.conf - OpenSIPS GB28181 代理统一编译配置
# 包含所有模块（基础 + 集群），部署时通过配置切换模式

# === 基础模块 ===
db_sqlite=1
sqlops=1
signaling=1
sl=1
tm=1
rr=1
maxfwd=1
sipmsgops=1
db_text=1
usrloc=1
registrar=1
acc=1
proto_udp=1
dispatcher=1
uac=1
nathelper=1
xml=1
tls_openssl=1

# === 集群模式模块（统一编译）===
clusterer=1
proto_bin=1
proto_bins=1
mi_script=1
```

- [ ] **Step 2: 创建 build.sh**

```bash
#!/bin/bash
# deploy/scripts/build.sh - 编译 OpenSIPS

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENSIPS_DIR="/root/work/zf2zf/opensips/opensips"

usage() {
    echo "Usage: $0 [build|clean|install]"
    exit 1
}

build() {
    echo "=== Building OpenSIPS (all modules) ==="
    cd "$OPENSIPS_DIR"
    cp "$SCRIPT_DIR/../Makefile.conf" "$OPENSIPS_DIR/Makefile.conf"
    make clean
    make config
    make -j$(nproc)
    echo "=== Build Complete ==="
}

install_opensips() {
    echo "=== Installing OpenSIPS to /opt/zfnproxy/opensips ==="
    cd "$OPENSIPS_DIR"
    make install PREFIX=/opt/zfnproxy/opensips
    echo "=== Install Complete ==="
    echo "Installed to: /opt/zfnproxy/opensips"
    echo "  - bin/: /opt/zfnproxy/opensips/bin/"
    echo "  - sbin/: /opt/zfnproxy/opensips/sbin/"
    echo "  - lib/: /opt/zfnproxy/opensips/lib64/opensips/modules/"
    echo "  - etc/: /opt/zfnproxy/opensips/etc/opensips/"
    echo "  - data/: /opt/zfnproxy/opensips/data/opensips/"
}

case "${1:-}" in
    build) build ;;
    clean)
        cd "$OPENSIPS_DIR"
        make clean
        ;;
    install) install_opensips ;;
    *) usage ;;
esac
```

- [ ] **Step 3: 提交**

```bash
git add deploy/Makefile.conf deploy/scripts/build.sh
chmod +x deploy/scripts/build.sh
git commit -m "feat: 添加编译配置和构建脚本"
```

---

## Task 7: 创建部署和同步脚本

**Files:**
- Create: `deploy/scripts/deploy.sh`
- Create: `deploy/scripts/sync-to-peer.sh`

- [ ] **Step 1: 创建 deploy.sh**

```bash
#!/bin/bash
# deploy/scripts/deploy.sh - 部署 OpenSIPS GB28181 代理

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_PREFIX="/opt/zfnproxy/opensips"
DEPLOY_DIR="$INSTALL_PREFIX/etc/opensips"
BACKUP_DIR="$INSTALL_PREFIX/etc/opensips.bak.$(date +%Y%m%d_%H%M%S)"

usage() {
    echo "Usage: $0 [single|node_a|node_b] [LOCAL_IP] [PEER_IP] [VIP] [SOCKET_PORT] [BIN_PORT]"
    echo "Example:"
    echo "  $0 single"
    echo "  $0 node_a 20.20.136.66 20.20.136.67 20.20.136.100 5060 5566"
    exit 1
}

backup_config() {
    echo "=== Backing up existing config ==="
    if [ -d "$DEPLOY_DIR" ]; then
        mkdir -p "$(dirname "$BACKUP_DIR")"
        cp -r "$DEPLOY_DIR" "$BACKUP_DIR"
        echo "Backup: $BACKUP_DIR"
    fi
}

deploy() {
    local MODE="${1:-single}"
    local LOCAL_IP="${2:-127.0.0.1}"
    local PEER_IP="${3:-127.0.0.1}"
    local VIP="${4:-127.0.0.1}"
    local SOCKET_PORT="${5:-5060}"
    local BIN_PORT="${6:-5566}"

    echo "=== Deploying OpenSIPS GB28181 Proxy ==="
    echo "  mode: $MODE"
    echo "  local_ip: $LOCAL_IP"
    echo "  install_prefix: $INSTALL_PREFIX"

    backup_config

    # 生成配置
    "$SCRIPT_DIR/gen-cfg.sh" "$MODE" "$LOCAL_IP" "$PEER_IP" "$VIP" "$SOCKET_PORT" "$BIN_PORT"

    # 创建必要目录
    mkdir -p "$INSTALL_PREFIX/data/opensips"
    mkdir -p "$INSTALL_PREFIX/log/opensips"

    # 设置权限
    chown -R opensips:opensips "$DEPLOY_DIR" 2>/dev/null || true
    chown -R opensips:opensips "$INSTALL_PREFIX/data/opensips" 2>/dev/null || true
    chown -R opensips:opensips "$INSTALL_PREFIX/log/opensips" 2>/dev/null || true

    # 验证配置
    "$INSTALL_PREFIX/sbin/opensips" -c "$DEPLOY_DIR/opensips_proxy.cfg"

    echo "=== Deployed ($MODE mode) to $INSTALL_PREFIX ==="
}

case "${1:-}" in
    single|node_a|node_b) deploy "$@" ;;
    *) usage ;;
esac
```

- [ ] **Step 2: 创建 sync-to-peer.sh**

```bash
#!/bin/bash
# deploy/scripts/sync-to-peer.sh - 将配置同步到对等节点

set -e

INSTALL_PREFIX="/opt/zfnproxy/opensips"
LOCAL_CFG="$INSTALL_PREFIX/etc/opensips/local.cfg"

if [ ! -f "$LOCAL_CFG" ]; then
    echo "Error: $LOCAL_CFG not found"
    exit 1
fi

source "$LOCAL_CFG"

RSYNC_OPTS="-az --delete -e ssh"

echo "=== Syncing config to peer ($peer_ip) ==="
rsync $RSYNC_OPTS \
    "$INSTALL_PREFIX/etc/opensips/local.cfg" \
    "$INSTALL_PREFIX/etc/opensips/ha.cfg" \
    "$INSTALL_PREFIX/etc/opensips/cluster/" \
    "$INSTALL_PREFIX/etc/opensips/opensips_proxy.cfg" \
    "root@$peer_ip:$INSTALL_PREFIX/etc/opensips/"

echo "=== Sync Complete ==="
```

- [ ] **Step 3: 设置可执行权限并提交**

```bash
chmod +x deploy/scripts/*.sh
git add deploy/scripts/
git commit -m "feat: 添加部署和同步脚本"
```

---

## Task 8: 创建 systemd 和 Keepalived 配置

**Files:**
- Create: `deploy/systemd/opensips-gb28181.service`
- Create: `deploy/keepalived/keepalived.conf.node_a`
- Create: `deploy/keepalived/keepalived.conf.node_b`
- Create: `deploy/keepalived/notify.sh`

- [ ] **Step 1: 创建 systemd 服务文件**

```ini
# deploy/systemd/opensips-gb28181.service
[Unit]
Description=OpenSIPS GB28181 SIP Proxy
After=network.target

[Service]
Type=forking
ExecStart=/opt/zfnproxy/opensips/sbin/opensips -D -f /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg
PIDFile=/var/run/opensips.pid
Restart=on-failure
RestartSec=5
User=opensips
Group=opensips

[Install]
WantedBy=multi-user.target
```

- [ ] **Step 2: 创建节点 A 的 Keepalived 配置**

```bash
# deploy/keepalived/keepalived.conf.node_a
global_defs {
    router_id opensips_master
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1234
    }
    virtual_ipaddress {
        VIP dev eth0
    }
    track_script {
        chk_opensips
    }
}

vrrp_script chk_opensips {
    script "/opt/zfnproxy/opensips/etc/keepalived/chk_opensips.sh"
    interval 2
    weight -20
}
```

- [ ] **Step 3: 创建节点 B 的 Keepalived 配置**

```bash
# deploy/keepalived/keepalived.conf.node_b
global_defs {
    router_id opensips_backup
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 90
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1234
    }
    virtual_ipaddress {
        VIP dev eth0
    }
    track_script {
        chk_opensips
    }
    notify_master "/opt/zfnproxy/opensips/etc/keepalived/notify.sh master"
    notify_backup "/opt/zfnproxy/opensips/etc/keepalived/notify.sh backup"
    notify_fault "/opt/zfnproxy/opensips/etc/keepalived/notify.sh fault"
}

vrrp_script chk_opensips {
    script "/opt/zfnproxy/opensips/etc/keepalived/chk_opensips.sh"
    interval 2
    weight -20
}
```

- [ ] **Step 4: 创建 notify.sh 和 chk_opensips.sh**

```bash
#!/bin/bash
# deploy/keepalived/notify.sh
# VIP 状态变更时执行，动态管理 iptables 和 OpenSIPS 配置

INSTALL_PREFIX="/opt/zfnproxy/opensips"
LOCAL_CFG="$INSTALL_PREFIX/etc/opensips/local.cfg"

# 从 local.cfg 读取 VIP 和本机 IP
source "$LOCAL_CFG"

case "$1" in
    master)
        iptables -t nat -A PREROUTING -d $vip -p udp --dport 5060 -j DNAT --to-destination $local_ip:5060 2>/dev/null
        sed -i "s|^socket=.*|socket=udp:$local_ip:5060 AS $vip:5060|" "$LOCAL_CFG"
        systemctl reload opensips
        ;;
    backup)
        iptables -t nat -D PREROUTING -d $vip -p udp --dport 5060 -j DNAT --to-destination $local_ip:5060 2>/dev/null
        sed -i "s| AS $vip:5060||" "$LOCAL_CFG"
        systemctl reload opensips
        ;;
    fault)
        iptables -t nat -D PREROUTING -d $vip -p udp --dport 5060 -j DNAT --to-destination $local_ip:5060 2>/dev/null
        ;;
esac
```

```bash
#!/bin/bash
# deploy/keepalived/chk_opensips.sh
# Keepalived 检测脚本

if pgrep -x opensips > /dev/null 2>&1; then
    exit 0
else
    exit 1
fi
```

**注意**：Keepalived 配置使用 VIP 作为占位符，部署时由 gen-cfg.sh 替换为实际值。

- [ ] **Step 5: 提交**

```bash
git add deploy/systemd/ deploy/keepalived/
git commit -m "feat: 添加 systemd 和 Keepalived 配置"
```

---

## Task 9: 修改配置模板实现子通道同步

**Files:**
- Modify: `deploy/cfg/opensips_proxy.cfg.m4`（route[process_catalog] 和 route[register]）

**说明**：将 `sql_query("INSERT")` 替换为 `mi("add")`，将 `sql_query("DELETE")` 替换为 `mi("rm_contact")`。

- [ ] **Step 1: 修改 route[process_catalog] 中的 INSERT**

**当前代码**：
```bash
sql_query("DELETE FROM location WHERE username='$avp(chan_id)'");
sql_query("INSERT INTO location (...)");
```

**替换为**：
```bash
# 使用 mi("add") 写入 usrloc，触发集群同步
$avp(params) = "table_name";
$avp(vals) = "location";
$avp(params) = "aor";
$avp(vals) = $avp(chan_id);
$avp(params) = "contact";
$avp(vals) = $avp(recorder_contact);
$avp(params) = "expires";
$avp(vals) = "1790000000";
$avp(params) = "q";
$avp(vals) = "-1.0";
$avp(params) = "flags";
$avp(vals) = "0";
$avp(params) = "cflags";
$avp(vals) = "0";
$avp(params) = "methods";
$avp(vals) = "0";
mi("add", $var(ret), $avp(params), $avp(vals));

if ($var(ret) == null) {
    xlog("L_INFO", "CATALOG: mi add channel $avp(chan_id) failed\n");
} else {
    xlog("L_INFO", "CATALOG: mi add channel $avp(chan_id) ok\n");
}
```

- [ ] **Step 2: 修改 route[register] 中的 DELETE**

**当前代码**：
```bash
if ($avp(expires_hdr) == "0") {
    sql_query("DELETE FROM location WHERE attr LIKE '%' || '$tu' || '%'");
}
```

**替换为**：
```bash
if ($avp(expires_hdr) == "0") {
    # 查找该设备的所有子通道并通过 mi 删除（触发集群同步）
    # 注意：sql_query 返回多行时，结果存储在 $sql(avp(...)) 中
    sql_query("SELECT username FROM location WHERE attr LIKE '%' || '$tu' || '%'", "ra");
    $var(i) = 0;
    while ($var(i) < 1000) {
        $avp(del_chan_id) = $(avp(ra)[$var(i)]);
        if ($avp(del_chan_id) == NULL)
            break;

        $avp(params) = "table_name";
        $avp(vals) = "location";
        $avp(params) = "aor";
        $avp(vals) = $avp(del_chan_id);
        $avp(params) = "contact";
        $avp(vals) = "";
        mi("rm_contact", $var(ret), $avp(params), $avp(vals));
        xlog("L_INFO", "REGISTER: child channel $avp(del_chan_id) cleaned\n");
        $var(i) = $var(i) + 1;
    }
}
```

**说明**：`sql_query(..., "ra")` 的结果是一个 AVP 数组，遍历 `$avp(ra)[0]`、`$avp(ra)[1]` 等获取每行。

- [ ] **Step 3: 提交**

```bash
git add deploy/cfg/opensips_proxy.cfg.m4
git commit -m "feat: 将子通道操作改为 mi() 调用触发集群同步"
```

---

## Task 10: 单机和集群模式验证

**Files:**
- Test: 验证配置生成和语法检查

- [ ] **Test 1: 单机模式部署**

```bash
./deploy/scripts/deploy.sh single
opensips -c /etc/opensips/opensips_proxy.cfg
# 期望：无错误
```

- [ ] **Test 2: 集群节点 A 部署**

```bash
./deploy/scripts/deploy.sh node_a 20.20.136.66 20.20.136.67 20.20.136.100 5060 5566
opensips -c /etc/opensips/opensips_proxy.cfg
# 期望：无错误
```

- [ ] **Test 3: 提交测试结果**

```bash
git commit -m "test: 验证单机和集群模式配置生成"
```

---

## Task 11: 更新文档

**Files:**
- Modify: `docs/opensips_gb28181_proxy.md`
- Create: `docs/cluster-deployment-guide.md`

- [ ] **Step 1: 更新 GB28181 代理调研报告**

添加集群部署相关章节。

- [ ] **Step 2: 创建集群部署指南**

内容包括：
- 硬件/网络要求
- 部署步骤（单机模式、集群模式）
- m4 模板配置说明
- 故障排查
- 维护操作

- [ ] **Step 3: 提交**

```bash
git add docs/
git commit -m "docs: 添加集群部署指南"
```

---

## 实施顺序

```
Task 1 → Task 2 → Task 3 → Task 4 → Task 5 → Task 6 → Task 7 → Task 8 → Task 9 → Task 10 → Task 11
  ↓         ↓        ↓        ↓        ↓         ↓         ↓         ↓         ↓          ↓          ↓
目录结构  环境配置  节点配置  主配置   配置生成  编译配置   脚本      HA系统   子通道同步   测试验证    文档
```

---

## 验收标准

### 配置生成
1. `./scripts/gen-cfg.sh single` 生成单机模式配置
2. `./scripts/gen-cfg.sh node_a ...` 生成节点 A 配置
3. `./scripts/gen-cfg.sh node_b ...` 生成节点 B 配置
4. 单机模式 `opensips -c` 语法检查通过
5. 集群模式 `opensips -c` 语法检查通过

### 编译
6. `make config && make` 成功编译（包含所有模块）

### 部署
7. `./scripts/deploy.sh single` 成功部署单机模式
8. `./scripts/deploy.sh node_a ...` 成功部署节点 A
9. `./scripts/deploy.sh node_b ...` 成功部署节点 B
10. `./scripts/sync-to-peer.sh` 成功同步配置到对端

### 功能验证
11. 设备在节点 A 注册，节点 B 能查询到相同记录
12. 设备 Catalog 在节点 A 写入，节点 B 同步成功
13. 设备注销时，两边都删除记录
14. VIP 漂移后，设备重新注册成功，数据完整
15. 重启后数据从对端恢复

---

## 参考

- OpenSIPS 官方模板化文档：`/root/work/zf2zf/opensips/opensips/docs/manual/Templating-Config-Files.md`
- usrloc 模块：`/root/work/zf2zf/opensips/opensips/modules/usrloc/README`
- clusterer 模块：`/root/work/zf2zf/opensips/opensips/modules/clusterer/README`
- mi_script 模块：`/root/work/zf2zf/opensips/opensips/modules/mi_script/README.md`
- sqlops 模块：`/root/work/zf2zf/opensips/opensips/modules/sqlops/README.md`
