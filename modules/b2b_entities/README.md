---
title: "B2B_ENTITIES"
description: "OpenSIPS 中的 B2BUA 实现分为两层：下层（在此模块中实现）实现了 UAS 和 UAC 的基本功能；上层 - 代表 B2BUA 的逻辑引擎，负责使用下层提供的功能实际实现 B2BUA 服务。"
---

## 管理指南

### 概述

OpenSIPS 中的 B2BUA 实现分为两层：

- **下层**（在此模块中实现）- 实现了 UAS 和 UAC 的基本功能
- **上层** - 代表 B2BUA 的逻辑引擎，负责使用下层提供的功能实际实现 B2BUA 服务

此模块存储 B2BUA 参与会话对应的记录。它导出一个 API，可供其他模块调用，提供以下功能：创建新会话记录、在会话中发送请求或回复，当下层收到属于已存储会话的请求或回复时，也会通知上层模块。

记录分为两种类型：**b2b 服务器实体**和 **b2b 客户端实体**，取决于创建模式。为收到的初始消息创建的实体是服务器实体，而将发送初始请求（创建新会话）的实体是 b2b 客户端实体。名称对应于第一个事务中的行为 - 如果是 UAS 则是服务器实体，如果是 UAC 则是客户端实体。

此模块不能单独实现 B2BUA，需要配合实现 B2B 逻辑的模块。

如果先加载了 uac_auth 模块，此模块能够响应认证挑战。b2b 认证的凭据列表也由 uac_auth 模块提供。

### 依赖

#### OpenSIPS 模块

- **tm**
- **db 模块**
- **uac_auth**（如果需要认证则为必选）

#### 外部库或应用程序

运行 OpenSIPS 加载此模块前必须安装以下库或应用程序：

- **无**

### 导出的参数

#### server_hsize (int)

存储 b2b 服务器实体的哈希表大小。这是实际大小的 2 的对数值。

**默认值为 "9"**（512 条记录）。

```c title="设置 server_hsize 参数"
...
modparam("b2b_entities", "server_hsize", 10)
...
```

#### client_hsize (int)

存储 b2b 客户端实体的哈希表大小。这是实际大小的 2 的对数值。

**默认值为 "9"**（512 条记录）。

```c title="设置 client_hsize 参数"
...
modparam("b2b_entities", "client_hsize", 10)
...
```

#### script_req_route (str)

当收到 B2B 请求时调用的 b2b 脚本路由名称。

```c title="设置 script_req_route 参数"
...
modparam("b2b_entities", "script_req_route", "b2b_request")
...
```

#### script_reply_route (str)

当收到 B2B 回复时调用的 b2b 脚本路由名称。

```c title="设置 script_repl_route 参数"
...
modparam("b2b_entities", "script_reply_route", "b2b_reply")
...
```

#### db_url (str)

数据库 URL。此参数可选，如不设置则数据不会存储到数据库。

```c title="设置 db_url 参数"
...
modparam("b2b_entities", "db_url", "mysql://opensips:opensipsrw@127.0.0.1/opensips")
...
```

#### cachedb_url (str)

要使用的 NoSQL 数据库的 URL。目前仅支持 Redis。

```c title="设置 cachedb_url 参数"
...
modparam("b2b_entities", "cachedb_url", "redis://localhost:6379/")
...
```

#### cachedb_key_prefix (string)

在 NoSQL 数据库中设置的每个键的前缀。

**默认值为 "b2be$".**

```c title="设置 cachedb_key_prefix 参数"
...
modparam("b2b_entities", "cachedb_key_prefix", "b2b")
...
```

#### update_period (int)

更新数据库中信息的时间间隔。

**默认值为 "100"。**

```c title="设置 update_period 参数"
...
modparam("b2b_entities", "update_period", 60)
...
```

#### b2b_key_prefix (string)

生成键时使用的字符串（它被插入 SIP 消息中作为 callid 或 to tag）。如果您在同一架构中使用多个级联的 OpenSIPS B2BUA 实例，设置此前缀很有用。有时 OpenSIPS B2BUA 会查看 callid 或 totag 以确定其格式，用来判断请求是否由它发送。

**默认值为 "B2B"。**

```c title="设置 b2b_key_prefix 参数"
...
modparam("b2b_entities", "b2b_key_prefix", "B2B1")
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
modparam("b2b_entities", "db_mode", 1)
...
```

#### db_table (str)

用于存储 B2B 实体的表名。

