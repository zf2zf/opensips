# OpenSIPS GB28181 代理主备（无 MySQL/PG/Redis）设计方案

**日期**：2026-07-28
**项目**：OpenSIPS 源码仓库 `/root/work/zf2zf/opensips/opensips`
**基线配置**：`etc/opensips_proxy.cfg`（GB28181 代理，单机 + 本地 SQLite）
**目标**：在基线配置上增加 2 节点主备高可用，**禁止使用 MySQL/PG/Redis**

---

## 1. 背景与动机

### 1.1 现状

`etc/opensips_proxy.cfg` 是一个 GB28181 SIP 信令代理，部署在设备和上游 EasyGBS 平台之间：

- **设备注册**（REGISTER）→ 写入本地 SQLite `location` 表
- **平台查询 / 视频呼叫**（MESSAGE / INVITE）→ 查 `location` 转发
- **Catalog 解析** → 直接 `sql_query` 写 SQLite 子通道
- **Keepalive 探测** → 查 location，未命中返回 401 触发重注册
- **上游平台分发** → dispatcher 选主备平台

数据全部在 `sqlite:///var/lib/opensips/opensips.db`，dispatcher 走 dbtext（`/etc/opensips/dbtext/dispatcher`）。

### 1.2 现有 HA 方案的问题

`docs/opensips_gb28181_proxy.md` 已经描述了 Keepalived + iptables + 每机独立 SQLite 的 HA 方案。它的不足：

- 主机故障 VIP 漂移到备机后，**备机 SQLite 是空的**，所有设备 lookup 失败
- 设备必须主动重连 + 重新 REGISTER 才能恢复（兜底是 Keepalive 401 触发）
- **没有解决 Catalog 子通道问题**：子通道是直写 SQLite，不走 usrloc；故障切换后子通道在备机上一条都没有 → 平台视频 INVITE 全部 404

### 1.3 本方案的目标

在**不引入 MySQL/PG/Redis** 的前提下：

1. **节点间共享 usrloc 主注册数据**（设备注册）
2. **节点间共享 dispatcher 上游平台状态**（SIP OPTIONS 探测）
3. **解决 Catalog 子通道的跨节点同步**
4. **节点 2 平时不接 SIP 流量**（最干净的故障边界）
5. **故障切换后业务可恢复**（不依赖平台主动重查）

---

## 2. 约束与决策

| 约束 | 决策 |
|---|---|
| 数据库 | 仅 SQLite（usrloc + clusterer 共用一份）+ dbtext（dispatcher），**不引入 MySQL/PG/Redis** |
| 节点规模 | 2 节点（active/standby），不留扩展 N 节点的接口 |
| 拓扑 | 主备（active/standby），节点 2 平时不接 SIP 流量 |
| 故障切换 | Keepalived + VIP 漂移 + 节点 2 接管 SIP 监听 |
| 节点间数据同步 | usrloc + dispatcher 走 `full-sharing-cluster`（clusterer BIN 协议） |
| Catalog 子通道同步 | 节点 1 直写 SQLite + `http_async_query` 异步重放到节点 2 HTTP 端 |
| 配置组织 | 3 个纯 .cfg 文件 + `include_file`，**不使用 m4** |

---

## 3. 架构

### 3.1 拓扑

```
                       ┌──────────────┐
        设备 ──SIP──▶  │     VIP      │  20.20.136.100:5060
                       └──────┬───────┘
                              │ Keepalived 漂移
              ┌───────────────┴───────────────┐
              │                               │
   ┌──────────▼──────────┐         ┌───────────▼─────────┐
   │ 节点1 (Active)      │ ◀─BIN──▶│ 节点2 (Standby)     │
   │  20.20.136.66       │  同步    │  20.20.136.67      │
   │  - OpenSIPS         │         │  - OpenSIPS         │
   │  - local SQLite     │         │  - local SQLite     │
   │  - clusterer        │         │  - clusterer        │
   │  - httpd            │ ◀─HTTP──▶│  - httpd           │
   │   角色=client       │  JSON    │   角色=server       │
   │   推 /replay/channel│  重放     │   收 /replay/channel│
   │  监听 SIP 5060      │         │  监听 BIN + httpd   │
   │                     │         │  不监听 SIP 5060    │
   └──────────┬──────────┘         └─────────┬───────────┘
              │ ds_select_dst(共享)            │
              └──────────┬────────────────────┘
                         ▼
                  ┌──────────────┐
                  │ 上游 EasyGBS │
                  │  (主/备)     │
                  └──────────────┘
```

### 3.2 关键事实

