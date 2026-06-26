---
title: "MSRP UA 模块"
description: "本模块实现了一个用户代理,能够使用 MSRP(RFC 4976)协议建立消息会话。"
---

## 管理指南


### 概述


本模块实现了一个用户代理,能够使用 MSRP(RFC 4976)协议建立消息会话。


通过内部 API 和导出的脚本及 MI 函数,该模块允许 OpenSIPS 通过 SIP 设置 MSRP 会话,
并作为 MSRP 端点交换消息。


该模块利用 *proto_msrp* 模块来实现 MSRP 协议栈,
以及 *b2b_entities* 模块来实现 SIP UAC/UAS 功能。


### 脚本和外部 API 使用


要从 OpenSIPS 发起携带 MSRP 的 SIP 呼叫,您可以使用
[mi start session](#mi_start_session) MI 函数。或者,要应答携带 MSRP 的 SIP 会话,
您可以使用 [msrp ua answer](#func_msrp_ua_answer) 脚本函数。


当 UAC 或 UAS 会话成功建立(ACK 发送/接收)时,
会触发 [E MSRP SESSION NEW](#event_e_msrp_session_new) 事件。此后,
您可能会收到 MSRP 消息或报告,由 [E MSRP MSG RECEIVED](#event_e_msrp_msg_received) 和
[E MSRP REPORT RECEIVED](#event_e_msrp_report_received) 事件信号通知。


请注意,*E_MSRP_REPORT_RECEIVED* 事件涵盖实际的 MSRP REPORT 请求、
否定的 MSRP 事务响应和本地发送超时(这些应被视为收到超时事务响应)。


您可以使用 [mi send message](#mi_send_message) MI 函数向对方发送 MSRP 消息。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载:


- *proto_msrp*
- *b2b_entities*


#### 外部库或应用程序


运行 OpenSIPS 加载此模块之前必须安装以下库或应用程序:


- *无*。


### 导出的参数


#### hash_size (int)


存储 MSRP 会话信息的哈希表大小。
这是实际大小的以 2 为底的对数值。


*默认值为 "10"*
(1024 条记录)。


```c title="设置 hash_size 参数"
...
modparam("msrp_ua", "hash_size", 16)
...
		
```


#### cleanup_interval (int)


完整遍历会话表进行清理过期 MSRP 会话的间隔时间。


*默认值为 "60"。*


```c title="设置 cleanup_interval 参数"
...
modparam("msrp_ua", "cleanup_interval", 30)
...
		
```


#### max_duration (integer)


呼叫的最大持续时间。如果设置为 0,则没有限制。


默认值为 12 * 3600 秒(12 小时)。


```c title="max_duration 参数示例"
...
modparam("msrp_ua", "max_duration", 7200)
...
```


#### my_uri (string)


OpenSIPS 端点的 MSRP URI。此 URI 将在提供给对方的 SDP offer 中公布,
并应与脚本中定义的 MSRP 监听器之一匹配。


URI 的 *session-id* 部分应省略。


如果未明确设置端口,则假定默认值为 2855


```c title="my_uri 参数用法"
...
modparam("msrp_ua", "my_uri", "msrp://opensips.org:2855;tcp")
...
```


#### advertised_contact (string)


在生成的 SIP 请求中使用的 Contact。对于由 OpenSIPS 应答的会话,
如果未设置,则会根据接收发起请求的套接字动态构建。


使用 [mi start session](#mi_start_session) MI 函数时,
此参数是必需的。


```c title="advertised_contact 参数用法"
...
modparam("msrp_ua", "advertised_contact", "sip:oss@opensips.org")
...
```


#### relay_uri (string)


用于已接受和发起会话的 MSRP 中继 URI。


MSRP 客户端的凭据通过 *uac_auth* 模块提供,
设置 *credential* 模块参数。


如果未设置,则不使用中继。


```c title="relay_uri 参数用法"
...
modparam("msrp_ua", "relay_uri", "msrp://opensips.org:2856;tcp")
...
```


### 导出的函数


#### msrp_ua_answer(content_types)


此函数应答发起新的 MSRP 消息会话的初始 INVITE。
使用此函数初始化会话后,呼叫将完全由 B2B 引擎处理。


参数:


- *content_types* (string) - 在 *accept-types* SDP
属性中公布的内容类型。此列表中至少有一种内容类型必须与对方在其 SDP offer 中提供的内容类型匹配。


此函数只能用于请求路由。


```c title="msrp_ua_answer() 用法"
...
if (!has_totag() && is_method("INVITE")) {
	msrp_ua_answer("text/plain");
	exit;
}
...
```


### 导出的 MI 函数


#### msrp_ua:send_message


替代已废弃的 MI 命令: *msrp_ua_send_message*。


向对方发送新的 MSRP 消息。


名称: *msrp_ua:send_message*


参数


- *session_id* (string) - MSRP 会话
标识符(MSRP URI 的 "session-id" 部分)。
- *mime* (string, 可选) - 此消息的 MIME 内容
类型。如果缺失,将发送空消息。
- *body* (string, 可选) - 实际的消息
体。如果缺失,将发送空消息。
- *success_report* (string, 可选) - 字符串,
指示是否请求 MSRP Success Report。可能的
值为 *yes* 或 *no*。
如果参数缺失或设置为 "no",则 SEND 请求
将不包含 Success-Report 头。
- *failure_report* (string, 可选) - 字符串,
指示是否请求 MSRP Failure Report。可能的
值为 *yes*、*no* 或
*partial*,如 MSRP 中所规定。
如果参数缺失或设置为 "yes",则 SEND 请求
将不包含 Failure-Report 头。请注意,如果头
字段不存在,接收 MSRP 端点必须将其视为
值为 "yes" 的 Failure-Report 头。


MI FIFO 命令格式:


```c
opensips-cli -x mi msrp_ua:send_message \
	session_id=5addd9e7b74fa44fbace68a4fc562293 \
	mime=text/plain body=Hello success_report=yes
		
```


#### msrp_ua:start_session


替代已废弃的 MI 命令: *msrp_ua_start_session*。


启动一个 MSRP 会话。


如果使用此函数,则 [advertised contact](#param_advertised_contact) 是必需的。


名称: *msrp_ua:start_session*


参数


- *content_types* (string) - 在 *accept-types* SDP
属性中公布的内容类型。
- *from_uri* (string) - INVITE 中使用的
From URI。
- *to_uri* (string) - INVITE 中使用的
To URI。
- *ruri* (string) - INVITE 的 Request URI 和目标。


MI FIFO 命令格式:


```c
opensips-cli -x mi msrp_ua:start_session \
	text/plain sip:oss@opensips.org \
	sip:alice@opensips.org sip:alice@opensips.org
		
```


#### msrp_ua:list_sessions


替代已废弃的 MI 命令: *msrp_ua_list_sessions*。


列出正在进行的 MSRP 会话信息。


名称: *msrp_ua:list_sessions*


参数


- *无*。


MI FIFO 命令格式:


```c
opensips-cli -x mi msrp_ua:list_sessions
		
```


#### msrp_ua:end_session


替代已废弃的 MI 命令: *msrp_ua_end_session*。


终止正在进行的 MSRP 会话。


名称: *msrp_ua:end_session*


参数


- *session_id* (string) - MSRP 会话
标识符(MSRP URI 的 "session-id" 部分)。


MI FIFO 命令格式:


```c
opensips-cli -x mi msrp_ua:end_session \
	5addd9e7b74fa44fbace68a4fc562293
		
```


### 导出的事件


#### E_MSRP_SESSION_NEW


当成功建立新的 MSRP 会话(ACK 发送/接收)时触发此事件。


参数:


- *from_uri* - 已应答 INVITE 的 SIP From 头中的 URI。
- *to_uri* - 已应答 INVITE 的 SIP To 头中的 URI。
- *ruri* - 已应答 INVITE 的 SIP Request URI。
- *session_id* - MSRP 会话标识符
(MSRP URI 的 "session-id" 部分)。
- *content_types* - 对方在 *accept-types* SDP 属性中提供的内容类型。


#### E_MSRP_SESSION_END


当正在进行的 MSRP 会话终止时触发此事件(会话
过期或收到 BYE;不包括通过
*msrp_ua:end_session* MI 函数终止会话)。


参数:


- *session_id* - MSRP 会话标识符
(MSRP URI 的 "session-id" 部分)。


#### E_MSRP_MSG_RECEIVED


当从对方收到新的非空 MSRP SEND 请求时触发此事件。


参数:


- *session_id* - MSRP 会话标识符
(MSRP URI 的 "session-id" 部分)。
- *content_type* - 此消息的内容类型。
- *body* - 实际的消息体。


#### E_MSRP_REPORT_RECEIVED


在以下情况下触发此事件:


- 收到 MSRP REPORT 请求
- 收到失败的事务响应
- SEND 请求的本地超时发生。


参数:


- *session_id* - MSRP 会话标识符
(MSRP URI 的 "session-id" 部分)。
- *message_id* - Message-ID
头字段的值。
- *status* - Status 头字段的值。
- *byte_range* - Byte-Range 头
字段的值。


## 开发者指南


### 概述


要应答携带 MSRP 的 SIP 会话,应使用 [init uas](#dev_init_uas)
函数。相反,对于作为 UAC 发起 MSRP 呼叫,
可以使用 [init uac](#dev_init_uac) 函数。


使用上述任一函数初始化会话后,SIP 呼叫将
由模块进一步处理,有关重要 SIP 级别事件和收到的 MSRP 请求
及响应的通知将通过注册回调函数传递。


会话建立后,可以使用 [send message](#dev_send_message) 函数发送 MSRP SEND 请求,
这将通过带有 *MSRP_UA_SESS_ESTABLISHED* 事件的
*msrp_ua_notify_cb_f* 回调进行信号通知。


收到的 MSRP 请求、事务响应和本地发送超时将通过
*msrp_ua_req_cb_f* 和
*msrp_ua_rpl_cb_f* 回调进行信号通知。


### 可用函数


#### init_uas(msg, accept_types, hdl)


此函数将基于收到的 SIP INVITE 初始化 MSRP UA 会话。


参数含义如下:


- *struct sip_msg *msg* - SIP 消息
- *str *accept_types* - 要包含在 SDP offer 中的
"accept-types" 属性的值。
- *struct msrp_ua_handler *hdl* - 处理程序
结构,用于注册 SIP 级别和 MSRP
级别通知的回调。


```c title="struct msrp_ua_handler 结构"
struct msrp_ua_handler {
	/* 此注册的名称 */
	str *name;
	/* 要传递给 msrp_req_cb 和 msrp_rpl_cb 回调的参数 */
	void *param;
	/* SIP 级别通知的回调 */
	msrp_ua_notify_cb_f notify_cb;
	/* 接收 MSRP 请求的回调 */
	msrp_ua_req_cb_f msrp_req_cb;
	/* 接收 MSRP 响应的回调 */
	msrp_ua_rpl_cb_f msrp_rpl_cb;
};
```


```c title="msrp_ua_notify_cb_f 原型"
typedef int (*msrp_ua_notify_cb_f)(struct msrp_ua_notify_params *params,
	void *hdl_param);
```


```c title="struct msrp_ua_notify_params 结构"
struct msrp_ua_notify_params {
	/* 事件类型 */
	enum msrp_ua_event_type event;
	/* SIP 消息 */
	struct sip_msg *msg;
	/* MSRP_UA_SESS_ESTABLISHED 事件情况下的 SDP "accept-types" 属性 */
	str *accept_types;
	/* MSRP UA 会话 ID */
	str *session_id;
};
```


```c title="enum msrp_ua_event_type"
enum msrp_ua_event_type {
	/* 会话已建立(ACK 已发送/接收) */
	MSRP_UA_SESS_ESTABLISHED = 1,
	/* 会话建立失败(否定回复/超时等) */
	MSRP_UA_SESS_FAILED,
	/* 收到/发送 BYE(会话超时情况) */
	MSRP_UA_SESS_TERMINATED
};
```


```c title="msrp_ua_req_cb_f 原型"
typedef int (*msrp_ua_req_cb_f)(struct msrp_msg *req, void *hdl_param);
```


```c title="msrp_ua_rpl_cb_f 原型"
/* MSRP 事务超时将通过使用 NULL rpl 参数调用此回调进行信号通知 */
typedef int (*msrp_ua_rpl_cb_f)(struct msrp_msg *rpl, void *hdl_param);
```


#### init_uac(accept_types, from_uri, to_uri, ruri, hdl)


此函数通过向目标发送 SIP INVITE 来初始化 MSRP UA 会话。


参数含义如下:


- *str *accept_types* - 要包含在 SDP offer 中的
"accept-types" 属性的值。
- *str *from_uri* - INVITE 中 From
头使用的 URI。
- *str *to_uri* - INVITE 中 To
头使用的 URI。
- *str *ruri* - INVITE 使用的
Request URI。
- *struct msrp_ua_handler *hdl* - 处理程序
结构,用于注册 SIP 级别和 MSRP
级别通知的回调。


#### end_session(session_id)


此函数终止 MSRP 会话。


参数含义如下:


- *str *session_id* - MSRP UA 会话 ID。


#### send_message(session_id, mime, body, failure_report, success_report)


此函数向对方发送 MSRP SEND 请求。


参数含义如下:


- *str *session_id* - MSRP UA 会话 ID。
- *str *mime* - 此消息的 MIME 内容
类型。如果为 NULL,将发送空消息。
- *str *body* - 实际的消息
体。如果为 NULL,将发送空消息。
- *enum msrp_failure_report_type failure_report* -
MSRP Failure Report 类型 - yes、no 或 partial。
- *int success_report* - 指示是否
请求 MSRP Failure Report。


```c title="enum msrp_failure_report_type"
enum msrp_failure_report_type {
	MSRP_FAILURE_REPORT_YES,
	MSRP_FAILURE_REPORT_PARTIAL,
	MSRP_FAILURE_REPORT_NO
};
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)均采用知识共享许可证 4.0 版授权
