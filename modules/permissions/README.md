---
title: "permissions Module"
---

## 管理指南


### 概述


#### 呼叫路由


该模块可用于判断呼叫是否具有建立连接的适当权限。
权限规则存储在纯文本配置文件中，类似于
`hosts.allow` 和 `hosts.deny` 文件（由 tcpd 使用）。


当调用 `allow_routing` 函数时，
它会尝试找到与消息选定字段匹配的规则。


OpenSIPS 是一个分叉代理（forking proxy），因此单个消息可以同时发送到不同的目的地。在检查权限时，必须检查所有目的地，如果其中任何一个失败，则转发将失败。


匹配算法如下，优先匹配原则：


- 创建一组配对，形式为 (From, 分支1的 R-URI)、
(From, 分支2的 R-URI) 等。
- 当所有配对都匹配 allow 文件中的条目时，允许路由。
- 否则，当某个配对匹配 deny 文件中的条目时，拒绝路由。
- 否则，允许路由。


不存在的权限控制文件被视为空文件。因此，可以通过不提供任何权限控制文件来关闭权限控制。


From 头域和 Request-URI 始终使用正则表达式进行比较！有关语法，请参阅示例文件：
`config/permissions.allow`。


#### 注册权限


除了呼叫路由外，还可以检查 REGISTER
消息，并根据配置文件决定是否允许该消息以及是否接受注册。


该函数的主要目的是防止"禁止" IP 地址进行注册。例如，当恶意用户注册包含 PSTN 网关 IP 地址的 contact 时，他可能能够绕过 SIP 代理执行的授权检查。这是不希望的，因此应拒绝尝试注册 PSTN 网关 IP 地址。文件 `config/register.allow` 和 `config/register.deny` 包含示例配置。


