---
title: "负载均衡器模块"
description: "负载均衡器模块提供基于负载的流量路由功能。简而言之，当 OpenSIPS 将呼叫路由到一组目标时，它能够跟踪每个目标的负载状态（当前通话数），并选择负载最轻的目标（当时）进行路由。"
---

## 管理指南


### 概述


负载均衡器模块提供基于负载的流量路由功能。
		简而言之，当 OpenSIPS 将呼叫路由到一组目标时，它能够
		跟踪每个目标的负载状态（当前通话数），
		并选择负载最轻的目标（当时）进行路由。
		OpenSIPS 知道每个目标的容量 - 它预先配置了
		目标接受的最大负载。更准确地说，
		在路由时，OpenSIPS 会考虑负载最轻的目标，而不是
		当前通话数最少的目标，而是可用槽位
		最大的目标。


此外，该模块还具有故障转移功能（如果选定的目标
		无响应，则尝试新目标）、保持目标状态
		（记住失败的目标并避免再次使用它们）以及
		检查目标健康状况（通过对目标进行探测
		并自动重新启用）。


### 工作原理


请参阅 OpenSIPS 网站上的负载均衡器教程：
		[https://opensips.org/Documentation/Tutorials-LoadBalancing-1-9](https://opensips.org/Documentation/Tutorials-LoadBalancing-1-9)。


### 探测和禁用目标


该模块能够通过执行 SIP 探测（发送 SIP 请求如 OPTIONS）
		来监控目标的状态。


对于每个目标，您可以配置应该执行何种探测
	（probe_mode 列）：


- *(0)* - 完全不探测；
- *(1)* - 仅当目标处于
		禁用模式时才进行探测（通过 MI 命令禁用将完全停止
		探测）。当探测下次成功时，
		目标将自动重新启用；
- *(2)* - 始终进行探测。如果已禁用，
		当探测下次成功时，
		目标将自动重新启用；


目标可以通过两种方式变为禁用状态：


- 脚本检测
- MI 命令


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *Dialog* - Dialog 模块
*freeswitch*。- 仅在
				启用"fetch_freeswitch_stats"时。
- *dialog* - TM 模块（仅在启用探测时）
- *clusterer* - 仅在启用"cluster_id"
				选项时。
- *database* - 某个 DB 模块


#### 外部库或应用程序


以下库或应用程序必须在运行加载了此模块的
		OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### db_url (string)


指向存储负载均衡规则的数据库的 URL。


*默认值为 "mysql://opensips:opensipsrw@localhost/opensips"。*


```c title="设置 db_url 参数"
...
modparam("load_balancer", "db_url", "dbdriver://username:password@dbhost/dbname")
...
```


#### db_table (string)


包含负载均衡规则的数据库表的名称。


*默认值为 "load_balancer"。*


```c title="设置 db_table 参数"
...
modparam("load_balancer", "db_table", "lb")
...
```


#### probing_interval (integer)


对目标进行探测的频率（以秒为单位）。如果
		设置为 0，则对所有
		目标禁用探测功能


*默认值为 "30"。*


```c title="设置 probing_interval 参数"
...
modparam("load_balancer", "probing_interval", 60)
...
```


#### probing_method (string)


用于探测请求的 SIP 方法。


*默认值为 ""OPTIONS""。*


```c title="设置 probing_method 参数"
...
modparam("load_balancer", "probing_method", "INFO")
...
```


#### probing_from (string)


在 SIP 探测请求中公布的 FROM SIP URI。


*默认值为 ""sip:prober@localhost""。*


```c title="设置 probing_from 参数"
...
modparam("load_balancer", "probing_from", "sip:pinger@192.168.2.10")
...
```


#### probing_reply_codes (string)


SIP 回复代码的逗号分隔列表。这里
		定义的代码，除了 200 之外，
		将被视为探测消息的有效回复代码。


*默认值为 "NULL"。*


```c title="设置 probing_reply_codes 参数"
...
modparam("load_balancer", "probing_reply_codes", "501, 403")
...
```


#### probing_verbose (number)


一个布尔选项，用于启用与基于探测
		回复和 MI 命令启用或禁用目标相关的
		额外日志记录。


0 值表示禁用，其他任何值表示启用。


额外日志将记录在 INFO 级别。


*默认值为 "0"（禁用）。*


```c title="设置 probing_verbose 参数"
...
modparam("load_balancer", "probing_verbose", 1)
...
```


#### lb_define_blacklist (string)


基于 lb 组定义黑名单。此列表将包含与给定组匹配的
		目标的 IP（无端口，所有协议）。


允许此参数的多个实例。


*默认值为 "NULL"。*


```c title="设置 lb_define_blacklist 参数"
...
modparam("load_balancer", "lb_define_blacklist", "list= 1,4,3")
modparam("load_balancer", "lb_define_blacklist", "blist2= 2,10,6")
...
```


#### fetch_freeswitch_stats (integer)


如果启用，资源的最大值也可以包含
		FreeSWITCH Event Socket Layer URL，例如 *"channels=fs://:password@freeswitch.example.com"*
		或 *"channels=fs://user:password@127.0.0.1:8021"*。默认 ESL 端口为 8021。


OpenSIPS 将与给定的套接字建立连接，并
		使用 FreeSWITCH 推送的统计信息定期更新
		给定资源的内部最大值。


资源的最大值每 *event_heartbeat_interval*
		秒更新一次（有关此设置的更多详细信息，请参阅 OpenSIPS 的"freeswitch"模块），
		当统计信息从 FreeSWITCH 到达时。


给定以下 FreeSWITCH 心跳消息格式：


```c
{
  ...
  "FreeSWITCH-Hostname": "pbx2",
  "FreeSWITCH-IPv4": "172.17.0.3",
  "Idle-CPU": "78.400000",
  "Max-Sessions": "1000",
  "Session-Count": "0",
  ...
}
```


，负载均衡器使用以下公式定期更新每个 FreeSWITCH 盒子的"max_load"值（FreeSWITCH 数据
		以粗体突出显示）：


*max_load = (**Idle-CPU** / 100)
				* (**Max-Sessions** -
				(**Session-Count** -
				current_load))*


*默认值为 "0"（禁用）。*


```c title="设置 fetch_freeswitch_load 参数"
...
modparam("load_balancer", "fetch_freeswitch_stats", 1)
...
```


#### initial_freeswitch_load (integer)


此参数仅在模块启动/重载后的几秒钟内相关，
		此时还没有从新加载的 FreeSWITCH ESL 套接字收到统计信息，
		但呼叫路由必须保持不受影响。任何启用 FreeSWITCH 的资源将
		继承上述整个间隔（最长 20 秒！）的此值。


*默认值为 "1000"。*


```c title="设置 initial_freeswitch_load 参数"
...
modparam("load_balancer", "initial_freeswitch_load", 200)
...
```


#### cluster_id (integer)


模块所属集群的 ID。集群支持用于
		负载均衡器模块的两个目的：共享
		目标的状态和控制对目标的 ping。


如果启用集群，模块将自动与属于集群的
		其他 OpenSIPS 实例共享
		目标状态的更改。每当状态发生此类更改（根据 MI 命令、探测结果、脚本命令），
		模块会将此状态更改复制到给定集群中的所有节点。


具有共享标签支持的集群可用于控制
		集群中的哪个节点将执行对
		目标的 ping/探测。请参阅
		[集群共享标签](#param_cluster_sharing_tag) 选项。


此 OpenSIPS 集群公开 **"load_balancer-status-repl"**
功能，以便在任意同步请求中将节点标记为合格的数据捐赠者。因此，集群必须至少有
一个节点标记有 **"seed"** 值
作为 *clusterer.flags* 列/属性才能完全正常运行。
有关更多详细信息，请参阅 [clusterer - Capabilities](../clusterer#capabilities)
章节。


有关如何定义和填充（使用 OpenSIPS
		节点）集群的更多信息，请参阅"clusterer"模块。


*默认值为 "0（无）"。*


```c title="设置 cluster_id 参数"
...
# 与集群 ID 9 中的所有 OpenSIPS 复制目标状态
modparam("load_balancer", "cluster_id", 9)
...
```


#### cluster_sharing_tag (string)


共享标签的名称（如 clusterer 模块所定义），
		用于控制哪个节点负责执行模块中的自我触发
		操作。此类操作可能是目标探测或
		共享目标状态的更改。
		如果已定义，只有具有此标签 active 状态的节点才会
		执行操作（ping 和共享状态）。


[cluster id](#param_cluster_id) 必须为此选项
		定义才能工作。


这是一个可选参数。如果未设置，集群中的所有节点
		将单独进行探测并共享状态更改。


*默认值为"空（无）"。*


```c title="设置 cluster_sharing_tag 参数"
...
# 只有具有 active "vip" 共享标签的节点将执行 ping
# 并广播状态更改
modparam("load_balancer", "cluster_id", 9)
modparam("load_balancer", "cluster_sharing_tag", "vip")
...
```


### 导出的函数


#### lb_start(grp,resources[,flags],[attrs])


此函数在可用
		目标上启动新的负载均衡会话。这相当于找到负载最轻的、能提供请求资源且属于请求
		组的目標。


参数含义如下：


- *grp* (int) - 目标组 ID；
			目标可以分组到多个组中，您可以将它们用于
			不同的场景。
- *resources* (string) - 
			当前呼叫所需的资源的
			分号分隔列表。
- *flags* (string, optional) - 各种标志
			用于控制 LB 算法（或计算
			系统上的可用负载）：

  - *n* - 负可用性  - 使用
				具有负可用性的目标（超出容量）；
				不忽略具有负可用性的资源，从而
				能够选择超出容量的目标进行负载均衡。这可能在我们需要
				限制通用呼叫量并始终传递
				重要/高优先级呼叫的场景中需要。
  - *r* - 相对值 - 使用相对
				可用负载（空闲百分比）来
				计算每个对等体/资源的负载；没有此标志，
				则假定绝对值 - 使用有效
				可用负载（maximum_load - current_load）来
				计算每个对等体/资源的负载。
  - *s* - 当找到多个具有相同负载的目标时，
				随机选择一个目标，而不是
				始终选择第一个匹配的目标。
				这有助于从第一个目标卸载过多负载，
				并在失败呼叫始终路由到第一个目标的场景中分配负载，
				因为它们几乎不影响目标的负载计数器。
- *attrs* (var, optional) - 一个可写变量，
			用于填充所选目标的属性。


函数可能返回：


- *1 (true)* - 如果设置了新的目标 URI，
			指向选定的目标。注意 RURI 不会
			被此函数更改。
- *-1 (false)* - 通用内部错误
			（内存分配、解析）
- *-2 (false)* - 没有可用容量
			（目标已启动并可用，但没有
			可用通道）
- *-3 (false)* - 没有可用目标
			（请求的资源与任何活动目标不匹配）
- *-4 (false)* - 错误的资源
			（请求的资源不存在）


此函数可以从 REQUEST_ROUTE、BRANCH_ROUTE 和
		FAILURE_ROUTE 使用。


```c title="lb_start 使用示例"
...
if (lb_start(1,"trascoding;conference")) {
	# 目标 URI 指向新目标
	xlog("发送呼叫到 $du\n");
	t_relay();
	exit;
}
...
```


#### lb_next([attrs])


用于获取下一个可用（且负载较轻）
		目标的函数。您需要有一个正在进行的 LB 会话（使用
		lb_start() 启动）。


此函数主要用于为 LB
		目标实现故障转移。


参数含义如下：


- *attrs* (var, optional) - 一个可写变量，
			用于填充所选目标的属性。


函数可能返回：


- *1 (true)* - 如果设置了新的目标 URI，
			指向选定的目标。注意 RURI 不会
			被此函数更改。
- *-1 (false)* - 通用内部错误
			（内存分配、解析）
- *-2 (false)* - 没有可用容量
			（目标已启动并可用，但没有
			可用通道）
- *-3 (false)* - 没有更多目标可用
			（请求的资源与活动目标不匹配）


此函数可以从 REQUEST_ROUTE 和 FAILURE_ROUTE 使用。


```c title="lb_next() 使用示例"
...
if (t_check_status("(408)|(5[0-9][0-9])")) {
	/* 检查下一个可用的 LB 目标 */
	if ( lb_next() ) {
		t_on_failure("1");
		xlog("-----------新目标是 $du\n");
		t_relay();
		exit;
	}
}

...
```


#### lb_start_or_next(grp,resources[,flags],[attrs])


这是一个简化脚本的包装函数。如果没有
		正在进行的 LB 会话，它充当 lb_start()；如果有正在进行的 LB
		会话，它充当 lb_next()。


#### load_balance(grp,resources[,flags],[attrs])


lb_start_or_next() 函数的旧名称。


请注意，这将变得过时。


#### lb_reset()


用于停止并刷新当前 LB 会话的函数。如果在
		failure route 中使用此函数，并且您想停止当前 LB 会话（不再尝试
		此会话中的任何其他目标）并启动一个全新的
		会话，请使用此函数。


此函数可以从 REQUEST_ROUTE 和 FAILURE_ROUTE 使用。


```c title="lb_next() 使用示例"
...
if (t_check_status("(5[0-9][0-9])")) {
	/* 检查下一个可用的 LB 目标 */
	if ( lb_next() ) {
		t_on_failure("1");
		xlog("-----------新目标是 $du\n");
		t_relay();
		exit;
	}
} else if (t_check_status("(408)")) {
	lb_reset();
	if (lb_start(1,"conference")) {
		t_relay();
		exit;
	}
}
...
```


#### lb_is_started()


用于检查是否存在任何正在进行的 LB 会话的函数。如果有则返回 true。


此函数可以在任何类型的 route 中使用。


#### lb_disable_dst()


将当前调用的最后一个使用的目标标记为禁用。通过此函数进行的
		禁用将阻止
		目标从现在起被使用。探测机制
		可以重新启用此对等体（请参阅开头的探测部分）


此函数可以从 REQUEST_ROUTE 和 FAILURE_ROUTE 使用。


```c title="lb_disable_dst() 使用示例"
...
if (t_check_status("(408)|(5[0-9][0-9])")) {
	lb_disable_dst();
	if ( lb_next() ) {
		t_on_failure("1");
		xlog("-----------新目标是 $du\n");
		t_relay();
	} else {
		t_reply(500,"错误");
	}
}

...
```


#### lb_is_destination(ip,port,[group],[active],[attrs]])


检查给定的 IP 和 PORT 是否属于负载均衡器列表中配置的目标。如果找到且处于活动状态（请参阅
		"active" 参数），则返回 true。


此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、
		ONREPLY_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE 使用。


参数含义如下：


- *ip* (string) - 要检查的 IP
- *port* (int) - 要检查的 PORT。
			0 值表示"任意" - 将匹配任何端口。
- *group* (int, optional) - 应该在哪个 LB 组中
			查找目标；如果未指定，搜索
			将在所有组中进行。
- *active*  (int, optional)- 如果为"1"，则搜索将仅在"活动"（未禁用）目标中进行。如果
			缺失，搜索将考虑任何类型的目标。
- *attrs* (var, optional) - 一个可写变量，
			用于填充所识别目标的属性。


```c title="lb_is_destination 使用示例"
...
if (lb_is_destination($si,$sp) ) {
	# 来自 LB 目标的请求
}
...
```


#### lb_count_call(ip,port,grp,resources[,undo])


此函数将当前呼叫计为给定目标
		与某些给定资源的负载。请注意，此呼叫不会通过
		负载均衡逻辑（不会为此呼叫做出任何路由决定）；
		它只是被 LB 计为目标的 ongoing call；


参数含义如下：


- *ip* (string) - 用于识别目标
			的 IP，呼叫将被计入该目标。
- *port* (int) - 用于识别目标
			的 PORT，呼叫将被计入该目标。
- *grp* (int) - 目标组 ID；如果
			未知，"-1"将表示所有组。
- *resources* - (string) 当前呼叫所需的
			资源的分号分隔列表。
- *undo* - (int, optional) 如果设置为非零
			值，它将强制函数取消计数 -
			实际上是在当前 LB 会话中撤销此呼叫的计数；如果我们需要为
			特定资源计数呼叫然后需要取消计数，可能需要这样做。


如果正确考虑了呼叫以估计
		目标的负载，函数返回 true。


此函数可以从 REQUEST_ROUTE、BRANCH_ROUTE 和
		FAILURE_ROUTE 使用。


```c title="lb_count_call 使用示例"
...
# 也将源自 lb 目标的呼叫计为负载
if (lb_is_destination($si,$sp) ) {
	# 来自目标的入站呼叫
	lb_count_call($si,$sp,-1,"conference");
} else {
	# 到目标的出站呼叫
	if ( !load_balance(1,"conference") ) {
		send_reply(503,"不可用");
		exit();
	}
	# 目标 URI 指向新目标
	xlog("发送呼叫到 $du\n");
	t_relay();
	exit;
}
...
```


### 导出的 MI 函数


#### load_balancer:reload


替换过时的 MI 命令：*lb_reload*。


触发从数据库重新加载负载均衡数据。


MI FIFO 命令格式：


```c
		opensips-cli -x mi load_balancer:reload
		
```


#### load_balancer:resize


替换过时的 MI 命令：*lb_resize*。


更改目标的资源容量。


参数：


- *destination_id* - 目标的 ID（根据数据库）。
- *res_name* - 您要调整大小的资源名称。
- *new_capacity* - 新的资源容量。


MI FIFO 命令格式：


```c
		opensips-cli -x mi load_balancer:resize 11 voicemail 56
		
```


#### load_balancer:list


替换过时的 MI 命令：*lb_list*。


列出所有目标以及每个目标的资源和当前负载
		的最大值。


```c title="load_balancer:list 使用示例"
$ opensips-cli -x mi load_balancer:list
Destination:: sip:127.0.0.1:5100 id=1 enabled=yes auto-re=on
        Resource:: pstn max=3 load=0
        Resource:: transc max=5 load=1
        Resource:: vm max=5 load=2
Destination:: sip:127.0.0.1:5200 id=2 enabled=no auto-re=on
        Resource:: pstn max=6 load=0
        Resource:: trans max=57 load=0
        Resource:: vm max=5 load=0
```


#### load_balancer:status


替换过时的 MI 命令：*lb_status*。


获取或设置目标的状态（启用或禁用）。


参数：


- *destination_id* - 目标的 ID（根据数据库）。
- *new_status* (optional) - 如果没有给出新状态，该
				函数将返回当前状态。如果给出了新状态
				（0 - 禁用，1 - 启用），则此状态将被强制用于
				目标。


```c title="load_balancer:status 使用示例"
$ opensips-cli -x mi load_balancer:status 2
enable:: no
$ opensips-cli -x mi load_balancer:status 2 1
$ opensips-cli -x mi load_balancer:status 2
enable:: yes
```


### 导出的事件


#### E_LOAD_BALANCER_STATUS


当模块更改目标的状态时触发此事件，
			无论是通过 MI 还是探测。


参数：


- *group* - 目标组。
- *uri* - 目标 URI。
- *status* - 如果
				目标被禁用则为 *disabled*，如果
				目标正在使用则为 *enabled*。


## 开发者指南


### 可用函数


无


## 常见问题


**Q: 在哪里可以找到更多关于 OpenSIPS 的信息？**


请参阅 [https://opensips.org/](https://opensips.org/)。


**Q: 在哪里可以发布关于此模块的问题？**


首先检查您的问题是否已在我们
			的邮件列表中回答：

关于任何稳定 OpenSIPS 版本的电子邮件应发送至
			users@lists.opensips.org，关于开发版本的
			电子邮件应发送至 devel@lists.opensips.org。

如果您想保持邮件私密，请发送至
			users@lists.opensips.org。


**Q: 如何报告错误？**


请遵循以下指南：
			[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证授权。
