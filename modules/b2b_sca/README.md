---
title: "b2b_sca 模块"
description: "此模块为 OpenSIPS 提供核心 SCA（Shared Call Appearance，共享呼叫外观）功能。它旨在与 presence_callinfo 模块协同工作。"
---

## 管理指南

### 概述

此模块为 OpenSIPS 提供核心 SCA（Shared Call Appearance，共享呼叫外观）功能。它旨在与 presence_callinfo 模块协同工作。

该模块处理呼叫控制的基本 SIP 信令，同时向存在服务器发布 callinfo 事件。它构建在 b2b_logic 模块之上，使用"拓扑隐藏"场景来控制 SIP 信令。

下面提供了一个典型的使用示例，其中 Alice 呼叫 Bob。Alice 与 b2b_sca 服务器之间的呼叫分支是 b2b_sca 服务器与 Bob 之间"共享"呼叫的"外观"呼叫。

```c
   主叫         主叫      b2b_sca     被叫   存在服务器
alice1@example alice2@example  server   bob@example watcher@example
     |              |             |           |           |
     |--INV bob------------------>|           |           |
     |              |             |--INV bob->|           |
     |              |             |--PUBLISH(alerting)--->|
     |              |             |<-----200 OK-----------|
     |              |             |           |           |
     |              |             |<-180 ring-|           |
     |<-180 ring------------------|           |           |
     |              |             |           |           |
     |              |             |           |           |
     |              |             |<-200 OK---|           |
     |<-200 OK--------------------|--ACK----->|           |
     |--ACK---------------------->|--PUBLISH(active)----->|
     |              |             |<-----200 OK-----------|
     |              |             |           |           |
     |--INV bob (hold)----------->|           |           |
     |              |             |--INV bob->|           |
     |              |             |--PUBLISH(held)------->|
     |              |             |<-----200 OK-----------|
     |              |             |<-200 OK---|           |
     |<--200 OK-------------------|           |           |
     |              |             |           |           |
     |              |--INV------->|           |           |
     |              |             |--INV bob->|           |
     |<-BYE-----------------------|--PUBLISH(active)----->|
     |--200 OK------------------->|<-----200 OK-----------|
     |              |             |<-200 OK---|           |
     |              |<-200 OK-----|           |

```

流程说明：

- Alice 从她的桌面 IP 电话（alice1）呼叫 Bob
- Bob 应答呼叫
- Alice 决定从会议室继续通话，她让 BOB 保持
- Alice 到达会议室并在会议室 IP 电话（alice2）上取回呼叫

### 待办事项

未来要添加的功能：

- 处理无限数量外观的能力

### 依赖

#### OpenSIPS 模块

加载此模块前必须先加载以下模块：

- **tm** 模块
- **pua** 模块
- **b2b_logic** 模块

### 导出的参数

#### hash_size (integer)

内部用于保持共享呼叫的哈希表大小。更大的表意味着更快的访问速度，但以内存为代价。哈希大小是 2 的幂次。

**默认值为 "10"。**

```c title="设置 hash_size 参数"
...
modparam("b2b_sca", "hash_size", "5")
...
```

#### presence_server (string)

存在服务器的地址，PUBLISH 消息应发送到这里（非必选）。如果未设置，PUBLISH 请求将基于 watcher 的 URI 路由。

**默认值为 "NULL"。**

```c title="设置 presence_server 参数"
...
modparam("b2b_sca", "presence_server", "sip:opensips.org")
...
```

#### watchers_avp_spec (string)

AVP 将包含一个或多个 watcher URI。如果未设置，将不会发送任何 PUBLISH 请求。watchers_avp_spec 必须在调用 sca_init_request() 之前设置。

**默认值为 "NULL"。**

```c title="设置 watchers_avp_spec 参数"
...
modparam("b2b_sca", "watchers_avp_spec", "$avp(watchers_avp_spec)")
...
route {
	...
	$avp(watchers_avp_spec) = "sip:first_watcher@opensip.org";
	$avp(watchers_avp_spec) = "sip:second_watcher@opensip.org";
	...
}
```

