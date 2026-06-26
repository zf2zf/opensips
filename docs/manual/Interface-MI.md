---
title: "管理接口"
description: "管理接口（或 MI）是 OpenSIPS 提供的一种接口，允许外部应用程序在 OpenSIPS 内部触发预定义的命令。"
---

**管理接口**（或 **MI**）是 OpenSIPS 提供的一种接口，允许外部应用程序在 OpenSIPS 内部触发预定义的命令。

## 概述

此类命令通常允许外部应用程序：
* 将数据推入 OpenSIPS（如设置调试级别、注册联系人等）
* 从 OpenSIPS 获取数据（查看注册用户、查看正在进行的通话、获取统计信息等）
* 在 OpenSIPS 中触发内部操作（重新加载数据、发送消息等）

**MI** 命令由 OpenSIPS 核心提供（请参阅[完整列表](Interface-CoreMI.md)），也由模块提供（请查看[每个模块](Modules.md)提供的命令）。

---

## 协议

可用于连接（从外部应用程序）到 OpenSIPS **MI** 的协议有：JSON-RPC（通过多种传输方式）和 XML-RPC。虽然接口本身（围绕 JSON 格式定制）由 OpenSIPS 核心提供，但每种实际传输协议由单独的 OpenSIPS 模块提供。您可以同时加载多个 MI 模块，以使用多种 MI 传输协议。

大多数 MI 后端模块只提供传输，而命令解析和响应格式（作为 **JSON-RPC**）由 OpenSIPS 核心完成。唯一的例外是 *mi_html* 和 *mi_xmlrpc* 模块，它们使用不同的格式。

可用的 MI 模块有：

### [mi_fifo](../../modules/mi_fifo/README.md)
通过 FIFO 文件提供 JSON-RPC 传输；OpenSIPS 从预定义的 FIFO 文件读取，外部应用程序在该文件中写入 MI 命令。由于文件实际上是数据流，因此对于 OpenSIPS 可能返回的数据量没有限制（当从 OpenSIPS 获取数据时）。

### [mi_datagram](../../modules/mi_datagram/README.md)
通过 UNIX 套接字或 UDP 数据包提供 JSON-RPC 传输；OpenSIPS 在 UDP 端口或 unisock 文件上监听 MI 命令。传输的数据受数据报大小限制（65K）。

### [mi_http](../../modules/mi_http/README.md)
通过 HTTP 提供 JSON-RPC 传输。由于使用 TCP，因此传输数据量没有限制。

### [mi_html](../../modules/mi_html/README.md)
提供直接从 Web 浏览器通过 HTML 页面发出 MI 命令的方式。命令的参数在 URL 的查询字符串中传递。虽然不符合 JSON-RPC，但 MI 响应仍以 JSON 格式在页面中传递。

### [mi_xmlrpc](../../modules/mi_xmlrpc/README.md)
通过不仅提供 HTTP 传输，还通过在 MI 的内部 JSON 格式和 XML 之间进行转换来实现 XML-RPC。

### [mi_script](../../modules/mi_script/README.md)
提供直接从 OpenSIPS 脚本运行 MI 命令的能力，将结果作为 JSON 字符串返回。

所有协议都允许多个应用程序（客户端）同时连接到 MI 接口。

---

## 示例

一些用于 OpenSIPS 的 JSON-RPC 调用示例：

```bash

# Request with no parameters:
{
  "jsonrpc": "2.0",
  "method": "ps",
  "id": 10
}

# Response:
{
  "jsonrpc":  "2.0",
  "result": {
    "Processes":  [{
        "ID": 0,
        "PID":  9467,
        "Type": "attendant"
      }, {
        "ID": 1,
        "PID":  9468,
        "Type": "HTTPD 127.0.0.1:8008"
      }, {
        "ID": 3,
        "PID":  9470,
        "Type": "time_keeper"
      }, {
        "ID": 4,
        "PID":  9471,
        "Type": "timer"
      }, {
        "ID": 5,
        "PID":  9472,
        "Type": "SIP receiver udp:127.0.0.1:5060 "
      }, {
        "ID": 7,
        "PID":  9483,
        "Type": "Timer handler"
      }, ]
  },
  "id": 10
}

# Request with positional parameters:
{
  "jsonrpc": "2.0",
  "method": "log_level",
  "params": [4, 9472],
  "id": 11
}

# Request with named parameters:
{
  "jsonrpc": "2.0",
  "method": "log_level",
  "params": {
    "level": 4,
    "pid": 9472
  },
  "id": 11
}

# Request with an array type of parameter:
{
  "jsonrpc": "2.0",
  "method": "get_statistics",
  "params": {
    "statistics": ["shmem:", "core:"]
  },
  "id": 11
}

```

通过 MI 接口与 OpenSIPS 交互的一个简单示例是 **opensips-cli** 工具——它使用 FIFO 将 MI 命令推入 OpenSIPS：

```bash

    opensips-cli -x mi ps
    opensips-cli -x mi log_level 4 9472

```

使用 *curl* 从命令行发送 JSON-RPC OpenSIPS MI 命令的示例：
```bash

$ curl -X POST localhost:8888/mi -H 'Content-Type: application/json' -d '{"jsonrpc": "2.0", "id": "1", "method": "ps"}'

```
