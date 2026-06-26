---
title: "proto_tls 模块"
description: "TLS,如 SIP RFC 3261 所定义,是代理的必备功能,可用于保护逐跳(非端到端)的 SIP 信令。TLS 在 TCP 之上工作。DTLS(即 UDP 上的 TLS)已由 IETF 定义,未来可能可用。"
---

## 管理指南


### 概述


TLS,如 SIP RFC 3261 所定义,是代理的必备功能,
		可用于保护逐跳(非端到端)的 SIP 信令。TLS 在 TCP 之上工作。DTLS,即 UDP 上的 TLS 已由 IETF 定义,未来可能可用。


### 历史


TLS 支持最初由 Peter Griffiths 开发,并作为补丁发布在 SER 开发邮件列表上。感谢 Cesc
		Santasusana,修复了几个问题并添加了一些改进。


TLS 支持同时添加到两个项目中。在 SER 中,支持被提交到一个单独的"experimental"
		CVS 树中,作为主 CVS 树的补丁。在 OpenSIPS 中,支持直接集成到 CVS 树中,作为内置组件,并且从 release >=1.0.0 开始成为稳定 OpenSIPS 的一部分。


从 OpenSIPS 2.1 开始,TLS 已移至单独的传输模块,实现了更通用的传输接口。


### 场景


随着提供商数量的增加,SIP 世界不断发展。更多用户意味着更多通话,更多通话意味着用户收到完全陌生来电的可能性很高,或者在最坏的情况下,收到不需要的电话。为了防止这种情况,SIP 提供商必须采用防御机制。由于只有被叫用户才能完全将电话分类为不需要的,SIP 服务器可以根据关于通话的所有信息通知用户来电的可取性。来电者的域、收到的源或传入的协议等信息对 SIP 服务器判断通话性质非常有用。


由于这些信息相当有限,服务器不可能检测到不需要的来电——有很多通话它无法预测其状态(中性通话)。因此,服务器不是提醒被叫用户注意不需要的来电,而是通知用户哪些电话被认为是可信的——服务器 100% 确定不是不需要的。


因此,必须为 SIP 服务器定义信任概念。哪些通话是可信的,哪些不是?如果来电者可以被识别为可信任的用户——一个我们有可靠信息的用户——则通话是可信的。


由于其域中的所有用户都已认证(或应该),SIP 服务器可以将其用户生成的所有通话视为可信。现在我们必须将信任概念扩展到多域级别。多个域之间的相互协议可以建立信任关系。因此,一个域(称为 A)也将把来自不同域(称为 B)的用户生成的通话视为可信,反之亦然。但仅有协议是不够的;由于认证信息严格限于某个域(一个域只能认证自己的用户,不能认证其他域的用户),仍然存在检查来电者真实性的问题——他可以冒充受信任域中的用户(通过伪造的 FROM 头)。


这个问题的答案是 TLS(传输层安全)。通过域 A 和域 B 的所有通话都将通过 TLS 进行。原始域中的认证加上域之间的 TLS 传输将使目标域认为通话 100% 可信。


为了使这种机制工作,必须满足以下要求:


- 所有 UA 必须将其家庭服务器设置为出站代理。
- 所有 SIP 服务器必须认证其用户生成的所有通话。
- 所有 SIP 服务器必须通过 TLS 将其用户生成的通话中继到可信域。


基于此,服务器可以将其用户之一的通话分类为可信,前提是该通话也是由其用户之一生成的,或者是收到来自可信域的通话(这与通过 TLS 收到的通话等效)。不可信通话将是这样一些通话:来自不可信域的用户,或来自可信域的用户,但其通话未通过其家庭服务器路由(因此未通过其家庭服务器认证)。


一旦服务器能够判断通话是否可信,仍然需要解决的是服务器用于通知被叫用户有关来电性质所使用的机制。


一种方法是远程更改被叫用户电话的振铃类型。这可以通过在 INVITE 请求中插入特殊头来完成。现在一些硬电话如 CISCO ATA、CISCO 7960 和 SNOM 支持此功能。这些电话可以根据"Alert-Info" SIP 头的存在或内容更改振铃音,如下:


