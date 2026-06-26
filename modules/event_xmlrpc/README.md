---
title: "event_xmlrpc 模块"
description: "此模块是 XMLRPC 客户端的实现，用于在 OpenSIPS 引发某些通知时通知 XMLRPC 服务器。它充当 Event Notification Interface 的传输层。"
---

## 管理指南


### 概述


此模块是 XMLRPC 客户端的实现，用于在 OpenSIPS 引发某些通知时通知 XMLRPC 服务器。它充当 Event Notification Interface 的传输层。


基本上，当使用 Event Interface 从 OpenSIPS 的脚本、核心或模块引发事件时，模块执行远程过程调用。


为了接收通知，XMLRPC 服务器需要订阅 OpenSIPS 提供的某个事件。这可以使用通用 MI Interface（*event_subscribe* 函数）或从 OpenSIPS 脚本（*subscribe_event* 核心函数）完成。


### XMLRPC 套接字语法


*'xmlrpc:' host ':' port ':' method*


含义：


- *'xmlrpc:'* - 通知 Event Interface，发送到此订阅者的事件应由 *event_xmlrpc* 模块处理。
- *host* - XMLRPC 服务器的主机名。
- *port* - XMLRPC 服务器的端口。
- *method* - XMLRPC 客户端远程调用的方法。
					注意：客户端不等待来自 XMLRPC 服务器的响应。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *无*。


#### 外部库或应用程序


运行加载此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *无*


### 导出的参数


#### use_struct_param (integer)


引发事件时，将参数的名称和值打包到 XMLRPC 结构中。这为某些 XMLRPC 服务器实现提供了一种更简单的方式来解释参数。将其设置为零以禁用，或设置为非零以启用。


*默认值为 "0（禁用）"。*


```c title="设置 use_struct_param 参数"
...
modparam("event_xmlrpc", "use_struct_param", 1)
...
```


### 导出的函数


没有可从配置文件使用的函数。


### 示例


这是 pike 模块在决定应阻止 IP 时引发的事件示例：


```c title="E_PIKE_BLOCKED 事件"
POST /RPC2 HTTP/1.1.
Host: 127.0.0.1:8081.
Connection: close.
User-Agent: OpenSIPS XMLRPC Notifier.
Content-type: text/xml.
Content-length: 240.
		.
<?xml version="1.0"?>
<methodCall>
	<methodName>e_dummy_h</methodName>
	<params>
		<param>
			<value><string>E_MY_EVENT</string></value>
		</param>
		<param>
			<name>ip</name>
			<value><string>192.168.2.11</string></value>
		</param>
	</params>
</methodCall>
```


```c title="XMLRPC 套接字"
	# 调用 'block_ip' 函数
	xmlrpc:127.0.0.1:8080:block_ip
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用 Creative Common License 4.0 许可证
