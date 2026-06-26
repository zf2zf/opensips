---
title: "proto_hep 模块"
description: "**proto_hep** 模块是一个传输模块,实现了 hepV1 和 hepV2 基于 UDP 的通信以及 hepV3 基于 TCP 的通信。它还提供了一个 API,你可以注册回调函数,在 HEP 头解析后调用,也可以将 SIP 消息打包成 HEP 消息。解包部分由内部完成。"
---

## 管理指南


### 概述


**proto_hep** 模块是一个传输模块,实现了 hepV1 和 hepV2 基于 UDP 的通信以及 hepV3 基于 TCP 的通信。它还提供了一个 API,你可以注册回调函数,在 HEP 头解析后调用,也可以将 SIP 消息打包成 HEP 消息。解包部分由内部完成。


加载后,你可以在配置文件中定义 HEP 监听器,添加其 IP 和可选的监听端口。你可以定义 TCP、UDP 和 TLS 监听器。在 UDP 上你将能够接收 HEP v1、v2 和 v3 数据包,在 TCP 和 TLS 上只能是 HEPv3。
```c

...
#HEPv3 监听器
socket= hep_tcp:127.0.0.1:6061 		# 更改监听 IP
#HEPv1, v2, v3 监听器
socket= hep_udp:127.0.0.1:6061 		# 更改监听 IP
...
```


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载:


- *tls_mgm* - 可选,仅当脚本中定义了基于 TLS 的
				HEP 监听器时需要。


#### 外部库或应用程序


运行 OpenSIPS 加载此模块之前,必须安装以下库或应用程序:


- *无*。


### 导出的参数


#### hep_id (str)


指定 HEP 数据包的目标和使用的 HEP 协议版本。所有参数在
			**hep_id** 内必须用
			**;** 分隔。参数以键值格式给出,可能的键为
			**uri**、**transport**
			和 **version**,但目的地的
			URI 没有键,格式为 **host:port**。**transport** 键可以是
			**TCP**、**UDP** 或
			**TLS**。
			**TCP** 和 **TLS**
			仅适用于 HEP 版本 3。
			**Version** 是 hep 协议版本,
			可以是 **1**、**2**
			或 **3**。


HEPv1 和 HEPv2 只能使用 UDP。HEPv3 可以使用 TCP、UDP 和 TLS,默认设置为 TCP。如果未定义 hep 版本,默认是版本 3,使用 TCP 和 TLS。


无默认值。如果 **hep_id** 未设置,该模块
		不能用于 HEP 跟踪。


```c title="设置 hep_id 参数"
...
/* 定义一个到 localhost:8001 的目标,使用 hepV3 over tcp */
modparam("proto_hep", "hep_id",
"[hep_dst] 127.0.0.1:8001; transport=tcp; version=3")
/* 定义一个到 1.2.3.4:5000 的目标,使用 hepV2; 无传输(默认 UDP) */
modparam("proto_hep", "hep_id", "[hep_dst] 1.2.3.4:5000; version=2")
/* 仅定义目标 URI; 版本将是 3(默认),传输是 TCP(默认) */
modparam("proto_hep", "hep_id", "[hep_dst] 1.2.3.4:5000")
```


#### homer5_on (int)


