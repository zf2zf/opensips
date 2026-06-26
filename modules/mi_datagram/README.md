---
title: "mi_datagram 模块"
description: "这是一个为管理接口提供UNIX/UDP SOCKET传输层实现的模块。"
---

## 管理指南


### 概述


这是一个为管理接口提供UNIX/UDP SOCKET传输层实现的模块。


### DATAGRAM命令语法


MI请求和回复遵循JSON-RPC语法。


如果是由MI引擎生成的错误（主要是内部错误），则会在datagram中发送纯文本错误消息。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他OpenSIPS模块*。


#### 外部库或应用程序


运行此模块加载的OpenSIPS之前必须安装以下库或应用程序：


- *无*


### 导出的参数


#### socket_name (string)


UNIX SOCKET的名称或IP地址。UNIX datagram或UDP socket将使用此参数创建，以便读取外部命令。同时支持IPv4和IPv6。


*默认值为NONE。*


```c title="设置 socket_name 参数"
...
modparam("mi_datagram", "socket_name", "/tmp/opensips.sock")
...
modparam("mi_datagram", "socket_name", "udp:192.168.2.133:8080")
...
```


#### children_count (string)


要创建的子进程数量。每个子进程都将成为一个datagram服务器。


*默认值为1。*


```c title="设置 children_count 参数"
...
modparam("mi_datagram", "children_count", 3)
...
```


#### unix_socket_mode (integer)


创建监听UNIX datagram socket时要使用的权限。不适用于UDP socket。它遵循UNIX约定。


*默认值为0660 (rw-rw----)。*


```c title="设置 unix_socket_mode 参数"
...
modparam("mi_datagram", "unix_socket_mode", 0600)
...
```


#### unix_socket_group (integer) unix_socket_group (string)


创建监听UNIX socket时要使用的组。


*默认值为继承的值。*


```c title="设置 unix_socket_group 参数"
...
modparam("mi_datagram", "unix_socket_group", 0)
modparam("mi_datagram", "unix_socket_group", "root")
...
```


#### unix_socket_user (integer) unix_socket_group (string)


创建监听UNIX socket时要使用的用户。


*默认值为继承的值。*


```c title="设置 unix_socket_user 参数"
...
modparam("mi_datagram", "unix_socket_user", 0)
modparam("mi_datagram", "unix_socket_user", "root")
...
```


#### socket_timeout (integer)


尝试发送回复的过期时间，以socket_timeout毫秒为单位。


*默认值为2000。*


```c title="设置 socket_timeout 参数"
...
modparam("mi_datagram", "socket_timeout", 2000)
...
```


#### trace_destination (string)


跟踪模块中定义的跟踪目标。目前唯一的跟踪模块是**proto_hep**。跟踪的MI消息将发送到此处。


**警告：**必须加载跟踪模块此参数才能工作。（例如**proto_hep**）。


*默认值为无（未定义）。*


```c title="设置 trace_destination 参数"
...
modparam("proto_hep", "trace_destination", "[hep_dest]10.0.0.2;transport=tcp;version=3")

modparam("mi_datagram", "trace_destination", "hep_dest")
...
```


#### trace_bwlist (string)


根据黑名单或白名单过滤跟踪的MI命令。必须定义**trace_destination**此参数才有意义。白名单可以使用'w'或'W'定义，黑名单使用'b'或'B'。类型与实际黑名单之间用':'分隔。列表中的MI命令必须用','分隔。


定义黑名单意味着所有未被列入黑名单的命令都将被跟踪。定义白名单意味着所有未被列入白名单的命令都不会被跟踪。
**警告：**不能同时定义白名单和黑名单。只允许其中一种。第二次定义参数将覆盖第一个。


**警告：**必须加载跟踪模块此参数才能工作。（例如**proto_hep**）。


*默认值为无（未定义）。*


```c title="设置 trace_destination 参数"
...
## 黑名单ps和which MI命令
## 所有其他命令将被跟踪
modparam("mi_datagram", "trace_bwlist", "b: ps, which")
...
## 只允许sip_trace MI命令
## 所有其他命令都不会被跟踪
modparam("mi_datagram", "trace_bwlist", "w: sip_trace")
...
```


#### pretty_printing (int)


指示通过MI发送的JSONRPC响应是否应该被美化打印。


*默认值为"0 - 不美化打印"。*


```c title="设置 pretty_printing 参数"
...
modparam("mi_fifo", "pretty_printing", 1)
...
```


#### socket_buf_size (integer)


接收和发送时使用的最大缓冲区大小。


*默认值为65457。*


```c title="设置 socket_buf_size 参数"
		...
		modparam("mi_datagram", "socket_buf_size", 131072)
		...
			
```


### 导出的函数


没有导出到配置文件使用的函数。


### 示例


这是一个显示"get_statistics dialog: tm:" MI命令的DATAGRAM格式示例：请求。


```c title="DATAGRAM请求"
{"jsonrpc":"2.0","method":"get_statistics","id":"1065","params":[["dialog:","tm:"]]}
```


## 常见问题


**问：UNIX和UDP类型的socket可以同时创建吗？**


此版本一次只支持一种socket类型。如果socket_name有多个值，最后一个将生效。


**问：datagram请求的大小有限制吗？**


datagram请求或回复的最大长度是65457字节。


**问：在哪可以找到更多关于OpenSIPS的信息？**


请查看[https://opensips.org/](https://opensips.org/)。


**问：在哪可以发布关于此模块的问题？**


首先检查您的问题是否已在我们的邮件列表中得到解答：

关于任何稳定OpenSIPS版本的电子邮件应发送至users@lists.opensips.org，关于开发版本的电子邮件应发送至devel@lists.opensips.org。

如果您想保持邮件私密，请发送至users@lists.opensips.org。


**问：如何报告错误？**


请按照以下指南：[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即.md扩展名）均采用知识共享署名4.0许可证。
