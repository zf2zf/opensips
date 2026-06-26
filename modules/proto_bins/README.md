---
title: "proto_bins 模块"
description: "该模块实现了通过 TLS 的安全 Binary 通信协议,供 clusterer 模块提供的 OpenSIPS 集群引擎使用。"
---

## 管理指南


### 概述


该模块实现了通过 TLS 的安全 Binary 通信协议,供
		clusterer 模块提供的 OpenSIPS 集群引擎使用。


加载后,你可以在配置文件中定义 BINS 监听器,添加其 IP 和可选的
		监听端口,类似于以下示例:
```c

...
socket= bins:127.0.0.1 		# 更改监听 IP
socket= bins:127.0.0.1:5557	# 更改监听 IP 和端口
...
```


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载:


- *tls_openssl* 或 *tls_wolfssl*,
				取决于所需的 TLS 库
- *tls_mgm*。


#### 外部库或应用程序


运行 OpenSIPS 加载此模块之前,必须安装以下库或应用程序:


- *无*。


### 导出的参数


#### bins_port (integer)


所有 BINS 监听器使用的默认端口。


*默认值为 5556。*


```c title="设置 bins_port 参数"
...
modparam("proto_bins", "bins_port", 5557)
...
```


#### bins_handshake_timeout (integer)


设置 SSL/TLS 握手序列完成的超时时间(毫秒)。当使用 CPU 密集型密码进行连接时,可能需要增加此值,以允许密钥生成和处理的时间。


超时在接受新连接(入站)时调用,并在新会话发起(出站)时等待期间调用。


*默认值为 100。*


```c title="设置 bins_handshake_timeout 变量"
param("proto_tls", "bins_handshake_timeout", 200) # 毫秒数

			
```


#### bins_send_timeout (integer)


设置阻塞发送操作完成的超时时间(毫秒)。


发送超时适用于所有 TLS 写入操作,
		不包括握手过程(参见: bins_handshake_timeout)


*默认值为 100 ms。*


```c title="设置 bins_send_timeout 参数"
...
modparam("proto_bins", "bins_send_timeout", 200)
...
```


#### bins_max_msg_chunks (integer)


BINS 消息通过 TCP 传输时预期的最大分片数。如果接收的数据包分片程度超过此值,则连接将被断开(要么连接严重过载导致高分片,要么我们正受到攻击,攻击者发送非常碎片化的流量以降低服务器性能)。


*默认值为 32。*


```c title="设置 bins_max_msg_chunks 参数"
...
modparam("proto_bins", "bins_max_msg_chunks", 8)
...
```


#### bins_async (integer)


指定 TCP/TLS 连接和写入操作是否应以异步模式(非阻塞连接和写入)进行。如果禁用,OpenSIPS 将阻塞并等待 TCP/TLS 操作如连接和写入。


*默认值为 1(启用)。*


```c title="设置 bins_async 参数"
...
modparam("proto_bins", "bins_async", 0)
...
```


#### bins_async_max_postponed_chunks (integer)


如果 bins_async 启用,此参数指定可暂存供以后/异步写入的最大 BINS 消息数。如果连接待写入超过此数量,连接将被标记为已损坏并被丢弃。


*默认值为 32。*


```c title="设置 bins_async_max_postponed_chunks 参数"
...
modparam("proto_bins", "bins_async_max_postponed_chunks", 16)
...
```


#### trace_destination (string)


跟踪目标,定义在跟踪模块中。目前唯一的跟踪模块是 **proto_hep**。
		网络事件(如连接、接受和连接关闭事件)以及过程中可能出现的错误将被跟踪。对于创建的每个连接,将发送包含有关客户端和服务器证书、主密钥和网络层信息的事件。


**警告:**必须加载跟踪模块此参数才能工作。(例如
			**proto_hep**)。


*默认值为无(未定义)。*


```c title="设置 trace_destination 参数"
...
modparam("proto_hep", "hep_id", "[hep_dest]10.0.0.2;transport=tcp;version=3")

modparam("proto_bins", "trace_destination", "hep_dest")
...
```


#### trace_on (int)


这控制 TLS 的跟踪是开启还是关闭。你仍然需要定义
			[trace destination](#param_trace_destination) 才能工作,但此值将使用 MI 函数 [mi trace](#mi_trace) 进行控制。


```c title="设置 trace_on 参数"
...
modparam("proto_bins", "trace_on", 1)
...
```


### 导出的 MI 函数


#### bins:trace


替换已弃用的 MI 命令: *tls_trace*。


名称: *bins:trace*


参数:


- trace_mode(可选): 开启和关闭 bins 跟踪。此参数
					可以缺失,命令将显示此模块的当前跟踪状态(开启或关闭);
					可能的值:
					
					on
					off


MI FIFO 命令格式:


```c
			opensips-cli -x mi bins:trace on
			
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)采用 Creative Common License 4.0 授权
