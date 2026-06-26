---
title: "STUN 模块"
---

## 管理指南

### 概述

#### 原理

一个 STUN 服务器与 SIP（5060）使用相同端口工作，以获取准确信息。这样做的好处是，当 NAT 根据不同目标端口进行不同转换时，能够获得准确的外网地址。服务器还可以广告与实际监听地址不同的网络地址。

#### 基本操作

STUN 服务器将使用 4 个套接字：

- socket1 = ip1 : port1
- socket2 = ip1 : port2
- socket3 = ip2 : port1
- socket4 = ip2 : port2

其中 *ip1* / *port1* 代表一个 UDP SIP 监听器，*ip2* / *port2* 通过[备用 IP](#param_alternate_ip)和[备用端口](#param_alternate_port)参数配置。

这些套接字来自现有 SIP 套接字或被创建。

Socket1 必须始终是 OpenSIPS 中的一个 SIP UDP 监听器。

如果启用了[将监听器用作主套接字](#param_use_listeners_as_primary)，STUN 服务器将实际使用多组从上述 IP/端口组合获得的套接字，每组对应 OpenSIPS 中的一个 SIP UDP 监听器。

服务器将创建一个单独的进程。此进程将监听创建套接字上的数据。服务器将向 SIP 注册一个回调函数。当找到特定（STUN）头时，将调用此函数。

#### 支持的 STUN 属性

此 STUN 实现 RFC3489（和 RFC5389 中的 XOR_MAPPED_ADDRESS）

- MAPPED_ADDRESS
- RESPONSE_ADDRESS
- CHANGE_REQUEST
- SOURCE_ADDRESS
- CHANGED_ADDRESS
- ERROR_CODE
- UNKNOWN_ATTRIBUTES
- REFLECTED_FROM
- XOR_MAPPED_ADDRESS

不支持的属性：

- USERNAME
- PASSWORD
- MESSAGE_INTEGRITY

以及相关的 ERROR_CODE

### 依赖

#### OpenSIPS 模块

以下模块必须在此模块之前加载：

*无*。

#### 外部库或应用程序

运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：

- *无*。

### 导出的参数

#### primary_ip (str)

配置为 OpenSIPS 中 UDP SIP 监听器的接口 IP。除非启用了[将监听器用作主套接字](#param_use_listeners_as_primary)，否则这是一个必选参数。

语法："ip [/ advertised_ip]"

默认情况下，*primary_ip* 和广告的 *primary_ip* 将相同。可选的 "/ xxx.xxx.xxx.xxx" 字符串可以更改此设置。

```c title="设置 primary_ip 参数"
...
modparam("stun", "primary_ip", "192.168.0.100")

# OpenSIPS 中位于 NAT 背后的 STUN 服务器示例
modparam("stun", "primary_ip", "192.168.0.100 / 64.50.46.78")
...
				
```

#### primary_port (str)

（与 *primary_ip* 一起）配置为 OpenSIPS 中 UDP SIP 监听器的端口。默认值为 5060。

语法："port [/ advertised_port]"

默认情况下，*primary_port* 和广告的 *primary_port* 将相同。可选的 "/ adv_port" 字符串可以更改此设置。

```c title="设置 primary_port 参数"
...
modparam("stun", "primary_port", "5060")

# 监听主端口，但广告不同的端口
modparam("stun", "primary_port", "5060 / 5062")
...
				
```

#### alternate_ip (str)

来自另一个接口的另一个 IP。这是一个必选参数。

如果启用了[将监听器用作主套接字](#param_use_listeners_as_primary)，备用 IP 必须是：

- OpenSIPS 中配置的现有 UDP SIP 监听器的 IP，但与所有其他 UDP 监听器不同；
- 与 OpenSIPS 中配置的 UDP SIP 监听器不同的 IP。

语法："ip [/ advertised_ip]"

默认情况下，*alternate_ip* 和广告的 *alternate_ip* 将相同。可选的 "/ xxx.xxx.xxx.xxx" 字符串可以更改此设置。

```c title="设置 alternate_ip 参数"
...
modparam("stun","alternate_ip","11.22.33.44")

# OpenSIPS 中位于 NAT 背后的 STUN 服务器示例
modparam("stun", "alternate_ip", "192.168.0.100 / 64.78.46.50")
...
				
```

#### alternate_port (str)

STUN 服务器用于第二个接口的端口。默认值为 3478（默认 STUN 端口）。

如果启用了[将监听器用作主套接字](#param_use_listeners_as_primary)，备用端口必须是：

- OpenSIPS 中配置的现有 UDP SIP 监听器的端口，但与所有其他 UDP 监听器不同；
- 与 OpenSIPS 中配置的 UDP SIP 监听器不同的端口。

语法："port [/ advertised_port]"

默认情况下，*alternate_port* 和广告的 *alternate_port* 将相同。可选的 "/ adv_port" 字符串可以更改此设置。

```c title="设置 alternate_port 参数"
...
modparam("stun","alternate_port","3479")

# 监听备用端口，但广告不同的端口
modparam("stun", "alternate_port", "5060 / 5062")
...
				
```

#### use_listeners_as_primary (int)

将此参数设置为 *1* 将允许所有配置的 UDP SIP 监听器自动用作"主"STUN 套接字。

启用此行为时，[主 IP](#param_primary_ip)和[主端口](#param_primary_port)参数将被忽略。

默认值为 *0*（禁用）。

```c title="设置 use_listeners_as_primary 参数"
...
modparam("stun","use_listeners_as_primary",1)
...
				
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