#### shared_line_spec_param (string)

必选参数。用于标识共享线路/呼叫的不透明字符串。shared_line_spec_param 必须在调用 sca_init_request() 之前设置。

**默认值为 "NULL"。**

```c title="设置 shared_line_spec_param 参数"
...
modparam("b2b_sca", "shared_line_spec_param", "$var(shared_line)")
...
```

#### appearance_name_addr_spec_param (string)

必选参数。它必须是有效的 SIP URI。它将填充 *Call-Info* SIP header 内的 *appearance-uri* SIP 参数。appearance_name_addr_spec_param 必须在调用 sca_init_request() 之前设置。

**默认值为 "NULL"。**

```c title="设置 appearance_name_addr_spec_param 参数"
...
modparam("b2b_sca", "appearance_name_addr_spec_param", "")
...
```

#### db_url (string)

要使用的数据库的 URL。

**默认值为 "NULL"。**

```c title="设置 db_url 参数"
...
modparam("b2b_sca", "db_url", "[dbdriver]://[[username]:[password]]@[dbhost]/[dbname]")
...
```

#### db_mode (integer)

b2b_sca 模块可以利用数据库进行持久化呼叫外观存储。使用数据库可确保活动的呼叫外观能够在机器重启或软件崩溃后存活。b2b_sca 模块支持以下数据库访问模式：

- **NO DB STORAGE** - 将此参数设置为 0
- **WRITE THROUGH**（同步写入数据库）- 将此参数设置为 1

**默认值为 0（NO DB STORAGE）。**

```c title="设置 db_mode 参数"
...
modparam("b2b_sca", "db_mode", 1)
...
```

#### table_name (string)

定义数据库中的表名。

**默认值为 "b2b_sca"。**

```c title="设置 table_name 参数"
...
modparam("b2b_sca", "table_name", "sla")
...
```

#### shared_line_column (string)

数据库中存储共享呼叫/线路 ID 的列名。请参阅 "shared_line_spec_param" 参数。

**默认值为 "shared_line"。**

```c title="设置 shared_line_column 参数"
...
modparam("b2b_sca", "shared_line_column", "")
...
```

#### watchers_column (string)

数据库中存储 watcher 列表的列名。请参阅 "watchers_avp_spec" 参数。

**默认值为 "watchers"。**

```c title="设置 watchers_column 参数"
...
modparam("b2b_sca", "watchers_column", "")
...
```

#### app[index]_shared_entity_column (string)

数据库中存储特定外观的共享实体的列名。请参阅 "sca_init_request" 获取更多信息。

**默认值为 "app[index]_shared_entity"。** 索引是 1 到 10 之间的整数。

```c title="设置 app[index]_shared_entity_column 参数"
...
modparam("b2b_sca", "app1_shared_entity_column", "first_shared_entity")
modparam("b2b_sca", "app2_shared_entity_column", "second_shared_entity")
...
```

#### app[index]_call_state_column (string)

数据库中存储特定外观的呼叫状态的列名。存储以下状态：

- **1** - alerting（振铃）
- **2** - active（活跃）
- **3** - held（保持）
- **4** - held-private（私人保持）

**默认值为 "app[index]_call_state"。** 索引是 1 到 10 之间的整数。

```c title="设置 app[index]_call_state_column 参数"
...
modparam("b2b_sca", "app1_call_state_column", "first_call_state")
modparam("b2b_sca", "app2_call_state_column", "second_call_state")
...
```

#### app[index]_call_info_uri_column (string)

数据库中存储特定外观的呼叫信息 URI 的列名。

**默认值为 "app[index]_call_info_uri"。** 索引是 1 到 10 之间的整数。

```c title="设置 app[index]_call_info_uri_column 参数"
...
modparam("b2b_sca", "app1_call_info_uri_column", "first_call_info_uri")
modparam("b2b_sca", "app2_call_info_uri_column", "second_call_info_uri")
...
```

#### app[index]_call_info_appearance_uri_column (string)

