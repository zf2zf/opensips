---
title: "CLUSTERER 模块"
description: "*clusterer* 模块用于将多个 OpenSIPS 实例组织成组（集群），集群中的节点可以相互通信以复制、共享信息或执行分布式任务。分布式逻辑由使用 *clusterer* 接口的不同模块执行（即 *dialog* 模块可以复制对话框/概要，*ratelimit* 模块可以跨多个实例共享管道等），或在脚本级别执行。*clusterer* 模块本身仅提供发送/接收 BIN 数据包的接口以及获取节点可用性通知。它通过内部学习集群拓扑和节点状态来实现这一点。通过数据库或配置脚本配置集群中的节点。可以通过 MI 接口发送命令来检查和触发重新加载节点相关信息。"
---

## 管理指南


### 概述


*clusterer* 模块用于将多个 OpenSIPS 实例组织成组（集群），集群中的节点可以相互通信以复制、共享信息或执行分布式任务。分布式逻辑由使用 *clusterer* 接口的不同模块执行（即 *dialog* 模块可以复制对话框/概要，*ratelimit* 模块可以跨多个实例共享管道等），或在脚本级别执行。*clusterer* 模块本身仅提供发送/接收 BIN 数据包的接口以及获取节点可用性通知。它通过内部学习集群拓扑和节点状态来实现这一点。通过数据库或配置脚本配置集群中的节点。可以通过 MI 接口发送命令来检查和触发重新加载节点相关信息。


*clusterer* 模块建立的拓扑是一个节点叠加层，其中"链接"表示 BIN 接口级别的通信可用性。为此，使用了一种探测机制，包括定期 ping 集群中的所有节点，必须在给定间隔内收到回复。集群中的所有节点交换关于其与其他节点的链路状态的信息，并计算一个"路由表"，该表为每个目的地提供下一跳。最短路径的度量是跳数。当没有到目的地的直接链路时，模块发送的 BIN 数据包会通过集群透明地路由。


请注意，一个 OpenSIPS 实例可以属于多个集群，分别通信并为每个集群建立拓扑。为了在数据库或脚本中配置，每个节点在全球级别有一个唯一的 ID，可以在每个集群中引用。


如果不需要数据库配置，OpenSIPS 实例可以动态学习集群中的所有节点。只需在脚本中定义至少一个邻居即可发现所有集群组件。


### 能力层


clusterer 模块还跟踪节点在数据同步方面的状态，用于其他模块在顶部实现的功能（或"能力"）。某些能力需要从集群中具有完整数据集的有效"供体"节点进行完整数据同步（在 OpenSIPS 启动时或通过 MI 在运行时）。此外，能力可以查询 clusterer 模块，以便仅将某些分布式逻辑划分到集群中已同步的节点上。


