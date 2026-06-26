---
title: "资源列表服务器"
description: "该模块是 RFC 4662 和 RFC 4826 规范的资源列表服务器实现。"
---

## 管理指南


### 概述


该模块是 RFC 4662 和 RFC 4826 规范的资源列表服务器实现。


服务器独立于本地存在服务器，通过 Subscribe-Notify 消息检索存在信息。


该模块将存在模块用作库，因为它需要类似的机制来处理 Subscribe。因此，如果本地存在服务器与 RL 服务器不在同一台机器上，则存在模块应该仅以库模式加载（请参阅存在模块的文档）。


它以事件独立的方式处理对列表的订阅。默认事件是存在，但如果服务器要处理其他事件，应使用"rls_events"模块参数添加它们。


它与 XCAP 服务器配合进行存储。也可以配置为集成 xcap 服务器模式，此时它仅查询数据库以获取资源列表文档。这在小型架构中很有用，当所有客户端使用集成服务器且列表中没有对外部文档的引用时。


与存在模块相同，它具有带数据库定期更新的缓存模式用于订阅信息。通過 Notify 消息检索的信息仅存储在数据库中。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *数据库模块*。
- *signaling*。
- *tm*。
- *presence（以库模式）*。
- *pua*。
- *xcap*。


#### 外部库或应用程序


- *libxml-dev*。


### 导出的参数


#### rlsubs_table(str)


存储资源列表订阅信息的数据库表名称。


*默认值为 "rls_watchers"。*


```c title="设置 rlsubs_table 参数"
...
modparam("rls", "rlsubs_table", "rls_subscriptions")
...
```


#### rlpres_table(str)


存储通知事件特定信息的数据库表名称。


*默认值为 "rls_presentity"。*


```c title="设置 rlpres_table 参数"
...
modparam("rls", "rlpres_table", "rls_notify")
...
```


#### clean_period (int)


检查过期信息的时间周期。


*默认值为 "100"。*


```c title="设置 clean_period 参数"
...
modparam("rls", "clean_period", 100)
...
```


#### waitn_time (int)


服务器尝试发送带有订阅列表或观察者信息更新存在状态的 Notify 的计时器周期。


*默认值为 "50"。*


```c title="设置 waitn_time 参数"
...
modparam("rls", "waitn_time", 10)
...
```


#### max_expires (int)


订阅列表的最大允许过期时间。


*默认值为 "7200"。*


```c title="设置 max_expires 参数"
...
modparam("rls", "max_expires", 10800)
...
```


#### hash_size (int)


用于存储订阅列表的哈希表维度。此参数在计算表大小时将用作 2 的幂。


*默认值为 "9 (512)"。*


```c title="设置 hash_size 参数"
...
modparam("rls", "hash_size", 11)
...
```


#### xcap_root (str)


xcap 服务器的地址。


*默认值为 "NULL"。*


```c title="设置 hash_size 参数"
...
modparam("rls", "xcap_root", "http://192.168.2.132/xcap-root:800")
...
```


#### to_presence_code (int)


如果处理的 Subscribe 不是资源列表 Subscribe，则由 rls_handle_subscribe 函数返回的代码。当存在和 rls 服务器在同一台机器上的架构中，此代码可用于对导致此代码的消息调用 handle_subscribe。


*默认值为 "0"。*


```c title="设置 to_presence_code 参数"
...
modparam("rls", "to_presence_code", 10)
...
```


#### rls_event (str)


RLS 处理的默认事件是存在。如果其他事件也应由 RLS 处理，应使用此参数添加。它可以设置多次。


*默认值为 ""presence""。*


```c title="设置 rls_event 参数"
...
modparam("rls", "rls_event", "dialog;sla")
...
```


#### presence_server (str)


存在服务器的地址。它将用作 RLS 服务器发送的 Subscribe 请求的出站代理，以避免在代理上弹跳并需要在代理配置文件中包含对此消息的特殊处理。


```c title="设置 presence_server 参数"
...
modparam("rls", "presence_server", "sip:pres@opensips.org:5060")
...
```


#### contact_user (str)


这是在 200 OK 回复 SUBSCRIBE 时以及在后续的同-dialog NOTIFY 请求中使用的 Contact 头中的用户名，也是 RLS 服务器生成的 SUBSCRIBE 请求中使用的用户名。Contact 的 IP 地址、端口和传输将根据接收或发送 SUBSCRIBE 的接口自动确定。


如果设置为空字符串，则不会在 contact 中添加用户名，contact 将仅由 IP、端口和传输构建。


*默认值为 "rls"。*


```c title="设置 contact_user 参数"
...
modparam("rls", "contact_user", "rls")
...
```


### 导出的函数


#### rls_handle_subscribe()


此函数检测 Subscribe 消息是否应由 RLS 处理。如果不是，它回复配置的 to_presence_code。如果是，它提取对话信息并发送带有列表信息的聚合 Notify 请求。


此函数可用于 REQUEST_ROUTE。


```c title="rls_handle_subscribe 用法"
...
对于同一机器上的存在和 rls：
	modparam(rls, "to_presence_code", 10)

	如果（是方法("SUBSCRIBE")）
	{	
		$var(ret_code)= rls_handle_subscribe();

		如果($var(ret_code)== 10)
				handle_subscribe();

		t_release();
	}

仅用于 rls：
	如果（是方法("SUBSCRIBE")）
	{
		rls_handle_subscribe();
		t_release();
	}

...
```


#### rls_handle_notify()


此函数必须为存在服务器回复 RLS 发送的 Subscribe 消息的 Notify 消息调用。


此函数可用于 REQUEST_ROUTE。


它可以返回 3 个代码：


- *1* - Notify 在 RLS 服务器识别的对话中，处理成功。
- *2* - Notify 不属于 RLS 服务器发起的对话。
- *-1* - 处理过程中发生错误。


```c title="rls_handle_notify 用法"
...
如果($rm=="NOTIFY")
    rls_handle_notify();
...
```


### 导出的 MI 函数


#### rls:update_subscriptions


替换已弃用的 MI 命令：*rls_update_subscriptions*。


在资源列表或 rls-services 文档更新后触发后端订阅更新。


名称：*rls:update_subscriptions*


参数：


- presentity_uri : 进行更改的用户的 URI，其订阅应被更新


MI FIFO 命令格式：


```c
opensips-cli -x mi rls:update_subscriptions sip:alice@atlanta.com
	
```


### 安装


该模块需要在 OpenSIPS 数据库中有 2 个表：rls_presentity 和 rls_watchers。创建它们的 SQL 语法可以在 opensips/scripts 文件夹的数据库目录中的 rls-create.sql 脚本中找到。
您还可以在项目网页上找到完整的数据库文档，[https://opensips.org/docs/db/db-schema-devel.html](https://opensips.org/docs/db/db-schema-devel.html)。


## 开发者指南


该模块不提供供其他 OpenSIPS 模块使用的函数。
<!-- CONTRIBUTORS -->

### 许可

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0 版授权
