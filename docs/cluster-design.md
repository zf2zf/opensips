# OpenSIPS GB28181 代理集群部署方案

## 1. 背景与目标

### 1.1 当前问题

现有 `opensips_proxy.cfg` 采用单机部署，存在以下问题：

- **SQLite 不同步**：两台机器各自维护独立 SQLite，VIP 漂移后设备需重新注册
- **数据丢失**：主备切换期间设备状态丢失
- **子通道独立于注册流程**：子通道通过 `sql_query("INSERT")` 直接写入 SQLite，绕过了 usrloc 的集群同步机制

### 1.2 目标

- 实现两节点 usrloc 数据集群同步
- 支持单机/集群两种部署方式（配置可切换）
- 主备 IP/VIP 通过独立配置文件管理
- 不开发新模块，纯配置脚本实现

---

## 2. 技术方案

### 2.1 集群模式选择

**选择：`full-sharing-cluster`**

| 模式 | 数据存储 | 集群同步方式 | SQL 写入 | 适用场景 |
|------|---------|------------|---------|---------|
| `sql-only` | 仅 SQLite | **不同步** | N/A | 单机 |
| `full-sharing-cluster` | 内存 + 本地 SQLite | clusterer binary 协议 | wb_timer 定时写回 | **两节点集群 ✓** |
| `federation-cluster` | 内存 + 本地 SQLite | clusterer binary 协议 | wb_timer 定时写回 | 多节点联盟 |
| `full-sharing-cachedb` | NoSQL 数据库 | N/A | N/A | 需要外部 NoSQL |

**为什么 `full-sharing-cluster` 适合两节点**：
- 每个节点维护完整 usrloc 内存数据集
- 所有 INSERT/UPDATE/DELETE 通过 clusterer 二进制协议同步到对端
- 对端节点通过 `wb_timer` 定时将内存数据写回本地 SQLite（用于重启恢复）

### 2.2 核心机制验证

#### 2.2.1 `sql-only` 不写 SQLite（代码确认）

```
sql-only → CM_SQL_ONLY → sql_wmode = SQL_NO_WRITE
```

- `insert_ucontact()` 只写内存，**跳过了 `db_insert_ucontact()`**
- `timer_urecord()` 对 `CM_SQL_ONLY` 调用 `nodb_timer()` — 空操作，不触发 DB 写入
- **结论**：`sql-only` 模式下 `save()` 只写内存，重启后数据丢失

#### 2.2.2 `full-sharing-cluster` 同步链路（代码确认）

```
insert_ucontact(urecord, contact, ci, match, skip_replication=0, &c)
    ↓
have_data_replication() == (CM_FULL_SHARING || CM_FEDERATION_CACHEDB) → true
    ↓
replicate_ucontact_insert(r, contact, c, match)
    ↓
clusterer_api.send_all() / send_all_having()
    ↓
对端节点 receive_binary_packets()
    ↓
wb_timer() 将数据写回本地 SQLite
```

**关键代码验证**：

```c
// urecord.c:877
if (!skip_replication && have_data_replication())
    replicate_ucontact_insert(_r, _contact, *_c, match);

// ul_mod.h:91
#define have_data_replication() \
    (cluster_mode == CM_FEDERATION_CACHEDB || \
     cluster_mode == CM_FULL_SHARING)

// ul_mod.c:570-572
} else if (!strcasecmp(runtime_preset, "full-sharing-cluster")) {
    cluster_mode = CM_FULL_SHARING;
    rr_persist = RRP_SYNC_FROM_CLUSTER;
    sql_wmode = SQL_NO_WRITE;  // 通过 wb_timer 写回，不直接写
```

#### 2.2.3 子通道通过 MI 命令触发同步

子通道无法使用 `save("location")`（无 SIP 事务上下文），改用 `mi_script` 模块的 `mi()` 函数调用 `ul_add` MI 命令：

```c
// ul_mi.c:469-542
mi_usrloc_add() {
    insert_ucontact(r, contact, &ci, &cmatch, 0, &c);  // skip_replication=0 ✓
}
```

**MI 调用语法**（已验证自 `mi_script` 模块）：

```bash
# 添加子通道 — mi("add", ret_var, params_avp, vals_avp)
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

# 删除子通道 — mi("rm_contact", ret_var, params_avp, vals_avp)
$avp(params) = "table_name";
$avp(vals) = "location";
$avp(params) = "aor";
$avp(vals) = $avp(chan_id);
$avp(params) = "contact";
$avp(vals) = $avp(recorder_contact);
mi("rm_contact", $var(ret), $avp(params), $avp(vals));
```

