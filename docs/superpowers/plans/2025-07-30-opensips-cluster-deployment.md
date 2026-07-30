# OpenSIPS GB28181 代理集群部署实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 OpenSIPS GB28181 代理从单机部署改造为支持单机/集群双模式部署，实现两节点 usrloc 数据集群同步。

**Architecture:** 通过配置文件分离实现单机/集群模式切换。单机模式保持现有 `sql-only` 行为；集群模式切换到 `full-sharing-cluster`，通过 clusterer binary 协议同步 usrloc 数据，子通道操作使用 `mi("add")` / `mi("rm_contact")` 触发同步。

**Tech Stack:** OpenSIPS 4.0, SQLite, clusterer, proto_bin, mi_script

---

## Global Constraints

- OpenSIPS 版本：4.0
- 数据库：SQLite（仅本地写入，不用于实时同步）
- 集群同步协议：clusterer binary（TCP）
- 配置文件格式：OpenSIPS cfg 脚本
- 不开发新模块，所有功能通过配置实现
- 子通道操作使用 `mi_script` 模块的 `mi()` 函数

---

## 文件架构

```
/etc/opensips/
├── opensips_proxy.cfg       # 主配置（条件加载）
├── local.cfg                # 本机基础参数（始终加载）
├── ha.cfg                   # HA 模式声明（mode=single 或 mode=cluster）
└── cluster/
    ├── node_a.cfg           # 节点 A 拓扑
    └── node_b.cfg           # 节点 B 拓扑
```

---

## Task 1: 创建基础配置文件（ha.cfg / local.cfg）

**Files:**
- Create: `etc/ha.cfg`
- Create: `etc/local.cfg`

**Interfaces:**
- Produces: `mode` 变量（single 或 cluster）、`node_id`、`local_ip`、`peer_ip`、`vip`

- [ ] **Step 1: 创建 ha.cfg（OpenSIPS 运行时配置）**

```bash
# /etc/opensips/ha.cfg
# HA 部署模式：single = 单机部署，cluster = 集群部署
# 此文件在 OpenSIPS 运行时加载，通过 $mode 变量控制行为
mode=single
```

```bash
# 创建空目录占位
mkdir -p /etc/opensips/cluster
```

- [ ] **Step 2: 创建 local.cfg（OpenSIPS 运行时配置）**

```bash
# /etc/opensips/local.cfg
# 本机基础配置（所有部署模式共享）
# 此文件在 OpenSIPS 运行时加载

# 节点标识
node_id=1

# 网络配置
local_ip=127.0.0.1
peer_ip=127.0.0.1
vip=127.0.0.1
socket_port=5060

# 集群通信端口（mode=cluster 时使用）
bin_port=5566
```

**说明**：ha.cfg 和 local.cfg 使用简单的 shell 格式，在 opensips_proxy.cfg 中通过 `include_file` 加载后，定义的变量（如 `$mode`、`$node_id`）可在运行时使用。

- [ ] **Step 3: 提交**

```bash
git add etc/ha.cfg etc/local.cfg
git commit -m "feat: 添加 ha.cfg 和 local.cfg 基础配置
- ha.cfg: 定义 mode=single 或 mode=cluster
- local.cfg: 定义 node_id、local_ip、peer_ip、vip 等
- 配置在运行时加载，无需重新编译即可切换模式"
```

---

## Task 2: 创建集群节点配置文件

**Files:**
- Create: `etc/cluster/node_a.cfg`
- Create: `etc/cluster/node_b.cfg`

**Interfaces:**
- Consumes: `node_id`、`local_ip`、`peer_ip`、`bin_port`（来自 local.cfg）
- Produces: clusterer 模块的 `my_node_info` 和 `neighbor_node_info` 配置

- [ ] **Step 1: 创建 cluster 目录并添加 .gitkeep**

```bash
mkdir -p /etc/opensips/cluster
touch /etc/opensips/cluster/.gitkeep
```

- [ ] **Step 2: 创建节点 A 配置**

```bash
# /etc/opensips/cluster/node_a.cfg
# 节点 A 配置（硬编码 node_id=1）
# 通过 ifdef(`NODE_ID_1') 选择性加载

