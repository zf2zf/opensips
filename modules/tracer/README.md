---
title: "追踪器模块"
description: "提供将传入/传出的 SIP 消息存储在数据库中的可能性。自 2.2 版本起，需要加载 proto_hep 模块才能进行 hep 复制。所有 hep 参数已移至 proto_hep。"
---

## 管理指南


### 概述


提供将传入/传出的 SIP 消息存储在数据库中的可能性。
		自 2.2 版本起，需要加载 proto_hep 模块才能进行 hep 复制。
		所有 hep 参数已移至 proto_hep。


OpenSIPS 2.2 版本的追踪器模块带来了重大改进。
		现在您所要做的就是使用正确的参数调用 *trace()* 函数，
		它会为您完成工作。现在您可以使用同一函数追踪消息、事务和 dialog。
		此外，您可以使用仅一个参数追踪到多个数据库、多个 hep 目的地和 sip 目的地。
		您现在需要做的就是在 modparam 部分定义 *trace_id* 参数，
		并在追踪器函数中在它们之间切换。
		您还可以使用 *trace_on* 打开和关闭追踪，
		可以全局（针对所有 trace_ids）或针对特定 trace_id。


重要提示：在 2.2 版本中，对无状态追踪的支持已被移除。


追踪可以使用 fifo 命令打开/关闭。


opensips-cli -x mi trace on
	opensips-cli -x mi trace [some_trace_id] on


opensips-cli -x mi trace off
	opensips-cli -x mi trace [some_trace_id] off


从 OpenSIPS 3.0 开始，您可以使用 *trace_start*
		基于某些自定义过滤器创建动态追踪目的地。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *database module* - mysql、postrgress、
				dbtext、unixodbc... 仅当您使用数据库类型 trace id 时
- *b2b_logic* - 仅当您想要追踪
				B2B 会话时。
- *dialog* - 仅当您想要追踪
				SIP dialog（基于 INVITE）时。
- *tm* - 仅当您想要追踪 
				SIP 事务时。
- *proto_hep* - 仅当您想要 
				通过 HEP 协议追踪/复制消息时。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### trace_on (integer)


启用/禁用追踪的参数（开(1)/关(0)）


*默认值为 "1"（启用）。*


```c title="设置 trace_on 参数"
...
modparam("tracer", "trace_on", 1)
...
```


#### trace_local_ip (str)


用于指定本地生成消息的源地址
		（协议、IP 和端口）的字段的地址。
		如果未设置，模块会将其设置为将用于发送消息的套接字的地址。
		协议和/或端口是可选的，如果省略将采用默认值：udp 和 5060。


*默认值为 "NULL"。*


```c title="设置 trace_local_ip 参数"
...
# 结果地址：udp:10.1.1.1:5064
modparam("tracer", "trace_local_ip", "10.1.1.1:5064")
...

...
# 结果地址：tcp:10.1.1.1:5060
modparam("tracer", "trace_local_ip", "tcp:10.1.1.1")
...

...
# 结果地址：tcp:10.1.1.1:5064
modparam("tracer", "trace_local_ip", "tcp:10.1.1.1:5064")
...

...
# 结果地址：udp:10.1.1.1:5060
modparam("tracer", "trace_local_ip", "10.1.1.1")
...
```


#### trace_id (str)


指定追踪目的地。这可以是 proto_hep 中定义的 hep id、
			sip uri、文件、syslog facility 或数据库
			url 和表。所有 *trace_id* 内的参数必须用
			*;* 分隔，最后一个除外。
			参数以键值格式给出，可能的键有
			*uri* 用于 HEP 和 SIP ID，
			*uri* 和 *table*
			用于数据库。格式为
			*[id_name]key1=value1;key2=value2;*。
			HEP id **必须**在 proto_hep 中定义才能在此使用。


