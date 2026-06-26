---
title: "dialog 模块"
description: "dialog 模块为 OpenSIPS 代理提供对话感知功能。其功能是跟踪当前对话,提供关于对话的信息(如当前有多少活跃对话)。"
---

## 管理指南

### 概述

dialog 模块为 OpenSIPS 代理提供对话感知功能。其功能是跟踪当前对话,提供关于对话的信息(如当前有多少活跃对话)。

除了跟踪, dialog 模块还提供每个对话的标志和属性(跨对话的持久数据)、对话分析和对话终止(基于超时或外部触发)。

该模块还通过内部 API 为在更多复杂对话功能之上构建其他 OpenSIPS 模块提供基础。

### 工作原理

要创建与初始请求关联的对话,您必须调用 create_dialog() 函数,可以带参数或不带参数。

当收到"BYE"时,对话会自动终止。如果没有"BYE",对话生命周期由默认超时控制(见"default_timeout" - [默认超时](#param_default_timeout))和自定义超时(见"$DLG_timeout" - [DLG 超时](#pv_DLG_timeout))。

一旦终止,内存中的对话可能会立即被销毁,或者,根据"delete_delay" - [删除延迟](#param_delete_delay)) 设置,它可能会在内存中保留一段时间,处于只读状态(无操作、无更改、无)。这种延迟可用于帮助路由可能在对话终止后收到的后期会话中请求(如由于重传的延迟 BYE、跨 BYE 请求、认证的 BYE 请求、慢速 ACK 重新邀请等)。

### 对话分析

对话分析是一种机制,有助于使用对话的任何属性(如呼叫者、目的地、呼叫类型等)对某些类型的对话进行分类、排序和跟踪。对话可以动态添加到不同的(多个)分析表中——从逻辑上讲,每个分析表可以具有特殊含义(如域外对话、终止到 PSTN 的对话等)。

有两种类型的分析:

- *无值* - 对话仅属于一个分析。(如外呼分析)。没有其他附加信息来描述对话对该分析的归属;
- *有值* - 对话属于具有特定值的分析(如呼叫者分析,其中值是呼叫者 ID)。对话对分析的归属与该值密切相关。

一个对话可以同时添加到多个分析中。

分析在请求路由中可见(用于初始和顺序请求)以及原始请求的分支、失败和回复路由中。

对话分析也可用于分布式系统,使用 OpenSIPS CacheDB 接口或 *clusterer* 模块。此功能允许您与使用相同 CacheDB 后端或属于 OpenSIPS 集群的多个 OpenSIPS 实例共享对话分析信息。为此,必须定义 **cachedb_url** 或 **profile_replication_cluster** 参数。此外,必须通过在 *profiles_with_value* 或 *profiles_no_value* 参数中的分析名称添加 *'/s'* 或 *'/b'* 后缀之一来将分析标记为共享。

### 对话集群

**对话复制** 是一种用于将发生在一个 OpenSIPS 实例上的所有对话更改镜像到一个或多个其他实例的机制。该过程通过使用促进 OpenSIPS 节点集群管理和发送复制相关 BIN 数据包(二进制编码,使用 *proto_bin*)的 *clusterer* 模块来简化。此功能有助于实现高可用性和/或负载均衡 ongoing calls。

配置接收和发送对话复制数据包非常简单,可以通过使用 **dialog_replication_cluster** 参数来完成。但除了共享数据之外,为了正确地对对话进行集群化,您需要使用 **共享标签** 机制来管理集群中哪个节点对哪个对话执行某些操作。
有关在不同使用场景中这将如何工作的配置示例,请参阅 [这篇文章](https://blog.opensips.org/2018/03/23/clustering-ongoing-calls-with-opensips-2-4/)。

以下操作**不会**对标记有处于"**备份**"状态的共享标签的对话执行:

- 向端点发送重新邀请或 OPTIONS ping
- 生成 BYE 请求或任何其他操作(如在对话过期时生成 CDR)
- 在对话事件(更新、删除)上发送复制数据包
- 在对话所属的分析中计算对话;仅在也启用了分析复制时

除了事件驱动的复制,OpenSIPS 实例还会在启动时首先尝试从集群中的另一个节点学习所有对话信息。数据同步机制要求将集群中的一个节点定义为"**种子**"节点。
请参阅 [clusterer](../clusterer#capabilities) 模块获取如何执行此操作以及为什么需要的详细信息。

在对话复制的上下文中,使用数据库作为获取对话数据重启持久性的故障保护很有用,以防集群中的所有节点都关闭了。如果为集群中的每个节点使用单独的本地 DB,这种方法最有意义。在从集群同步完成后,那些未通过同步重新确认的从数据库加载的对话将被删除并也从数据库中删除。

当已配置对话复制时,也不需要通过 *profile_replication_cluster* 参数配置分析复制。分析信息包含在发送到对话复制集群的对话更新中。但仍必须在 *profiles_with_value* 或 *profiles_no_value* 参数中将分析标记为共享。

当平台有多个 POP,其中为 HA 目的配置了单独的对话复制集群,并且还需要一个全局共享分析的集群时,应配置对话和分析复制。在这种情况下,通过使用共享标签机制来确保正确的对话计数(以避免在对话的活动和备份节点上重复计算每个对话)。

### 依赖

#### OpenSIPS 模块

以下模块必须在此模块之前加载:

- *TM* - 事务模块
- *RR* - 记录路由模块,如果在非拓扑隐藏情况下使用对话 ID 匹配,则为可选
- *clusterer* - 如果设置了 *replication_cluster* 参数(通过 clusterer 模块进行 contact 复制)

#### 外部库或应用程序

运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序:

- *无*。

### 导出的参数

#### enable_stats (整数)

是否应启用统计支持。通过统计变量,模块提供有关对话处理的信息。将其设置为零以禁用或非零以启用。

*默认值为"1(启用)"。*

```c title="设置 enable_stats 参数"
...
modparam("dialog", "enable_stats", 0)
...
```

#### hash_size (整数)

用于保存对话的哈希表的大小。较大的表速度更快但消耗更多内存。哈希大小必须是 2 的幂。

重要:如果要将对话信息存储在数据库中,则应使用恒定的 hash_size,否则恢复过程将不会发生。如果您真的想修改 hash_size,必须在重启 OpenSIPS 之前删除所有表行。

*默认值为"4096"。*

```c title="设置 hash_size 参数"
...
modparam("dialog", "hash_size", 1024)
...
```

#### log_profile_hash_size (整数)

用于存储 profile->dialog 关联的哈希表的大小。较大的表可以提供更多并行操作但消耗更多内存。哈希大小以 2 为底的对数提供(例如,log_profile_hash_size =4 表示表有 2^4 个条目)。

*默认值为"4"。*

```c title="设置 hash_size 参数"
...
modparam("dialog", "log_profile_hash_size", 5) #设置表大小为 32
...
```

#### rr_param (字符串)

要用对话 cookie 添加的 Record-Route 参数的名称。它用于快速匹配顺序请求的对话。

*默认值为"did"。*

```c title="设置 rr_param 参数"
...
modparam("dialog", "rr_param", "xyz")
...
```

#### default_timeout (整数)

如果没有设置自定义超时,则为默认对话超时(秒)。

*默认值为"43200(12 小时)"。*

```c title="设置 default_timeout 参数"
...
modparam("dialog", "default_timeout", 21600)
...
```

#### dlg_extra_hdrs (字符串)

一个字符串,包含要添加到模块生成的请求(如 BYE)中的额外首部(完整格式,带 EOH)。

*默认值为"NULL"。*

```c title="设置 dlf_extra_hdrs 参数"
...
modparam("dialog", "dlg_extra_hdrs", "Hint: credit expired\r\n")
...
```

#### dlg_match_mode (整数)

顺序请求应如何与已知对话匹配。这些模式是在 Record-Route 首部中存储为 cookie 的 cookie(DID)匹配和基于 SIP 元素(如 RFC3261 中)的匹配的组合。

支持的模式有:

- *0 - DID_ONLY* - 匹配完全基于 DID 完成;
- *1 - DID_FALLBACK* - 匹配首先尝试基于 DID,如果不存在,则回退到 SIP 匹配;
- *2 - DID_NONE* - 匹配完全基于 SIP 元素完成;不在 RR 中添加 DID 信息。

*默认值为"1 (DID_FALLBACK)"。*

请注意,如果您在 OpenSIPS 服务器上有呼叫循环(多次通过同一 OpenSIPS 实例),强烈建议仅使用 DID_ONLY 模式,因为基于 SIP 的匹配将有未定义行为 - 从 SIP 角度看,顺序对话将匹配呼叫的所有循环,因为 Call-ID、To 和 From TAG 都相同。

```c title="设置 dlg_match_mode 参数"
...
modparam("dialog", "dlg_match_mode", 0)
...
```

#### delete_delay (整数)

在终止后延迟删除/从内存中移除对话的时间间隔(秒)。一旦终止,对话将保持在只读状态(无操作、无更改),但仍能匹配和路由后期的会话中请求。

此全局值可以通过对话的 DLG_del_delay "$DLG_del_delay"([DLG del delay](#pv_DLG_del_delay)) 脚本变量进行每个呼叫的更改。

*默认值为"0"(禁用)。*

```c title="设置 delete_delay 参数"
...
modparam("dialog", "delete_delay", 10)
...
```

#### db_url (字符串)

如果您想将对话信息存储在数据库中,则必须指定数据库 URL。

*默认值为"mysql://opensips:opensipsrw@localhost/opensips"。*

```c title="设置 db_url 参数"
...
modparam("dialog", "db_url", "dbdriver://username:password@dbhost/dbname")
...
```

#### db_mode (整数)

描述如何将对话信息从内存推送到 DB。

支持的模式有:

- *0 - NO_DB* - 内存内容不
				刷新到数据库;
- *1 - REALTIME* - 任何对话信息
				更改都会立即反映到数据库中。
- *2 - DELAYED* - 对话信息
				更改将定期刷新到数据库,基于定时器例程。
- *3 - SHUTDOWN* - 对话信息
				仅在关闭时刷新到数据库 - 无运行时更新。

*默认值为"0"。*

```c title="设置 db_mode 参数"
...
modparam("dialog", "db_mode", 1)
...
```

#### db_update_period (整数)

如果选择以给定间隔存储对话信息,则更新对话信息的间隔(秒)。太短的间隔会产生密集的数据库操作,太长的间隔会忽略短对话。

*默认值为"60"。*

```c title="设置 db_update_period 参数"
...
modparam("dialog", "db_update_period", 120)
...
```

#### options_ping_interval (整数)

OpenSIPS 将生成会话中 OPTIONS ping 的一方或双方的时间间隔(秒)。

*默认值为"30"。*

```c title="设置 options_ping_interval 参数"
...
modparam("dialog", "options_ping_interval", 20)
...
```

#### reinvite_ping_interval (整数)

OpenSIPS 将生成会话中重新邀请 ping 的一方或双方的时间间隔(秒)。

**重要:** ping 超时检测每次此间隔 tick 时都会执行,而不是在重新邀请事务超时时!因此,请确保重新邀请事务的超时(例如"tm"模块的"fr_timeout" modparam或其 $T_fr_timeout 变量)始终**低于**此参数的值!未能确保此超时顺序可能会导致重新邀请 ping 由于在有机会正确超时之前重试而永远不会结束断开的对话。

*默认值为"300"。*

```c title="设置 reinvite_ping_interval 参数"
...
modparam("dialog", "reinvite_ping_interval", 600)
...
```

#### table_name (字符串)

如果您想将对话信息存储在数据库中,则必须指定表名。

*默认值为"dialog"。*

```c title="设置 table_name 参数"
...
modparam("dialog", "table_name", "my_dialog")
...
```

#### call_id_column (字符串)

数据库中存储对话 callid 的列名。

*默认值为"callid"。*

```c title="设置 call_id_column 参数"
...
modparam("dialog", "call_id_column", "callid_c_name")
...
```

#### from_uri_column (字符串)

数据库中存储呼叫者 sip 地址的列名。

*默认值为"from_uri"。*

```c title="设置 from_uri_column 参数"
...
modparam("dialog", "from_uri_column", "from_uri_c_name")
...
```

#### from_tag_column (字符串)

数据库中存储邀请请求的 From tag 的列名。

*默认值为"from_tag"。*

```c title="设置 from_tag_column 参数"
...
modparam("dialog", "from_tag_column", "from_tag_c_name")
...
```

#### to_uri_column (字符串)

数据库中存储被叫者 sip 地址的列名。

*默认值为"to_uri"。*

```c title="设置 to_uri_column 参数"
...
modparam("dialog", "to_uri_column", "to_uri_c_name")
...
```

#### to_tag_column (字符串)

数据库中存储邀请请求的 200 OK 响应中的 To tag 的列名(如果存在)。

*默认值为"to_tag"。*

```c title="设置 to_tag_column 参数"
...
modparam("dialog", "to_tag_column", "to_tag_c_name")
...
```

#### from_cseq_column (字符串)

数据库中存储呼叫者端 cseq 的列名。

*默认值为"caller_cseq"。*

```c title="设置 from_cseq_column 参数"
...
modparam("dialog", "from_cseq_column", "from_cseq_c_name")
...
```

#### to_cseq_column (字符串)

数据库中存储被叫者端 cseq 的列名。

*默认值为"callee_cseq"。*

```c title="设置 to_cseq_column 参数"
...
modparam("dialog", "to_cseq_column", "to_cseq_c_name")
...
```

#### from_route_column (字符串)

数据库中存储来自呼叫者端的路由记录的列名(代理到呼叫者)。

*默认值为"caller_route_set"。*

```c title="设置 from_route_column 参数"
...
modparam("dialog", "from_route_column", "from_route_c_name")
...
```

#### to_route_column (字符串)

数据库中存储来自被叫者端的路由记录的列名(代理到被叫者)。

*默认值为"callee_route_set"。*

```c title="设置 to_route_column 参数"
...
modparam("dialog", "to_route_column", "to_route_c_name")
...
```

#### from_contact_column (字符串)

数据库中存储呼叫者 contact uri 的列名。

*默认值为"caller_contact"。*

```c title="设置 from_contact_column 参数"
...
modparam("dialog", "from_contact_column", "from_contact_c_name")
...
```

#### to_contact_column (字符串)

数据库中存储被叫者 contact uri 的列名。

*默认值为"callee_contact"。*

```c title="设置 to_contact_column 参数"
...
modparam("dialog", "to_contact_column", "to_contact_c_name")
...
```

#### from_sock_column (字符串)

数据库中存储有关接收来自呼叫者的流量的本地接口信息的列名。

*默认值为"caller_sock"。*

```c title="设置 from_sock_column 参数"
...
modparam("dialog", "from_sock_column", "from_sock_c_name")
...
```

#### to_sock_column (字符串)

数据库中存储有关接收来自被叫者的流量的本地接口信息的列名。

*默认值为"callee_sock"。*

```c title="设置 to_sock_column 参数"
...
modparam("dialog", "to_sock_column", "to_sock_c_name")
...
```

#### dlg_id_column (字符串)

数据库中存储对话 id 信息的列名。

*默认值为"dlg_id"。*

```c title="设置 dlg_id_column 参数"
...
modparam("dialog", "dlg_id_column", "dlg_id_c_name")
...
```

#### state_column (字符串)

数据库中存储对话状态信息的列名。

*默认值为"state"。*

```c title="设置 state_column 参数"
...
modparam("dialog", "state_column", "state_c_name")
...
```

#### start_time_column (字符串)

数据库中存储对话开始时间信息的列名。

*默认值为"start_time"。*

```c title="设置 start_time_column 参数"
...
modparam("dialog", "start_time_column", "start_time_c_name")
...
```

#### timeout_column (字符串)

数据库中存储对话超时的列名。

*默认值为"timeout"。*

```c title="设置 timeout_column 参数"
...
modparam("dialog", "timeout_column", "timeout_c_name")
...
```

#### profiles_column (字符串)

数据库中存储对话分析的列名。

*默认值为"profiles"。*

```c title="设置 profiles_column 参数"
...
modparam("dialog", "profiles_column", "profiles_c_name")
...
```

#### vars_column (字符串)

数据库中存储对话变量的列名。

*默认值为"vars"。*

```c title="设置 vars_column 参数"
...
modparam("dialog", "vars_column", "vars_c_name")
...
```

#### sflags_column (字符串)

数据库中存储对话脚本标志的列名。

*默认值为"script_flags"。*

```c title="设置 sflags_column 参数"
...
modparam("dialog", "sflags_column", "sflags_c_name")
...
```

#### mflags_column (字符串)

数据库中存储对话模块标志的列名。

*默认值为"module_flags"。*

```c title="设置 mflags_column 参数"
...
modparam("dialog", "mflags_column", "mflags_c_name")
...
```

#### flags_column (字符串)

数据库中存储对话标志的列名。

*默认值为"flags"。*

```c title="设置 flags_column 参数"
...
modparam("dialog", "flags_column", "flags_c_name")
...
```

#### profiles_with_value (字符串)

带值的分析名称列表(字母数字/-/_)。标志 */b* 或 */s* 允许分别使用 clusterer 模块或 CacheDB 后端在 OpenSIPS 实例之间共享分析。

*默认值为"empty"。*

```c title="设置 profiles_with_value 参数"
...
modparam("dialog", "profiles_with_value", "callerCC; gatewayCC; clientChannels/s; codecUsed/b;")
...
```

#### profiles_no_value (字符串)

无值的分析名称列表(字母数字/-/_)。标志 */b* 或 */s* 允许分别使用 clusterer 模块或 CacheDB 后端在 OpenSIPS 实例之间共享分析。

*默认值为"empty"。*

```c title="设置 profiles_no_value 参数"
...
modparam("dialog", "profiles_no_value", "inbound ; outbound ; shared/s; repl/b;")
...
```

#### db_flush_vals_profiles (整数)

将对话值、分析和标志连同其他对话状态信息一起推送到数据库(见 db_mode 1 和 2)。

*默认值为"empty"。*

```c title="设置 db_flush_vals_profiles 参数"
...
modparam("dialog", "db_flush_vals_profiles", 1)
...
```

#### timer_bulk_del_no (整数)

应同时尝试删除的对话数量(单个查询)。

*默认值为"1"。*

```c title="设置 timer_bulk_del_no 参数"
...
modparam("dialog", "timer_bulk_del_no", 10)
...
```

#### race_condition_timeout (整数)

如果使用'E'标志创建对话,并且发生了 SIP Race condition,则对话将在'race_condition_timeout'秒后终止。目前,唯一支持的 race conditions 是(200OK vs CANCEL)和(early BYE vs 200OK)

*默认值为"5"秒。*

```c title="设置 race_condition_timeout 参数"
...
modparam("dialog", "race_condition_timeout", 1)
...
```

#### cachedb_url (字符串)

启用分布式对话分析,并指定 CacheDB 接口应使用的后端。

*默认值为"empty"。*

```c title="设置 cachedb_url 参数"
...
modparam("dialog", "cachedb_url", "redis://127.0.0.1:6379")
...
```

#### profile_value_prefix (字符串)

指定在将带值的分析插入 CacheDB 后端时要添加的前缀。这仅在启用分布式分析时使用。

*默认值为"dlg_val_"。*

```c title="设置 profile_value_prefix 参数"
...
modparam("dialog", "profile_value_prefix", "dlgv_")
...
```

#### profile_no_value_prefix (字符串)

指定在将无值的分析插入 CacheDB 后端时要添加的前缀。这仅在启用分布式分析时使用。

*默认值为"dlg_noval_"。*

```c title="设置 profile_no_value_prefix 参数"
...
modparam("dialog", "profile_no_value_prefix", "dlgnv_")
...
```

#### profile_size_prefix (字符串)

指定在 CacheDB 后端中保存带值分析大小的实体时要添加的前缀。这仅在启用分布式分析时使用。

*默认值为"dlg_size_"。*

```c title="设置 profile_size_prefix 参数"
...
modparam("dialog", "profile_size_prefix", "dlgs_")
...
```

#### profile_timeout (整数)

指定对话分析应在 CacheDB 中保持有效的时长,直到过期。这仅在启用分布式分析时使用。

*默认值为"86400"。*

```c title="设置 profile_timeout 参数"
...
modparam("dialog", "profile_timeout", "43200")
...
```

#### dialog_replication_cluster (整数)

使用 *clusterer* 模块指定对话复制的集群 ID。这启用在集群中发送和接收所有对话相关事件(创建、更新和删除)。

此 OpenSIPS 集群公开 **"dialog-dlg-repl"**
能力,以将节点标记为在任意同步请求期间有资格成为数据供体。因此,集群必须至少有一个节点标记为 **"seed"** 值作为 *clusterer.flags* 列/属性才能完全正常运行。
请参阅 [clusterer - 能力](../clusterer#capabilities) 章节获取更多详细信息。

*默认值为"0"(无复制)。*

```c title="设置 dialog_replication_cluster 参数"
...
modparam("dialog", "dialog_replication_cluster", 1)
...
```

#### profile_replication_cluster (整数)

使用 *clusterer* 模块指定分析复制的集群 ID。这启用在集群中发送和接收分析信息(值、对话计数)。

*默认值为"0"(无复制)。*

```c title="设置 profile_replication_cluster 参数"
...
modparam("dialog", "profile_replication_cluster", 1)
...
```

#### replicate_profiles_buffer (字符串)

用于指定二进制复制使用的缓冲区长度(字节)。通常这应该足够大以容纳尽可能多的数据,但又要足够小以避免 UDP 分片。建议值是所有复制实例之间的最小 MTU。

*默认值为 1400 字节。*

```c title="设置 replicate_profiles_buffer 参数"
...
modparam("dialog", "replicate_profiles_buffer", 500)
...
```

#### replicate_profiles_check (字符串)

检查旧复制分析值是否过时且应被移除的时间间隔(秒),以秒为单位。

*默认值为 10 秒。*

```c title="设置 replicate_profiles_check 参数"
...
modparam("dialog", "replicate_profiles_check", 100)
...
```

#### replicate_profiles_timer (字符串)

指定模块应多久将分析复制到其他实例一次的时间间隔,以毫秒为单位。

*默认值为 200 毫秒。*

```c title="设置 replicate_profiles_timer 参数"
...
modparam("dialog", "replicate_profiles_timer", 100)
...
```

#### replicate_profiles_expire (字符串)

指定从不同实例收到的分析计数器不再考虑的过期时间(秒)。这用于防止实例停止复制其计数器时的过时值。

*默认值为 10 秒。*

```c title="设置 replicate_profiles_expire 参数"
...
modparam("dialog", "replicate_profiles_expire", 10)
...
```

#### cluster_auto_sync (字符串)

指定当节点变得可到达时,是否自动发出同步请求(针对标记为备份状态共享标签的对话)。值 *1* 表示启用,*0* 表示禁用。

*默认值为 1(启用)。*

```c title="设置 cluster_auto_sync 参数"
...
modparam("dialog", "cluster_auto_sync", 0)
...
```

#### auto_prack_hangup_on_failure (整数)

控制使用"auto-prack"标志创建的对话在自动生成的 PRACK 事务失败时的行为。值 *1* 会导致 OpenSIPS 在相关 INVITE 事务上生成原生 *502 Bad Gateway* 回复,而值 *0* 会使 INVITE 事务保持不变。

失败意味着本地 PRACK 事务完成并收到最终否定回复或命中 TM 失败处理。

*默认值为"0"(禁用)。*

#### auto_prack_fr_timeout (整数)

为使用"auto-prack"标志创建的对话自动生成的 PRACK 事务指定 TM FR 超时(秒)。此值在本地 PRACK 事务创建后立即应用。

*默认值为"3"。*

### 导出的函数

#### create_dialog([flags])

该函数为当前处理的请求创建对话。该请求必须是初始请求。

可选地,该函数也接收一个字符串参数,该参数指定要对此当前对话执行的特殊行为。

参数:

- *flags (字符串,可选)*
			可能的值有:
				
				"bye-on-timeout" - 达到对话生命周期时,双向都会触发 BYE
				"options-ping-caller" - 使用 OPTIONS 消息 ping 呼叫者端,每
				`options_ping_interval` 秒一次
				"options-ping-callee" - 使用 OPTIONS 消息 ping 被叫者端,每
				`options_ping_interval` 秒一次
				"reinvite-ping-caller" - 使用 RE-INVITE 消息 ping 呼叫者端,每
				`reinvite_ping_interval` 秒一次
				"reinvite-ping-callee" - 使用 RE-INVITE 消息 ping 被叫者端,每
				`reinvite_ping_interval` 秒一次
				"end-on-race-condition" - 检测到 SIP Race condition 时(见 RFC 5407),在
				`race_condition_timeout` 秒后结束呼叫
				"auto-prack" - 为携带 RSeq 首部的可靠 101-199 临时 INVITE 回复自动生成 PRACK 请求
				
				多个字符串标志可以作为 CSV 同时使用,即传递
				"bye-on-timeout,options-ping-caller,options-ping-callee"
				将启用所有 3 个标志。

注意:不能同时为单个对话端启用 RE-INVITE 和 OPTIONS ping。如果为同一端提供了两个标志(例如
				"options-ping-caller,reinvite-ping-caller" 或
				"options-ping-callee,reinvite-ping-callee"),
				则只会使用 RE-INVITE ping。

如果对话创建成功或对话已存在,则函数返回 true。

此函数可以从 REQUEST_ROUTE 使用。

```c title="create_dialog() 使用示例"
...
create_dialog();
...
#ping 呼叫者
create_dialog("options-ping-caller");
...
#ping 呼叫者和被叫者
create_dialog("options-ping-caller,options-ping-callee");

#超时时 bye
create_dialog("bye-on-timeout");

#auto-PRACK 可靠临时回复
create_dialog("auto-prack");
...
```

#### match_dialog([dlg_match_mode])

此函数用于将顺序(会话中)请求匹配到 ongoing 对话。

默认情况下,对话匹配根据 [dlg match mode](#param_dlg_match_mode) 模块参数执行。可以通过指定可选的"dlg_match_mode"参数来强制执行特定匹配模式。此参数的可能值为"DID_ONLY"、"DID_FALLBACK"和"DID_NONE"。

由于顺序请求在进行"loose_route()"时会自动匹配到对话,此函数旨在:(A)控制脚本中执行对话匹配的位置;(B)处理没有 Route 首部的虚假顺序请求,因此不会被 loose_route() 处理。

参数:

- *dlg_match_mode (字符串,可选)*

如果请求存在对话,函数返回 true。

此函数可以从 REQUEST_ROUTE 使用。

```c title="match_dialog() 使用示例"
...
    if (has_totag()) {
        loose_route();

        # 示例 1:根据
```

#### validate_dialog()

该函数检查当前收到的请求与它所属的对话(内部数据)。
通过执行多个测试,该函数将有助于检测注入的虚假会话中请求(如恶意 BYE)。

执行的测试与 CSEQ 序列检查和路由信息检查(contact 和路由集)相关。

如果请求存在对话且请求有效(根据对话数据),则函数返回 true。如果请求无效,则返回以下返回码:

- *-1* - 无效的 cseq
- *-2* - 无效的远程目标
- *-3* - 无效的路由集
- *-4* - 其他错误(解析、无对话等)

此函数可以从 REQUEST_ROUTE 使用。

```c title="validate_dialog() 使用示例"
...
    if (has_totag()) {
        loose_route();
        if ($DLG_status!=NULL && !validate_dialog() ) {
            xlog(" 会话中虚假请求 \n");
        } else {
            xlog(" 会话中有效请求 - $DLG_dir !\n");
        }
    }
...
```

#### fix_route_dialog()

该函数强制会话中 SIP 消息包含由其所属对话的内部数据指定的 ruri、路由首部和 dst_uri。该函数将防止虚假注入的会话中请求(如恶意 BYE)的存在。

此函数可以从 REQUEST_ROUTE 使用。

```c title="fix_route_dialog() 使用示例"
...
    if (has_totag()) {
        loose_route();
        if ($DLG_status!=NULL)
            if (!validate_dialog())
                fix_route_dialog();
    }
...
```

#### get_dialog_info(attr,avp,key,key_val,no_dlgs)

该函数从另一个对话中提取对话值。它首先搜索所有现有(进行中)对话,查找具有名为"key"且值为"key_val"的对话变量的所有对话(即 $dlg_val(key)=="key_val" 的对话)。如果找到,它将从所有找到的对话中返回名为"attr"的对话变量的值到"avp"伪变量,否则不会写入"avp",并返回负错误代码。

注意:该函数不需要在对话上下文中调用 - 您可以在搜索其他对话时随时随地使用它。

参数含义如下:

- *attr (字符串)* - 要返回的(从找到的对话中)对话变量的名称;
- *avp (var)* - 用于存储从找到的对话中推送的"attr"对话变量值的 AVP。
			由于函数检查所有对话,这需要是一个实际的 AVP 以支持从所有匹配的对话推送值。
- *key (字符串)* - 用作搜索目标对话的键的对话变量名。
- *key_val (var)* - 用作键的对话变量的值,用于在搜索目标对话时。
- *no_dlgs (var)* - 包含键变量的对话总数。

此函数可以从所有路由使用。

```c title="get_dialog_info 使用示例"
...
if ( get_dialog_info("callee",$avp(callee_array),"caller",$fu,$var(dlg_no)) ) {
	xlog("呼叫者 $fu 有 $var(dlg_no) 个其他进行中呼叫,正在与:");	
	$var(it) = 0;
	while ($var(it) < $var(dlg_no)) {
		$var(current_callee) = $(avp(callee_array)[$var(it)]);
		xlog(" $var(current_callee) ");
		$var(it) = $var(it) + 1;
	}

	xlog("\n");
}

# 为当前呼叫创建对话并放置呼叫者和被叫者属性
create_dialog();
$dlg_val(caller) = $fu;
$dlg_val(callee) = $ru;
...
```

#### get_dialog_vals(names,vals,callid)

该函数获取另一个对话的所有对话变量。它首先基于给定的 SIP CallID 搜索所有现有(进行中)对话。如果找到,它以两个并行的名称和值数组形式返回所有对话变量(使用给定的"names"和"vals"变量)。由于这些变量必须保存数组,它们必须是 AVP。

注意:该函数不需要在对话上下文中调用 - 您可以在搜索其他对话时随时随地使用它。

参数含义如下:

- *names (var)* - 一个 AVP 变量,用于保存从找到的对话中获取的所有变量名。
- *vals (var)* - 一个 AVP 变量,用于保存从找到的对话中获取的所有变量值。
- *callid (字符串)* - 要搜索的对话的 callid(并获取变量)。

此函数可以从任何类型的路由使用。

```c title="get_dialog_vals 使用示例"
...
if ( get_dialog_vals($avp(d_names),$avp(d_vals),$var(callid)) ) {
	xlog("呼叫 $var(callid) 有变量:\n);
	$var(i) = 0;
	while ( $(avp(d_names)[$var(i)])!=NULL ) {
		xlog("var $var(i) 是 $(avp(d_names)[$var(i)])='$(avp(d_vals)[$var(i)])'\n");
		$var(i) = $var(i) + 1;
	}
}
...
```

#### get_dialogs_by_val(name,value,out_avp,out_dlg_no)

该函数在整个对话表中查找包含具有提供名称和值的 $dlg_val 的对话,并返回所有匹配对话的 $DLG_ctx_json 变量,将它们存储在提供的 out_avp 中。匹配对话的总数在 out_dlgs_no 变量中返回。

注意:该函数不需要在对话上下文中调用 - 您可以在搜索其他对话时随时随地使用它。

参数含义如下:

- *name (字符串)* - 用于查找的对话变量的名称。
- *value (var)* - 上述对话 val 的值。
- *out_avp (var)* - 将填充所有匹配呼叫的对话 JSON 的 AVP。
- *dlg_no (var)* - 将包含匹配对话总数的 out 变量。

此函数可以从任何类型的路由使用。

```c title="get_dialog_vals 使用示例"
...
if ( get_dialogs_by_val("caller",$fU,$avp(dlg_jsons),$avp(dlg_no)) ) {
	xlog("呼叫者 $fU 有 $avp(dlg_no) 个其他呼叫 \n);
	$var(i) = 0;
	while ( $(avp(dlg_jsons)[$var(i)])!=NULL ) {
		$json(dlg_info) := $(avp(dlg_jsons)[$var(i)]); 
		# 获取上述呼叫的任何信息并处理
		$var(i) = $var(i) + 1;
	}
}
...
```

#### get_dialogs_by_profile(name,value,out_avp,out_dlg_no)

该函数在整个对话表中查找配置为在提供的对话分析名称中的对话,并可选地使用提供的分析值。该函数返回所有匹配对话的 $DLG_ctx_json 变量,将它们存储在提供的 out_avp 中。匹配对话的总数在 out_dlgs_no 变量中返回。

注意:该函数不需要在对话上下文中调用 - 您可以在搜索其他对话时随时随地使用它。

参数含义如下:

- *name (字符串)* - 用于查找的对话分析的名称。
- *value (字符串)* - 上述对话分析的值(可选)。
- *out_avp (var)* - 将填充所有匹配呼叫的对话 JSON 的 AVP。
- *dlg_no (var)* - 将包含匹配对话总数的 out 变量。

此函数可以从任何类型的路由使用。

```c title="get_dialog_vals 使用示例"
...
if ( get_dialogs_by_profile("caller",$fU,$avp(dlg_jsons),$avp(dlg_no)) ) {
	xlog("呼叫者 $fU 有 $avp(dlg_no) 个其他呼叫 \n);
	$var(i) = 0;
	while ( $(avp(dlg_jsons)[$var(i)])!=NULL ) {
		$json(dlg_info) := $(avp(dlg_jsons)[$var(i)]); 
		# 获取上述呼叫的任何信息并处理
		$var(i) = $var(i) + 1;
	}
}
...
```

#### load_dialog_ctx( dialog [, id_type] [, active_only])

该函数加载并切换到给定对话的上下文。
对话的上下文由对话的标志、变量、分析以及与对话相关的任何其他值/状态给出。通过切换到另一个对话的上下文,您将在脚本级别默认看到新对话的所有数据。

注意:在执行卸载之前,您无法执行新的加载 - 不支持嵌套加载。

参数含义如下:

- *dialog (字符串)* - 要加载的对话的标识符,它可以是 SIP Call-ID 或对话 ID。
- *id_type (字符串,可选)* - 第一个参数中使用的对话标识符类型。它可以是 *callid*(SIP Call-ID)或 *did*(内部对话 ID)。默认为 callid。
- *active_only (整数,可选)* - 如果设置为不同于 *0* 的值,
			它仅考虑活动对话 - 未删除的对话。

此函数可以从任何类型的路由使用。

```c title="load_dialog_ctx 使用示例"
...
if (load_dialog_ctx("$var(callid)")) {
	xlog("对话 '$var(callid)' 已经存在 "
	     "$DLG_lifetime 秒\n");
	if (is_in_profile("inboundCall"))
		xlog("这是一个入站呼叫\n");
	unload_dialog_ctx();
}
...
```

#### unload_dialog_ctx()

该函数卸载另一个对话的加载上下文,暴露执行加载之前存在的任何对话上下文。

注意:您必须从脚本中显式卸载您执行的每次加载,否则加载的对话将永远挂起。

此函数可以从任何类型的路由使用。

有关使用示例,请参阅 [load dialog ctx](#func_load_dialog_ctx)。

#### set_dlg_profile(profile, [value], [clear_values])

将当前对话插入分析。请注意,如果分析不支持值,这将静默丢弃。一个对话可以多次插入同一分析。

注意:必须在使用此函数之前创建对话(请在此之前使用 create_dialog() 函数)。

参数含义如下:

- *profile (字符串)* - 要添加到对话的分析的名称。
- *value (字符串,可选)* - 字符串值用于定义对话对该分析的归属 - 请注意,分析必须支持值。
- *clear_values (布尔值,可选)* - 如果设置为 *true*(1),
				所有分析值将在设置给定值之前清除。默认值: *false*。

此函数可以从 REQUEST_ROUTE, BRANCH_ROUTE,
			REPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="set_dlg_profile 使用示例"
...
set_dlg_profile("inboundCall");

# 设置新值(保留所有其他值)
set_dlg_profile("caller", $fu);

# 设置新值同时删除所有先前的值
set_dlg_profile("caller", $fu, true);
...
```

#### unset_dlg_profile(profile, [value])

从分析中移除当前对话。

注意:必须在使用此函数之前创建对话(请在此之前使用 create_dialog() 函数)。

参数含义如下:

- *profile (字符串)* - 要从中移除的分析的名称。
- *value (字符串,可选)* - 字符串值用于定义对话对该分析的归属 - 请注意,分析必须支持值。
3.4 新增:对于带值的分析,通过省略此参数,您现在可以清除给定分析的所有值。

此函数可以从 REQUEST_ROUTE, BRANCH_ROUTE,
			REPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="unset_dlg_profile 使用示例"
...
unset_dlg_profile("inboundCall");
unset_dlg_profile("caller", $fu);
...
# 清除分析中的所有值
unset_dlg_profile("caller");
...
```

#### is_in_profile(profile,[value])

检查当前对话是否属于某分析。如果分析支持值,则检查可以加强以考虑特定值 - 如果对话使用特定值插入到分析中。如果未传递值,则仅检查对话对该分析的简单归属。请注意,如果分析不支持值,这将静默丢弃。

注意:必须在使用此函数之前创建对话(请在此之前使用 create_dialog() 函数)。

参数含义如下:

- *profile (字符串)* - 要检查的分析的名称。
- *value (字符串,可选)* - 字符串值用于加强检查。

此函数可以从 REQUEST_ROUTE, BRANCH_ROUTE,
			REPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="is_in_profile 使用示例"
...
if (is_in_profile("inboundCall")) {
	log("此请求属于入站呼叫\n");
}
...
if (is_in_profile("caller","XX")) {
	log("此请求属于用户 XX 的呼叫\n");
}
...
```

#### get_profile_size(profile,[value],size)

返回属于某分析的对话数量。如果分析支持值,则检查可以加强以考虑特定值 - 有多少对话使用特定值插入到分析中。如果未传递值,则仅检查对话对该分析的简单归属。请注意,如果分析不支持值,这将静默丢弃。

参数含义如下:

- *profile (字符串)* - 要获取其大小的分析名称。
- *value (字符串,可选)* - 字符串值用于加强检查。
- *size (var)* - AVP 或脚本变量,用于返回分析大小。

此函数可以从 REQUEST_ROUTE, BRANCH_ROUTE,
			REPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="get_profile_size 使用示例"
modparam("dialog", "profiles_no_value", "inboundCalls")
modparam("dialog", "profiles_with_value", "caller")
...
get_profile_size("inboundCalls",,$var(size));
xlog("inboundCalls: $var(size)\n");
...
get_profile_size("caller", $fu, $var(size));
xlog("当前,用户 $fu 有 $var(size) 个活动外呼\n");
...
```

#### set_dlg_flag(flag)

将名为 *flag* 的对话标志设置为 true。对话标志是对话持久的,它们可以访问(设置和测试)属于该对话的所有请求。

参数:

- *flag (字符串,静态)* - 标志名称。

注意:必须在使用此函数之前创建对话(请在此之前使用 create_dialog() 函数)。

此函数可以从 REQUEST_ROUTE, BRANCH_ROUTE,
			REPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="set_dlg_flag 使用示例"
...
set_dlg_flag("MY_DLG_FLAG");
...
```

#### test_and_set_dlg_flag(flag, value)

原子性地检查名为 *flag* 的对话标志是否等于 *value*。如果是,则将其值更改为相反的值。此操作在对话锁下完成。

- *flag (字符串,静态)* - 标志名称。
- *value (整数)* - 值应为 0(false)或 1(true)。

注意:必须在使用此函数之前创建对话(请在此之前使用 create_dialog() 函数)。

此函数可以从 REQUEST_ROUTE, BRANCH_ROUTE,
			REPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="test_and_set_dlg_flag 使用示例"
...
test_and_set_dlg_flag("MY_DLG_FLAG", 0);
...
```

#### reset_dlg_flag(flag)

将名为 *flag* 的对话标志重置为 false。对话标志是对话持久的,它们可以访问(设置和测试)属于该对话的所有请求。

参数:

- *flag (字符串,静态)* - 标志名称。

注意:必须在使用此函数之前创建对话(请在此之前使用 create_dialog() 函数)。

此函数可以从 REQUEST_ROUTE, BRANCH_ROUTE,
			REPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="reset_dlg_flag 使用示例"
...
reset_dlg_flag("MY_DLG_FLAG");
...
```

#### is_dlg_flag_set(flag)

如果名为 *flag* 的对话标志已设置,则返回 true。对话标志是对话持久的,它们可以访问(设置和测试)属于该对话的所有请求。

参数:

- *flag (字符串,静态)* - 标志名称。

注意:必须在使用此函数之前创建对话(请在此之前使用 create_dialog() 函数)。

此函数可以从 REQUEST_ROUTE, BRANCH_ROUTE,
			REPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="is_dlg_flag_set 使用示例"
...
if (is_dlg_flag_set("MY_DLG_FLAG")) {
	xlog("对话标志 MY_DLG_FLAG 已设置\n");
}
...
```

#### store_dlg_value(name,val)

将变量 *val* 的值以名称 *name* 附加到对话。附加到对话的值是对话持久的,它们可以访问(读写)属于该对话的所有请求。

参数:

- *name (字符串)*
- *val (var)*

注意:必须在使用此函数之前创建对话(请在此之前使用 create_dialog() 函数)。

也可以通过将值赋给伪变量 *$dlg_val(name)* 来获得相同功能。

此函数可以从 REQUEST_ROUTE, BRANCH_ROUTE,
			REPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="store_dlg_value 使用示例"
...
store_dlg_value("inv_src_ip",$si);
store_dlg_value("account type",$var(account));
# 或
$dlg_val(account_type) = "prepaid";
...
```

#### fetch_dlg_value(name,val)

从对话中获取名为 *name* 的属性值。附加到对话的值是对话持久的,它们可以访问(读写)属于该对话的所有请求。

参数:

- *name (字符串)*
- *val (var)*

注意:必须在使用此函数之前创建对话(请在此之前使用 create_dialog() 函数)。

也可以通过读取伪变量 *$dlg_val(name)* 来获得相同功能。

此函数可以从 REQUEST_ROUTE, BRANCH_ROUTE,
			REPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="fetch_dlg_value 使用示例"
...
fetch_dlg_value("inv_src_ip",$avp(2));
fetch_dlg_value("account type",$var(account));
# 或
$var(account) = $dlg_val(account_type);
...
```

#### set_dlg_sharing_tag(tag_name)

使用共享标签 *tag_name* 标记当前对话。从此时起,诸如会话中 ping、超时 BYE 等操作将取决于标签状态("备份"状态无操作,"活动"状态正常操作)。

有关更多详细信息,请参阅 [对话集群](#dialog_clustering) 章节。

参数:

- *tag_name (字符串)*

注意:必须在使用此函数之前创建对话(请在此之前使用 create_dialog() 函数)。

此函数可以从 REQUEST_ROUTE, BRANCH_ROUTE,
			REPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="set_dlg_sharing_tag 使用示例"
...
set_dlg_sharing_tag("vip1");
...
```

#### dlg_on_answer([route_name])

该函数在当前对话稍后被应答时设置要执行的脚本路由。当路由执行时,对话上下文将暴露,但没有有效的 SIP 消息(只是一个假消息)。

您必须在创建对话之后且在对话被应答之前使用此函数。

如果参数缺失,函数会重置之前设置的任何路由;将不会触发。

参数:

- *route_name (字符串,可选)* - 要执行的脚本路由的名称。

此函数可以从 REQUEST_ROUTE, BRANCH_ROUTE,
			REPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="dlg_on_answer 使用示例"
...
create_dialog();
dlg_on_answer("dlg_answered");
...
route[dlg_answered] {
	xlog("对话 $DLG_did 已被应答\n");
}
```

#### dlg_on_timeout([route_name])

该函数在当前对话超时(如持续时间)时设置要执行的脚本路由。当路由执行时,对话上下文将暴露,但没有有效的 SIP 消息(只是一个假消息)。

当路由执行时,对话尚未终止,只是其生命周期达到了设定的限制。在超时路由中,您可以增加对话过期超时(对话将继续)或者可以让对话终止(在此路由结束后)。

您必须在创建对话之后且在对话被应答之前使用此函数。

您必须在创建对话之后且在对话被应答之前使用此函数。

参数:

- *route_name (字符串,可选)* - 要执行的脚本路由的名称。

此函数可以从 REQUEST_ROUTE, BRANCH_ROUTE,
			REPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="dlg_on_timeout 使用示例"
...
create_dialog();
$DLG_timeout=120;
dlg_on_timeout("dlg_timeout");
...
route[dlg_timeout] {
	xlog("对话 $DLG_did 超时\n");
	if (_some_prolongation_condition)
		$DLG_timeout = 60; # 再给1分钟
}
```

#### dlg_on_hangup([route_name])

该函数在当前对话终止时设置要执行的脚本路由。当路由执行时,对话上下文将暴露,但没有有效的 SIP 消息(只是一个假消息)。请注意,对话已经终止,除了从其上下文读取数据外,您无能为力。

您必须在创建对话之后且在对话被应答之前使用此函数。
		
如果参数缺失,函数会重置之前设置的任何路由;将不会触发。

参数:

- *route_name (字符串,可选)* - 要执行的脚本路由的名称。

此函数可以从 REQUEST_ROUTE, BRANCH_ROUTE,
			REPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="dlg_on_hangup 使用示例"
...
create_dialog();
dlg_on_hangup("dlg_hangup");
...
route[dlg_hangup] {
	xlog("对话 $DLG_did 在 $DLG_lifetime 秒后终止\n");
}
```

#### dlg_send_sequential(method, leg, [, body] [, content-type] [, headers])

用于向对话的一个端点发送会话中请求。该函数假定它在对话上下文中运行 - 如果您从不同上下文(如 event_route)运行它,请确保首先使用 [load dialog ctx](#func_load_dialog_ctx) 函数加载对话上下文。

参数:

- *method (字符串)* -
			发送请求的方法。
- *leg (字符串)* - 发送请求的端点。必须是 *caller* 或 *callee*。
- *body (字符串,可选)* -
			请求中发送的可选 body。如果缺失,则不发送 body。
- *content-type (字符串,可选)* -
			发送的 body 的内容类型。每次发送带 body 的请求时,请确保指定此项,否则您的 UAC 很可能拒绝该请求。
- *headers (字符串,可选)* -
			附加到发送请求的首部。

此函数可以从任何路由使用。

```c title="dlg_send_sequential 使用示例转换 DTMF 代码"
...
event_route[E_RTPPROXY_DTMF] {
    if (load_dialog_ctx("$param(id)", "did")) {
        if ($param(stream) == 0) {
            $var(direction) = "callee";
        } else {
            $var(direction) = "caller";
        }
        dlg_send_sequential($var(direction), "INFO",
                "Signal=$param(digit)\nDuration=160",
                "application/dtmf-relay");
        unload_dialog_ctx();
    }
}
...
```

#### dlg_inc_cseq([tag, ][inc])

递增与对话标签标识的端点关联的对话生成的 CSeq。

参数:

- *tag (字符串,可选)* -
			要递增 CSeq 值的标签。如果缺失,则使用消息的 *To* 标签来识别要递增 CSeq 的端点。
- *inc (整数,可选)* - 用于递增/递减(如果为负)标识端点的 CSeq 的值。如果未使用,则值递增 *1*。

此函数可以从 REQUEST_ROUTE, FAILURE_ROUTE,
			ONREPLY_ROUTE, BRANCH_ROUTE 和 LOCAL_ROUTE 路由使用。

```c title="dlg_inc_cseq 使用示例"
...
route {
	...
	if (has_totag()) {
		if (loose_route())
			dlg_inc_cseq(); # 在每个会话中请求后向上游递增 CSeq
	}
}
...
```

### 导出的统计信息

#### active_dialogs

返回当前活动对话的数量(可以是已确认或未确认)。

#### early_dialogs

返回早期对话的数量。

#### processed_dialogs

从启动以来处理的对话总数(终止、过期或活动)。

#### expired_dialogs

从启动以来过期的对话总数。

#### failed_dialogs

返回失败对话的数量(由于各种原因从未建立的对话 - 内部错误、否定回复、取消等)。

#### create_sent

返回发送到其他 OpenSIPS 实例的复制对话 **创建** 请求数量。

#### update_sent

返回发送到其他 OpenSIPS 实例的复制对话 **更新** 请求数量。

#### delete_sent

返回发送到其他 OpenSIPS 实例的复制对话 **删除** 请求数量。

#### create_recv

返回从其他 OpenSIPS 实例接收的对话 **创建** 事件数量。

#### update_recv

返回从其他 OpenSIPS 实例接收的对话 **更新** 事件数量。

#### delete_recv

返回从其他 OpenSIPS 实例接收的对话 **删除** 事件数量。

### 导出的 MI 函数

#### dialog:list

替换已废弃的 MI 命令: *dlg_list*。

列出对话(呼叫)的描述。如果未提供参数,将列出所有对话。如果传递对话标识符作为参数(callid 和 fromtag),则仅列出该对话。如果传递索引和计数器参数,它将列出从索引开始的一定数量的"计数器"对话 - 这用于仅获取对话的部分。

名称: *dialog:list*

参数(带对话标识):

- *callid (可选)* - 如果要列出单个对话则为 callid。
- *from_tag (可选,但不能在没有 callid 参数的情况下存在)* - 要列出的对话的 fromtag(根据初始请求)。

参数(带对话计数):

- *index* - 对话列表应开始的位置偏移量。
- *counter* - 应列出的对话数量(从偏移量开始)。

MI FIFO 命令格式:

```c
		## 列出所有进行中的对话
		opensips-cli -x mi dialog:list
		## 通过 callid 和 From TAG 列出对话
		opensips-cli -x mi dialog:list callid=abcdrssfrs122444@192.168.1.1 from_tag=AAdfeEFF33
		## 列出从位置 40 开始的 10 个对话
		## (在所有进行中对话的列表中)
		opensips-cli -x mi dialog:list index=40 counter=10
		
```

#### dialog:list_ctx

替换已废弃的 MI 命令: *dlg_list_ctx*。

与"dialog:list"相同,但在对话描述中包含位于对话模块之上的模块的关联上下文。
此函数还打印对话的值。对于二进制值,不可打印字符以十六进制表示(例如 \x00)。

名称: *dialog:list_ctx*

参数: *参见"dialog:list"*

MI FIFO 命令格式:

```c
		opensips-cli -x mi dialog:list_ctx
		
```

#### dialog:end_dlg

替换已废弃的 MI 命令: *dlg_end_dlg*。

终止正在进行的对话。
			如果对话已建立,则双向发送 BYE。
			如果对话处于未确认或早期状态,将向被叫方发送 CANCEL,这将触发 487,当被转发时,也将终止呼叫者端的对话。

名称: *dialog:end_dlg*

参数为:

- *dialog_id* - 这是对话的标识符 - 它可以是(1)对话的唯一 ID(由 dialog:list 提供),或者(2)对话的 SIP Call-ID。
- *extra_hdrs* - (可选)字符串,包含要添加到 BYE 请求中的额外首部(完整格式)。

"dialog_id" 值可以通过"dialog:list" MI 命令获取。

MI FIFO 命令格式:

```c
		# 通过内部对话-ID 终止对话
		opensips-cli -x mi dialog:end_dlg 6ae.4b38d013
		# 通过其 SIP Call-ID 终止对话
		opensips-cli -x mi dialog:end_dlg Y2IwYjQ2YmE2ZDg5MWVkNDNkZGIwZjAzNGM1ZDY
		
```

#### dialog:profile_get_size

替换已废弃的 MI 命令: *profile_get_size*。

返回属于某分析的对话数量。如果分析支持值,则检查可以加强以考虑特定值 - 有多少对话使用特定值插入到分析中。如果未传递值,则仅检查对话对该分析的简单归属。请注意,如果分析不支持值,这将静默丢弃。

名称: *dialog:profile_get_size*

参数:

- *profile* - 要获取其值的分析名称。
- *value (可选)- 字符串值用于加强检查;

MI FIFO 命令格式:

```c
		opensips-cli -x mi dialog:profile_get_size inboundCalls
		
```

#### dialog:profile_list_dlgs

替换已废弃的 MI 命令: *profile_list_dlgs*。

列出属于某分析的所有对话。如果分析支持值,则检查可以加强以考虑特定值 - 仅列出使用该特定值插入到分析中的对话。如果未传递值,将列出属于该分析的所有对话。请注意,如果分析不支持值,这将静默丢弃。此外,当使用 CacheDB 接口使用共享分析时,此命令仅显示本地对话。

名称: *dialog:profile_list_dlgs*

参数:

- *profile* - 要列出其对话的分析名称。
- *value (可选)- 字符串值用于加强检查;

MI FIFO 命令格式:

```c
		opensips-cli -x mi dialog:profile_list_dlgs inboundCalls
		
```

#### dialog:profile_get_values

替换已废弃的 MI 命令: *profile_get_values*。

列出属于某分析的所有值及其计数。如果分析不支持值,将返回总数。请注意,此函数不适用于通过 CacheDB 接口的共享分析。

名称: *dialog:profile_get_values*

参数:

- *profile* - 要列出其对话的分析名称。

MI FIFO 命令格式:

```c
		opensips-cli -x mi dialog:profile_get_values inboundCalls
		
```

#### dialog:profile_end_dlgs

替换已废弃的 MI 命令: *profile_end_dlgs*。

从指定分析中终止所有正在进行的对话,在单个对话上执行与命令 **[mi end dlg](#mi_end_dlg)** 相同的操作。

名称: *dialog:profile_end_dlgs*

参数:

- *profile* - 将终止其对话的分析的名称。
- *value* - (可选)如果分析支持值,则仅终止具有指定值的对话。

MI FIFO 命令格式:

```c
		opensips-cli -x mi dialog:profile_end_dlgs inboundCalls
		
```

#### dialog:db_sync

替换已废弃的 MI 命令: *dlg_db_sync*。

将有关对话的所有信息从数据库加载到 OpenSIPS 内部内存中。如果在内存中找到对话且具有相同/较旧状态,则将使用数据库中的值进行更新。否则,较新的内存版本不会被更改。

名称: *dialog:db_sync*

它不带参数。

MI FIFO 命令格式:

```c
		opensips-cli -x mi dialog:db_sync
		
```

#### dialog:cluster_sync

替换已废弃的 MI 命令: *dlg_cluster_sync*。

此命令仅在启用对话复制时才会生效。

从 [对话复制集群](#param_dialog_replication_cluster) 中的合适供体节点完全同步内存中的对话信息。已经存在于内存中但未通过同步重新确认的对话将被丢弃。可以指定共享标签以仅同步标记有该共享标签的对话。

名称: *dialog:cluster_sync*

参数:

- *sharing_tag* - 对话必须标记以便同步的共享标签名称。

MI FIFO 命令格式:

```c
		opensips-cli -x mi dialog:cluster_sync vip1
		
```

#### dialog:restore_db

替换已废弃的 MI 命令: *dlg_restore_db*。

在潜在的同步失调事件后恢复对话表。该表被截断,然后用内存中的已确认对话填充。

名称: *dialog:restore_db*

它不带参数。

MI FIFO 命令格式:

```c
		opensips-cli -x mi dialog:restore_db
		
```

#### dialog:list_all_profiles

替换已废弃的 MI 命令: *list_all_profiles*。

列出所有对话分析,以及给定分析是否具有关联值的 1 或 0。

名称: *dialog:list_all_profiles*

参数: *它不带参数*

MI FIFO 命令格式:

```c
		opensips-cli -x mi dialog:list_all_profiles
		
```

#### dialog:push_var

替换已废弃的 MI 命令: *dlg_push_var*。

为给定的对话 ID 列表 / Call-ID 推送或更新对话值。

名称: *dialog:push_var*

参数: *它需要 3 个或更多参数*

- *dlg_val_name* - 需要插入/更新的对话值名称。
- *dlg_val_value* - 要插入/更新的值。
- *DID* - 对话标识符。可以是 $DLG_did 或实际 Call-ID。

MI FIFO 命令格式:

```c
		opensips-cli -x mi dialog:push_var var_name var_value DID1 [ DID2 DID3 ...  DIDN ]
		
```

#### dialog:send_sequential

替换已废弃的 MI 命令: *dlg_send_sequential*。

在正在进行的对话中发送顺序请求。

名称: *dialog:send_sequential*

参数:

- *callid* - 需要触发顺序消息的对话的 callid。
- *method* - (可选)用于顺序消息的方法。默认值为 *INVITE*。
- *mode* - (可选)可用于调整顺序消息行为的模式。*mode* 的可能值为:
					
					*caller* - (默认)发送顺序消息到呼叫者。在高可用性场景中,当您想更新上游的路由集(特别是 contact)时,此模式很有用。
					*callee* - 与 caller 相同,但发送顺序消息到被叫者。
					*challenge* - 发送顺序 INVITE(或 UPDATE)到呼叫者以质询其广告的 SDP body。收到 body 后,将其转发到被叫者。此模式在尝试更改两个端点(上游和下游)的路由集时很有用。它在尝试为 SDP body 重新协商时也很有用。
					*challenge-caller* - 与 *challenge* 相同。
					*challenge-callee* - 与 *challenge-caller* 相同,只是它首先质询被叫者,而不是呼叫者。
- *body* - (可选)可用于指定初始顺序消息的 body。*body* 参数的可能值为:
					
					*none* - (默认)不向顺序消息添加 body。
					*inbound* - 在生成的顺序消息的 body 中广告其对应方收到的最后一个 body。例如,如果 *mode=challenge-caller*,则消息将包含被叫者发送给 OpenSIPS 的 body。当您需要更改之前发送给呼叫者的 body 时,这很有用,因为您想为呼叫重新协商不同的媒体代理。这可以通过在 *local_route* 中捕获生成的请求并重新参与媒体代理来实现。
					*outbound* - 在生成的顺序消息的 body 中广告最后发送给该 UAC 的 body。例如,如果 *mode=challenge-caller*,则消息将包含 OpenSIPS 发送给呼叫者的最后一个 body。在高可用性场景中,当尝试重新协商服务器的 contact 但不需要更改之前发送的 body 时,这很有用。
					*custom:CONTENT_TYPE:BODY* - 可用于为生成的顺序消息指定特定 Content-Type 首部和 body。
- *headers* - (可选)可用于指定初始顺序消息的某些首部。

此函数异步运行,并返回最后收到的回复的状态码和原因,无论是 *challenge* 还是正常模式。

MI 命令格式:

```c
			opensips-cli -x mi dialog:send_sequential \
				callid=5291231-testing@127.0.0.1
			
```

用于触发媒体重新协商的 MI 命令:

```c
			opensips-cli -x mi dialog:send_sequential \
				callid=5291231-testing@127.0.0.1 \
				mode=challenge \
				body=inbound
			
```

用于在服务器故障转移后更新被叫者远程 Contact 的 MI 命令:

```c
			opensips-cli -x mi dialog:send_sequential \
				callid=5291231-testing@127.0.0.1 \
				mode=challenge-callee \
				body=outbound \
				method=UPDATE
			
```

用于发送 REFER 到被叫者,并添加 Refer-To 首部:

```c
			opensips-cli -x mi dialog:send_sequential \
				callid=usR8FlGOSMfCTAIHebHCOQ.. \
				method=REFER \
				body=none \
				mode=callee \
				headers='Refer-To: sip:user@domain:50060'
			
```

#### dialog:set_profile

替换已废弃的 MI 命令: *set_dlg_profile*。

将标识的对话(带可选值和清除旧分析值)通过对话 ID / Call-ID 设置到给定分析中。

名称: *dialog:set_profile*

参数: *它需要 2-4 个参数*

- *dlg_id* - 相应对话的对话 ID 或 Call-ID。
- *profile* - 要设置的分析名称。
- *value* - 可选,要设置的分析值。
- *clear_values* - 可选,在设置新值之前清除分析中的先前值。

MI FIFO 命令格式:

```c
		opensips-cli -x mi dialog:set_profile dlg_id=DID profile=my_profile value=my_value clear_values=1
		
```

#### dialog:unset_profile

替换已废弃的 MI 命令: *unset_dlg_profile*。

将标识的对话(带可选值)从给定分析中取消设置。

名称: *dialog:unset_profile*

参数: *它需要 2-3 个参数*

- *dlg_id* - 相应对话的对话 ID 或 Call-ID。
- *profile* - 要取消设置的分析名称。
- *value* - 可选,要取消设置的分析值。对于带值的分析,通过省略此参数,您现在可以清除给定分析的所有值。

MI FIFO 命令格式:

```c
		opensips-cli -x mi dialog:unset_profile dlg_id=DID profile=my_profile value=my_value
		
```

### 导出的伪变量

#### $DLG_count

返回当前活动对话的数量(可以是已确认或未确认)。

#### $DLG_status

返回与处理的顺序请求对应的对话状态。此 PV 仅在顺序请求中可用,在执行 loose_route() 之后。

值可能是:

- *NULL* - 未找到对话。
- *1* - 对话未确认(已创建但未收到任何回复)。
- *2* - 对话处于早期状态(已收到临时回复,但尚未收到最终回复)。
- *3* - 已通过最终回复确认但尚未收到 ACK。
- *4* - 已通过最终回复确认并收到 ACK。
- *5* - 对话已结束。

#### $DLG_lifetime

返回与处理的顺序请求对应的对话持续时间(秒)。持续时间从对话确认到当前时刻计算。此 PV 仅在顺序请求中可用,在执行 loose_route() 之后。

如果没有对话则返回 NULL。

#### $DLG_flags

以标志名称列表(以空格分隔)形式返回与处理的顺序请求对应的对话标志。此 PV 仅在顺序请求中可用,在执行 loose_route() 之后。

如果没有对话则返回 NULL。

#### $DLG_dir

以字符串形式返回请求在对话中的方向(如果请求由被叫者生成,则为"upstream",如果由呼叫者生成,则为"downstream") - 用于顺序请求。此 PV 仅在顺序请求中可用,在执行 loose_route() 之后。

如果没有对话则返回 NULL。

#### $DLG_did

返回与处理的顺序请求对应的对话 ID。输出格式与 dialog:list MI 函数返回的格式相同。此 PV 仅在顺序请求中可用,在执行 loose_route() 之后。

如果没有对话则返回 NULL。

#### $DLG_end_reason

返回对话终止的原因。它可以是以下之一:

- *Upstream BYE* - 被叫者发送了 BYE。
- *Downstream BYE* - 呼叫者发送了 BYE。
- *Lifetime Timeout* - 对话生命周期已过期。
- *MI Termination* - 对话通过 MI 接口终止。
- *Ping Timeout* - 对话因选项 ping 无回复而结束。
- *ReINVITE Ping Timeout* - 对话因重新邀请 ping 无回复而结束。
- *RTPProxy Timeout* - RTPProxy 信号的媒体超时。
- *SIP Race Condition* - 发生了 SIP Race Condition。

如果没有对话或对话未在当前上下文中结束,则返回 NULL。

#### $DLG_timeout

用于设置对话生命周期(秒)。读取时,变量返回对话过期并被销毁前的秒数。请注意,读取变量仅在对话创建后(对于初始请求)或执行 loose_route() 后(对于顺序请求)才可能。重要提示:在 REALTIME db_mode 下使用此变量非常低效,因为每次更改对话值时都会执行数据库更新。

如果没有对话则返回 NULL,否则返回距离对话过期的秒数。

#### $DLG_del_delay

用于设置当前对话的对话删除延迟(秒)(以每个呼叫的方式)。读取时,变量返回为呼叫设置的秒数,或者是默认值(请参阅 "delete_delay" - [删除延迟](#param_delete_delay))模块参数)用于删除延迟。

当对话上下文在脚本中可用时,必须使用此变量。

#### $DLG_json

该变量是只读的,暴露一个包含 dialog:list MI 函数包含的所有信息的 JSON 变量。

如果没有对话则返回 NULL,否则返回 JSON。

#### $DLG_ctx_json

该变量是只读的,暴露一个包含 dialog:list_ctx MI 函数包含的所有信息的 JSON 变量(在 $DLG_json 之上,这将暴露当前对话的所有对话 vars 和分析链接的完整列表)。

如果没有对话则返回 NULL,否则返回 JSON。

#### $dlg_val(name)

这是一个读/写变量,允许访问名为 *name* 的对话属性。它可以保存字符串或整数值。

请确保仅在拥有对话上下文时使用此变量(如在 create_dialog() 或 match_dialog() 之后或等效操作之后)。

变量接受动态名称,意味着名称可以包含其他变量。

如果没有对话则返回 NULL。

### 导出的事件

#### E_DLG_STATE_CHANGED

当对话状态改变时引发此事件。

参数:

- *id* - 对话 ID 的十六进制表示。
- *db_id* - 对话 ID 的整数表示,如其存储在数据库 *dlg_id* 字段中。
- *callid* - callid。
- *from_tag* - From tag。
- *to_tag* - To tag。
- *old_state* - 对话的旧状态。
- *new_state* - 对话的新状态。

## 开发者指南

### 可用函数

#### register_dlgcb (dialog, type, cb, param, free_param_cb)

向对话注册新回调。

参数含义如下:

- *struct dlg_cell* dlg* - 要注册回调的对话。如果可能为 NULL,则仅适用于 DLG_CREATED 回调类型,它不是每个对话类型。
- *int type* - 回调的类型;可以为同一回调函数注册多种类型;只有 DLG_CREATED 必须单独注册。可能的类型:
				
				*DLGCB_LOADED* - 当对话从数据库加载或使用
				集群复制接收到节点时调用。
				
				*DLGCB_SAVED*
				
				*DLG_CREATED* - 当新对话创建时调用 - 它是一个全局类型(不与任何对话关联)。
				
				*DLG_FAILED* - 当对话被否定回复(非 2xx)时调用 - 它是一个每个对话类型。
				
				*DLG_CONFIRMED* - 当对话被确认(2xx 回复)时调用 - 它是一个每个对话类型。
				
				*DLG_REQ_WITHIN* - 当对话匹配顺序请求时调用 - 它是一个每个对话类型。
				
				*DLG_TERMINATED* - 当对话通过 BYE 或 mi dlg_end_dlg 命令终止时调用 - 它是一个每个对话类型。
				
				*DLG_EXPIRED* - 当对话在未收到 BYE 的情况下过期时调用 - 它是一个每个对话类型。请注意,当使用复制共享标签时,此回调仅由拥有活动标签的节点执行。
				
				*DLGCB_EARLY* - 当对话在早期状态(18x 回复)中创建时调用 - 它是一个每个对话类型。
				
				*DLGCB_RESPONSE_FWDED* - 当对话匹配对初始 INVITE 请求的回复时调用 - 它是一个每个对话类型。
				
				*DLGCB_RESPONSE_WITHIN* - 当对话匹配对后续会话中请求的回复时调用 - 它是一个每个对话类型。
				
				*DLGCB_MI_CONTEXT* - 当调用 mi dlg_list_ctx 命令时调用 - 它是一个每个对话类型。
				
				*DLGCB_DESTROY*
- *dialog_cb cb* - 要调用的回调函数。原型是: "void (dialog_cb) 
			(struct dlg_cell* dlg, int type, struct dlg_cb_params * params);
			"。
- *void *param* - 要传递给回调函数的参数。
- *param_free callback_param_free* - 
			回调函数,用于释放参数。原型是: "void (param_free_cb) (void *param);"

## 常见问题

**Q: "topology_hiding()" 函数发生了什么?**

相应功能已移至 topology_hiding 模块。函数原型保持不变。

**Q: "use_tight_match" 参数发生了什么?**

该参数在 1.3 版本中移除,因为紧密匹配选项变得强制性和不可配置。现在,紧密匹配始终执行(当使用 DID 匹配时)。

**Q: "bye_on_timeout_flag" 参数发生了什么?**

该参数在 dialog 模块参数重组中移除。要保持超时时 bye 行为,您需要向 create_dialog() 函数提供"B"字符串参数。

**Q: "dlg_flag" 参数发生了什么?**

该参数已被视为过时。创建对话的唯一方法是调用 create_dialog() 函数。

**Q: 在哪里可以找到更多关于 OpenSIPS 的信息?**

请查看 [https://opensips.org/](https://opensips.org/)。

**Q: 在哪里可以发布关于此模块的问题?**

首先检查您的问题是否已在我们某个邮件列表中得到解答:

关于任何稳定 OpenSIPS 版本的电子邮件应发送到 users@lists.opensips.org,关于开发版本的电子邮件应发送到 devel@lists.opensips.org。

如果您想保持邮件私密,请发送至 users@lists.opensips.org。

**Q: 如何报告错误?**

请遵循以下指南:
[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。

### 许可证

所有文档文件(即 .md 扩展名)均采用知识共享 4.0 许可证授权。
