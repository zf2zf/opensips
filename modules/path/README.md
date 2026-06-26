---
title: "path 模块"
description: "本模块设计用于在注册商和代理前面的中间 sip 代理(如负载均衡器)中使用。它提供插入 Path 头的函数,包括用于将注册的 received-URI 转发到下一跳的参数。它还提供了一种机制来评估后续请求中的此参数并根据它设置目标 URI。"
---

## 管理指南


### 概述


本模块设计用于在注册商和代理前面的中间 sip 代理(如负载均衡器)中使用。
它提供插入 Path 头的函数,包括用于将注册的 received-URI 转发到下一跳的参数。
它还提供了一种机制来评估后续请求中的此参数并根据它设置目标 URI。


#### 注册的 Path 插入


对于类似 "[UAC] -> [P1] -> [REG]" 的注册场景,
"path" 模块可用于中间代理 P1 在将消息转发给注册商 REG 之前插入 Path 头。
可以使用两个函数来实现这一点:


- *add_path(...)* 以 "Path: <sip:1.2.3.4;lr>" 的形式向消息添加 Path 头,
使用传出接口的地址。只有当端口不是默认端口 5060 时才添加端口。
如果向函数传递了用户名,它也会被包含在 Path URI 中,
如 "Path: <sip:username@1.2.3.4;lr>"。
- *add_path_received(...)* 也以与上述相同的形式添加 Path 头,
但还添加一个参数,指示消息的 received-URI,
如 "Path: <sip:1.2.3.4;received=sip:2.3.4.5:1234;lr>"。
如果代理进行 NAT 检测并希望将 NAT'ed 地址传递给注册商,这特别有用。
如果使用用户名调用函数,它也会被包含在 Path URI 中。


#### 到 NAT'ed UAC 的出站路由


如果 UAC 的 NAT'ed 地址被传递给注册商,注册商使用注册的 Path 头作为当前请求的 Route 头来路由后续请求。
如果中间代理在注册期间插入了包含 "received" 参数的 Path 头,
此参数也将显示在新请求的 Route 头中,
允许中间代理路由到此地址,而不是 Route URI 中传播的地址,
用于通过 NAT 隧道传输。
可以通过设置模块参数 "use_received" 来激活此行为。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载:


- 需要 "rr" 模块来进行基于 "received" 参数的出站路由。


#### 外部库或应用程序


运行 OpenSIPS 加载此模块之前必须安装以下库或应用程序:


- *无*。


### 导出的参数


#### use_received (int)


如果设置为 1,则评估第一个 Route URI 的 "received" 参数,
如果存在则用作 destination-URI。


*默认值为 0。*


```c title="设置 use_received 参数"
...
modparam("path", "use_received", 1)
...
```


#### enable_double_path (integer)


在某些情况下,服务器需要插入两个 Path 头字段而不是一个。
例如,当使用两个断开连接的网络或进行跨协议转发从 UDP->TCP 时。
此参数启用插入 2 个 Path。


*默认值为 1(是)。*


```c title="设置 enable_double_path 参数"
...
modparam("path", "enable_double_path", 0)
...
```


### 导出的函数


#### add_path([user])


此函数添加形式为 "Path: <sip:user@1.2.3.4;lr>" 的 Path 头。


参数含义如下:


- *user* (string, 可选) -
要插入为用户部分的用户名。


此函数可用于 REQUEST_ROUTE。


```c title="add_path(user) 用法"
...
if (!add_path("loadbalancer")) {
	sl_send_reply(503, "Internal Path Error");
	...
};
...
```


#### add_path_received([user])


此函数添加形式为 "Path: <sip:user@1.2.3.4;received=sip:2.3.4.5:1234;lr>" 的 Path 头,
将 'user' 设置为地址的用户名部分,
自己的传出地址作为域名部分,
以及请求被接收到的地址作为 received 参数。


参数含义如下:


- *user* (string, 可选) -
要插入为用户部分的用户名。


此函数可用于 REQUEST_ROUTE。


```c title="add_path_received(user) 用法"
...
if (!add_path_received("inbound")) {
	sl_send_reply(503, "Internal Path Error");
	...
};
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)均采用知识共享许可证 4.0 版授权
