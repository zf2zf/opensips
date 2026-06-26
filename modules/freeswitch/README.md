---
title: "freeswitch 模块"
description: "*\"freeswitch\"* 模块是 FreeSWITCH Event Socket Layer 接口的 C 驱动程序。它可以通过向 FreeSWITCH 服务器发送命令或从其接收事件来与一个或多个 FreeSWITCH 服务器交互。"
---

## 管理指南


### 概述


*"freeswitch"* 模块是 FreeSWITCH Event Socket Layer 接口的
		C 驱动程序。它可以通过向 FreeSWITCH 服务器发送命令或从其接收事件
		来与一个或多个 FreeSWITCH 服务器交互。


此驱动程序可以看作是一个集中式的 FreeSWITCH ESL 连接管理器。
		OpenSIPS 模块可以使用其 API 来轻松建立、引用和重用 ESL 连接。


FreeSWITCH ESL URL 格式为：
	**fs://[username]:password@host[:port]**。
	默认 ESL 端口为 8021。


### 外部库或应用程序


以下库或应用程序必须在运行
		加载本模块的 OpenSIPS 之前安装：


- *无*


### 导出的参数


#### event_heartbeat_interval (integer)


FreeSWITCH HEARTBEAT 事件到达之间的预期间隔。


*默认值为 "1"（秒）。*


```c title="设置 event_heartbeat_interval 参数"
...
modparam("freeswitch", "event_heartbeat_interval", 20)
...
```


#### esl_connect_timeout (integer)


建立 ESL 连接的最大允许时长。


*默认值为 "5000"（毫秒）。*


```c title="设置 esl_connect_timeout 参数"
...
modparam("freeswitch", "esl_connect_timeout", 3000)
...
```


#### esl_cmd_timeout (integer)


执行 ESL 命令的最大允许时长。
		此间隔不包括连接时长。


*默认值为 "5000"（毫秒）。*


```c title="设置 esl_cmd_timeout 参数"
...
modparam("freeswitch", "esl_cmd_timeout", 3000)
...
```


#### esl_cmd_polling_itv (integer)


轮询 ESL 命令响应时使用的睡眠间隔。
		由于此参数的值对任何 ESL 命令施加了最小持续时间,
		您应该首先在调试模式下运行 OpenSIPS 以确定任意 ESL 命令的预期响应时间,
		然后相应地调整此参数。


*默认值为 "1000"（微秒）。*


```c title="设置 esl_cmd_polling_itv 参数"
...
modparam("freeswitch", "esl_cmd_polling_itv", 3000)
...
```


### 导出的函数
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权