| 项 | 节点 1 (Active) | 节点 2 (Standby) |
|---|---|---|
| 绑定 VIP | 是 | 否 |
| 接 SIP 流量 | 是 | **否**（不监听 5060） |
| 监听 BIN 5566 | 是 | 是 |
| 监听 HTTP 8080 | 是（运行时角色由 HA 状态决定，见 §4.5） | 是（运行时角色由 HA 状态决定，见 §4.5） |
| SQLite 写入 | 是 | 通过 BIN + HTTP 重放接收 |
| `usrloc.working_mode_preset` | `full-sharing-cluster` | `full-sharing-cluster` |
| `dispatcher.cluster_probing_mode` | `by-shtag` | `by-shtag`（仅 active 节点探测） |
| `clusterer.cluster_id` | 1 | 1 |

### 3.3 数据流

| 业务事件 | 节点 1 行为 | 节点 2 接收方式 |
|---|---|---|
| 设备 REGISTER | `save("location")` → 本地 SQLite | usrloc + clusterer BIN 同步（自动） |
| 设备注销级联删除 | `sql_query("DELETE FROM location WHERE attr LIKE ...")` | **HTTP 异步重放**（`http_async_query`） |
| 设备 Catalog 响应 | `sql_query` 写 location（DELETE+INSERT） | **HTTP 异步重放** |
| 设备 Keepalive | `lookup("location")` 查询 | 本地 SQLite 已有副本（响应 200） |
| 平台查询 / INVITE | `lookup` + `ds_select_dst` 转发 | 本地 SQLite + dispatcher 共享 |
| 上游平台 SIP OPTIONS 探测 | 节点 1 探测（by-shtag） | 节点 2 不探测 |

**两条同步通道**：
1. **BIN 通道**（clusterer 模块）：usrloc 自动接管 registrar 的 `save("location")` 写入（这是 registrar 模块 → usrloc 模块的内部 callback 链路），通过 clusterer BIN 推到节点 2
2. **HTTP 通道**（httpd 模块）：节点 1 主动重放**直写 SQLite** 的 SQL 到节点 2

边界判定：走 `save("location")` / `lookup("location")` 这类 usrloc 模块函数 → 走 BIN 通道；走 `sql_query` 直接操作 location 表 → 走 HTTP 通道。

---

## 4. 模块加载与参数

### 4.1 模块加载顺序

```ini
# HA 模块
loadmodule "proto_bin.so"          # clusterer BIN 协议
loadmodule "clusterer.so"          # 节点间状态/数据同步
loadmodule "httpd.so"              # HTTP 传输（节点 2 接收重放 + 节点 1 异步发送）

# DB 驱动
loadmodule "db_sqlite.so"
loadmodule "sqlops.so"
loadmodule "db_text.so"

# 核心 SIP
loadmodule "signaling.so"
loadmodule "sl.so"
loadmodule "tm.so"
modparam("tm", "fr_timeout", 5)
modparam("tm", "fr_inv_timeout", 30)
modparam("tm", "restart_fr_on_each_reply", 0)
modparam("tm", "onreply_avp_mode", 1)
loadmodule "rr.so"
modparam("rr", "append_fromtag", 0)
loadmodule "maxfwd.so"
loadmodule "sipmsgops.so"
loadmodule "usrloc.so"
loadmodule "dispatcher.so"
loadmodule "registrar.so"
loadmodule "acc.so"
loadmodule "uac.so"
loadmodule "nathelper.so"
loadmodule "xml.so"
loadmodule "proto_udp.so"

# MI FIFO（保留原有）
loadmodule "mi_fifo.so"
modparam("mi_fifo", "fifo_name", "/run/opensips/opensips_fifo")
modparam("mi_fifo", "fifo_mode", 0666)
```

### 4.2 usrloc（HA 模式）

```ini
# working_mode_preset 必须是 full-sharing-cluster：
#   - cluster_mode = CM_FULL_SHARING
#   - restart_persistency = RRP_SYNC_FROM_CLUSTER（启动时从 cluster 拉取完整副本）
#   - sql_write_mode = SQL_NO_WRITE（不重复写 SQLite，避免和 HTTP 重放冲突）
modparam("usrloc", "working_mode_preset", "full-sharing-cluster")
modparam("usrloc", "db_url", "sqlite:///var/lib/opensips/opensips.db")
modparam("usrloc", "use_domain", false)
modparam("usrloc", "nat_bflag", "NAT")
modparam("usrloc", "location_cluster", 1)         # 必填，对应 clusterer cluster_id=1
modparam("usrloc", "skip_replicated_db_ops", 0)    # 默认 0：收到 BIN 事件后写本地 DB
```

