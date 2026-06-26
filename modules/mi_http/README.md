---
title: "mi_http 模块"
description: "本模块为 OpenSIPS 的管理接口提供 HTTP 传输层实现。"
---

## 管理指南


### 概述


本模块为 OpenSIPS 的管理接口提供 HTTP 传输层实现。


### 依赖


#### 外部库或应用程序


无


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *httpd* 模块。


### 导出的参数


#### root (string)


指定 HTTP 请求的根路径：
http://[opensips_IP]:[opensips_httpd_port]/[root]


*默认值为 "mi"。*


```c title="设置 root 参数"
...
modparam("mi_http", "root", "opensips_mi")
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

modparam("mi_http", "trace_destination", "hep_dest")
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
modparam("mi_http", "trace_bwlist", "b: ps, which")
...
## 仅允许 sip_trace mi 命令
## 所有其他命令都不会被跟踪
modparam("mi_http", "trace_bwlist", "w: sip_trace")
...
```


### 导出的函数


配置文件中没有导出可供使用的函数。


### 已知问题


大型响应的命令（如 ul_dump）如果 httpd 缓冲区配置太小（或没有配置足够的 pkg 内存）将会失败。


httpd 模块的未来版本将解决此问题。


### 示例


这是一个通过 HTTP 展示 "ps" MI 命令的 JSON-RPC 请求和响应的示例。


```c title="JSON-RPC 请求"
POST /mi HTTP/1.1
Accept: application/json
Content-Type: application/json
Host: example.net

{"jsonrpc":"2.0","method":"ps","id":10}

HTTP/1.1 200 OK
Content-Length: 317
Content-Type: application/json
Date: Fri, 01 Nov 2013 12:00:00 GMT

{"jsonrpc":"2.0","result":{"Processes":[{"ID":0,"PID":9467,"Type":"attendant"},{"ID":1,"PID":9468,"Type":"HTTPD127.0.0.1:8008"},{"ID":3,"PID":9470,"Type":"time_keeper"},{"ID":4,"PID":9471,"Type":"timer"},{"ID":5,"PID":9472,"Type":"SIPreceiverudp:127.0.0.1:5060"},{"ID":7,"PID":9483,"Type":"Timerhandler"},]},"id":10}
```


这是一个通过 HTTP 展示带参数的 "get_statistics" MI 命令的 JSON-RPC 请求和响应的示例。


```c title="带参数的 JSON-RPC 请求"
POST /mi HTTP/1.1
Accept: application/json
Content-Type: application/json
Host: example.net

{"jsonrpc":"2.0","method":"get_statistics","params":[["dialog:","tm:"]],"id":10}

HTTP/1.1 200 OK
Content-Length: 317
Content-Type: application/json
Date: Fri, 01 Nov 2013 12:00:00 GMT

{"jsonrpc":"2.0","result":{"dialog:active_dialogs":0,"dialog:early_dialogs":0,"dialog:processed_dialogs":2,"dialog:expired_dialogs":0,"dialog:failed_dialogs":2,"dialog:create_sent":0,"dialog:update_sent":0,"dialog:delete_sent":0,"dialog:create_recv":0,"dialog:update_recv":0,"dialog:delete_recv":0,"tm:received_replies":49252,"tm:relayed_replies":49220,"tm:local_replies":370,"tm:UAS_transactions":49584,"tm:UAC_transactions":0,"tm:2xx_transactions":12004,"tm:3xx_transactions":0,"tm:4xx_transactions":37580,"tm:5xx_transactions":0,"tm:6xx_transactions":0,"tm:inuse_transactions":60},"id":10}
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议。
