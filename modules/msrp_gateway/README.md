---
title: "MSRP Gateway 模块"
description: "本模块实现了一个网关,用于在页面模式(SIP MESSAGE 方法)和会话模式(MSRP)即时消息之间进行转换。"
---

## 管理指南


### 概述


本模块实现了一个网关,用于在页面模式
(SIP MESSAGE 方法)和会话模式(MSRP)即时消息之间进行转换。


该模块利用 *msrp_ua* 模块的 API 来实现
MSRP UAC/UAS 功能。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载:


- *tm*
- *msrp_ua*


#### 外部库或应用程序


运行 OpenSIPS 加载此模块之前必须安装以下库或应用程序:


- *无*。


### 导出的参数


#### hash_size (int)


存储网关会话信息的哈希表大小。
这是实际大小的以 2 为底的对数值。


*默认值为 "10"*
(1024 条记录)。


```c title="设置 hash_size 参数"
...
modparam("msrp_gateway", "hash_size", 16)
...
		
```


#### cleanup_interval (int)


完整遍历会话表进行清理残留会话的间隔时间。


*默认值为 "60"。 (秒)*


```c title="设置 cleanup_interval 参数"
...
modparam("msrp_gateway", "cleanup_interval", 60)
...
		
```


#### session_timeout (int)


从任一方上次收到消息后经过的时间(秒),超过该时间会话将被终止。


*默认值为 12 * 3600 秒(12 小时)。*


```c title="设置 session_timeout 参数"
...
modparam("msrp_gateway", "session_timeout", 7200)
...
		
```


#### message_timeout (int)


自上次收到 MESSAGE 后经过的时间(秒),超过该时间会话将被终止。


*默认值为 2 * 3600 秒(2 小时)。*


```c title="设置 message_timeout 参数"
...
modparam("msrp_gateway", "message_timeout", 3600)
...
		
```


### 导出的函数


#### msrp_gw_answer(key, content_types, from, to, ruri)


此函数通过应答来自 MSRP 侧 SIP 会话的初始 INVITE 来初始化一个新的网关会话。运行此函数后,
呼叫将完全由 MSRP UA 引擎处理,MSRP SEND 请求将自动转换为 SIP MESSAGE 请求。


用于构建 MESSAGE 请求的 SIP From、To 和 RURI 坐标作为参数传递给函数。


参数:


- *key* (string) - 网关会话密钥,用于将 MESSAGE 请求与 MSRP 侧 SIP 会话关联。
一个简单的例子是根据初始 MSRP 侧 INVITE 和 SIP MESSAGE 请求各自的 From 和 To URI 来构建此密钥。
- *content_types* (string) - 在 MSRP 侧 SIP 会话的 SDP offer 中公布的内容类型。
- *from* (string) - 用于构建 SIP MESSAGE 请求的 From URI。
- *to* (string) - 用于构建 SIP MESSAGE 请求的 To URI。
- *ruri* (string) - 用于构建 SIP MESSAGE 请求的 Request-URI。


此函数只能用于请求路由。


```c title="msrp_gw_answer() 用法"
...
if (!has_totag() && is_method("INVITE")) {
	msrp_gw_answer($var(corr_key), "text/plain", $fu, $tu, $ru);
	exit;
}
...
```


#### msg_to_msrp(key, content_types)


此函数将 SIP MESSAGE 请求转换为 MSRP SEND 请求。
如果之前的调用尚未完成,该函数将初始化一个新的网关会话并建立 MSRP 侧 SIP 会话。


新的 MSRP 侧会话的 SIP From、To 和 RURI 坐标取自 MESSAGE 请求,
并在通过 *msrp_gw_answer* 将 MSRP SEND 转换回 SIP MESSAGE 时镜像回来。


参数:


- *key* (string) - 网关会话密钥,用于将 MESSAGE 请求与 MSRP 侧 SIP 会话关联。
一个简单的例子是根据初始 MSRP 侧 INVITE 和 SIP MESSAGE 请求各自的 From 和 To URI 来构建此密钥。
- *content_types* (string) - 在 MSRP 侧 SIP 会话的 SDP offer 中公布的内容类型。


此函数只能用于请求路由。


```c title="msg_to_msrp() 用法"
...
if (is_method("MESSAGE")) {
	msg_to_msrp($var(corr_key), "text/plain");
	exit;
}
...
```


### 导出的 MI 函数


#### msrp_gateway:list_sessions


替代已废弃的 MI 命令: *msrp_gw_list_sessions*。


列出正在进行的会话信息。


名称: *msrp_gateway:list_sessions*


参数


- *无*。


MI FIFO 命令格式:


```c
opensips-cli -x mi msrp_gateway:list_sessions
		
```


#### msrp_gateway:end_session


替代已废弃的 MI 命令: *msrp_gw_end_session*。


终止正在进行的会话。


名称: *msrp_gateway:end_session*


参数


- *key* (string) - 会话密钥


MI FIFO 命令格式:


```c
opensips-cli -x mi msrp_gateway:end_session alice@opensips.org-bob@opensips.org
		
```


### 导出的事件


#### E_MSRP_GW_SETUP_FAILED


当使用 *msg_to_msrp()* 函数时,MSRP 侧 SIP 会话建立失败,触发此事件。


该事件可用于生成包含失败描述的消息,
返回到 MESSAGE 侧。


参数:


- *key* - 会话密钥。
- *from_uri* - SIP From 头中的 URI,
用于 MESSAGE 侧。
- *to_uri* - SIP To 头中的 URI,
用于 MESSAGE 侧。
- *ruri* - SIP Request URI 用于
MESSAGE 侧。
- *code* - MSRP 侧收到的否定回复中的 SIP 错误代码。
如果 MSRP UA 会话在收到否定回复之前过期,则可能为 NULL。
- *reason* - MSRP 侧收到的否定回复中的 SIP 原因字符串。
如果 MSRP UA 会话在收到否定回复之前过期,则可能为 NULL。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)均采用知识共享许可证 4.0 版授权