**注意**：
- `usrloc.working_mode_preset = "sql-only-cluster"` **不存在**（已查源码 `ul_mod.c:546-585`，合法预设只有 7 个，`sql-only` 和 `full-sharing-cluster` 是两个独立预设）
- `usrloc.cluster_id` 和 `usrloc.cluster_sharing_tag` **不是 usrloc 参数**（这是 clusterer 的概念）
- 正确参数名是 `location_cluster`（README 1.5.31 段明确为 `full-sharing-cluster` 必填）

### 4.3 dispatcher（HA 模式）

```ini
modparam("dispatcher", "db_url", "text:///etc/opensips/dbtext/dispatcher")
modparam("dispatcher", "ds_ping_interval", 10)
modparam("dispatcher", "ds_probing_mode", 1)
modparam("dispatcher", "ds_ping_from", "20.20.136.100:5060")  # 用 VIP 探测上游
modparam("dispatcher", "ds_probing_threshhold", 3)
modparam("dispatcher", "cluster_id", 1)
modparam("dispatcher", "cluster_sharing_tag", "sip_active")
modparam("dispatcher", "cluster_probing_mode", "by-shtag")   # 仅 active 节点探测
```

**`cluster_probing_mode = by-shtag` 含义**：clusterer 决定哪个节点持 `sip_active` sharing tag，**只有该节点做 ds 探测**。节点 1 挂了，节点 2 自动接管 shtag 并开始探测。

### 4.4 clusterer

```ini
modparam("clusterer", "db_url", "sqlite:///var/lib/opensips/opensips.db")
modparam("clusterer", "db_mode", 1)              # 自动建 clusterer 表
modparam("clusterer", "ping_interval", 2)         # 心跳 2s
modparam("clusterer", "ping_timeout", 1)          # 1s 无响应认为丢
modparam("clusterer", "node_timeout", 5)          # 5s 累计丢 → 节点离群
modparam("clusterer", "sync_timeout", 500)        # 启动时同步状态超时
# my_node_id / neighbor_node_info 由 local.cfg.nodeX 设置
```

### 4.5 httpd（双向可用，HA 角色决定收发）

```ini
# 节点 1 和节点 2 都加载 httpd，既能发也能收；运行时由 HA 状态决定扮演哪种角色
modparam("httpd", "ip", "0.0.0.0")           # 节点1 / 节点2 各自监听本机所有 IP
modparam("httpd", "port", 8080)
```

> **注**：httpd 的 bind IP 应改为各节点的本机 IP（如 20.20.136.66 / 20.20.136.67），通过 `local.cfg.nodeX` 覆盖。0.0.0.0 仅作示意。

**节点 HTTP 角色**（运行时由 clusterer 状态决定）：

| HA 状态 | 节点 1 (Active) | 节点 2 (Standby) |
|---|---|---|
| 正常（节点 1 active） | **HTTP client**：向节点 2 POST `/replay/channel` | **HTTP server**：监听 `:8080`，接收重放 |
| 故障切换后（节点 2 提为 active） | **HTTP server**：监听 `:8080`，接收重放 | **HTTP client**：向节点 1 POST `/replay/channel` |
| 都 standby | 不发 | 不收 |

**判断方式**：用 clusterer 暴露的 sharing tag 状态。clusterer 提供 `clusterer_get_shtag_state(cluster_id, shtag, node_id)` 伪变量/函数（具体 API 以 `clusterer` README 为准），或通过 event_route `[clusterer:my-node-status]` 拿到 `$clustermode`（值为 1=active / 0=standby）。

**实现方式**：在路由入口根据 `$clustermode` 决定是否发 HTTP：

```ini
# 在 route[process_catalog] 头部
if ($clustermode == 1) {
    $var(peer_http) = "20.20.136.67:8080";  # 我是 active，推给 standby
} else {
    $var(peer_http) = NULL;                  # 我是 standby，不发
}
# 后续的 http_async_query 在 $var(peer_http) != NULL 时才调用
```

**接收端**：两节点都监听 8080 + 都跑 `route[replay_channel]`，但**只有 standby 角色会真正收到请求**（因为 active 节点不会向自己发）。这种"双方都监听、不发自己"的方式避免了状态切换瞬间的错位。

### 4.6 db_text

```ini
modparam("db_text", "db_mode", 1)
```

### 4.7 数据库

| 用途 | 驱动 | 路径 |
|---|---|---|
| usrloc `location` 表 | sqlite | `/var/lib/opensips/opensips.db` |
| clusterer 节点表 | sqlite | `/var/lib/opensips/opensips.db`（同库不同表） |
| dispatcher | dbtext | `/etc/opensips/dbtext/dispatcher`（与单机版一致） |