当 uri 是 *file* 时，文件路径必须指定在冒号之后。
			如果文件存在，输出总是追加，
			如果不存在则创建，使用 [文件模式](#param_file_mode) 权限。


当 uri 是 *syslog* 时，必须遵循以下格式：
			*syslog[:FACILITY[:LEVEL]]*。
			默认 facility 和 level 是 OpenSIPS 使用的
			（*syslog_facility* 和 *log_level*）。
			这些可以使用
			[syslog 默认 facility](#param_syslog_default_facility) 和
			[syslog 默认 level](#param_syslog_default_level) 参数进行调整。


可以声明多个类型的追踪在同一个 trace id 下，
			通过它们的名称识别。因此，如果您使用相同的名称
			定义两个数据库 url、一个 hep uri 和一个 sip uri，
			当使用此名称调用 trace() 时，追踪将执行到所有目的地。


所有旧参数如 db_url、table 和 duplicate_uri
			将使用名称 "default" 形成 trace id。


*没有默认值。如果不设置，模块将无法使用。*


```c title="设置 trace_id 参数"
...
/*DB trace id*/
modparam("tracer", "trace_id",
"[tid]
uri=mysql://xxxx:xxxx@10.10.10.10/opensips;
table=new_sip_trace;")
/* hep trace id，带有在 proto_hep 中定义的 hep id；有关更多信息请查看 proto_hep 文档
 * */
modparam("proto_hep", "hep_id",  "[hid]10.10.10.10")
modparam("tracer", "trace_id", "[tid]uri=hep:hid")
/*sip trace id*/
modparam("tracer", "trace_id",
"[tid]uri=sip:10.10.10.11:5060")
/* 注意它们都有相同的名称
 * 这意味着调用 trace("tid",...)
 * 将执行 sql、sip 和 hep 追踪 */
/*file trace id*/
modparam("tracer", "trace_id",
"[tid]uri=file:/path/to/file")
/*syslog trace id，错误级别 (level -1)*/
modparam("tracer", "trace_id",
"[tid]uri=syslog:local0:-1")
...
```


#### syslog_default_facility (string)


当使用 *syslog* 追踪时，此参数指定
			写入追踪的日志 facility。


*默认值是 *syslog_facility* 的值。*


```c title="设置 syslog_default_facility 参数"
...
modparam("tracer", "syslog_default_facility", "LOG_DAEMON")
...
```


#### syslog_default_level (integer)


当使用 *syslog* 追踪时，此参数指定
			写入追踪的级别。


*默认值是 *log_level* 的值。*


```c title="设置 syslog_default_level 参数"
...
modparam("tracer", "syslog_default_level", 2) # NOTICE
...
```


#### file_mode (integer)


当使用 *file* 追踪时，此参数指定
			用于创建追踪文件的权限。它遵循 UNIX 约定。


*默认值为 *0600 (rw-------)*。*


```c title="设置 file_mode 参数"
...
modparam("tracer", "file_mode", 0644)
...
```


### 导出的函数


#### trace(trace_id, [scope], [type], [trace_attrs], [flags], [correlation_id])


此函数在 OpenSIPS 3.0 中已替换 *sip_trace()*。


存储或复制当前处理的 SIP 消息、事务/dialog 或 B2B 会话。
			它以应用更改之前的形式存储。
			traced_user_avp 参数现在是 trace() 函数的参数。
			自 2.2 版本起，此函数还在无状态模式下捕获内部生成的回复（sl_send_reply(...)）。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE。


参数的含义如下：


- *trace_id (string)*
			指定在哪里进行追踪的 *trace_id* 的名称。
- *scope (string, 可选)* 您想追踪什么：
		dialog、事务、B2B 会话或仅消息。
		如果未指定，将尝试执行最顶层的追踪：
		如果加载了 dialog 模块将追踪 dialog，
		否则如果加载了 tm 模块将追踪事务，
		如果都没有加载则追踪消息。
类型可以是以下几种：

  - *'m'/'M'* 追踪消息。这是您应该在无状态模式下使用的唯一类型。
  - *'t'/'T'* 追踪事务。
				如果未加载 tm 模块，它将处于无状态事务感知模式，
				这意味着它会捕获选定的请求（进和出）
				以及内部生成的回复。
  - *'d'/'D'* 追踪 dialog
  - *'b'/'B'* 追踪与要创建的 B2B 会话相关的所有流量
- *type (string, 可选)* 此函数要追踪的消息类型列表；
			如果未设置，则只追踪 sip 消息；
			如果设置了参数但未指定 *sip*，
			则不会追踪 *sip*；
			列表中的所有参数必须用 '|' 分隔
当前可追踪的类型如下：

  - *sip* - 启用 sip 消息追踪；
  - *xlog* - 在当前范围（dialog、事务、B2B 会话
					或消息）中启用 xlog 消息追踪；
  - *rest* - 启用 rest 消息追踪；
- *trace_attrs (string, 可选)* 此参数替换旧版本的 traced_user_avp。
			为避免为此参数重复条目，
			您在此处放置的内容（字符串/pvar）
			将存储在 sip_trace 表的 trace_attrs 列中。
- *flags (string,pvar)* 是追踪过程的一些控制标志
			（如何追踪和追踪什么）。

  - *C* - 仅追踪 SIP 呼叫方侧；
  - *c* - 仅追踪 SIP 被叫方侧；
如果 *C* 和 *c* 标志都缺失，则假定追踪两侧/支路。
注意：这些标志仅在事务和 dialog 追踪中支持
- *correlation_id (string,pvar)* 一个自定义
			SIP correlation ID（通常使用 SIP Call-ID）
			用于将此流量（事务、dialog）与其他流量相关联。


```c title="trace() 使用示例"
...
/* 参见 trace_id 部分的声明 */
	$var(trace_id) = "tid";
	$var(user) = "osip_user@opensips.org";

...
/* 示例 1：如何追踪 dialog sip 和 xlog */
	if (has_totag()) {
		match_dialog();
	} else {
		if (is_method("INVITE") {
			trace($var(trace_id), "d", "sip|xlog", $var(user));
		}
	}
...
/* 示例 2：如何追踪初始 INVITE 和 BYE，sip 和 rest */
	if (has_totag()) {
		if (is_method("BYE")) {
			trace($var(trace_id), "m", "sip|rest", $var(user));
		}
	} else {
		if (is_method("INVITE")) {
			trace($var(trace_id), "m", "sip|rest", $var(user));
		}
	}

...
/* 示例 3：仅追踪初始 INVITE 事务的 xlog 和 rest，不追踪 sip */
	if (!has_totag()) {
		if (is_method("INVITE")) {
			trace($var(trace_id), "t", "xlog|rest", $var(user));
		}
	}
...
/* 示例 4：无状态事务感知模式！*/
/* tm 模块不能加载 */
	if (is_method("REGISTER")) {
		trace($var(trace_id), "t", "xlog|rest", $var(user));
		if (!www_authorize("", "subscriber")) {
			/* 追踪器还将捕获 www_challenge() 生成的 401 */
			www_challenge("", "auth");
		}
	}
```


### 导出的 MI 函数


#### trace


启用/禁用追踪（全局或针对特定 trace id）
			或转储有关 trace id 的信息。
			此命令需要命名参数
			（每个参数以 param_name=param_value 格式给出）。


名称：*trace*


参数：


- *id* (可选) - 追踪实例的名称。
				如果此参数缺失，命令将
				转储所有 tace id 的信息（并返回全局追踪状态）
				或设置全局追踪状态。
- *mode* (可选) - 
				可能的值为：

  - "on" - 启用追踪
  - "off" - 禁用追踪
如果第一个参数缺失，命令将设置全局追踪状态，
				否则它将为特定 trace id 设置状态。
				如果您打开全局追踪但某些 trace id 的追踪设置为关闭，
				它们将不执行追踪。
				如果您想为所有 trace id 打开追踪，
				您必须为每个单独设置。
如果此参数缺失但设置了第一个参数，
				命令将仅转储有关该特定 trace id 的信息。
				如果两个参数都缺失，命令将返回全局追踪状态，
				并为每个 id 转储信息。


MI FIFO 命令格式：


```c
# 显示全局追踪模式和所有追踪目的地：
opensips-cli -x mi trace
# 关闭全局追踪：
opensips-cli -x mi trace mode=off
# 打开针对目标 id tid2 的追踪：
opensips-cli -x mi trace id=tid2 mode=on

```


#### tracer:start


替换已弃用的 MI 命令：*trace_start*。


使用自定义过滤器创建动态追踪目的地。
			此函数可用于实时调试某些目的地的呼叫。


动态目的地不会在重启后保持！


名称：*tracer:start*


参数：


- *id* - 追踪实例的名称。
- *uri* - 此实例的目标 uri。
- *filter* (可选) - 用于过滤
				发送者接收的流量。
				此参数应该是一个数组，可以包含多个
				*condition=value* 格式的过滤器。
				*condition* 参数的可能值为：

  - caller
  - callee
  - ip
*condition* 参数可以包含多个不同的过滤器。
				为了满足整体条件并将流量发送到所需目的地，
				必须满足所有条件。
如果此参数缺失，所有流量都转发到目的地。
过滤器适用于任何传入请求
- *scope* - 要进行追踪的范围。
				此参数接收的格式类似于 *trace()* 函数接收的格式。
- *type* - 您要接收的消息类型。
				此参数接收的格式类似于 *trace()* 函数接收的格式。


用于开始追踪从 IP 127.0.0.1 到 HEP 目的地 10.0.0.1:9060 的呼叫的 MI FIFO 命令：


```c
		opensips-cli -x mi tracer:start id=ip_filter uri=hep:10.0.0.1:9060 filter=ip=127.0.0.1

```


用于开始追踪从用户 Alice 到用户 Bob 的呼叫的 MI FIFO 命令：


```c
		opensips-cli -x mi tracer:start id=alice_bob uri=hep:10.0.0.1:9060 filter=caller=Alice filter=caller=Bob

```


#### tracer:stop


替换已弃用的 MI 命令：*trace_stop*。


停止 OpenSIPS 向使用 *trace_start* 命令创建的动态 trace id 发送流量。


名称：*tracer:stop*


参数：


- *id* - 要停止的追踪实例的名称。


用于停止追踪从用户 Alice 到用户 Bob 的呼叫的 MI FIFO 命令：


```c
		opensips-cli -x mi tracer:stop alice_bob

```


### 数据库设置


在运行带有追踪器的 OpenSIPS 之前，
			您必须设置将存储数据的数据库表。
			因此，如果表不是由安装脚本创建的，
			或者您选择自己安装所有内容，
			您可以使用 opensips/scripts 文件夹中数据库目录中的
			tracer-create.sql SQL 脚本作为模板。
			您还可以在项目网页上找到完整的数据库文档，
			[https://opensips.org/docs/db/db-schema-devel.html](https://opensips.org/docs/db/db-schema-devel.html)。


### 已知问题


ACK 与离开 OpenSIPS 的事务相关，由于使用 forward_request 函数以无状态方式处理，
			因此不会被追踪。
			修复它意味着注册一个 fwdcb 回调，
			该回调将为所有消息调用，但仅被 ACK 使用，
			这将非常低效。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
