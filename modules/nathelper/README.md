---
title: "nathelper 模块"
description: "这是一个帮助 NAT 穿越的模块。特别地,它帮助那些没有宣告自己是对称 UA、无法确定自己公网地址的对称 UA。fix_nated_contact 使用请求的源地址:端口对重写 Contact 头字段。fix_nated_sdp 向 SDP 添加活动方向指示(标志 0x01)并更新源 IP 地址(标志 0x02)。"
---

## 管理指南


### 概述


这是一个帮助 NAT 穿越的模块。特别地,
它帮助那些没有宣告自己是对称 UA
且无法确定自己公网地址的对称 UA。fix_nated_contact
使用请求的源地址:端口对重写 Contact 头字段。
fix_nated_sdp 向 SDP 添加活动方向指示(标志
0x01)并更新源 IP 地址(标志 0x02)。


自 2.2 版本起,nathelper 支持有状态的 ping(仅 SIP Ping)。
这允许您在 *max_pings_lost* 个 ping 未响应时从 usrloc 位置表中删除联系人,
每个 ping 的响应超时为 *ping_threshold* 秒。
要使用此功能,联系人在插入位置表时必须设置
*remove_on_timeout_bflag* 标志。


适用于包含 SDP 部分的 multipart 消息,
但不适用于多层 multipart 消息。


### NAT ping 类型


目前,nathelper 模块支持两种类型的 NAT ping:


- *UDP 数据包* - 向联系人地址发送 4 字节(零填充)UDP
数据包。

  - *优点:* 低带宽流量,
易于由 OpenSIPS 生成;
  - *缺点:* 通过 NAT 的单向流量(入站 - 从外部到内部);由于
许多 NAT 仅在出站流量时更新绑定超时,
绑定可能会过期并关闭。
- *SIP 请求* - 向联系人地址发送无状态的 SIP 请求。

  - *优点:* 通过 NAT 的双向流量,
因为 OpenSIPS 的每个 PING 请求(入站流量)
将强制 SIP 客户端生成 SIP 回复(出站流量) - NAT 绑定将肯定保持打开。
自 2.2 版本起,您还可以选择在检测到某个阈值时从位置表中删除联系人。
  - *缺点:* 更高的带宽流量,
由 OpenSIPS 生成的时间成本更高;


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载:


- *usrloc* 模块 - 仅当要 ping NATed 联系人时。
- *clusterer* - 仅当启用 "cluster_id" 选项时。


#### 外部库或应用程序


运行 OpenSIPS 加载此模块之前必须安装以下库或应用程序:


- *无*。


### 导出的参数


#### natping_interval (integer)


向所有当前注册的 UA 发送 NAT ping 以保持其 NAT 绑定活跃的间隔时间(秒)。
值为 0 禁用此功能。


> [!NOTE]
> 启用 NAT ping 功能将强制模块绑定到 USRLOC 模块。


*默认值为 0。*


```c title="设置 natping_interval 参数"
...
modparam("nathelper", "natping_interval", 10)
...
```


#### ping_nated_only (integer)


如果设置此变量,则仅对在用户位置数据库中设置了
"behind_NAT" 标志的联系人进行 ping。


*默认值为 0。*


```c title="设置 ping_nated_only 参数"
...
modparam("nathelper", "ping_nated_only", 1)
...
```


#### natping_partitions (integer)


用于发送 ping 的分区/块数量。
一个分区意味着同时发送所有 ping。两个分区
意味着先发送一半 ping,然后再发送另一半。


*默认值为 1。*
*最大允许值为 8。*


```c title="设置 natping_partitions 参数"
...
modparam("nathelper", "natping_partitions", 4)
...
```


#### natping_socket (string)


将 natping 的源 IP 欺骗为此地址。仅适用于 IPv4。


*默认值为 NULL。*


```c title="设置 natping_socket 参数"
...
modparam("nathelper", "natping_socket", "192.168.1.1:5006")
...
```


#### received_avp (str)