clusterer 和 usrloc 复用同一 SQLite 文件 — `clusterer` 模块自管 `clusterer` 表，usrloc 自管 `location` 表，互不冲突。

---

## 5. 节点特定配置（`local.cfg.node1` / `local.cfg.node2`）

**只放节点差异，逻辑代码不放这里**。

### 5.1 `local.cfg.node1`（Active 节点）

```ini
# ---- 节点网络身份（每节点不同） ----
# 节点1 物理 IP / VIP
listen=udp:20.20.136.66:5060 AS 20.20.136.100:5060
#        ^ bind 本机 IP         ^ 对外通告 VIP（设备收到 200 OK 看到 VIP）
listen=bin:20.20.136.66:5566

# ---- clusterer 节点身份 ----
modparam("clusterer", "my_node_id", 1)
modparam("clusterer", "neighbor_node_info", "id=2; url=bin:20.20.136.67:5566")
```

### 5.2 `local.cfg.node2`（Standby 节点）

```ini
# ---- 节点网络身份（每节点不同） ----
# 节点2 物理 IP，VIP 平时不绑
# listen=udp:20.20.136.67:5060 AS 20.20.136.100:5060
# ↑ 注释保留：notify_master 时由 notify.sh 去掉 # + restart OpenSIPS
listen=bin:20.20.136.67:5566

# ---- clusterer 节点身份 ----
modparam("clusterer", "my_node_id", 2)
modparam("clusterer", "neighbor_node_info", "id=1; url=bin:20.20.136.66:5566")
```

### 5.3 节点差异集中表

| 项 | 节点 1 | 节点 2 |
|---|---|---|
| `LOCAL_IP` | 20.20.136.66 | 20.20.136.67 |
| `BIN_IP` | 20.20.136.66 | 20.20.136.67 |
| `my_node_id` | 1 | 2 |
| `neighbor_node_info` | `id=2; url=bin:...:67:5566` | `id=1; url=bin:...:66:5566` |
| `listen=udp:...:5060` | **有**（带 AS VIP） | **无**（注释行，notify.sh 注入） |
| `listen=bin:...:5566` | 有 | 有 |

**为什么 listen 放这里而不是 m4 拼**：见 §6.4 配置组织。

---

## 6. 配置组织（无 m4）

### 6.1 文件清单

```
/etc/opensips/
├── opensips_proxy_ha.cfg          # 主入口（节点共用）
├── opensips_ha_routes.cfg         # 业务路由（节点共用）
└── local.cfg.node1 / local.cfg.node2   # 节点私有
```

### 6.2 不使用 m4 的理由

- 我们需要"节点差异文件 + 共享逻辑文件" → `include_file` 直接满足
- m4 的条件分支（HA_MODE / DB_ENGINE / WITH_DISPATCHER）在本方案**不需要**（HA 版就是 HA 版，单机版仍是 `opensips_proxy.cfg`）
- 节点身份信息在 `local.cfg.nodeX` 看得见、改得动（运维友好）
- `notify.sh` 改 `local.cfg.nodeX` 里的某一行（如 `listen=`）比改 m4 模板、跑 m4 进程简单一个数量级

### 6.3 `opensips_proxy_ha.cfg`（主入口）

```ini
# 全局参数
log_level=3
xlog_level=3
stderror_enabled=yes
syslog_enabled=yes
syslog_facility=LOG_LOCAL0
udp_workers=4

# 节点特定参数
include_file "/etc/opensips/local.cfg"

# HA 模块 + DB 驱动 + 核心 SIP（见 §4.1）
# ...

# HA 模式 modparam（见 §4.2-4.6）
# ...

# 业务路由
include_file "/etc/opensips/opensips_ha_routes.cfg"

# startup_route
startup_route {
    sql_query("CREATE TABLE IF NOT EXISTS location (
        contact_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        username CHAR(64) DEFAULT '' NOT NULL,
        ...
    )");
    xlog("L_INFO", "HA: startup on node $cluster.my_node_id (cluster_id=1)\n");
}

# event_route: clusterer 状态变化
event_route[clusterer:my-node-status] {
    if ($clustermode == 1) {
        xlog("L_INFO", "HA: node $cluster.my_node_id promoted to ACTIVE\n");
    } else {
        xlog("L_WARN", "HA: node $cluster.my_node_id demoted to STANDBY\n");
    }
}

event_route[clusterer:node-failure] {
    xlog("L_ERR", "HA: neighbor node $cluster.elected_node_id lost\n");
}

event_route[clusterer:node-rejoin] {
    xlog("L_INFO", "HA: neighbor node $cluster.elected_node_id rejoined\n");
}

# event_route: HTTP 请求（节点 2 接收重放）
event_route[http:request] {
    if ($hdrc(method) == "POST" && $hdrc(path) == "/replay/channel") {
        route(replay_channel);
        exit;
    }
    xlog("L_WARN", "HTTP: unknown path $hdrc(path)\n");
    $http_reply(404, "Not Found", "", "");
}
```

