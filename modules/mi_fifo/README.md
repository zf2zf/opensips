---
title: "mi_fifo 模块"
description: "这是一个为管理接口提供 FIFO 传输层实现的模块。它通过 FIFO 文件接收命令，并通过指定的 reply_fifo 返回输出。"
---

## 管理指南


### 概述


这是一个为管理接口提供 FIFO 传输层实现的模块。
它通过 FIFO 文件接收命令，并通过指定的 reply_fifo 返回输出。


该模块每 30 秒检查一次 FIFO 文件是否存在，
如果文件被删除，它会重新创建。
如果想强制重新创建 fifo 文件，应该向 MI 进程 PID 发送 SIGHUP 信号。


### FIFO 命令语法


通过 FIFO 接口发出的外部命令必须遵循以下语法：
*request = ':'(reply_fifo)?':'jsonrpc_command*


如果缺少 *reply_fifo*，MI FIFO 模块将不会发送任何回复。
当 *jsonrpc_command* 不包含 *id* 元素时，
也会发生类似的行为，该命令被视为 JSON-RPC 通知。


### 返回值


成功时，将在 fifo 文件上回复一个有效的 [JSON-RPC](http://www.jsonrpc.org/specification) 响应，
包含成功的 JSON-RPC 响应。


当 MI 命令失败时，将通过回复 fifo 文件发送 JSON-RPC 错误回复。


如果是由 MI 引擎生成的错误（主要是内部错误），
则会将错误原因以纯文本形式通过回复 FIFO 发送回来。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *无其他 OpenSIPS 模块依赖*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *无*


### 导出的参数


#### fifo_name (string)


用于监听和读取外部命令的 FIFO 文件名称。


*注意：* 从 Linux 内核 4.19 开始，
进程无法再从保存在带有粘性位的目录（如 */tmp*）
且不由进程运行用户拥有的 FIFO 文件中读取。
这会阻止外部工具（如 *opensips-cli*）
使用不同用户的身份运行 MI 命令（会触发 *权限被拒绝* 错误）。
如果在尝试使用 *opensips-cli* 时遇到此错误，
可以通过将 fifo 文件存储在不带粘性位的目录中（如 */run/opensips*）来修复，
或者使用 *sysctl fs.protected_fifos = 0* 禁用 fifo 保护（不推荐）。


*默认值为 "/tmp/opensips_fifo"。*


```c title="设置 fifo_name 参数"
...
modparam("mi_fifo", "fifo_name", "/tmp/opensips_b2b_fifo")
...
```


#### fifo_mode (integer)


用于创建监听 FIFO 文件的权限。它遵循 UNIX 约定。


*默认值为 0660 (rw-rw----)。*


```c title="设置 fifo_mode 参数"
...
modparam("mi_fifo", "fifo_mode", 0600)
...
```


#### fifo_group (integer) fifo_group (string)


用于创建监听 FIFO 文件的组。


*默认值为继承的值。*


```c title="设置 fifo_group 参数"
...
modparam("mi_fifo", "fifo_group", 0)
modparam("mi_fifo", "fifo_group", "root")
...
```


#### fifo_user (integer) fifo_group (string)


用于创建监听 FIFO 文件的用户。


*默认值为继承的值。*


```c title="设置 fifo_user 参数"
...
modparam("mi_fifo", "fifo_user", 0)
modparam("mi_fifo", "fifo_user", "root")
...
```


#### reply_dir (string)


用于创建回复 FIFO 文件的目录。


*默认值为 "/tmp/"*


```c title="设置 reply_dir 参数"
...
modparam("mi_fifo", "reply_dir", "/home/opensips/tmp/")
...
```


#### pretty_printing (int)


指示通过 MI 发送的 JSONRPC 响应是否应该进行格式化输出。


*默认值为 "0 - 不进行格式化输出"。*


```c title="设置 pretty_printing 参数"
...
modparam("mi_fifo", "pretty_printing", 1)
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

modparam("mi_fifo", "trace_destination", "hep_dest")
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
modparam("mi_fifo", "trace_bwlist", "b: ps, which")
...
## 仅允许 sip_trace mi 命令
## 所有其他命令都不会被跟踪
modparam("mi_fifo", "trace_bwlist", "w: sip_trace")
...
```


### 导出的函数


配置文件中没有导出可供使用的函数。


### 示例


这是一个展示 "get_statistics dialog: tm:" MI 命令的 FIFO 格式的示例：
响应。


```c title="FIFO 请求"
:reply_fifo:{"jsonrpc":"2.0","method":"get_statistics","id":"5672","params":[["dialog:","tm:"]]}
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议。