---

## 3. 配置文件架构

### 3.1 文件结构

```
/etc/opensips/
├── opensips_proxy.cfg       # 主配置（条件加载）
├── local.cfg                # 本机网络参数（始终加载）
├── ha.cfg                   # HA 模式声明（mode=single 或 mode=cluster）
└── cluster/
    ├── node_a.cfg           # 节点 A 拓扑（mode=cluster 时加载）
    └── node_b.cfg           # 节点 B 拓扑（mode=cluster 时加载）
```

### 3.2 配置加载逻辑

```bash
# local.cfg — 始终加载，定义本机基础参数
mode=single          # 或 cluster
node_id=1            # 1 或 2
local_ip=20.20.136.66
peer_ip=20.20.136.67
vip=20.20.136.100
socket_port=5060

# ha.cfg — 根据 mode 决定是否加载集群配置
# mode=single 时：跳过所有集群配置
# mode=cluster 时：加载 clusterer + proto_bin + 节点拓扑
```

### 3.3 单机部署

```
ha.cfg: mode=single
→ 不加载 clusterer.so / proto_bin.so
→ 不加载 cluster/node_*.cfg
→ usrloc 使用 sql-only 模式（现有行为）
```

### 3.4 集群部署

```
ha.cfg: mode=cluster
→ 加载 clusterer.so / proto_bin.so
→ 加载 cluster/node_*.cfg（根据 node_id 选择）
→ usrloc 使用 full-sharing-cluster 模式
```

---

## 4. 集群同步数据流

### 4.1 设备注册流程

```
设备 → REGISTER → save("location")
    ↓
写本机内存 usrloc
    ↓
clusterer binary 同步到对端内存
    ↓
对端 wb_timer 写回本地 SQLite
```

### 4.2 子通道写入流程

```
设备 → MESSAGE(Catalog) → 解析 XML
    ↓
mi("add", ...) → mi_usrloc_add()
    ↓
insert_ucontact(..., skip_replication=0)
    ↓
replicate_ucontact_insert()
    ↓
clusterer binary 同步到对端内存
    ↓
对端 wb_timer 写回本地 SQLite
```

### 4.3 设备注销流程

```
设备 → REGISTER(Expires=0) → save("location")
    ↓
删除主设备内存记录
    ↓
clusterer binary 同步删除到对端
    ↓
对端删除 SQLite 记录
    ↓
mi("rm_contact", ...) 清理残留子通道（如有）
```

---

## 5. 模块依赖

### 5.1 新增模块

| 模块 | 用途 | 备注 |
|------|------|------|
| `clusterer.so` | 集群拓扑管理、二进制通信 | 集群模式必选 |
| `proto_bin.so` | clusterer 通信协议 | 集群模式必选 |
| `mi_script.so` | 提供 `mi()` 函数调用 MI 命令 | 集群模式必选（子通道操作） |

### 5.2 单机模式模块

- `db_sqlite.so` — SQLite 驱动
- `usrloc.so` — `sql-only` 模式
- 现有所有模块

### 5.3 集群模式模块

- `db_sqlite.so` — SQLite 驱动（本地写入）
- `usrloc.so` — `full-sharing-cluster` 模式
- `clusterer.so` — 集群同步
- `proto_bin.so` — 集群通信协议
- `mi_script.so` — 子通道 MI 操作

---

## 6. 配置参数参考

### 6.1 usrloc 参数（集群模式）

```bash
# 集群模式
modparam("usrloc", "working_mode_preset", "full-sharing-cluster")
modparam("usrloc", "location_cluster", 1)
modparam("usrloc", "db_url", "sqlite:///var/lib/opensips/opensips.db")
# sql_write_mode 由 preset 自动设置为 SQL_NO_WRITE，SQLite 通过 wb_timer 写回

# 单机模式（保持现有配置）
modparam("usrloc", "working_mode_preset", "sql-only")
modparam("usrloc", "db_url", "sqlite:///var/lib/opensips/opensips.db")
```

### 6.2 clusterer 参数

