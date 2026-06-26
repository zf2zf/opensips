---
title: "MSRP 中继模块"
description: "MSRP 中继模块提供 MSRP（会话发起协议请求通道）消息的中继功能，用于在 NAT 环境下中继 SIP 消息。"
---

## 管理指南

### 概述

MSRP 中继模块提供 MSRP（会话发起协议请求通道）消息的中继功能。MSRP 用于在 SIP 会话中传输多媒体内容。

### 依赖

#### OpenSIPS 模块

- *tm* -- 事务模块

#### 外部库或应用程序

无

### 导出的参数

#### msrp_sock (string)

MSRP 监听套接字。

```c title="设置 MSRP 套接字"
modparam("msrp_relay", "msrp_sock", "udp:127.0.0.1:2855")
```

### 导出的函数

#### msrp_relay()

中继 MSRP 消息。

此函数可以从 REQUEST_ROUTE 使用。

```c title="msrp_relay 用法"
if (msrp_relay()) {
    xlog("MSRP 消息已中继\n");
}
```
