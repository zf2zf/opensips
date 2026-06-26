---
title: "Diversion 模块"
description: "该模块实现了 draft-levy-sip-diversion-08 中规定的 Diversion 扩展。Diversion 扩展在各种呼叫转发场景中很有用。通常需要将呼叫的原始收件人传达给 PSTN 网关，这就是 diversion 扩展的用途。"
---

## 管理指南


### 概述


该模块实现了 draft-levy-sip-diversion-08 中规定的 Diversion 扩展。
Diversion 扩展在各种呼叫转发场景中很有用。通常需要将呼叫的原始收件人传达给 PSTN 网关，这就是 diversion 扩展的用途。


> [!WARNING]
> draft-levy-sip-diversion-08 已过期！请参阅
		[IETF I-D tracker](https://datatracker.ietf.org/public/idindex.cgi?command=id_detail&and;id=6002)。


### 依赖


#### OpenSIPS 模块


无。


#### 外部库或应用程序


以下库或应用程序必须在运行加载了此模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### suffix (string)


要附加到头部字段末尾的后缀。您可以使用该参数指定要添加到头部字段的额外参数，请参见示例。


默认值为 ""（空字符串）。


```c title="suffix 使用"
modparam("diversion", "suffix", ";privacy=full")
```


### 导出的函数


#### add_diversion(reason, [uri], [counter])


该函数在消息中任何现有的 Diversion 头部字段之前添加一个新的 diversion 头部字段（新添加的 Diversion 头部字段将成为最上面的 Diversion 头部字段）。
入站（未经代理服务器修改的）Request-URI 将被用作 Diversion URI。


参数的含义如下：


- *reason* (string) - 要添加为 reason 参数的原因字符串
- *uri* (string, optional) - 要添加到头部的 URI。如果缺失，将使用原始消息中未修改的 RURI。
- *counter* (int, optional) - 要添加到头部的 Diversion 计数器，如标准所定义。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE。


```c title="add_diversion 使用"
...
add_diversion("user-busy");
...
```


### Diversion 示例


以下示例显示添加到 INVITE 消息的 Diversion 头部字段。用户代理
收到的原始 INVITE sip:bob@sip.org 是：


```c
INVITE sip:bob@sip.org SIP/2.0
Via: SIP/2.0/UDP 1.2.3.4:5060
From: "mark" <sip:mark@sip.org>;tag=ldgheoihege
To: "Bob" <sip:bob@sip.org>
Call-ID: adgasdkgjhkjha@1.2.3.4
CSeq: 3 INVITE
Contact: <sip:mark@1.2.3.4>
Content-Length: 0
```


INVITE 消息被 sip:bob@sip.org 的用户代理转发，因为用户正在与他人通话，
新目标是 sip:alice@sip.org：


```c
INVITE sip:alice@sip.org SIP/2.0
Via: SIP/2.0/UDP 5.6.7.8:5060
Via: SIP/2.0/UDP 1.2.3.4:5060
From: "mark" <sip:mark@sip.org>;tag=ldgheoihege
To: "Bob" <sip:bob@sip.org>
Call-ID: adgasdkgjhkjha@1.2.3.4
CSeq: 3 INVITE
Diversion: <sip:bob@sip.org>;reason=user-busy
Contact: <sip:mark@1.2.3.4>
Content-Length: 0
```


## 开发者指南


根据规范，新的 Diversion 头部字段应作为消息中最上面的 Diversion 头部字段插入，这意味着在任何其他现有的 Diversion 头部字段之前。此外，`add_diversion` 函数可以多次调用，每次都应将新的 Diversion 头部字段插入为最上面的。


为了实现这一点，add_diversion 函数在 data_lump 列表中创建锚点作为静态变量，以确保函数的下次调用将使用相同的锚点，并将新的 Diversion 头部插入到上次执行创建的头部之前。据我所知，这是将 diversion 头部字段插入到之前创建的任何其他头部之前的唯一方法。


以这种方式保持的锚点仅对单个消息有效，当处理另一条消息时我们必须使其失效。为此，函数还在另一个静态变量中存储消息的 ID，并将该变量的值与正在处理的 SIP 消息的 ID 进行比较。如果不同，则锚点将失效，函数将创建一个新的。


以下代码片段显示了使锚点失效的代码，当 `anchor` 变量设置为 0 时将创建新锚点。


```c
static inline int add_diversion_helper(struct sip_msg* msg, str* s)
{
    static struct lump* anchor = 0;
    static int msg_id = 0;

    if (msg_id != msg->id) {
        msg_id = msg->id;
        anchor = 0;
    }
...
}
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0 版授权