数据库中存储特定外观的呼叫信息外观 URI 的列名。对于每个外观，值从 "appearance_name_addr_spec_param" 参数中提取。

**默认值为 "app[index]_call_info_appearance_uri"。** 索引是 1 到 10 之间的整数。

```c title="设置 app[index]_call_info_appearance_uri_column 参数"
...
modparam("b2b_sca", "app1_call_info_appearance_uri_column", "first_call_info_appearance_uri")
modparam("b2b_sca", "app2_call_info_appearance_uri_column", "second_call_info_appearance_uri")
...
```

#### appindex_b2bl_key_column (string)

数据库中存储特定外观的 b2b_logic 键的列名。

**默认值为 "app[index]_b2bl_key"。** 索引是 1 到 10 之间的整数。

```c title="设置 app[index]_b2bl_key_column 参数"
...
modparam("b2b_sca", "app1_b2bl_key_column", "first_b2bl_key")
modparam("b2b_sca", "app2_b2bl_key_column", "second_b2bl_key")
...
```

### 导出的函数

#### sca_init_request(shared_line)

这是脚本编写者必须在初始 INVITE 上调用的函数，对于该 INVITE 必须实例化 SCA 呼叫（请参阅上面图中来自 alice1 的呼叫）。

参数含义：

- **shared_line (int)** - 一个整数，用于将呼叫分支标识为"外观"呼叫或"共享"呼叫：
  - **0**："共享"呼叫
  - **1**："外观"呼叫

```c title="sca_init_request() 使用示例"
...
modparam("b2b_sca",
	"shared_line_spec_param","$var(shared_line)")
modparam("b2b_sca",
	"appearance_name_addr_spec_param","$var(appearance_name_addr)")
modparam("b2b_sca",
	"watchers_avp_spec","$avp(watchers_avp_spec)")

...

	# 设置共享呼叫标识符
	$var(shared_line) = "alice";

	# 设置 watchers
	$avp(watchers_avp_spec) = "sip:alice1@example.com";
	$avp(watchers_avp_spec) = "sip:alice2@example.com";

	if (INCOMING_SHARED_CALL) {
		# 呼入是'共享'呼叫
		$var(shared_line_entity) = 0;
		# 设置外观名称地址
		$var(appearance_name_addr) = $fu;
	}
	else {
		# 呼入是'外观'呼叫
		# - 请参阅上面示例中 Alice 的初始呼叫分支
		$var(shared_line_entity) = 1;
		# 设置外观名称地址
		$var(appearance_name_addr) = $tu;
	}

	# 发起呼叫
	if (!sca_init_request($var(shared_line_entity))) {
		send_reply(403, "Internal Server Error (SLA)");
		exit;
	}
...
```

#### sca_bridge_request(shared_line_to bridge)

这是脚本编写者必须在现有共享呼叫的初始"外观" INVITE 上调用的函数。它将把当前的"外观"呼叫与现有的"共享"呼叫桥接，旧"外观"呼叫将断开（请参阅上面图中来自 alice2 的呼叫）。

参数含义：

- **shared_line_to_bridge (string)** - 一个字符串，标识之前由 sca_init_request() 设置的共享线路/呼叫。

```c
...
	if ($rU==NULL && is_method("INVITE") &&
		$fU==$tU && is_present_hf("Call-Info")) {
		# 呼入是'外观'呼叫
		# - 请参阅上面示例中 Alice 从 alice2 开始的呼叫
		$var(shared_line_to_bridge) = "alice";
		if (!sca_bridge_request($var(shared_line_to_bridge)))
			send_reply(403, "Internal SLA Error");
			exit;
		}
	}
...
```

### 导出的 MI 函数

#### b2b_sca:list

替换已废弃的 MI 命令：*sca_list*。

它列出属于共享线路/呼叫的外观。

名称：*b2b_sca:list*

参数：*无*

MI FIFO 命令格式：

```c
	opensips-cli -x mi b2b_sca:list
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享署名 4.0 国际许可证。
