---
title: "proto_msrp 模块"
description: "**proto_msrp** 模块提供 MSRP 协议栈,即网络读/写(明文和 TLS)、消息解析和组装、事务层以及基本信令操作。"
---

## 管理指南


### 概述


**proto_msrp** 模块提供
		MSRP 协议栈,即网络读/写(明文和 TLS)、
		消息解析和组装、事务层以及基本信令操作。


加载后,你可以在脚本中定义 MSRP 监听器,
		通过在配置文件中添加其 IP 和可选的监听端口,
		类似于以下示例:
```c

...
socket=msrp:127.0.0.1:65432
socket=msrps:127.0.0.1:65431
...
```


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载:


- *tls_mgm* - 如果使用 MSRPS(安全)套接字,你需要加载此模块。
				通过此模块你将管理 SSL 证书。


#### 外部库或应用程序


运行 OpenSIPS 加载此模块之前,必须安装以下库或应用程序:


- *无*。


### 导出的参数


#### send_timeout (integer)


MSRP 连接在此时间后将被关闭(如果在此间隔内无法进行阻塞写入,并且 OpenSIPS 想在其上发送数据)。


*默认值为 100 ms。*


```c title="设置 send_timeout 参数"
...
modparam("proto_msrp", "send_timeout", 200)
...
```


#### max_msg_chunks (integer)


SIP 消息通过 MSRP 传输时预期的最大分片数。如果收到的数据包分片程度超过此值,则连接将被断开(要么连接严重过载导致高分片,要么我们正受到攻击,攻击者发送非常碎片化的流量以降低我们的性能)。


*默认值为 4。*


```c title="设置 max_msg_chunks 参数"
...
modparam("proto_msrp", "max_msg_chunks", 8)
...
```


#### tls_handshake_timeout (integer)


设置 SSL 握手序列完成的超时时间(毫秒)。当使用 CPU 密集型密码进行连接时,可能需要增加此值,以允许密钥生成和处理的时间。


超时在接受新连接(入站)时调用,并在新会话发起(出站)时等待期间调用。


*默认值为 100。*


```c title="设置 tls_handshake_timeout 变量"
param("proto_msrp", "tls_handshake_timeout", 200) # 毫秒数

			
```


#### cert_check_on_conn_reusage (integer)


此参数开启或关闭在重用现有 TLS 连接时对 TLS 域(SSL 证书)的额外检查/匹配。没有此额外检查,只会检查连接的 IP 和端口(以便重用现有连接)。有此额外检查时,要重用的连接必须具有与当前信令操作设置的相同的 SSL 证书。


此检查仅在通过 TLS 发送 SIP 流量时进行,仅适用于由 OpenSIPS(作为 TLS 客户端)创建/发起的连接。任何接受的连接(作为 TLS 服务器)将自动匹配(跳过额外测试)。


*默认值为 0(禁用)。*


```c title="设置 cert_check_on_conn_reusage 参数"
...
modparam("proto_msrp", "cert_check_on_conn_reusage", 1)
...
```


#### trace_destination (string)


跟踪目标,定义在跟踪模块中。目前唯一的跟踪模块是 **proto_hep**。
		网络事件(如连接、接受和连接关闭事件)以及过程中可能出现的错误将被跟踪。


**警告:**必须加载跟踪模块此参数才能工作。(例如
			**proto_hep**)。


*默认值为无(未定义)。*


```c title="设置 trace_destination 参数"
...
modparam("proto_hep", "hep_id", "[hep_dest]10.0.0.2;transport=tcp;version=3")

modparam("proto_msrp", "trace_destination", "hep_dest")
...
```


#### trace_on (int)


这控制 MSRP 的跟踪是开启还是关闭。你仍然需要定义 [trace destination](#param_trace_destination) 才能工作,但此值将使用 MI 函数 [msrp trace](#msrp-trace) 进行控制。


```c title="设置 trace_on 参数"
...
modparam("proto_msrp", "trace_on", 1)
...
```


#### trace_filter_route (string)


定义一个路由的名称,你可以在其中过滤哪些连接将被跟踪,哪些不会。在该路由中你将有关于当前连接源和目标 IP 和端口的信息。要禁用特定连接的跟踪,该路由中的最后一个调用必须是 **drop**,任何其他退出模式都会导致跟踪当前连接(当然你仍然需要定义 [trace destination](#param_trace_destination),并且在此连接打开时跟踪必须开启)。


**重要**
			可以使用 **$si** 和 **$sp** 根据 IP 地址和端口进行过滤,以匹配连接到 OpenSIPS 的实体或 OpenSIPS 正在连接的实体。名称可能具有误导性(**$si** 在文档中表示源 IP),但实际上它只是 OpenSIPS 套接字以外的套接字。为了匹配 OpenSIPS 接口(接受连接的接口或发起连接的接口),可以使用 **$socket_in(ip)** (IP)和 **$socket_in(port)** (端口)。


**警告:** 如果 [trace on](#param_trace_on) 设置为 0,或通过 MI 命令 [msrp trace](#msrp-trace) 停用了跟踪,则不会调用此路由。


```c title="设置 trace_filter_route 参数"
...
modparam("proto_msrp", "trace_filter_route", "msrp_filter")
...
/* 如果跟踪已激活且定义了跟踪目标,所有 MSRP 连接都将通过此路由 */
route[msrp_filter] {
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


### 导出的 MI 函数


#### msrp:trace


替换已弃用的 MI 命令: *msrp_trace*。


名称: *msrp:trace*


参数:


- trace_mode(可选): 开启和关闭 MSRP 跟踪。此参数
					可以缺失,命令将显示此模块的当前跟踪状态(开启或关闭);
					可能的值:
					
					on
					off


MI FIFO 命令格式:


```c
			:msrp:trace:_reply_fifo_file_
			trace_mode
			_empty_line_
			
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)采用 Creative Common License 4.0 授权
