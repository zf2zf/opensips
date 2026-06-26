---
title: "proto_ipsec 模块"
description: "**proto_ipsec** 模块提供用于建立安全通信通道的 IPSec 套接字。它依赖 RFC 3329(Session Initiation Protocol (SIP) 的安全机制协议)来建立创建动态安全关联(SA)所需的 IPSec 参数,用于每个连接。"
---

## 管理指南


### 概述


**proto_ipsec** 模块提供用于建立安全通信通道的 IPSec 套接字。
		它依赖 RFC 3329(Session Initiation Protocol (SIP) 的安全机制协议)来建立创建动态安全关联(SA)所需的 IPSec 参数,用于每个连接。


此模块完全符合 VoLTE 规范(GSMA PRD IR.92)开发,并实现了 TS 33.203(3G 安全:基于 IP 服务的接入安全)中定义的扩展。


它允许在相同的 IP:port 对上创建 UDP 和 TCP 安全连接,定义为套接字。本质上,当使用 *proto_ipsec* 协议定义套接字时,会在指定端口上创建两个新的内部/隐藏套接字。
例如,定义以下套接字:
```c

...
socket=ipsec:127.0.0.1:5100
...
```
		内部创建两个不同的套接字:
```c

...
socket=udp:127.0.0.1:5100
socket=tcp:127.0.0.1:5100
...
```
		通过这些套接字的通信应通过 IPSec 进行,因此在使用这些监听器之前应按照 RFC 3329 的定义建立适当的安全关联(SA)。


*注意* 这意味着你不能再在配置中定义这些套接字,否则它们会与内部定义的套接字重叠。


IPSec 通信要求每个参与者为每个连接定义至少两个端口:一个在实体作为客户端时,另一个在实体作为服务器时。因此,通常需要定义至少两个 IPSec 套接字才能使模块正常工作。


该模块实现了通过挂接到 usrloc 模块并监听联系变更更新来跟踪注册状态的全部逻辑。它还通过在重启后恢复隧道来确保隧道的持久性。


