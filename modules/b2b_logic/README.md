---
title: "B2B_LOGIC"
description: "OpenSIPS 中的 B2BUA 实现分为两层：下层（在 b2b_entities 模块中实现）- UAS 和 UAC 的基本功能；上层（在 b2b_logic 模块中实现）- 代表 B2BUA 的逻辑引擎，负责使用下层提供的功能实际实现 B2BUA 服务。"
---

## 管理指南

### 概述

OpenSIPS 中的 B2BUA 实现分为两层：

- **下层**（在 b2b_entities 模块中实现）- UAS 和 UAC 的基本功能
- **上层**（在 b2b_logic 模块中实现）- 代表 B2BUA 的逻辑引擎，负责使用下层提供的功能实际实现 B2BUA 服务

此模块是 B2BUA 的上层实现，可与 b2b_entities 模块配合使用以提供各种 B2BUA 服务（例如 PBX 功能）。B2BUA 场景的实际逻辑可以在专用脚本路由中实现。

B2B 会话可以通过两种方式触发：

- **从脚本** - 收到初始 INVITE 消息时
- **通过外部命令（MI）** - 服务器将把两个端点连接到一个会话中（第三方呼叫控制）

可以通过启用下层 *b2b_entities* 模块提供的集群支持来实现 B2B 会话的高可用性（通过设置 *b2b_entities* 的 [cluster_id](../b2b_entities#param_cluster_id) modparam）。

### 场景逻辑

初始化 B2B 会话后，呼叫分支将由 b2b_logic 模块处理，第一步是将两个初始实体连接起来。属于这些会话的请求和回复不会通过标准 OpenSIPS 路由进入脚本，而是将由 b2b_logic 专用路由处理（通过 [script req route](#param_script_req_route) 和 [script reply route](#param_script_reply_route) modparams 定义，或通过 [b2b init request](#func_b2b_init_request) 参数提供的自定义路由）。场景的进一步步骤可以在这些路由中实现，通过调用专用的 b2b_logic 脚本函数来执行各种操作。不应在 b2b_logic 路由中执行普通的"代理式"OpenSIPS 函数。

某些消息将由模块自动处理，根本不会进入 b2b_logic 路由（当正在桥接两个实体时收到的 BYE 请求、已断开实体的 ACK/BYE/回复）。此外，如果未定义专用的 b2b_logic 回复路由，回复将由模块内部处理，其效果与从这样的路由调用 [b2b handle reply](#func_b2b_handle_reply) 相同（如果定义了的话）。

### 依赖

#### OpenSIPS 模块

- **b2b_entities, db 模块**

#### 外部库或应用程序

运行 OpenSIPS 加载此模块前不需要任何库或应用程序。

### 导出的参数

#### hash_size (int)

存储会话实体的哈希表大小。

**默认值为 "9"**（512 条记录）。

```c title="设置 server_hsize 参数"
...
modparam("b2b_logic", "hash_size", 10)
...
```

#### script_req_route (str)

当收到属于 ongoing B2B 会话的请求时调用的脚本路由名称。

```c title="设置 script_req_route 参数"
...
modparam("b2b_logic", "script_req_route", "b2b_request")
...
```

#### script_reply_route (str)

当收到属于 ongoing B2B 会话的回复时调用的脚本路由名称。

```c title="设置 script_repl_route 参数"
...
modparam("b2b_logic", "script_reply_route", "b2b_reply")
...
```

#### cleanup_period (int)

搜索挂起的 b2b 上下文的时间间隔。如果会话持续时间超过其定义的生存期，则认为会话已过期。此时，将向该上下文中的所有会话发送 BYE，并删除上下文。

**默认值为 "100"。**

```c title="设置 cleanup_period 参数"
...
modparam("b2b_logic", "cleanup_period", 60)
...
```

#### custom_headers_regexp (str)

用于按名称搜索 SIP header 的正则表达式，这些 header 应该从一侧的会话传递到另一侧。默认情况下会传递许多 header，它们是：

- Max-Forwards（递减 1）
- Content-Type
- Supported
- Allow
- Proxy-Require
- Session-Expires
- Min-SE
- Require
- RSeq

如果您希望传递其他 header，应该通过设置此参数来定义它们。

格式可以是 "regexp"、"/regexp/" 和 "/regexp/flags"。

标志的含义如下：

- **i** - 不区分大小写搜索
- **e** - 使用扩展正则表达式

**默认值为 "NULL"。**

```c title="设置参数"
...
modparam("b2b_logic", "custom_headers_regexp", "/^x-/i")
...
```

#### custom_headers (str)

用 ';' 分隔的 SIP header 名称列表，这些 header 应该从一侧的会话传递到另一侧。默认情况下会传递许多 header，它们是：

- Max-Forwards（递减 1）
- Content-Type
- Supported
- Allow
- Proxy-Require
- Session-Expires
- Min-SE
- Require
- RSeq

如果您希望传递其他 header，应该通过设置此参数来定义它们。

**默认值为 "NULL"。**

```c title="设置参数"
...
modparam("b2b_logic", "custom_headers", "User-Agent;Date")
...
```

#### custom_contact_header_params (str)

用 ';' 分隔的 Contact header 参数列表，这些参数应该从一侧的会话传递到另一侧。

在整个会话中，每个参数的值都附加到实体 - 这意味着当实体被桥接时，相应实体的 header 参数将发送到新实体。

**默认值为 ""（无参数）。**

```c title="设置 custom_contact_header_params 参数"
...
modparam("b2b_logic", "custom_contact_header_params", "audio;video")
...
```

#### db_url (str)

数据库 URL。

```c title="设置 db_url 参数"
...
modparam("b2b_logic", "db_url", "mysql://opensips:opensipsrw@127.0.0.1/opensips")
...
```

#### cachedb_url (str)

要使用的 NoSQL 数据库的 URL。目前仅支持 Redis。

```c title="设置 cachedb_url 参数"
...
modparam("b2b_logic", "cachedb_url", "redis://localhost:6379/")
...
```

#### cachedb_key_prefix (string)

在 NoSQL 数据库中设置的每个键的前缀。

**默认值为 "b2bl$"。**

```c title="设置 cachedb_key_prefix 参数"
...
modparam("b2b_logic", "cachedb_key_prefix", "b2b")
...
```

#### update_period (int)

更新数据库中信息的时间间隔。

**默认值为 "100"。**

```c title="设置 update_period 参数"
...
modparam("b2b_logic", "update_period", 60)
...
```

#### max_duration (int)

呼叫的最大持续时间。此值作为所有 B2B 会话的默认生存期应用。可以通过使用 [b2b bridge](#func_b2b_bridge) 函数的 *max_duration* 标志在每个桥接的基础上覆盖。

**默认值为 "12 * 3600（12 小时）"。**

如果设置为 0，则没有限制。

```c title="设置 max_duration 参数"
...
modparam("b2b_logic", "max_duration", 7200)
...
```

#### contact_user (int)

如果设置为 1，则将从 From: header 添加用户到生成的 Contact:。

**默认值为 "0"。**

```c title="设置 contact_user 参数"
...
modparam("b2b_logic", "contact_user", 1)
...
```

#### b2bl_from_spec_param (string)

用于存储新 "From" header 的伪变量名称。必须在调用 "b2b_init_request" 之前设置 PV。

**默认值为 "NULL"（禁用）。**

```c title="设置 b2bl_from_spec_param 参数"
...
modparam("b2b_logic", "b2bl_from_spec_param", "$var(b2bl_from)")
...
route{
	...
	# 设置 From header
	$var(b2bl_from) = "\"Call ID\" <sip:user@opensips.org>";
	...
	b2b_init_request("top hiding");
	...
}
```

#### server_address (str)

将用作生成消息中 Contact 的机器 IP 地址。这仅在 OpenSIPS 从中间开始呼叫时才是必选的。对于由收到的呼叫触发的场景，如果未设置，则从接收发起请求的 socket 动态构造。此 socket 将用于发送该会话的所有请求和回复。此参数支持伪变量。

```c title="设置 server_address 参数"
...
modparam("b2b_logic", "server_address", "sip:sa@10.10.10.10:5060")
...
```

```c title="使用伪变量设置 server_address 参数"
...
modparam("b2b_logic", "server_address", "sip:$socket_in(advertised_ip):$socket_in(advertised_port)")
...
```

#### init_callid_hdr (str)

模块提供在生成的 Invite 中将原始 callid 插入到 header 中的可能性。如果您希望这样做，请将此参数设置为要插入原始 callid 的 header 名称。

```c title="设置 init_callid_hdr 参数"
...
modparam("b2b_logic", "init_callid_hdr", "Init-CallID")
...
```

#### db_mode (int)

B2B 模块支持 3 种类型的数据库存储：

- **NO DB STORAGE** - 将此参数设置为 0
- **WRITE THROUGH**（同步写入数据库）- 将此参数设置为 1
- **WRITE BACK**（定期更新到数据库）- 将此参数设置为 2

**默认值为 "2"（WRITE BACK）。**

```c title="设置 db_mode 参数"
...
modparam("b2b_logic", "db_mode", 1)
...
```

#### db_table (str)

要使用的数据库表名。

**默认值为 "b2b_logic"**

```c title="设置 db_table 参数"
...
modparam("b2b_logic", "db_table", "some_table_name")
...
```

#### b2bl_th_init_timeout (int)

拓扑隐藏场景的呼叫建立超时。

**默认值为 "60"**

```c title="设置 b2bl_th_init_timeout 参数"
...
modparam("b2b_logic", "b2bl_th_init_timeout", 60)
...
```

#### b2bl_early_update (int)

允许通过发送 "UPDATE" 请求在早期阶段桥接呼叫。

- **0** - 不要在早期阶段桥接会话
- **1** - 尝试通过发送 UPDATE 在早期阶段更新会话

**默认值为 "0" 不要在早期阶段桥接会话**

```c title="设置 b2bl_early_update 参数"
...
modparam("b2b_logic", "b2bl_early_update", 1)
...
```

#### old_entity_term_delay (int)

当使用 *b2b_bridge_request* 与 *late_bye* 标志时，此参数可以延迟向终止实体发送 BYE 的时刻。因此，不是当新实体建立时就终止它，而是延迟发送 BYE，延迟时间为此参数的值（以秒为单位）。

**默认值为 "0" - 立即发送 BYE**

```c title="设置 old_entity_term_delay 参数"
...
modparam("b2b_logic", "old_entity_term_delay", 2) # 延迟 2 秒发送 BYE
...
```

### 导出的函数

#### b2b_init_request(id, [flags], [req_route], [reply_route])

此函数基于初始 INVITE 初始化新的 B2B 会话。在运行此函数之前，必须先使用 [b2b server new](#func_b2b_server_new) 和 [b2b client new](#func_b2b_client_new) 分别创建新的服务器实体和新的客户端实体。这些是要连接初始实体，可以在 b2b_logic 专用路由中实现进一步的场景逻辑。

参数：

- **scenario_id (string)** - 此 B2B 会话的场景标识符。特殊值 *top hiding* 初始化内部拓扑隐藏场景。此场景将简单地在消息从一侧传递到另一侧，不需要额外的脚本或专用路由。
- **flags (string, optional)** - CSV 格式的以下标志列表：
  - **setup-timeout=[nn]** - 呼叫建立超时。0 将超时设置为 max_duration 值。例如："setup-timeout=300"
  - **transparent-auth** - 透明认证。在此模式下 b2b 将您的 401 或 407 认证请求传递到目标服务器
  - **preserve-to** - 保留 To: header
  - **pass-legs-upstream** - 在将预建立回复上游转发时重用下游回复分支索引
- **req_route (string, optional)** - 当收到属于此 B2B 会话的请求时调用的脚本路由名称。此参数将覆盖此特定 B2B 会话的全局 [script req route](#param_script_req_route) modparam
- **reply_route (string, optional)** - 当收到属于此 B2B 会话的回复时调用的脚本路由名称。此参数将覆盖此特定 B2B 会话的全局 [script reply route](#param_script_reply_route) modparam

此函数可用于 REQUEST_ROUTE。

> [!NOTE]
> 如果您有多接口设置并想更改出站接口，在将控制权传递给 b2b 函数之前必须使用 "force_send_socket()" 核心函数。如果不这样做，请求可能被正确路由，但 SIP 数据包可能无效（因为 Contact、Via 等）。

```c title="b2b_init_request 使用示例"
...
if(is_method("INVITE") && !has_totag() && prepaid_user()) {
   ...
   # 创建初始实体
   b2b_server_new("server1");
   b2b_client_new("client1", $var(media_uri));

   # 初始化 B2B 会话
   b2b_init_request("prepaid");
   exit;
}
...
```

#### b2b_server_new(id, [adv_contact], [extra_hdrs], [extra_hdr_bodies])

此函数创建新的服务器实体（OpenSIPS 作为 UAS 的会话），用于初始化新的 B2B 会话。它只应用于初始 INVITE，在调用 [b2b init request](#func_b2b_init_request) 之前。

参数：

- **id (string)** - 用于在进一步的 B2B 操作中引用此实体的 ID
- **adv_contact (string, optional)** - 在生成的消息中公布的 Contact header
- **extra_hdrs (var, optional)** - 包含额外 headers 列表（header 名称）的 AVP 变量，将添加到发送到此实体的任何请求中
- **extra_hdr_bodies (var, optional)** - 包含额外 header bodies 列表（对应于 *extra_hdrs* 参数中给出的 headers）的 AVP 变量，将添加到发送到此实体的任何请求中

此函数可用于 REQUEST_ROUTE。

```c title="b2b_server_new 使用示例"
...
if(is_method("INVITE") && !has_totag()) {
   b2b_server_new("server1", $avp(b2b_hdrs), $avp(b2b_hdr_bodies));
   ...
}
...
```

#### b2b_client_new(id, dest_uri, [proxy], [from_dname], [adv_contact], [extra_hdrs], [extra_hdr_bodies], [flags])

此函数创建新的客户端实体（OpenSIPS 作为 UAC 的会话），用于初始化新的 B2B 会话或用于桥接操作。此函数可以在调用 [b2b init request](#func_b2b_init_request) 或 [b2b bridge](#func_b2b_bridge) 之前使用。

参数：

- **id (string)** - 用于在进一步的 B2B 操作中引用此实体的 ID
- **dest_uri (string)** - 新目标 URI
- **proxy (string, optional)** - 发送 INVITE 的出站代理 URI
- **from_dname (string, optional)** - 在 From header 中使用的 Display name
- **adv_contact (string, optional)** - 在生成的消息中公布的 Contact header
- **extra_hdrs (var, optional)** - 包含额外 headers 列表（header 名称）的 AVP 变量，将添加到发送到此实体的任何请求中
- **extra_hdr_bodies (var, optional)** - 包含额外 header bodies 列表（对应于 *extra_hdrs* 参数中给出的 headers）的 AVP 变量，将添加到发送到此实体的任何请求中
- **flags (string, optional)** - CSV 格式的每实体标志列表。支持的值有：
  - **pass-legs-upstream** - 仅为此客户端实体向上游传递下游分支索引

此函数可用于 REQUEST_ROUTE 和 b2b_logic 请求路由。

```c title="b2b_client_new 使用示例"
...
b2b_client_new("client1", "sip:alice@opensips.org");
...
```

#### b2b_bridge(entity1, entity2, [provmedia_uri], [flags])

此函数在现有 B2B 会话的上下文中桥接两个实体（初始实体已连接）。两个实体中至少有一个必须是新的客户端实体。

参数：

- **entity1 (string)** - 要桥接的第一个实体的 ID；也可以使用特殊值：*peer* 和 *this* 来引用现有实体
- **entity2 (string)** - 要桥接的第二个实体的 ID；也可以使用特殊值：*peer* 和 *this* 来引用现有实体
- **provmedia_uri (string, optional)** - 临时媒体服务器的 URI，在被叫应答时与主叫连接
- **flags (string, optional)** - CSV 格式的以下标志列表：
  - **max_duration=[nn]** - B2B 会话的最大持续时间。如果生存期到期，B2BUA 将向两端发送 BYE 消息并删除记录。此每桥接值优先于全局 [max duration](#param_max_duration) 模块参数。例如："max_duration=300"
  - **notify** - 启用 rfc3515 NOTIFY 以通知发送 REFER 的代理引用的状态
  - **rollback-failed** - 如果转移失败则回滚呼叫到桥接前的状态，不挂断呼叫（默认行为）
  - **hold** - 在将旧实体桥接到新实体之前将其置于保持状态
  - **no-late-sdp** - 不尝试与新实体进行延迟 SDP 协商。首先使用从旧实体收到的初始 SDP 联系新实体。在新实体应答后，向旧实体发送不带 body 的 reINVITE。使用从旧实体收到的新应答中的当前 SDP 触发与新实体的重新协商
  - **propagate-avps** - 桥接呼叫时使用此标志将 AVPs 从初始元组复制到新元组。当进行需要存储 AVPs（用户名和密码）进行会话中认证时，这可能很有帮助，但也可用于存储跨桥接的其他信息

此函数可用于 b2b_logic 请求路由。

```c title="b2b_bridge 使用示例"
...
route[b2b_logic_request] {
   ...
   b2b_client_new("client2", $hdr(Refer-To));

   b2b_bridge("peer", "client2");
}
...
```

#### b2b_bridge_retry(new_entity)

此函数可用于通过联系新目标重试失败的桥接操作。在运行此函数之前必须使用 [b2b client new](#func_b2b_client_new) 创建新的客户端实体。

参数：

- **entity1 (string)** - 要桥接的新实体的 ID

此函数可用于 b2b_logic 回复路由。

```c title="b2b_bridge 使用示例"
...
route[b2b_logic_reply] {
   ...
   if ($b2b_logic.entity(id) == "client1" && $rm == "INVITE" && $rs >= 300) {
      b2b_client_new("client_retry", "sip:alice@opensips.org");

      b2b_bridge_retry("client_retry");
   } else {
      b2b_handle_reply();
   }
   ...
}
...
```

#### b2b_pass_request()

此函数将属于现有 B2B 会话的请求传递到对等实体。除非需要不同的操作来实现场景逻辑（例如桥接操作），否则应该为所有请求调用此函数。

此函数可用于 b2b_logic 请求路由。

```c title="b2b_pass_request 使用示例"
...
route[b2b_logic_request] {
   if ($rm != "BYE") {
      b2b_pass_request();
      exit;
   } else {
      # 删除当前实体并将 peer 桥接到新实体
   }
...
```

#### b2b_handle_reply([flags])

此函数通过为 ongoing B2B 会话的当前状态采取适当的操作来处理收到的回复（将回复传递给对等、完成 ongoing 桥接操作等）。如果定义了 b2b_logic 回复路由，应该为所有回复调用此函数。

此函数可用于 b2b_logic 回复路由。

参数：

- **flags (string, optional)** - 逗号分隔的标志列表，用于更改回复处理的行为。支持的值有：
  - **pass-3xx-contact** - 当收到重定向回复（3xx）消息时，按原样将对端传递给其他 peer，不进行修改

```c title="b2b_handle_reply 使用示例"
...
route[b2b_logic_reply] {
    xlog("B2B REPLY: [$rs $rm] from entity: $b2b_logic.entity(id)\n");
    b2b_handle_reply();
}
...
```

#### b2b_send_reply(code, reason[, headers[, body]])

此函数向发送当前请求的实体发送回复。

参数：

- **code (int)** - 回复代码
- **reason (string)** - 回复原因字符串
- **headers (string, optional)** - 额外 headers
- **body (string, optional)** - 消息 body

此函数可用于 b2b_logic 请求路由。

```c title="b2b_send_reply 使用示例"
...
route[b2b_logic_request] {
   if ($rm == "REFER") {
      b2b_send_reply(202, "Accepted");
      ...
   }
}
...
```

#### b2b_delete_entity()

此函数删除发送当前请求的实体。

此函数可用于 b2b_logic 请求路由。

```c title="b2b_delete_entity 使用示例"
...
route[b2b_logic_request] {
   if ($rm == "BYE") {
      b2b_send_reply(200, "OK");
      b2b_delete_entity();
      ...
   }
}
...
```

#### b2b_end_dlg_leg()

此函数向发送当前请求的实体发送 BYE 请求。不需要同时调用 [b2b delete entity](#func_b2b_delete_entity) 来删除当前实体。

此函数可用于 b2b_logic 请求或回复路由。

```c title="b2b_end_dlg_leg 使用示例"
...
route[b2b_logic_request] {
   if ($rm == "REFER") {
      b2b_send_reply(202, "Accepted");
      b2b_end_dlg_leg();
   }
}
...
```

#### b2b_bridge_request(b2bl_key,entity_no, [adv_contact], [flags])

此函数将初始 INVITE 与现有 b2b 会话中的一个参与者桥接。

参数：

- **b2bl_key (string)** - 包含 b2b_logic 键的字符串。键也可以采用 *callid;from-tag;to-tag* 形式
- **entity_no (int)** - 包含要桥接的实体/参与者编号的整数
- **adv_contact (string, optional)** - 在生成的消息中公布的 Contact header
- **flags (string, optional)** - 可修改函数行为的标志。可用标志有：
  - **late_bye** - 在停止时不终止被替换的实体，而是将其保持悬停直到新实体完全建立

```c title="b2b_bridge_request 使用示例"
...
if ($rU == "pickup") {
    # 获取此用户停放的呼叫的 b2b logic 键
    cache_fetch("local", "$fU", $var(b2bl_key));
    cache_remove("local", "$fU");

    if ($var(b2bl_key) != NULL)
        b2b_bridge_request($var(b2bl_key), 0);
    else
        send_reply(481, "Call/Transaction Does Not Exist");

    exit;
}
...
```

#### b2b_trigger_scenario(scenario, [params], peer1, [extra_headers_peer1], [extra_headers_contents_peer1], peer2 [extra_headers_peer2], [extra_headers_contents_peer2])

此函数从路由脚本触发特定场景，例如 out-of-dialog REFER。

参数：

- **scenario (string)** - 要触发场景的名称
- **params (string, optional)** - 此场景使用的参数（可选择作为 CSV 格式）
  - **n** - 启用 rfc3515 NOTIFY 以通知发送 REFER 的代理引用的状态
  - **session key (string, optional)** - 内部会话键，如果 NOTIFY 应该在此 B2B-UA 上的不同会话中发送（例如，用于接收 out-of-dialog REFER）
  - **party of remote session (int, optional)** - 如果 NOTIFY 应该发送到不同会话，则哪一侧应该收到会话的 NOTIFY（0 = 会话的 A 方，1 = 会话的 B 方）
- **peer1 (string)** - 定义被触发场景的 A 方的参数
  - **entitiy_name (string)** - 实体名称
  - **RURI (string)** - 要联系实体的 R-URI
  - **Proxy (string, optional)** - 用于此实体的出站代理
  - **Display-Name (string, optional)** - 用于此实体的 Display Name
- **extra_headers_peer1 (var, optional)** - 包含额外 headers 列表（header 名称）的 AVP 变量，将添加到为第一个实体发送的任何请求中
- **extra_headers_contents_peer1 (var, optional)** - 包含额外 header bodies 列表（对应于 *extra_headers_peer1* 参数中给出的 headers）的 AVP 变量，将添加到为第一个实体发送的任何请求中
- **peer2 (string)** - 定义被触发场景的 B 方的参数。格式与 *peer1* 的定义相同
- **extra_headers_peer2 (var, optional)** - 包含额外 headers 列表（header 名称）的 AVP 变量，将添加到为第二个实体发送的任何请求中
- **extra_headers_contents_peer2 (var, optional)** - 包含额外 header bodies 列表（对应于 *extra_headers_peer2* 参数中给出的 headers）的 AVP 变量，将添加到为第二个实体发送的任何请求中

此函数可用于 REQUEST_ROUTE。

```c title="b2b_trigger_scenario 使用示例"
...
if(is_method("REFER") && !has_totag()) {
   $avp(header) = "Replaces";
   $avp(header_content) = "call-id=xyz";
   b2b_trigger_scenario("refer", "n", "conf,sip:conference@10.0.0.1", $avp(header), $avp(header_content), "callee,sip:user@10.0.0.1,sip:10.0.0.1");
   ...
}
...
```

### 导出的 MI 函数

#### b2b_logic:trigger_scenario

替换已废弃的 MI 命令：*b2b_trigger_scenario*。

此命令初始化新的 B2B 会话，其中 OpenSIPS 将从中间开始呼叫。要连接的初始实体通过命令的参数指定，进一步的场景逻辑可以在 b2b_logic 专用路由中实现。

名称：*b2b_logic:trigger_scenario*

参数：

- **senario_id**：此 B2B 会话的场景 ID
- **entity1** - 要连接的第一个实体；按以下格式指定：*id,dest_uri[,from_dname]*，其中：
  - **id** - 用于在进一步的 B2B 操作中引用此实体的 ID
  - **dest_uri** - 新目标 URI
  - **from_dname (optional)** - 在 From header 中使用的 Display name
- **entity2** - 要连接的第二个实体；格式与 *entity1* 相同
- **context (array, optional)** - B2B 上下文值数组，格式为：*key=value*

MI FIFO 命令格式：

```c
	opensips-cli -x mi b2b_logic:trigger_scenario marketing client1,sip:bob@opensips.org client2,sip:322@opensips.org:5070 agent_uri=sip:alice@opensips.org
```

#### b2b_logic:bridge

替换已废弃的 MI 命令：*b2b_bridge*。

此命令可由外部应用程序使用，告诉 B2BUA 将 ongoing 会话中的一方桥接到另一个目标。默认情况下，主叫被桥接到新 URI，并向被叫发送 BYE。如果发送 1 作为第三个参数，则可以桥接被叫。

名称：*b2b_logic:bridge*

参数：

- **dialog_id**：*b2b_logic key*，或 ongoing 会话的 *callid;from-tag;to-tag*
- **new_uri** - 新目标的 URI
- **flag (optional)** - 用于指定必须将被叫桥接到新目标。如果不存在，则桥接主叫。可能的值为 '0' 或 '1'
- **prov_media_uri (optional)** - 能够从桥接场景开始到最后向其播放临时媒体的媒体服务器 URI。这是可选的。如果不存在，则不会有其他实体参与桥接场景

MI FIFO 命令格式：

```c
	opensips-cli -x mi b2b_logic:bridge 1020.30 sip:alice@opensips.org
```

opensips-cli 命令格式：

```c
	opensips-cli -x mi b2b_logic:bridge 1020.30 sip:alice@opensips.org
```

#### b2b_logic:list

替换已废弃的 MI 命令：*b2b_list*。

此命令可用于列出 b2b_logic 实体的内部信息。

名称：*b2b_logic:list*

参数：*无*

MI FIFO 命令格式：

```c
	opensips-cli -x mi b2b_logic:list
```

#### b2b_logic:terminate_call

替换已废弃的 MI 命令：*b2b_terminate_call*。

终止 ongoing B2B 会话。

名称：*b2b_logic:terminate_call*

参数：

- **key**：*b2b_logic key*，或 ongoing 会话的一个呼叫分支的 *callid;from-tag;to-tag*

MI FIFO 命令格式：

```c
	opensips-cli -x mi b2b_logic:terminate_call 159.0
```

### 导出的伪变量

#### $b2b_logic.key

这是只读变量，返回 ongoing B2B 会话的 b2b_logic 键。

此变量可用于请求路由、local_route 以及通过 *b2b_entities* 和 *b2b_logic* 模块定义的专用路由。

```c title="$b2b_logic.key 使用示例"
...
local_route {
   ...
   if ($b2b_logic.key) {
      xlog("request belongs to B2B session: $b2b_logic.key\n");
      ...
   }
   ...
}
...
```

#### $b2b_logic.entity(field)[idx]

这是只读变量，返回与 ongoing B2B 会话涉及的实体（会话）相关的信息。

可用的实体信息有：

- 会话的 Call-ID，可通过使用 *callid* 子名称访问
- 实体键，可通过使用 *key* 子名称或不使用任何子名称访问
- 实体 ID，可通过使用 *id* 子名称访问
- 会话的 From-Tag，可通过使用 *fromtag* 子名称访问
- 会话的 To-Tag，可通过使用 *totag* 子名称访问

索引用于选择要引用的 B2B 会话中的实体。唯一可能的值是 *0* 或 *1*，对应于场景中实体的位置。最初，这取决于创建实体的顺序。在内部拓扑隐藏场景的情况下，*0* 是主叫，*1* 是被叫。当发生进一步的桥接操作时，被桥接的实体总是放在 *0* 索引，新实体放在 *1*。

如果未提供索引，变量将引用当前 SIP 消息所属的实体（会话）。

此变量可用于请求路由、local_route 以及通过 *b2b_entities* 和 *b2b_logic* 模块定义的专用路由。

```c title="$b2b_logic.entity 使用示例"
...
modparam("b2b_entities", "script_request_route", "b2b_request")
...
route[b2b_request] {
   ...
   xlog("received request for entity: $b2b_logic.entity\n");
   ...
   if ($rm == "BYE" && $b2b_logic.entity == $(b2b_logic.entity[1]))
      xlog("Disconnecting callee\n")
   ...
}
...
```

#### $b2b_logic.ctx(key)

这是读写变量，提供对 ongoing B2B 会话上下文中自定义键值存储（字符串值）的访问。

此变量可用于请求路由、local_route 以及通过 *b2b_entities* 和 *b2b_logic* 模块定义的专用路由。在主请求路由中，甚至在实例化 *b2b_init_request()* 之前的场景之前，此变量可用于存储新的上下文值。

将变量设置为 *NULL* 将删除给定键的值。

```c title="$b2b_logic.ctx 使用示例"
...
modparam("b2b_entities", "script_reply_route", "b2b_reply")
...
route {
   ...
   b2b_init_request("prepaid", "sip:alice@127.0.0.1");

   $b2b_logic.ctx(my_extra_info) = "my_value";
   ...
}
route[b2b_reply] {
   ...
   xlog("my info: $b2b_logic.ctx(my_extra_info)\n");
   ...
}
...
```

#### $b2b_logic.scenario(key)

这是只读变量，返回 ongoing B2B 会话的场景 ID。

此变量可用于请求路由、local_route 以及通过 *b2b_entities* 和 *b2b_logic* 模块定义的专用路由。

```c title="$b2b_logic.scenario 使用示例"
...
route[b2b_logic_request] {
   if ($b2b_logic.scenario == "prepaid") {
      route(prepaid);
   } else {
      route(marketing);
   }
}
...
```

#### $b2b_logic.peer(b2b_key)

这是只读变量，返回与提供的 *callid;from-tag;to-tag* 格式的 associated b2b_key 通信的对等方。

```c title="$b2b_logic.peer 使用示例"
...
	$var(b2b_key) = $ci + ';' + $ft + ';' + $tt;
	xlog("$var(b2b_key) is talking to $b2b_logic.peer($var(b2b_key))\n");
...
```

## 开发者指南

此模块提供了一个 API，可供其他 OpenSIPS 模块使用。该 API 提供了从其他模块实例化 b2b 场景的函数（这是实例化 b2b 场景的另外两种方式 - 从脚本和通过 MI 命令 - 的补充）。此外，实例化可以动态控制，通过命令将参与呼叫的实体桥接到另一个实体或终止呼叫，甚至桥接两个现有呼叫。

### b2b_logic_bind(b2bl_api_t* api)

此函数绑定 b2b_entities 模块并填充导出函数结构，这些函数将在后面详细描述。

```c title="b2bl_api_t 结构"
...
typedef struct b2bl_api
{
	b2bl_init_f init;
	b2bl_bridge_f bridge;
	b2bl_bridge_extern_f bridge_extern;
	b2bl_bridge_2calls_t bridge_2calls;
	b2bl_terminate_call_t terminate_call;
	b2bl_set_state_f set_state;
	b2bl_bridge_msg_t bridge_msg;
}b2bl_api_t;
...
```

### init

字段类型：

```c
...
typedef str* (*b2bl_init_f)(struct sip_msg* msg, str* name, str* args[5],
		b2bl_cback_f, void* param);
...
```

初始化 b2b 场景。最后两个参数是在下面列出的 3 种情况下调用的回调函数和参数。回调函数具有以下定义：

```c
...
typedef int (*b2b_notify_t)(struct sip_msg* msg, str* id, int type, void* param);
...
```

第一个参数是 init 函数中给出的回调。

第二个参数是包含呼叫统计信息（开始时间、建立时间、呼叫时间）的结构。

第三个参数是场景实例化的当前状态。

最后一个参数是触发回调的事件。有 3 种事件会调用回调：

- **当从任一方收到 BYE 时** - 事件参数也将显示从哪一方收到 BYE，因此可以是 B2B_BYE_E1 或 B2B_BYE_E2
- **如果在桥接过程中从第二个实体收到否定回复** - 事件是 B2B_REJECT_E2
- **当 b2b logic 实体被删除时** - 事件是 B2B_DESTROY

返回码控制将如何处理导致事件（最后一个事件除外，此时返回码无关紧要）的请求/回复：

- **-1** - 错误
- **0** - 丢弃 BYE 或回复
- **1** - 在另一侧发送 BYE 或回复
- **2** - 按场景指示的做，如果没有定义规则则在另一侧发送 BYE 或回复

### bridge

字段类型：

```c
...
typedef int (*b2bl_bridge_f)(str* key, str* new_uri, str* new_from_dname,int entity_type);
...
```

此函数允许将正在由 b2b_logic 处理的呼叫中的实体桥接到另一个实体。

### bridge_extern

字段类型：

```c
...
typedef str* (*b2bl_bridge_extern_f)(str* scenario_name, str* args[5],
                b2bl_cback_f cbf, void* cb_param);
...
```

此函数允许启动外部场景，此时 B2BUA 从中间开始呼叫。

### bridge_2calls

字段类型：

```c
...
typedef int (*b2bl_bridge_2calls_t)(str* key1, str* key2);
...
```

使用此函数可以将两个现有呼叫桥接在一起。两个呼叫的第一个实体将连接，并向它们的对等方发送 BYE。

### terminate_call

字段类型：

```c
...
typedef int (*b2bl_terminate_call_t)(str* key);
...
```

终止呼叫。

### set_state

字段类型：

```c
...
typedef int (*b2bl_set_state_f)(str* key, int state);
...
```

设置场景状态。

### bridge_msg

字段类型：

```c
...
typedef int (*b2bl_bridge_msg_t)(struct sip_msg* msg, str* key, int entity_no);
...
```

此函数允许将呼入呼叫桥接到现有呼叫中的实体。

第一个参数是当前呼入呼叫的 INVITE 消息。

第二个参数是现有呼叫的 b2bl_key。

第三个参数是实体标识符。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享署名 4.0 国际许可证。