指定 HEP 数据包中数据的封装方式。如果设置为
			*0*,则将使用基于 JSON 的 HOMER 6 格式。否则,
			如果设置为 *0* 以外的任何值,将使用纯文本 HOMER 5
			格式进行封装。在捕获节点上,此参数影响
			[sipcapture](../sipcapture#func_report_capture)
			模块中 *report_capture* 函数的行为。


默认值 1,HOMER5 格式。


```c title="设置 homer5_on 参数"
modparam("proto_hep", "homer5_on", 0)
```


#### homer5_delim (str)


如果 **homer5_on** 已设置
		(不等于 0),通过此参数你可以设置不同有效载荷部分之间的分隔符。


默认值为 ":"。


```c title="设置 homer5_on 参数"
modparam("proto_hep", "homer5_delim", "##")
```


#### hep_port (integer)


所有 TCP/UDP/TLS 监听器使用的默认端口。


*默认值为 5656。*


```c title="设置 hep_port 参数"
...
modparam("proto_hep", "hep_port", 6666)
...
```


#### hep_send_timeout (integer)


TCP 连接在此时间后将被关闭(如果在此间隔内无法进行阻塞写入,并且 OpenSIPS 想在其上发送数据)。


*默认值为 100 ms。*


```c title="设置 hep_send_timeout 参数"
...
modparam("proto_hep", "hep_send_timeout", 200)
...
```


#### hep_max_msg_chunks (integer)


HEP 消息通过 TCP 传输时预期的最大分片数。如果接收的数据包分片程度超过此值,则连接将被断开(要么连接严重过载导致高分片,要么我们正受到攻击,攻击者发送非常碎片化的流量以降低服务器性能)。


*默认值为 32。*


```c title="设置 hep_max_msg_chunks 参数"
...
modparam("proto_hep", "hep_max_msg_chunks", 8)
...
```


#### hep_async (integer)


指定 TCP 连接和写入操作是否应以异步模式(非阻塞连接和写入)进行。如果禁用,OpenSIPS 将阻塞并等待 TCP 操作如连接和写入。


*默认值为 1(启用)。*


```c title="设置 hep_async 参数"
...
modparam("proto_hep", "hep_async", 0)
...
```


#### hep_async_max_postponed_chunks (integer)


如果 *hep_async* 启用,此参数指定可暂存供以后/异步写入的最大 HEP 消息数。如果连接待写入超过此数量,连接将被标记为已损坏并被丢弃。


*默认值为 32。*


```c title="设置 hep_async_max_postponed_chunks 参数"
...
modparam("proto_hep", "hep_async_max_postponed_chunks", 16)
...
```


#### hep_capture_id (integer)


该参数指示 HEPv2/v3 协议的捕获代理 ID。
		限制:16 位整数。


*默认值为 "1"。*


```c title="设置 hep_capture_id 参数"
...
modparam("proto_hep", "hep_capture_id", 234)
...
```


#### hep_retry_cooldown (integer)


此参数定义在达到 hep_max_retries 设置的最大失败尝试次数后,OpenSIPS 在重试到 HEP 目标的 TCP 连接之前应等待的秒数。
		限制:16 位整数。


*默认值为 "3600"。*


```c title="设置 hep_retry_cooldown 参数"
...
modparam("proto_hep", "hep_retry_cooldown", 60)
...
```


#### hep_max_retries (integer)


此参数定义 OpenSIPS 将尝试与 HEP 目标建立 TCP 连接的最大次数。
		限制:16 位整数。


*默认值为 "5"。*


```c title="设置 hep_max_retries 参数"
...
modparam("proto_hep", "hep_max_retries", 10)
...
```


#### hep_async_local_write_timeout (integer)


如果 *hep_async* 启用,此参数指定写入操作将以阻塞模式(优化)尝试的毫秒数。如果写入操作持续超过此时间,写入将进入异步模式并传递给 bin MAIN 进行轮询。


*默认值为 10 ms。*


```c title="设置 hep_async_local_write_timeout 参数"
...
modparam("proto_hep", "hep_async_local_write_timeout", 100)
...
```


### 导出的函数


#### correlate(hep_id, type1, correlation1, type2, correlation2)


发送一个带有额外关联 ID 的 hep 消息,包含作为参数给出的两个关联。两个类型必须不同。这将帮助在捕获侧关联两个调用,例如,通过它们的 callid 作为关联 ID。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE。


参数含义如下:


- *hep_id (string)*
				在 modparam 部分定义的 *hep_id* 的名称,
				指定在哪里进行跟踪。
- *type1 (string)*
				标识第一个关联 ID 的键名。
- *correlation1 (string)*
				第一个额外关联 ID,将放在额外关联块中。
- *type2 (string)*
				标识第二个关联 ID 的键名。
- *correlation2 (string)*
				第二个额外关联 ID,将放在额外关联块中。


```c title="correlate 使用示例"
...
/* 参见 trace_id 部分中 hep_dst 的声明 */
/* 假设我们在两个变量中有两个关联: cor1 和 cor2 */
	correlate("hep_dst", "correlation-no-1",$var(cor1),"correlation-no-2", $var(cor2));
...
```


## 开发者指南


### 可用函数


#### pack_hep(from, to, proto, payload, plen, retbuf, retlen)


该函数将连接细节和 sip 消息打包成 HEP 消息。你的工作是释放旧缓冲区和新缓冲区。


参数含义如下:


- *sockaddr_union *from* - 描述
			发送套接字的 sockaddr_union
- *sockaddr_union *to* - 描述
			接收套接字的 sockaddr_union
- *int proto* - hep 头中使用的协议;
- *char *payload* SIP 有效载荷缓冲区
- *int plen* SIP 有效载荷缓冲区长度
- *char **retbuf* HEP 消息缓冲区
- *int *retlen* HEP 消息缓冲区长度


#### register_hep_cb(cb)


该函数注册回调,每当收到 HEP 消息时调用。回调参数是 struct hep_desc*(参见 hep.h 获取详情),一个包含 hep 头和 receive_info* 结构所有细节的结构。回调可以返回 HEP_SCRIPT_SKIP,这阻止 HEP 消息通过脚本。


参数含义如下:


- *hep_cb_t cb* HEP 回调


#### hep_version


当前使用的 hep 版本。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)采用 Creative Common License 4.0 授权