用于存储包含接收到的 IP、端口和协议的 URI 的属性-值对(AVP)名称。
该 URI 由 [fix nated register](#func_fix_nated_register) 函数创建,
registrar 模块随后可以获取此数据,
并向注册信息附加 "Received=" 属性。当您更改此参数的值时,
不要忘记更改 [registrar](../registrar) 模块中相应参数的值。


> [!NOTE]
> 如果您使用 [fix nated register](#func_fix_nated_register),则必须设置此参数。
此外,如果您使用的是 registrar,则还必须将其对称的
[received_avp](../registrar#received_avp) 模块参数
设置为**相同的值**。


*默认值为 "NULL"(禁用)。*


```c title="设置 received_avp 参数"
...
modparam("nathelper", "received_avp", "$avp(received)")
...
```


#### force_socket (string)


用于 ping 没有本地套接字信息的联系人(本地套接字信息可能在重启或联系人复制期间丢失)。
如果未指定,OpenSIPS 将选择与目标协议和
AF 族匹配的第一个监听接口。


*默认值为 "NULL"。*


```c title="设置 force_socket 参数"
...
modparam("nathelper", "force_socket", "localhost:33333")
...
```


#### sipping_bflag (string)


模块使用什么分支标志来识别 NATed 联系人,
以便通过 SIP 请求而不是虚拟 UDP 数据包执行 NAT ping。


*默认值为 NULL(禁用)。*


```c title="设置 sipping_bflag 参数"
...
modparam("nathelper", "sipping_bflag", "SIPPING_ENABLE")
...
```


#### remove_on_timeout_bflag (string)


使用什么分支标志来激活 usrloc 联系人移除,
当 [ping threshold](#param_ping_threshold) 超过时。


*默认值为 NULL(禁用)。*


```c title="设置 remove_on_timeout_bflag 参数"
...
modparam("nathelper", "remove_on_timeout_bflag", "SIPPING_RTO")
...
```


#### sipping_latency_flag (string)


分支标志,用于启用通过 usrloc E_UL_LATENCY_UPDATE
事件进行的联系人 ping 延迟计算和报告。


*默认值为 NULL(禁用)。*


```c title="设置 sipping_latency_flag 参数"
...
modparam("nathelper", "sipping_latency_flag", "SIPPING_CALC_LATENCY")
...
```


#### sipping_ignore_rpl_codes (CSV 字符串)


逗号分隔的 SIP 回复状态代码列表,
对于这些代码的联系人 ping 将被丢弃。
这对于"完全共享"用户位置拓扑可能有用,
其中位置节点不直接面向 UA,
因此中间 SIP 组件可能对离线联系人 ping 尝试生成回复(如 408 - Request Timeout) -- 这些 ping 回复应被忽略。


*默认值为 "NULL"(接受所有回复状态代码)。*


```c title="设置 sipping_ignore_rpl_codes 参数"
...
modparam("nathelper", "sipping_ignore_rpl_codes", "408, 480, 404")
...
```


#### sipping_from (string)


该参数设置用于生成 SIP 请求进行 NAT ping 的 SIP URI。
要启用 SIP 请求 ping 功能,您必须设置此参数。
SIP 请求 ping 仅用于标记为如此的请求。


*默认值为 "NULL"。*


```c title="设置 sipping_from 参数"
...
modparam("nathelper", "sipping_from", "sip:pinger@siphub.net")
...
```


#### sipping_method (string)


该参数设置用于生成 SIP 请求进行 NAT ping 的 SIP 方法。


*默认值为 "OPTIONS"。*


```c title="设置 sipping_method 参数"
...
modparam("nathelper", "sipping_method", "INFO")
...
```


#### nortpproxy_str (string)


该参数设置 nathelper 用于标记数据包 SDP 信息已被修改的 SDP 属性。


如果为空字符串,则不会添加或检查任何标记。


> [!NOTE]
> 该字符串必须是完整的 SDP 行,包括 EOH(\r\n)。


*默认值为 "a=nortpproxy:yes\r\n"。*


```c title="设置 nortpproxy_str 参数"
...
modparam("nathelper", "nortpproxy_str", "a=sdpmangled:yes\r\n")
...
```


#### natping_tcp (integer)


如果设置该标志,TCP/TLS 客户端也将通过 SIP OPTIONS 消息进行 ping。


*默认值为 0(未设置)。*


```c title="设置 natping_tcp 参数"
...
modparam("nathelper", "natping_tcp", 1)
...
```


#### oldip_skip (string)


该参数指定是否将旧媒体 IP 和旧起源 IP 放入 sdp 正文中。
该参数有两个值:
'o'("a=oldoip" 字段将被跳过)和 'c'("a=oldcip" 字段
将被跳过)。


*默认值为 0(未设置)。*


```c title="设置 oldip_skip 参数"
...
modparam("nathelper", "oldip_skip", "oc")
...
```


#### ping_threshold (int)


如果联系人在 ping 发送后的 *ping_threshold*
秒内未响应,则在 [max pings lost](#param_max_pings_lost) 个未响应 ping 后,
该联系人将从位置表中删除。


*默认值为 3(秒)。*


```c title="设置 ping_threshold 参数"
...
modparam("nathelper", "ping_threshold", 10)
...
```


#### max_pings_lost (int)


未响应 ping 的数量,超过该数量联系人将从位置表中删除。


*默认值为 3(ping)。*


```c title="设置 max_pings_lost 参数"
...
modparam("nathelper", "max_pings_lost", 5)
...
```


#### cluster_id (integer)


模块所属集群的 ID。集群支持由 nathelper 模块用于控制 ping 过程。
当作为多个节点的集群的一部分时,节点可以商定哪个节点
负责 ping。


可以使用带共享标签的集群来控制集群中的哪个节点将对联系人执行 ping/探测。
请参阅 [cluster sharing tag](#param_cluster_sharing_tag) 选项。


有关如何定义和填充集群(使用 OpenSIPS 节点)的更多信息,请参阅 "clusterer" 模块。


*默认值为 "0(无)。"*


```c title="设置 cluster_id 参数"
...
# 成为集群 ID 9 的一部分
modparam("nathelper", "cluster_id", 9)
...
```


#### cluster_sharing_tag (string)


共享标签的名称(按 clusterer 模块定义)用于控制哪个节点负责对联系人执行 ping。
如果定义,则只有具有此标签活动状态的节点将执行 ping。


此选项必须定义 [cluster id](#param_cluster_id) 才能工作。


这是一个可选参数。如果未设置,集群中的所有节点将单独执行 ping。


*默认值为 "空(无)。"*


```c title="设置 cluster_sharing_tag 参数"
...
# 只有具有活动 "vip" 共享标签的节点将执行 ping
modparam("nathelper", "cluster_id", 9)
modparam("nathelper", "cluster_sharing_tag", "vip")
...
```


### 导出的函数


#### fix_nated_contact([uri_params [, flags]])


重写 URI Contact HF 以包含请求的源地址:端口。
如果提供了 URI 参数列表,它将被添加到修改后的联系人;


*重要提示:* 此函数所做的更改在异步恢复路由中不可见。
因此,请确保在所有需要修复联系人的恢复路由中调用它。


参数:


- *uri_params (string, 可选)*
- *flags (string, 可选)* - CSV 标志列表:
					
					*preserve-uri* - 添加一个名为 "org" 的额外 Contact URI
参数。org 值是原始 Contact URI host:port 部分的 Base64 编码。
将其与 `restore_nated_ruri()` 配对以恢复
原始 host:port 到 R-URI。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE。


```c title="fix_nated_contact 用法"
...
if (search("User-Agent: Cisco ATA.*") {
    fix_nated_contact(";ata=cisco", "preserve-uri");
} else {
    fix_nated_contact();
}
...
```


#### fix_nated_sdp(flags [, ip_address [, sdp_fields]])


修改 SDP 信息以促进 NAT 穿越。可通过
"flags" 参数控制执行哪些更改。
自 1.12 版本起,旧 IP 字段的名称为 "a=oldoip"(旧起源 IP)和 "a=oldcip"(旧媒体 IP)。


参数含义如下:


- *flags (string)* - 值可以是
以下标志的 CSV:

  - *add-dir-active* - (旧
标志 *0x01*) 添加
"a=direction:active" SDP 行;
  - *rewrite-media-ip* - (旧
标志 *0x02*) 重写媒体
IP 地址(c=)为消息的源地址
或提供的 IP 地址(提供的 IP 地址优先于源地址)。
  - *add-no-rtpproxy* - (旧
标志 *0x04*) 添加
"a=nortpproxy:yes" SDP 行;
  - *rewrite-origin-ip* - (旧
标志 *0x08*) 重写
起源描述(o=)中的 IP 为消息的源地址
或提供的 IP 地址(提供的 IP 地址优先于源地址)。
  - *rewrite-null-ips* - (旧
标志 *0x10*) 强制重写
空媒体 IP 和/或起源 IP 地址。
如果没有此标志,空 IP 保持不变。
- *ip_address (string, 可选)* - 用于重写 SDP 的 IP。
如果未指定,将使用接收到的信令 IP。
注意:要使用该 IP,您需要使用 0x02 或 0x08 标志,
否则它将不起作用。
- *sdp_fields (string, 可选)* - 要附加到 SDP 的 SDP 字段。
注意:每个 SDP 字段必须以 "\r\n" 为前缀。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
FAILURE_ROUTE、BRANCH_ROUTE。


```c title="fix_nated_sdp 用法"
...
# 添加 "a=direction:active" SDP 行
# 重写媒体 IP(c= 行)
# 添加额外的 "a=x-attr1" SDP 行
# 添加额外的 "a=x-attr2" SDP 行
if (search("User-Agent: Cisco ATA.*")
    {fix_nated_sdp(3,,"\r\na=x-attr1\r\na=x-attr2");};
...
```


#### add_rcv_param([flag]),


向 Contact 头字段或 Contact URI 添加 received 参数。
该参数将包含根据包含 SIP 消息的数据包的源 IP、端口和协议创建的 URI。
然后该参数可由另一个 registrar 处理,例如,
当使用 t_replicate 函数将注册消息复制到另一个 registrar 时。


参数含义如下:


- *flag (int, 可选)* - 标志,指示是否
应将参数添加到 Contact URI 或 Contact 头。
如果标志非零,参数将被添加到 Contact URI。
如果未使用或等于零,参数将进入 Contact 头。


此函数可用于 REQUEST_ROUTE。


```c title="add_rcv_paramer 用法"
...
add_rcv_param(); # 将参数添加到 Contact 头
....
add_rcv_param(1); # 将参数添加到 Contact URI
...
```


#### fix_nated_register()


该函数创建一个由源 IP、端口和协议组成的 URI,
并将其存储在 [received avp](#param_received_avp) AVP 中。
该 URI 将作为 "received" 参数附加到 200 OK 的 Contact 中,
如果相同的 AVP 也为 [registrar](../registrar) 模块配置,
则也可以存储在用户位置数据库中。


此函数可用于 REQUEST_ROUTE。


```c title="fix_nated_register 用法"
...
fix_nated_register();
...
```


#### nat_uac_test(flags)


使用一个或多个预定义检查来确定收到的 SIP 消息是否来自 NAT 后面。


*flags* (string) 参数表示要执行的检查的逗号分隔列表,
如下所示:


- *private-contact* - (旧 *1* 标志)
在 Contact 头字段中搜索 RFC1918 / RFC6598 地址的出现
- *diff-ip-src-via* - (旧 *2* 标志)
使用 "received" 测试:将 Via 中的地址与信令源 IP 地址进行比较
- *private-via* - (旧 *4* 标志)
在最顶层 VIA 中搜索 RFC1918 / RFC6598 地址的出现
- *private-sdp* - (旧 *8* 标志)
在 SDP 中搜索 RFC1918 / RFC6598 地址的出现
- *diff-port-src-via* - (旧 *16*
标志) 测试源端口是否与 Via 中的端口不同
- *diff-ip-src-contact* - (旧 *32*
标志) 将 Contact 中的地址与信令源 IP 地址进行比较
- *diff-port-src-contact* - (旧 *64*
标志) 将 Contact 中的端口与信令源端口进行比较
- *carrier-grade-nat* - (旧 *128*
标志) 也在 *Contact*、*Via* 和 *SDP* 的检查中包含 RFC 6333 地址


**如果任何测试通过则返回 true**。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE。


```c title="nat_uac_test 用法"
...
# 检查私有 Contact 或 SDP 媒体 IP 地址
if (nat_uac_test("private-contact,private-sdp"))
	xlog("SIP 消息在 NAT 后面(Call-ID: $ci)\n");
...
```


#### restore_nated_ruri()


从 `fix_nated_contact("...", "preserve-uri")`
生成的 "org" URI 参数恢复原始 R-URI host:port。


如果错误或 R-URI 中不存在 "org",则返回 -1。
成功时,从 R-URI 中移除 "org" 后返回 1,
并将结果 R-URI 存储到 D-URI,
从 "org" 解码原始 host:port,
并用解码值重写 R-URI host:port。


此函数可用于 REQUEST_ROUTE、BRANCH_ROUTE。


### 导出的 MI 函数


#### nathelper:enable_ping


替代已废弃的 MI 命令: *nh_enable_ping*。


获取或设置 natping 状态。


参数:


- *status* (可选) - 如果未提供,函数
返回当前 natping 状态。否则,如果参数值大于 0 则启用 natping,
如果参数值为 0 则禁用 natping。


```c title="nathelper:enable_ping 用法"
...
$ opensips-cli -x mi nathelper:enable_ping
Status:: 1
$
$ opensips-cli -x mi nathelper:enable_ping 0
$
$ opensips-cli -x mi nathelper:enable_ping
Status:: 0
$
...
			
```


## 常见问题


**Q: 在哪里可以找到更多关于 OpenSIPS 的信息?**


请查看 [https://opensips.org/](https://opensips.org/)。


**Q: 我可以在哪里发布关于这个模块的问题?**


首先检查您的问题是否已在我们的邮件列表中得到解答:

与任何稳定 OpenSIPS 版本相关的电子邮件应发送至 
users@lists.opensips.org,与开发版本相关的电子邮件应发送至 devel@lists.opensips.org。

如果您想保持邮件私密,请发送至 users@lists.opensips.org。


**Q: 如何报告错误?**


请遵循以下指南:
[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)均采用知识共享许可证 4.0 版授权
