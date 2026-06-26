---
title: "event_kafka 模块"
description: "此模块实现了一个事件接口消费者，可将 OpenSIPS 事件发布到 Kafka 消息队列。"
---

## 管理指南

### 概述

event_kafka 模块实现了一个事件接口消费者，可将 OpenSIPS 事件发布到 Kafka 消息队列。

### 依赖

#### OpenSIPS 模块

无

#### 外部库或应用程序

- *librdkafka* - Kafka 客户端库

### 导出的参数

#### bootstrap brokers (string)

Kafka 代理列表。

```c title="设置 bootstrap brokers"
modparam("event_kafka", "bootstrap brokers", "kafka1:9092,kafka2:9092")
```

#### topic (string)

用于发布事件的默认 Kafka 主题。

```c title="设置默认主题"
modparam("event_kafka", "topic", "opensips-events")
```

#### group_id (string)

Kafka 消费者组 ID。

```c title="设置消费者组"
modparam("event_kafka", "group_id", "opensips-consumer-group")
```

### 导出的函数

此模块无导出函数。

### 事件格式

发布到 Kafka 的事件以 JSON 格式编码。