### 6.4 `opensips_ha_routes.cfg`（业务路由）

包含 `route[register]`、`route[message]`、`route[check_keepalive]`、`route[platform_query]`、`route[device_response]`、`route[process_catalog]`、`route[process_device_info]`、`route[invite]`、`route[gb28181_playback]`、`route[forward]`、`route[in_dialog]`、主 `route {}`、`onreply_route[handle_nat]`、`failure_route[missed_call]`。

**业务路由与单机版 `opensips_proxy.cfg` 的差异**：

| 路由 | 改动 |
|---|---|
| `route[process_catalog]` | 在每条 DELETE + INSERT 后追加 `http_async_query` 重放到节点 2（§7.1） |
| `route[register]` | 在 `sql_query("DELETE FROM location WHERE attr LIKE ...")` 后追加 `http_async_query`（§7.2） |
| `route[check_keepalive]` | 末尾加一行 `xlog` 告警日志（HA 兜底场景诊断） |
| 其余路由 | **无改动**，直接复用 |

**新增的 `route[replay_channel]`**（节点接收端，详见 §7.3）：解析 JSON body，按 `op` 字段执行 delete / insert 写本地 SQLite。

---

## 7. Catalog 子通道与注销级联删除的 HTTP 重放

### 7.1 `route[process_catalog]` 改造

在原 `sql_query` 后追加 HTTP 异步重放。每条子通道 2 个 HTTP 请求：DELETE + INSERT，body 是 JSON 而非裸 SQL：

```ini
route[process_catalog] {
    $xml(cat) = $rb;
    $var(cnt) = 0;
    $var(i) = 0;
    # HTTP 目标：Active 节点推 → Standby 节点的 /replay/channel
    $var(repl_url) = "http://" + $var(peer_http) + "/replay/channel";

    while ($var(i) < 256) {
        $avp(chan_id) = $xml(cat/Response/DeviceList/Item[$var(i)]/DeviceID.val);
        if ($avp(chan_id) == NULL || $(avp(chan_id){s.len}) == 0)
            break;

        $avp(parent_id) = $xml(cat/Response/DeviceList/Item[$var(i)]/ParentID.val);

        if ($avp(chan_id) != $avp(parent_id)) {
            $avp(chan_name) = $xml(cat/Response/DeviceList/Item[$var(i)]/Name.val);
            $avp(chan_manufacturer) = $xml(cat/Response/DeviceList/Item[$var(i)]/Manufacturer.val);
            $avp(chan_model) = $xml(cat/Response/DeviceList/Item[$var(i)]/Model.val);
            $avp(recorder_contact) = "sip:" + $avp(chan_id) + "@" + $si + ":" + $sp;
            $avp(channel_ua) = $avp(chan_manufacturer) + " " + $avp(chan_model) + " (" + $avp(chan_name) + ")";
            $avp(channel_attr) = "parent=" + $fu;

            # 1. 本地 SQLite（原有行为）
            sql_query("DELETE FROM location WHERE username='$avp(chan_id)'");
            sql_query("INSERT INTO location (username, domain, contact, expires, q, callid, cseq, last_modified, flags, user_agent, socket, attr)
                VALUES ('$avp(chan_id)', '$fd', '$avp(recorder_contact)', 1790000000, -1.0, '$ci', 9999, datetime('now', 'localtime'), 0, '$avp(channel_ua)', 'udp:$socket_in(ip):$socket_in(port)', '$avp(channel_attr)')");
            $var(cnt) = $var(cnt) + 1;

            # 2. 异步重放到对端（结构化 JSON，不用裸 SQL）
            $var(repl_delete) = "{"
                + "\"op\":\"delete\","
                + "\"where\":{\"username\":\"" + $avp(chan_id) + "\"}"
                + "}";
            $var(repl_insert) = "{"
                + "\"op\":\"insert\","
                + "\"row\":{"
                +   "\"username\":\"" + $avp(chan_id) + "\","
                +   "\"domain\":\"" + $fd + "\","
                +   "\"contact\":\"" + $avp(recorder_contact) + "\","
                +   "\"expires\":1790000000,"
                +   "\"q\":-1.0,"
                +   "\"callid\":\"" + $ci + "\","
                +   "\"cseq\":9999,"
                +   "\"last_modified\":\"" + $avp(now_iso) + "\","
                +   "\"flags\":0,"
                +   "\"user_agent\":\"" + $avp(channel_ua) + "\","
                +   "\"socket\":\"udp:" + $socket_in(ip) + ":" + $socket_in(port) + "\","
                +   "\"attr\":\"" + $avp(channel_attr) + "\""
                + "}}";

            http_async_query($var(repl_url), $var(repl_delete), "replay_del_" + $avp(chan_id));
            http_async_query($var(repl_url), $var(repl_insert), "replay_ins_" + $avp(chan_id));
        }
        $var(i) = $var(i) + 1;
    }
    xlog("L_INFO", "CATALOG: inserted $var(cnt) channels, replayed to peer\n");
    $xml(cat) = NULL;
    return 1;
}
```

