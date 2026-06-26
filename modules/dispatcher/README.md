---
title: "调度器模块"
description: "此模块实现目标地址的调度器。它对请求的各个部分计算哈希值，并从目标集中选择一个地址。所选地址可以覆盖 SIP 请求的 R-URI 或用作出站代理。"
---

## 管理指南


### 概述


此模块实现目标地址的调度器。它
		对请求的各个部分计算哈希值，并从
		目标集中选择一个地址。所选地址可以覆盖 SIP 请求的 R-URI 或用作出站代理。


该模块可用作无状态负载均衡器，不保证公平分配。


对于分配算法，该模块允许定义
		目标的权重。这对于在目标之间获得不同的流量分配比例很有用。


从版本 2.1 开始，调度器模块将其目标集
		保存到不同的分区中。每个分区由其自己的
		"db_url"、"table_name"、"dst_avp"、"grp_avp"、"cnt_avp"、"sock_avp"、
                "attr_avp"、"blacklists"、"ping_from"、"ping_method" 和
                "persistent_state" 属性集描述。设置任何这些
                模块参数将仅更改"默认"分区的属性。


为了创建新分区，可以使用 [partition](#param_partition)
		参数。如果未为"默认"分区定义任何 8 个分区特定参数，
		则不会创建此分区。一旦创建了"默认"分区，任何未定义的
		参数将从"默认"分区的相应参数继承值。如果没有
		"默认"分区，则使用参数描述中指定的默认值。最后，请注意，每个使用"table_name"分区属性指定的调度器表
		需要该分区数据库中相应的"version"表记录，
		通过"db_url"指定。


从版本 2.1 开始，"flags"参数已移至
		ds_select_dst() 和 ds_select_domain()，以及"force_dst"和
		"use_default"标志。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *TM - 仅在需要主动恢复失败主机时使用*。
- *clusterer* - 仅在启用"cluster_id"
				选项时。
- *database* - 某个数据库 SQL 模块
- *freeswitch - 仅在启用"fetch_freeswitch_stats"时使用。*。


#### 外部库或应用程序


以下库或应用程序必须在运行
		OpenSIPS 与此模块一起使用之前安装：


- *无*。


### 导出的参数


#### db_url (string)


模块的默认数据库连接，覆盖全局
		'db_default_url' 设置。一旦指定，缺少
		'db_url' 属性的分区将从该值继承其 URL。


*默认值为 "NULL"。*


```c title="设置调度器的默认数据库 URL"
...
modparam("dispatcher", "db_url", "mysql://user:passwb@localhost/database")
...
```


#### attrs_avp (str)


用于包含当前目标属性字符串的 avp 名称。
		选择目标时，自动地，此 AVP
		将提供属性字符串 - 这是一个不透明字符串（从
		OpenSIPS 角度看）：它从目标定义加载（通过
		数据库）并在脚本中盲目提供。
		设置此参数将仅更改默认分区的
		attrs_avp。使用 partition 参数创建和更改
		其他分区。


*默认值为 "null" - 不提供 ATTRIBUTEs。*


```c title="设置'默认'分区的'attrs_avp'参数"
...
modparam("dispatcher", "attrs_avp", "$avp(272)")
...
```


#### script_attrs_avp (str)


用于包含当前目标脚本属性字符串的 avp 名称。
		选择目标时，自动地，此 AVP
		将提供属性字符串 - 这是一个不透明字符串（从
		OpenSIPS 角度看）：它通过
		ds_push_script_attrs MI 或 SCRIPT 函数提供。


*默认值为 "null" - 不提供 SCRIPT ATTRIBUTEs。*


```c title="设置'默认'分区的'script_attrs_avp'参数"
...
modparam("dispatcher", "attrs_avp", "$avp(script_attrs)")
...
```


#### algo_route (str)


使用算法 10 时要调用的路由名称。
		该路由将获得当前需要评估的调度器条目的 dst_uri、attrs 和 script_attrs 作为参数（可通过
		$param(1)、$param(2) 和 $param(3) 或通过 $param(dst_uri)、$param(attrs) 和 $param(script_attrs) 获取）。
		调度器模块考虑路由的返回值作为当前调度器条目的权重，使用算法 10 时，调度器条目按权重升序排序。

		如果从算法路由返回的值是负数，则当前调度器条目将自动跳过使用


*默认值为 "null" - 禁用。*


```c title="使用 algo_route 进行哈希："
...
modparam("dispatcher", "algo_route", "my_dispatcher_logic)"
...
route[my_dispatcher_logic] {
        $var(curent_score) = 0;
        xlog("DISPATCHER - 为 $param(dst_uri) 运行逻辑，属性 $param(attrs) 和脚本属性 $param(script_attrs) \n");

	# 根据您的逻辑决定惩罚当前调度器条目
	if (my_condition_here)
		$var(current_score) = $var(current_score) + 10;

        return $var(rc);
}
```


#### hash_pvar (str)


用于哈希算法 7 的 PV 字符串。


> [!注意]
> 如果您想对自定义消息部分进行哈希，则必须设置此参数。


*默认值为 "null" - 禁用。*


```c title="使用 $avp(273) 进行哈希："
...
modparam("dispatcher", "hash_pvar", "$avp(273)")
...
```


```c title="使用 PV 组合进行哈希："
...
modparam("dispatcher", "hash_pvar", "hash the $fU@$ci")
...
```


#### setid_pvar (str)


在不带组参数调用 ds_is_in_list()（第三个参数）时，
		存储设置 ID（组 ID）的 PV 名称。


*默认值为 "null" - 不设置 PV。*


```c title="设置'setid_pvar'参数"
...
modparam("dispatcher", "setid_pvar", "$var(setid)")
...
```


#### ds_ping_method (string)


通过此方法，您可以定义使用哪种方法探测
		失败网关。此方法仅在编译时
		启用了失败网关探测才可用。


如果要为其他分区定义 ping 方法，
		请使用'partition'参数。


*默认值为 "OPTIONS"。*


```c title="设置'ds_ping_method'参数"
...
modparam("dispatcher", "ds_ping_method", "INFO")
...
```


#### ds_ping_from (string)


通过此方法，您可以定义发送到
		失败网关的请求的"From:"行。此方法仅在
		编译时启用了失败网关探测才可用。


如果要为其他分区的"From:"
		ping 头定义，请使用'partition'参数。


*默认值为 "sip:dispatcher@localhost"。*


```c title="设置'ds_ping_from'参数"
...
modparam("dispatcher", "ds_ping_from", "sip:proxy@sip.somehost.com")
...
```


#### ds_ping_interval (int)


通过此方法，您可以定义向
		失败网关发送请求的间隔。此参数仅在 TM 模块
		加载时使用。如果设置为"0"，则
		禁用失败请求的 ping。


*默认值为 "0"（禁用）。*


```c title="设置'ds_ping_interval'参数"
...
modparam("dispatcher", "ds_ping_interval", 30)
...
```


#### ds_ping_maxfwd (int)


此参数允许您为调度器模块
		生成的 SIP ping 请求强制执行特定的 Max-Forward 值。
		如果未明确设置，则不会强制执行任何值，而由
		事务层（TM 模块）设置默认的 Max-Forward 值。


接受的值包括任何正整数值，包括
		"0"值。


```c title="设置'ds_ping_maxfwd'参数"
...
modparam("dispatcher", "ds_ping_maxfwd", 2)
...
```


#### ds_probing_sock (str)


本地套接字（OpenSIPS
		用于 SIP 流量的 [proto:]host[:port]）的描述，如果存在多个，用于
		发送探测消息。


*默认值为 "NULL(none)"。*


```c title="设置'ds_probing_sock'参数"
...
modparam("dispatcher", "ds_probing_sock", "udp:192.168.1.100:5077")
...
```


#### ds_probing_threshold (int)


如果要使网关进入探测模式，您将需要一定数量的请求，直到它从"active"变为
		探测。尝试次数可以通过此参数设置。


*默认值为 "3"。*


```c title="设置'ds_probing_threshold'参数"
...
modparam("dispatcher", "ds_probing_threshold", 10)
...
```


#### ds_probing_mode (int)


控制测试哪些网关以查看它们是否可访问。如果设置为
		0，则仅测试状态为 PROBING 的网关；如果设置为 1，则测试所有
		网关。如果设置为 1 且响应为 408（超时），
		则活动网关将设置为 PROBING 状态。


*默认值为 "0"。*


```c title="设置'ds_probing_mode'参数"
...
modparam("dispatcher", "ds_probing_mode", 1)
...
```


#### ds_probing_list (str)


定义一个或多个 setid 的列表，用于限制
		哪些目标在探测处于活动状态时被探测。当多个代理共享同一调度器表，但您希望限制哪些代理负责探测特定目标时，这很有用。


*默认值为 "NULL（探测所有集合）"。*


```c title="设置'ds_probing_list'参数"
...
modparam("dispatcher", "ds_probing_list", "1,2,3")
...
```


#### ds_define_blacklist (str)


根据'默认'
		分区的调度 setid 定义黑名单。
		此列表将包含与给定 setid 匹配的
		目标的 IP（无端口，所有协议）。
		如果要根据其他分区的集合定义黑名单，
		请使用'partition'参数。


允许此参数的多个实例。


*默认值为 "NULL"。*


```c title="设置'默认'分区的'ds_define_blacklist'参数"
...
modparam("dispatcher", "ds_define_blacklist", "list= 1,4,3")
modparam("dispatcher", "ds_define_blacklist", "blist2= 2,10,6")
...
```


#### options_reply_codes (str)


此参数必须包含以逗号分隔的 SIP 回复代码列表。
		这里定义的代码，除了 200 之外，
		将被视为用于 ping 的 OPTIONS 消息的有效回复代码。


*默认值为 "NULL"。*


```c title="设置'options_reply_codes'参数"
...
modparam("dispatcher", "options_reply_codes", "501, 403")
...
```


#### dst_avp (str)


这主要用于内部使用，代表将保存地址列表的 avp
		的名称，按所选算法的
		顺序排列。如果 use_default 为 1，
		则最后一个 dst_avp_id 的值是目标集中的最后一个地址。第一个
		dst_avp_id 是选定的目标。所有其他地址
		将从目标集添加到 avp 列表中以实现顺序分支。
		设置此参数将仅更改默认分区的
		dst_avp。使用 partition 参数创建和更改
		其他分区。


*对于'默认'分区，默认值为
			"$avp(ds_dst_failover)"。对于任何其他分区，
			默认值为 "$avp(ds_dst_failover_partitionname)"。*


```c title="设置'默认'分区的'dst_avp'参数"
...
modparam("dispatcher", "dst_avp", "$avp(271)")
...
```


#### grp_avp (str)


这主要用于内部使用，代表存储目标集组 ID 的 avp
		的名称。便于以后使用或检查。
		设置此参数将仅更改默认分区的
		grp_avp。使用 partition 参数创建和更改
		其他分区。


*对于'默认'分区，默认值为
			"$avp(ds_grp_failover)"。对于任何其他分区，
			默认值为 "$avp(ds_grp_failover_partitionname)"。*


```c title="设置'默认'分区的'grp_avp'参数"
...
modparam("dispatcher", "grp_avp", "$avp(273)")
...
```


#### cnt_avp (str)


这主要用于内部使用，代表保存 dst_avp avp 中保留的目标地址数量的 avp
		的名称。
		设置此参数将仅更改默认分区的
		cnt_avp。使用 partition 参数创建和更改
		其他分区。


*对于'默认'分区，默认值为
			"$avp(ds_cnt_failover)"。对于任何其他分区，
			默认值为 "$avp(ds_cnt_failover_partitionname)"。*


```c title="设置'默认'分区的'cnt_avp'参数"
...
modparam("dispatcher", "cnt_avp", "$avp(274)")
...
```


#### sock_avp (str)


这主要用于内部使用，代表存储套接字的 avp
		的名称，用于 dst_avp avp 中保存的目标地址。
		设置此参数将仅更改默认分区的
		sock_avp。使用 partition 参数创建和更改
		其他分区。


*对于'默认'分区，默认值为
			"$avp(ds_sock_failover)"。对于任何其他分区，
			默认值为 "$avp(ds_sock_failover_partitionname)"。*


```c title="设置'默认'分区的'sock_avp'参数"
...
modparam("dispatcher", "sock_avp", "$avp(275)")
...
```


#### pvar_algo_pattern (str)


此参数由 PVAR(9) 算法使用，用于指定
		用于检测每个目标负载的伪变量模式。伪变量的名称应包含字符串"%u"，
		该字符串将被模块内部替换为目标的
		URI。字符串"%i"也可以使用，将被
		替换为目标集 ID（在同一 URI 存在于多个集中的情况下很有用）。


*默认值为 "none"。*


```c title="设置'pvar_algo_pattern'参数"
...
modparam("dispatcher", "pvar_algo_pattern", "$stat(load_%u)")
...
```


#### persistent_state (int)


指定 *state* 列是否
		应在启动时加载并在运行时刷新
		（针对"默认"分区）。


如果要为其他分区定义持久状态，
		请使用'partition'参数。


*默认值为 "1"（启用）。*


```c title="设置 persistent_state 参数"
...
# 禁用与目标状态相关的所有数据库操作
modparam("dispatcher", "persistent_state", 0)
...
```


#### cluster_id (integer)


模块所属集群的 ID。集群支持用于
		调度器模块的两个目的：共享
		目标的状态和控制对目标的 ping。


如果启用集群，模块将自动与属于集群的
		其他 OpenSIPS 实例共享
		目标状态的更改。每当状态发生此类更改（根据 MI 命令、探测结果、脚本命令），
		模块会将此状态更改复制到给定集群中的所有节点。


具有共享标签支持的集群可用于控制
		集群中的哪个节点将执行对
		目标的 ping/探测。请参阅
		[集群共享标签](#param_cluster_sharing_tag) 选项。


此 OpenSIPS 集群公开 **"dispatcher-status-repl"**
功能，以便在任意同步请求中将节点标记为合格的数据捐赠者。因此，集群必须至少有
一个节点标记有 **"seed"** 值
作为 *clusterer.flags* 列/属性才能完全正常运行。
有关更多详细信息，请参阅 [clusterer - Capabilities](../clusterer#capabilities)
章节。


有关如何定义和填充（使用 OpenSIPS
		节点）集群的更多信息，请参阅 [clusterer](../clusterer) 模块。


*默认值为 "0（无）"。*


```c title="设置 cluster_id 参数"
...
# 与集群 ID 9 中的所有 OpenSIPS 复制目标状态
modparam("dispatcher", "cluster_id", 9)
...
```


#### cluster_sharing_tag (string)


共享标签的名称（如 clusterer 模块所定义），
		用于控制哪个节点负责执行模块中的自我触发
		操作。此类操作可能是目标探测
		（另请参阅 [集群探测模式](#param_cluster_probing_mode) 参数）
		或共享目标状态的更改。
		如果已定义，只有具有此标签 active 状态的节点才会
		执行操作（ping 和共享状态）。


[cluster id](#param_cluster_id) 必须为此选项
		定义才能工作。


这是一个可选参数。如果未设置，集群中的所有节点
		将共享状态更改。


*默认值为"空（无）"。*


```c title="设置 cluster_sharing_tag 参数"
...
# 只有具有 active "vip" 共享标签的节点将执行 ping
# 并广播状态更改
modparam("dispatcher", "cluster_id", 9)
modparam("dispatcher", "cluster_sharing_tag", "vip")
...
```


#### cluster_probing_mode (string)


此参数控制在使用
		集群支持时如何进行探测/ping。它涉及集群中的哪个节点
		ping 哪个网关/目标。


[cluster id](#param_cluster_id) 必须为此选项
		定义才能工作。


支持的探测模式有：


- **"all"** - 集群中的所有节点
			将独立地 ping 所有定义的目标，
			一种"全部 ping 全部"模式。
- **"by-shtag"** - 所有目标
			仅由集群中的一个节点 ping，该节点具有
			[集群共享标签](#param_cluster_sharing_tag) active。通过
			在不同的节点上激活共享标签，
			ping 职责将转移到集群中的另一个节点。
- **"distributed"** - ping
			工作分布在集群中的所有节点上，因此每个
			节点将 ping 目标整体集合的一个子集。仍然
			所有目标都会被 ping（并且在每个 ping 周期中只 ping 一次）。
			当新节点加入或
			节点退出时，节点间的 ping 工作重新分配是自动完成的。仍然无法保证哪个节点
			将负责 ping 哪个目标。


*默认值为 ""all""。*


```c title="设置 cluster_probing_mode 参数"
...
# 只有具有 active "vip" 共享标签的节点将执行 ping
modparam("dispatcher", "cluster_id", 9)
modparam("dispatcher", "cluster_sharing_tag", "vip")
modparam("dispatcher", "cluster_probing_mode", "by-shtag")
...
# ping 工作分布在所有节点上
modparam("dispatcher", "cluster_id", 9)
modparam("dispatcher", "cluster_probing_mode", "distributed")
...
```


#### partition (string)


使用以下属性定义新的分区（数据源）：
		"db_url"、"table_name"、"dst_avp"、"grp_avp"、"cnt_avp"、"sock_avp"、
		"attrs_avp"、"script_attrs"、"ds_define_blacklist"。所有这些
		属性都是可选的，具有适当的默认值。


语法是："partition_name: param1 = value1; param2 = value2"。
		每个值的格式与使用 modparam 定义特定
		参数时使用的格式相同。


可以多次设置此参数，从而根据需要定义尽可能多的
		分区。'default'分区也可以使用此参数定义。


```c title="定义名为'voicemail'的新分区"
...
modparam("dispatcher", "partition",
                "voicemail:
                    db_url = mysql://user:passwd@localhost/database;
                    table_name = dispatcher;
                    attrs_avp = $avp(ds_attr_vm);
                    ds_define_blacklist = list2 = 4,6")
...
```


```c title="定义'trunks'分区并将其设为'default'分区，以避免加载'dispatcher'表"
...
modparam("dispatcher", "partition",
                "trunks:
                    db_url = mysql://user:passwd@localhost/database;
                    table_name = dispatcher_trunks;
                    attrs_avp = $avp(ds_attr_trunks)")
modparam("dispatcher", "partition", "default: trunks")
...
```


#### table_name (string)


从中加载调度器目标的默认表名。
		缺少'table_name'属性的分区将从该值继承其表名。


*默认值为 "dispatcher"。*


```c title="设置默认表名"
...
modparam("dispatcher", "table_name", "my_dispatcher")
...
```


#### setid_col (string)


数据库中存储网关组 ID 的列名。


*默认值为 "setid"。*


```c title="设置'setid_col'参数"
...
modparam("dispatcher", "setid_col", "groupid")
...
```


#### destination_col (string)


数据库中存储目标的
			sip uri 的列名。


*默认值为 "destination"。*


```c title="设置'destination_col'参数"
...
modparam("dispatcher", "destination_col", "uri")
...
```


#### state_col (string)


数据库中存储目标
			uri 状态的列名。


*默认值为 "state"。*


```c title="设置'state_col'参数"
...
modparam("dispatcher", "state_col", "dststate")
...
```


#### weight_col (string)


数据库中存储目标 uri
			权重的列名。


*默认值为 "weight"。*


```c title="设置'weight_col'参数"
...
modparam("dispatcher", "weight_col", "dstweight")
...
```


#### priority_col (string)


数据库中存储目标 uri
			优先级的列名。


*默认值为 "priority"。*


```c title="设置'priority_col'参数"
...
modparam("dispatcher", "priority_col", "dstprio")
...
```


#### attrs_col (string)


数据库中存储目标 uri
			属性（不透明字符串）的列名。


*默认值为 "attrs"。*


```c title="设置'attrs_col'参数"
...
modparam("dispatcher", "attrs_col", "dstattrs")
...
```


#### socket_col (string)


数据库中存储目标 uri
			套接字（作为字符串）的列名。


*默认值为 "socket"。*


```c title="设置'socket_col'参数"
...
modparam("dispatcher", "socket_col", "my_sock")
...
```


#### probe_mode_col (string)


数据库中存储目标
			probe_mode（作为字符串）的列名。


*默认值为 "probe_mode"。*


```c title="设置'probe_mode_col'参数"
...
modparam("dispatcher", "probe_mode_col", "probing")
...
```


#### fetch_freeswitch_stats (integer)


如果启用，FreeSWITCH 目标可以具有动态调度权重，
		使用 FreeSWITCH Event Socket Layer 在运行时刷新。
		对于这些目标，必须在"weight"列中配置 Event Socket Layer URL，而不是整数字符串。一些示例值：
		*"fs://:password@freeswitch.example.com"*
		或 *"fs://user:password@127.0.0.1:8021"*。
		默认 ESL 端口为 8021。


OpenSIPS 将与给定的套接字建立连接，并
		使用 FreeSWITCH 推送的统计信息定期计算/更新这些目标的权重。


自动计算的权重值范围为
		**0 - 100**。
		这在将正常目标与 FreeSWITCH 目标分组时很有帮助。


动态权重每
		*event_heartbeat_interval* 秒重新计算（请参阅
		"freeswitch" OpenSIPS 模块以了解更多详细信息），
		因为统计信息预计会从 FreeSWITCH 到达。以下是更新公式
		（FreeSWITCH 统计信息以粗体突出显示）：


*weight = 100 * (**Idle-CPU** / 100) * (1 - **Session-Count** / **Max-Sessions**)*


*默认值为 **0**（禁用）。*


```c title="设置 fetch_freeswitch_load 参数"
...
modparam("dispatcher", "fetch_freeswitch_stats", 1)
...
```


#### max_freeswitch_weight (integer)


FreeSWITCH ESL 启用目标的最大权重。此值
		也在启动/重载时使用，当时还没有从 FreeSWITCH 获得统计信息。


重要提示：当将正常目标与 FreeSWITCH 启用的目标混合在同一调度集中时，OpenSIPS 会将任何大于 **max_freeswitch_weight**
		的权重值截断到此参数的值！


注意：OpenSIPS 在内部将权重四舍五入到最近的整数，因此更大的
		最大权重值将更准确地表示 FreeSWITCH 盒子上的当前负载！例如，如果将此参数设置为 1，当 CPU 或会话使用率超过 50% 时，
		该盒子将不会收到任何流量！


*默认值为 **100**。*


```c title="设置 max_freeswitch_weight 参数"
...
modparam("dispatcher", "max_freeswitch_weight", 1000)
...
```


### 导出的函数


#### ds_select_dst(set, alg, [flags], [partition], [max_res])


该方法从给定的地址集中选择一个目标。它将
		覆盖 SIP 请求的目标 URI (*$du*)。


参数含义如下：


- *set (int)* - 要从中选择目标的集合标识符
- *alg (int)* - 用于选择
			目标地址的算法

  - "0" - 按 callid 哈希
  - "1" - 按 from uri 哈希
  - "2" - 按 to uri 哈希
  - "3" - 按 request-uri 哈希
  - "4" - 加权轮询（下一个目标）。
				目标的权重决定了在转到下一个目标之前选择它的次数。
  - "5" - 按 authorization-username 哈希
				（Proxy-Authorization 或"普通"认证）。
				如果找不到用户名，则使用加权轮询。
  - "6" - 随机（使用 rand()）。
  - "7" - 按 PV 字符串内容的哈希。
				注意：这仅在设置 hash_pvar 参数时有效。
  - "8" - 选择集合中的第一个条目。
  - "9" - 使用 *pvar_algo_pattern*
				参数确定每个服务器的负载。如果未指定该参数，
				则选择集合中的第一个条目。
  - "10" - 为 setid 中的每个调度器条目调用
				*algo_route*
				OpenSIPS 路由，以决定路由顺序。
				请参阅 algo_route 参数以获取使用示例
  - "X" - 如果算法未实现，则
				选择集合中的第一个条目。
- *flags (string, optional)* - 调整函数行为的标志字符串：

  - 'f'（故障转移支持）：将目标集中剩余的
				地址存储在内部管理的 AVP 中。您可以使用
				[ds next dst](#func_ds_next_dst) 切换到下一个
				地址，从而实现到所有可能目标的顺序分支。
  - 'u'（仅用户）：将仅指定 URI 用户部分
					用于哈希。
  - 'd'（使用默认）：使用目标集中的最后一个地址
					作为发送消息的最后一个选项。
  - 'a'（追加目标）：将任何新目标追加到
					当前目标列表，而不是重写列表。
标志按分区保存。
- *partition (string, optional)* - 数据库分区名称
- *max_res (int, optional)* - 表示仅最大数量的目标应包含在指定的故障转移 AVP 中。这允许有多个目标，同时
			防止在某个数字全局失败的情况下进行过多的故障转移尝试。


此函数可以从 REQUEST_ROUTE、BRANCH_ROUTE 和 FAILURE_ROUTE 使用。


```c title="ds_select_dst 使用示例"
...
if (!ds_select_dst(1, 0)) {
	xlog("ERROR: 未找到活动目标！\n");
	send_reply(503, "服务不可用");
	exit;
}
...
ds_select_dst(1, 0, , "fs_boxes", 5);
...
ds_select_dst(1, 0, "fUD", "ask_boxes");
...
ds_select_dst(2, 0, "fud", "pstn_gws", 5);
ds_select_dst(3, 1, "fua", "pstn_gws", 2);
...
# 使用变量
$var(part) = "pstn_gws"
$var(setid) = 1;
$var(alg) = 4;
$var(flags) = "fdu";
$var(max_res) = 2;
ds_select_dst($var(setid), $var(alg), $var(flags), $var(part), $var(max_res));
...
```


#### ds_select_domain(set, alg, [flags], [partition], [max_res])


该方法从地址集中选择一个目标并重写
		Request-URI (*$ru*) 的主机名和端口部分。
		其参数与 [ds select dst](#func_ds_select_dst) 中的含义相同。


如果存在"f"（故障转移支持）标志，则目标集中的其余地址将存储在内部
		管理的 AVP 中。您可以使用 [ds next domain](#func_ds_next_domain) 切换到列表中的下一个地址，从而实现到所有可能目标的顺序分支。


此函数可以从 REQUEST_ROUTE、BRANCH_ROUTE 和 FAILURE_ROUTE 使用。


#### ds_next_dst([partition])


从 partition.'dst_avp_id' 的 AVP 中获取下一个目标地址，并设置 dst_uri（出站代理地址）。
		如果省略"partition"，则使用默认分区。此
		函数使用 ds_select_dst 或 ds_select_domain 中设置的标志。


此函数可以从 REQUEST_ROUTE 和 FAILURE_ROUTE 使用。


#### ds_next_domain([partition])


从 partition.'dst_avp_id' 的 AVP 中获取下一个目标地址，并设置请求 uri 的域部分。
		如果省略"partition"，则使用默认分区。此
		函数使用 ds_select_dst 或 ds_select_domain 中设置的标志。


此函数可以从 REQUEST_ROUTE 和 FAILURE_ROUTE 使用。


#### ds_mark_dst([state], [partition])


将分区目标集中最后使用的地址标记为
		非活动（"i"/"I"/"0"）、活动（"a"/"A"/"1"）或探测（"p"/"P"/"2"）。
		使用此函数，可以实现对失败网关的自动检测。当地址被标记为非活动或探测时，它将被
		[ds select dst](#func_ds_select_dst) 和 [ds select domain](#func_ds_select_domain) 忽略。
		如果省略"partition"，则使用默认分区。此函数使用 [ds select dst](#func_ds_select_dst) 或
		[ds select domain](#func_ds_select_domain) 中设置的标志。


可能的参数：


- state (string, optional) - 上次尝试目标的
				新状态。可能的值：

  - *"i", "I" 或 "0"（默认）* - 最后
					一个目标应设置为非活动状态，并在将来被忽略。
  - *"a", "A" 或 "1"* - 最后
					一个目标应设置为活动状态。
  - *"p", "P" 或 "2"* - 最后
					一个目标将设置为探测状态。注意：您需要调用此函数"threshold"次，
					它才会真正设置为探测。
- partition (string, optional) - 数据库分区名称，
			否则将使用默认分区。


此函数可以从 REQUEST_ROUTE 和 FAILURE_ROUTE 使用。


#### ds_count(set, state_filter, res_var, [partition])


返回分区集合中活动、非活动或探测目标的数量，
		或这些属性的组合。


参数含义：


- *set (int)* - 一组调度目标
- *state_filter (string)* - 应该计数哪些目标。活动（"a"、"A" 或 "1"）、非活动
			（"i"、"I" 或 "0"）、探测（"p"、"P" 或 "2"）目标或
			这些标志的不同组合，如"pI"、"1i"、"ipA"...
- *res_var (variable)* - 将保存整数结果的变量
- *partition (string, optional)* - 数据库分区名称。如果省略，将使用"默认"分区。


此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE、
		LOCAL_ROUTE、TIMER_ROUTE、EVENT_ROUTE 使用。


```c title="ds_count 使用示例"
...
if (ds_count(1, "a", $avp(result))) {
	...
}
...
if (ds_count($avp(set), "ip", $avp(result), $avp(partition))) {
	...
}
...
```


#### ds_is_in_list(ip, port, [set], [partition], [active_only], [pattern])


仅当"ip"和"port"指向给定调度器"集合"中的主机时，此函数才返回 *true*。


参数含义：


- *ip (string)* - 要根据调度器"集合"测试的 IPv4 或 IPv6 地址
- *port (int)* - 要根据调度器列表测试的端口。
			为匹配任何端口，请使用 *0* 值
- *set (int, optional)* - 要根据其测试的调度器集合标识符。
			如果缺失，将检查所有集合。
			*-1* 集合是一个特殊值，充当"检查所有集合"的通配符。
- *partition (string, optional)* - 数据库分区名称
- *active_only (int, optional)* - 指定一个非零值以仅搜索活动目标（忽略探测和非活动状态的目标）
- *pattern (string, optional)* - 用于匹配目标属性的 glob 模式。如果目标 IP 和端口匹配但模式与目标的属性不匹配，则函数将失败。


此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、
		BRANCH_ROUTE 和 ONREPLY_ROUTE 使用。


```c title="ds_is_in_list 使用示例"
...
if (ds_is_in_list($si, $sp)) {
	# 源 IP:PORT 在调度器列表中
}
...
if (ds_is_in_list($rd, $rp, 2)) {
	# R-URI（IP 和端口）在"默认"分区的调度器集合 2 中
}
...
if (ds_is_in_list($rd, $rp, 2, "part2")) {
	# R-URI（IP 和端口）在"part2"分区的调度器集合 2 中
}
...
```


#### ds_push_script_attrs(script_attr, ip, port, set, [partition])


为由 IP、Port、setid 和 partition 定义的调度器条目设置脚本属性。


参数含义：


- *script_attr (str or pvar)* - 新的脚本属性
- *IP (string)* - 我们正在推送脚本属性的 IP 地址
- *port (int)* - 我们正在推送脚本属性的端口
- *setid (int)* - 我们正在推送脚本属性的 Setid
- *partition (string, optional)* - 数据库分区名称。如果省略，将使用"默认"分区。


此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE、
		LOCAL_ROUTE、TIMER_ROUTE、EVENT_ROUTE 使用。


```c title="ds_count 使用示例"
...
if (ds_push_script_attrs($var(my_attributes),$si , $sp, 1, 'my_partition')) {
	...
}
...
```


#### ds_get_script_attrs(uri, set, [partition], out_attrs)


获取由 URI、setid 和 partition 定义的调度器条目的脚本属性。


参数含义：


- *URI (string)* - 我们正在获取脚本属性的 URI 地址
- *setid (int)* - 我们正在推送脚本属性的 Setid
- *partition (string, optional)* - 数据库分区名称。如果省略，将使用"默认"分区。
- *out_atrs (pvar)* - 用于存储脚本属性的变量名称。


此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE、
		LOCAL_ROUTE、TIMER_ROUTE、EVENT_ROUTE 使用。


```c title="ds_count 使用示例"
...
if (ds_push_script_attrs($var(my_attributes),$si , $sp, 1, 'my_partition')) {
	...
}
...
```


### 导出的 MI 函数


#### dispatcher:set_state


替换过时的 MI 命令：*ds_set_state*。


设置目标地址的状态（可用于将目标标记为活动或非活动）。


名称：*dispatcher:set_state*


参数：


- *state* : 目标地址的状态

  - "a": 活动
  - "i": 非活动
  - "p": 探测
- *group*: 分区名称，后跟冒号和目标组 ID。如果省略分区名称，
			将使用默认分区。
- *address*: 组中目标的地址


MI FIFO 命令格式：


```c
opensips-cli -x mi dispatcher:set_state a 2 sip:10.0.0.202
```


#### dispatcher:list


替换过时的 MI 命令：*ds_list*。


它列出所有分区的组和包含的目标。


名称：*dispatcher:list*


参数：


- *full* (optional) - 在列表中添加权重、
				优先级和描述字段
- *partition* (optional) - 仅返回
				提供分区中的目标和集合。


MI FIFO 命令格式：


```c
opensips-cli -x mi dispatcher:list
```


#### dispatcher:reload


替换过时的 MI 命令：*ds_reload*。


它重新加载指定分区或所有分区的组和包含的目标。


名称：*dispatcher:reload*


参数：


- *partition* (optional) - 要重新加载的
				分区名称。默认分区是"default"。
- *inherit_state* (optional) : 是否继承目标的旧状态，默认是 y。

  - "n": 不继承状态
  - "y": 继承状态


MI FIFO 命令格式：


```c
opensips-cli -x mi dispatcher:reload
opensips-cli -x mi dispatcher:reload inherit_state=n
```


#### dispatcher:push_script_attrs


替换过时的 MI 命令：*ds_push_script_attrs*。


为由 IP、Port、setid 和可选 partition 定义的调度器条目推送脚本属性。


名称：*dispatcher:push_script_attrs*


参数：


- *attrs* : 要推送的新属性
- *ip*: 我们正在推送脚本属性的 IP
- *port*: 我们正在推送脚本属性的端口
- *setid*: 我们正在推送脚本属性的 Setid
- *partition ( optional )*: 我们正在推送脚本属性的分区


MI FIFO 命令格式：


```c
#opensips-cli -x mi dispatcher:push_script_attrs '{"ping":"30000","load":"50"}' '192.168.0.107' 5091 1 main
```


### 导出的事件


#### E_DISPATCHER_STATUS


当调度器模块将目标标记为激活或停用时触发此事件。


参数：


- *partition* - 目标所在分区名称。
- *group* - 目标组。
- *address* - 目标地址。
- *status* - 如果
				目标被激活则为 *active*，如果
				目标被检测为无响应则为 *inactive*。


### 导出的状态/报告标识符


该模块提供"dispatcher"状态/报告组，其中每个分区定义为单独的 SR 标识符。


#### [partition_name]


这些标识符的状态反映缓存数据的就绪/状态（从数据库加载时是否可用）：


- *-2* - 完全没有数据（初始状态）
- *-1* - 没有数据，初始加载正在进行
- *1* - 数据已加载，分区就绪
- *2* - 数据可用，正在重新加载


重新加载报告：


在数据重新加载方面，将报告以下事件：


- 启动数据库数据加载
- 数据库数据加载失败，丢弃
- 数据库数据加载成功完成
- 已加载 N 个目标（已丢弃 N 个）


```c
        {
            "Name": "default",
            "Reports": [
                {
                    "Timestamp": 1652373212,
                    "Date": "Thu May 12 19:33:32 2022",
                    "Log": "starting DB data loading"
                },
                {
                    "Timestamp": 1652373212,
                    "Date": "Thu May 12 19:33:32 2022",
                    "Log": "DB data loading successfully completed"
                },
                {
                    "Timestamp": 1652373212,
                    "Date": "Thu May 12 19:33:32 2022",
                    "Log": "2 destinations loaded (0 discarded)"
                }
            ]
        }

	
```


#### [partition_name];events


目标切换报告：


对于与目标状态更改相关的事件报告，该模块提供单独的标识符（仍然是每个分区一个）。
	为什么要单独的？状态更改报告可能很冗长，而且由于状态更改数量众多，存在丢失/丢弃重要重新加载报告的风险。


因此，每个分区将提供标识的"partition_name;events"用于报告目标的状态更改，以及
		更改的原因。这些标识符有 200 条记录历史，之后丢弃旧的。


```c
        {
            "Name": "default;events",
            "Reports": [
                {
                    "Timestamp": 1652373308,
                    "Date": "Thu May 12 19:35:08 2022",
                    "Log": "DESTINATION <sip:127.0.1.1>, set 1 switched to [inactive] due to negative probing reply\n"
                },
                {
                    "Timestamp": 1652373308,
                    "Date": "Thu May 12 19:35:08 2022",
                    "Log": "DESTINATION <sip:127.0.1.2>, set 1 switched to [inactive] due to negative probing reply\n"
                }
            ]
        },

	
```


有关如何访问和使用状态/报告信息，请参阅
	[https://www.opensips.org/Documentation/Interface-StatusReport-3-3](>https://www.opensips.org/Documentation/Interface-StatusReport-3-3)。


### 安装和运行


#### OpenSIPS 配置文件


下一张图片显示调度器的示例用法。


[OpenSIPS 配置文件 - 调度器使用示例](./samples.md "include")


## 常见问题


**Q: *dispatcher* 是否提供公平分配？**


无法保证这一点。您应该进行一些测量以决定哪种分配算法更适合您的环境。


**Q: *dispatcher* 是有状态的吗？**


不是。调度器是无状态的，尽管某些分配算法
			设计为选择同一目标用于同一对话的后续请求（例如，对 call-id 进行哈希）。**Q: *ds_is_from_list()* 函数怎么了？**该函数已被更通用的
			*ds_is_in_list()* 函数取代，该函数将 IP 和 PORT 作为参数来根据调度器列表进行测试。ds_is_from_list() == ds_is_in_list("$si", "$sp")


**Q: 调度器在选择目标时如何使用权重和优先级？**目标 *weight* 目前用于哈希算法，它增加了被选中的概率（如果我们有两个权重分别为 1 和 4 的目标，则第二个目标被选中的可能性是第一个的 4 倍）。所有权重的总和不需要加起来达到特定数字。
			权重现在用于轮询算法，一个目标在转到下一个目标之前会被连续选择次数等于其权重的次数。
			 *priority* 字段用于对集合中的目标进行排序。它不影响目标被选中的整体概率。它反映在列出目标时，字段可以肯定地用于进一步的选择算法。

**Q: *list_file* 模块参数怎么了？**文本文件支持（用于配置目标）已被删除。
			现在仅提供数据库支持（通过数据库表进行配置）- 如果您仍然希望使用文本文件进行配置，请使用 db_text 数据库驱动程序（通过文本文件模拟的数据库）


**Q: 在哪里可以找到更多关于 OpenSIPS 的信息？**


请参阅 [https://opensips.org/](https://opensips.org/)。


**Q: 在哪里可以发布关于此模块的问题？**


首先检查您的问题是否已在我们
			的邮件列表中回答：

关于任何稳定版本的问题应发送至
			users@lists.opensips.org，关于开发版本或 SVN 快照的问题应发送至 devel@lists.opensips.org。

如果您想保持邮件私密，请发送至 users@lists.opensips.org。


**Q: 如何报告错误？**


请遵循以下指南：[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证授权。
