---
title: "统计接口"
description: "统计接口是 OpenSIPS 提供访问各种内部统计信息的接口。统计信息提供有关 OpenSIPS 内部情况的有用信息——可被外部应用使用，用于监控目的、负载评估、与其它服务的实时集成。统计变量的值仅为数值。"
---

**统计接口**是 OpenSIPS 提供访问各种内部统计信息的接口。统计信息提供有关 OpenSIPS 内部情况的有用信息——可被外部应用使用，用于监控目的、负载评估、与其它服务的实时集成。统计变量的值仅为数值。

---

## 概述

**OpenSIPS** 通常提供两种类型的统计变量:
* 计数器类型 - 持续累计 OpenSIPS 中发生的事情的变量，如接收到的请求、处理的 dialog、失败的 DB 查询等
* 计算值 - 实时计算的变量，如已使用内存量、当前负载、活跃 dialog、活跃事务等

统计变量不是重启持久的，它们都以 0 值开始（计数器类型变量）。计数器类型统计也可以在 OpenSIPS 运行时重置（为零）。

在 OpenSIPS 中，统计变量按不同集合分组，根据其用途或提供方式。例如，OpenSIPS 核心提供 **shmem**、**load**、**net** 等组，而每个 OpenSIPS 模块提供自己的组（通常组名与模块名相同）。

所有可用的统计变量都有列出和文档说明: 由 [OpenSIPS 核心](Interface-CoreStatistics.md)或 [OpenSIPS 模块](Modules.md)提供的统计（请参阅每个模块的统计章节）。

---

## 使用

要获取统计信息的访问权，您必须使用 [MI 接口](Interface-MI.md)，它提供（直接从 OpenSIPS 核心）多个 MI 函数用于:

\
**获取**统计变量、整个变量组或所有变量的值。可在此使用 MI [get_statistics](Interface-CoreMI.md) 命令:
```bash

   # 获取一个统计变量，按名称
   > opensipsctl fifo get_statistics rcv_requests
   > core:rcv_requests = 3428
   > opensipsctl fifo get_statistics real_used_size 
   > shmem:real_used_size = 2951864

   # 按名称列表获取多个统计变量
   > opensipsctl fifo get_statistics rcv_requests inuse_transactions
   > core:rcv_requests = 453
   > tm:inuse_transactions = 10

   # 从一个组获取所有统计
   > opensipsctl fifo get_statistics shmem:
   > shmem:total_size = 33554432
   > shmem:used_size = 2897024
   > shmem:real_used_size = 2951864
   > shmem:max_used_size = 2952304
   > shmem:free_size = 30602568
   > shmem:fragments = 26

   # 从 OpenSIPS 获取所有统计
   > opensipsctl fifo get_statistics all
   >...........

```

  

**重置**统计变量的值（为零），但仅适用于计数器类型变量。

> [!IMPORTANT]
> 重置计算值统计将被忽略且无效。

 可在此使用 MI [reset_statistics](Interface-CoreMI.md) 命令:

```bash

   # 重置一个统计变量，按名称
   > opensipsctl fifo reset_statistics rcv_requests

```
