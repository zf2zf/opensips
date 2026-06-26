---
title: "SST 模块 (SIP 会话计时器)"
description: "sst 模块提供了一种根据 SIP INVITE/200 OK Session-Expires 头值更新对话过期计时器的方法。您可以在 OpenSIPS 代理中使用 sst 模块来释放已死亡（过期）呼叫的本地资源。"
---

## 管理指南


### 概述


sst 模块提供了一种根据 SIP INVITE/200 OK
		Session-Expires 头值更新对话过期计时器的方法。您可以在
		OpenSIPS 代理中使用 sst 模块来释放已死亡（过期）呼叫的本地资源。


您还可以使用 sst 模块验证 MIN_SE 头值，
		如果值对于您的 OpenSIPS 配置太小，则以 "422 - Session Timer Too Small"
		回复任何请求。


### 工作原理


sst 模块使用 dialog 模块来接收任何新对话或更新对话的通知。
		然后它将查找并提取 session-expire: 头值（如果存在），
		并覆盖当前上下文对话的对话过期计时器值。


您可以标记任何您希望建立定时会话的呼叫设置 INVITE。
		这将导致 OpenSIPS 请求使用会话时间（如果 UAC 未请求）。


所有这些都通过正确配置的 dialog 和 sst 模块发生，
		并在看到任何 INVITE sip 消息时设置 dialog 标志和 sst 标志。
		无需调用 opensips.cfg 脚本函数来设置对话过期超时值。
		有关更多信息，请参阅 dialog 模块用户指南。


sstCheckMin() 脚本函数可用于验证 Session-expires / MIN-SE
		头字段值对于代理来说是否不太小。如果 SST min_se 参数值小于
		消息的 Session-Expires / MIN-SE 值，则测试将返回 true。
		您还可以将函数配置为为您发送 422 响应。


以下是从 RFC 中获取的呼叫流程示例：


```c title="会话计时器呼叫流程"
+-------+    +-------+       +-------+
| UAC-1 |    | PROXY |       | UAC-2 |
+-------+    +-------+       +-------+
    |(1) INVITE  |               |
    |SE: 50      |               |
    |----------->|               |
    |            |(2)sstCheckMin |
    |            |-----+         |
    |            |     |         |
    |            |<----+         |
    |(3) 422     |               |
    |MSE:1800    |               |
    |<-----------|               |
    |            |               |
    |(4)ACK      |               |
    |----------->|               |
    |            |               |
    |(5) INVITE  |               |
    |SE: 1800    |               |
    |MSE: 1800   |               |
    |----------->|               |
    |            |(6)sstCheckMin |
    |            |-----+         |
    |            |     |         |
    |            |<----+         |
    |            |(7)setflag     |
    |            |create dialog  |
    |            |Set expire     |
    |            |-----+         |
    |            |     |         |
    |            |<----+         |
    |            |               |
    |            |(8)INVITE      |
    |            |SE: 1800       |
    |            |MSE: 1800      |
    |            |-------------->|
    |            |               |
 ...

```


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *dialog* - dialog 模块及其依赖项。(tm)
- *sl* - 无状态模块。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### enable_stats (integer)


是否应启用统计支持。通过统计变量，
		该模块提供有关对话处理的信息。将其设置为零以禁用，
		或设置为非零以启用。


*默认值为 "1"（启用）。*


```c title="设置 enable_stats 参数"
...
modparam("sst", "enable_stats", 0)
...
```


#### min_se (integer)


该值用于设置代理的 MIN-SE 值，
		如果 sstCheckMin() 标志设置为 true 且检查失败，
		则在 422 回复中用作代理的 MIN-SE: 头值。


如果未设置且使用 send-reply 标志调用 sstCheckMin()，
		则默认 1800 秒将用作比较值，
		如果发送 422 回复，也将用作 MIN-SE: 头值。


*默认值为 "1800" 秒。*


```c title="设置 min_se 参数"
...
modparam("sst", "min_se", 2400)
...
```


#### sst_interval (integer)


如果 OpenSIPS 请求使用会话时间，
		则这是 Session-Expires 头中的最小间隔。
		使用的值将是 OpenSIPS minSE、UAS minSE 和此值之间的最大值。


默认情况下，使用的间隔将是 min_se 值


*默认值为 "0" 秒。*


```c title="设置 sst_interval 参数"
...
modparam("sst", "sst_interval", 2400)
...
```


#### reject_to_small (integer)


在初始 INVITE 中，如果 UAC 请求了 Session-Expire:
		且其值小于我们本地策略的 Min-SE（见上面的 min_se），
		则代理有权通过回复消息 "422 Session Timer Too Small"
		并说明我们的本地 Min-SE: 值来拒绝呼叫。
		INVITE 不会通过代理转发。


如果此标志为 true，则告诉 SST 模块
		使用 422 响应拒绝 INVITE。如果为 false，
		则 INVITE 通过代理转发，不做任何修改。


*默认值为 "1"（true/on）。*


```c title="设置 reject_to_small 参数"
...
modparam("sst", "reject_to_small", 0)
...
```


#### sst_flag (string)


与 OpenSIPS 保持一致，该模块不会对任何消息执行任何操作，
		除非通过 opensips.cfg 脚本指示。
		您必须在要处理的 INVITE 的 setflag() 调用中设置 sst_flag 值。
		但在此之前，您需要告诉 sst 模块您分配给 sst 的标志值是多少。


在大多数情况下，每当您通过 create_dialog() 函数创建新对话时，
		您会想要设置 sst 标志。如果未调用 create_dialog() 
		且设置了 sst 标志，则不会有任何效果。


必须设置此参数，否则模块将不会加载。


*默认值为 "未设置！"*


```c title="设置 sst_flag 参数"
...
modparam("sst", "sst_flag", "SST_FLAG")
...
route {
  ...
  if ($rm=="INVITE") {
    setflag(SST_FLAG); # 设置 sst 标志
    create_dialog(); # 然后创建对话
  }
  ...
}
```


### 导出的函数


#### sstCheckMin(send_reply_flag)


根据 sst_min_se 参数值检查当前的 Session-Expires / MIN-SE 值。
		如果 Session-Expires 或 MIN_SE 头值小于模块的最小值，
		此函数将返回 true。


如果使用 send_reply_flag 设置为 true (1) 调用该函数，
		且请求的 Session-Expires / MIN-SE 值太小，
		则将为您发送 422 回复。422 将携带一个 MIN-SE: 头，
		其中包含设置的 sst min_se 参数值。


参数的含义如下：


- *min_allowed* (int, 可选) - 用于与 MIN_SE 头值比较的值。


```c title="sstCheckMin 使用示例"
...
modparam("sst", "sst_flag", "SST_FLAG")
modparam("sst", "min_se", 2400) # 必须 >= 90
...

route {
  if ($rm=="INVITE") {
	if (sstCheckMin(1)) {
		xlog("L_ERR", "422 Session Timer Too Small 回复已发送。\n");
		exit;
	}
	# 通过 dialog 模块跟踪会话计时器
	setflag(SST_FLAG);
	create_dialog();
  }
}

...
```


### 导出的统计


#### expired_sst


获得过期会话计时器的对话数量。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
