---
title: "event_datagram 模块"
description: "这是为 Event Interface 提供 UNIX/UDP SOCKET 传输层实现的模块。"
---

## 管理指南


### 概述


这是为 Event Interface 提供 UNIX/UDP SOCKET 传输层实现的模块。


### DATAGRAM 事件语法


事件负载格式为 JSON-RPC 通知，事件名称作为 *method* 字段，事件参数作为 *params* 字段。


### DATAGRAM 套接字语法


此模块使用两种类型的套接字，基于套接字类型。UNIX 套接字应遵循此语法：
		*['unix:'] unix_socket_path*


UDP 套接字应遵循此语法：
		*'udp:' address ':' port*


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他 OpenSIPS 模块*。


#### 外部库或应用程序


运行加载此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *无*


### 导出的参数


此模块不导出任何参数。


### 导出的函数


没有可从配置文件使用的函数。


### 示例


这是 pike 模块在决定应阻止 IP 时引发的事件示例：


```c title="E_PIKE_BLOCKED 事件"
{
  "jsonrpc": "2.0",
  "method": "E_PIKE_BLOCKED",
  "params": {
    "ip": "192.168.2.11"
  }
}
```


```c title="UNIX 套接字"
unix:/tmp/opensips_event.sock
```


```c title="UDP 套接字"
udp:127.0.0.1:8081
```


## 常见问题


**Q: UNIX 和 UDP 类型的套接字都可以用于通知事件吗？**


是的，两者都可以使用。


**Q: datagram 事件的最大长度是多少？**


datagram 事件的最大长度为 65457 字节。


**Q: 在哪里可以找到更多关于 OpenSIPS 的信息？**


请查看 [https://opensips.org/](https://opensips.org/)。


**Q: 在哪里可以发布关于此模块的问题？**


首先检查您的问题是否已在我们的邮件列表中得到解答：

		关于任何稳定版 OpenSIPS 版本的电子邮件应发送至
			users@lists.opensips.org，关于开发版本的电子邮件
			应发送至 devel@lists.opensips.org。

如果您希望保密邮件，请发送至
			users@lists.opensips.org。


**Q: 如何报告 bug？**


请按照以下指南操作：
			[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用 Creative Common License 4.0 许可证
