---
title: "event_stream 模块"
description: "此模块为 Event Interface 提供 TCP 传输层实现。该模块可以发送 JSON-RPC 通知或标准请求并等待响应（当在 *reliable_mode* 中使用时）。"
---

## 管理指南


### 概述


此模块为 Event Interface 提供 TCP 传输层实现。该模块可以发送 JSON-RPC 通知或标准请求并等待响应（当在 *reliable_mode* 中使用时）。


由于 JSON-RPC 直接通过 TCP 发送，避免了任何应用传输层（如 HTTP），此模块提供了一种非常轻量级和可靠的方式来向应用服务器传递事件。


为了接收通知，JSON-RPC 服务器需要订阅 OpenSIPS 提供的某个事件。这可以使用通用 MI Interface（*event_subscribe* 函数）或从 OpenSIPS 脚本（*subscribe_event* 核心函数）完成。


### Stream 套接字语法


*'tcp:' host ':' port ['/' method]*


含义：


- *'tcp:'* - 指定 Event Interface 用来发送命令的传输协议。*tcp* 令牌表示订阅者的事件应使用 *event_stream* 模块通知。
- *host* - JSON-RPC 服务器的主机名。
- *port* - JSON-RPC 服务器的端口。
- *method* - JSON-RPC 客户端远程调用的方法。
					注意：此参数是可选的——如果缺失，则使用实际订阅的事件（即如果 *localhost:8080* 订阅了 *E_PIKE_BLOCKED* 事件，RPC 调用将使用 *E_PIKE_BLOCKED* 方法）。


JSON-RPC 命令构建如下：


- *id* - 如果使用 *reliable_mode*，则唯一生成，否则（用于通知）为 *null*。
- *method* - 如果套接字中未指定方法，则设置为事件名称，否则使用指定的令牌。
- *params* - 如果发送的事件包含命名参数，则此参数包含一个 JSON 对象，每个参数一个对象。如果发送的事件仅包含值，则参数将作为数组发送。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *无*。


#### 外部库或应用程序


运行加载此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *无*


### 导出的参数


#### reliable_mode (integer)


此参数控制 *event_stream* 模块与 JSON-RPC 服务器通信的方式。如果启用（设置为 *1*），每个事件都被转换为 JSON-RPC 请求。如果禁用，每个事件将作为 JSON-RPC 通知发送——我们的客户端不会期望回复。


请注意，如果您需要与 JSON-RPC 服务器进行可靠通信，其中发送的每个事件都需要确认（通过 JSON-RPC 响应），则必须将此参数设置为 *1/yes*。如果您在故障转移设置中使用此模块（使用 *event_virtual* 模块），建议将此参数设置为 *1/yes*。


*默认值为 "0（禁用）"。*


```c title="设置 reliable_mode 参数"
...
modparam("event_stream", "reliable_mode", yes)
...
```


#### timeout (integer)


指定模块等待命令完成的毫秒数。在 *reliable_mode* 中，它指定模块等待请求发送和接收回复的时间。在非 *reliable_mode* 中，它仅表示 opensips 发送 JSON-RPC 通知所需的时间。


请注意，如果事件没有为其参数使用名称，则事件将成为 JSON-RPC 命令中的第一个参数。


*默认值为 "1000 毫秒 = 1 秒"。*


```c title="设置 timeout 参数"
...
# 仅等待 200 毫秒获取回复
modparam("event_stream", "timeout", 200)
...
```


#### event_param (string)


默认情况下，订阅的事件名称不会在 JSON-RPC 命令中发送。如果需要发送事件名称，可以使用此参数指定 params 中将包含事件名称的 JSON 对象名称。


*默认值为 "disabled" - 不添加事件。*


```c title="设置 event_param 参数"
...
modparam("event_stream", "event_param", "opensips_event")
# 生成的 json 将包含 "opensips_event": EVENT 令牌
...
```


### 导出的函数


没有可从配置文件使用的函数。


### 示例


```c title="Stream 套接字"
	# 调用 'block_ip' 方法
	tcp:127.0.0.1:8080/block_ip

	# 如果订阅了 E_PIKE_BLOCKED 事件，则调用 'E_PIKE_BLOCKED' 方法
	tcp:127.0.0.1:8080
```


#### JSON-RPC 通知


这是当 *reliable_mode* 被禁用时，pike 模块在决定应阻止 IP 时引发的事件示例：


```c title="E_PIKE_BLOCKED JSON-RPC 通知"
{
	"jsonrpc": "2.0",
	"method": "E_PIKE_BLOCKED",
	"params": {
		"ip": "192.168.2.11"
	}
}
```


#### JSON-RPC 请求


这是在 *reliable_mode* 中，pike 模块在决定应阻止 IP 时引发的事件示例：


```c title="E_PIKE_BLOCKED JSON-RPC 请求 (reliable_mode)"
# 请求
{
	"id": 915243442,
	"jsonrpc": "2.0",
	"method": "E_PIKE_BLOCKED",
	"params": {
		"ip": "192.168.2.11"
	}
}

# 回复
{
	"jsonrpc": "2.0",
	"result": 8,
	"id": 915243442
}
```


#### 带事件名称的 JSON-RPC 通知


当 *event_param* 设置为 *opensips_event* 时，pike 模块引发的事件将如下所示：


```c title="带事件名称的 E_PIKE_BLOCKED 通知"
# 模块配置
modparam("event_stream", "event_param", "opensips_event")

# Stream 套接字: tcp:HOST:PORT/handle_cmd

# 发送的 JSON-RPC 命令
{
	"jsonrpc": "2.0",
	"method": "handle_cmd",
	"params": {
		"opensips_event": "E_PIKE_BLOCKED"
		"ip": "192.168.2.11"
	}
}
```


#### 从脚本发送自定义 JSON-RPC 通知


此示例包含使用 *event_stream* 模块从脚本发送自定义事件的代码片段。


请注意，我们仅为事件填充值，没有为这些值分配名称。因此，参数将作为数组发送。


```c title="E_PIKE_BLOCKED 事件"
startup_route {
	subscribe_event("E_MY_EVENT", "tcp:127.0.0.1:8080");
}

route {
	...
	$avp(attr-val) = 3;
	$avp(attr-val) = 5;
	raise_event("E_MY_EVENT", $avp(attr-val));
	...
}

# 发送的 JSON-RPC 命令
{
	"jsonrpc": "2.0",
	"method": "E_MY_EVENT",
	"params": [3, 5]
}
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用 Creative Common License 4.0 许可证
