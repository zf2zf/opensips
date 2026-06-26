---
title: "proto_ws 模块"
description: "WebSocket 协议([RFC 6455](http://tools.ietf.org/html/rfc6455))在两个基于 Web 的应用程序之间提供端到端全双工通信通道。这允许支持 WebSocket 的浏览器连接到 WebSocket 服务器并交换任何类型的数据。[RFC 7118](http://tools...."
---

## 管理指南


### 概述


WebSocket 协议([RFC 6455](http://tools.ietf.org/html/rfc6455))
	 提供两个基于 Web 的应用程序之间的端到端全双工通信通道。
	这允许支持 WebSocket 的浏览器连接到 WebSocket 服务器并交换任何类型的数据。
	[RFC 7118](http://tools.ietf.org/html/rfc7118)
	提供了通过 WebSocket 协议传输 SIP 消息的规范。


**proto_ws** 模块是提供 WebSocket 协议通信的传输模块。此模块完全符合
	[RFC 7118](http://tools.ietf.org/html/rfc7118),因此允许浏览器充当 OpenSIPS 代理的 SIP 客户端。


当前实现同时充当 WebSocket 服务器和客户端,因此它可以接受来自 WebSocket 客户端的连接,也可以主动连接到另一个 WebSocket 服务器。连接建立后,消息可以双向流动。


OpenSIPS 支持以下 WebSocket 操作:


- 文本和二进制 - 都可以发送和接收包含文本或二进制体的 WebSocket 消息
- 关闭 - 用于使用 2 消息握手安全关闭 WebSocket 通信的消息
- ping - 用 pong 消息响应。没有触发 ping 消息的机制。
- pong - 当收到 ping 消息时发送。OpenSIPS 吸收收到的 pong 消息。


加载后,你将能够在脚本中定义 WebSocket 监听器。要添加监听器,你必须在其 IP 之后添加,可选地添加监听端口,
	*在* `mpath` 参数*之后*,类似于以下示例:
```c

...
mpath=/path/to/modules
...
socket=ws:127.0.0.1		# 更改为监听 IP
socket=ws:127.0.0.1:5060	# 更改为监听 IP 和端口
...
```


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载:


- *无*。


#### 外部库或应用程序


运行 OpenSIPS 加载此模块之前,必须安装以下库或应用程序:


- *无*。


### 导出的参数


#### ws_port (integer)


用于所有 WS 相关操作的默认端口。请小心,因为默认端口会影响 SIP 监听部分(如果在 WS 监听器中未定义端口)和 SIP 发送部分(如果目标 WS URI 没有显式端口)。


如果你只想更改 WS 的监听端口,请使用 SIP 监听器定义中的端口选项。


*默认值为 80。*


```c title="设置 ws_port 参数"
...
modparam("proto_ws", "ws_port", 8080)
...
```


#### ws_send_timeout (integer)


WebSocket 连接在此时间后将被关闭(如果在此间隔内无法进行阻塞写入,并且 OpenSIPS 想在其上发送数据)。


*默认值为 100 ms。*


```c title="设置 ws_send_timeout 参数"
...
modparam("proto_ws", "ws_send_timeout", 200)
...
```


#### ws_max_msg_chunks (integer)


SIP 消息通过 WebSocket 传输时预期的最大分片数。如果收到的数据包分片程度超过此值,则连接将被断开(要么连接严重过载导致高分片,要么我们正受到攻击,攻击者发送非常碎片化的流量以降低服务器性能)。


*默认值为 4。*


```c title="设置 ws_max_msg_chunks 参数"
...
modparam("proto_ws", "ws_max_msg_chunks", 8)
...
```


#### trace_destination (string)


跟踪目标,定义在跟踪模块中。目前唯一的跟踪模块是 **proto_hep**。
		网络事件(如连接、接受和连接关闭事件)以及过程中可能出现的错误将被跟踪。对于创建的每个连接,将发送包含有关属于 WebSocket 协议握手的 HTTP 请求和回复以及网络层信息的事件。


**警告:**必须加载跟踪模块此参数才能工作。(例如
			**proto_hep**)。


*默认值为无(未定义)。*


```c title="设置 trace_destination 参数"
...
modparam("proto_hep", "hep_id", "[hep_dest]10.0.0.2;transport=tcp;version=3")

modparam("proto_ws", "trace_destination", "hep_dest")
...
```


#### trace_on (int)


这控制 WS 的跟踪是开启还是关闭。你仍然需要定义
			[trace destination](#param_trace_destination) 才能工作,但此值将使用 MI 函数 [mi trace](#mi_trace) 进行控制。


```c title="设置 trace_on 参数"
...
modparam("proto_ws", "trace_on", 1)
...
```


#### trace_filter_route (string)


定义一个路由的名称,你可以在其中过滤哪些连接将被跟踪,哪些不会。在该路由中你将有关于当前连接源和目标 IP 和端口的信息。要禁用特定连接的跟踪,该路由中的最后一个调用必须是 **drop**,任何其他退出模式都会导致跟踪当前连接(当然你仍然需要定义 [trace destination](#param_trace_destination),并且在此连接打开时跟踪必须开启)。


**重要**
			可以使用 **$si** 和 **$sp** 根据 IP 地址和端口进行过滤,以匹配连接到 OpenSIPS 的实体或 OpenSIPS 正在连接的实体。名称可能具有误导性(**$si** 在文档中表示源 IP),但实际上它只是 OpenSIPS 套接字以外的套接字。为了匹配 OpenSIPS 接口(接受连接的接口或发起连接的接口),可以使用 **$socket_in(ip)** (IP)和 **$socket_in(port)** (端口)。


**警告:** 如果 [trace on](#param_trace_on) 设置为 0,或通过 MI 命令 [mi trace](#mi_trace) 停用了跟踪,则不会调用此路由。


```c title="设置 trace_filter_route 参数"
...
modparam("proto_ws", "trace_filter_route", "ws_filter")
...
/* 如果跟踪已激活且定义了跟踪目标,所有 ws 连接都将通过此路由 */
route[ws_filter] {
	...
	/* 所有从/由 ip 1.1.1.1:8000 打开的连接将被跟踪
	   在接口 1.1.1.10:5060(opensips 监听器)上
	   其他连接不会 */
	 if ( $si == "1.1.1.1" && $sp == 8000 &&
		$socket_in(ip) == "1.1.1.10"  && $socket_in(port) == 5060)
		exit;
	else
		drop;
}
...
```


#### require_origin (int)


控制模块是否需要 Origin 头。


```c title="设置 require_origin 参数"
...
modparam("proto_ws", "require_origin", no)
...
```


### 导出的 MI 函数


#### ws:trace


替换已弃用的 MI 命令: *ws_trace*。


名称: *ws:trace*


参数:


- trace_mode(可选): 开启和关闭 WS 跟踪。此参数
					可以缺失,命令将显示此模块的当前跟踪状态(开启或关闭);
					可能的值:
					
					on
					off


MI FIFO 命令格式:


```c
			opensips-cli -x mi ws:trace on
			
```


## 常见问题


**Q: OpenSIPS 可以充当 WebSocket 客户端吗?**


可以,从 OpenSIPS 2.2 开始,它可以充当 WebSocket 客户端。


**Q: OpenSIPS 支持 WebSocket 消息分片吗?**


不支持,WebSocket 分片机制不受支持。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)采用 Creative Common License 4.0 授权
