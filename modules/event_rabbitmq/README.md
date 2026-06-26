---
title: "event_rabbitmq 模块"
description: "*RabbitMQ* ([http://www.rabbitmq.com/](http://www.rabbitmq.com/)) 是一个开源消息服务器。其目的是通过灵活的 AMQP 协议管理队列中收到的消息。"
---

## 管理指南


### 概述


*RabbitMQ*
		([http://www.rabbitmq.com/](http://www.rabbitmq.com/)) 
		是一个开源消息服务器。其目的是通过灵活的
		AMQP 协议管理队列中收到的消息。


此模块提供 RabbitMQ 客户端的实现，支持两个主要功能：


- *事件驱动消息传递：*
		每次 Event Interface 触发所订阅的事件时，用于向 RabbitMQ 服务器发送 AMQP 消息。
- *通用消息发布：*
		此模块还支持直接向 RabbitMQ 服务器发送 AMQP 消息。可以根据 AMQP 规范以及 RabbitMQ 扩展轻松自定义消息。


### RabbitMQ 事件语法


事件负载格式为 JSON-RPC 通知，事件名称作为 *method* 字段，事件参数作为 *params* 字段。


### RabbitMQ 套接字语法


*'rabbitmq:' [user[':'password] '@' host [':' port] '/' [params '?'] routing_key*


含义：


- *'rabbitmq:'* - 通知 Event Interface，发送到此订阅者的事件应由 *event_rabbitmq* 模块处理。
- *user* - 用于 RabbitMQ 服务器认证的用户名。默认值为 'guest'。
- *password* - 用于 RabbitMQ 服务器认证的密码。默认值为 'guest'。
- *host* - RabbitMQ 服务器的主机名。
- *port* - RabbitMQ 服务器的端口。默认值为 '5672'。
- *params* - 额外参数，指定为 *key[=value]*，用 ';' 分隔：
					
					*exchange* - RabbitMQ 服务器的 exchange。默认值为 ''。
					*tls_domain* - 指示为此连接使用哪个 TLS domain（如使用 *tls_mgm* 模块定义）。必须启用 [use tls](#param_use_tls) 模块参数。
					*persistent* - 指示消息应作为持久消息 *delivery_mode=2* 发布。此参数没有值。
- *routing_key* - AMQP 协议使用的路由键，用于标识事件应发送到的队列。
					注意：如果队列不存在，此模块不会尝试创建它。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *如果启用了 [use tls](#param_use_tls)，则需要 tls_mgm*。


#### 外部库或应用程序


运行加载此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *librabbitmq-dev*


### 导出的参数


#### heartbeat (integer)


启用 AMQP 通信的心跳支持。如果客户端在指定间隔内未收到服务器的心跳，套接字将由 rabbitmq-client 自动关闭。这可以防止 OpenSIPS 在等待已死亡的 rabbitmq-server 响应时阻塞。该值表示心跳间隔（秒）。


*默认值为 "0（禁用）"。*


```c title="设置 heartbeat 参数"
...
modparam("event_rabbitmq", "heartbeat", 3)
...
```


#### connect_timeout (integer)


建立与 RabbitMQ 服务器的 TCP 连接所允许的最大持续时间（毫秒）。


*默认值为 "500"（毫秒）。*


```c title="设置 connect_timeout 参数"
...
modparam("event_rabbitmq", "connect_timeout", 1000)
...
	
```


#### use_tls (integer)


设置此参数将允许您使用 TLS 进行代理连接。为了对特定连接启用 TLS，您可以在 [socket syntax](#rabbitmq_socket_syntax) 指定的配置中使用 "tls_domain=*dom_name*" 参数。


使用此参数时，您还必须确保 *tls_mgm* 已加载并正确配置。请参阅该模块以获取关于 TLS 客户端域的更多信息。


*默认值为 **0**（未启用）*


```c title="设置 use_tls 参数"
...
modparam("tls_mgm", "client_domain", "rmq")
modparam("tls_mgm", "certificate", "[rmq]/etc/pki/tls/certs/rmq.pem")
modparam("tls_mgm", "private_key", "[rmq]/etc/pki/tls/private/rmq.key")
modparam("tls_mgm", "ca_list",     "[rmq]/etc/pki/tls/certs/ca.pem")
...
modparam("event_rabbitmq", "use_tls", 1)
...
```


#### timeout (integer)


表示发送到 RabbitMQ 服务器的任何命令（即发布）的超时（毫秒）。


*请注意*，此参数仅在 RabbitMQ 库版本 *0.9.0* 及更高版本中可用；在使用早期版本时设置此参数将无效，发布命令将以阻塞模式运行。


*默认值为 **0**（无超时 - 阻塞模式）*


```c title="设置 timeout 参数"
...
modparam("event_rabbitmq", "timeout", 1000) # 1秒后超时
...
```


#### server_id (string)


指定 RabbitMQ 服务器的配置。它包含一组用于自定义连接服务器以及发送消息的参数。参数格式为 *[id_name] param1=value1; param2=value2;*。*uri* 参数是必需的。


可以为每个 RabbitMQ 服务器多次设置此参数。


可以使用以下参数：


- *uri* - 必选参数 - 一个完整的 *amqp* URI（如
				[此处](https://www.rabbitmq.com/uri-spec.html) 所述。
				URI 中缺少的字段将使用默认值，如：*user: guest*、
				*password: guest*、*host: localhost*、
				*vhost: /*、*port: 5672*。使用 *amqps* URI
				指定 TLS 连接。
- *frames* - AMQP 帧的最大大小。可选参数，默认大小为 131072。
- *retries* - 连接断开时的重试次数。可选参数，默认为禁用（不重试）。
- *exchange* - 用于发送 AMQP 消息的 exchange。可选参数，默认为 *""*。
- *heartbeat* - 发送心跳消息的间隔（秒）。可选参数，默认为禁用。
- *immediate* - 指示代理消息必须立即传递给消费者。可选参数，默认为非立即传递。
- *mandatory* - 指示代理消息必须路由到队列。可选参数，默认为非强制。
- *non-persistent* - 指示在 RabbitMQ 服务器重启时消息不应持久化。可选参数，默认为持久化。
- *tls_domain* - 指示为此连接使用哪个 TLS domain（如使用 *tls_mgm* 模块定义）。这必须是 *amqps* URI，且必须启用 [use tls](#param_use_tls) 模块参数。


```c title="设置 server_id 参数"
...
# 连接到 localhost 上的 RabbitMQ 服务器，默认端口
modparam("event_rabbitmq", "server_id","[ID1] uri = amqp://127.0.0.1")
...
# 连接，心跳消息间隔为 5 秒
modparam("event_rabbitmq", "server_id","[ID2] uri = amqp://127.0.0.1;
heartbeat = 5")
...
# TLS 连接
modparam("event_rabbitmq", "server_id","[ID3] uri = amqps://127.0.0.1; tls_domain=rmq")
...
		
```


### 导出的函数


#### rabbitmq_publish(server_id, routing_key, message [, [content_type [, headers, headers_vals]]])


向 RabbitMQ 服务器发送发布消息。


此函数还允许您在 AMQP 消息中附加 AMQP 头和值。这是通过指定一组头名称（在 *headers* 参数中）和相应的值（在 *headers_vals* 参数中）来完成的。*headers* 中 AVP 值的数量必须与 *headers_vals* 中的数量相同。


此函数可用于任何路由。


函数具有以下参数：


- *server_id* (string) - RabbitMQ 服务器的 ID。必须是 *server_id* modparam 中定义的参数之一。
- *routing_key* (string) - 用于传递 AMQP 消息的路由键。
- *message* (string) - 消息正文。
- *content_type* (string, 可选) - 发送消息的内容类型。默认为 *none*。
- *headers* (string, 可选) - 包含 AMQP 消息中头名称的 AVP。如果设置，还必须指定 *headers_vals* 参数。
- *headers_vals* (string, 可选) - 包含 AMQP 头相应值的 AVP。如果设置，还必须指定 *headers* 参数。


```c title="rabbitmq_publish() 函数使用示例"
	...
	rabbitmq_publish("ID1", "call", "$fU called $rU");
	...
	rabbitmq_publish("ID1", "call", "{ \'caller\': \'$fU\',
					\'callee\; \'$rU\'", "application/json");
	...
	$avp(hdr_name) = "caller";
	$avp(hdr_value) = $fU;
	$avp(hdr_name) = "callee";
	$avp(hdr_value) = $rU;
	rabbitmq_publish("ID2", "call", $rb, , $avp(hdr_name), $avp(hdr_value));
	...
	
```


### 示例


这是 pike 模块在决定应阻止 IP 时引发的事件示例：


```c title="E_PIKE_BLOCKED 事件"
{
  "jsonrpc": "2.0",
  "method": "E_PIKE_BLOCKED",
  "params": {
    "ip": "192.168.2.11"
  }
}
```


```c title="RabbitMQ 套接字"
	rabbitmq:guest:guest@127.0.0.1:5672/pike

	# 相同套接字也可以写为
	rabbitmq:127.0.0.1/pike

	# TLS 代理连接
	rabbitmq:127.0.0.1/tls_domain=rmq?pike
```


### 安装和运行


#### OpenSIPS 配置文件


此配置文件展示了 event_rabbitmq 模块的使用。在此场景中，每次 OpenSIPS 收到 MESSAGE 请求时，都会向 RabbitMQ 服务器发送一条消息。传递给服务器的参数是 R-URI 用户名和消息正文。


[OpenSIPS 配置文件 - event_rabbitmq 使用示例](./samples.md "include")


## 常见问题


**Q: AMQP 消息的最大长度是多少？**


datagram 事件的最大长度为 16384 字节。


**Q: 在哪里可以找到更多关于 OpenSIPS 的信息？**


请查看 [https://opensips.org/](https://opensips.org/)。


**Q: AMQP 服务器使用的 vhost 是什么？**


目前唯一支持的 vhost 是 *'/'*。


**Q: 如何在套接字中设置 vhost？**


此版本不支持不同的 vhost。


**Q: 如何将事件发送到我的 RabbitMQ 服务器？**


此模块充当 OpenSIPS Event Interface 的传输模块。因此，此模块应遵循 Event Interface 行为：

第一步是订阅 RabbitMQ 服务器到 OpenSIPS Event Interface。这可以使用 *subscribe_event* 核心函数完成：

下一步是从脚本中引发事件，使用 *raise_event* 核心函数：

请注意，上面使用的事件仅用于说明脚本中的用法。任何通过 OpenSIPS Event Interface 发布的事件都可以使用此模块引发。


**Q: 在哪里可以找到更多关于 RabbitMQ 的信息？**


您可以在他们的官方网站上找到更多关于 RabbitMQ 的信息
			（[http://www.rabbitmq.com/](http://www.rabbitmq.com/)）。


**Q: 在哪里可以发布关于此模块的问题？**


首先检查您的问题是否已在我们的邮件列表中得到解答：

		关于任何稳定版 OpenSIPS 版本的电子邮件应发送至
			users@lists.opensips.org，关于开发版本的电子邮件
			应发送至 devel@lists.opensips.org。

如果您希望保密邮件，请发送至
			users@lists.opensips.org。


**Q: 如何报告 bug？**


请按照以下指南操作：
			[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用 Creative Common License 4.0 许可证
