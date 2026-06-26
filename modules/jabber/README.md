---
title: "Jabber 模块"
description: "这是集成 XODE XML 解析器用于解析 Jabber 消息的新版本 Jabber 模块。这引入了一个新的模块依赖：expat 库。"
---

## 管理指南


### 概述


这是集成 XODE XML 解析器用于解析 Jabber 消息的新版本 Jabber 模块。
		这引入了一个新的模块依赖：expat 库。


Expat 是一个常见的 XML 库，是 Linux/Unix 上最快的 XML 库，
		在所有库中排名第二，仅次于 msxml 库。它已集成在大多数知名 Linux 发行版中。


#### 新功能


- 支持存在状态（参见 doc/xxjab.cfg 获取示例 cfg 文件）（2003 年 1 月）。
- SIP 到 Jabber 会议支持（2003 年 12 月）。
- 管理各种 Jabber 消息的可能性
			（message/presence/iq）（2003 年 12 月）。
- 别名 -- 为地址设置主机别名的可能性
			（参见参数说明）（2003 年 12 月）。
- 发送接收到的 SIP MESSAGE 消息到不同的 IM 网络
			（Jabber、ICQ、MSN、AIM、Yahoo），使用 Jabber 服务器（2003 年 12 月）。
- 将收到的 Jabber 即时消息作为 SIP MESSAGE 消息发送。
- 网关检测 -- 能够查看 IM 网关是上线还是下线。


### 管理员指南


