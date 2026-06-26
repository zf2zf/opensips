---
title: "RabbitMQ Consumer 模块"
description: "*RabbitMQ Consumer* ([http://www.rabbitmq.com/](http://www.rabbitmq.com/)) 是一个开源消息服务器。其目的是管理队列中接收到的消息，利用灵活的 AMQP 协议。"
---

## 管理指南


### 概述


*RabbitMQ Consumer*
		([http://www.rabbitmq.com/](http://www.rabbitmq.com/)) 
	是一个开源消息服务器。其目的是管理队列中接收到的消息，利用灵活的
		AMQP 协议。


使用此模块，您可以向 RabbitMQ broker 订阅消费者，以接收指定队列的 AMQP 消息。消息将通过 OpenSIPS 事件接口触发事件来传递。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *tls_mgm*（如果启用了 [use tls](#param_use_tls)）。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *librabbitmq-dev*


请注意，该模块与 librabbitmq-dev 库 0.4 或更低版本不兼容。


### 导出的参数


#### connection_id (string)


指定 RabbitMQ 连接的配置。它包含一组用于自定义到服务器的连接以及消费者订阅的参数。参数格式为
			*param1=value1; param2=value2;*。
			*uri*、*queue* 和
			*event* 参数是必需的。


可以为每个 RabbitMQ 连接多次设置此参数。


可使用以下参数：


- *uri* - 必需参数 - 一个完整的
				*amqp* URI（如
				[此处](https://www.rabbitmq.com/uri-spec.html) 所述）。
				URI 中缺失的字段将接收默认值，
				例如：*user: guest*、
				*password: guest*、
				*host: localhost*、
				*vhost: /*、
				*port: 5672*。TLS 连接使用 *amqps* URI 指定。
- *queue* - 必需参数 - 订阅消费者的
				RabbitMQ 队列名称。此参数是必需的。
- *event* - 必需参数 - 为每个接收到的 AMQP 消息触发的 OpenSIPS
				事件的名称。
- *ack* - 指示 broker
				消息将在收到后被确认的标志。如果不设置此标志，服务器将不会期望 ACK，OpenSIPS 也不会发送它们。
- *exclusive* - 指示 broker
				请求独占消费者访问的标志，这意味着只有此消费者可以访问该队列。
- *frame_max* - AMQP
				帧的最大大小。默认大小为 131072。
- *heartbeat* - 发送
				心跳消息的间隔（以秒为单位）。默认禁用。
- *tls_domain* - 指示此连接使用哪个 TLS 域（使用
				*tls_mgm* 模块定义）的参数。这必须是 *amqps* URI，并且必须启用
				[use tls](#param_use_tls) 模块参数。


```c title="设置 connection_id 参数"
...
# 连接到本地主机上默认端口的 RabbitMQ 服务器
# 心跳消息间隔为 5 秒
modparam("rabbitmq_consumer", "connection_id",
    "uri = amqp://127.0.0.1; queue = myqueue1; event = E_Q1_MSG; heartbeat = 5;")
...
# 确认消息的消费者
modparam("rabbitmq_consumer", "connection_id",
    "uri = amqp://127.0.0.1; queue = myqueue2; event = E_Q2_MSG; ack;")
...
# TLS 连接
modparam("rabbitmq_consumer", "connection_id",
    "uri = amqps://127.0.0.1; queue = myqueue3; event = E_Q3_MSG; tls_domain=rmq;")
...
		
```


#### connect_timeout (integer)


与 RabbitMQ 服务器建立 TCP 连接的最大允许持续时间（以毫秒为单位）。


*默认值为 "500"（毫秒）。*


```c title="设置 connect_timeout 参数"
...
modparam("rabbitmq_consumer", "connect_timeout", 1000)
...
```


#### retry_timeout (integer)


OpenSIPS 尝试重新建立到 RabbitMQ 服务器的失败 AMQP 连接的间隔（以毫秒为单位）。


*默认值为 "5000"（毫秒）。*


```c title="设置 retry_timeout 参数"
...
modparam("rabbitmq_consumer", "retry_timeout", 10000)
...
```


#### use_tls (integer)


设置此参数将允许您对 broker 连接使用 TLS。要为特定连接启用 TLS，可以使用 [connection id](#param_connection_id) 模块参数中指定的配置中的
			"tls_domain=*dom_name*" 参数。


使用此参数时，还必须确保 *tls_mgm* 已加载并正确配置。请参阅模块以获取关于 TLS 客户端域的更多信息。


*默认值为 **0**（未启用）*


```c title="设置 use_tls 参数"
...
modparam("tls_mgm", "client_domain", "rmq")
modparam("tls_mgm", "certificate", "[rmq]/etc/pki/tls/certs/rmq.pem")
modparam("tls_mgm", "private_key", "[rmq]/etc/pki/tls/private/rmq.key")
modparam("tls_mgm", "ca_list",     "[rmq]/etc/pki/tls/certs/ca.pem")
...
modparam("rabbitmq_consumer", "use_tls", 1)
...
```


### 导出的函数


该模块不导出任何脚本函数。


### 导出的事件


对于每个接收到的 AMQP 消息，将引发一个具有自定义名称的事件，该名称在 [connection id](#param_connection_id) 参数的 *event*
		字段中设置。


参数：


- *body* - AMQP 消息正文。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0（Creative Common License 4.0）授权。
