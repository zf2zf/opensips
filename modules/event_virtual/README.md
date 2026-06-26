---
title: "event_virtual 模块"
description: "*event_virtual* 模块提供了将多个使用不同传输协议的外部应用程序作为单个虚拟订阅者订阅到 OpenSIPS Event Interface 的功能，用于特定事件。当事件被触发时，event_virtual 模块通知指定的传输模块，使用以下策略之一："
---

## 管理指南


### 概述


*event_virtual* 模块提供了将多个使用不同传输协议的外部应用程序作为单个虚拟订阅者订阅到 OpenSIPS Event Interface 的功能，用于特定事件。当事件被触发时，event_virtual 模块使用以下策略之一通知指定的传输模块：


- *PARALLEL* - 所有订阅者（应用程序）同时收到通知
- *FAILOVER* - 对于引发的每个事件，按给定顺序尝试通知订阅者，直到第一次成功通知。失败的订阅者在[故障转移超时](#param_failover_timeout)过去之前会被跳过，不会收到进一步通知。
- *ROUND-ROBIN* - 对于引发的每个事件，按给定顺序交替通知订阅者（对于每个引发的事件，通知不同的订阅者）


只能使用一个过期值（针对整个虚拟订阅），不能为每个单独订阅者设置不同的过期值。


### Virtual 套接字语法


*virtual:policy subscriber_1 [[subscriber_2] ...]*


含义：


- *virtual:* - 通知 Event Interface，发送到此订阅者的事件应由 *event_virtual* 模块处理
- *policy* - 订阅者通知策略，可以是以下值之一：'PARALLEL'、'FAILOVER'、'ROUND-ROBIN'（行为如上所述）
					
					
					*!! 重要：策略必须始终指定为大写字符串！*
- *subscriber_1* - 使用此特定订阅者的套接字语法（例如 "rabbitmq:guest:guest@127.0.0.1:5672/pike"）


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：
			*实现订阅者使用的传输协议的 OpenSIPS 事件模块*。


### 外部库或应用程序


运行加载此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *无*


### 导出的参数


#### failover_timeout (integer)


失败的订阅者被跳过进一步通知的最短持续时间（秒）。此参数仅影响 *FAILOVER* 策略。


*默认值为 "30"。*


```c title="设置 failover_timeout 参数"
...
modparam("event_virtual", "failover_timeout", 5)
...
	
```


### 导出的函数


没有可从配置文件使用的导出函数。


### 示例


订阅者的套接字可以用任意数量的空格或制表符分隔：


```c title="Virtual 套接字"
	virtual:PARALLEL rabbitmq:guest:guest@127.0.0.1:5672/pike flatstore:/var/log/opensips_proxy.log
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用 Creative Common License 4.0 许可证
