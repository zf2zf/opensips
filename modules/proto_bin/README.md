---
title: "proto_bin 模块"
description: "**proto_bin** 模块是一个传输模块,实现了基于 TCP 的 Binary Interface 通信。它不处理 TCP 连接管理,只是提供高级原语来通过 TCP 读取和写入 BIN 消息。每收到一个完整消息时,它会调用已注册的回调函数。"
---

## 管理指南


### 概述


**proto_bin** 模块是一个传输模块,实现了基于 TCP 的 Binary Interface 通信。它不处理 TCP 连接管理,只是提供高级原语来通过 TCP 读取和写入 BIN 消息。每收到一个完整消息时,它会调用已注册的回调函数。


加载后,你可以在配置文件中定义 BIN 监听器,添加其 IP 和可选的监听端口,类似于以下示例:
```c

...
socket= bin:127.0.0.1 		# 更改监听 IP
socket= bin:127.0.0.1:5080	# 更改监听 IP 和端口
...
```


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载:


- *无*。


#### 外部库或应用程序


运行 OpenSIPS 加载此模块之前,必须安装以下库或应用程序:


- *无*。


### 导出的参数


#### bin_port (integer)


所有 TCP 监听器使用的默认端口。


*默认值为 5555。*


```c title="设置 bin_port 参数"
...
modparam("proto_bin", "bin_port", 6666)
...
```


#### bin_send_timeout (integer)


TCP 连接在此时间后将被关闭(如果在此间隔内无法进行阻塞写入,并且 OpenSIPS 想在其上发送数据)。


*默认值为 100 ms。*


```c title="设置 bin_send_timeout 参数"
...
modparam("proto_bin", "bin_send_timeout", 200)
...
```


#### bin_max_msg_chunks (integer)


BIN 消息通过 TCP 传输时预期的最大分片数。如果接收的数据包分片程度超过此值,则连接将被断开(要么连接严重过载导致高分片,要么我们正受到攻击,攻击者发送非常碎片化的流量以降低服务器性能)。


*默认值为 32。*


```c title="设置 bin_max_msg_chunks 参数"
...
modparam("proto_bin", "bin_max_msg_chunks", 8)
...
```


#### bin_async (integer)


指定 TCP 连接和写入操作是否应以异步模式(非阻塞连接和写入)进行。如果禁用,OpenSIPS 将阻塞并等待 TCP 操作如连接和写入。


*默认值为 1(启用)。*


```c title="设置 bin_async 参数"
...
modparam("proto_bin", "bin_async", 0)
...
```


#### bin_async_max_postponed_chunks (integer)


如果 *bin_async* 启用,此参数指定可暂存供以后/异步写入的最大 BIN 消息数。如果连接待写入超过此数量,连接将被标记为已损坏并被丢弃。


*默认值为 1024。*


```c title="设置 bin_async_max_postponed_chunks 参数"
...
modparam("proto_bin", "bin_async_max_postponed_chunks", 1024)
...
```


#### bin_async_local_write_timeout (integer)


如果 *bin_async* 启用,此参数指定写入操作将以阻塞模式(优化)尝试的毫秒数。如果写入操作持续超过此时间,写入将进入异步模式并传递给 bin MAIN 进行轮询。


*默认值为 10 ms。*


```c title="设置 bin_async_local_write_timeout 参数"
...
modparam("proto_bin", "tcp_async_local_write_timeout", 100)
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)采用 Creative Common License 4.0 授权
