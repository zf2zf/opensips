---
title: "OpenTelemetry 模块"
description: "*opentelemetry* 模块为 OpenSIPS 路由执行提供 OpenTelemetry 追踪。它为每个处理的 SIP 消息创建一个根跨度,为每个路由条目创建一个子跨度。"
---

## 管理指南


### 概述


*opentelemetry* 模块为 OpenSIPS 路由执行提供 OpenTelemetry
追踪。它为每个处理的 SIP 消息创建一个根跨度,
为每个路由条目创建一个子跨度。


根 SIP 消息跨度遵循本地语义约定,灵感来自 OpenTelemetry HTTP 跨度约定:
它使用基于 OpenSIPS 路由类型的 method-plus-target 跨度名称、
server/client/internal 跨度种类,
以及通用网络、客户端、服务器和 URL 属性,
只要它们适合 SIP 模型。


跨度包含常见 SIP 属性(请求方法、Call-ID、CSeq、
响应状态)和连接元数据。当跨度处于活动状态时,
OpenSIPS 日志可以作为 OpenTelemetry 事件附加,以便更轻松地进行关联。


追踪数据通过 OpenTelemetry C++ SDK 的 OTLP/HTTP 导出器导出。


此模块发出的本地 SIP 跨度约定记录在
`modules/opentelemetry/semantic-convention/sip-spans.md` 中。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载:


- *无*。


#### 外部库或应用程序


运行 OpenSIPS 加载此模块之前必须安装以下库或应用程序:


- *OpenTelemetry C++ SDK* (opentelemetry-cpp),
启用了 OTLP/HTTP 导出器。


### 导出的参数


#### enable (integer)


在启动时启用或禁用 OpenTelemetry 追踪。
也可以使用 `opentelemetry:enable`
MI 命令在运行时更改。


仅当 OpenTelemetry C++ SDK 在构建时可用时,
才会构建此模块。


*默认值为 "0(禁用)"。*


```c title="设置 enable 参数"
...
modparam("opentelemetry", "enable", 1)
...
```


#### proc_profiling (integer)


如果启用,模块还将对 OpenSIPS 进程进行分析/追踪,
而不仅仅是脚本。


*默认值为 "0(禁用)"。*


```c title="设置 proc_profiling 参数"
...
modparam("opentelemetry", "proc_profiling", 1)
...
```


#### log_level (integer)


OpenTelemetry 日志消费者在将日志事件附加到活动跨度时使用的日志级别阈值。


*默认值为 "L_DBG"。*


```c title="设置 log_level 参数"
...
modparam("opentelemetry", "log_level", 3)
...
```


#### use_batch (integer)


选择 OpenTelemetry 跨度处理器。如果启用,
模块使用批量跨度处理器;否则使用简单跨度处理器。


*默认值为 "1(启用)"。*


```c title="设置 use_batch 参数"
...
modparam("opentelemetry", "use_batch", 0)
...
```


#### service_name (string)


设置 OpenTelemetry "service.name" 资源属性。


*默认值为 "opensips"。*


```c title="设置 service_name 参数"
...
modparam("opentelemetry", "service_name", "edge-proxy")
...
```


#### exporter_endpoint (string)


覆盖 OTLP/HTTP 导出器端点。如果为空,则使用 OpenTelemetry SDK 默认值。


*默认值为 "空"。*


```c title="设置 exporter_endpoint 参数"
...
modparam("opentelemetry", "exporter_endpoint", "http://127.0.0.1:4318/v1/traces")
...
```


### 导出的 MI 函数


#### opentelemetry:enable


替代已废弃的 MI 命令: *otel_enable*。


在运行时启用或禁用 OpenTelemetry 追踪。


名称: *opentelemetry:enable*


参数:


- *opentelemetry:enable* - 设置为 "1" 以启用
追踪,或 "0" 以禁用。


MI FIFO 命令格式:


```c
		## 启用追踪
		opensips-cli -x mi opentelemetry:enable enable=1
		## 禁用追踪
		opensips-cli -x mi opentelemetry:enable enable=0
		
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)均采用知识共享许可证 4.0 版授权
