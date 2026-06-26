---
title: "usrloc 模块"
description: "SIP 用户位置实现。其主要目的是为其他模块(例如 registrar、mid-registrar、nathelper 等)存储、管理和提供 SIP 注册绑定(contact)的访问。该模块不导出可从 OpenSIPS 脚本直接使用的函数。"
---

## 管理指南

### 概述

SIP 用户位置实现。其主要目的是为其他模块(例如 registrar、mid-registrar、nathelper 等)存储、管理和提供 SIP 注册绑定(contact)的访问。该模块不导出可从 OpenSIPS 脚本直接使用的函数。

在运行时,contact 可以驻留在内存、SQL 数据库或 NoSQL 数据库中。也可以同时使用上述两种的组合。例如,contact 可能仅直接在内存中操作以保证快速交互,同时异步同步到 SQL 数据库。后者有助于实现重启持久性。有关模块所有可能的运行时行为的更多详细信息,请参阅 **[工作模式预设](#param_working_mode_preset)** 参数。

OpenSIPS 用户位置实现支持集群。除了支持传统的"单实例"设置外,它还允许多个 OpenSIPS 用户位置节点形成单一的全局用户位置集群。这允许高级功能,如从随机、健康的"供体"节点启动同步(数据隧道)和均匀分布的 NAT ping 工作负载。

### 分布式 SIP 用户位置

从 OpenSIPS 2.4 开始,用户位置模块提供了多种可选数据分发模型,每个模型针对特定的实际生产用例量身定制。这些模型建立在 OpenSIPS 集群模块之上,考虑了服务关注点,如 *高可用性、地理分布、水平可扩展性和 NAT 穿越*。

根据数据局部性,分发模型分为两大类:

#### "联邦"拓扑

*联邦* 用户位置将 contact 数据保留在原始 OpenSIPS 节点的本地,contact 最初注册到该节点。为了与全局 OpenSIPS 用户位置集群共享这些 contact 的可达性,registrar 节点仅为任何可从它们到达的地址记录发布一些轻量级"元数据"条目。这些条目将导致其他节点在收到对其广告地址记录的呼叫时,也派生指向发布 registrar 的额外 SIP 分支。

**联邦**拓扑是以下核心问题的优化解决方案:

- **IP 地址限制** - 在某些情况下,路由到注册 contact 的呼叫必须经过这些 contact 的原始注册节点。一个典型例子是,当 OpenSIPS registrar 位于平台边缘,直接面对 NAT 设备通往 contact 的路径时。除非从该确切的 registrar 发送呼叫,否则它们将无法穿越 NAT 设备并到达 contact。
- **水平可扩展性** - 避免集群内的全局复制/contact 广播不仅显著提高了 contact 存储性能,而且带来了更好的服务可扩展性。不同的地理位置可以根据其本地订阅用户群进行规模调整(例如,流量可以使用 DNS SRV 权重平衡到它们),而不会失去平台范围的可达性。

目前,元数据信息可以发布到支持键/多值列式关联的 NoSQL 数据库。已知支持这些抽象的后端示例在编写时包括 MongoDB 和 Cassandra。

[联邦用户位置教程](https://docs.opensips.org/tutorials-distributed-user-location-federation) 包含关于如何实现此设置的精确细节(包括高可用性支持)。

#### "完全共享"拓扑

*完全共享* 用户位置将 contact 信息广播到所有数据节点(OpenSIPS 或 NoSQL)。此模式的主要假设是任何路由限制都已事先消除。因此,或者SIP 流量从"完全共享"
OpenSIPS 用户位置拓扑发出时由我们平台的额外 SIP 边缘端点中介,或者根本没有出口 IP 限制(例如,如果所有 SIP UA 都有公共 IP)。在此设置中,所有 OpenSIPS 用户位置节点彼此*等价*,因为它们每个都可以访问相同的数据集且没有路由限制。

**完全共享**拓扑是多层 VoIP 平台的适当解决方案,其中 OpenSIPS registrar 节点不直接与外部 SIP 端点交互。此外,可以将其配置为完全在 NoSQL 集群内存储 contact 数据(零内存存储),从而充分利用专用分布式数据处理引擎的数据共享、分片、迁移和其他能力。

另外,"完全共享"拓扑可用于实现具有主动-被动 registrar 节点配置的基本"热备份"高可用性设置,两者都使用共享虚拟 IP。

注册可以选择性地由支持键/多值列式关联的 NoSQL 数据库完全管理。已知目前支持这些抽象的后端包括 MongoDB 和 Apache Cassandra。

["完全共享"用户位置教程](https://docs.opensips.org/tutorials-distributed-user-location-full-sharing) 包含关于如何实现此设置的精确细节(包括完整的 NoSQL 存储支持)。

#### "N Contact Pings"问题

由于 contact 信息通过复制直接复制到多个 SIP registrar 实例,或间接通过全局可达的数据库复制,由此产生的长期问题。只要传统集群化的节点彼此不了解,它们将各自扫描整个 contact 数据集,从而定期发送"N 个 ping"而不是每个 contact"1 个 ping"。这种差异直接影响服务可扩展性,以及 CPU 和网络带宽等消耗资源的数量,无论是在服务端还是客户端。

此问题通过 OpenSIPS 集群层解决,它使所有节点彼此了解。因此,分布式用户位置节点拓扑能够共同划分 ping 工作负载,并在任意给定时间点均匀地分布在当前集群节点数量上。[ping 模式](#param_pinging_mode) 模块参数更详细地描述了内置的 ping 启发式算法。

### Contact 匹配

Contact 匹配(针对同一地址记录 AoR)是 SIP 用户位置服务的重要方面,特别是在 NAT 穿越上下文中。后者引发了更多问题,因为来自同一用户不同电话的 contact 可能会重叠(如果具有相同的 NAT 配置),或者同一 SIP 用户代理的重新注册 Contact 可能会被视为新的(由于请求通过新的 NAT 绑定到达)。

SIP RFC 3261 发布了一种匹配算法,该算法仅基于 contact 字符串,并进行 Call-ID 和 CSeq 号码额外检查(如果 Call-ID 匹配,它必须有更高的 CSeq 号码,否则注册无效)。但如上所述,在 NAT 穿越上下文中这还不够,因此 OpenSIPS 的 contact 匹配实现提供了更多算法:

- *仅基于 Contact* - 严格遵循 RFC 3261
		- contact 作为字符串匹配,并通过 Call-ID 和 CSeq 进行额外检查(如果 Call-ID 相同,它必须有更高的 CSeq 号码,否则注册无效)。
- *基于 Contact 和 Call-ID* - 第一种情况的扩展
		- Contact 和 Call-ID 首部字段值必须作为字符串匹配;CSeq 必须高于前一个 - 因此在这种情况下请小心处理 REGISTER 重传。

有关如何控制/选择 contact 匹配算法的更多详细信息,请转到 **[匹配模式](#param_matching_mode)**。

### 依赖

#### OpenSIPS 模块

以下模块必须在此模块之前加载:

- *可选的 SQL 数据库模块*。
- *可选的 NoSQL 数据库模块*。
- *clusterer,如果 [集群模式](#param_cluster_mode) 与"none"不同*。

#### 外部库或应用程序

运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序:

- *无*。

### 导出的参数

#### nat_bflag (字符串)

用作 NAT 标记的分支标志名称(如果 contact 是或不是 natted)。这是一个分支标志,所有其他依赖 usrloc 模块的模块都会导入和使用它。

*默认值为 NULL(未设置)。*

```c title="设置 nat_bflag 参数"
...
modparam("usrloc", "nat_bflag", "NAT_BFLAG")
...
```

#### contact_id_column (字符串)

保存唯一 contact ID 的列名。

*默认值为"contact_id"。*

```c title="设置 contact_id_column 参数"
...
modparam("usrloc", "contact_id_column", "ctid")
...
```

#### user_column (字符串)

包含用户名的列名。

*默认值为"username"。*

```c title="设置 user_column 参数"
...
modparam("usrloc", "user_column", "username")
...
```

#### domain_column (字符串)

包含域的列名。

*默认值为"domain"。*

```c title="设置 user_column 参数"
...
modparam("usrloc", "domain_column", "domain")
...
```

#### contact_column (字符串)

包含 contact 的列名。

*默认值为"contact"。*

```c title="设置 contact_column 参数"
...
modparam("usrloc", "contact_column", "contact")
...
```

#### expires_column (字符串)

包含过期值的列名。

*默认值为"expires"。*

```c title="设置 expires_column 参数"
...
modparam("usrloc", "expires_column", "expires")
...
```

#### q_column (字符串)

包含 q 值的列名。

*默认值为"q"。*

```c title="设置 q_column 参数"
...
modparam("usrloc", "q_column", "q")
...
```

#### callid_column (字符串)

包含 callid 值的列名。

*默认值为"callid"。*

```c title="设置 callid_column 参数"
...
modparam("usrloc", "callid_column", "callid")
...
```

#### cseq_column (字符串)

包含 cseq 号码的列名。

*默认值为"cseq"。*

```c title="设置 cseq_column 参数"
...
modparam("usrloc", "cseq_column", "cseq")
...
```

#### methods_column (字符串)

包含支持方法的列名。

*默认值为"methods"。*

```c title="设置 methods_column 参数"
...
modparam("usrloc", "methods_column", "methods")
...
```

#### flags_column (字符串)

保存记录内部标志的列名。

*默认值为"flags"。*

```c title="设置 flags_column 参数"
...
modparam("usrloc", "flags_column", "flags")
...
```

#### cflags_column (字符串)

保存记录的分支/contact 标志的列名。

*默认值为"cflags"。*

```c title="设置 cflags_column 参数"
...
modparam("usrloc", "cflags_column", "cflags")
...
```

#### user_agent_column (字符串)

包含 user-agent 值的列名。

*默认值为"user_agent"。*

```c title="设置 user_agent_column 参数"
...
modparam("usrloc", "user_agent_column", "user_agent")
...
```

#### received_column (字符串)

包含来自 REGISTER 消息的源 IP、端口和协议的列名。

*默认值为"received"。*

```c title="设置 received_column 参数"
...
modparam("usrloc", "received_column", "received")
...
```

#### socket_column (字符串)

包含 REGISTER 消息的收到套接字信息(IP:port)的列名。

*默认值为"socket"。*

```c title="设置 socket_column 参数"
...
modparam("usrloc", "socket_column", "socket")
...
```

#### path_column (字符串)

包含 Path 首部的列名。

*默认值为"path"。*

```c title="设置 path_column 参数"
...
modparam("usrloc", "path_column", "path")
...
```

#### sip_instance_column (字符串)

包含 SIP 实例的列名。

*默认值为"NULL"。*

```c title="设置 sip_instance_column 参数"
...
modparam("usrloc", "sip_instance_column", "sip_instance")
...
```

#### kv_store_column (字符串)

包含通用键值数据的列名。

*默认值为"kv_store"。*

```c title="设置 kv_store_column 参数"
...
modparam("usrloc", "kv_store_column", "json_data")
...
```

#### attr_column (字符串)

包含与注册相关的附加信息的列名。

*默认值为"attr"。*

```c title="设置 attr_column 参数"
...
modparam("usrloc", "attr_column", "attributes")
...
```

#### use_domain (布尔值)

表示是否也应保存和使用用户 *domain* 部分以及 *username* 部分来识别用户。多域场景中有用。

*默认值为 *true*(启用)。*

```c title="设置 use_domain 参数"
...
modparam("usrloc", "use_domain", true)
...
```

#### desc_time_order (整数)

是否应按时间戳保持用户的 contact 顺序;否则 contact 将基于 q 值排序。非 0 值表示 true。

*默认值为"0 (false)"。*

```c title="设置 desc_time_order 参数"
...
modparam("usrloc", "desc_time_order", 1)
...
```

#### timer_interval (整数)

两次定时器运行之间的秒数。在每次运行期间,模块将从内存中更新/删除脏/过期 contact,并且如果配置了,会将这些操作镜像到数据库。

> [!WARNING]
> 如果 OpenSIPS 关闭甚至崩溃,仅在内存中且尚未刷新到磁盘的 contact 不会丢失!OpenSIPS 将在关闭前尽最大努力执行最后一次 DB 同步。

*默认值为 60。*

```c title="设置 timer_interval 参数"
...
modparam("usrloc", "timer_interval", 120)
...
```

#### db_url (字符串)

应该使用的数据库的 URL。

*默认值为"mysql://opensips:opensipsrw@localhost/opensips"。*

```c title="设置 db_url 参数"
...
modparam("usrloc", "db_url", "dbdriver://username:password@dbhost/dbname")
...
```

#### cachedb_url (字符串)

要使用的 NoSQL 数据库的 URL。仅在启用缓存的 **[集群模式](#param_cluster_mode)** 中需要。

*默认值为"none"。*

```c title="设置 cachedb_url 参数"
...
modparam("usrloc", "cachedb_url", "mongodb://10.0.0.4:27017/opensipsDB.userlocation")
...
```

#### working_mode_preset (字符串)

usrloc 模块的预定义工作模式。设置此参数将覆盖任何 [集群模式](#param_cluster_mode)、[重启持久性](#param_restart_persistency) 和 [sql 写入模式](#param_sql_write_mode) 设置。

- **"single-instance-no-db"** - 这完全禁用数据库。只使用内存。Contact 不会在重启后存活。如果您需要真正快速的 usrloc 并且 contact 持久性不必要或由其他方式提供,请使用此值。
- **"single-instance-sql-write-through"**
			- 写透方案。对 usrloc 的所有更改也会立即反映到数据库中。这非常慢,但非常可靠。如果您不将速度作为优先考虑但需要确保在崩溃或重启期间不会丢失任何已注册的 contact,请使用此方案。
- **"single-instance-sql-write-back"**
			- 写回方案。这是前两种方案的组合。所有更改都写入内存,数据库同步在定时器中完成。定时器删除所有过期的 contact,并将所有已修改或新的 contact 刷新到数据库。如果您遇到高负载峰值并希望尽快处理,请使用此方案。如果负载一直很高,此模式根本没有帮助。使用此异步预设的 SIP 信令延迟比使用安全但阻塞的"single-instance-sql-write-through"预设要低得多。
- **"sql-only"** -
			仅数据库方案。不保留内存缓存,所有操作都直接对数据库执行。定时器从数据库中删除所有过期的 contact - 清理未注销或重新注册的客户端。此模式在配置多台服务器共享相同 DB 而无需任何 SIP 级别复制的场景中很有用。该模式可能由于大量 DB 操作而变慢。例如,NAT ping 是杀手,因为在每个 ping 周期内所有带 nat 的 contact 都从 DB 加载;缺乏内存缓存也会禁用统计信息导出。
- **"federation-cachedb-cluster"** -
			OpenSIPS 将以"federation-cachedb" [集群模式](#param_cluster_mode) 和"sync-from-cluster" [重启持久性](#param_restart_persistency) 运行。这将需要在集群中配置多个"种子"节点。请参阅 [联邦用户位置教程](https://docs.opensips.org/tutorials-distributed-user-location-federation) 获取更多详细信息。
- **"full-sharing-cluster"** -
			OpenSIPS 将以"full-sharing" [集群模式](#param_cluster_mode) 和"sync-from-cluster" [重启持久性](#param_restart_persistency) 运行。这将需要将集群中的一个节点配置为"种子"节点,以引导同步过程。
- **"full-sharing-cachedb-cluster"** -
			OpenSIPS 将以"full-sharing-cachedb" [集群模式](#param_cluster_mode) 运行,其中所有位置数据严格驻留在 NoSQL 数据库中,因此它具有自然的重启持久性。

请参阅 [分布式 sip 用户位置](#distributed_sip_user_location) 部分获取关于集群拓扑及其行为的详细信息。

*默认值为"single-instance-no-db"。*

```c title="设置 working_mode_preset 参数"
...
modparam("usrloc", "working_mode_preset", "full-sharing-cachedb-cluster")
...
```

#### cluster_mode (字符串)

**如果设置了 [工作模式预设](#param_working_mode_preset) 或 [db 模式](#param_db_mode),此参数将被覆盖。**

全局 OpenSIPS 用户位置集群的行为。请参阅 [分布式 sip 用户位置](#distributed_sip_user_location) 部分获取详细信息。

此参数可以采用以下值:

- *"none"* - 单实例模式。
- *"federation-cachedb"* -
				基于联邦的数据共享。局部 AoR 元数据发布在 NoSQL 数据库中,以便其他集群节点可以将 SIP 流量分叉到当前节点。因此,[位置集群](#param_location_cluster) 和 [cachedb url](#param_cachedb_url) 参数是必需的。
- *"full-sharing"* -
				向所有其他 OpenSIPS 集群参与者广播 contact 更新(全网状镜像)。每个节点将保存整个用户位置数据集。因此,[位置集群](#param_location_cluster) 参数是必需的。
- *"full-sharing-cachedb"* -
				通过使用 NoSQL 数据库进行完整 contact 数据管理(有些类似于"sql-only"预设)。集群层仍然需要,以便能够均匀地划分和分配 ping 工作负载到参与的 OpenSIPS 节点。因此,[位置集群](#param_location_cluster) 和 [cachedb url](#param_cachedb_url) 参数是必需的。
- *"sql-only"* -
				使用公共 [db url](#param_db_url) 的多个 OpenSIPS 盒子,不必彼此了解。

*默认值为 *"none" (单实例模式)*。*

```c title="设置 cluster_mode 参数"
...
modparam("usrloc", "cluster_mode", "federation-cachedb")
...
```

#### restart_persistency (字符串)

**如果设置了 [工作模式预设](#param_working_mode_preset) 或 [db 模式](#param_db_mode),此参数将被覆盖。**

控制 OpenSIPS 用户位置在重启后的行为。此参数在某些仅数据库工作模式预设中无效,因为重启持久性是自然保证的。

此参数可以采用以下值:

- *"none"* - 重启后没有明确的数据
				同步。节点以空状态启动。
- *"load-from-sql"* - 启用
				基于 SQL 的重启持久性。这会导致所有运行时内存写入(即新注册、重新注册或注销)也传播到 SQL 数据库,重启后将从中导入所有数据。选择此值将使 [db url](#param_db_url) 参数成为必需,同时也会使 [sql 写入模式](#param_sql_write_mode) 默认为"write-back"而不是"none"。
- *"sync-from-cluster"* - 启用
				基于集群的重启持久性。重启后,OpenSIPS 集群节点将搜索健康的"供体"节点,通过直接集群同步(基于 TCP 的二进制编码数据传输)从中镜像整个用户位置数据集。根据集群模式和集群拓扑,这将需要在集群中配置一个或多个"种子"节点。选择此值将使 [位置集群](#param_location_cluster) 参数成为必需。

*默认值为
			*"none" (无重启持久性)*。*

```c title="设置 restart_persistency 参数"
...
modparam("usrloc", "restart_persistency", "sync-from-cluster")
...
```

#### sql_write_mode (字符串)

**如果设置了 [工作模式预设](#param_working_mode_preset) 或 [db 模式](#param_db_mode),此参数将被覆盖。**

仅在 [重启持久性](#param_restart_persistency) 启用时有效。控制 OpenSIPS 对 SQL 数据库的运行时写入行为。

此参数可以采用以下值:

- *"none"* - 不执行任何
				额外的运行时 SQL 写入到 SQL 数据库以专门确保重启持久性。
- *"write-through"* - 所有内存
				写入(即新注册、重新注册或注销)也会同步内联到 SQL 数据库。虽然这肯定会减慢注册性能(查询从内存提供!),但它具有使实例崩溃安全的优点。
- *"write-back"* - 所有内存
				写入(即新注册、重新注册或注销)最终也会通过单独的定时器例程传播到 SQL 数据库。这大大加快了注册速度,但也引入了在最新 contact 更改传播到数据库之前崩溃的可能性。请参阅 [定时器间隔](#param_timer_interval) 获取其他配置。

*默认值为 *"none" (无额外 SQL 写入)*。*

```c title="设置 sql_write_mode 参数"
...
modparam("usrloc", "sql_write_mode", "write-back")
...
```

#### matching_mode (整数)

要使用的 contact 匹配算法。请参阅 [contact 匹配](#contact_matching) 部分获取算法的描述。

该参数可以采用以下值:

- *0* - 仅基于 CONTACT 的匹配
				算法。
- *1* - 基于 CONTACT 和 CALLID 的
				匹配算法。

*默认值为 *0 (CONTACT_ONLY)*。*

```c title="设置 matching_mode 参数"
...
modparam("usrloc", "matching_mode", 1)
...
```

#### cseq_delay (整数)

接受具有相同 Call-ID 和 Cseq 的注册请求重传的延迟(秒)。延迟从收到具有该 Call-ID 和 Cseq 的第一个注册开始计算。

在此延迟间隔内的重传将被接受并作为原始请求回复,但不会在位置中进行更新。如果超过延迟,则报告错误。

值为 0 会禁用重传检测。

*默认值为"20 秒"。*

```c title="设置 cseq_delay 参数"
...
modparam("usrloc", "cseq_delay", 5)
...
```

#### location_cluster (整数)

指定此实例将向其发送并从中接收所有用户位置相关信息
		(*address-of-record*、*contacts*)
		的集群 ID,组织成特定事件(插入、删除或更新)。

此 OpenSIPS 集群公开 **"usrloc-contact-repl"**
能力,以将节点标记为在任意同步请求期间有资格成为数据供体。因此,集群必须至少有一个节点标记为 **"seed"** 值作为 *clusterer.flags* 列/属性才能完全正常运行。
请参阅 [clusterer - 能力](../clusterer#capabilities) 章节获取更多详细信息。

默认值为 0(禁用复制)。

用户位置分发机制的更多详细信息可在 [分布式 sip 用户位置](#distributed_sip_user_location) 下获取。

```c title="设置 location_cluster 参数"
...
modparam("usrloc", "location_cluster", 1)
...
```

#### ha_cluster (整数)

仅与 **"federation-cachedb"** [集群模式](#param_cluster_mode) 相关。表示要使用的 HA 集群 ID,以建立 HA 对中的活动节点,使得只有该节点执行对 CacheDB 的写入操作。

默认值为 0(禁用)。

```c title="设置 ha_cluster 参数"
...
modparam("usrloc", "ha_cluster", 4)
...
```

#### ha_shtag (字符串)

仅与 **"federation-cachedb"** [集群模式](#param_cluster_mode) 相关。表示要使用的 HA 集群共享标签,以建立 HA 对中的活动节点,使得只有该节点执行对 CacheDB 的写入操作。

默认值为 NULL(禁用)。

```c title="设置 ha_shtag 参数"
...
modparam("usrloc", "ha_shtag", "vip2")
...
```

#### skip_replicated_db_ops (整数)

防止 OpenSIPS 在通过 *二进制接口* 接收事件时执行任何与数据库相关的 contact 操作。这通常用于防止不必要的重复操作。

默认值为"0"(在接收 usrloc 相关二进制接口事件时,可以自由执行数据库查询)

用户位置复制机制的更多详细信息可在 [分布式 sip 用户位置](#distributed_sip_user_location) 中获取。

```c title="设置 skip_replicated_db_ops 参数"
...
modparam("usrloc", "skip_replicated_db_ops", 1)
...
```

#### max_contact_delete (整数)

仅在 WRITE_THROUGH 或 WRITE_BACK 方案中相关。一次从数据库删除的最大 contact 数量。如果遍历所有 contact 后数量较少,将全部删除。

默认值为"10"

```c title="设置 max_contact_delete 参数"
...
modparam("usrloc", "max_contact_delete", 10)
...
```

#### hash_size (整数)

usrloc 用于存储位置记录的哈希表的条目数为 2^hash_size。对于 hash_size=4,哈希表的条目数为 16。从版本 2.2 开始,此参数的最大大小为 16,意味着哈希表最大支持 65536 个条目。

*默认值为"9"。*

```c title="设置 hash_size 参数"
...
modparam("usrloc", "hash_size", 10)
...
```

#### regen_broken_contactid (整数)

从版本 2.2 开始,**contact_id** 概念被引入。由于此参数在每次 OpenSIPS 启动时验证 contact,因此有时应该重新生成此参数的值。这是在 **location** 表从旧于 2.2 的版本迁移时,或者更改了 **hash_size** 模块参数时。启用此参数将根据当前配置重新生成损坏的 contact id。

*默认值为"0(未启用)"*

```c title="设置 regen_broken_contactid 参数"
...
modparam("usrloc", "regen_broken_contactid", 1)
...
```

#### latency_event_min_us (整数)

定义最小 ping 延迟阈值(以微秒为单位),超过该阈值后将引发 contact ping 延迟更新事件。默认情况下,每次 ping 回复都会引发一个事件(即延迟更新)。

如果同时设置了 [latency event min us](#param_latency_event_min_us) 和 [latency event min us delta](#param_latency_event_min_us_delta),则当其中任一为真时都会引发事件。

*默认值为"0(未设置下限)"。*

```c title="设置 latency_event_min_us 参数"
...
# 为任何 425+ 毫秒的 ping 延迟引发事件
modparam("usrloc", "latency_event_min_us", 425000)
...
```

#### latency_event_min_us_delta (整数)

定义最小绝对 ping 延迟差值(以微秒为单位),超过该差值后将引发 contact ping 延迟更新事件。该差值使用最后两次 contact ping 回复的延迟计算。默认情况下,每次 ping 回复都会引发一个事件(即延迟更新)。

如果同时设置了 [latency event min us](#param_latency_event_min_us) 和 [latency event min us delta](#param_latency_event_min_us_delta),则当其中任一为真时都会引发事件。

*默认值为"0(未设置最小延迟差)"。*

```c title="设置 latency_event_min_us_delta 参数"
...
# 仅在 contact 的 ping 延迟波动为 300+ 毫秒时引发事件
modparam("usrloc", "latency_event_min_us_delta", 300000)
...
```

#### pinging_mode (字符串)

根据 [集群模式](#param_cluster_mode),模块可以使用两种可能的启发式算法之一执行 contact ping:

- **"ownership"** - 此实例
				仅在确定自己是 contact 的逻辑所有者时才尝试 ping contact。如果 contact 附加了共享标签,只要节点拥有相应标签,它就会继续向该 contact 发送 ping。如果未为给定 contact 指定共享标签,默认假定永久拥有该 contact 并在请求时 ping 它。
- **"cooperation"** - 此
				ping 启发式算法背后的假设是,所有用户位置集群节点是对称的(可能由 SIP 流量平衡实体前端),
				使得 **任意** 节点都可以 ping
				**任意** contact。
				在此假设下,所有当前在线的用户位置集群节点将合作并通过将 AoR 哈希到当前在线节点数量来均匀分担 ping 工作负载,仅选择它们负责的节点。

**根据当前"cluster_mode","pinging_mode"的可能值**

|  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- |
| [集群模式](#param_cluster_mode) | none | federation-cachedb | full-sharing | full-sharing-cachedb | sql-only |
| [pinging 模式](#param_pinging_mode) | **ownership** | **ownership** | **cooperation** / ownership | **cooperation** | *未维护* |

请注意,只有 **"full-sharing"** 集群模式允许一些灵活性 -- 所有其他模式在逻辑上绑定到单一 ping 逻辑。任何不符合上表的不可接受的值,将静默丢弃。

```c title="设置 pinging_mode 参数"
...
# 准备一个主动/备份"full-sharing"设置,无前端
modparam("usrloc", "pinging_mode", "ownership")
...
```

#### mi_dump_kv_store (整数)

启用是为了在所有输出 AoR 或 Contact 表示的 usrloc MI 命令中包含"KV-Store"字段。此详细字段包含附加到这两个实体的自定义数据。例如,mid_registrar 使用这两个 holder。

*默认值为"0(禁用)"。*

```c title="设置 mi_dump_kv_store 参数"
...
# 在所有 usrloc MI 输出中包含"KV-Store"键
modparam("usrloc", "mi_dump_kv_store", 1)
...
```

#### contact_refresh_timer (布尔值)

启用一个定时器,该定时器将定期扫描排序的 contact 列表,并为其中任何超过重新注册时间间隔限制的 contact 引发 [E_UL_CONTACT_REFRESH](#event_e_ul_contact_refresh)。此限制可能由 registrar 的 *pn_trigger_interval* 模块参数给出,例如。

*默认值为"false(禁用)"。*

```c title="设置 contact_refresh_timer 参数"
...
modparam("usrloc", "contact_refresh_timer", true)
...
```

### 导出的函数

#### ul_add_key(domain, aor, key_name, [key_value])

向 Usrloc 记录的键值存储追加键/值。

如果在 usrloc 中未找到记录,则返回 false。

参数含义如下:

- *domain (字符串)* - AOR 的域,例如"location"
- *aor (字符串)* - 地址记录,
				为其保存键的特定(已注册)用户。
- *key (字符串)* - 要存储的键的名称。
- *value (字符串,可选)*
			        - 要存储的值。不提供值或提供空值将删除条目。

此函数可在任何路由中使用。

```c title="ul_add_key 使用示例"
...
ul_add_key("location", "$tU@$td", "service_route", "$hdr(Service-Route)");
...
```

#### ul_get_key(domain, aor, key_name, destination)

从 Usrloc 记录的键值存储中检索键/值。

如果在 usrloc 中未找到记录或未找到相应键,则返回 false。

参数含义如下:

- *domain (字符串)* - AOR 的域,例如"location"
- *aor (字符串)* - 地址记录,
				为其保存键的特定(已注册)用户。
- *key (字符串)* - 要检索的键的名称。
- *destination (变量)*
			        - 存储检索到的键的变量。

此函数可在任何路由中使用。

```c title="ul_get_key 使用示例"
...
if (ul_get_key("location", "$tU@$td", "service_route", $avp(service_route))) {
        append_to_reply("Service-Route: $avp(service_route)\r\n");
}
...
```

#### ul_del_key(domain, aor, key_name)

从 Usrloc 记录的键值存储中删除键/值。

如果在 usrloc 中未找到记录,则返回 false。

参数含义如下:

- *domain (字符串)* - AOR 的域,例如"location"
- *aor (字符串)* - 地址记录,
				为其保存键的特定(已注册)用户。
- *key (字符串)* - 要删除的键的名称。

此函数可在任何路由中使用。

```c title="ul_del_key 使用示例"
...
ul_del_key("location", "$tU@$td", "service_route");
...
```

### 导出的 MI 函数

#### usrloc:rm

替换已废弃的 MI 命令: *ul_rm*。

删除整个 AOR 记录(包括其 contacts)。

参数:

- *table_name* - 要从中删除 AOR 的表(例如:location)。
- *aor* - 用户 AOR,格式为 username[@domain]
	(仅当 use_domain 选项开启时必须提供 domain)。

#### usrloc:rm_contact

替换已废弃的 MI 命令: *ul_rm_contact*。

从 AOR 记录中删除 contact。

参数:

- *table name* - 要从中删除 AOR 的表(例如:location)。
- *AOR* - 用户 AOR,格式为 username[@domain]
	(仅当 use_domain 选项开启时必须提供 domain)。
- *contact* - 要删除的精确 contact。

#### usrloc:dump

替换已废弃的 MI 命令: *ul_dump*。

转储 USRLOC 内存缓存中的全部内容。

参数:

- *brief* - (可选,可以不存在);如果等于字符串"brief",将执行简要转储(仅 AOR 和 contact,无其他详细信息)。

#### usrloc:flush

替换已废弃的 MI 命令: *ul_flush*。

强制将所有待处理的 usrloc 缓存更改刷新到数据库。
		通常,此例程每 [timer interval](#param_timer_interval) 秒运行一次。

#### usrloc:add

替换已废弃的 MI 命令: *ul_add*。

为用户 AOR 添加新 contact。

参数:

- *table name (字符串)* - 将添加 contact 的表(例如:"location")。
- *aor (字符串)* - 用户 AOR,格式为 username[@domain]
	(仅当 use_domain 选项开启时必须提供 domain)。
- *contact (字符串)* - 要添加的 Contact URI。
- *expires (整数)* - contact 的过期值。
- *q (字符串)* - contact 的 Q 值。
- *flags (整数)* - contact 的内部 USRLOC 标志。
- *cflags (整数)* - contact 的每分支标志。
- *methods (整数)* - contact 支持的请求的位掩码。要将所有 SIP 方法列入白名单,只需使用值 **32767**。有关每个方法的值分解,请参见"request_method"内部枚举。

#### usrloc:show_contact

替换已废弃的 MI 命令: *ul_show_contact*。

转储用户 AOR 的 contacts。

参数:

- *table_name* - AOR 所在的表(例如:location)。
- *aor* - 用户 AOR,格式为 username[@domain]
	(仅当 use_domain 选项开启时必须提供 domain)。

#### usrloc:sync

替换已废弃的 MI 命令: *ul_sync*。

清空位置表,然后用内存中的所有 contact 将其同步。
		请注意,在未指定数据库或使用仅数据库方案时不能使用此命令。

重要:在执行此命令之前,请确保您的所有 contact 都在内存中
		(*usrloc:dump* MI 函数)。

参数:

- *table name* - AOR 所在的表(例如:location)。
- *AOR (可选)* - 仅删除/同步此用户 AOR,而不是整个表。格式:"username[@domain]"
	(*domain* 仅在 [use domain](#param_use_domain) 选项开启时需要)。

#### usrloc:cluster_sync

替换已废弃的 MI 命令: *ul_cluster_sync*。

此命令仅在目标 OpenSIPS 实例与热备份实例配对且在启用集群的 [工作模式预设](#param_working_mode_preset) 下运行时才会生效。

当前节点将在 [位置集群](#param_location_cluster) 中定位一个健康的供体节点,并向其发出同步请求。供体节点将通过二进制接口将所有用户位置数据推送到当前节点。收到的数据将与现有数据合并。冲突的 contact(根据 [匹配模式](#param_matching_mode) 匹配)仅在同步数据比当前数据更新时才被覆盖。

### 导出的统计信息

导出的统计信息在下一节中列出。

#### users

USRLOC 内存缓存中该域存在的 AOR 数量
			- 不能重置;此统计信息将为每个使用的域注册(例如:location)。

#### contacts

USRLOC 内存缓存中该域存在的 contact 数量 - 不能重置;此统计信息将为每个使用的域注册(例如:location)。

#### expires

该域的过期 contact 总数 - 可以重置;
			此统计信息将为每个使用的域注册(例如:location)。

#### registered_users

所有域的 USRLOC 内存缓存中存在的 AOR 总数 - 不能重置。

### 导出的事件

#### E_UL_AOR_INSERT

当新 AOR 被插入 USRLOC 内存缓存时引发此事件。

参数:

- *domain* - 表的名称。
- *aor* - 插入记录的 AOR。

#### E_UL_AOR_DELETE

当新 AOR 从 USRLOC 内存缓存中删除时引发此事件。

参数:

- *domain* - 表的名称。
- *aor* - 删除记录的 AOR。

#### E_UL_CONTACT_INSERT

当新 contact 插入现有 AOR 的 contact 列表时引发此事件。对于每个新 contact,如果其 AOR 不存在于内存中,则会同时引发 E_UL_AOR_CREATE 和 E_UL_CONTACT_INSERT 事件。

参数:

- *domain* - 表的名称。
- *aor* - 插入 contact 的 AOR。
- *uri* - 插入 contact 的 Contact URI。
- *received* - 收到注册消息的 IP、端口和协议。如果这些值与 contact 的地址相同(见 address 参数),则 received 参数将为空字符串。
- *path* - 注册消息的 PATH 首部值(如果不存在则为空字符串)。
- *qval* - contact 的 Q 值(优先级)(0 到 10 的整数值)。
- *user_agent* - User-Agent 首部值。
*注意:*可以包含空格。
- *socket* - OpenSIPS 用于接收 contact 注册的 SIP 套接字/监听器(作为字符串)。
- *bflags* - contact 的分支标志(bflags)(整数位掩码值)。
- *expires* - contact 的过期值(UNIX 时间戳整数)。
- *callid* - 注册消息的 Call-ID 首部。
- *cseq* - cseq 号码作为整数值。
- *attr* - 附加到 contact 的属性字符串(从脚本级别附加的自定义属性)。由于此字符串是可选的,如果 contact 中缺少,事件将为此字段推送空字符串。
- *latency* - 上一次成功 ping 此 contact 的延迟,以微秒为单位。在给定 contact 的第一次 ping 回复到达之前,其 ping 延迟将为 0。
- *shtag* - contact 的共享标签,
			有助于确定当前节点是否拥有该 contact
			(例如,可能使用 **$cluster.sh_tag** 伪变量来执行检查)。
*注意:*如果 contact 没有附加共享标签,则此参数的值将为""(空字符串)!

#### E_UL_CONTACT_DELETE

当 contact 从现有 AOR 的 contact 列表中删除时引发此事件。如果 contact 是列表中唯一的一个,则会同时引发 E_UL_AOR_DELETE 和 E_UL_CONTACT_DELETE 事件。

参数: 与 [E_UL_CONTACT_INSERT](#event_e_ul_contact_insert) 事件相同。

#### E_UL_CONTACT_UPDATE

当通过收到另一条注册消息更新 contact 信息时引发此事件。

参数: 与 [E_UL_CONTACT_INSERT](#event_e_ul_contact_insert) 事件相同。

#### E_UL_CONTACT_REFRESH

此事件可能仅为 RFC 8599(推送通知)启用的 contact 引发。

将 [contact refresh timer](#param_contact_refresh_timer) 设置为 *true* 以启用此事件。该事件在 RFC 8599 启用的 contact 即将过期前的合理时间内引发,以便脚本编写者可以采取行动,可能强制端点进行注册刷新。

参数:

- *domain* - 表的名称。
- *aor* - 插入 contact 的 AOR。
- *uri* - 插入 contact 的 Contact URI。
- *received* - 收到注册消息的 IP、端口和协议。如果这些值与 contact 的地址相同(见 address 参数),则 received 参数将为空字符串。
- *user_agent* - User-Agent 首部值。
*注意:*可以包含空格。
- *socket* - OpenSIPS 用于接收 contact 注册的 SIP 套接字/监听器(作为字符串)。
- *bflags* - contact 的分支标志(bflags)(整数位掩码值)。
- *expires* - contact 的过期值(UNIX 时间戳整数)。
- *callid* - 注册消息的 Call-ID 首部。
- *attr* - 附加到 contact 的属性字符串(从脚本级别附加的自定义属性)。由于此字符串是可选的,如果 contact 中缺少,事件将为此字段推送空字符串。
- *shtag* - contact 的共享标签,
			有助于确定当前节点是否拥有该 contact
			(例如,可能使用 **$cluster.sh_tag** 伪变量来执行检查)。
- *reason* - 触发绑定刷新事件的原因。可能的值:
				
				"reg-refresh" - 由 OpenSIPS 触发的定期刷新
				
				"ini-INVITE"、"ini-SUBSCRIBE" 等 - 由传入的初始 SIP 请求触发的刷新
				
				"mid-INVITE"、"mid-BYE" 等 - 由传入的会话中 SIP 请求触发的刷新
- *req_callid* - 触发此事件的 SIP 请求的 Call-ID(如果有的话)。这提供了将待处理请求与当前事件逻辑关联起来的能力,并可从该请求访问有用数据(例如,呼叫者身份、拨打的号码等)。
使用 *req_callid*,如果为待处理请求创建了对话,则可以使用 dialog 模块的 [load_dialog_ctx()](../dialog#func_load_dialog_ctx) 和 [unload_dialog_ctx()](../dialog#func_unload_dialog_ctx) 函数将此对话临时加载到 event_route 中。

#### E_UL_LATENCY_UPDATE

当 contact ping 延迟匹配 [latency event min us](#param_latency_event_min_us) 或 [latency event min us delta](#param_latency_event_min_us_delta) 过滤器时引发此事件。如果未设置这些过滤器,则每次成功的 contact ping 操作都会引发此事件。

参数: 与 [E_UL_CONTACT_INSERT](#event_e_ul_contact_insert) 事件相同。

## 开发者指南

### 可用函数

#### ul_register_domain(name)

该函数注册一个新域。域只是 registrar 中使用的表的另一个名称。该函数从 fixups 在 registrar 中调用。它获取域名作为参数并返回指向新域结构的指针。然后 fixup"修复"registrar 中的参数,以便每次调用 save() 或 lookup() 时传递指针而不是名称。某些 usrloc 函数在调用时获取指针作为参数。有关更多详细信息,请参阅 registrar 中 save 函数的实现。

参数含义如下:

- *const char* name* - 要注册的域(也称为表)的名称。

#### ul_insert_urecord(domain, aor, rec, is_replicated)

该函数创建一个新记录结构并将其插入指定域。记录是包含属于指定用户名的所有 contact 的结构。

参数含义如下:

- *udomain_t* domain* - 指向由 ul_register_udomain 返回的域的指针。
- *str* aor* - 新记录的地址记录(又名用户名)(此时记录还不包含任何 contact)。
- *urecord_t** rec* - 新创建记录结构。
- *char is_replicated* - 指定此函数是否将从二进制接口回调的上下文中调用。如果不确定,只需使用 0。

#### ul_delete_urecord(domain, aor, is_replicated)

该函数删除与给定地址记录绑定的所有 contact。

参数含义如下:

- *udomain_t* domain* - 指向由 ul_register_udomain 返回的域的指针。
- *str* aor* - 要删除的记录的地址记录(又名用户名)。
- *char is_replicated* - 指定此函数是否将从二进制接口回调的上下文中调用。如果不确定,只需使用 0。

#### ul_get_urecord(domain, aor)

该函数返回指向具有给定地址记录的记录的指针。

参数含义如下:

- *udomain_t* domain* - 指向由 ul_register_udomain 返回的域的指针。

- *str* aor* - 请求记录的地址记录。

#### ul_lock_udomain(domain)

该函数锁定指定域,这意味着在此期间,其他进程将无法访问。这可以防止竞争条件。锁的范围是指定域,也就是说,多个域可以同时访问,它们不会相互阻塞。

参数含义如下:

- *udomain_t* domain* - 要锁定的域。

#### ul_unlock_udomain(domain)

解锁之前由 ul_lock_udomain 锁定的指定域。

参数含义如下:

- *udomain_t* domain* - 要解锁的域。

#### ul_release_urecord(record, is_replicated)

执行一些完整性检查 - 如果所有 contact 都已被删除,则删除整个记录结构。

参数含义如下:

- *urecord_t* record* - 要释放的记录。
- *char is_replicated* - 指定此函数是否将从二进制接口回调的上下文中调用。如果不确定,只需使用 0。

#### ul_insert_ucontact(record, contact, contact_info, contact, is_replicated)

该函数使用指定参数在给定记录中插入新 contact。

参数含义如下:

- *urecord_t* record* - 要插入 contact 的记录。
- *str* contact* - Contact URI。
- *ucontact_info_t* contact_info* -
				包含新 contact 信息的单个结构。
- *char is_replicated* - 指定此函数是否将从二进制接口回调的上下文中调用。如果不确定,只需使用 0。

#### ul_delete_ucontact (record, contact, is_replicated)

该函数从记录中删除给定的 contact。

参数含义如下:

- *urecord_t* record* - 要从中删除 contact 的记录。

- *ucontact_t* contact* - 要删除的 contact。
- *char is_replicated* - 指定此函数是否将从二进制接口回调的上下文中调用。如果不确定,只需使用 0。

#### ul_delete_ucontact_from_id (domain, contact_id)

该函数从给定域中删除具有给定 contact_id 的 contact。

参数含义如下:

- *udomain_t* domain* - 可以找到 contact 的域。

- *uint64_t contact_id* - 标识要删除的 contact 的 contact_id。

#### ul_get_ucontact(record, contact)

该函数尝试查找具有给定 Contact URI 的 contact,并返回指向表示该 contact 的结构的指针。

参数含义如下:

- *urecord_t* record* - 要搜索 contact 的记录。

- *str_t* contact* - 请求 contact 的 URI。

#### ul_get_domain_ucontacts (domain, buf, len, flags)

该函数从给定域检索所有已注册用户的所有 contact,并将它们返回给调用者提供的缓冲区。如果缓冲区太小,函数返回正值,指示需要多少额外空间来容纳所有 contact。请注意,正值应该仅作为"提示"使用,因为在后续调用之间,已注册 contact 的数量不能保证保持不变。

如果标志参数设置为非零值,则仅返回设置了指定标志的 contact。例如,可以仅列出 NAT 后面的 contact。

参数含义如下:

- *udomaint_t* domain* - 要从中获取 contact 的域。

- *void* buf* - 用于返回 contact 的缓冲区。

- *int len* - 缓冲区的长度。

- *unsigned int flags* - 必须设置的标志。

#### ul_get_all_ucontacts (buf, len, flags)

该函数检索所有已注册用户的所有 contact,并将它们返回给调用者提供的缓冲区。如果缓冲区太小,函数返回正值,指示需要多少额外空间来容纳所有 contact。请注意,正值应该仅作为"提示"使用,因为在后续调用之间,已注册 contact 的数量不能保证保持不变。

如果标志参数设置为非零值,则仅返回设置了指定标志的 contact。例如,可以仅列出 NAT 后面的 contact。

参数含义如下:

- *void* buf* - 用于返回 contact 的缓冲区。

- *int len* - 缓冲区的长度。

- *unsigned int flags* - 必须设置的标志。

#### ul_update_ucontact(record, contact, contact_info, is_replicated)

该函数使用新值更新 contact。

参数含义如下:

- *urecord_t* record* - 要插入 contact 的记录。
- *ucontact_t* contact* - Contact URI。
- *ucontact_info_t* contact_info* -
				包含新 contact 信息的单个结构。
- *char is_replicated* - 指定此函数是否将从二进制接口回调的上下文中调用。如果不确定,只需使用 0。

#### ul_bind_ursloc( api )

该函数导入 USRLOC 模块导出的所有函数。为其他想要使用内部 USRLOC API 的模块提供了一种轻松的加载和访问函数的方式。

参数含义如下:

- *usrloc_api_t* api* - USRLOC API。

#### ul_register_ulcb(type ,callback, param)

该函数向 USRLOC 注册一个回调函数,当 USRLOC 内部发生某些事件时调用。

参数含义如下:

- *int types* - 应该调用回调的事件类型(请参阅 usrloc/ul_callback.h)。
- *ul_cb f* - 回调函数;请参阅 usrloc/ul_callback.h 获取原型。
- *void *param* - 每次调用回调时要传递的一些参数。

#### ul_get_num_users()

该函数遍历所有域并汇总用户数量。

### 许可证

所有文档文件(即 .md 扩展名)均采用知识共享 4.0 许可证授权。
