---
title: "核心统计"
description: "OpenSIPS 核心导出多个统计信息，这些统计被分组到各个类别中。要查看某个类别的所有统计信息，请获取 \"class:\" 统计（例如: opensips-cli -x mi get_statistics load: core: shmem:）"
---

**OpenSIPS** 核心导出多个统计信息，这些统计被分组到各个**类别**中。要查看某个类别的所有统计信息，请获取 "class:" 统计（例如: **opensips-cli -x mi get_statistics load: core: shmem:**）

---

## "CORE" 类别

### rcv_requests
返回 OpenSIPS 接收的请求总数。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics rcv_requests

```

从脚本使用的示例
```text

xlog("Total number of received requests = $stat(rcv_requests) \n");

```

### rcv_replies
返回 OpenSIPS 接收的回复总数。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics rcv_replies

```

从脚本使用的示例
```text

xlog("Total number of received replies = $stat(rcv_replies) \n");

```

### fwd_requests
返回 OpenSIPS 无状态转发的请求数量。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics fwd_requests

```

从脚本使用的示例
```text

xlog("Total number of forwarded requests = $stat(fwd_requests) \n");

```

### fwd_replies
返回 OpenSIPS 无状态转发的回复数量。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics fwd_replies

```

从脚本使用的示例
```text

xlog("Total number of forwarded replies = $stat(fwd_replies) \n");

```

### drop_requests
返回在进入脚本路由逻辑之前就被丢弃的请求数量。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics drop_requests

```

从脚本使用的示例
```text

xlog("Total number of dropped requests = $stat(drop_requests) \n");

```

### drop_replies
返回在进入脚本路由逻辑之前就被丢弃的回复数量，或在 onreply_route 中明确丢弃的回复数量。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics drop_replies

```

从脚本使用的示例
```text

xlog("Total number of dropped replies = $stat(drop_replies) \n");

```

### err_requests
返回从 SIP 角度来看的伪造请求数量（例如: 未找到 VIA header）

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics err_requests

```

从脚本使用的示例
```text

xlog("Total number of error requests = $stat(err_requests) \n");

```

### err_replies
返回从 SIP 角度来看的伪造回复数量（例如: 未找到 VIA header）

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics err_replies

```

从脚本使用的示例
```text

xlog("Total number of error replies = $stat(err_replies) \n");

```

### bad_URIs_rcvd
返回 OpenSIPS 解析失败的 URI 数量。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics bad_URIs_rcvd

```

从脚本使用的示例
```text

xlog("Total number of bad URIs detected = $stat(bad_URIs_rcvd) \n");

```

从脚本使用的示例
```text

xlog("Total number of unsupported methods detected = $stat(unsupported_methods) \n");

```

### bad_msg_hdr
返回 OpenSIPS 解析失败的 SIP header 数量。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics bad_msg_hdr

```

从脚本使用的示例
```text

xlog("Total number of headers that failed to parse = $stat(bad_msg_hdr) \n");

```

### timestamp
返回从 OpenSIPS 启动以来经过的秒数。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics timestamp

```

从脚本使用的示例
```text

xlog("OpenSIPS has been alive for $stat(timestamp) seconds \n");

```

---

## "LOAD" 类别

提供有关 OpenSIPS 内部负载的信息。负载定义为处理所花费时间与总时间的百分比。遵循 "top" 的模型，有三个负载值，在不同时间段计算:
* 实时负载 - 最近 1 秒计算
* 上分钟负载 - 最近 1 分钟计算
* 上 10 分钟负载 - 最近 10 分钟计算

所有三个负载值都以每进程方式（每个进程的负载）和全局方式（覆盖所有进程）由 OpenSIPS 提供。

### load
整个 OpenSIPS 的实时负载 - 这统计了 OpenSIPS 的所有核心进程; 模块请求的额外进程不计入此负载。另请注意，某些核心进程不计入，因为它们不产生任何负载; 这样的进程有 attendant、time keeper 和 timer trigger。
此统计实际上反映的是处理 SIP 流量产生的负载（因为只统计了核心活跃进程）。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics load
load:load:: 24

```

从脚本使用的示例
```text

xlog("The OpenSIPS processing load is $stat(load) \n");

```