> [!NOTE]
> 关于 SIMPLE2Jabber 网关的更完整指南可以在
		[https://opensips.org/](https://opensips.org/) 找到。以下部分将很快被删除，只有网页上的手册会更新。


Jabber 服务器设置不是本指南的主题。请查看 [http://www.jabber.org](http://www.jabber.org) 获取相关信息。


用于创建 Jabber 网关数据库或从 Web 管理 Jabber 账户的有用脚本
		位于模块的 'doc' 子目录中。


使用 Jabber 网关的主要步骤：


- 创建 MySQL 数据库。
- 设置本地 Jabber 服务器。
- 在 OpenSIPS 的 cfg 文件中设置模块参数值，加载依赖模块，设置 Jabber 网关的路由规则。
- 运行 OpenSIPS。


OpenSIPS/Jabber 网关管理员 *必须*
		告知用户 Jabber/其他 IM 网络的别名是什么。
		其他 IM 可以是 AIM、ICQ、
		MSN、Yahoo 等。


这些别名取决于运行 OpenSIPS 的服务器主机名以及本地 Jabber 服务器的设置方式。


接下来是一个用例。前言：


- OpenSIPS 运行在 "server.org" 上。
- 本地 Jabber 服务器运行在 "jabsrv.server.org" 上。
- Jabber 网络别名（"jdomain" 的第一部分）是 "jabber.server.org"


其他 IM 网络的别名 *必须* 与 Jabber 配置文件中为每个 IM 传输设置的 JID 相同。


Jabber 传输的 JID *必须* 以网络名称开头。
		对于 AIM，JID 必须以 "aim." 开头；对于 ICQ，
		以 "icq" 开头（因为我使用 icqv7-t）；
		对于 MSN，以 "msn." 开头；
		对于 Yahoo，以 "yahoo." 开头。网关需要这些来查明哪个传输正在工作，哪个不工作。对于我们的用例，这些可能是 "aim.server.org"、
		"icq.server.org"、
		"msn.server.org"、"yahoo.server.org"。


建议在 DNS 中设置这些别名，以便客户端应用程序可以解析 DNS 名称。
		否则必须将出站代理设置为 OpenSIPS 服务器。


*** Jabber 网关的路由规则 第一步是配置 OpenSIPS
		以识别发往 Jabber 网关的消息。查看
		"doc/xjab.cfg" 了解示例。思路是查看消息中的目标地址，
		如果包含 Jabber 别名或其他 IM 别名，则意味着该消息是发往 Jabber 网关的。


下一步是了解发往 Jabber 网关的消息意味着什么。
		它可能是一条触发网关执行操作的特殊消息，
		或者是一条应使用 "jab_send_message" 方法传递到 Jabber 网络的简单消息。


特殊消息用于：


- 注册到 Jabber 服务器（在 Jabber 网络中上线）-- 这里必须调用 "jab_go_online" 方法。
- 离开 Jabber 网络（在 Jabber 网络中下线）-- 这里必须调用 "jab_go_offline" 方法。
- 加入 Jabber 会议室 -- 这里必须调用 "jab_join_jconf"。
- 离开 Jabber 会议室 -- 这里必须调用 "jab_exit_jconf"。


目标地址 *必须* 遵循以下格式：


- 对于 Jabber 网络：
			"username<delim>jabber_server@jabber_alias"。
- 对于 Jabber 会议："nickname<delim>room<delim>conference_server@jabber_alias"。
- 对于 AIM 网络：
			"aim_username@aim_alias"。
- 对于 ICQ 网络：
			"icq_number@icq_alias"。
- 对于 MSN 网络：
			"msn_username<delim>msn_server@msn_alias"。
			msn_server 可以是 "msn.com" 或 "hotmail.com"。
- 对于 YAHOO 网络："yahoo_username@yahoo_alias"。


> [!NOTE]
> "jabber_alias" 是 "jdomain" 的第一部分。


### 管理指南


用户必须激活与其 SIP ID 关联的 Jabber 账户。对于他想要发送消息的其他每个 IM 网络，
		他必须为该 IM 网络设置一个账户。网关无法在外来网络中创建新账户，本地 Jabber 服务器除外。


当您想向其他 IM 网络中的某用户发送消息时，
		必须根据该 IM 网络对应的格式设置消息目标
		（参见"管理指南"章节的最后部分）。


对于 Jabber 网络中位于 user@jabber.xxx.org 的用户，
		目标必须是：user<delim>jabber.xxx.org@jabber_alias。


对于位于 Yahoo 网络的用户，目标必须是：
	user@yahoo_alias


> [!NOTE]
> OpenSIPS 管理员必须为每个 IM 网络设置 Jabber 传输，
		以便能够向这些网络发送消息。每个 IM 网络的别名可以从 OpenSIPS 管理员处获取。
		您无法从 SIP 客户端向关联的 Jabber 账户发送消息 -- 这类似于向自己发送消息。


### 依赖


#### OpenSIPS 模块


加载此模块之前必须加载以下模块：


- 数据库模块。
- *pa*（可选）-- 存在代理。
- *tm* -- 事务管理器。


#### 外部库或应用程序


运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- *Expat* 库。


### 导出的参数


#### db_url (字符串)


数据库的 SQL URL。


*默认值为 "mysql://root@127.0.0.1/sip_jab"*。


```c title="设置 db_url 参数"
...
modparam("jabber", "db_url", "mysql://username:password@host/sip_jab")
...
```


#### jaddress (字符串)


Jabber 服务器的 IP 或主机名 -- 它必须与 Jabber 服务器配置文件 <host> 标签中的值相同。


*默认值为 "127.0.0.1"*。


```c title="设置 jaddress 参数"
...
modparam("jabber", "jaddress", "1.2.3.4")
...
```


#### jport (整数)


Jabber 服务器端口号。


*默认值为 "5222"*。


```c title="设置 jport 参数"
...
modparam("jabber", "jport", 1234)
...
```


#### jdomain (字符串)


格式：jabber.sipserver.com=<delim>。如果目标是 Jabber 网络，
		则 URI 应为：username<delim>jabber_server@jdomain 或
		nickname<delim>roomname<delim>conference_server@jdomain


<delim> 必须是一个非保留字符。默认情况下，此字符是 *。目标将被转换为
		username@jabber_server 或 roomname@conference_server/nickname，
		然后再发送到 Jabber 服务器。


*默认值为无。*


```c title="设置 jdomain 参数"
...
modparam("jabber", "jdomain", "jabber.sipserver.com=*")
...
```


#### aliases (字符串)


IM 网络的别名。


格式："N;alias1=<delim1>;...;aliasN=<delimN>;"
		像 '*@aliasX' 这样的目标可以具有与 Jabber 网络指定的格式不同的格式。
		如果目标地址包含 <aliasX>，
		则目标地址用户部分中的所有 <delim> 将被更改为 <delimX>。


（例如，jdomain 是 'jabber.x.com=*'，msn_alias 是 'msn.x.com=%'。
		SIP 端 MSN 网络的目标地址格式为 'username*hotmail.com@msn.x.com'。
		目标地址将被转换为 'username%hotmail.com@msn.x.com'。
		'msn.x.com' 必须与 Jabber 配置文件中与 MSN 传输关联的 JID 相同
		（通常是 'jabberd.xml'）


*默认值为无。*


```c title="设置 jdomain 参数"
...
modparam("jabber", "aliases", "1;msn.x.com=%")
...
```


#### proxy (字符串)


出站代理地址。


格式：ip_address:port hostname:port


所有网关生成的 SIP 消息都将发送到该地址。如果缺失，
		消息将被传递到目标地址的主机名


默认值为无。


```c title="设置 proxy 参数"
...
modparam("jabber", "proxy", "10.0.0.1:5060 sipserver.com:5060")
...
```


#### registrar (字符串)


代表其发送 INFO 和 ERROR 消息的地址。


*默认值为 "jabber_gateway@127.0.0.1"*。


```c title="设置 registrar 参数"
...
modparam("jabber", "registrar", "jabber_gateway@127.0.0.1")
...
```


#### workers (整数)


工作进程数。


*默认值为 2。*


```c title="设置 workers 参数"
...
modparam("jabber", "workers", 2)
...
```


#### max_jobs (整数)


每个工作进程的最大作业数。


*默认值为 10。*


```c title="设置 max_jobs 参数"
...
modparam("jabber", "max_jobs", 10)
...
```


#### cache_time (整数)


Jabber 连接的缓存时间。


*默认值为 600。*


```c title="设置 cache_time 参数"
...
modparam("jabber", "cache_time", 600)
...
```


#### delay_time (整数)


保留 SIP 消息的时间（秒）。


*默认值为 90 秒。*


```c title="设置 delay_time 参数"
...
modparam("jabber", "delay_time", 90)
...
```


#### sleep_time (整数)


检查过期 Jabber 连接之间的时间（秒）。


*默认值为 20 秒。*


```c title="设置 sleep_time 参数"
...
modparam("jabber", "sleep_time", 20)
...
```


#### check_time (整数)


检查 JabberGW 工作进程状态的时间间隔（秒）。


*默认值为 20 秒。*


```c title="设置 check_time 参数"
...
modparam("jabber", "check_time", 20)
...
```


#### priority (字符串)


Jabber 网关的存在状态优先级。


*默认值为 "9"。*


```c title="设置 priority 参数"
...
modparam("jabber", "priority", "3")
...
```


### 导出的函数


#### jab_send_message()


将 SIP MESSAGE 消息转换为 Jabber 消息并发送到 Jabber 服务器。


此函数可用于 REQUEST_ROUTE。


```c title="jab_send_message() 用法"
...
jab_send_message();
...
```


#### jab_join_jconf()


加入 Jabber 会议 -- 昵称、会议室名称和会议服务器地址
		应包含在 To 头中，格式为：nickname%roomname%conference_server@jdomain。
		如果昵称缺失，则使用 SIP 用户名。


此函数可用于 REQUEST_ROUTE。


```c title="jab_join_jconf() 用法"
...
jab_join_jconf();
...
```


#### jab_exit_jconf()


离开 Jabber 会议 -- 昵称、会议室名称和会议服务器地址
		应包含在 To 头中，格式为：nickname%roomname%conference_server@jdomain。


此函数可用于 REQUEST_ROUTE。


```c title="jab_exit_jconf() 用法"
...
jab_exit_jconf();
...
```


#### jab_go_online()


使用 SIP 用户的关联 Jabber ID 注册到 Jabber 服务器。


此函数可用于 REQUEST_ROUTE。


```c title="jab_go_online() 用法"
...
jab_go_online();
...
```


#### jab_go_offline()


从 Jabber 服务器注销 SIP 用户的关联 Jabber ID。


此函数可用于 REQUEST_ROUTE。


```c title="jab_go_offline() 用法"
...
jab_go_offline();
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议。