当通过 IPSec 隧道收到请求时,模块提供两个变量 [ipsec](#pv_ipsec) 和
		[ipsec ue](#pv_ipsec_ue) 来检查其详情。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载:


- *tm* - 用于跟踪请求和回复之间的 IPSec
				SA 上下文。
- *usrloc* - 用于识别
				注册/注销何时成功发生。
- *proto_udp* - 用于处理
				IPSec UDP 连接操作。
- *proto_tcp* - 用于处理
				IPSec TCP 连接操作。


#### 外部库或应用程序


运行 OpenSIPS 加载此模块之前,必须安装以下库或应用程序:


- *libmnl* - 最小化 Netlink 库,
				用于使用 XFRM 内核接口创建 IPSec SA。


### 导出的参数


#### port (integer)


当 *socket* 全局参数中未指定端口时使用的默认 IPSec 端口。


*默认值为 5062。*


```c title="设置 port 参数"
...
modparam("proto_ipsec", "port", 5100)
...
```


#### min_spi (integer)


此参数表示安全关联(SA)SPI 参数的最小值。与
			*max_spi* 设置结合,它定义 SPI
			范围 *[min_spi, max_spi]*,该范围在系统内必须是唯一的。


*默认值为 65536。*


```c title="设置 min_spi 参数"
...
modparam("proto_ipsec", "min_spi", 10000)
...
```


#### max_spi (integer)


此参数表示安全关联(SA)SPI 参数的最大值。与
			*min_spi* 设置结合,它定义 SPI
			范围 *[min_spi, max_spi]*,该范围在系统内必须是唯一的。


*默认值为 262144。*


```c title="设置 max_spi 参数"
...
modparam("proto_ipsec", "max_spi", 20000)
...
```


#### temporary_timeout (integer)


设置临时安全关联可以存储在内存中直到被远程端点确认(或使用)的超时时间(秒)。


超时表示在 401 回复中发送安全关联(SA)参数之后,以及用户设备(UE)通过新的安全通道传输初始消息之间经过的时间。


*默认值为 30。*


```c title="设置 temporary_timeout 变量"
param("proto_ipsec", "temporary_timeout", 10) # 秒数

			
```


#### default_client_port (integer)


当我们在 IPSec 通信中充当客户端时使用的默认端口值。


*默认值为未定义 - 使用随机套接字,但需要与服务器套接字不同。*


```c title="设置 default_client_port 参数"
...
modparam("proto_ipsec", "default_client_port", 5100)
...
```


#### default_server_port (integer)


当我们在 IPSec 通信中充当服务器时使用的默认端口值。


*默认值为未定义 - 使用随机套接字,但需要与客户端套接字不同。*


```c title="设置 default_server_port 参数"
...
modparam("proto_ipsec", "default_server_port", 6100)
...
```


#### allowed_algorithms (string)


白名单允许用于 IPSec 的认证和加密算法。


其格式为: *alg|ealg|alg=ealg*


多个算法对可用逗号分隔指定。


当前支持的算法:


- 认证算法:
					
					hmac-md5-96 - 被 TS 33.203 V13 弃用
					hmac-sha-1-96 - 不推荐由 TS 33.203 V17
					aes-gmac
					null - 必须仅与 aes-gcm 加密一起使用
- 加密算法:
					
					des-ede3-cbc - 不推荐
					aes-cbc - 不推荐由 TS 33.203 V17
					aes-gcm
					null - 无加密


*默认值为无 - 这意味着可以使用所有算法。*


```c title="设置 allowed_algorithms 参数"
...
modparam("proto_ipsec", "allowed_algorithms", "null")
modparam("proto_ipsec", "allowed_algorithms", "hmac-sha-1-96=null")
modparam("proto_ipsec", "allowed_algorithms", "hmac-sha-1-96=null,aes-gmac=aes-gcm")
...
```


#### disable_deprecated_algorithms (integer)


指示我们是否应忽略已弃用的算法,
			如 TS 33.203(3G 安全:基于 IP 服务的接入安全)所定义。目前,这禁用以下算法:


- *hmac-md5-96* 和 *hmac-sha-1-96* 认证算法
- *des-ede3-cbc* 和 *aes-cbc* 加密算法


*默认值为 false - 可以使用所有算法。*


```c title="设置 disable_deprecated_algorithms 参数"
...
modparam("proto_ipsec", "disable_deprecated_algorithms", yes)
...
```


### 导出的函数


#### ipsec_create([port_server], [port_client], [algos])


根据 *Security-Client* 头和 401 回复中收到的 AKA 信息创建 IPSec SA/隧道。


此函数只应在 REGISTER 消息的 401 回复上调用。


成功创建 IPSec 隧道后,它会构建 *Security-Server* 头并将其附加到回复中。


参数含义如下:


- *port_server (integer, 可选)* - IPSec 通信中使用的服务器端口。它应该是一个现有的 IPSec 端口,并在 *Security-Server* 头中公布。如果缺失,则考虑 [default client port](#param_default_client_port)。
- *port_client (integer, 可选)* - IPSec 通信中使用的客户端端口。它应该是一个现有的 IPSec 端口,并在 *Security-Server* 头中公布。如果缺失,则考虑 [default server port](#param_default_server_port)。
- *algos (string, 可选)* - 用于创建此安全关联的算法列表。它具有与 [allowed algorithms](#param_allowed_algorithms) 相同的格式,使用时覆盖其值。如果缺失,则考虑 [allowed algorithms](#param_allowed_algorithms)。


此函数可用于 REPLY_ROUTE。


```c title="ipsec_create() 使用示例"
...
onreply_route[ipsec] {
	if ($T_reply_code == 401)
		if (ipsec_create())
}
...
```


### 导出的伪变量


#### $ipsec


对于通过 IPSec 隧道接收的请求填充,它包含有关本地 IPSec 端点的信息。


可以检索以下字段:


- *ik* - IPSec 隧道使用的完整性密钥。
- *ck* - IPSec 隧道使用的保密密钥。
- *alg* - 使用的认证算法。
- *ealg* - 使用的加密算法。
- *ip* - 绑定到此隧道的本地 IP。
- *spi-c* - 为通过客户端通道接收消息而选择的本地 SPI。
- *spi-s* - 为通过服务器通道接收消息而选择的本地 SPI。
- *port-c* - 为通过客户端通道通信而选择的本地端口。
- *port-c* - 为通过服务器通道通信而选择的本地端口。


```c title="$ipsec(field) 使用示例"
...
xlog("Using $ipsec(ip):$ipsec(port-c) and $ipsec(ip):$ipsec(port-s) socket\n");
...
```


#### $ipsec_ue


对于通过 IPSec 隧道接收的请求填充,它包含有关远程 IPSec 端点的信息。


可以检索以下字段:


- *ik* - IPSec 隧道使用的完整性密钥。
- *ck* - IPSec 隧道使用的保密密钥。
- *alg* - 使用的认证算法。
- *ealg* - 使用的加密算法。
- *ip* - 使用此隧道的 UE 的远程 IP。
- *spi-c* - 为通过客户端通道发送消息而选择的远程 SPI。
- *spi-s* - 为通过服务器通道发送消息而选择的远程 SPI。
- *port-c* - 为通过客户端通道通信而选择的远程端口。
- *port-c* - 为通过服务器通道通信而选择的远程端口。


```c title="$ipsec_ue(field) 使用示例"
...
xlog("Using $ipsec_ue(ip):$ipsec_ue(port-c) and $ipsec_ue(ip):$ipsec_ue(port-s) socket\n");
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)采用 Creative Common License 4.0 授权