### load1m
核心 OpenSIPS（仅覆盖核心/SIP 进程）的上分钟平均负载。更多信息请参见 [load](#load)。

### load10m
核心 OpenSIPS（仅覆盖核心/SIP 进程）的上 10 分钟平均负载。更多信息请参见 [load](#load)。

### load-all
整个 OpenSIPS 的实时负载，同时统计核心和模块进程。与 [[#load|load] 类似，不产生任何负载的进程不被统计。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics load-all
load:load-all:: 24

```

从脚本使用的示例
```text

xlog("The overall OpenSIPS load is $stat(load-all) \n");

```

### load1m-all
整个 OpenSIPS（覆盖所有进程）的上分钟平均负载。更多信息请参见 [load-all](#load-all)。

### load10m-all
整个 OpenSIPS（覆盖所有进程）的上 10 分钟平均负载。更多信息请参见 [load-all](#load-all)。

### load-proc-id
进程 **ID** 的实时负载。要了解 OpenSIPS 进程的 ID（及其类型），请使用 **ps** MI 命令。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics load-proc-5
load:load-proc-5:: 79

```

从脚本使用的示例
```text

xlog("The load of processes 5 is $stat(load-proc-5) \n");

```

### load1m-proc-id
进程 **ID** 的上分钟平均负载。更多信息请参见 [load-proc-id](#load-proc-id)。

### load10m-proc-id
进程 **ID** 的上 10 分钟平均负载。更多信息请参见 [load-proc-id](#load-proc-id)。

---

## "NET" 类别

提供有关 OpenSIPS 监听接口上的 UDP、TCP 和 TLS 缓冲区的信息。

### waiting_udp
返回 OpenSIPS 监听接口上等待消费的字节数。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics waiting_udp

```

从脚本使用的示例
```text

xlog("The UDP waiting buffer size is $stat(waiting_udp) \n");

```

### waiting_tcp
返回 OpenSIPS 监听接口上等待消费的字节数。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics waiting_tcp

```

从脚本使用的示例
```text

xlog("The TCP waiting buffer size is $stat(waiting_tcp) \n");

```

### waiting_tls
返回 OpenSIPS 监听接口上等待消费的字节数。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics waiting_tls

```

从脚本使用的示例
```text

xlog("The TLS waiting buffer size is $stat(waiting_tls) \n");

```

---

## "SHMEM" 类别

提供有关 OpenSIPS 使用的共享内存的信息。

### total_size
返回可供 OpenSIPS 进程使用的共享内存总量。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics total_size

```

从脚本使用的示例
```text

xlog("Total size of SHMEM available is $stat(total_size) \n");

```

### used_size
返回 OpenSIPS 进程请求和使用的共享内存量。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics used_size

```

从脚本使用的示例
```text

xlog("SHMEM in use = $stat(used_size) \n");

```

### real_used_size
返回 OpenSIPS 进程请求的共享内存量 + malloc 开销

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics real_used_size

```

从脚本使用的示例
```text

xlog("Real SHMEM used size is $stat(real_used_size) \n");

```

### max_used_size
返回 OpenSIPS 进程曾经使用的最大共享内存量。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics max_used_size

```

从脚本使用的示例
```text

xlog("The max SHMEM ever used is $stat(max_used_size) \n");

```

### free_size
返回可用空闲内存。计算公式为 total_size - real_used_size

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics free_size

```

从脚本使用的示例
```text

xlog("Free SHMEM available is $stat(free_size) \n");

```

### fragments
返回共享内存中的碎片总数。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics fragments

```

从脚本使用的示例
```text

xlog("The total number of SHMEM fragments is $stat(fragments) \n");

```

---

## "PKMEM" 类别

每个 OpenSIPS 进程的各种私有内存相关统计。每个 "PKMEM" 统计以数字为前缀，代表 OpenSIPS 进程的索引（0, 1, ...）。

### N-total_size
返回可供 OpenSIPS 进程 #N 使用的私有内存总量。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics 0-total_size

```

从脚本使用的示例
```text

xlog("Total size of PKG memory available for process #0 is $stat(0-total_size) \n");

```

### N-used_size
返回 OpenSIPS 进程 #N 请求和使用的私有内存量。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics 0-used_size

```

从脚本使用的示例
```text

xlog("PKG mem in use for process #1 = $stat(1-used_size) \n");

```

### N-real_used_size
返回 OpenSIPS 进程 #N 请求的私有内存量，包括分配器特定元数据

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics 0-real_used_size

```

从脚本使用的示例
```text

xlog("Process #0 actually uses $stat(0-real_used_size) bytes of private memory\n");

```

### N-max_used_size
返回 OpenSIPS 进程 #N 曾经使用的最大私有内存量。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics 0-max_used_size

```

从脚本使用的示例
```text

xlog("The max PKG memory ever used for process #0 is $stat(0-max_used_size) \n");

```

### N-free_size
返回 OpenSIPS 进程 #N 可用的空闲私有内存。计算公式为 total_size - real_used_size

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics 0-free_size

```

从脚本使用的示例
```text

xlog("Free PKG memory available for process #0 is $stat(0-free_size) \n");

```

### N-fragments
返回 OpenSIPS 进程 #N 私有内存中当前可用的空闲碎片数量。

通过 MI FIFO 使用的示例
```bash

opensips-cli -x mi get_statistics 0-fragments

```

从脚本使用的示例
```text

xlog("The total number of PKG fragments is $stat(0-fragments) \n");

```