modparam("clusterer", "my_node_info", "cluster_id=1, node_id=1, url=bin:$local_ip:$bin_port, flags=seed")
modparam("clusterer", "neighbor_node_info", "cluster_id=1, node_id=2, url=bin:$peer_ip:$bin_port")
```

- [ ] **Step 3: 创建节点 B 配置**

```bash
# /etc/opensips/cluster/node_b.cfg
# 节点 B 配置（node_id=2）
# 注意：此文件仅在 mode=cluster 时加载

modparam("clusterer", "my_node_info", "cluster_id=1, node_id=2, url=bin:$local_ip:$bin_port, flags=seed")
modparam("clusterer", "neighbor_node_info", "cluster_id=1, node_id=1, url=bin:$peer_ip:$bin_port")
```

- [ ] **Step 4: 提交**

```bash
git add etc/cluster/
git commit -m "feat: 添加集群节点配置文件 node_a.cfg 和 node_b.cfg"
```

---

## Task 3: 修改 opensips_proxy.cfg 支持运行时模式切换

**Files:**
- Modify: `etc/opensips_proxy.cfg:1-20`（全局参数和 include 段）
- Modify: `etc/opensips_proxy.cfg:49-64`（模块加载和 modparam 段）
- Modify: `etc/opensips_proxy.cfg:114-133`（route[register]）
- Modify: `etc/opensips_proxy.cfg:214-246`（route[process_catalog]）

**Interfaces:**
- Consumes: `mode`、`node_id`、`local_ip`、`peer_ip`、`vip`（来自 local.cfg）
- Produces: 支持单机/集群模式切换的 opensips_proxy.cfg

**说明**：由于 `ifdef` 是编译时检查，而 `ha.cfg mode` 是部署时配置，采用运行时条件加载。所有模块（包括集群模块）统一编译，部署时通过配置决定是否加载集群相关参数。

- [ ] **Step 1: 添加集群模块加载（所有模块统一编译）**

在现有 `loadmodule` 段之后添加集群模块（始终加载，由配置决定是否启用）：

```bash
# === 集群通信协议（始终编译，运行时启用）===
loadmodule "proto_bin.so"
loadmodule "proto_bins.so"

# === 集群拓扑管理（始终编译，运行时启用）===
loadmodule "clusterer.so"

# === MI 脚本接口（用于子通道操作）===
loadmodule "mi_script.so"
```

- [ ] **Step 2: 修改 usrloc 配置支持运行时切换**

**当前代码**：
```bash
modparam("usrloc", "working_mode_preset", "sql-only")
```

**替换为**（在 ha.cfg include 之后）：

```bash
# === HA 模式配置（根据部署方式切换）===
# 通过 ha.cfg 定义 mode=single 或 mode=cluster
include_file "/etc/opensips/ha.cfg"

# 根据 mode 设置 usrloc 模式
if ($mode == "cluster") {
    # 集群模式：full-sharing-cluster，数据通过 clusterer 同步
    modparam("usrloc", "working_mode_preset", "full-sharing-cluster")
    modparam("usrloc", "location_cluster", 1)
} else {
    # 单机模式：sql-only，直接操作 SQLite
    modparam("usrloc", "working_mode_preset", "sql-only")
}
```

- [ ] **Step 3: 添加集群模式额外参数**

```bash
# === 集群模式额外配置（仅 mode=cluster 时生效）===
if ($mode == "cluster") {
    # clusterer 参数
    modparam("clusterer", "db_mode", 0)  # 动态学习节点拓扑
    modparam("clusterer", "ping_interval", 4)
    modparam("clusterer", "ping_timeout", 1000)
    modparam("clusterer", "node_timeout", 60)
    modparam("clusterer", "seed_fallback_interval", 10)

    # proto_bin 监听集群通信端口
    listen = bin:$local_ip:$bin_port

    # mi_script 参数
    modparam("mi_script", "pretty_printing", 1)

    # 根据 node_id 加载节点配置
    if ($node_id == 1) {
        include_file "/etc/opensips/cluster/node_a.cfg"
    } else {
        include_file "/etc/opensips/cluster/node_b.cfg"
    }

    xlog("L_INFO", "CLUSTER: starting in cluster mode, node_id=$node_id\n");
}
```

- [ ] **Step 4: 提交**

```bash
git add etc/opensips_proxy.cfg
git commit -m "feat: 修改为运行时模式切换（无需重新编译）
- 集群模块统一编译，部署时通过 mode 决定是否启用
- usrloc 模式根据 mode=single/cluster 动态配置
- clusterer 参数在 mode=cluster 时加载"
```

---

## Task 4: 实现配置加载逻辑（支持真实配置值）

**Files:**
- Modify: `etc/local.cfg`
- Modify: `etc/opensips_proxy.cfg`（添加配置解析路由）

**Interfaces:**
- Consumes: local.cfg 文件内容
- Produces: 正确的 `$var(local_ip)`、`$var(peer_ip)` 等变量值

**问题**：OpenSIPS cfg 不支持直接解析 key=value 文件。需要使用 `eval_pipek` 或 `cfg` 框架。

**替代方案**：使用预编译 `define`，在编译前通过脚本替换：

- [ ] **Step 1: 创建配置生成脚本**

```bash
#!/bin/bash
# /usr/local/bin/generate-opensips-cfg.sh
# 根据部署环境生成 OpenSIPS 配置文件