- *CISCO ATA* - 它有 4 个预定义的
			振铃类型。Alert-Info 头必须看起来像
			"Alert-info: Bellcore-drX EOH",其中 X 介于 1 和 4 之间。注意 1 是电话默认振铃音。
- *CISCO 7960* - 它有 2 个预定义的
			振铃类型,并可以上传新的。"Alert-Info" 头必须看起来像
			"Alert-info: X EOH",其中 X 可以是任意数字。
			当此头存在时,电话不会更改振铃音,而是更改振铃模式。正常情况下,电话振铃像 [ring.........ring..........ring],其中 [ring] 是振铃音;如果头存在,振铃模式将是 [ring.ring.........ring.ring........]。因此,为了能够听到两种模式之间的差异(而不仅仅是长度),强烈建议使用高度不对称的振铃类型(因为预定义的不是!!)。
- *SNOM* - "Alert-Info"
			头必须看起来像 "Alert-info: URL EOH",其中 URL 可以是 HTTP URL(例如),电话可以从中检索振铃音。


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
		来配置 OpenSIPS-TLS 的行为。


#### listen=interface


非 TLS 特有。允许指定监听服务器的协议
			(udp、tcp、tls)、IP 地址和端口。


```c title="设置 listen 变量"
...
socket= tls:1.2.3.4:5061
...
					
```


#### tls_port (integer)


用于所有 TLS 相关操作的默认端口。请小心,因为默认端口会影响 SIP 监听部分
			(如果在 TLS 监听器中未定义端口)和 SIP 发送部分
			(如果目标 URI 没有显式端口)。


如果你只想更改 TLS 的监听端口,请使用 SIP 监听器定义中的端口选项。


*默认值为 5061。*


```c title="设置 tls_port 变量"
...
modparam("proto_tls", "tls_port", 5062)
...
					
```


#### tls_crlf_pingpong (integer)


通过 TLS 发送 CRLF pong (\r\n) 到传入的 CRLFCRLF ping 消息。默认情况下启用(1)。


*默认值为 1(启用)。*


```c title="设置 tls_crlf_pingpong 参数"
...
modparam("proto_tls", "tls_crlf_pingpong", 0)
...
```


#### tls_crlf_drop (integer)


丢弃 CRLF (\r\n) ping 消息。当启用此参数时,
			TLS 层丢弃包含单个 CRLF 消息的数据包。
			如果收到 CRLFCRLF 消息,则根据 *tls_crlf_pingpong* 参数处理。


*默认值为 0(禁用)。*


```c title="设置 tls_crlf_drop 参数"
...
modparam("proto_tls", "tls_crlf_drop", 1)
...
```


#### tls_max_msg_chunks (integer)


SIP 消息通过 TLS 传输时预期的最大分片数。如果收到的数据包分片程度超过此值,则连接将被断开(要么连接严重过载导致高分片,要么我们正受到攻击,攻击者发送非常碎片化的流量以降低服务器性能)。


*默认值为 4。*


```c title="设置 tls_max_msg_chunks 参数"
...
modparam("proto_tls", "tls_max_msg_chunks", 8)
...
```


#### cert_check_on_conn_reusage (integer)


此参数开启或关闭在重用现有 TLS 连接时对 TLS 域(SSL 证书)的额外检查/匹配。没有此额外检查,只会检查连接的 IP 和端口(以便重用现有连接)。有此额外检查时,要重用的连接必须具有与当前信令操作设置的相同的 SSL 证书。


此检查仅在通过 TLS 发送 SIP 流量时进行,仅适用于由 OpenSIPS(作为 TLS 客户端)创建/发起的连接。任何接受的连接(作为 TLS 服务器)将自动匹配(跳过额外测试)。


*默认值为 0(禁用)。*


```c title="设置 cert_check_on_conn_reusage 参数"
...
modparam("proto_tls", "cert_check_on_conn_reusage", 1)
...
```


#### trace_destination (string)


