---
title: "presence_dialoginfo 模块"
description: "该模块在 presence 模块内启用对 "Event: dialog"（RFC 4235 中定义）的处理。这可用于将 dialog-info 状态分发给订阅的 watchers。"
---

## 管理指南


### 概述


该模块在 presence 模块内启用对 "Event: dialog"（RFC 4235 中定义）的处理。这可用于
将 dialog-info 状态分发给订阅的 watchers。


该模块目前未实现任何授权规则。它假设 publish 请求仅由
授权应用程序发布，而 subscribe 请求仅由
授权用户发布。因此，可以在 OpenSIPS 配置文件中
在调用 handle_publish() 和 handle_subscribe() 函数之前
轻松完成授权。


注意：此模块仅在 presence 模块中激活 "dialog" 的处理。要向 watchers 发送 dialog-info，
您还需要一个向 presence 模块 PUBLISH dialog info 的源。例如，您可以使用 pua_dialoginfo
模块或任何外部组件。这种方法允许将 presence 服务器和 dialog-info 感知的发布者
（例如主代理）放在不同的 OpenSIPS 实例上。


该模块默认执行 body 聚合。这意味着，如果 presence 模块从多个 presentities
收到了 PUBLISH（例如，如果实体有多个 dialog，pua_dialoginfo 将发送多个 PUBLISH），
模块将解析所有收到的 XML 文档（根据 PUBLISH 请求中的 Expires header，仍有效的）
并生成包含多个 "dialog" 元素的单个 XML 文档。这是完全有效的，但不幸的是
并非所有 SIP 电话都支持此功能，例如 Linksys SPA962 在收到包含多个 dialog 元素的
dialog-info 时会崩溃。在这种情况下，请使用 force_single_dialog 模块参数。


为了更好地理解所有模块如何协同工作，请查看下图：


```c
    主代理和 Presence 服务器在同一实例上

   呼叫方        代理 &      被叫方         watcher
alice@example   presence   bob@example   watcher@example
                 server
     |             |            |               |
     |             |<-------SUBSCRIBE bob-------|
     |             |--------200 OK------------->|
     |             |--------NOTIFY------------->|
     |             |<-------200 OK--------------|
     |             |            |               |
     |--INV bob--->|            |               |
     |             |--INV bob-->|               |
     |             |<-100-------|               |
     |             |            |               |
     |             |<-180 ring--|               |
     |<--180 ring--|            |               |
     |             |--          |               |
     |             |   \        |               |
     |             | PUBLISH bob|               |
     |             |   /        |               |
     |             |<-          |               |
     |             |            |               |
     |             |--          |               |
     |             |   \        |               |
     |             | 200 ok     |               |
     |             |   /        |               |
     |             |<-          |               |
     |             |--------NOTIFY------------->|
     |             |<-------200 OK--------------|
     |             |            |               |
```


- Watcher 订阅 Bob 的 "Event: dialog"。
- Alice 呼叫 Bob。
- Bob 回复 ringing，dialog 模块中的 dialog 转换为 "early" 状态。
  执行 pua_dialoginfo 中的回调。pua_dialoginfo 模块创建 XML 文档并使用
  pua 模块发送 PUBLISH。（pua 模块本身使用 tm 模块以状态方式发送 PUBLISH）
- PUBLISH 被接收并由 presence 模块处理。Presence 模块更新 "presentity"。
  Presence 模块检查 presentity 的活跃 watchers。它将所有 XML 文档交给
  presence_dialoginfo 模块进行聚合，生成单个 XML 文档。然后向所有活跃
  watchers 发送包含聚合 XML 文档的 NOTIFY。


presence 服务器也可以通过使用单独的 OpenSIPS 实例与主代理分离，如下图所示。
（设置 pua 模块的 outbound_proxy 参数，或确保将主代理的 "循环" PUBLISH 请求
路由到 presence 服务器）。


```c
    主代理和 Presence 服务器使用单独实例

   呼叫方        代理 &   presence      被叫方         watcher
alice@example    server     server     bob@example   watcher@example
     |             |            |               |            |
     |             |<--------------------SUBSCRIBE bob-------|
     |             |-SUBSC bob->|               |            |
     |             |<-200 ok----|               |            |
     |             |---------------------200 OK------------->|
     |             |          .... NOTIFY ... 200 OK ...     |
     |             |            |               |            |
     |             |            |               |            |
     |--INV bob--->|            |               |            |
     |             |--INV bob------------------>|            |
     |             |<-100-----------------------|            |
     |             |            |               |            |
     |             |<-180 ring------------------|            |
     |<--180 ring--|            |               |            |
     |             |--PUBL bob->|               |            |
     |             |<-200 ok----|               |            |
     |             |            |--------NOTIFY------------->|
     |             |            |<-------200 OK--------------|
     |             |            |               |            |
```


已知问题：


- "version" 属性在每次 NOTIFY 时都会递增，即使
  XML 文档没有更改。这当然是有效的，但不太智能。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *presence*。


#### 外部库或应用程序


无。


### 导出的参数


#### force_single_dialog (int)


默认情况下，模块将所有可用的 dialog info 聚合到
包含多个 "dialog" 元素的单个 dialog-info 文档中。如果您的电话不支持此功能，
可以激活此参数。


如果设置此参数，则只有具有最有趣 dialog 状态的 dialog 元素
才会被放入 dialog-info 文档中。因此，dialog-info 元素将只包含
一个 "dialog" 元素。算法基于以下优先级顺序选择状态（从最不重要开始）：
terminated、trying、proceeding、confirmed、early。注意：我认为 "early" 状态
比 confirmed 更有趣，因为通常您可能希望在原始被叫方已经在通话中时接听电话。


*默认值为 "0"。*


```c title="设置参数"
...
modparam("presence_dialoginfo", "force_single_dialog", 1)
...
```


### 导出的函数


配置文件中无需使用的函数。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可证 4.0