### 7.2 `route[register]` 注销级联删除的 HTTP 重放

```ini
# 原注销级联删除：
if ($avp(expires_hdr) == "0") {
    sql_query("DELETE FROM location WHERE attr LIKE '%' || '$tu' || '%'");
    xlog("L_INFO", "REGISTER: child channels cleaned for $tu\n");

    # 追加 HTTP 重放（结构化 JSON）
    $var(repl_body) = "{"
        + "\"op\":\"delete\","
        + "\"where\":{\"attr_like\":\"%" + $tu + "%\"}"
        + "}";
    http_async_query("http://" + $var(peer_http) + "/replay/channel",
        $var(repl_body), "replay_unreg_" + $tu);
}
```

### 7.3 接收端 `route[replay_channel]`：解析 JSON 后写本地 SQLite

```ini
route[replay_channel] {
    $var(body) = $rb;
    if ($var(body) == NULL || $(var(body){s.len}) == 0) {
        $http_reply(400, "Bad Request", "Content-Type: text/plain", "empty body");
        exit;
    }

    # 极简 JSON 解析：用正则抠出 op / 字段
    # OpenSIPS 脚本无原生 JSON 解析，使用 json_get_field 需 json.so 模块
    # 此处示意：实际由 json 模块提供解析
    json_get_field("$var(body)", "op", "$var(op)");

    if ($var(op) == "delete") {
        json_get_field("$var(body)", "where.username", "$var(username)");
        if ($var(username) != NULL) {
            sql_query("DELETE FROM location WHERE username='" + $var(username) + "'");
            $http_reply(200, "OK", "Content-Type: text/plain", "deleted");
            xlog("L_INFO", "REPLAY: delete channel $var(username)\n");
        } else {
            json_get_field("$var(body)", "where.attr_like", "$var(attr_like)");
            if ($var(attr_like) != NULL) {
                sql_query("DELETE FROM location WHERE attr LIKE '" + $var(attr_like) + "'");
                $http_reply(200, "OK", "Content-Type: text/plain", "deleted");
                xlog("L_INFO", "REPLAY: delete by attr_like $var(attr_like)\n");
            } else {
                $http_reply(400, "Bad Request", "Content-Type: text/plain", "missing where");
            }
        }
    } else if ($var(op) == "insert") {
        # 解析 row.* 字段并 INSERT
        json_get_field("$var(body)", "row.username", "$var(username)");
        json_get_field("$var(body)", "row.domain", "$var(domain)");
        json_get_field("$var(body)", "row.contact", "$var(contact)");
        # ... 其余字段 ...
        sql_query("INSERT INTO location (username, domain, contact, expires, q, callid, cseq, last_modified, flags, user_agent, socket, attr) "
            + "VALUES ('" + $var(username) + "', '" + $var(domain) + "', '" + $var(contact) + "', 1790000000, -1.0, '" + $var(callid) + "', 9999, datetime('now', 'localtime'), 0, '" + $var(user_agent) + "', '" + $var(socket) + "', '" + $var(attr) + "')");
        $http_reply(200, "OK", "Content-Type: text/plain", "inserted");
        xlog("L_INFO", "REPLAY: insert channel $var(username)\n");
    } else {
        $http_reply(400, "Bad Request", "Content-Type: text/plain", "unknown op");
    }
}
```

> **注**：本设计要求在 `opensips_proxy_ha.cfg` 加载 `json.so` 模块，提供 `json_get_field` 脚本函数。

### 7.4 同步保证级别