```bash
# 基础参数
loadmodule "clusterer.so"
modparam("clusterer", "db_mode", 0)  # 动态学习节点拓扑，不依赖 DB

# 本机节点信息（node_a.cfg / node_b.cfg）
modparam("clusterer", "my_node_info", "cluster_id=1, node_id=1, url=bin:20.20.136.66:5566, flags=seed")
modparam("clusterer", "neighbor_node_info", "cluster_id=1, node_id=2, url=bin:20.20.136.67:5566")

# 探测参数
modparam("clusterer", "ping_interval", 4)
modparam("clusterer", "ping_timeout", 1000)
modparam("clusterer", "node_timeout", 60)
modparam("clusterer", "seed_fallback_interval", 10)
```

### 6.3 proto_bin 参数

```bash
# 监听集群通信端口
listen = bin:20.20.136.66:5566
```

---

## 7. 实现计划

### 7.1 Phase 1：配置分离

- [ ] 创建 `ha.cfg`，定义 `mode` 参数（single/cluster）
- [ ] 调整 `local.cfg`，添加 `node_id` / `local_ip` / `peer_ip` / `vip`
- [ ] 创建 `cluster/node_a.cfg` 和 `cluster/node_b.cfg`
- [ ] 修改 `opensips_proxy.cfg`，实现条件加载

### 7.2 Phase 2：单机模式验证

- [ ] 确保单机模式（mode=single）行为与现有配置一致
- [ ] 验证 `sql-only` 模式正常工作

### 7.3 Phase 3：集群模式实现

- [ ] 添加 `clusterer.so` / `proto_bin.so` / `mi_script.so` 模块
- [ ] 配置 `usrloc` 为 `full-sharing-cluster` 模式
- [ ] 配置 `clusterer` 节点拓扑
- [ ] 验证节点间 binary 通信

### 7.4 Phase 4：子通道同步

- [ ] 将 `route[process_catalog]` 中的 `sql_query("INSERT")` 替换为 `mi("add", ...)`
- [ ] 将设备注销时的 `sql_query("DELETE ...")` 替换为 `mi("rm_contact", ...)`

### 7.5 Phase 5：测试验证

- [ ] 单机部署测试
- [ ] 双机集群注册同步测试
- [ ] 双机集群子通道同步测试
- [ ] 主备切换测试（VIP 漂移 + 数据一致性）
- [ ] 重启后从对端恢复数据测试

---

## 8. 已知限制

1. **SQLite 不用于实时同步**：运行时同步完全依赖 clusterer binary 协议，SQLite 仅用于本地重启恢复
2. **重启恢复依赖对端节点**：重启后通过 `sync-from-cluster` 从对端拉取数据，要求至少有一台节点存活
3. **子通道无事务上下文**：`mi("add")` 是异步 MI 调用，不参与 SIP 事务，如果调用失败需要额外处理
4. **wb_timer 延迟写回**：`sql_wmode=SQL_NO_WRITE`，数据通过 `wb_timer` 定时批量写回 SQLite，极端情况下可能丢失少量最近更新

---

## 9. 参考

- OpenSIPS 4.0 usrloc 模块文档：`/root/work/zf2zf/opensips/opensips/modules/usrloc/README`
- OpenSIPS 4.0 clusterer 模块文档：`/root/work/zf2zf/opensips/opensips/modules/clusterer/README`
- OpenSIPS 4.0 mi_script 模块文档：`/root/work/zf2zf/opensips/opensips/modules/mi_script/README.md`
- GB28181 代理调研报告：`/root/work/zf2zf/opensips/opensips/docs/opensips_gb28181_proxy.md`

---

## 10. 调研结论

| 结论 | 依据 |
|------|------|
| `sql-only` 模式下 `save()` 不写 SQLite | 代码确认：`sql_wmode = SQL_NO_WRITE` + `nodb_timer()` 空操作 |
| `full-sharing-cluster` 支持集群同步 | 代码确认：`insert_ucontact(..., 0)` → `replicate_ucontact_insert()` → `clusterer_api.send_all()` |
| 子通道可通过 `mi("add")` 触发同步 | 代码确认：`mi_usrloc_add()` 调用 `insert_ucontact(..., 0, ...)` |
| 删除可通过 `mi("rm_contact")` 触发同步 | 代码确认：`mi_usrloc_rm_contact()` 调用 `delete_ucontact(..., 0)` |
| 无需开发新模块 | 所有功能通过现有模块 `mi_script` / `clusterer` / `usrloc` 实现 |
