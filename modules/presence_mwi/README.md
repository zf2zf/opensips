---
title: "Presence_MWI 模块"
description: "该模块对 notify-subscribe message-summary（消息等待指示）事件进行特定处理，如 RFC 3842 中所规定。它与通用事件处理模块 presence 一起使用。它向其中构造并添加 message-summary 事件。"
---

## 管理指南


### 概述


该模块对 notify-subscribe
message-summary（消息等待指示）事件进行特定处理，
如 RFC 3842 中所规定。
它与通用事件处理模块
presence 一起使用。它向其中构造并添加 message-summary 事件。


该模块目前未实现任何授权规则。它假设 publish 请求仅由
语音邮件应用程序发布，而 subscribe 请求仅由
语音邮件箱的所有者发布。因此，可以在 OpenSIPS 配置文件中
在调用 handle_publish() 和 handle_subscribe()
函数之前轻松完成授权。


该模块对内容类型 application/simple-message-summary
实现简单的检查：内容必须以 Messages-Waiting 状态行开头，
后跟零行或多行由制表符和可打印 ASCII 字符组成的行。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *presence*。


#### 外部库或应用程序


无。


### 导出的参数


无。


### 导出的函数


配置文件中无需使用的函数。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可证 4.0