| 异常 | 影响 | 兜底 |
|---|---|---|
| 节点 2 HTTP 8080 挂 | 节点 1 异步请求失败，本地写入正常 | 节点 2 提为 active 后查不到，401 触发重注册 |
| 节点 1 写 SQLite 后 HTTP 推送前挂 | 节点 2 缺这条 | 401 触发重注册 |
| 节点 1 / 2 网络断 | HTTP 超时失败 | 401 触发重注册 |
| 节点 1 SQL 写失败 | 不发 HTTP | 同原行为 |

**HTTP 推送失败不做补偿**，依赖现有 401 重注册兜底。

### 7.5 失败回调

```ini
event_route[http:reply] {
    if ($http_ok != 1) {
        xlog("L_WARN", "REPLAY: HTTP reply failed for $http_name code=$http_code\n");
    }
}
```

---

## 8. 启动与故障切换流程

### 8.1 启动顺序

```
T0   节点 1 启动
     ├─ keepalived 启动 (priority=100, MASTER)
     ├─ OpenSIPS 启动
     │   ├─ include_file local.cfg.node1 → listen SIP + listen BIN
     │   ├─ modparam: my_node_id=1, neighbor=2
     │   ├─ startup_route: CREATE TABLE location
     │   └─ clusterer 启动 → 等 neighbor
     └─ keepalived 把 VIP 绑到本机

T0+  节点 2 启动
     ├─ keepalived 启动 (priority=90, BACKUP)
     ├─ OpenSIPS 启动
     │   ├─ include_file local.cfg.node2 → 只 listen BIN，listen SIP 行被注释
     │   ├─ modparam: my_node_id=2, neighbor=1
     │   ├─ startup_route: CREATE TABLE location
     │   ├─ clusterer 启动 → 找 donor → 从节点 1 拉取完整 location 副本
     │   │   （RRP_SYNC_FROM_CLUSTER 行为）
     │   └─ httpd 监听 20.20.136.67:8080
     └─ 节点 2 SQLite 与节点 1 一致
```

### 8.2 正常运行

```
设备 REGISTER → VIP → 节点 1
节点 1: save("location") → 本地 SQLite + clusterer BIN 推节点 2
节点 2: 收到 BIN 事件 → skip_replicated_db_ops=0 → 写本地 SQLite

设备 MESSAGE (Catalog 响应) → VIP → 节点 1
节点 1: 解析 → sql_query 写本地 + http_async_query 重放节点 2
节点 2: HTTP POST /replay/channel → route[replay_channel] → 解析 JSON → sql_query 写本地

设备 Keepalive → VIP → 节点 1 → lookup → 200 OK

平台 INVITE → VIP → 节点 1 → lookup → ds_select_dst → 转发
（节点 1 做 ds 探测；节点 2 by-shtag 不探测）
```

### 8.3 故障切换

```
T_n   节点 1 OpenSIPS 挂
       keepalived chk_opensips.sh 连续 3 次失败（interval=2s, weight=-20）
T_n+~6s   keepalived 切换
       ├─ 节点 1: 状态变 FAULT，释放 VIP
       └─ 节点 2: 状态变 MASTER，触发 notify_master
T_n+~6s   节点 2 notify_master 脚本
       ├─ 1. 取消 local.cfg.node2 里 SIP listen 行的注释
       ├─ 2. systemctl restart opensips
       │      └─ 新进程加载 listen=udp:...:5060 AS VIP:5060
       └─ 3. 写 /var/log/keepalived.log
T_n+~10s  VIP 绑到节点 2，设备后续请求到节点 2
       ├─ 节点 2 已有 location 副本（clusterer 已同步）
       ├─ 大多数 lookup 命中
       └─ 边缘场景：BIN 同步滞后 / 写完 SQLite 但 HTTP 重放前挂
            └─ 节点 2 lookup 失败 → 401 → 设备重注册 → 200 OK
```

### 8.4 节点 1 恢复

```
T_m   节点 1 重启
       ├─ keepalived 启动 (priority=100)
       ├─ OpenSIPS 启动
       │   ├─ clusterer 找 donor → 从节点 2 拉取完整副本
       │   └─ local.cfg.node1 SIP listen 一直存在
       └─ keepalived 抢回 VIP（priority 100 > 90）

T_m+~3s  节点 2 notify_backup 脚本
       ├─ 1. 注释 local.cfg.node2 里 SIP listen 行
       └─ 2. systemctl restart opensips
              └─ 节点 2 退回 standby，不接 SIP
```

**关键不变式**：节点 1 和节点 2 永远不同时监听 SIP 5060（避免 SIP 双收、media fork 混乱）。

---

## 9. 配置示例文件清单

最终产出物（新增文件）：

