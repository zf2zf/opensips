---
title: "xmpp 模块"
description: "该模块是 OpenSIPS 与 jabber 服务器之间的网关。它支持 SIP 客户端和 XMPP(jabber) 客户端之间即时消息的交换。"
---

## 管理指南


### 概述


该模块是 OpenSIPS 与 jabber 服务器之间的网关。
	它支持 SIP 客户端和 XMPP(jabber) 客户端之间即时消息的交换。


该网关有两种运行模式：


- **组件模式** - 网关需要一个独立的 XMPP 服务器，'xmpp' 模块作为
			XMPP 组件运行
- **服务器模式** - 该模块本身作为 XMPP 服务器运行，系统不需要其他 XMPP 服务器。
			注意：这是 XMPP 服务器的有限实现，
			目前不支持 SRV 或 TLS。此模式目前处于测试阶段。


在组件模式下，您需要一个本地 XMPP 服务器（推荐 jabberd2 或 ejabberd）；
	xmpp 模块将把您的所有连接中继到与本地 jabber 服务器的 TCP 连接。


运行 XMPP 服务器后，您需要在 OpenSIPS 配置文件中设置以下参数：


- xmpp_domain 和 xmpp_host，详见
				[导出的参数](#exported_parameters) 部分；
- socket= 您的 IP；
- alias=opensips 域和
	alias=网关域；
- 您也可以更改 jabber 服务器密码，该密码必须与 xmpp_password 参数相同。


组件模式的一个用例如下：


- OpenSIPS 运行在 sip-server.opensips.org；
- jabber 服务器运行在 xmpp.opensips.org；
- 组件运行在 xmpp-sip.opensips.org。


在服务器模式下，xmpp 模块是一个最小的 jabber 服务器，
	因此您不需要安装另一个 jabber 服务器，
	网关将连接到 jabber 服务器，
	您想要聊天的用户在这些服务器上拥有账户。


如果您想切换到服务器模式，
	必须将 "backend" 参数从 component 更改为 server，
	详见 [导出的参数](#exported_parameters) 部分。


服务器模式的一个用例如下：


- OpenSIPS 运行在 sip-server.opensips.org；
- "XMPP 服务器"运行在 xmpp-sip.opensips.org。


### 依赖


#### OpenSIPS 模块


以下模块必须在加载此模块之前加载：


- *需要 'tm' 模块*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *libexpat1-devel* - 用于解析/构建 XML。


### 导出的参数


#### backend (string)


您使用模块的模式，可以是 component 或 server。


*默认值为 "component"。*


```c title="设置 backend 参数"
...
 modparam("xmpp", "backend", "server")
...
```


#### xmpp_domain (string)


组件或服务器的 XMPP 域，取决于我们所处的模式。


*默认值为 "127.0.0.1"。*


```c title="设置 xmpp_domain 参数"
...
 modparam("xmpp", "xmpp_domain", "xmpp.opensips.org")
...
```


#### xmpp_host (string)


本地 jabber 服务器的 IP 地址或名称（如果 backend 设置为 "component"）；
	或在服务器模式下绑定的地址。


*默认值为 "127.0.0.1"。*


```c title="设置 xmpp_host 参数"
...
 modparam("xmpp", "xmpp_host", "xmpp.opensips.org")
...
```


#### sip_domain (string)


仅当在组件模式下使用 xmpp 模块且 jabber 服务器所在的主机域
	与 SIP 服务器的域相同时（当 SIP 服务和 XMPP 服务使用相同的域名时），
	才需要设置此参数。
	在这种情况下，
	如果我们要用该域在 xmpp 账户中添加联系人，
	那么所有到达 jabber 服务器的消息都将被视为本地 xmpp 用户的消息。
	因此，在 XMPP 中发送消息时，有必要将 SIP 域名转换为另一个域。
	此参数正是应该用作 XMPP 中 SIP 域名名称的参数。
	使用示例：如果 SIP 和 XMPP 域都是 opensips.org，
	且此参数设置为 sip.opensips.org，
	那么在 XMPP 中发送的所有请求中，
	SIP 用户的域将被转换为 sip.opensips.org。
	此外，在 XMPP 账户中，
	SIP 联系人必须使用此域：sip.opensips.org，
	当穿越网关时，它将被转换为真实的域 opensips.org。


*默认值为 NULL。*


```c title="设置 xmpp_host 参数"
...
 modparam("xmpp", "sip_domain", "sip.opensips.org")
...
```


#### xmpp_port (integer)


在组件模式下，这是我们连接的 jabber 路由器的端口。
	在服务器模式下，这是要绑定的传输地址。


*默认值为：如果 backend 设置为 "component" 则为 "5347"，
	如果 backend 设置为 "server" 则为 "5269"。*


```c title="设置 xmpp_port 参数"
...
 modparam("xmpp", "xmpp_port", 5269)
...
```


#### xmpp_password (string)


本地 jabber 服务器的密码。


*默认值为 "secret"；如果在此处更改，
	还必须在 c2s.xml 中更改，
	c2s.xml 由 jabber 服务器添加。
	jabberd2 默认配置如下：*


```c
			<router>
	............... 
	;
    <pass>secret</pass>;           ;	
				
```


```c title="设置 xmpp_password 参数"
...
 modparam("xmpp", "xmpp_password", "secret")
...
```


#### outbound_proxy (string)


发送消息时用作下一跳的 SIP 地址。
	当 OpenSIPS 使用不在 DNS 中的域名时，
	或当使用单独的 OpenSIPS 实例进行 xmpp 处理时，
	这非常有用。
	如果未设置，消息将被发送到目标 URI 中的地址。


*默认值为 NULL。*


```c title="设置 outbound_proxy 参数"
...
 modparam("xmpp", "outbound_proxy", "sip:opensips.org;transport=tcp")
...
```


### 导出的函数


#### xmpp_send_message()


将 SIP 消息转换为 XMPP(jabber) 消息，
	以便中继到 XMPP(jabber) 客户端。


```c title="xmpp_send_message() 使用示例"
...
xmpp_send_message();
...
```


### 配置


下面是一个用于实现独立 SIP 到 XMPP 网关的示例配置文件。
	您可以在单独的机器上或在不同端口上运行一个 OpenSIPS 实例，
	并使用以下配置，
	让主 SIP 服务器将所有 XMPP 世界的 SIP 请求转发到它。


[samples](./samples.md "include")
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0
