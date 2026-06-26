---
title: "presence_reginfo 模块"
description: "该模块支持在 presence 模块中处理 \"Event: reg\"（如 RFC 3680 中所定义）。这可用于将注册信息状态分发给订阅的 watcher。"
---

## 管理指南


### 概述


该模块支持在 presence 模块中处理 "Event: reg"（如
	      RFC 3680 中所定义）。这可用于将注册信息状态分发给订阅的 watcher。


该模块目前不实现任何授权规则。它假设发布请求仅由授权应用发送，
	      订阅请求仅由授权用户发送。因此，授权可以很容易地在
	      OpenSIPS 配置文件中完成，然后再调用 handle_publish()
	      和 handle_subscribe() 函数。


注意：此模块仅在 presence 模块中激活 "reg" 的处理。
	      要向 watcher 发送 dialog-info，您还需要一个向 presence 模块发布 reg info 的来源。
	      例如，您可以使用 pua_reginfo 模块或任何外部组件。
	      这种方法允许将 presence 服务器和 reg-info 感知的发布者（例如主代理）放在不同的
	      OpenSIPS 实例上。


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *presence*。


#### 外部库或应用程序


无。


### 导出的参数


#### default_expires (int)


当 SUBSCRIBE 消息中缺少时使用的默认 expires 值（以秒为单位）。


*默认值为 "3600"。*


```c title="设置 default_expires 参数"
        ...
        modparam("presence_reginfo", "default_expires", 3600)
        ...
        
```


#### aggregate_presentities (int)


是否在单个通知正文中聚合所有注册 presentities。
						 Useful to have all registrations on first NOTIFY
						following initial SUBSCRIBE.


*默认值为 "0"（禁用）。*


```c title="设置 aggregate_presentities 参数"
				...
				modparam("presence_reginfo", "aggregate_presentities", 1)
				...
				
```


### 导出的函数


配置文件中无函数可用。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