跟踪目标,定义在跟踪模块中。目前唯一的跟踪模块是 **proto_hep**。
		网络事件(如连接、接受和连接关闭事件)以及过程中可能出现的错误将被跟踪。对于创建的每个连接,将发送包含有关客户端和服务器证书、主密钥和网络层信息的事件。


**警告:**必须加载跟踪模块此参数才能工作。(例如
			**proto_hep**)。


*默认值为无(未定义)。*


```c title="设置 trace_destination 参数"
...
modparam("proto_hep", "hep_id", "[hep_dest]10.0.0.2;transport=tcp;version=3")

modparam("proto_tls", "trace_destination", "hep_dest")
...
```


#### trace_on (int)


这控制 TLS 的跟踪是开启还是关闭。你仍然需要定义
			[tls trace destination](#param_trace_destination) 才能工作,但此值将使用 MI 函数 [mi trace](#mi_trace) 进行控制。


```c title="设置 trace_on 参数"
...
modparam("proto_tls", "trace_on", 1)
...
```


#### trace_filter_route (string)


定义一个路由的名称,你可以在其中过滤哪些连接将被跟踪,哪些不会。在该路由中你将有关于当前连接源和目标 IP 和端口的信息。要禁用特定连接的跟踪,该路由中的最后一个调用必须是 **drop**,任何其他退出模式都会导致跟踪当前连接(当然你仍然需要定义 [tls trace destination](#param_trace_destination),并且在此连接打开时跟踪必须开启)。


**重要**
			可以使用 **$si** 和 **$sp** 根据 IP 地址和端口进行过滤,以匹配连接到 OpenSIPS 的实体或 OpenSIPS 正在连接的实体。名称可能具有误导性(**$si** 在文档中表示源 IP),但实际上它只是 OpenSIPS 套接字以外的套接字。为了匹配 OpenSIPS 接口(接受连接的接口或发起连接的接口),可以使用 **$socket_in(ip)** (IP)和 **$socket_in(port)** (端口)。


**警告:** 如果 [trace on](#param_trace_on) 设置为 0,或通过 MI 命令 [mi trace](#mi_trace) 停用了跟踪,则不会调用此路由。


```c title="设置 trace_filter_route 参数"
...
modparam("proto_tls", "trace_filter_route", "tls_filter")
...
/* 如果跟踪已激活且定义了跟踪目标,所有 tls 连接都将通过此路由 */
route[tls_filter] {
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


#### tls_handshake_timeout (integer)


设置 SSL 握手序列完成的超时时间(毫秒)。当使用 CPU 密集型密码进行连接时,可能需要增加此值,以允许密钥生成和处理的时间。


超时在接受新连接(入站)时调用,并在新会话发起(出站)时等待期间调用。


*默认值为 100。*


```c title="设置 tls_handshake_timeout 变量"
...
modparam("proto_tls", "tls_handshake_timeout", 200) # 毫秒数
...
```


#### tls_send_timeout (integer)


设置发送操作完成的超时时间(毫秒)


发送超时适用于所有 TLS 写入操作,不包括
			握手过程(参见: tls_handshake_timeout)


*默认值为 100。*


```c title="设置 tls_send_timeout 变量"
...
modparam("proto_tls", "tls_send_timeout", 200) # 毫秒数
...
```


#### tls_async (integer)


TLS 连接和写入操作是否应以异步模式(非阻塞连接和写入)进行。如果禁用,OpenSIPS 将阻塞并等待 TLS 操作如连接和写入。


*默认值为 1(启用)。*


```c title="设置 tls_async 变量"
...
modparam("proto_tls", "tls_async", 1) # 启用异步 TLS
...
```


#### tls_async_max_postponed_chunks (integer)


如果 *tls_async* 启用,此参数指定可暂存供以后/异步写入的最大 SIP 消息数。如果连接待写入超过此数量,连接将被标记为已损坏并被丢弃。


*默认值为 32。*


```c title="设置 tls_async_max_postponed_chunks 参数"
...
modparam("proto_tls", "tls_async_max_postponed_chunks", 16)
...
```


### 导出的 MI 函数


#### tls:trace


替换已弃用的 MI 命令: *tls_trace*。


名称: *tls:trace*


参数:


- trace_mode(可选): 开启和关闭 TLS 跟踪。此参数
					可以缺失,命令将显示此模块的当前跟踪状态(开启或关闭);
					可能的值:
					
					on
					off


MI FIFO 命令格式:


```c
			opensips-cli -x mi tls:trace on
			
```


## 开发者指南


### TLS_SERVER


#### 每个连接的 SSL 数据


每个 TLS 连接(入站或出站)创建一个
			SSL * 对象,其中存储从 SSL_CTX * 继承的配置和该套接字的特定信息。
			此 SSL * 结构在 OpenSIPS 中作为 "struct tcp_connection *"
			对象的一部分保留,只要连接存活:


```c
...
struct tcp_connection *c;
SSL *ssl;

/*以某种方式创建 SSL 对象*/
c->extra_data = (void *) ssl;
ssl = (SSL *) c->extra_data;
...
```


TLS 握手完成后,后端还将协商的 TLS 元数据存储在同一连接对象上的共享 "c->shared_data" 附件中。附件是 "struct tcp_tls_info *",包括 TLS 版本、密码名称、密码描述、密码位数和对方验证结果,以便其他代码可以在不接触实时 "SSL *" 句柄的情况下读取它。相同的缓存附件也被协议连接转储钩子使用,允许 "list_tcp_conns" 直接从共享内存打印 TLS 元数据。


#### tls_print_errstack


void  tls_print_errstack(void);


转储 ssl 错误栈。


#### tls_tcpconn_init


int tls_tcpconn_init( struct tcp_connection *c, int fd);


接受新 tcp 连接时调用。


#### tls_tcpconn_clean


void tls_tcpconn_clean( struct tcp_connection *c);


关闭 TLS 连接。


#### tls_blocking_write


size_t tls_blocking_write( struct tcp_connection *c, int fd,
			const char *buf, size_t len);


以阻塞模式(同步)写入内存块。


#### tls_read


size_t tls_read( struct tcp_connection *c);


从 TLS 连接读取。返回读取的字节数。


#### tls_fix_read_conn


void tls_tcpconn_clean( struct tcp_connection *c);


关闭 TLS 连接。


## 常见问题


**Q: 在哪里可以发布关于 TLS 的问题?**


使用 OpenSIPS 邮件列表(最合适的一个):

记住:首先检查你的问题是否已经得到回答。


**Q: 如何报告错误?**


收集尽可能多的信息(OpenSIPS 版本,
			opensips -V 输出,你的 OS (uname -a)、OpenSIPS 日志、网络转储、
			核心转储文件、配置文件)
			并发送邮件到 [http://lists.opensips.org/cgi-bin/mailman/listinfo/devel](http://lists.opensips.org/cgi-bin/mailman/listinfo/devel)

你也可以尝试 OpenSIPS 的错误报告网页:
			https://opensips.org/pmwiki.php?n=Development.Tracker


**Q: 如何调试 ssl/tls 问题?**


在 opensips.cfg 中增加日志级别(log_level=4)并观察 syslog 中的日志语句。


安装 ssldump 实用程序并启动它。这将给你 ssl/tls 连接的跟踪。


**Q: TLS 目录和 TLSOPS 模块目录有什么区别?**


TLS 目录中的代码实现 TLS 传输层。TLSOPS 模块实现可在路由脚本中使用的 TLS 相关函数。


**Q: 在哪里可以找到更多关于 OpenSIPS 的信息?**


看看 [https://opensips.org/](https://opensips.org/)。


**Q: 在哪里可以发布关于此模块的问题?**


首先检查你的问题是否已在我们某个邮件列表上得到解答:
			
针对任何稳定 OpenSIPS 版本的电子邮件应发送到
			users@lists.opensips.org,针对开发版本的电子邮件应发送到 devel@lists.opensips.org。

如果你想保持邮件私密,请发送至 users@lists.opensips.org。


**Q: 如何报告错误?**


请遵循以下指南:
			[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)采用 Creative Common License 4.0 授权