注册检查函数的名称为 `allow_register`，其算法与
[呼叫路由](#call_routing) 中描述的算法非常相似。唯一的区别在于配对的创建方式。


该函数使用 To 头域而不是 From 头域，因为
REGISTER 消息中的 To 头域包含被注册人员的 URI。该函数使用 Contact 头域而不是分支的 Request-URI。


因此，匹配中使用的配对如下：(To, Contact 1)、
(To, Contact 2)、(To, Contact 3)，依此类推。


匹配算法与 [呼叫路由](#call_routing) 中描述的相同。


#### URI 权限


该模块可用于确定请求是否允许访问由
pvar 中存储的 URI 指定的目的地。权限规则存储在纯文本配置文件中，类似于
`hosts.allow` 和
`hosts.deny`（由 tcpd 使用）。


当调用 `allow_uri` 函数时，它尝试找到与消息选定字段匹配的规则。
匹配算法如下，优先匹配原则：


- 创建配对 <From URI, pvar 中存储的 URI>。
- 当配对匹配 allow 文件中的条目时，允许请求。
- 否则，当配对匹配 deny 文件中的条目时，拒绝请求。
- 否则，允许请求。


不存在的权限控制文件被视为空文件。因此，可以通过不提供任何权限控制文件来关闭权限控制。


From URI 和 pvar 中存储的 URI 始终使用正则表达式进行比较！有关语法，请参阅示例文件：
`config/permissions.allow`。


#### 地址权限


该模块可用于确定地址（IP
地址和端口）是否与缓存的 OpenSIPS 数据库表中存储的 IP 子网匹配。缓存数据库表中的端口 0 匹配任何端口。要匹配的组 ID、IP
地址、端口和传输协议值可以来自请求（`check_source_address`），也可以作为 pvar
参数或直接作为字符串给出（`check_address`）。


存储在缓存数据库表中的地址可以按组标识符（无符号整数）分组为一个或多个组。组标识符作为
`check_address` 和
`check_source_address` 的参数给出。


否则，请求被拒绝。


地址数据库表由模块参数指定。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *无其他 OpenSIPS 模块的依赖*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### default_allow_file (string)


默认的 allow 文件，用于没有参数的函数。如果你
不指定完整路径名，则使用主配置文件所在的目录。


*默认值为 "permissions.allow"。*


```c title="设置 default_allow_file 参数"
...
modparam("permissions", "default_allow_file", "/etc/permissions.allow")
...
```


#### default_deny_file (string)


包含拒绝规则的默认文件。该文件用于没有参数的函数。
如果你不指定完整路径名，则使用主配置文件所在的目录。


*默认值为 "permissions.deny"。*


```c title="设置 default_deny_file 参数"
...
modparam("permissions", "default_deny_file", "/etc/permissions.deny")
...
```


#### check_all_branches (integer)


如果设置，则 allow_routing 函数将检查所有分支的 Request-URI（默认）。如果禁用，则仅检查第一个分支的 Request-URI。


> [!警告]
> 除非你真正知道自己在做什么，否则不要禁用此参数。


*默认值为 1。*


```c title="设置 check_all_branches 参数"
...
modparam("permissions", "check_all_branches", 0)
...
```


#### allow_suffix (string)


当使用 `allow_routing` 或
`allow_register` 的一参数版本时，附加到基本名称以创建 allow 文件名的后缀。


> [!注意]
> 包括前导点。


*默认值为 ".allow"。*


```c title="设置 allow_suffix 参数"
...
modparam("permissions", "allow_suffix", ".allow")
...
```


#### deny_suffix (string)


当使用 `allow_routing` 或
`allow_register` 的一参数版本时，附加到基本名称以创建 deny 文件名的后缀。


> [!注意]
> 包括前导点。


*默认值为 ".deny"。*


```c title="设置 deny_suffix 参数"
...
modparam("permissions", "deny_suffix", ".deny")
...
```


#### db_url (string)


用于加载 IP 检查相关数据（"address" 表）的数据库 URL。


此参数是可选的，仅在你使用 IP 检查相关函数时才需要。如果这样做，你需要显式设置此参数（它不会从
"db_default_url" 继承）。


从版本 2.2 开始，此 URL 表示 "default" 分区的 db_url。


*默认值为 "NULL"。*


```c title="设置 db_url 参数"
...
modparam("permissions", "db_url", "dbdriver://username:password@dbhost/dbname")
...
```


#### address_table (string)


包含 `allow_register` 函数使用的匹配规则的数据库表名。
从版本 2.2 开始，此表名也代表没有 'table_name' 设置的分区的默认表名。


*默认值为 "address"。*


```c title="设置 address_table 参数"
...
modparam("permissions", "address_table", "pbx")
...
```


#### partition (string)


指定一个新的基于 IP 检查的分区（数据源）。此
参数可以设置多次。每个分区可以有特定的 "db_url" 和 "table_name"。如果未指定，这些值将从 [db url](#param_db_url)、db_default_url
或 [address table](#param_address_table) 继承。默认分区的名称为 'default'。


```c title="设置 partition 参数"
...
modparam("permissions", "partition", "
	inbound:
		db_url = postgres://opensips:opensipsrw@127.0.0.1/opensips;
		table_name = address")
...
```


#### grp_col (string)


地址表列的名称，包含地址的组标识符。


*默认值为 "grp"。*


```c title="设置 grp_col 参数"
...
modparam("permissions", "grp_col", "group_id")
...
```


#### ip_col (string)


地址表列的名称，包含地址的 IP 地址部分。


*默认值为 "ip"。*


```c title="设置 ip_col 参数"
...
modparam("permissions", "ip_col", "ipess")
...
```


#### mask_col (string)


地址表列的名称，包含地址的网络掩码。可能的值为 0-128。如果 IP 是 v4，应该是最多 32；如果是 v6，应该是最多 128。


*默认值为 "mask"。*


```c title="设置 mask_col 参数"
...
modparam("permissions", "mask_col", "subnet_length")
...
```


#### port_col (string)


地址表列的名称，包含地址的端口部分。


*默认值为 "port"。*


```c title="设置 port_col 参数"
...
modparam("permissions", "port_col", "prt")
...
```


#### proto_col (string)


地址表列的名称，包含传输协议，该协议与接收请求的传输协议进行匹配。可以存储在 proto_col 中的可能值为 "any"、"udp"、
"tcp"、"tls"、
"sctp" 和 "none"。值
"any" 始终匹配，值
"none" 从不匹配。


*默认值为 "proto"。*


```c title="设置 proto_col 参数"
...
modparam("permissions", "proto_col", "transport")
...
```


#### pattern_col (string)


地址表列的名称，包含一个模式（shell 通配符模式，类似于文件名匹配使用的模式），该模式与
`check_address`
或 `check_source_address` 接收的参数进行匹配。


*默认值为 "pattern"。*


```c title="设置 pattern_col 参数"
...
modparam("permissions", "pattern_col", "wildcard_col")
...
```


#### info_col (string)


地址表列的名称，包含一个字符串，
如果函数成功，该字符串将作为值添加到 `check_address`
或 `check_source_address` 的 pvar 参数中。


*默认值为 "context_info"。*


```c title="设置 info_col 参数"
...
modparam("permissions", "info_col", "info_col")
...
```


### 导出的函数


#### check_address(group_id, ip, port, proto [, context_info], [pattern], [partition])


如果作为参数给出的组 ID、IP 地址、端口和协议与缓存地址表中找到的 IP 子网匹配（如 [地址权限](#address_permissions) 中所述），则返回 1。
此函数接受 4 个强制参数和 3 个可选参数。


此函数可用于在无需认证的情况下检查请求是否允许。


参数含义如下：


- group_id (int)
此参数表示要匹配的组 ID。如果 group_id 参数为 "0"，则查询可以匹配缓存地址表中的任何组。
- ip (string)
此参数表示要匹配的 IP 地址。此参数不能为空。
- port (int)
此参数表示要匹配的端口。包含端口值 0 的缓存地址表条目匹配任何端口。
参数的 *0* 值也将匹配地址表中的任何端口。
- proto (string)
此参数表示传输使用的协议；传输协议是 "ANY" 或任何有效的传输协议值："UDP"、"TCP"、"TLS" 和 "SCTP"。
- context_info (var, 可选)
此参数表示在匹配时缓存地址表中的 context_info 字段将被存储在其中的变量。
- pattern (string, 可选)
此参数是一个字符串，要与地址表中的通配符模式字段进行匹配。
- partition (string, 可选)
组 ID 的可选分区名称。如果未指定分区，将使用 "default" 分区。


此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、
LOCAL_ROUTE、BRANCH_ROUTE、STARTUP_ROUTE、TIMER_ROUTE、EVENT_ROUTE 使用。


```c title="check_address() 使用示例"
...

// 检查 IP 地址/端口元组（作为字符串给出）和源协议
// （作为 pvar 给出），是否属于组 4，验证字符串 "texttest"
// 是否匹配数据库表中的通配符模式字段，并将上下文信息存储在 $avp(ctx)
if (check_address( 4, "192.168.2.135", 5700, "$socket_in(proto)", $avp(ctx), "texttest")) {
	t_relay();
	xlog("$avp(ctx)\n");
}

if (check_address( 4, "192.168.2.135", 5700, "$socket_in(proto)", , , "my_part")) {
	t_relay();
	xlog("$avp(ctx)\n");
}
...

// 检查源消息的 IP 地址/端口/协议元组是否在组 4 中
if (check_address( 4, "$si", "$sp", "$socket_in(proto)")) {
	t_relay();
}

...

// 检查存储在 AVP s:ip/s:port/s:proto 中的 IP 地址/端口/协议元组
// 是否在组 4 中，并将上下文信息存储在 $avp(ctx)
$avp(ip) = "192.168.2.135";
$avp(port) = 5061;
$avp(proto) = "any";
$avp(partition)="my_part";
if (check_address( 4, $avp(ip), $avp(port), $avp(proto), $avp(ctx), , $avp(partition))) {
	t_relay();
	xlog("$avp(ctx)\n");
}

...

// 检查 IP 地址/端口元组（作为字符串给出）和源协议
// （作为 pvar 给出）是否在组 4 中，验证字符串 "texttest" 是否匹配
// 数据库表中的通配符模式字段，不存储任何上下文信息
if (check_address( 4,$si, 5700, $socket_in(proto), ,"texttest")) {
	t_relay();
}

...
```


#### check_source_address(group_id , [context_info], [pattern], [partition])


等价于 check_address(group_id, "$si", "$sp", "$socket_in(proto)", context_info, pattern, partition)。


此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、
LOCAL_ROUTE、BRANCH_ROUTE、STARTUP_ROUTE、TIMER_ROUTE、EVENT_ROUTE 使用。


```c title="check_source_address() 使用示例"
...
// 检查源地址/端口/协议是否在组 4 中，并将
// 上下文信息存储在 $avp(ctx)
if (check_source_address( 4,$avp(ctx), , , $avp(my_partition))) {
	xlog("$avp(ctx)\n");
}else {
	sl_send_reply(403, "Forbidden");
}
...
```


#### get_source_group(var,[partition])


检查在缓存地址表或子网表中是否存在源 IP/端口/协议的条目。
如果是，则在变量参数中返回该组。如果不是，返回 -1。缓存地址表和子网表中的端口值 0 匹配任何端口。你也可以指定分区。如果未指定分区，将使用 "default" 分区。


参数：


- *var* (var)
- *partition* (string, 可选)


此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、
LOCAL_ROUTE、BRANCH_ROUTE 使用。


```c title="get_source_group() 使用示例"
...

if ( get_source_group( $var(group)) ) {
   # 对 $var(group) 进行操作
   xlog("group is $var(group)\n");
};
...
```


#### allow_routing()


如果 [呼叫路由](#call_routing) 中描述的所有配对都具有适当的权限（根据配置文件），则返回 true。此函数使用
`default_allow_file` 和
`default_deny_file` 中指定的默认配置文件。


此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE 使用。


```c title="allow_routing 使用示例"
...
if (allow_routing()) {
	t_relay();
};
...
```


#### allow_routing(basename)


如果 [呼叫路由](#call_routing) 中描述的所有配对都具有适当的权限（根据作为参数给出的配置文件），则返回 true。


参数含义如下：


- *basename* (string) - 基本名称，将通过附加
`allow_suffix` 和 `deny_suffix`
参数的内容来创建 allow 和 deny 文件名。
如果参数不包含完整路径名，则函数期望该文件位于服务器主配置文件所在的同一目录中。


此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE 使用。


```c title="allow_routing(basename) 使用示例"
...
if (allow_routing("basename")) {
	t_relay();
};
...
```


#### allow_register(basename)


如果 [注册权限](#registration_permissions) 中描述的所有配对都具有适当的权限（根据作为参数给出的配置文件），则函数返回 true。


参数含义如下：


- *basename* (string) - 基本名称，将通过附加
`allow_suffix` 和 `deny_suffix`
参数的内容来创建 allow 和 deny 文件名。
如果参数不包含完整路径名，则函数期望该文件位于服务器主配置文件所在的同一目录中。


此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE 使用。


```c title="allow_register(basename) 使用示例"
...
if ($rm=="REGISTER") {
	if (allow_register("register")) {
		save("location");
		exit;
	} else {
		sl_send_reply(403, "Forbidden");
	};
};
...
```


#### allow_uri(basename, uri)


如果 [URI 权限](#uri_permissions) 中描述的配对具有适当的权限（根据参数指定的配置文件），则返回 true。


参数含义如下：


- *basename* (string) - 基本名称，将通过附加
`allow_suffix` 和 `deny_suffix`
参数的内容来创建 allow 和 deny 文件名。
如果参数不包含完整路径名，则函数期望该文件位于服务器主配置文件所在的同一目录中。
- *uri* (string) - 要检查的 SIP URI。


此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE 使用。


```c title="allow_uri(basename, uri) 使用示例"
...
if (allow_uri("basename", $rt)) {  // 检查 Refer-To URI
	t_relay();
};
if (allow_uri("basename", $avp(uri)) {  // 检查存储在 $avp(uri) 中的 URI
	t_relay();
};
...
```


### 导出的 MI 函数


#### address_reload


使权限模块将地址数据库表的内容重新读入缓存内存。在缓存内存中，出于性能原因，条目存储在两个不同的表中：地址表和子网表（取决于掩码字段的值，32 或更小）。


参数：


- *partition* -
要重载的分区名称。如果未指定，所有分区都将被重载。


#### address_dump


使权限模块从缓存内存中转储地址表的内容。


参数：


- *partition* -
要转储的分区名称。如果未指定，所有分区都将被转储。


#### subnet_dump


使权限模块从缓存内存中转储子网表的内容。


参数：


- *partition* -
要转储的分区名称。如果未指定，所有分区都将被转储。


#### allow_uri


测试（URI, Contact）配对是否根据 allow/deny 文件允许。文件必须已由 OpenSIPS 加载。


参数：


- *basename* -
基本名称，将通过附加 allow_suffix 和 deny_suffix 参数的内容来创建 allow 和 deny 文件名。
- *URI* - 要测试的 URI
- *Contact* - 要测试的 Contact
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享署名 4.0 国际许可协议授权。
