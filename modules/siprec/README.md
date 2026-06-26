---
title: "SIPREC 模块"
description: "该模块提供了使用外部录音设备进行通话录音的手段——录音实体不在通话双方之间的媒体路径中，而是完全独立的，因此不会以任何方式影响通话质量。这是以一种标准化的方式完成的，使用 SIPREC 协议。"
---

## 管理指南


### 概述


该模块提供了使用外部录音设备进行通话录音的手段。
录音实体不在通话双方之间的媒体路径中，而是完全独立的，
因此不会以任何方式影响通话质量。
这是以一种标准化的方式完成的，使用
[ SIPREC 协议](https://tools.ietf.org/html/rfc7866)，
因此可以被任何实现此协议的录音设备使用。


由于使用外部服务器进行通话录音，因此录音设备的位置没有限制，
可以任意放置。这为您的架构配置和各种扩展方式提供了极大的灵活性。


该模块的工作由 [OrecX 公司](http://www.orecx.com/) 赞助。
该模块与 OrecX 通话录音产品完全集成。


### 工作原理


SIP 媒体录制平台的完整架构记录在 [RFC 7245](https://tools.ietf.org/html/rfc7245) 中。
根据此架构，该 OpenSIPS 模块实现了一个 SRC（会话录制客户端），
用于指示 SRS（会话录制服务器）何时开始新通话、
参与者及其配置文件。根据这些数据，SRS 可以决定是否应录制通话。


从 SIP 信令的角度来看，该模块不会改变通话双方之间的通话流程。
通话的建立与任何其他未录制的通话完全相同。
但是对于每个启用了 *SIPREC* 的通话，
SRC（OpenSIPS）会向 SRS 发起一个完全独立的 SIP 会话，
使用 [OpenSIPS Back-2-Back 模块](../b2b_entities)。
发送到 SRS 的 *INVITE* 消息包含一个由两部分组成的多部分内容：


- *录制 SDP* - 媒体服务器的 SDP，
			它将把 RTP 分叉到录音设备。
- *参与者元数据* - 一个 XML 格式的文档，
			包含有关参与者的信息。文档结构详见 [RFC 7865](https://tools.ietf.org/html/rfc7865)。


SRS 可以回复负面回复，表示不需要录制会话，
或回复正面回复（200 OK），在 SDP 正文中指示媒体 RTP 应被发送/分叉到哪里。
当通话结束时，SRC 必须向 SRS 发送 *BYE* 消息，
表示录音应完成。


完整的通话流程示例可在 [RFC 8068](https://tools.ietf.org/html/rfc8068) 中找到。


### 媒体处理


由于 OpenSIPS 是一个 SIP 代理，它本身没有任何媒体能力。
因此我们需要依赖不同的媒体服务器来捕获 RTP 流量并将其分叉到 SRS。
当前实现支持 [RTPProxy](http://www.rtpproxy.org/)
（通过 [RTPProxy 模块](../rtpproxy)）和
[RTPEngine](https://github.com/sipwise/rtpengine)
（通过 [RTEngine 模块](../rtpengine)）媒体服务器。


### SRS 故障转移


*siprec* 模块支持多个 SRS 服务器之间的故障转移——
当调用 *[siprec start recording](#func_siprec_start_recording)* 函数时，
可以配置多个 SRS URI，用逗号分隔。
在这种情况下，OpenSIPS 将按指定的顺序尝试使用它们，一个接一个，
直到其中一个以正面回复（200 OK）响应，
或者响应代码是由 *[skip failover codes](#param_skip_failover_codes)* 正则表达式匹配代码之一。
在后一种情况下，通话根本不会被录制。


### 限制


该模块仅实现了 [SIPREC RFC](https://tools.ietf.org/html/rfc7866) 的 SRC 规范。
为了获得完整的录音解决方案，您还需要一个 SRS 解决方案，
如 [Oreka](http://oreka.sourceforge.net/) —— 一个由 [OrecX](http://www.orecx.com/) 提供的开源项目。


虽然该模块提供了进行通话录音的所有必要工具，
但它并未完全实现整个 *SIPREC* SRC 规范。
此列表包含该模块的一些限制：


- *不会向被叫方播放录制指示器* -
				由于 OpenSIPS 继续充当代理，
			我们无法在通话双方之间插入媒体来播放录制指示器消息。
- *无法处理由 SRS 发起的录制会话* -
				我们不支持 SRS 突然决定在对话中间录制通话的场景。
- *OpenSIPS 不能被"查询"正在进行的
				录制会话* - 这计划在后续版本中实现。


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *TM* - 事务模块。
- *Dialog* - 用于跟踪通话的对话框模块。
- *RTP_Relay* - 用于控制将分叉媒体的
				媒体服务器的 RTP 中继模块。
- *B2B_ENTITIES* - 用于与 SRS 通信的 Back-2-Back 模块。


#### 外部库或应用程序


运行 OpenSIPS 并加载此模块之前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### skip_failover_codes (string)


一个正则表达式，用于指定应防止模块故障转移到新 SRS 服务器的代码。


*默认情况下，任何负面回复都会生成故障转移。*


```c title="设置 skip_failover_codes 参数"
...
# 不要在 408 回复代码上故障转移
modparam("siprec", "skip_failover_codes", "408")

# 不要在 408 或 487 回复代码上故障转移
modparam("siprec", "skip_failover_codes", "408|487")

# 不要在任何 3xx 或 4xx 回复代码上故障转移
modparam("siprec", "skip_failover_codes", "[34][0-9][0-9]")
...

```


### 导出的事件


#### E_SIPREC_START


当 SIPREC 通话建立并开始录制时触发此事件。


参数：


- *dlg_id* - 正在录制的通话的对话框 ID ("did")
- *dlg_callid* - 正在录制的通话的 Call-Id
- *callid* - SIPREC 通话的 Call-Id (B2B id)
- *session_id* - 录制通话的 SIPREC UUID
- *server* - 处理此通话的 SIPREC 服务器
- *instance* - 触发此事件的 SIPREC 实例


#### E_SIPREC_STOP


当 SIPREC 通话终止时触发此事件。


此事件公开与 [E SIPREC START](#event_e_siprec_start) 事件相同的参数。


### 导出的函数


#### siprec_start_recording(srs[, instance])


在初始 *INVITE* 上调用此函数会为该通话启用到 SRS 的通话录制。
请注意，这不一定意味着通话会被录制——这只是意味着 OpenSIPS 会查询
指示 SRS 有新通话已开始，但 SRS 可能决定对这些参与者禁用了录制。


*请注意，通话录制不会立即开始，
				而是要等到被叫方也提供 SDP 时（通常是 200 OK，或可能是 183 Ringing）。


*请注意，如果您只想在通话建立后开始录制（收到 200 OK），
				您应该在处理 200 OK 的 onreply 路由中调用此函数。


参数：


- *srs* (string) - 以逗号分隔的 SRS URI 列表。
				这些 URI 按指定顺序使用。
				详见 [siprec srs failover](#srs_failover)。
- *instance* (string, 可选) - 用于启动特定 SIPREC *实例*。
				如果缺失，将启动 *默认* 实例。


当触发内部错误且通话录制设置失败时，函数返回 false。
否则，如果所有内部机制都被激活，它返回 true。


此函数可用于 REQUEST_ROUTE。


```c title="使用单个 SRS 的 siprec_start_recording() 函数"
	...
	if (!has_totag() && is_method("INVITE")) {
		$var(srs) = "sip:127.0.0.1";
		xlog("为 $ci 启用到 $var(srs) 的 SIPREC 通话录制\n");
		siprec_start_recording($var(srs));
	}
	...

```


```c title="使用多个 SRS 服务器的 siprec_start_recording() 函数"
	...
	if (!has_totag() && is_method("INVITE")) {
		$var(srs) = "sip:127.0.0.1, sip:127.0.0.1;transport=TCP";
		xlog("为 $ci 在入站组中启用到服务器 $var(srs) 的 SIPREC 通话录制\n");
		siprec_start_recording($var(srs), "inbound");
	}
	...

```


```c title="使用自定义 XML 值参与者的 siprec_start_recording() 函数"
	...
	$xml(caller_xml) = "<nameID></nameID>";
	$xml(caller_xml/nameID.attr/aor) = "sip:6024151234@10.0.0.11:5090";
	$xml(caller_xml/nameID) = "<name>test</name>";
	$siprec(caller) = $xml(caller_xml/nameID);
	siprec_start_recording($var(srs));
	...

```


```c title="使用自定义头部的 siprec_start_recording() 函数"
	...
	$siprec(headers) = "X-MY-CUSTOM_HDR: 1\r\n";
	siprec_start_recording($var(srs));
	...

```


```c title="使用自定义组和会话扩展的 siprec_start_recording() 函数"
	...
	$var(temp) = "
```


#### siprec_pause_recording([instance])


暂停正在进行的通话的录制。应在对话框匹配后调用。


参数：


- *instance* (string, 可选) - 用于暂停特定 SIPREC *实例*。
				如果缺失，将暂停 *默认* 实例。


此函数可用于任何路由。


```c title="使用 siprec_pause_recording()"
	...
	if (has_totag() && is_method("INVITE")) {
		if (is_audio_on_hold())
			siprec_pause_recording();
	}
	...

```


#### siprec_resume_recording([instance])


恢复正在进行的通话的录制。应在对话框匹配后调用。


参数：


- *instance* (string, 可选) - 用于恢复特定 SIPREC *实例*。
				如果缺失，将恢复 *默认* 实例。


此函数可用于任何路由。


```c title="使用 siprec_resume_recording()"
	...
	if (has_totag() && is_method("INVITE")) {
		if (!is_audio_on_hold())
			siprec_resume_recording();
	}
	...

```


#### siprec_stop_recording([instance])


停止正在进行的通话的录制。应为由之前启动的 SIPREC 会话调用。


参数：


- *instance* (string, 可选) - 用于停止特定 SIPREC *实例*。
				如果缺失，将停止 *默认* 实例。


此函数可用于任何路由。


```c title="使用 siprec_stop_recording()"
	...
	if (has_totag() && is_method("INVITE")) {
		if (is_audio_on_hold())
			siprec_stop_recording();
	}
	...

```


#### siprec_send_indialog([hdrs[, body]])


向 SRS 发送一个任意的会话内请求。


此函数可用于任何路由。


参数：


- *headers* (string, 可选) - 将添加到生成请求的头部集合。
- *body* (string, 可选) - 将添加到生成请求的内容。
- *instance* (string, 可选) - 用于在特定 SIPREC *实例*内发送请求。
				如果缺失，请求将在 *默认* 实例中发送。


```c title="使用 siprec_send_indialog()"
	...
	if (has_totag() && is_method("INFO")) {
		siprec_send_indialog("Content-Type: $hdr(Content-Type)\r\n", $rb);
	}
	...

```


### 导出的伪变量


#### $siprec


用于修改/描述应被
				[siprec start recording](#func_siprec_start_recording) 函数考虑的
				不同 siprec 会话参数。


该变量可以用 *instance* 索引，
				用户要调整的变量。如果缺失，
				*默认* 实例将被更改。


此变量的上下文仅限于当前处理的消息——它在事务或对话框级别不可用。


所有这些设置都是可选的。


可以配置以下设置：


- *group* - 一个不透明值，将插入到 SIPREC 正文中，
					表示可用于将通话分类到特定配置文件的组名称。如果缺失，不添加任何组。
- *caller* - 包含有关主叫方信息的 XML 块。
					如果缺失，初始对话框的 *From* 头部用于构建该值。
- *callee* - 包含有关被叫方信息的 XML 块。
					如果缺失，初始对话框的 *To* 头部用于构建该值。
- *media* - RTPProxy 将从中流式传输媒体的 IP。
					如果缺失，将使用 *127.0.0.1*。
					*注意：**media_ip* 已被删除。
- *headers* - 要添加到到 SRS 初始请求中的额外头部。
					*注意：*头部必须用 *\r\n* 分隔，
					必须以 *\r\n* 结尾。
- *socket* - 传出请求应使用的监听套接字
					到 SRS。
- *from_uri* - 对话框的 *From* 头部中显示的 URI。
					默认值为请求 URI。请注意，这不影响 XML 块中的
					*caller* 信息，它取自初始对话框。
- *to_uri* - 对话框的 *To* 头部中显示的 URI。
					默认值为请求 URI。请注意，这不影响 XML 块中的
					*callee* 信息，它取自初始对话框。
- *group_custom_extension* - 可选的 XML 块，
					包含要添加到 *group* 标签下的自定义信息。
					*注意：*如果 *group* 不存在，此值将被忽略且不会在任何地方使用。
- *session_custom_extension* - 可选的 XML 块，
					包含要添加到 *session* 标签下的自定义信息。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可证 4.0 版授权
