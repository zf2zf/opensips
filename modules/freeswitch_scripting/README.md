---
title: "freeswitch_scripting 模块"
description: "*freeswitch_scripting* 是一个辅助模块,将 FreeSWITCH ESL 接口的完全控制权暴露给 OpenSIPS 脚本。"
---

## 管理指南


### 概述


*freeswitch_scripting* 是一个辅助模块,
		将 FreeSWITCH ESL 接口的完全控制权暴露给 OpenSIPS 脚本。


它允许 OpenSIPS 脚本编写者订阅通用 FreeSWITCH ESL 事件,
		以及运行任意 FreeSWITCH ESL 命令并解释其结果。
		它使用 [freeswitch](../freeswitch) 模块来管理 ESL 连接和事件订阅。


初始思路和代码示例的功劳归功于 Giovanni Maruzzelli
		<gmaruzz@opentelecom.it>,他提供了 ESL 事件和命令的示例。


### 依赖


#### OpenSIPS 模块


以下模块必须与此模块一起加载：


- *freeswitch*
- *（可选）SQL DB 模块*


#### 外部库或应用程序


以下库或应用程序必须在运行
		加载本模块的 OpenSIPS 之前安装：


- *无*


### 导出的参数


#### db_url (string)


SQL 数据库 URL,模块将使用它来加载一组 FreeSWITCH ESL 套接字及其事件订阅。


*默认值为 "NULL"（DB 支持已禁用）。*


```c title="设置 db_url 参数"
...
modparam("freeswitch_scripting", "db_url", "dbdriver://username:password@dbhost/dbname")
...
```


#### db_table (string)


此模块的 SQL 表名。


*默认值为 "freeswitch"。*


```c title="设置 db_table 参数"
...
modparam("freeswitch_scripting", "db_table", "freeswitch_sockets")
...
```


#### db_col_username (string)


"username" ESL 连接信息的 SQL 列名。


*默认值为 "username"。*


```c title="设置 db_col_username 参数"
...
modparam("freeswitch_scripting", "db_col_username", "user")
...
```


#### db_col_password (string)


"password" ESL 连接信息的 SQL 列名。


*默认值为 "password"。*


```c title="设置 db_col_password 参数"
...
modparam("freeswitch_scripting", "db_col_password", "pass")
...
```


#### db_col_ip (string)


"ip" ESL 连接信息的 SQL 列名。


*默认值为 "ip"。*


```c title="设置 db_col_ip 参数"
...
modparam("freeswitch_scripting", "db_col_ip", "ip_addr")
...
```


#### db_col_port (string)


"port" ESL 连接信息的 SQL 列名。


*默认值为 "port"。*


```c title="设置 db_col_port 参数"
...
modparam("freeswitch_scripting", "db_col_port", "tcp_port")
...
```


#### db_col_events (string)


OpenSIPS 将订阅的以逗号分隔、大小写敏感的 FreeSWITCH
		事件名称的 SQL 列名。


*默认值为 "events_csv"。*


```c title="设置 db_col_events 参数"
...
modparam("freeswitch_scripting", "db_col_events", "fs_events")
...
```


#### fs_subscribe (string)