| 文件 | 用途 |
|---|---|
| `etc/opensips_proxy_ha.cfg` | 主入口 |
| `etc/opensips_ha_routes.cfg` | 业务路由 |
| `etc/local.cfg.node1` | 节点 1 私有 |
| `etc/local.cfg.node2` | 节点 2 私有 |
| `docs/opensips_gb28181_proxy.md` | 文档更新（去掉 MySQL 方案，新增本方案） |

**不修改**：`etc/opensips_proxy.cfg`（单机版保留）、`etc/opensips.cfg`（项目无关）。

---

## 10. 验证（验收方法）

### 10.1 单元层

```bash
# 配置文件语法检查
opensips -f /etc/opensips/opensips_proxy_ha.cfg -c
# 期望：no errors
```

### 10.2 启动层

```bash
# 节点 1
systemctl start opensips
# 期望日志：
#   HA: startup on node 1 (cluster_id=1)
#   clusterer: neighbor 2 reachable
journalctl -u opensips -f | grep -E "HA:|clusterer"

# 节点 2（启动后等几秒）
systemctl start opensips
# 期望日志：
#   HA: startup on node 2 (cluster_id=1)
#   clusterer: sync from node 1 OK
#   usrloc synced from donor
```

### 10.3 同步层

```bash
# 节点 1 查设备
sqlite3 /var/lib/opensips/opensips.db \
  "SELECT username FROM location WHERE expires > strftime('%s','now');"

# 节点 2 同步查（应相同）
ssh node2 sqlite3 /var/lib/opensips/opensips.db \
  "SELECT username FROM location WHERE expires > strftime('%s','now');"
```

### 10.4 故障切换层

```bash
# 模拟节点 1 故障
ssh node1 systemctl stop opensips

# 观察节点 2
# 期望：
#   1. keepalived 切换日志
#   2. notify_master 触发，OpenSIPS 重启
#   3. 节点 2 接受 SIP 流量

# 设备端发送 REGISTER（模拟）
# 期望：节点 2 响应 200 OK
```

### 10.5 边缘场景层

```bash
# 场景 A：节点 1 写完 SQLite 后 HTTP 推送前挂
#  1. 触发 Catalog（200 个子通道）
#  2. 节点 1 立即 kill -9
#  3. 节点 2 提为 active
#  4. 平台 INVITE 未同步的子通道
#  期望：404 触发设备重发 Catalog，重注册成功

# 场景 B：节点 2 HTTP 8080 挂
#  1. ssh node2 systemctl stop opensips
#  2. 节点 1 触发 Catalog
#  3. 节点 1 推 HTTP 失败，本地写入正常
#  4. 节点 1 故障
#  5. 节点 2 提为 active
#  期望：主注册命中，子通道 404 触发重发
```

---

## 11. 风险与未决项

| 风险 | 说明 | 缓解 |
|---|---|---|
| `working_mode_preset=full-sharing-cluster` 在 OpenSIPS 2.4+ 才支持 | 需确认项目 OpenSIPS 版本 ≥ 2.4 | 检查 `opensips -V` |
| `http_async_query` 在事件路由中可能丢失 | 高频写场景下 async 队列可能满 | 监控 `httpd` 队列；超限后降级为同步 |
| HTTP 端口暴露风险 | httpd 绑 20.20.136.67 但不验证来源 IP | 文档化"内网限定"，运维加防火墙 |
| 子通道 SQL 重放错误（含特殊字符） | 设备 ID 含 `'`, `;` 等可能破坏 SQL | 实施时用转义或预校验 |
| 启动同步超时（sync_timeout=500） | 节点 2 启动时如节点 1 还没就绪会卡 | 节点 1 先启动 + wait-for-ready 脚本 |

---

## 12. 已澄清的设计点

| 议题 | 结论 |
|---|---|
| 节点规模 | 2 节点，active/standby |
| 拓扑 | 主备（不做双活） |
| 数据共享 | 本地 SQLite + clusterer BIN + HTTP 重放（不用 Redis） |
| 配置文件组织 | 3 个纯 .cfg + `include_file`，不用 m4 |
| usrloc 模式 | `full-sharing-cluster`（已查源码确认合法） |
| 故障切换 | Keepalived + VIP 漂移 + 节点 2 启动 SIP 监听 |
| Catalog 子通道 | 节点 1 写 + HTTP 异步重放节点 2 |
| 兜底 | 401 重注册（已有逻辑） |
| 节点 2 提为主时 SQL 状态 | 通过 clusterer 启动同步 + HTTP 重放，已有完整 location |

---

**本设计文档已与用户对齐 5 节内容（架构/模块/节点配置/路由调整/启动与故障切换 + HTTP 重放细节），通过逐节确认。**