集群中的每个节点以空数据集启动，并尝试找一个合适的节点从中拉取数据。为了帮助"引导"集群，应定义一个"种子"节点。这是通过将 **flags** 列在 clusterer 表中的值设置为 *seed* 来完成的（或在 *my_node_info* 参数中具有相同名称的属性）。种子节点将在可配置间隔后简单地回退到"同步"状态（[seed fallback interval](#param_seed_fallback_interval) 参数）。请注意，此机制仅在启动时同步数据的能力需要，因此请查看相应模块的文档。


clusterer 模块透明地将 clusterer 表中的 *sip_addr* 列（或 *my_node_info* 参数中相同名称的属性）暴露给上面的模块，因此请查看相应模块的文档以了解此节点相关信息的使用。


### 集群桥接复制


*（在 OpenSIPS 4.0 中添加）*


集群桥接复制（或"桥接复制"）允许模块跨*不同*集群交换数据。这意味着是一个拓扑/数据流优化功能，在某些具有多个数据中心的 OpenSIPS 集群设置中可能有用。在这种情况下，可能需要最小化 DC 间复制通道的数量，例如：


```c
      之前（标准，全网状复制）：

                    DC #1         DC #2
                          WAN link
                      A <─────────> C
                      ^ \        /  ^
                      │   \   /     │         4 个 OpenSIPS 节点，1 个集群
                      │      X      │       （8 个 DC 间复制通道）
                      │    /   \    │         AC, AD, BC, BD, CA, CB, DA, DB
                      v  /       \  v
                      B <─────────> D
                          WAN link
                       cluster_id: 1

      之后（集群桥接复制）：

                    DC #1         DC #2
                          WAN link
                      A ──────────> C
                      ^             ^
                      │             │          4 个 OpenSIPS 节点，2 个集群
                      │             │       （2 个 DC 间复制通道）
                      │             │                   AC, DB
                      v             v
                      B <────────── D
                          WAN link
            cluster_id: 1           cluster_id: 2
            sender: 
```


*添加了一个新表* 来表示集群间复制桥接，名为 [clusterer_bridge](#param_db_bridge_table)：


```c
    mysql> select * from clusterer_bridge;
    +----+-----------+-----------+------------+-------------------------------+
    | id | cluster_a | cluster_b | send_shtag | dst_node_csv                  |
    +----+-----------+-----------+------------+-------------------------------+
    |  1 |         1 |         2 | wan1       | bin:10.0.0.213,bin:10.0.0.214 |
    |  2 |         2 |         1 | wan1       | bin:10.0.0.210,bin:10.0.0.212 |
    +----+-----------+-----------+------------+-------------------------------+
    2 rows in set (0,00 sec)
			
```


*集群"1"和"2"之间双向桥接的示例。*


"send_shtag" 控制表中定义的每个集群桥接的发起节点。只有具有"active"标签的节点才会实际通过网络发送数据。可以使用 [sharing tag](#param_sharing_tag) 模块参数定义共享标签。


"dst_node_csv" 充当要尝试的远程集群节点列表。该模块将为每个节点尝试一次 TCP 发送，按故障转移方式（始终相同顺序）。


在撰写本文时，使用新桥接复制功能的唯一模块是 [ratelimit](../ratelimit#bridge_replication)，以优化其"CPS 管道广播"复制机制。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *数据库模块* - 如果 [db mode](#param_db_mode) 为 *1*。
- *proto_bin 模块*。


#### 外部库或应用程序


以下库或应用程序必须在运行加载了此模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### my_node_id


本地实例的 ID。此参数必须等于数据库中 *node_id* 字段之一。


*没有默认值。此参数必须明确设置为大于零的值。*


```c title="设置 my_node_id 参数"
...
modparam("clusterer", "my_node_id", 1)
...
			
```


#### db_mode


指定是否应从数据库加载本地实例的节点信息以及集群中其他实例的信息，或者在脚本中配置（见 [my node info](#param_my_node_info) 和 [neighbor node info](#param_neighbor_node_info)）。值为 "0" 表示不使用 DB，节点信息方面的集群拓扑将在运行时动态发现。


如果启用了 DB 模式，则此实例仅接受数据库中定义的节点。


*默认值为 "1"*


```c title="设置 db_mode 参数"
...
modparam("clusterer", "db_mode", 0)
...
			
```


#### db_url


数据库 URL。


*默认值为 "NULL"。*


```c title="设置 db_url 参数"
...
modparam("clusterer", "db_url",
	"mysql://opensips:opensipsrw@localhost/opensips")
...
			
```


#### db_table


存储集群信息的表名。


*默认值为 "clusterer"。*


```c title="设置 db_table 参数"
...
modparam("clusterer", "db_table", "clusterer")
...
			
```


#### db_bridge_table


存储集群间桥接定义的表名。


*默认值为 "clusterer_bridge"。*


```c title="设置 db_bridge_table 参数"
...
modparam("clusterer", "db_bridge_table", "clusterer_bridge")
...
			
```


#### sharing_tag


共享标签的定义。共享标签由 clusterer 模块管理，但可以被构建在 clusterer 引擎之上的任何模块（如 dialog 或 presence）使用（就读取其状态而言）。


请注意，其他标签可能在运行时通过与集群中其他节点的集群通信动态学习。


此值的格式为 "tag_name / cluster_id = active/backup"。


允许多次定义此参数。默认值为 "none"。


```c title="设置 sharing_tag 参数"
...
modparam("clusterer", "sharing_tag", "vip1/2=active")
modparam("clusterer", "sharing_tag", "node/10=backup")
...
```


#### my_node_info


与 clusterer DB 表中对应于本地实例的行类似节点规范。此参数可以设置多次以将本地节点包含在多个集群中。


参数格式：多个 "*prop=value*" 属性定义用 ',' 分隔，属性名称与 DB 列名相同。至少必须定义 *cluster_id* 和 *url* 属性。


如果 [db mode](#param_db_mode) 设置为 "0"，则需要此参数以便在动态节点学习过程中正确通告关于本地实例的信息。


```c title="设置 my_node_info 参数"
...
modparam("clusterer", "my_node_info", "cluster_id=1, url=bin:192.168.0.5:5566")
...
			
```


#### neighbor_node_info


与 clusterer DB 表中对应于集群中另一个实例的行类似的节点规范。此节点将是本地实例在动态节点学习过程中进入集群的入口点。此参数可以设置多次以定义多个要连接的邻居（或同一邻居但在不同集群中）。


参数格式：多个 "*prop=value*" 属性定义用 ',' 分隔，属性名称与 DB 列名相同。至少必须定义 *cluster_id*、*node_id* 和 *url* 属性。


如果 [db mode](#param_db_mode) 设置为 *0*，则应至少设置一次此参数以便正确学习集群拓扑。如果未设置，唯一学习节点拓扑的方式是通过其他节点连接到本地实例。


```c title="设置 neighbor_node_info 参数"
...
modparam("clusterer", "neighbor_node_info", "cluster_id=1,node_id=2,url=bin:192.168.0.6:5566")
...
			
```


#### ping_interval


向邻居节点发送定期 ping 之间的间隔（秒）。


*默认值为 "4"*


```c title="设置 ping_interval 参数"
...
modparam("clusterer", "ping_interval", 1)
...
			
```


#### ping_timeout


在重试或认为与邻居节点的链路中断之前等待先前发送的 ping 回复的时间（毫秒）。这也是发送失败时连续重试之间的间隔。


*默认值为 "1000"*


```c title="设置 ping_timeout 参数"
...
modparam("clusterer", "ping_timeout", 500)
...
			
```


#### node_timeout


在重启失败节点的 ping 之前等待的时间（秒）。


*默认值为 "60"*


```c title="设置 node_timeout 参数"
...
modparam("clusterer", "node_timeout", 10)
...
			
```


#### seed_fallback_interval


仅与"种子"节点相关。在节点重启或 MI 集群同步命令后，在回退到"同步"状态之前等待合适供体节点的时间（秒）。


*默认值为 "5"。*


```c title="设置 seed_fallback_interval 参数"
...
modparam("clusterer", "seed_fallback_interval", 10)
...
			
```


#### sync_timeout


自上次收到同步数据包以来经过的秒数，超过此时间将认为同步过程失败并将节点恢复到未同步状态。


*默认值为 "15"。*


```c title="设置 sync_timeout 参数"
...
modparam("clusterer", "sync_timeout", 5)
...
			
```


#### sync_packet_size


执行数据同步时发送的 BIN 数据包的最大大小。这只是一个建议值，因为数据包的实际大小可能略大。


*默认值为 "65535"。*


```c title="设置 sync_packet_size 参数"
...
modparam("clusterer", "sync_packet_size", 32765)
...
			
```


#### dispatch_jobs


启用将作业（处理复制的数据包）从接收 TCP 工作进程分派到空闲 opensips 工作进程（包括 UDP、定时器进程等）。


这通常会提高在高流量场景中处理复制包的性能，不应禁用。


尽管如此，在某些情况下会出现"雷鸣般的群体"问题，导致 CPU 负载异常高。禁用此分派机制可以解决此类问题。


*默认值为 "1"（启用）。*


```c title="设置 dispatch_jobs 参数"
...
modparam("clusterer", "dispatch_jobs", 0)
...
			
```


#### id_col


存储表行 ID 的列名。


*默认值为 "id"。*


```c title="设置 id_col 参数"
...
modparam("clusterer", "id_col", "id")
...
			
```


#### cluster_id_col


存储集群 ID 的列名。


*默认值为 "cluster_id"。*


```c title="设置 cluster_id_col 参数"
...
modparam("clusterer", "cluster_id_col", "cluster_id")
...
			
```


#### node_id_col


存储实例 ID 的列名。值必须大于 0。


*默认值为 "node_id"。*


```c title="设置 node_id_col 参数"
...
modparam("clusterer", "node_id_col", "node_id")
...
			
```


#### url_col


包含实例 URL 的列名。值必须大于 0。


*默认值为 "url"。*


```c title="设置 url_col 参数"
...
modparam("clusterer", "url_col", "url")
...
			
```


#### state_col


存储节点状态（启用/禁用）的列名。


*默认值为 "state"。*


```c title="设置 state_col 参数"
...
modparam("clusterer", "state_col", "state")
...
			
```


#### no_ping_retries_col


包含在认为与邻居节点的链路中断之前最大 ping 重试次数的列名。


*默认值为 "no_ping_retries"。*


```c title="设置 no_ping_retries_col 参数"
...
modparam("clusterer", "no_ping_retries_col", "no_ping_retries")
...
			
```


#### priority_col


存储节点优先级的列名，在重新路由消息时，当相同长度（跳数）的路径时选择下一跳。


*默认值为 "priority"。*


```c title="设置 priority_col 参数"
...
modparam("clusterer", "priority_col", "priority")
...
			
```


#### sip_addr_col


包含节点 SIP 地址的列名。


*默认值为 "sip_addr"。*


```c title="设置 sip_addr_col 参数"
...
modparam("clusterer", "sip_addr_col", "sip_addr")
...
			
```


#### flags_col


包含节点标志的列名。


*默认值为 "flags"。*


```c title="设置 flags_col 参数"
...
modparam("clusterer", "flags_col", "flags")
...
			
```


#### description_col


包含节点描述的列名。


*默认值为 "description"。*


```c title="设置 description_col 参数"
...
modparam("clusterer", "description_col", "description")
...
			
```


#### enable_stats (integer)


是否应启用统计支持。通过统计变量，模块提供有关集群节点的信息。将其设置为零以禁用，非零以启用。


*默认值为 "1（启用）"。*


```c title="设置 enable_stats 参数"
...
modparam("clusterer", "enable_stats", 0)
...
					
```


#### enable_rerouting (integer)


如果到目的地的直接路由不可用，数据包是否应通过另一个节点重新路由。在双节点拓扑中禁用可以提高稳定性。
将其设置为零以禁用，非零以启用。


*默认值为 "1（启用）"。*


```c title="设置 enable_rerouting 参数"
...
modparam("clusterer", "enable_rerouting", 0)
...
					
```


### 导出的函数


#### cluster_send_req(cluster_id, dst_id, msg, [tag])


此函数用于从脚本向集群中的特定节点发送包含自定义数据的通用请求类消息。该消息本身不是"请求"，但根据接收端的逻辑，该节点可以发送回复。为了将收到的回复与发出的请求相关联，该函数通过 *tag* 参数返回一个随机生成的通信标签，该标签随原始消息一起发送，可以与收到回复中的标签进行对照检查。


参数的含义如下：


- *cluster_id* (int) - 目标节点的集群 ID；
- *dst_id* (int) - 目标节点的 ID；
- *msg* (string) - 实际消息负载；
- *tag* (var, optional) - 随机生成的通信标签。


函数可以返回以下值：


- *1* - 成功发送消息到目标节点或有效下一跳
- *-1* - 本地节点已禁用，无法发送
- *-2* - 根据发现的拓扑，目标节点无法通过任何路径到达
- *-3* - 目标节点或有效下一跳似乎可以到达但发送失败或其他 OpenSIPS 内部错误


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE 和 EVENT_ROUTE。


```c title="cluster_send_req() 使用"
...
# 发送请求
cluster_send_req(1, 1, "Check USER: $fU", $var(req_tag));
# 等待回复
$avp(filter) = "tag=" + $var(req_tag);
async(wait_for_event("E_CLUSTERER_RPL_RECEIVED", $avp(filter), 5), rpl_resume);
# 完成
...
route[rpl_resume] {
  xlog("Received reply: $avp(msg)\n");
}
...
					
```


#### cluster_send_rpl(cluster_id, dst_id, msg, tag)


此函数用于从脚本向集群中的特定节点发送包含自定义数据的通用回复类消息。该消息被标记为"回复"，因此此函数应仅用于回复先前收到的请求类消息。为了让最初发送请求的其他节点能够将其与此回复相关联，应将与请求一起收到的通信标签传递给函数。


参数的含义如下：


- *cluster_id* (int) - 目标节点的集群 ID；
- *dst_id* (int) - 目标节点的 ID；
- *msg* (string) - 实际消息负载；
- *tag* (var) - 通信标签。


函数可以返回以下值：


- *1* - 成功发送消息到目标节点或有效下一跳
- *-1* - 本地节点已禁用，无法发送
- *-2* - 根据发现的拓扑，目标节点无法通过任何路径到达
- *-3* - 目标节点或有效下一跳似乎可以到达但发送失败或其他 OpenSIPS 内部错误


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE 和 EVENT_ROUTE。


```c title="cluster_send_rpl() 使用"
...
event_route[E_CLUSTERER_REQ_RECEIVED] {
  cluster_send_rpl($param(cluster_id), $param(src_id), $var(my_reply), $param(tag));
}
...
					
```


#### cluster_broadcast_req(cluster_id, msg, [tag], [include_self])


此函数与 `cluster_send_req()` 函数类似，不同之处在于消息被发送到指定集群中的所有节点。


- *include_self* (bool, optional, default: *false*) - 也为当前节点引发事件，但不实际发送数据包（请求和回复都）。


函数可以返回以下值：


- *1* - 成功发送消息到至少一个节点；
- *-1* - 本地节点已禁用，无法发送；
- *-2* - 根据发现的拓扑，集群中所有节点都无法到达；
- *-3* - 发送给集群中所有节点失败或其他 OpenSIPS 内部错误。


参数的含义与 `cluster_send_req()` 相同。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE 和 EVENT_ROUTE。


```c title="cluster_broadcast_req() 使用"
...
# 也为当前节点引发事件
cluster_broadcast_req($var(cl_id), $var(share_data), , true);
...
					
```


#### cluster_check_addr(cluster_id, ip, addr_type)


此函数检查给定 IP 地址是否属于集群中的节点之一。


参数：


- *cluster_id* (int)
- *ip* (string)
- *addr_type* (string, optional) -
						选择要进行比较的节点地址，可能的值为：
						
						
							*"sip"* (default) - 节点的数据库配置 SIP 地址
						
						
							*"bin"* - 节点的 BIN 接口监听器


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE 和 EVENT_ROUTE。


```c title="cluster_check_addr() 使用"
...
if (cluster_check_addr(1, $si)) {
	...
}
...
					
```


### 导出的 MI 函数


#### clusterer:reload


替换已弃用的 MI 命令：*clusterer_reload*。


从 clusterer 数据库重新加载数据。当前建立的拓扑将丢失，节点将重新发现新拓扑。


名称：*clusterer:reload*


参数：*无*


MI FIFO 命令格式：


```c
		opensips-cli -x mi clusterer:reload
		
```


#### clusterer:list


替换已弃用的 MI 命令：*clusterer_list*。


列出有关每个集群中其他节点的信息（节点 ID、URL、与该节点的链路状态等）。


名称：*clusterer:list*


参数：*无*


```c title="clusterer:list 使用"
$ opensips-cli -x mi clusterer:list
{
    "Clusters": [
        {
            "cluster_id": 1,
            "Nodes": [
                {
                    "node_id": 1,
                    "db_id": 1,
                    "url": "bin:127.0.0.1",
                    "link_state": "Up",
                    "next_hop": "1",
                    "description": "none"
                }
            ]
        }
    ]
}
```


#### clusterer:list_topology


替换已弃用的 MI 命令：*clusterer_list_topology*。


从本地节点的角度列出每个集群的拓扑作为邻接表。如果节点的链路处于活动状态，则该节点显示为邻居。


请注意，如果节点 ID 出现在多个集群中，它指的是属于不同集群的同一实例，它有不同的拓扑。


名称：*clusterer:list_topology*


参数：*无*


```c title="clusterer:list_topology 使用"
$ opensips-cli -x mi clusterer:list_topology
{
    "Clusters": [
        {
            "cluster_id": 1,
            "Nodes": [
                {
                    "node_id": 2,
                    "Neighbours": [
                        1
                    ]
                },
                {
                    "node_id": 1,
                    "Neighbours": [
                        2
                    ]
                }
            ]
        }
    ]
}
```


#### clusterer:set_status


替换已弃用的 MI 命令：*clusterer_set_status*。


设置节点的状态（启用/禁用）。如果本地实例被禁用，节点将不发送任何消息并忽略收到的消息，从而在拓扑中显得像是一个失败的节点（从其他节点的角度看）。如果不同的节点被禁用，指定节点将在发送/接收任何消息方面被本地实例简单忽略，就好像不再是拓扑的一部分。


名称：*clusterer:set_status*


参数：


- *cluster_id* - 指示集群的 ID。
- *node_id* (optional) - 指示要禁用的节点的 ID。如果缺失，本地实例将被禁用。
- *status* - 指示新状态（0 - 禁用，1 - 启用）。


MI FIFO 命令格式：


```c
		# 禁用本地实例
		opensips-cli -x mi clusterer:set_status 1 0
		# 禁用节点 ID 3
		opensips-cli -x mi clusterer:set_status 1 3 0
		
```


#### clusterer:remove_node


替换已弃用的 MI 命令：*clusterer_remove_node*。


从集群拓扑中移除节点。只需在一个节点上运行函数即可从集群中所有其他节点移除目标节点。如果要移除的节点在触发此函数时正在运行，它将自动被禁用（等同于在该特定节点上运行 [mi set status](#mi_set_status)）。


此函数仅在 [db mode](#param_db_mode) 设置为 *0*（禁用）时可用。


名称：*clusterer:remove_node*


参数：


- *cluster_id* - 集群 ID
- *node_id* - 要移除的节点的 ID。


MI FIFO 命令格式：


```c
		opensips-cli -x mi clusterer:remove_node 1 3
		
```


#### clusterer:send_mi


替换已弃用的 MI 命令：*cluster_send_mi*。


分派给定的 MI 命令在集群中的特定节点上运行。


名称：*clusterer:send_mi*


参数：


- *cluster_id* - 集群的 ID。
- *destination* - 目标节点的 ID
- *cmd_name* - 要运行的 MI 命令的名称
- *cmd_params* (optional) - 要运行的 MI 命令的参数数组


请注意，目前不支持需要命名参数或数组作为参数值的 MI 命令。


MI FIFO 命令格式：


```c
opensips-cli -x mi clusterer:send_mi 1 3 lb_reload
		
```


#### clusterer:broadcast_mi


替换已弃用的 MI 命令：*cluster_broadcast_mi*。


分派给定的 MI 命令在集群中的所有节点上运行。该命令也在本地执行。


名称：*clusterer:broadcast_mi*


参数：


- *cluster_id* - 集群的 ID。
- *cmd_name* - 要运行的 MI 命令的名称
- *cmd_params* (optional) - 要运行的 MI 命令的参数数组


请注意，目前不支持需要命名参数或数组作为参数值的 MI 命令。


MI FIFO 命令格式：


```c
opensips-cli -x mi clusterer:broadcast_mi 1 dr_reload partition_5
		
```


#### clusterer:list_cap


替换已弃用的 MI 命令：*clusterer_list_cap*。


列出已注册的能力及其状态。


名称：*clusterer:list_cap*


参数：*无*


```c title="clusterer:list_cap 使用"
$ opensips-cli -x mi clusterer:list_cap
{
    "Clusters": [
        {
            "cluster_id": 1,
            "Capabilities": [
                {
                    "name": "dialog-dlg-repl",
                    "state": "Ok",
                    "enabled": "yes"
                },
                {
                    "name": "dialog-prof-repl",
                    "state": "Ok",
                    "enabled": "yes"
                }
            ]
        }
    ]
}
```


#### clusterer:set_cap_status


替换已弃用的 MI 命令：*clusterer_set_cap_status*。


设置能力的状态（启用/禁用）。如果能力被禁用，节点将不发送属于该能力的任何复制/同步消息。同样，收到 messages 将被丢弃。而且，该能力将转换到"未同步"状态，节点将不再能够成为同步的供体。


名称：*clusterer:set_cap_status*


参数：


- *cluster_id* - 集群的 ID
- *capability* - 能力的名称，如 [mi list cap](#mi_list_cap) 所列
- *status* - 指示新状态（0 - 禁用，1 - 启用）。


MI FIFO 命令格式：


```c
		# 在集群 1 中禁用对话框复制
		opensips-cli -x mi clusterer:set_cap_status 1 dialog-dlg-repl 0
		# 在集群 2 中启用对话框概要复制
		opensips-cli -x mi clusterer:set_cap_status 2 dialog-prof-repl 1
		
```


#### clusterer:shtag_set_active


替换已弃用的 MI 命令：*clusterer_shtag_set_active*。


将给定的共享标签设置为 *active* 状态。关于此更改的信息也在集群中广播，以强制可能在 此标签上活动的任何其他节点降为 backup。


名称：*clusterer:shtag_set_active*


参数： *tag* - 要设置为活动的标签名称及其所属集群，格式为 'tag/cluster_id'。


MI FIFO 命令格式：


```c
		opensips-cli -x mi clusterer:shtag_set_active vip1/3
		
```


#### clusterer:list_shtags


替换已弃用的 MI 命令：*clusterer_list_shtags*。


列出所有已知的共享标签及其状态。


名称：*clusterer:list_shtags*


参数： *命令不带参数*


MI FIFO 命令格式：


```c
		opensips-cli -x mi clusterer:list_shtags
		
```


### 导出的脚本变量


#### $cluster.sh_tag


这是一个读/写变量，允许访问由 clusterer 模块管理的共享标签。


此类变量的名称格式为 *tag_name/cluster_id*，如 *$cluster.sh_tag(vip/3)* 访问集群 ID 3 中的名为 "vip" 的共享标签。


设置时，共享标签只能通过分配以下值切换到活动状态：


- "active"
- 1


读取时，共享标签返回：


- "active" 或 1
- "backup" 或 0


NULL 值可能仅作为内部错误的结果返回（如内存错误）。


### 导出的事件


#### E_CLUSTERER_REQ_RECEIVED


当收到通用请求类 clusterer 消息时引发此事件。此类消息直接从脚本发送，不是由 OpenSIPS 模块发送。


参数：


- *cluster_id* - 源节点的集群 ID。
- *src_id* - 源节点的 ID。
- *msg* - 实际消息负载。
- *tag* - 此消息的通信标签，由源节点生成。这可用于通过将标签提供给 `cluster_send_rpl()` 函数来发送对应于收到消息的回复。


#### E_CLUSTERER_RPL_RECEIVED


当收到通用回复类 clusterer 消息时引发此事件。此类消息直接从脚本发送，不是由 OpenSIPS 模块发送。


参数：


- *cluster_id* - 源节点的集群 ID。
- *src_id* - 源节点的 ID。
- *msg* - 实际消息负载。
- *tag* - 此消息的通信标签。这可用于将通过 `cluster_send_req()` 或 `cluster_broadcast_req()` 函数发送的请求与收到的回复进行匹配。


#### E_CLUSTERER_NODE_STATE_CHANGED


当节点的状态在可用性方面发生变化时引发此事件。


参数：


- *cluster_id* - 集群 ID。
- *node_id* - 节点的 ID。
- *new_state* - 节点的新状态，可能的值为：0 - down，1 - up。


#### E_CLUSTERER_SHARING_TAG_CHANGED


当共享标签的状态发生变化时引发此事件。


参数：


- *name* - 共享标签的名称。
- *cluster* - 集群 ID。
- *state* - 共享标签的新状态，可能的值为："active" 或 "backup"。
- *reason* - 简短文本，描述触发状态变化的原因，如另一个节点作为活动节点、一个 MI 命令或脚本变量。


### 导出的状态/报告标识符


模块提供 *clusterer* 状态/报告组。


#### sharing_tags


提供 *sharing_tags* 标识符用于报告 sharing_tags 状态变化的报告（在 active 和 backup 之间），以及变化的原因。此标识符有 200 条记录历史，然后丢弃旧记录。


```c
{
    "Name": "sharing_tags",
    "Reports": [
        {
            "Timestamp": 1652367224,
            "Date": "Thu May 12 17:53:44 2022",
            "Log": "TAG <HA>, cluster 1, became backup due to cluster broadcast from 2"
        },
        {
            "Timestamp": 1652367326,
            "Date": "Thu May 12 17:55:26 2022",
            "Log": "TAG <HA>, cluster 1, became active due to MI command"
        }
    ]
}

	
```


#### node_states


*node_states* 标识符用于报告节点状态变化（在可用性方面）。此标识符有 200 条记录历史，然后丢弃旧记录。


```c
{
    "Name": "node_states",
    "Reports": [
        {
            "Timestamp": 1656489246,
            "Date": "Wed Jun 29 10:54:06 2022",
            "Log": "Node [2], cluster [1] is UP"
        },
        {
            "Timestamp": 1656489261,
            "Date": "Wed Jun 29 10:54:21 2022",
            "Log": "Node [2], cluster [1] is DOWN"
        }
    ]
}

	
```


#### cap:[capability_name]


注册到 clusterer 模块的每个能力都有相应的标识符，名为 *cap:[capability_name]*，用于提供该能力的数据同步状态。此状态反映同步过程的进度，可以有以下值：


- *-3* - 未同步
- *-2* - 同步待定（等待合适的供体节点或实际同步数据）
- *-1* - 同步进行中
- *1* - 已同步（同步已完成或该能力根本不需要数据同步）


```c
{
    "Name": "cap:dialog-dlg-repl",
    "Readiness": true,
    "Status": 1,
    "Details": "synced"
},
	
```


能力标识符还提供关于同步过程主要阶段的报告。这些标识符有 200 条记录历史，然后丢弃旧记录。


```c
{
    "Name": "cap:dialog-dlg-repl",
    "Reports": [
        {
            "Timestamp": 1656966903,
            "Date": "Mon Jul  4 23:35:03 2022",
            "Log": "Sync requested"
        },
        {
            "Timestamp": 1656966904,
            "Date": "Mon Jul  4 23:35:04 2022",
            "Log": "Sync started from node [1]"
        },
        {
            "Timestamp": 1656966906,
            "Date": "Mon Jul  4 23:35:06 2022",
            "Log": "Sync completed, received [10000] chunks"
        }
    ]
},

	
```


有关如何访问和使用状态/报告信息，请参阅 [状态/报告接口文档](https://docs.opensips.org/manual/3-4/interface-statusreport)。


### 使用示例


本节提供在两个 OpenSIPS 实例之间复制 ratelimit 管道的使用示例。它使用 clusterer 模块管理复制节点，并配合 *proto_bin* 模块发送复制信息。


设置拓扑很简单：我们在两台独立的机器上运行两个 OpenSIPS 节点（尽管它们也可以在同一台机器上运行）：*节点 A* 的 IP 为 192.168.0.5，*节点 B* 的 IP 为 192.168.0.6。两者除了流量监听器（UDP、TCP 等）外，还在端口 *5566* 上绑定了 BIN 监听器。这些监听器将用于二进制通信。


我们在 *clusterer* 表中插入以下内容：


```c title="示例数据库内容 - clusterer 表"
+----+------------+---------+----------------------+-------+-----------------+----------+----------+-------+-------------+
| id | cluster_id | node_id | url                  | state | no_ping_retries | priority | sip_addr | flags | description |
+----+------------+---------+----------------------+-------+-----------------+----------+----------+-------+-------------+
| 10 |          1 |       1 | bin:192.168.0.5:5566 |     1 |                3|       50 | NULL     | NULL  | Node A      |
| 20 |          1 |       2 | bin:192.168.0.6:5566 |     1 |                3|       50 | NULL     | NULL  | Node B      |
+----+------------+---------+----------------------+-------+-----------------+----------+----------+-------+-------------+
		
```


- "cluster_id" - 集群的标识符。组/集群内所有节点应有相同的 ID（在我们的示例中，两个节点都有 ID *1*）。值必须大于 0。
- "node_id" - 机器/节点的标识符，因此集群内每个实例应有不同的 ID。值必须大于 0。在我们的示例中，*节点 A* 将有 ID 1，*节点 B* 有 ID 2。
- "url" - 该实例所有 BIN 数据包将被发送到的地址。
- "state" - 节点的状态：*1* 表示启用，*0* 表示禁用。禁用的节点将不发送任何 BIN 数据包并丢弃收到的数据包。
- "no_ping_retries" - 在认为与节点的链路中断之前的最大 ping 重试次数。
- "priority" - 节点在被选为下一跳时的优先级，当重新路由消息时相同长度（跳数）的路径；在这个双节点拓扑示例中，它不相关。
- "sip_addr" - 节点的 SIP 地址，透明地提供给模块；在我们的示例中，它对 ratelimit 模块没有用处。
- "flags" - 用于定义种子节点；在我们的示例中，它没有用处。
- "description" - 用于描述节点的不透明值


在数据库中配置两个节点后，我们必须配置 OpenSIPS 的两个实例。首先，我们配置 *节点 A*：


```c title="*节点 A* 配置"
...
socket= bin:192.168.0.5:5566 # 节点 A 的 BIN 监听器

loadmodule "proto_bin.so"

loadmodule "clusterer.so"
modparam("clusterer", "db_url", "mysql://opensips@192.168.0.7/opensips")
modparam("clusterer", "my_node_id", 1) # 节点 A 的 node_id

loadmodule "ratelimit.so"
modparam("ratelimit", "pipe_replication_cluster", 1)
...
			
```


类似地，*节点 B* 的配置如下：


```c title="*节点 B* 配置"
...
socket= bin:192.168.0.6:5566 # 节点 B 的 BIN 监听器

loadmodule "proto_bin.so"

loadmodule "clusterer.so"
# 理想情况下，两个节点使用同一个数据库
modparam("clusterer", "db_url", "mysql://opensips@192.168.0.7/opensips")
modparam("clusterer", "my_node_id", 2) # 节点 B 的 node_id

loadmodule "ratelimit.so"
modparam("ratelimit", "pipe_replication_cluster", 1)
...
			
```


使用上述配置启动两个 OpenSIPS 实例后，您的平台能够以非常高效和可扩展的方式使用共享 ratelimit 管道。


### 导出的统计信息


#### clusterer_nodes


返回集群节点总数。


#### clusterer_nodes_up


返回处于 UP 状态的集群节点总数。


#### clusterer_nodes_down


返回不处于 UP 状态的集群节点总数。


## 开发者指南


### 可用函数


#### get_nodes(cluster_id)


此函数将返回指定集群中所有可达节点的列表（如果直接链路关闭/探测中，则考虑通过中间节点的路径）。


返回的节点结构：


```c
...
typedef struct clusterer_node {
    int node_id;
    union sockaddr_union addr;
    str sip_addr;
    str description;
    struct clusterer_node *next;
} clusterer_node_t;
...
        
```


参数的含义如下：


- *int cluster_id* - 集群 id


#### free_nodes(list)


此函数将释放由 *get_nodes* 返回的节点列表。


参数的含义如下：


- *clusterer_node_t *list* - 列表头


#### set_state(cluster_id, state)


此函数设置当前节点在指定集群中的状态（启用/禁用）。


参数的含义如下：


- *int cluster_id* - 集群 id
- *enum cl_node_state state* - 新状态；可能的值：

  - *STATE_DISABLED*
  - *STATE_ENABLED*


#### check_addr(cluster_id, su)


此函数检查给定地址是否属于集群中的节点之一。


参数的含义如下：


- *int cluster_id* - 集群 id
- *union sockaddr_union* su* - 套接字地址


#### get_my_id()


此函数将返回当前节点的 ID。


#### send_to(packet, cluster_id, node_id)


此函数将发送给定的 BIN 数据包到集群中的指定节点。如果直接链路关闭/探测中，如果目标节点可通过拓扑中的另一条路径到达，它将把数据包发送到中间节点。


参数的含义如下：


- *bin_packet_t packet* - 要发送的数据包
- *int cluster_id* - 集群 id
- *int node_id* - 目标节点的 id


函数返回以下值之一：


- *CLUSTERER_SEND_SUCCESS* - 成功发送数据包到目标节点或有效下一跳
- *CLUSTERER_CURR_DISABLED* - 当前节点已禁用，无法发送
- *CLUSTERER_DEST_DOWN* - 根据发现的拓扑，目标节点无法通过任何路径到达
- *CLUSTERER_SEND_ERR* - 目标节点或有效下一跳似乎可以到达但发送失败


#### send_all(packet, cluster_id)


将给定的 BIN 数据包发送到指定集群中的所有节点。该函数操作类似于 *send_to*。


参数的含义如下：


- *bin_packet_t packet* - 要发送的数据包
- *int cluster_id* - 集群 id


函数返回以下值之一：


- *CLUSTERER_SEND_SUCCESS* - 成功发送数据包到至少一个节点
- *CLUSTERER_CURR_DISABLED* - 当前节点已禁用，无法发送
- *CLUSTERER_DEST_DOWN* - 根据发现的拓扑，集群中所有节点都无法到达
- *CLUSTERER_SEND_ERR* - 发送给集群中所有节点失败


#### get_next_hop(cluster_id, node_id)


此函数返回到指定集群中给定目标节点的计算最短路径的下一跳。当直接链路与预期目标关闭时，这是 *send_to* 和 *send_all* 函数的实际目标节点。函数返回与 *get_nodes* 相同的结构。


参数的含义如下：


- *int cluster_id* - 集群 id
- *int node_id* - 要返回下一跳的目标节点的节点 id


#### free_next_hop(next_hop)


此函数将释放由 *get_next_hop* 返回的下一跳。


参数的含义如下：


- *clusterer_node_t *next_hop* - 要释放的下一跳


#### register_module(mod_name, cb, auth_check, accept_clusters_ids, no_accept_clusters)


此函数注册一个 OpenSIPS 模块以接收 BIN 数据包和集群通知。某个模块可以接受来自多个集群的数据包，并提供在收到每个数据包时调用的单个回调函数。此函数还将被调用以通知集群事件，如节点变得可达/不可达。


参数的含义如下：


- *char *mod_name* - 模块名
- *clusterer_cb_f cb* - 回调函数
- *int auth_check* - 0 - 无检查，1 - 对收到的每个 BIN 数据包检查源 IP 是否属于集群中的节点之一
- *int* accept_clusters_ids* - 接受数据包的集群 ID 数组
- *int no_accept_clusters* - accept_clusters_ids 数组的长度


回调函数原型：


```c
...
typedef void (*clusterer_cb_f)(enum clusterer_event ev,bin_packet_t *, int packet_type,
                struct receive_info *ri, int cluster_id, int src_id, int dest_id);
...
```


通过 *ev* 参数传递给回调函数的事件的可能值：


- *CLUSTER_RECV_MSG* - 收到 BIN 消息
- *CLUSTER_ROUTE_FAILED* - 路由到集群中另一节点的收到的 BIN 数据包失败
- *CLUSTER_NODE_UP* - 节点变得可达
- *CLUSTER_NODE_DOWN* - 节点变得不可达
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0 版授权
