---
title: "mi_xmlrpc 模块"
description: "本模块实现了一个 xmlrpc 服务器，用于处理 xmlrpc 请求并生成 xmlrpc 响应。当收到 xmlrpc 消息时，将执行默认方法。"
---

## 管理指南


### 概述


本模块实现了一个 xmlrpc 服务器，用于处理 xmlrpc 请求并生成 xmlrpc 响应。
当收到 xmlrpc 消息时，将执行默认方法。


首先，它查找 MI 命令。
如果找到，则将调用的过程的参数解析为 MI 树，然后执行该命令。
返回一个 MI 回复树，该树被格式化为 xmlrpc 格式。
响应以两种方式构建 - 一种是包含 MI 树节点信息（名称、值和属性）的字符串，
另一种是由每个 MI 树节点存储的信息组成的数组。


### 依赖


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *libxml2*


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *httpd* 模块。


### 导出的参数


#### http_root (string)


指定 xmlrpc 请求的根路径：
http://[opensips_IP]:[opensips_httpd_port]/[http_root]


*默认值为 "RPC2"。*


```c title="设置 http_root 参数"
...
modparam("mi_xmlrpc", "http_root", "opensips_mi_xmlrpc")
...
```


#### trace_destination (string)


跟踪目标，定义在跟踪模块中。
目前唯一的跟踪模块是 **proto_hep**。
跟踪的 mi 消息将发送到这里。


**警告：** 必须加载跟踪模块此参数才能工作。
（例如 **proto_hep**）。


*默认值为无（未定义）。*


```c title="设置 trace_destination 参数"
...
modparam("proto_hep", "trace_destination", "[hep_dest]10.0.0.2;transport=tcp;version=3")

modparam("mi_xmlrpc", "trace_destination", "hep_dest")
...
```


#### trace_bwlist (string)


基于黑名单或白名单过滤跟踪的 mi 命令。
**trace_destination** 必须定义此参数才能生效。
白名单可以使用 'w' 或 'W' 定义，黑名单使用 'b' 或 'B'。
类型与实际黑名单之间用 ':' 分隔。
列表中的 mi 命令必须用 ',' 分隔。


定义黑名单意味着所有未被列入黑名单的命令都将被跟踪。
定义白名单意味着所有未被列入白名单的命令都不会被跟踪。
**警告：** 不能同时定义白名单和黑名单。
只允许其中一种。第二次定义此参数将覆盖第一次的值。


**警告：** 必须加载跟踪模块此参数才能工作。
（例如 **proto_hep**）。


*默认值为无（未定义）。*


```c title="设置 trace_destination 参数"
...
## 黑名单 ps 和 which mi 命令
## 所有其他命令都将被跟踪
modparam("mi_xmlrpc", "trace_bwlist", "b: ps, which")
...
## 仅允许 sip_trace mi 命令
## 所有其他命令都不会被跟踪
modparam("mi_xmlrpc", "trace_bwlist", "w: sip_trace")
...
```


### 导出的函数


配置文件中没有导出可供使用的函数。


### 已知问题


大型响应的命令（如 ul_dump）如果 httpd 缓冲区配置太小（或没有配置足够的 pkg 内存）将会失败。


httpd 和 mi_xmlrpc 模块的未来版本将解决此问题。


### 示例


这是一个展示 "get_statistics net: shmem:" MI 命令的 xmlrpc 格式的示例：
响应。


```c title="XMLRPC 请求"
POST /xmlrpc HTTP/1.0
Host: my.host.com
User-Agent: My xmlrpc UA
Content-Type: text/xml
Content-Length: 216

<?xml version='1.0'?>
<methodCall>
	<methodName>get_statistics</methodName>
	<params>
		<param>
		<value>
		<struct>
		<member>
			<name>statistics</name>
			<value>
			<array>
			<data>
				<value><string>shmem:</string></value>
				<value><string>core:</string></value>
			</data>
			</array>
			</value>
		</member>
		</struct>
		</value>
		</param>
	</params>
</methodCall>


HTTP/1.0 200 OK
Content-Length: 236
Content-Type: text/xml; charset=utf-8
Date: Mon, 8 Mar 2013 12:00:00 GMT

<?xml version="1.0" encoding="UTF-8"?>.
<methodResponse>
<params><param>
<value><struct><member><name>net:waiting_udp</name><value><string>0</string></value></member><member><name>net:waiting_tcp</name><value><string>0</string></value></member><member><name>net:waiting_tls</name><value><string>0</string></value></member><member><name>shmem:total_size</name><value><string>268435456</string></value></member><member><name>shmem:used_size</name><value><string>40032</string></value></member><member><name>shmem:real_used_size</name><value><string>277112</string></value></member><member><name>shmem:max_used_size</name><value><string>277112</string></value></member><member><name>shmem:free_size</name><value><string>268158344</string></value></member><member><name>shmem:fragments</name><value><string>194</string></value></member></struct></value></param></params>
</methodResponse>.
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议。