set -e

LOCAL_CFG="/etc/opensips/local.cfg"
OUTPUT_CFG="/etc/opensips/opensips_proxy_generated.cfg"
TEMPLATE_CFG="/etc/opensips/opensips_proxy.cfg"

# 读取 local.cfg
source "$LOCAL_CFG"

# 生成配置（替换变量）
sed -e "s/\$local_ip/$local_ip/g" \
    -e "s/\$peer_ip/$peer_ip/g" \
    -e "s/\$vip/$vip/g" \
    -e "s/\$node_id/$node_id/g" \
    -e "s/\$bin_port/$bin_port/g" \
    -e "s/\$socket_port/$socket_port/g" \
    -e "s/\$ha_mode/$ha_mode/g" \
    "$TEMPLATE_CFG" > "$OUTPUT_CFG"

echo "Generated config: $OUTPUT_CFG"
```

- [ ] **Step 2: 更新 local.cfg 为真实配置格式**

```bash
# /etc/opensips/local.cfg
# HA 部署模式
ha_mode=cluster

# 节点标识（部署时修改）
node_id=1

# 网络配置
local_ip=20.20.136.66
peer_ip=20.20.136.67
vip=20.20.136.100
socket_port=5060

# 集群通信端口
bin_port=5566
```

**注意**：`node_id` 用于生成 `NODE_ID_n` 预编译 define，例如 `node_id=1` 会生成 `define(`NODE_ID_1', `1')`。

- [ ] **Step 3: 修改 opensips_proxy.cfg 使用变量替换**

```bash
# 在 opensips_proxy.cfg 开头添加生成标记
# GENERATED_CONFIG - DO NOT EDIT DIRECTLY
# 此文件由 generate-opensips-cfg.sh 生成

# 使用实际的 IP 地址替换模板变量
listen = udp:$local_ip:$socket_port AS $vip:$socket_port
listen = bin:$local_ip:$bin_port

ifdef(`CLUSTER_MODE', `
    modparam("clusterer", "my_node_info", "cluster_id=1, node_id=$node_id, url=bin:$local_ip:$bin_port, flags=seed")
    # 邻居节点：根据 node_id 确定（硬编码两节点关系）
    # node_id=1 的邻居是 node_id=2，node_id=2 的邻居是 node_id=1
    modparam("clusterer", "neighbor_node_info", "cluster_id=1, node_id=2, url=bin:$peer_ip:$bin_port")
')
```

- [ ] **Step 4: 提交**

```bash
git add etc/local.cfg
git commit -m "feat: 更新 local.cfg 支持真实配置值
- 添加 ha_mode/node_id/local_ip/peer_ip/vip/socket_port/bin_port
- 添加配置生成脚本模板"
```

---

## Task 5: 实现单机模式验证

**Files:**
- Modify: `etc/ha.cfg`（设置为单机模式）
- Modify: `etc/local.cfg`（设置 node_id=1, local_ip=127.0.0.1）

**Interfaces:**
- Consumes: mode=single
- Produces: 验证单机模式与现有行为一致

- [ ] **Step 1: 配置为单机模式**

```bash
# /etc/opensips/ha.cfg
mode=single
```

```bash
# /etc/opensips/local.cfg
ha_mode=single
node_id=1
local_ip=127.0.0.1
peer_ip=127.0.0.1
vip=127.0.0.1
socket_port=5060
bin_port=5566
```

- [ ] **Step 2: 验证 opensipsProxy 语法**

```bash
opensips -c /etc/opensips/opensips_proxy.cfg 2>&1 | head -50
# 期望：无错误，只有警告
```

- [ ] **Step 3: 提交**

```bash
git commit -m "test: 验证单机模式配置正常
- ha.cfg 设置 mode=single
- 验证 opensips -c 语法检查通过"
```

---

## Task 6: 实现集群模式基础配置

**Files:**
- Modify: `etc/ha.cfg`（设置为集群模式）
- Modify: `etc/local.cfg`（设置真实 IP）

**Interfaces:**
- Consumes: mode=cluster, node_id, local_ip, peer_ip
- Produces: 集群模式基础配置

- [ ] **Step 1: 节点 A 配置**

```bash
# /etc/opensips/ha.cfg
mode=cluster
```

```bash
# /etc/opensips/local.cfg (节点 A)
ha_mode=cluster
node_id=1
local_ip=20.20.136.66
peer_ip=20.20.136.67
vip=20.20.136.100
socket_port=5060
bin_port=5566
```

- [ ] **Step 2: 验证节点 A 配置语法**

```bash
opensips -c /etc/opensips/opensips_proxy.cfg 2>&1 | head -50
# 期望：clusterer 模块加载成功
```

- [ ] **Step 3: 提交**

```bash
git commit -m "feat: 添加集群模式基础配置
- ha.cfg 设置 mode=cluster
- 添加节点 A 本地配置"
```

---

## Task 7: 实现子通道同步（mi("add") / mi("rm_contact")）

**Files:**
- Modify: `etc/opensips_proxy.cfg:214-246`（route[process_catalog]）
- Modify: `etc/opensips_proxy.cfg:114-133`（route[register]）

**Interfaces:**
- Consumes: `mode=cluster`、`mi_script` 模块
- Produces: 子通道通过 `mi("add")` 写入并触发集群同步

- [ ] **Step 1: 将 route[process_catalog] 中的 sql_query 替换为 mi("add")**

**当前代码（约 line 236-238）**：
```bash
sql_query("DELETE FROM location WHERE username='$avp(chan_id)'");
sql_query("INSERT INTO location (username, domain, contact, expires, q, callid, cseq, last_modified, flags, user_agent, socket, attr)
    VALUES ('$avp(chan_id)', '$fd', '$avp(recorder_contact)', 1790000000, -1.0, '$ci', 9999, datetime('now', 'localtime'), 0, '$avp(channel_ua)', 'udp:$socket_in(ip):$socket_in(port)', '$avp(channel_attr)')");
```

**替换为**：
```bash
# 构造 mi() 调用参数
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
    xlog("L_INFO", "CATALOG: mi add channel $avp(chan_id) failed: $var(ret)\n");
} else {
    xlog("L_INFO", "CATALOG: mi add channel $avp(chan_id) ok\n");
}
```

- [ ] **Step 2: 将 route[register] 中的 sql DELETE 替换为 mi("rm_contact")**

**当前代码（约 line 122-125）**：
```bash
if ($avp(expires_hdr) == "0") {
    sql_query("DELETE FROM location WHERE attr LIKE '%' || '$tu' || '%'");
    xlog("L_INFO", "REGISTER: child channels cleaned for $tu\n");
}
```

**替换为**：
```bash
if ($avp(expires_hdr) == "0") {
    # 通过 mi("rm_contact") 删除该设备所有子通道
    # 需要先查找该设备的子通道
    sql_query("SELECT username FROM location WHERE attr LIKE '%' || '$tu' || '%'", "ra");
    while ($(avp(ra)[0]) != NULL) {
        $avp(del_chan_id) = $(avp(ra)[0]);
        sql_query("DELETE FROM location WHERE username='$avp(del_chan_id)'");
        $avp(params) = "table_name";
        $avp(vals) = "location";
        $avp(params) = "aor";
        $avp(vals) = $avp(del_chan_id);
        $avp(params) = "contact";
        $avp(vals) = "";
        mi("rm_contact", $var(ret), $avp(params), $avp(vals));
        xlog("L_INFO", "REGISTER: child channel $avp(del_chan_id) cleaned\n");
    }
}
```

**简化方案（因为是集群模式，直接用 SQL 删除本地 + clusterer 同步）**：
```bash
if ($avp(expires_hdr) == "0") {
    # 先删除本地 SQLite 中的子通道记录
    # 在 full-sharing-cluster 模式下，clusterer 会自动同步删除操作到对端
    sql_query("DELETE FROM location WHERE attr LIKE '%' || '$tu' || '%'");
    xlog("L_INFO", "REGISTER: child channels cleaned for $tu (cluster sync will follow)\n");
}
```

**注意**：在 `full-sharing-cluster` 模式下，`sql_query("DELETE ...")` 只删除本地 SQLite 记录，**不会触发集群同步**。需要改用 `mi("rm_contact")`。

**最终正确实现**：
```bash
if ($avp(expires_hdr) == "0") {
    # 查找该设备的所有子通道并逐个通过 mi 删除
    # 这样可以触发集群同步
    $var(i) = 0;
    while ($var(i) < 1000) {
        $avp(chan_id) = $(ssql("ra", "SELECT username FROM location WHERE attr LIKE '%' || '$tu' || '%' LIMIT 1 OFFSET $var(i)")[0]);
        if ($avp(chan_id) == NULL || $(avp(chan_id){s.len}) == 0)
            break;
        
        $avp(params) = "table_name";
        $avp(vals) = "location";
        $avp(params) = "aor";
        $avp(vals) = $avp(chan_id);
        $avp(params) = "contact";
        $avp(vals) = "";
        mi("rm_contact", $var(ret), $avp(params), $avp(vals));
        $var(i) = $var(i) + 1;
    }
    xlog("L_INFO", "REGISTER: child channels cleaned for $tu via cluster sync\n");
}
```

**注意**：`ssql()` 是 `sqlops` 模块提供的函数，用于直接执行 SQL 并返回结果。

- [ ] **Step 3: 提交**

```bash
git commit -m "feat: 将子通道操作改为 mi() 调用触发集群同步
- route[process_catalog]: sql_query INSERT → mi(\"add\")
- route[register]: sql_query DELETE → mi(\"rm_contact\")"
```

---

## Task 8: 集群模式端到端测试

**Files:**
- Test: 两台服务器的实际部署测试

**测试用例**：

- [ ] **Test 1: 节点 A 注册设备，节点 B 应能查询到**

```bash
# 节点 A 上注册设备
sipregister ... # 设备连接到 VIP 或节点 A IP

# 节点 B 上查询
sqlite3 /var/lib/opensips/opensips.db "SELECT * FROM location;"
# 期望：看到设备记录

# 通过 MI 查询
opensipsctl fifo ul_dump
```

- [ ] **Test 2: 节点 A 收到 Catalog，节点 B 应同步子通道**

```bash
# 设备发送 Catalog MESSAGE 到节点 A

# 节点 A 查询
sqlite3 /var/lib/opensips/opensips.db "SELECT username FROM location WHERE q=-1.0;"

# 节点 B 查询
sqlite3 /var/lib/opensips/opensips.db "SELECT username FROM location WHERE q=-1.0;"
# 期望：两边都有相同的子通道记录
```

- [ ] **Test 3: 节点 A 设备注销，节点 B 应同步删除**

```bash
# 设备发送注销 REGISTER 到节点 A（Expires=0）

# 两边查询
sqlite3 /var/lib/opensips/opensips.db "SELECT * FROM location;"
# 期望：两边都没有该设备的任何记录
```

- [ ] **Test 4: VIP 漂移测试**

```bash
# Keepalived 触发 VIP 漂移到节点 B

# 设备重连到 VIP
# 期望：设备能正常注册，子通道数据完整
```

- [ ] **Test 5: 重启后数据恢复**

```bash
# 重启节点 A
systemctl restart opensips

# 检查节点 A 是否从节点 B 恢复数据
sqlite3 /var/lib/opensips/opensips.db "SELECT * FROM location;"
# 期望：数据完整恢复
```

---

## Task 9: 更新文档

**Files:**
- Modify: `docs/opensips_gb28181_proxy.md`
- Create: `docs/cluster-deployment-guide.md`

- [ ] **Step 1: 更新 GB28181 代理调研报告**

添加集群部署相关章节。

- [ ] **Step 2: 创建集群部署指南**

```bash
# 创建 /docs/cluster-deployment-guide.md
```

内容包括：
- 硬件/网络要求
- 配置文件说明
- 部署步骤（单机模式、集群模式）
- 故障排查
- 维护操作

- [ ] **Step 3: 提交**

```bash
git add docs/
git commit -m "docs: 添加集群部署指南和使用文档"
```

---

## Task 10: 创建编译配置和构建脚本

**Files:**
- Create: `Makefile.conf`（统一编译模块配置，包含所有模块）
- Create: `scripts/build.sh`（构建脚本）

**说明**：单机和集群使用同一套程序，仅在部署时通过配置切换模式。编译时包含所有模块（基础 + 集群）。

**Interfaces:**
- Produces: `Makefile.conf` 和 `build.sh`

- [ ] **Step 1: 创建统一的 Makefile.conf（包含所有模块）**

```makefile
# Makefile.conf - OpenSIPS GB28181 代理统一编译配置
# 单机和集群使用同一套程序，仅部署时配置不同
# 用法：cp Makefile.conf /root/work/zf2zf/opensips/opensips/ && cd /root/work/zf2zf/opensips/opensips/ && make config && make

# === 基础模块（单机/集群都需要）===
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

# === 集群模式模块（部署时选择是否启用）===
clusterer=1
proto_bin=1
proto_bins=1
mi_script=1
```

- [ ] **Step 2: 创建构建脚本**

```bash
#!/bin/bash
# scripts/build.sh - OpenSIPS GB28181 代理构建脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENSIPS_DIR="/root/work/zf2zf/opensips/opensips"
MAKEFILE_CONF="$OPENSIPS_DIR/Makefile.conf"

usage() {
    echo "Usage: $0 [build|clean|install]"
    echo "  build   - 编译 OpenSIPS（包含所有模块）"
    echo "  clean   - 清理构建"
    echo "  install - 安装编译结果"
    exit 1
}

build() {
    echo "=== Building OpenSIPS (all modules) ==="
    cd "$OPENSIPS_DIR"
    if [ ! -f "$MAKEFILE_CONF" ]; then
        cp "$SCRIPT_DIR/Makefile.conf" "$MAKEFILE_CONF"
    fi
    make clean
    make config
    make -j$(nproc)
    echo "=== Build Complete ==="
}

install_opensips() {
    echo "=== Installing OpenSIPS ==="
    cd "$OPENSIPS_DIR"
    make install
    echo "=== Install Complete ==="
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
git add scripts/build.sh
git commit -m "feat: 添加统一编译配置和构建脚本
- Makefile.conf: 包含所有模块（基础+集群），一次编译通用于单机/集群部署
- scripts/build.sh: 自动化构建脚本"
```

---

## Task 11: 创建部署脚本

**Files:**
- Create: `scripts/deploy.sh`（主部署脚本）
- Create: `scripts/sync-to-peer.sh`（节点间配置同步脚本）

**说明**：同一套程序和配置，部署时通过 ha.cfg 的 `mode` 字段切换单机/集群模式，无需重新编译。

**Interfaces:**
- Produces: 自动化部署脚本

- [ ] **Step 1: 创建部署脚本**

```bash
#!/bin/bash
# scripts/deploy.sh - OpenSIPS GB28181 代理部署脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOY_DIR="/etc/opensips"
BACKUP_DIR="/etc/opensips.bak.$(date +%Y%m%d_%H%M%S)"

usage() {
    echo "Usage: $0 [deploy|validate|backup|restore]"
    echo "  deploy    - 部署到 /etc/opensips（根据 ha.cfg 中的 mode 字段决定模式）"
    echo "  validate - 验证配置语法"
    echo "  backup   - 备份现有配置"
    echo "  restore  - 从备份恢复"
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
    echo "=== Deploying OpenSIPS GB28181 Proxy ==="

    # 检查 ha.cfg 中的 mode
    if [ ! -f "$DEPLOY_DIR/ha.cfg" ]; then
        echo "Error: $DEPLOY_DIR/ha.cfg not found"
        exit 1
    fi

    source "$DEPLOY_DIR/ha.cfg"
    echo "Deploying mode: $mode"

    # 备份现有配置
    backup_config

    # 复制配置文件
    cp etc/opensips_proxy.cfg "$DEPLOY_DIR/"
    cp etc/local.cfg "$DEPLOY_DIR/"
    cp etc/ha.cfg "$DEPLOY_DIR/"

    # 复制集群节点配置（如有）
    if [ -d "etc/cluster" ]; then
        mkdir -p "$DEPLOY_DIR/cluster"
        cp etc/cluster/*.cfg "$DEPLOY_DIR/cluster/"
    fi

    # 创建必要目录
    mkdir -p "$DEPLOY_DIR/dbtext/dispatcher"
    mkdir -p /var/lib/opensips
    mkdir -p /var/log/opensips

    # 设置权限
    chown -R opensips:opensips "$DEPLOY_DIR" 2>/dev/null || true
    chown -R opensips:opensips /var/lib/opensips 2>/dev/null || true
    chown -R opensips:opensips /var/log/opensips 2>/dev/null || true

    # 验证配置
    opensips -c "$DEPLOY_DIR/opensips_proxy.cfg"

    echo "=== Deployed ($mode mode) ==="
}

validate() {
    echo "=== Validating config ==="
    opensips -c "$DEPLOY_DIR/opensips_proxy.cfg"
    echo "=== Validation OK ==="
}

restore() {
    echo "=== Restoring from Backup ==="
    if [ -d "$BACKUP_DIR" ]; then
        rm -rf "$DEPLOY_DIR"
        cp -r "$BACKUP_DIR" "$DEPLOY_DIR"
        echo "Restored from: $BACKUP_DIR"
    else
        echo "Error: No backup found"
        exit 1
    fi
}

case "${1:-}" in
    deploy) deploy ;;
    validate) validate ;;
    backup) backup_config ;;
    restore) restore ;;
    *) usage ;;
esac
```

- [ ] **Step 2: 创建节点间配置同步脚本**

```bash
#!/bin/bash
# scripts/sync-to-peer.sh - 将配置同步到对等节点

set -e

LOCAL_CFG="/etc/opensips/local.cfg"

if [ ! -f "$LOCAL_CFG" ]; then
    echo "Error: $LOCAL_CFG not found"
    exit 1
fi

source "$LOCAL_CFG"

RSYNC_OPTS="-az --delete -e ssh"
SRC_DIR="/etc/opensips"

echo "=== Syncing config to peer ($peer_ip) ==="
rsync $RSYNC_OPTS \
    "$SRC_DIR/local.cfg" \
    "$SRC_DIR/ha.cfg" \
    "$SRC_DIR/cluster/" \
    "$SRC_DIR/opensips_proxy.cfg" \
    "root@$peer_ip:$SRC_DIR/"

echo "=== Sync Complete ==="
```

- [ ] **Step 3: 设置脚本可执行权限并提交**

```bash
chmod +x scripts/*.sh
git add scripts/
git commit -m "feat: 添加部署和配置同步脚本
- scripts/deploy.sh: 自动化部署（mode 由 ha.cfg 决定，无需重新编译）
- scripts/sync-to-peer.sh: 节点间配置同步
- scripts/build.sh: 编译构建脚本（Task 10）"
```

---

## Task 12: 创建 systemd 服务和 Keepalived 配置

**Files:**
- Create: `systemd/opensips-gb28181.service`
- Create: `systemd/keepalived-check.sh`
- Create: `keepalived/keepalived.conf.node_a`
- Create: `keepalived/keepalived.conf.node_b`

- [ ] **Step 1: 创建 systemd 服务文件**

```ini
# /etc/systemd/system/opensips-gb28181.service
[Unit]
Description=OpenSIPS GB28181 SIP Proxy
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/sbin/opensips -D -f /etc/opensips/opensips_proxy.cfg
PIDFile=/var/run/opensips.pid
Restart=on-failure
RestartSec=5
User=opensips
Group=opensips

[Install]
WantedBy=multi-user.target
```

- [ ] **Step 2: 创建 Keepalived 检查脚本**

```bash
#!/bin/bash
# /etc/keepalived/chk_opensips.sh
# Keepalived 调用此脚本检测 OpenSIPS 进程是否存活

if pgrep -x opensips > /dev/null 2>&1; then
    exit 0
else
    exit 1
fi
```

- [ ] **Step 3: 创建 Keepalived 配置（节点 A）**

```bash
# /etc/keepalived/keepalived.conf.node_a
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
        20.20.136.100 dev eth0
    }
    track_script {
        chk_opensips
    }
}

vrrp_script chk_opensips {
    script "/etc/keepalived/chk_opensips.sh"
    interval 2
    weight -20
}
```

- [ ] **Step 4: 创建 Keepalived 配置（节点 B）**

```bash
# /etc/keepalived/keepalived.conf.node_b
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
        20.20.136.100 dev eth0
    }
    track_script {
        chk_opensips
    }
    notify_master "/etc/keepalived/notify.sh master"
    notify_backup "/etc/keepalived/notify.sh backup"
    notify_fault "/etc/keepalived/notify.sh fault"
}

vrrp_script chk_opensips {
    script "/etc/keepalived/chk_opensips.sh"
    interval 2
    weight -20
}
```

- [ ] **Step 5: 创建 Keepalived notify 脚本**

```bash
#!/bin/bash
# /etc/keepalived/notify.sh
# VIP 状态变更时执行，动态管理 iptables 和 OpenSIPS 配置

VIP="20.20.136.100"
LOCAL_IP="20.20.136.67"
LOCAL_CFG="/etc/opensips/local.cfg"

case "$1" in
    master)
        iptables -t nat -A PREROUTING -d $VIP -p udp --dport 5060 -j DNAT --to-destination $LOCAL_IP:5060 2>/dev/null
        sed -i "s/^socket=.*/socket=udp:$LOCAL_IP:5060 AS $VIP:5060/" "$LOCAL_CFG"
        systemctl reload opensips
        ;;
    backup)
        iptables -t nat -D PREROUTING -d $VIP -p udp --dport 5060 -j DNAT --to-destination $LOCAL_IP:5060 2>/dev/null
        sed -i "s/ AS $VIP:5060//" "$LOCAL_CFG"
        systemctl reload opensips
        ;;
    fault)
        iptables -t nat -D PREROUTING -d $VIP -p udp --dport 5060 -j DNAT --to-destination $LOCAL_IP:5060 2>/dev/null
        ;;
esac
```

- [ ] **Step 6: 提交**

```bash
git add systemd/ keepalived/
git commit -m "feat: 添加 systemd 服务和 Keepalived 配置
- systemd/opensips-gb28181.service
- keepalived/keepalived.conf.node_a
- keepalived/keepalived.conf.node_b
- keepalived/notify.sh"
```

---

## 实施顺序

```
Task 1 → Task 2 → Task 3 → Task 5 → Task 6 → Task 7 → Task 8 → Task 9 → Task 10 → Task 11 → Task 12
  ↓         ↓        ↓         ↓          ↓          ↓          ↓         ↓        ↓         ↓          ↓
基础配置  节点配置  运行时切换  单机验证   集群基础   子通道同步   测试      文档    编译脚本   部署脚本   HA配置
```

---

## 依赖关系

```
Task 1 (ha.cfg + local.cfg)
    ↓
Task 2 (cluster/node_*.cfg) ← Task 1 完成
    ↓
Task 3 (opensips_proxy.cfg 运行时切换) ← Task 1, 2 完成
    ↓
Task 5 (单机验证) ← Task 3 完成
    ↓
Task 6 (集群配置) ← Task 5 验证通过
    ↓
Task 7 (子通道同步) ← Task 6 完成
    ↓
Task 8 (测试) ← Task 7 完成
    ↓
Task 9 (文档) ← Task 8 完成
    ↓
Task 10 (编译配置) ← Task 9 完成
    ↓
Task 11 (部署脚本) ← Task 10 完成
    ↓
Task 12 (HA配置) ← Task 11 完成
```

---

## 验收标准

### 配置和编译
1. `make config && make` 成功编译（包含所有模块）
2. 单机模式（ha.cfg 中 `mode=single`）`opensips -c` 语法检查通过
3. 集群模式（ha.cfg 中 `mode=cluster`）`opensips -c` 语法检查通过
4. 切换 mode 后只需 `systemctl restart opensips` 即可切换模式

### 功能验证
5. 设备在节点 A 注册，节点 B 能查询到相同记录
6. 设备 Catalog 在节点 A 写入，节点 B 同步成功
7. 设备注销时，两边都删除记录
8. VIP 漂移后，设备重新注册成功，数据完整
9. 重启后数据从对端恢复

### 部署验证
10. `./scripts/deploy.sh deploy` 根据 ha.cfg 部署成功
11. `./scripts/sync-to-peer.sh` 成功同步配置到对端
12. Keepalived 高可用切换正常