**默认值为 "b2b_entities"**

```c title="设置 db_table 参数"
...
modparam("b2b_entities", "db_table", "some table name")
...
```

#### cluster_id (int)

此实例所属集群的 ID。设置此参数可启用 OpenSIPS B2BUA 的集群支持，通过在实例之间复制 B2B 实体（B2B 会话）来实现。这也通过 *clusterer* 模块的数据"同步"机制确保重启持久性。

此 OpenSIPS 集群暴露 **"b2be-entities-repl"** 能力，以将节点标记为在任意同步请求期间有资格成为数据捐赠者。因此，集群必须至少有一个节点在 *clusterer.flags* 列/属性中标记为 **"seed"** 值才能完全正常运行。有关更多详细信息，请参阅 [clusterer - Capabilities](../clusterer#capabilities) 章节。

**默认值为 "0"（禁用集群）**

```c title="设置 cluster_id 参数"
...
modparam("b2b_entities", "cluster_id", 10)
...
```

#### passthru_prack (int)

此参数允许控制 PRACK 是本地生成（=0）还是端到端请求（=1）。

**默认值为 "0"（本地生成 PRACK）**

```c title="设置 passthru_prack 参数"
...
modparam("b2b_entities", "passthru_prack", 1)
...
```

#### advertised_contact (str)

对于使用 [mi ua session client start](#mi_ua_session_client_start) MI 函数启动的 UA 会话，在生成的消息中使用的 Contact。

```c title="设置 advertised_contact 参数"
...
modparam("b2b_entities", "advertised_contact", "opensips@10.10.10.10:5060")
...
```

#### ua_default_timeout (str)

对于使用 [ua session server init](#func_ua_session_server_init) 函数或 [mi ua session client start](#mi_ua_session_client_start) MI 函数启动的 UA 会话，默认超时时间（秒）。超过此间隔后将发送 BYE 并删除会话。

如未设置，默认值为 43200（12 小时）。

```c title="设置 ua_default_timeout 参数"
...
modparam("b2b_entities", "ua_default_timeout", 7200)
...
```

### 导出的函数

#### ua_session_server_init([key], [flags], [extra_params])

此函数通过处理初始 INVITE 来初始化新的 UA 会话。进一步收到的属于此会话的请求/回复将仅通过 [E UA SESSION](#event_e_ua_session) 事件处理。

参数：

- **key (var, optional)** - 返回新 UA 会话的 b2b 实体键的变量
- **flags (string, optional)** - 通过以下标志配置此 UA 会话的选项：
  - **t[nn]** - 此会话的最大持续时间（秒）。超过此超时后将发送 BYE 并删除会话。如果未设置，则使用 [ua default timeout](#param_ua_default_timeout) 配置的默认超时。例如：*t3600*
  - **a** - 通过 [E UA SESSION](#event_e_ua_session) 事件报告收到 ACK 请求
  - **r** - 通过 [E UA SESSION](#event_e_ua_session) 事件报告收到回复
  - **d** - 禁用收到 INVITE 的 200 OK 回复时自动发送 ACK（对于 UAC 会话或 re-INVITE）
  - **h** - 在 [E UA SESSION](#event_e_ua_session) 事件中提供 SIP 请求/回复的 headers
  - **b** - 在 [E UA SESSION](#event_e_ua_session) 事件中提供 SIP 请求/回复的 body
  - **n** - 不为使用此函数处理的初始 INVITE 触发 [E UA SESSION](#event_e_ua_session) 事件（event_type 为 *NEW*）
- **extra_params (string, optional)** - 要传递给 [E UA SESSION](#event_e_ua_session) 事件中 *extra_params* 参数的任意值。

此函数可用于 REQUEST_ROUTE。

```c title="ua_session_server_init 使用示例"
...
if(is_method("INVITE") && !has_totag()) {
   ua_session_server_init($var(b2b_key), "arhb");

   ua_session_reply($var(b2b_key), "INVITE", 200, "OK", $var(my_sdp));
   
   exit;
}
...
```

#### ua_session_update(key, method, [body], [extra_headers], [content_type])

为使用 [ua session server init](#func_ua_session_server_init) 函数或 [mi ua session client start](#mi_ua_session_client_start) MI 函数启动的 UA 会话发送顺序请求。

参数：

- **key (string)** - UA 会话的 b2b 实体键
- **method (string)** - 此请求的 SIP 方法名称
- **body (string, optional)** - 要包含在 SIP 消息中的 body
- **extra_headers (string, optional)** - 要包含在 SIP 消息中的额外 headers
- **content_type (string, optional)** - Content-Type header。如果缺少此参数且提供了 body，将使用 "Content-Type: application/sdp"

此函数可用于 REQUEST_ROUTE、EVENT_ROUTE。

```c title="ua_session_update 使用示例"
...
ua_session_update($var(b2b_key), "OPTIONS");
...
```

#### ua_session_reply(key, method, code, [reason], [body], [extra_headers], [content_type])

为使用 [ua session server init](#func_ua_session_server_init) 函数或 [mi ua session client start](#mi_ua_session_client_start) MI 函数启动的 UA 会话发送回复。

参数：

- **key (string)** - UA 会话的 b2b 实体键
- **method (string)** - 被回复的 SIP 方法名称
- **code (int)** - 回复代码
- **reason (string, optional)** - 回复原因字符串
- **body (string, optional)** - 要包含在 SIP 消息中的 body
- **extra_headers (string, optional)** - 要包含在 SIP 消息中的额外 headers
- **content_type (string, optional)** - Content-Type header。如果缺少此参数且提供了 body，将使用 "Content-Type: application/sdp"

此函数可用于 REQUEST_ROUTE、EVENT_ROUTE。

```c title="ua_session_reply 使用示例"
...
ua_session_reply($var(b2b_key), "INVITE", 180, "Ringing");
...
```

#### ua_session_terminate(key, [extra_headers])

终止使用 [ua session server init](#func_ua_session_server_init) 函数或 [mi ua session client start](#mi_ua_session_client_start) MI 函数启动的 UA 会话。

参数：

- **key (string)** - UA 会话的 b2b 实体键
- **extra_headers (string, optional)** - 要包含在 SIP 消息中的额外 headers

此函数可用于 REQUEST_ROUTE、EVENT_ROUTE。

```c title="ua_session_terminate 使用示例"
...
ua_session_terminate($var(b2b_key));
...
```

### 导出的 MI 函数

#### b2b_entities:list

替换已废弃的 MI 命令：*b2be_list*。

此命令可用于列出 b2b 实体的内部信息。

名称：*b2b_entities:list*

参数：*无*

MI FIFO 命令格式：

```c
	opensips-cli -x mi b2b_entities:list
```

#### ua_session_client_start

此命令通过发送初始 INVITE 启动新的 UAC 会话。进一步收到的属于此会话的请求/回复将仅通过 [E UA SESSION](#event_e_ua_session) 事件处理。

名称：*ua_session_client_start*

参数：

- **ruri** - Request URI
- **to** - To URI；也可以指定为：*display_name,uri* 以设置 Display Name，例如 *Alice,sip:alice@opensips.org*
- **from** - From URI；也可以指定为：*display_name,uri* 以设置 Display Name，例如 *Alice,sip:alice@opensips.org*
- **proxy (optional)** - 发送 INVITE 的出站代理 URI
- **body (optional)** - 消息 body
- **content_type (optional)** - 要使用的 Content Type header。如果缺少且提供了 body，将使用 "Content-Type: application/sdp"
- **extra_headers (optional)** - 额外 headers
- **flags (optional)** - 与 [ua session server init](#func_ua_session_server_init) 的 *flags* 参数含义相同的标志
- **socket (optional)** - OpenSIPS 发送 socket

opensips-cli 命令格式：

```c
opensips-cli -x mi ua_session_client_start ruri=sip:bob@opensips.org \
to=sip:bob@opensips.org from=sip:alice@opensips.org flags=arhb
```

#### ua_session_update

为使用 [ua session server init](#func_ua_session_server_init) 函数或 [mi ua session client start](#mi_ua_session_client_start) MI 函数启动的 UA 会话发送顺序请求。

名称：*ua_session_update*

参数：

- **key** - UA 会话的 b2b 实体键
- **method** - 此请求的 SIP 方法名称
- **body (optional)** - 要包含在 SIP 消息中的 body
- **extra_headers (optional)** - 要包含在 SIP 消息中的额外 headers
- **content_type (string)** - Content-Type header。如果缺少此参数且提供了 body，将使用 "Content-Type: application/sdp"

opensips-cli 命令格式：

```c
opensips-cli -x mi ua_session_update key=B2B.436.1925389.1649338095 method=OPTIONS
```

#### ua_session_reply

为使用 [ua session server init](#func_ua_session_server_init) 函数或 [mi ua session client start](#mi_ua_session_client_start) MI 函数启动的 UA 会话发送回复。

名称：*ua_session_reply*

参数：

- **key** - UA 会话的 b2b 实体键
- **method** - 被回复的 SIP 方法名称
- **code** - 回复代码
- **reason** - 回复原因字符串
- **body (optional)** - 要包含在 SIP 消息中的 body
- **extra_headers (optional)** - 要包含在 SIP 消息中的额外 headers
- **content_type (optional)** - Content-Type header。如果缺少此参数且提供了 body，将使用 "Content-Type: application/sdp"

opensips-cli 命令格式：

```c
opensips-cli -x mi ua_session_reply key=B2B.436.1925389.1649338095 method=OPTIONS code=200 reason=OK
```

#### ua_session_terminate

终止使用 [ua session server init](#func_ua_session_server_init) 函数或 [mi ua session client start](#mi_ua_session_client_start) MI 函数启动的 UA 会话。

名称：*ua_session_terminate*

参数：

- **key** - UA 会话的 b2b 实体键
- **extra_headers (optional)** - 要包含在 SIP 消息中的额外 headers

opensips-cli 命令格式：

```c
opensips-cli -x mi ua_session_terminate key=B2B.436.1925389.1649338095
```

#### ua_session_list

列出使用 [ua session server init](#func_ua_session_server_init) 函数或 [mi ua session client start](#mi_ua_session_client_start) MI 函数启动的 UA 会话信息。

名称：*ua_session_list*

参数：

- **key (optional)** - 要列出的 UA 会话的 b2b 实体键。如果缺失，将列出所有会话。

MI FIFO 命令格式：

```c
	opensips-cli -x mi ua_session_list
```

### 导出的事件

#### E_UA_SESSION

当属于使用 [ua session server init](#func_ua_session_server_init) 函数或 [mi ua session client start](#mi_ua_session_client_start) MI 函数启动的 ongoing UA 会话的请求/回复时触发此事件。

请注意，除非在启动 UA 会话时设置了 *r* 标志，否则不会报告任何回复。同样，只有在设置了 *a* 标志时才会报告 ACK 请求。

参数：

- **key** - UA 会话的 b2b 实体键
- **entity_type** - 指示这是 *UAS* 还是 *UAC* 实体
- **event_type** - 事件类型：
  - **NEW** - 对于初始 INVITE 请求，使用 [ua session server init](#func_ua_session_server_init) 函数处理
  - **EARLY** - 对于 1xx 临时响应
  - **ANSWERED** - 对于 2xx 成功响应
  - **REJECTED** - 对于 3xx-6xx 失败响应
  - **UPDATED** - 对于任何顺序请求，包括 ACK 但不包括 BYE/CANCEL
  - **TERMINATED** - 对于 BYE 或 CANCEL 请求
- **status** - 如果消息是 SIP 回复，则为回复状态码
- **reason** - 如果消息是 SIP 回复，则为回复原因
- **method** - SIP 方法名称
- **body** - SIP 消息 body
- **headers** - 消息中所有 SIP headers 的完整列表
- **extra_params** - 任意值。目前只有 [ua session server init](#func_ua_session_server_init) 函数在使用了 *extra_params* 参数时传递此值，且仅出现在 *NEW* event_type 中

## 开发者指南

此模块提供了一个 API，可供其他 OpenSIPS 模块使用。该 API 提供了用于创建和处理会话的函数。可以在收到初始消息时创建会话，这将对应一个 b2b 服务器实体，或者由服务器发起，在这种情况下将在 b2b_entities 模块中创建客户端实体。

### b2b_load_api(b2b_api_t* api)

此函数绑定 b2b_entities 模块并填充导出函数结构，这些函数将在后面详细描述。

```c title="b2b_api_t 结构"
...
typedef struct b2b_api {
	b2b_server_new_t          server_new;
	b2b_client_new_t          client_new;

	b2b_send_request_t        send_request;
	b2b_send_reply_t          send_reply;

	b2b_entity_delete_t       entity_delete;

	b2b_restore_linfo_t       restore_logic_info;
	b2b_update_b2bl_param_t   update_b2bl_param;
}b2b_api_t;
...
```

### server_new

字段类型：

```c
...
typedef str* (*b2b_server_new_t) (struct sip_msg* , str* local_contact,
		b2b_notify_t , str *mod_name, str* logic_key, struct b2b_tracer *tracer,
		void *param, b2b_param_free_cb free_param);
...
```

此函数请求 b2b_entities 模块创建新的服务器实体记录。内部处理实际上从消息中提取会话信息，并构建将存储在哈希表中的记录。第二个参数是指向函数的指针，当该会话有事件（请求或回复）时 b2b_entities 模块将调用该函数。第三个参数是指向值的指针，它将被存储并在调用通知函数时作为参数传入（必须在内共享内存中分配）。

返回值是记录的标识符，在调用其他表示会话中操作的函数（发送请求、发送回复）时会用到。

通知函数具有以下原型：

```c
...
typedef int (*b2b_notify_t)(struct sip_msg* msg, str* id, int type, void* param);
...
```

当收到属于 b2b_entities 处理的会话的请求或回复时调用此函数。第一个参数是消息，第二个是会话的标识符，第三个是标志，指示消息的类型（有两个可能的值 - B2B_REQUEST 和 B2B_REPLY）。最后一个参数是上层模块在创建实体时传入的参数。

### client_new

字段类型：

```c
...
typedef str* (*b2b_client_new_t) (client_info_t* , b2b_notify_t b2b_cback,
		b2b_add_dlginfo_t add_dlginfo_f, str *mod_name, str *logic_key,
		struct b2b_tracer *tracer, void *param, b2b_param_free_cb free_param);
...
```

此函数请求 b2b_entities 模块创建新的客户端实体记录，并通过发送初始消息创建新会话。参数是初始请求所需的所有值，加上通知函数和参数。b2b_cback 参数是指向回调函数的指针，当在此函数创建的会话中发生事件（收到回复或请求）时必须调用该回调。add_dlginfo_f 参数也是函数指针，指向一个回调，当为创建的会话收到最终成功响应时将调用该回调。回调将接收完整会话信息作为参数。应存储此信息并在调用 send_request 或 send_reply 函数时使用。

返回值是记录的标识符，在调用其他表示会话中操作的函数（发送请求、发送回复）时会用到。

### send_request

字段类型：

```c
...
typedef int (*b2b_send_request_t)(enum b2b_entity_type ,str* b2b_key, str* method,
		str* extra_headers, str* body, b2b_dlginfo_t*);
...
```

此函数请求 b2b_entities 模块在由 b2b_key 标识的 b2b 会话中发送请求。第一个参数是实体类型，可以有两个值：B2B_SERVER 和 B2B_CLIENT。第二个是由创建函数（server_new 或 client_new）返回的标识符，接下来是 新请求所需的信息：method、extra_headers、body。最后一个参数包含会话信息 - callid、to tag、from tag。这些信息用于完美匹配 b2b_entities 记录，以便为其发送新请求。

返回值为 0 表示成功，负值表示错误。

### send_reply

字段类型：

```c
...
typedef int (*b2b_send_reply_t)(enum b2b_entity_type et, str* b2b_key, int code, str* text,
		str* body, str* extra_headers, b2b_dlginfo_t* dlginfo);
...
```

此函数请求 b2b_entities 模块在由 b2b_key 标识的 b2b 会话中发送回复。第一个参数是实体类型，可以有两个值：B2B_SERVER 和 B2B_CLIENT。第二个是由创建函数（server_new 或 client_new）返回的标识符，接下来是 新回复所需的信息：code、text、body、extra_headers。最后一个参数包含用于匹配正确记录的会话信息。

返回值为 0 表示成功，负值表示错误。

### entity_delete

字段类型：

```c
...
typedef void (*b2b_entity_delete_t)(enum b2b_entity_type et, str* b2b_key,
	 b2b_dlginfo_t* dlginfo);
...
```

此函数必须由上层函数调用以删除 b2b_entities 中的记录。记录不会被 b2b_entities 模块自动清理，上层模块必须负责删除它们。

### restore_logic_info

字段类型：

```c
...
typedef int (*b2b_restore_linfo_t)(enum b2b_entity_type type, str* key,
		b2b_notify_t cback, void *param, b2b_param_free_cb free_param);
...
```

此函数用于在从数据库加载数据启动时恢复回调函数的指针。

### update_b2bl_param

字段类型：

```c
...
typedef int (*b2b_update_b2bl_param_t)(enum b2b_entity_type type, str* key,
		str* param, int replicate);
...
```

此函数可用于更改存储在实体中的逻辑参数（在实体在逻辑记录之间移动的情况下很有用）。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享署名 4.0 国际许可证。
