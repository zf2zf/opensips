---
title: "proto_wss 模块"
description: "WSS(Secure WebSocket)模块提供了通过安全(TLS 加密)通道与 WebSocket([RFC 6455](http://tools.ietf.org/html/rfc6455))客户端或服务器通信的能力。作为 [WebRTC](https://webrtc.org/) 规范的一部分,该协议可用于为 HTTPS 浏览器提供安全 VoIP 通话。"
---

## 管理指南


### 概述


WSS(Secure WebSocket)模块提供了通过安全(TLS 加密)通道与
	WebSocket([RFC
		6455](http://tools.ietf.org/html/rfc6455))客户端或服务器通信的能力。
	作为 [WebRTC](https://webrtc.org/)
	规范的一部分,该协议可用于为 HTTPS 浏览器提供安全 VoIP 通话。


此模块的行为与任何其他传输协议模块一样:要使用它,你必须定义一个或多个将处理安全 WebSocket 流量的监听器,
	*在* `mpath` 参数*之后*:
```c

...
mpath=/path/to/modules
...
socket=wss:10.0.0.1			# 更改为监听 IP
socket=wss:10.0.0.1:5060	# 更改为监听 IP 和端口
...
```
	除此之外,你需要定义 TLS 参数来保护连接。这通过 *tls_mgm* 模块接口完成,类似于 *proto_tls* 模块:
```c

modparam("tls_mgm", "certificate", "/certs/biloxy.com/cert.pem")
modparam("tls_mgm", "private_key", "/certs/biloxy.com/privkey.pem")
modparam("tls_mgm", "ca_list", "/certs/wellknownCAs")
modparam("tls_mgm", "tls_method", "tlsv1")
modparam("tls_mgm", "verify_cert", "1")
modparam("tls_mgm", "require_cert", "1")
```
	有关更多信息,请查看 *tls_mgm* 模块文档。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载:


- *tls_openssl* 或 *tls_wolfssl*,
				取决于所需的 TLS 库
- *tls_mgm*。


#### 外部库的依赖


运行 OpenSIPS 加载此模块之前,必须安装以下库或应用程序:


- *无*。


### 导出的参数


所有这些参数都可以从 opensips.cfg 文件使用,
		来配置 OpenSIPS-WSS 的行为。


#### listen=interface


这是一个全局参数,指定哪个接口/IP 和端口应处理 WSS 流量。


```c title="设置 listen 变量"
...
socket= wss:1.2.3.4:44344
...
					
```


#### wss_port (integer)


用于所有 WSS 相关操作的默认端口。请小心,因为默认端口会影响 SIP 监听部分
			(如果在 WSS 监听器中未定义端口)和 SIP 发送部分
			(如果目标 WSS URI 没有显式端口)。


如果你只想更改 WSS 的监听端口,请使用 SIP 监听器定义中的端口选项。


*默认值为 443。*


```c title="设置 wss_port 变量"
...
modparam("proto_wss", "wss_port", 44344)
...
					
```


#### wss_max_msg_chunks (integer)


SIP 消息通过 WSS 传输时预期的最大分片数。如果收到的数据包分片程度超过此值,则连接将被断开(要么连接严重过载导致高分片,要么我们正受到攻击,攻击者发送非常碎片化的流量以降低服务器性能)。


*默认值为 4。*


```c title="设置 wss_max_msg_chunks 参数"
...
modparam("proto_wss", "wss_max_msg_chunks", 8)
...
```


#### wss_resource (string)


发起 WebSocket 握手时查询的资源。


*默认值为 "/"。*


```c title="设置 wss_resource 参数"
...
modparam("proto_wss", "wss_resource", "/wss")
...
```


#### wss_handshake_timeout (integer)


此参数指定 proto_wss 模块等待 WebSocket 服务器 WebSocket 握手回复的毫秒数。


*默认值为 100。*


```c title="设置 wss_handshake_timeout 参数"
...
modparam("proto_wss", "wss_handshake_timeout", 300)
...
```


#### cert_check_on_conn_reusage (integer)


此参数开启或关闭在重用现有 TLS 连接时对 TLS 域(SSL 证书)的额外检查/匹配。没有此额外检查,只会检查连接的 IP 和端口(以便重用现有连接)。有此额外检查时,要重用的连接必须具有与当前信令操作设置的相同的 SSL 证书。


此检查仅在通过 TLS 发送 SIP 流量时进行,仅适用于由 OpenSIPS(作为 TLS 客户端)创建/发起的连接。任何接受的连接(作为 TLS 服务器)将自动匹配(跳过额外测试)。


*默认值为 0(禁用)。*


```c title="设置 cert_check_on_conn_reusage 参数"
...
modparam("proto_wss", "cert_check_on_conn_reusage", 1)
...
```


#### trace_destination (string)


跟踪目标,定义在跟踪模块中。目前唯一的跟踪模块是 **proto_hep**。
		网络事件(如连接、接受和连接关闭事件)以及过程中可能出现的错误将被跟踪。对于创建的每个连接,将发送包含有关客户端和服务器证书、主密钥、属于 WebSocket 协议握手的 HTTP 请求和回复以及网络层信息的事件。


**警告:**必须加载跟踪模块此参数才能工作。(例如
			**proto_hep**)。


*默认值为无(未定义)。*


```c title="设置 trace_destination 参数"
...
modparam("proto_hep", "hep_id", "[hep_dest]10.0.0.2;transport=tcp;version=3")

modparam("proto_wss", "trace_destination", "hep_dest")
...
```


#### trace_on (int)


这控制 WSS 的跟踪是开启还是关闭。你仍然需要定义
			[trace destination](#param_trace_destination) 才能工作,但此值将使用 MI 函数 [mi trace](#mi_trace) 进行控制。


```c title="设置 trace_on 参数"
...
modparam("proto_wss", "trace_on", 1)
...
```


#### trace_filter_route (string)


定义一个路由的名称,你可以在其中过滤哪些连接将被跟踪,哪些不会。在该路由中你将有关于当前连接源和目标 IP 和端口的信息。要禁用特定连接的跟踪,该路由中的最后一个调用必须是 **drop**,任何其他退出模式都会导致跟踪当前连接(当然你仍然需要定义 [trace destination](#param_trace_destination),并且在此连接打开时跟踪必须开启)。


**重要**
			可以使用 **$si** 和 **$sp** 根据 IP 地址和端口进行过滤,以匹配连接到 OpenSIPS 的实体或 OpenSIPS 正在连接的实体。名称可能具有误导性(**$si** 在文档中表示源 IP),但实际上它只是 OpenSIPS 套接字以外的套接字。为了匹配 OpenSIPS 接口(接受连接的接口或发起连接的接口),可以使用 **$socket_in(ip)** (IP)和 **$socket_in(port)** (端口)。


**警告:** 如果 [trace on](#param_trace_on) 设置为 0,或通过 MI 命令 [mi trace](#mi_trace) 停用了跟踪,则不会调用此路由。


```c title="设置 trace_filter_route 参数"
...
modparam("proto_wss", "trace_filter_route", "wss_filter")
...
/* 如果跟踪已激活且定义了跟踪目标,所有 wss 连接都将通过此路由 */
route[wss_filter] {
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


#### wss_tls_handshake_timeout (integer)


设置 SSL 握手序列完成的超时时间(毫秒)。当使用 CPU 密集型密码进行连接时,可能需要增加此值,以允许密钥生成和处理的时间。


超时在接受新连接(入站)时调用,并在新会话发起(出站)时等待期间调用。


*默认值为 100。*


```c title="设置 wss_tls_handshake_timeout 变量"
param("proto_wss", "wss_tls_handshake_timeout", 200) # 毫秒数

			
```


#### wss_send_timeout (integer)


设置发送操作完成的超时时间(毫秒)


发送超时适用于所有 TLS 写入操作,不包括
			握手过程(参见: wss_tls_handshake_timeout)


*默认值为 100。*


```c title="设置 wss_send_timeout 变量"
modparam("proto_wss", "wss_send_timeout", 200) # 毫秒数

			
```


#### require_origin (int)


控制模块是否需要 Origin 头。


```c title="设置 require_origin 参数"
modparam("proto_wss", "require_origin", no)

			
```


### 导出的 MI 函数


#### wss:trace


替换已弃用的 MI 命令: *wss_trace*。


名称: *wss:trace*


参数:


- trace_mode(可选): 开启和关闭 WSS 跟踪。此参数
					可以缺失,命令将显示此模块的当前跟踪状态(开启或关闭);
					可能的值:
					
					on
					off


MI FIFO 命令格式:


```c
			opensips-cli -x mi wss:trace on
			
```


## 常见问题


**Q: OpenSIPS 支持分片的安全 WebSocket 消息吗?**


不支持,WebSocket 分片机制不受支持。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)采用 Creative Common License 4.0 授权
