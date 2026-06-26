---
title: "事件接口"
description: "事件接口是 OpenSIPS 提供的一种接口，用于通知外部应用程序关于在 OpenSIPS 内部触发的某些事件。"
---

**事件接口**是 OpenSIPS 提供的一种接口，用于通知外部应用程序关于在 OpenSIPS 内部触发的某些事件。

## 概述

为了将 OpenSIPS 内部事件通知给外部应用程序，**事件接口**提供以下功能：
* 管理导出的事件
* 管理来自不同应用程序的订阅
* 导出通用函数以触发事件（无论使用何种传输协议）
* 与不同传输协议通信以发送事件

有关 **OpenSIPS 事件接口**的更多详细信息，请参阅[事件接口教程](https://docs.opensips.org/tutorials-eventinterface)。

---

## 事件

OpenSIPS 可以导出多种类型的事件：
* **核心事件** - 触发 OpenSIPS 核心/全局行为变化的内部事件。导出的核心事件完整列表可在此处找到[here](Interface-CoreEvents.md)。
* **模块事件** - 每个模块在加载时触发的事件。每个模块可以导出零个、一个或多个事件。详细信息可在每个模块的[文档页面](Modules.md)中找到。
* **自定义事件** - 使用脚本中的 [raise_event()](Script-CoreFunctions.md#raise_event) 命令触发。

---

## 传输协议

外部应用程序可以通过各种传输协议接收关于触发事件的通知。虽然接口本身由 OpenSIPS 核心提供，但以下每种传输协议都由一个单独的 OpenSIPS 模块实现。可以同时加载多个传输模块，以提供不同的通知方式。

可用的传输协议有：

* [event_datagram](../../modules/event_datagram/README.md) - 通过 UDP 或 UNIX 套接字发送数据报
* [event_flatstore](../../modules/event_flatstore/README.md) - 写入纯文本文件
* [event_kafka](../../modules/event_kafka/README.md) - 通过 Apache Kafka broker 发送事件
* [event_rabbitmq](../../modules/event_rabbitmq/README.md) - 向 RabbitMQ 服务器发送 AMQP 消息
* [event_stream](../../modules/event_stream/README.md) - 通过 TCP 发送 JSON-RPC 命令/通知
* [event_virtual](../../modules/event_virtual/README.md) - 聚合事件后端以实现故障转移和负载均衡
* [event_xmlrpc](../../modules/event_xmlrpc/README.md) - 通过 TCP 发送 XML-RPC 命令

外部应用程序可以订阅任何导出的事件，并可以使用任何已加载的传输模块/协议接收通知。此外，核心事件接口可以运行与触发事件同名的 `event_route`，例如 `event_route[E_PIKE_BLOCKED]`，而无需加载专用传输模块。

---

## 事件订阅

您可以在启动时订阅事件（使用脚本中的 [subscribe_event()](Script-CoreFunctions.md#subscribe_event) 命令），也可以在运行时使用 [evi:subscribe](Interface-CoreMI.md#evi_subscribe) MI 命令进行订阅。

---

## 示例

为了配置 RabbitMQ 服务器在触发自定义事件时收到通知，首先您必须使用 [subscribe_event()](Script-CoreFunctions.md#subscribe_event) 命令将其订阅到事件：

```c

    startup_route {
        subscribe_event("E_SCRIPT_CUSTOM_EVENT", "rabbitmq:127.0.0.1/opensips");
    }

```

然后，为了从脚本触发事件，在需要时调用 [raise_event()](Script-CoreFunctions.md#raise_event) 命令：

```text

   ....
   raise_event("E_SCRIPT_CUSTOM_EVENT");     # raises an event without any parameters
   ...

```
