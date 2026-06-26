---
title: "动态套接字管理模块"
description: "该模块提供了在运行时为 OpenSIPS 配置和管理动态套接字的方法。套接字的定义存储在 SQL 数据库中，可以在运行时动态更改。"
---

## 管理指南


### 概述


该模块提供了在运行时为 OpenSIPS 配置和管理动态套接字的方法。
套接字的定义存储在 SQL 数据库中，可以在运行时动态更改。


该模块缓存整个 sockets 表，仅在通过
[mi reload](#mi_reload) MI 命令重新加载后才调整动态套接字列表。


[mi list](#mi_list) MI 命令
	可用于显示 OpenSIPS 正在监听的所有动态套接字。


### 套接字


该模块专门处理用于 SIP 流量的套接字（如 UDP、TCP、TLS、WSS）。
它不支持 BIN 或 HEP 监听器，因为这些无法在脚本中动态利用或强制执行。


动态套接字的管理分为两种行为，
	取决于流量是基于 UDP 还是基于 TCP。
根据流量的性质，确保正确调整您的设置以适应
	您可能动态配置的任何套接字。


#### UDP 处理


所有动态添加的 UDP 套接字都被分配给一组专用的额外进程。
这些进程的数量可以通过 [processes](#param_processes) 参数进行调整。
这些进程通过在负载较轻的进程之间平衡请求来均匀处理基于 UDP 的套接字流量。
但是，静态套接字绑定到指定的进程，而动态套接字共享额外进程的池。


#### TCP 处理


与 UDP 流量处理相比，TCP 流量的处理方式与所有其他 TCP 流量相同：
请求被分派到现有静态 TCP 进程之一。


### 限制


虽然动态工作者的流量处理与静态工作者非常相似，
	但使用动态套接字存在某些限制：


- UDP 套接字处理目前不能从指定额外进程的
			自动扩展功能中受益。
			这意味着启动时定义的 [processes](#param_processes) 数量将始终被分叉，
			只有这些进程将处理与动态添加的 UDP 套接字相关的所有流量。
- 如前所述，该模块仅支持基于 SIP 的动态监听器，不支持 HEP 或 BIN。
- 数据库中定义的套接字不能扩展到多个监听器。
			这意味着您不能使用接口名称或解析为多个 IP 的别名作为主机。
			只会创建一个 IP:port 套接字，因此配置应该理想地使用显式 IP 完成。
- 由于某些内部限制，动态套接字需要在启动时预分配。
			这意味着运行时使用的动态套接字数量必须限制为启动时定义的静态值。
			这就是为什么建议为 [max sockets](#param_max_sockets) 参数中的套接字使用相当高的值——
			我们默认为 100 个舒适的套接字。
- [max sockets](#param_max_sockets) 中定义的套接字
			以 FIFO 方式轮换——这样我们试图避免在短时间内重叠套接字。


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *需要数据库模块来获取套接字*。


#### 外部库或应用程序


运行 OpenSIPS 并加载此模块之前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### db_url (string)


获取套接字的数据库 URL。


*默认值为 "mysql://opensips:opensipsrw@localhost/opensips"。*


```c title="设置 'db_url' 参数"
...
modparam("sockets_mgm", "db_url", "dbdriver://username:password@dbhost/dbname")
...
```


#### table_name (string)


存储套接字的数据库表名。


*默认值为 "sockets"。*


```c title="设置 'table_name' 参数"
...
modparam("sockets_mgm", "table_name", "sockets_def")
...
```


#### socket_column (string)


存储套接字定义的数据库表列名。


*默认值为 "socket"。*


```c title="设置 'socket_column' 参数"
...
modparam("sockets_mgm", "socket_column", "sock")
...
```


#### advertised_column (string)


存储通告定义的数据库表列名。


*默认值为 "advertised"。*


```c title="设置 'advertised_column' 参数"
...
modparam("sockets_mgm", "advertised_column", "adv")
...
```


#### tag_column (string)


存储标签定义的数据库表列名。


*默认值为 "tag"。*


```c title="设置 'tag_column' 参数"
...
modparam("sockets_mgm", "tag_column", "sock")
...
```


#### flags_column (string)


存储标志定义的数据库表列名。


*默认值为 "flags"。*


```c title="设置 'flags_column' 参数"
...
modparam("sockets_mgm", "flags_column", "sock")
...
```


#### tos_column (string)


存储 tos 定义的数据库表列名。


*默认值为 "tos"。*


```c title="设置 'tos_column' 参数"
...
modparam("sockets_mgm", "tos_column", "sock")
...
```


#### processes (integer)


处理 UDP 套接字的进程数量。


*默认值为 "8"。*


```c title="设置 'processes' 参数"
...
modparam("sockets_mgm", "processes", 32)
...
```


#### max_sockets (integer)


可以动态定义的套接字最大数量。
			有关更多信息，请参见 [限制](#limitations) 部分。


*默认值为 "100"。*


```c title="设置 'max_sockets' 参数"
...
modparam("sockets_mgm", "max_sockets", 2000)
...
```


### 导出的 MI 函数


#### sockets_mgm:reload


替换已弃用的 MI 命令：*sockets_reload*。


用于从数据库重新加载套接字的 MI 命令。


MI FIFO 命令格式：


```c
		## 从数据库重新加载套接字
		opensips-mi sockets_mgm:reload
		opensips-cli -x mi sockets_mgm:reload

```


#### sockets_mgm:list


替换已弃用的 MI 命令：*sockets_list*。


列出所有当前使用的动态套接字的 MI 命令。


MI FIFO 命令格式：


```c
		## 从数据库重新加载套接字
		opensips-mi sockets_mgm:list
		opensips-cli -x mi sockets_mgm:list

```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可证 4.0 版授权
