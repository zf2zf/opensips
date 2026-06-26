---
title: "JANUS 模块"
description: "*\"janus\"* 模块是 Janus WebSocket 协议的 C 驱动程序。它可以通过向一个或多个 Janus 服务器发送命令或从它们接收事件来与它们交互。"
---

## 管理指南


### 概述


*"janus"* 模块是 Janus WebSocket 协议的 C 驱动程序。
		它可以通过向一个或多个 Janus 服务器发送命令或从它们接收事件来与它们交互。


此驱动程序可以被视为一个集中的 Janus 连接管理器。
		它将连接到每个 Janus 服务器，建立连接处理器 ID，
		客户端可以从连接处理器 ID 的角度透明地工作，
		只需传递他们想要运行的所需 Janus 命令。


### 外部库或应用程序


#### OpenSIPS 模块


加载此模块时必须同时加载以下模块：


- *SQL 数据库模块*


运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- *无*


### 导出的参数


#### janus_send_timeout (整数)


在 OpenSIPS 想要在其上发送内容但连接不可用于阻塞写入的情况下，
		Janus WebSocket 连接将被关闭的时间（毫秒）。


*默认值为 "1000"（毫秒）。*


```c title="设置 janus_send_timeout 参数"
...
modparam("janus", "janus_send_timeout", 2000)
...
```


#### janus_max_msg_chunks (整数)


期望通过 WebSocket 接收的 Janus 消息被分成的最大块数。
		如果接收到的数据包比这更碎片化，则连接将被断开。


*默认值为 "4"*


```c title="设置 janus_max_msg_chunks 参数"
...
modparam("janus", "janus_max_msg_chunks", 8)
...
```


#### janus_cmd_timeout (整数)


执行 Janus 命令所允许的最大持续时间。
		此间隔不包括连接持续时间。


*默认值为 "5000"（毫秒）。*


```c title="设置 janus_cmd_timeout 参数"
...
modparam("janus", "janus_cmd_timeout", 3000)
...
```


#### janus_cmd_polling_itv (整数)


轮询 Janus 命令响应时使用的睡眠间隔。由于此参数的值强制任何 Janus 命令的最小持续时间，
		您应该首先在调试模式下运行 OpenSIPS 以确定任意 Janus 命令的预期响应时间，
		然后相应地调整此参数。


*默认值为 "1000"（微秒）。*


```c title="设置 janus_cmd_polling_itv 参数"
...
modparam("janus", "janus_cmd_polling_itv", 3000)
...
```


#### janus_ping_interval (整数)


OpenSIPS 在 Janus 连接上执行保活 ping 的时间间隔。


*默认值为 "5"（秒）。*


```c title="设置 janus_ping_interval 参数"
...
modparam("janus", "janus_ping_interval", 10)
...
```


#### janus_db_url (字符串)


OpenSIPS 从中加载 Janus 连接列表的数据库 URL。


*默认值为 ""none""（需要设置才能启动模块）。*


```c title="设置 janus_db_url 参数"
...
modparam("janus", "janus_db_url", "mysql://root@localhost/opensips")
...
```


#### janus_db_table (字符串)


OpenSIPS 从中加载 Janus 连接列表的数据库表。


*默认值为 "janus"*


```c title="设置 janus_db_table 参数"
...
modparam("janus", "janus_db_table", "my_janus_table")
...
```


### 导出的函数


#### janus_send_requeest(janus_id, janus_command[, response_var])


在任意 Janus 套接字上运行任意命令。
		janus_id 必须在数据库中定义。


当前 OpenSIPS 工作进程将阻塞，直到收到 Janus 的回答。
		此操作的超时时间可通过 **janus_cmd_timeout** 参数控制。


参数的含义如下：


- *janus_id* (字符串) - 数据库中定义的 janus 连接 ID。
- *janus_command* (字符串) - 要运行的 JANUS 命令。
- *response_var* (变量，可选) - 一个变量，用于保存 Janus 命令的文本结果。


**返回值**


- 1（成功）-- Janus 命令执行成功，任何
				输出变量都被成功写入。请注意，这并不说明 Janus 响应的性质
				（它可能是一个 "-ERR" 类型的响应）
- -1（失败）-- 内部错误或 Janus 命令未能
				执行


此函数可用于任何路由。


```c title="*janus_send_request()* 用法"
...
# 如果数据库包含：
#       id: 1
# janus_id: test_janus
# janus_url: janusws://my_janus_host:80/janus?room=abcd

	$var(rc) = janus_send_request("test_janus", "{
  "janus": "attach",
  "plugin": "janus.plugin.videoroom",
  "transaction": "abcdef123456",
  "session_id": 987654321
}", $var(response));
	if (!$var(rc)) {
		xlog("failed to execute Janus command ($var(rc))\n");
		return -1;
	}
	xlog("Janus response is $var(response) \n");
...
...
```


#### 导出的事件


##### E_JANUS_EVENT


当从 Janus 服务器收到通知时触发此事件。


参数表示发起通知的 janus_id 和 janus_url，以及收到的完整 janus_body。


- *janus_id* - 数据库中定义的 janus ID
- *janus_url* - 数据库中定义的 janus URL
- *janus_body* - 从 janus 收到的通知的完整主体


```c title="*E_JANUS_EVENT* 示例"
...
# 如果数据库包含：
#       id: 1
# janus_id: test_janus
# janus_url: janusws://my_janus_host:80/janus?room=abcd

event_route[E_JANUS_EVENT] {
	xlog("Received janus event from $param(janus_id) - $param(janus_url) - $param(janus_body) \n");
	$json(janus_body) := $param(janus_body);
	$avp(janus_sender) =  $json(janus_body/sender);
	if ($avp(janus_sender) != NULL) {
		xlog("Received event from sender $avp(janus_sender) \n");
	}
}
...
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议。