添加 OpenSIPS 将在启动时连接的 FreeSWITCH ESL URL。
		URL 语法包括支持指定要订阅的事件列表,
		遵循以下模式：
		**[fs://][[username]:password@]host[:port][?event1[,event2]...]**


*此参数可以设置多次。*


```c title="设置 fs_subscribe 参数"
...
modparam("freeswitch_scripting", "fs_subscribe", ":ClueCon@10.0.0.10?CHANNEL_STATE")
modparam("freeswitch_scripting", "fs_subscribe", ":ClueCon@10.0.0.11:8021?DTMF,BACKGROUND_JOB")
...
```


### 导出的函数


#### freeswitch_esl(command, freeswitch_url[, response_var])


在任意 FreeSWITCH ESL 套接字上运行任意命令。
		该套接字不一定需要在数据库中定义或通过
		**[fs subscribe](#param_fs_subscribe)** 定义。
		但是,如果在数据库中定义,则 URL 的 "password" 部分变为必填。


当前 OpenSIPS worker 将阻塞,直到收到来自 FreeSWITCH 的答复。
		此操作的超时时间可以通过
		freeswitch 连接管理器模块的 **esl_cmd_timeout** 参数控制。


参数含义如下：


- *command* (string) - 要执行的 ESL 命令字符串。
- *freeswitch_url* (string) - 要连接的 ESL 接口。
			语法为：[fs://][[username]:password@]host[:port][?event1[,event2]...]。
			URL 的 "?events" 部分将被静默丢弃。
- *response_var (var, 可选)* - 将保存 ESL 命令文本结果的变量。


**返回值**


- 1（成功） - ESL 命令执行成功,所有输出变量都成功写入。
				但请注意,这并不能说明 ESL 答复的性质（它可能是 "-ERR" 类型的响应）。
- -1（失败） - 内部错误或 ESL 命令执行失败。


此函数可用于任何路由。


```c title="*freeswitch_esl()* 使用示例"
...
	# ESL 套接字 10.0.0.10 在数据库中定义（密码 "ClueCon"）
	$var(rc) = freeswitch_esl("bgapi originate {origination_uuid=123456789}user/1010 9386\njob-uuid: foobar", "10.0.0.10", "$var(response)");
	if ($var(rc) < 0) {
		xlog("执行 ESL 命令失败 ($var(rc))\n");
		return -1;
	}
...
	# ESL 套接字 10.0.0.10 是新的,我们必须指定密码
	$var(rc) = freeswitch_esl("bgapi originate {origination_uuid=123456789}user/1010 9386\njob-uuid: foobar", ":ClueCon@10.0.0.10", $var(response));
	if ($var(rc) < 0) {
		xlog("执行 ESL 命令失败 ($var(rc))\n");
		return -1;
	}
...
```


### 导出的 MI 命令


#### freeswitch_scripting:subscribe


替换已废弃的 MI 命令：*fs_subscribe*。


确保给定的 FreeSWITCH ESL 套接字已订阅给定的事件列表。
		如果某个事件无法订阅,freeswitch 驱动程序将定期重试订阅,
		直到发出相应的 freeswitch_scripting:unsubscribe
		MI 命令。


参数：


- *freeswitch_url* - 要连接的 ESL 接口。
				语法为：[fs://][[username]:password@]host[:port][?event1[,event2]...]。
				URL 的 "?events" 部分将被静默丢弃。
- *event* - 要订阅的事件名称。
- *...* - （其他事件）。


#### freeswitch_scripting:unsubscribe


替换已废弃的 MI 命令：*fs_unsubscribe*。


确保给定的 FreeSWITCH ESL 套接字已取消订阅给定的事件列表。


参数：


- *freeswitch_url* - 要查找的 ESL 接口。
				语法为：[fs://][[username]:password@]host[:port][?event1[,event2]...]。
				URL 的 "?events" 部分将被静默丢弃。
- *event* - 要取消订阅的事件名称。
- *...* - （其他事件）。


#### freeswitch_scripting:list


替换已废弃的 MI 命令：*fs_list*。


显示当前 FreeSWITCH ESL 套接字集合以及模块为每个套接字订阅的事件列表。


#### freeswitch_scripting:reload


替换已废弃的 MI 命令：*fs_reload*。


用当前在 "freeswitch" 表中找到的当前数据（ESL 套接字及其事件）替换
		当前 FreeSWITCH ESL 套接字集合及其各自的事件。


* 这包括通过 [fs subscribe](#param_fs_subscribe)、MI
			[mi subscribe](#freeswitch_scripting_subscribe) 命令或先前 DB 数据集配置的任何套接字/事件。


### 导出的事件


#### E_FREESWITCH


当 OpenSIPS 从 "freeswitch_scripting" 模块订阅的套接字收到 ESL 事件通知时引发此事件。


参数：


- *name* - 事件名称。
- *sender* - FreeSWITCH 发送者 IP 地址。
- *body* - 事件的完整 JSON 编码主体,
					由 FreeSWITCH 发送。使用 json 模块（$json 变量）
					可以轻松解释它。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权
