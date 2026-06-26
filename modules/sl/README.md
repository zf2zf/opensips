---
title: "sl Module"
description: "SL 模块允许 OpenSIPS 作为无状态 UA 服务器生成对 SIP 请求的回复而不保持状态。这在许多场景中是有益的，在这些场景中你希望不增加服务器内存负担并能够良好扩展。"
---

## 管理指南


### 概述


SL 模块允许 OpenSIPS 作为无状态
UA 服务器生成对 SIP 请求的回复而不保持状态。这在许多场景中是有益的，在这些场景中你不希望增加服务器内存负担并能够良好扩展。


SL 模块需要过滤在生成本地无状态回复到 INVITE 后发送的 ACK。为了识别这些 ACK，OpenSIPS 在 to-tag 中添加了一个特殊的"签名"。在传入的 ACK 中寻找这个签名，如果包含，则吸收这些 ACK。


为了加快过滤过程，该模块使用超时机制。当发送回复时，设置一个计时器。只要超时未到达，传入的 ACK 请求将使用 TO tag 值进行检查。一旦计时器到期，所有 ACK 都被放行——因为已经过了很长时间才发送回复，所以不期望有需要阻止的 ACK。


ACK 过滤在某些罕见情况下可能会失败。如果你认为这些对你很重要，最好使用有状态处理（tm 模块）进行 INVITE 处理。特别地，问题发生在 UA 发送已包含 to-tag 的 INVITE（例如 re-INVITE）而 OpenSIPS 想要回复它时。然后，它将保持当前的 to-tag，这将在 ACK 中被镜像。OpenSIPS 不会看到其签名并向下游转发 ACK。造成的损害并不大——只是一个无用的 ACK 被转发。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *无其他 OpenSIPS 模块的依赖*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### enable_stats (integer)


模块是否应生成统计信息并导出到核心管理器。零值表示禁用。


SL 模块提供有关发送了多少回复（按代码类别分）和过滤了多少本地 ACK 的统计信息。


默认值为 1（启用）。


```c title="enable_stats 示例"
modparam("sl", "enable_stats", 0)
```


### 导出的函数


#### sl_send_reply(code, reason)


对于当前请求，发送一个具有给定代码和文本原因的回复。回复是无状态发送的，完全独立于事务模块，并且 INVITE 回复不会重传。'code' 和 'reason' 可以包含在运行时替换的伪变量。


参数含义如下：


- *code (int)* - 返回码。
- *reason (string)* - 原因短语。


此函数可以从 REQUEST_ROUTE、ERROR_ROUTE 使用。


```c title="sl_send_reply 使用示例"
...
sl_send_reply(404, "Not found");
...
sl_send_reply($err.rcode, $err.rreason);
...
```


#### sl_reply_error()


发送一个描述最后一个内部错误性质的错误回复。通常此函数应在返回错误代码的脚本函数之后使用。


此函数可以从 REQUEST_ROUTE 使用。


```c title="sl_reply_error 使用示例"
...
sl_reply_error();
...
```


### 导出的统计信息


#### 1xx_replies


1xx_replies 的数量。


#### 2xx_replies


2xx_replies 的数量。


#### 3xx_replies


3xx_replies 的数量。


#### 4xx_replies


4xx_replies 的数量。


#### 5xx_replies


5xx_replies 的数量。


#### 6xx_replies


6xx_replies 的数量。


#### sent_replies


sent_replies 的数量。


#### sent_err_replies


sent_err_replies 的数量。


#### received_ACKs


received_ACKs 的数量。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享署名 4.0 国际许可协议授权。
