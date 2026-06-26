---
title: "RTP 中继模块"
description: "此模块的目的是简化在 OpenSIPS 脚本中使用不同 RTP 中继服务器（如 RTPProxy、RTPEngine、Media Proxy）的操作，并提供依赖于 RTP 中继使用的各种复杂功能（如媒体重新锚定）。"
---

## 管理指南


### 概述


此模块的目的是简化在 OpenSIPS 脚本中使用不同
		RTP 中继服务器（如 RTPProxy、RTPEngine、Media Proxy）
		的操作，并提供依赖于 RTP 中继使用的各种复杂
		功能（如媒体重新锚定）。


该模块提供了在初始 INVITE 期间参与特定 RTP 中继的逻辑，
		然后它将处理与 RTP 中继的整个通信，直到呼叫终止。


此外，可以指定各种标志来修改 RTP 引擎使用每个用户代理 SDP 的方式
		- 这些标志在整个 RTP 会话期间保持有效，
		并用于后续的同-dialog 请求。这些标志可以通过
		[rtp relay](#pv_rtp_relay) 和/或
		[rtp relay peer](#pv_rtp_relay_peer) 变量在初始 INVITE 时指定，
		或通过绝对的
		[rtp relay caller](#pv_rtp_relay_caller) 和
		[rtp relay callee](#pv_rtp_relay_callee) 变量指定，
		然后随 RTP 中继上下文一起传递直到呼叫结束。
		它们也可以在同-dialog 顺序请求期间修改。


这不是一个直接与 RTP 中继通信的独立模块，
		而是一个通用接口，能够与和每个特定 RTP 中继
		（如 *rtpproxy* 或 *rtpengine*）交互的模块进行交互，
		并实现它们特定的通信协议。


### 多分支


该模块能够处理多分支的 RTP 中继，具有不同的标志风格。
		每个分支可以通过 [rtp relay](#pv_rtp_relay) 变量调整其标志
		- 如果在主路由中配置了变量，则标志将被所有后续分支继承，
		除非特定修改每个分支。
		要修改特定分支，需要指定所需的分支索引作为变量索引
		（即 *$(rtp_relay[1]) = "cor"*）。
		如果在分支路由中配置，标志仅针对该特定分支更改。


从 OpenSIPS 3.3 开始，分支可以基于其参与者的 to_tag 进行识别。
		当在 B2B 模式下使用 *rtp_relay* 时，此功能变得方便，
		因为对等方不能再简单地通过索引进行识别。
		但是，此功能也可用于对话场景。


多分支行为由后端引擎根据其能力以不同方式处理。
		例如，*rtpengine* 能够本机支持多分支呼叫，
		而对于 *rtpproxy*，每个分支在不同的会话中以不同的 call-id 进行模拟。


当呼叫被应答且只剩一个活动分支时，
		所有其他分支都被销毁，只有建立的分支在呼叫期间保持活动状态。


### RTP 中继引擎


该模块本身不执行任何 SDP 处理，它只是不同后端的启用器，
		如 RTPProxy 或 RTPEngine。这些后端称为 RTP 中继引擎，
		在参与 RTP 中继时需要指定。


从 OpenSIPS 3.6 开始，该模块增加了内部 RTP 引擎，
		可用于通过在发生 RTP 事件（如 offer、answer、delete）时运行一组路由来执行
		*手动/自定义* SDP 处理。
		可以通过使用 *route* 引擎参与 RTP 中继来启用此功能。
		如果未定义定义的路由，则 SDP 不会更改。
		有关更多信息，请参阅
		[route offer](#param_route_offer)、
		[route answer](#param_route_answer) 和
		[route delete](#param_route_delete) 参数。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *Dialog 模块* - 用于跟踪同-dialog 请求。
- *RTP 中继模块* - 如 *rtpproxy*、*rtpengine*，
				或任何实现 *rtp_relay* 接口的模块。


#### 外部库或应用程序


以下库或应用程序必须在运行加载了此模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### route_offer (string)


当发生 SDP offer 时运行的路由（即。
			正在处理带有 SDP 的 INVITE 时）。


当路由执行时，以下参数被填充：


- *callid* - 正在处理的呼叫的 callid。
- *from_tag* - 正在处理的呼叫的 from_tag。
- *to_tag* - 正在处理的呼叫的 to_tag（如果存在）。
- *branch* - RTP 中继参与的分支
				- 如果在主分支参与，则使用 *-1*。
- *body* - 可选，如果使用显式正文，
				否则应考虑消息的正文。
- *set* - 用于呼叫的 rtp 中继集。
- *node* - 可选，节点引擎标识符 - 这是
				在运行 *route_offer* 路由后返回的用户填充值（请参阅下面的返回值部分）。
- *ip* - 可选，在当前对等方的
				[rtp relay](#pv_rtp_relay) 变量中指定的 IP。
- *type* - 可选，在当前对等方的
				[rtp relay](#pv_rtp_relay) 变量中指定的 RTP 类型。
- *in-iface* - 可选，应该用于此对等方的入站接口。
- *out-iface* - 可选，应该用于此对等方的出站接口。
- *ctx-flags* - 可选，在 [rtp relay ctx](#pv_rtp_relay_ctx) 变量中指定的全局标志。
- *flags* - 可选，为此对等方指定的标志。
- *peer* - 可选，为相应对等方指定的对等标志；


运行路由时期望返回以下值：
			
			
			*body* - 要提供的新创建的正文。如果
				未返回，则正文保持不变。
			
			
			*node* - 可选，要为进一步识别的节点
				路由/执行的命令。
		*默认值为 "rtp_relay_offer"。*


```c title="设置 route_offer 参数"
...
modparam("rtp_relay", "route_offer", "custom_rtp_offer")
...
```


```c title="route_offer 路由用法"
...
route[rtp_relay_offer] {
	# 手动参与 RTPEngine，获取 SDP，并将其替换到消息中
	返回 (1, $var(body));
}
...
```


#### route_answer (string)


当发生 SDP answer 时运行的路由（即。
			正在处理带有 SDP 的 183 或 200 OK 回复时）。


当路由执行时，以下参数被填充：


- *callid* - 正在处理的呼叫的 callid。
- *from_tag* - 正在处理的呼叫的 from_tag。
- *to_tag* - 正在处理的呼叫的 to_tag（如果存在）。
- *branch* - RTP 中继参与的分支
				- 如果在主分支参与，则使用 *-1*。
- *body* - 可选，如果使用显式正文，
				否则应考虑消息的正文。
- *set* - 用于呼叫的 rtp 中继集。
- *node* - 可选，节点引擎标识符 - 这是
				在运行 *route_offer* 路由后返回的用户填充值。
- *ip* - 可选，在当前对等方的
				[rtp relay](#pv_rtp_relay) 变量中指定的 IP。
- *type* - 可选，在当前对等方的
				[rtp relay](#pv_rtp_relay) 变量中指定的 RTP 类型。
- *in-iface* - 可选，应该用于此对等方的入站接口。
- *out-iface* - 可选，应该用于此对等方的出站接口。
- *ctx->flags* - 可选，在 [rtp relay ctx](#pv_rtp_relay_ctx) 变量中指定的全局标志。
- *flags* - 可选，为此对等方指定的标志。
- *peer* - 可选，为相应对等方指定的对等标志；


运行路由时期望返回以下值：
			
			
			*body* - 要应答的新创建的正文。如果
				未返回，则正文保持不变。
		*默认值为 "rtp_relay_answer"。*


```c title="设置 route_answer 参数"
...
modparam("rtp_relay", "route_answer", "custom_rtp_answer")
...
```


```c title="route_answer 路由用法"
...
route[rtp_relay_answer] {
	# 再次手动参与 RTPEngine
	rtpengine_answer(,, $var(body), $rb);
	返回 (1, $var(body));
}
...
```


#### route_delete (string)


当媒体应断开连接时运行的路由（即。
			收到 CANCEL 或 BYE 时）。


当路由执行时，以下参数被填充：


- *callid* - 正在处理的呼叫的 callid。
- *from_tag* - 正在处理的呼叫的 from_tag。
- *to_tag* - 正在处理的呼叫的 to_tag（如果存在）。
- *branch* - RTP 中继参与的分支
				- 如果在主分支参与，则使用 *-1*。
- *body* - 可选，如果使用显式正文，
				否则应考虑消息的正文。
- *set* - 用于呼叫的 rtp 中继集。
- *node* - 可选，节点引擎标识符 - 这是
				在运行 *route_offer* 路由后返回的用户填充值（请参阅下面的返回值部分）。
- *ctx->flags* - 可选，在 [rtp relay ctx](#pv_rtp_relay_ctx) 变量中指定的全局标志。
- *delete* - 可选，在 [rtp relay ctx](#pv_rtp_relay_ctx) 变量中指定的删除标志。


不需要返回值。
		*默认值为 "rtp_relay_delete"。*


```c title="设置 route_delete 参数"
...
modparam("rtp_relay", "route_delete", "custom_rtp_delete")
...
```


```c title="rtp_relay_delete 路由用法"
...
route[rtp_relay_delete] {
	# 手动移除 RTPEngine 会话
	rtpengine_delete();
}
...
```


#### route_copy_offer (string)


当新呼叫的 SDP 被复制时执行的路由。


当路由执行时，以下参数被填充：


- *callid* - 正在处理的呼叫的 callid。
- *from_tag* - 正在处理的呼叫的 from_tag。
- *to_tag* - 正在处理的呼叫的 to_tag（如果存在）。
- *branch* - RTP 中继参与的分支
				- 如果在主分支参与，则使用 *-1*。
- *set* - 用于呼叫的 rtp 中继集。
- *node* - 可选，节点引擎标识符 - 这是
				在运行 *route_offer* 路由后返回的用户填充值（请参阅下面的返回值部分）。
- *flags* - 可选，由正在复制 SDP 的模块指定的标志。
- *copy-ctx* - 可选，复制上下文标识符 -
				这是用户填充值，在运行
				*route_copy_offer* 路由后返回（请参阅下面的返回值部分）。


运行路由时期望返回以下值：
			
			
			*copy-ctx* - 可选，复制上下文标识符，
				以后可用于识别当前复制会话。
		*默认值为 "rtp_relay_copy_offer"。*


```c title="设置 rtp_relay_copy_offer 参数"
...
modparam("rtp_relay", "route_copy_offer", "custom_rtp_copy_offer")
...
```


```c title="设置 rtp_relay_copy_offer 用法"
...
route[rtp_relay_copy_offer] {
	# 指示媒体引擎分叉媒体并分配一个标识符
	# 应存储在 $var(handle) 变量中
	返回 (1, $var(handle));
}
...
```


#### route_copy_answer (string)


当收到复制的流的 SDP 时运行的路由。
			（即收到 CANCEL 或 BYE 时）。


当路由执行时，以下参数被填充：


- *callid* - 正在处理的呼叫的 callid。
- *from_tag* - 正在处理的呼叫的 from_tag。
- *to_tag* - 正在处理的呼叫的 to_tag（如果存在）。
- *branch* - RTP 中继参与的分支
				- 如果在主分支参与，则使用 *-1*。
- *body* - 可选，如果使用显式正文，
				否则应考虑消息的正文。
- *set* - 用于呼叫的 rtp 中继集。
- *node* - 可选，节点引擎标识符 - 这是
				在运行 *route_offer* 路由后返回的用户填充值（请参阅下面的返回值部分）。
- *flags* - 可选，由正在复制 SDP 的模块指定的标志。
- *copy-ctx* - 可选，复制上下文标识符 -
				这是用户填充值，在
				*route_copy_offer* 执行结束时返回。


*默认值为 "rtp_relay_copy_answer"。*


```c title="设置 rtp_relay_copy_answer 参数"
...
modparam("rtp_relay", "route_copy_answer", "custom_rtp_copy_answer")
...
```


```c title="设置 rtp_relay_copy_answer 用法"
...
route[rtp_relay_copy_answer] {
	# 将收到的 $param(body) 提供给正在分叉呼叫的媒体引擎
	# 复制实例由 $param(copy-ctx) 变量标识
}
...
```


#### route_copy_delete (string)


当应移除媒体分叉时运行的路由。


当路由执行时，以下参数被填充：


- *callid* - 正在处理的呼叫的 callid。
- *from_tag* - 正在处理的呼叫的 from_tag。
- *to_tag* - 正在处理的呼叫的 to_tag（如果存在）。
- *branch* - RTP 中继参与的分支
				- 如果在主分支参与，则使用 *-1*。
- *body* - 可选，如果使用显式正文，
				否则应考虑消息的正文。
- *set* - 用于呼叫的 rtp 中继集。
- *node* - 可选，节点引擎标识符 - 这是
				在运行 *route_offer* 路由后返回的用户填充值（请参阅下面的返回值部分）。
- *flags* - 可选，由正在复制 SDP 的模块指定的标志。
- *copy-ctx* - 可选，复制上下文标识符 -
				这是用户填充值，在
				*route_copy_offer* 执行结束时返回。


不需要返回值。


*默认值为 "rtp_relay_copy_delete"。*


```c title="设置 rtp_relay_copy_delete 参数"
...
modparam("rtp_relay", "route_copy_delete", "custom_rtp_copy_delete")
...
```


```c title="设置 rtp_relay_copy_delete 用法"
...
route[rtp_relay_copy_delete] {
	# 移除由 $param(copy-ctx) 变量标识的复制实例
}
...
```


### 导出的函数


#### rtp_relay_engage(engine, [set])


为当前初始 INVITE 参与 RTP 中继 *engine*。
		调用此函数后，整个 RTP 中继通信将由模块本身处理，
		无需为任何进一步的同-dialog 请求/回复进行干预（除非您特别希望这样做）。


该函数不是立即执行媒体请求，而是注册钩子以自动处理任何进一步的媒体请求。


使用的 RTP 会话修改器是通过
		[rtp relay](#pv_rtp_relay)、
		[rtp relay peer](#pv_rtp_relay_peer)、
		[rtp relay caller](#pv_rtp_relay_caller) 和/或
		[rtp relay callee](#pv_rtp_relay_callee) 变量配置的。


该函数可以从主请求路由调用 - 在这种情况下，
		RTP 中继将为任何进一步的分支参与；或者从分支路由调用 - 在这种情况下，
		RTP 中继将仅在为它调用的分支或具有关联 *rtp_relay* 配置的分支参与。


将作用域相关的 [rtp relay](#pv_rtp_relay) 变量与此函数一起使用时，
		请注意其含义取决于使用位置。在初始 INVITE 的主请求路由中，
		[rtp relay](#pv_rtp_relay) 指呼叫者，
		[rtp relay peer](#pv_rtp_relay_peer) 指被呼叫者。
		在分支路由中，[rtp relay](#pv_rtp_relay) 指被呼叫者分支，
		[rtp relay peer](#pv_rtp_relay_peer) 指呼叫者。
		为避免依赖此路由作用域，请改用
		[rtp relay caller](#pv_rtp_relay_caller) 和
		[rtp relay callee](#pv_rtp_relay_callee)。


参数的含义如下：


- *engine(string)* - 用于呼叫的 RTP 中继引擎
				（即 *rtpproxy*、*rtpengine* 或 *route*）
- *set(int, 可选)* - 用于此呼叫的集合。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE。


```c title="rtp_relay_engage 用法"
...
如果（是方法("INVITE") && !has_totag()）{
	xlog("脚本：为所有分支参与 RTPProxy 中继\n");
	$rtp_relay = "co";
	$rtp_relay_peer = "co";
	rtp_relay_engage("rtpproxy");
}
...
		
```


### 导出的 MI 函数


#### rtp_relay:list


替换已弃用的 MI 命令：*rtp_relay_list*。


列出所有参与的 RTP 中继会话。


参数：


- *engine* -（可选）RTP
					中继引擎（即 *rtpproxy*
					或 *rtpengine*）。
- *set* -（可选）RTP
					中继集合。当使用时，*engine*
					参数也必须指定。
- *node* -（可选）RTP
					中继节点。当使用时，*engine*
					参数也必须指定。


```c title="rtp_relay:list 用法"
...
## 列出所有会话
$ opensips-cli -x mi rtp_relay:list

## 列出通过特定 RTP 节点的所有会话
$ opensips-cli -x mi rtp_relay:list rtpproxy udp:127.0.0.1:2222
...
			
```


#### rtp_relay:update


替换已弃用的 MI 命令：*rtp_relay_update*。


更新/重新参与所有正在进行的 RTP 中继会话。


此函数可用于触发某些正在进行的 RTP 会话的同-dialog
				更新。对于所有匹配的会话，它重新参与 RTP 中继 offer/answer 会话，
				然后向呼叫参与者发送带有更新 SDP 的 re-INVITE。


*注意：*运行没有过滤器（如 *engine* 或 *set*）的命令
				将导致所有 RTP 中继会话被重新参与。


*注意：*当强制新节点时，
				不能保证使用该节点 - 如果节点不可用，
				但另一个节点可用，则将选择活动节点。


*注意：*如果节点正在更改，
				模块会尝试 unforce 之前的 RTP 中继会话，
				即使它可能不起作用。


参数：


- *engine* -（可选）RTP
					中继引擎（即 *rtpproxy*
					或 *rtpengine*）用作过滤器。
- *set* -（可选）RTP
					中继集合用作过滤器。如果缺失，
					将使用与最初参与的相同集合。
- *node* -（可选）RTP
					中继节点用作过滤器。
- *new_set* -（可选）新的 RTP
					中继集合用于此呼叫。
- *new_node* -（可选）新的 RTP
					节点用于此呼叫。如果
					*new_set* 缺失，
					将使用相同的集合。


```c title="rtp_relay:update 用法"
...
## 更新使用 rtpproxy 的所有会话
$ opensips-cli -x mi rtp_relay:update rtpproxy
...
			
```


#### rtp_relay:update_callid


替换已弃用的 MI 命令：*rtp_relay_update_callid*。


更新/重新参与所有正在进行的 RTP 中继会话。


该函数基本上以与 [mi update](#mi_update) 相同的方式工作，
				但用于更新特定 callid。此外，还可以
				为特定会话更新使用的 *engine* 和 *flags*。


参数：


- *callid* - 用于
					匹配要更新的对话的 callid。
- *engine* -（可选）新的 RTP
					中继引擎（即 *rtpproxy*
					或 *rtpengine*）使用。如果
					缺失，将使用相同的初始引擎。
- *set* -（可选）新的 RTP
					中继集合使用。如果缺失，
					将使用与最初参与的相同默认集合。
- *node* -（可选）RTP
					中继节点使用。如果未指定，
					使用第一个可用节点。
- *flags* -（可选）一个 JSON，
					包含 *caller* 和/或
					*callee* 节点，
					其中包含应用于会话的新标志。仅
					显式指定的标志将被覆盖。


```c title="rtp_relay:update_callid 用法"
...
## 使用工作的 RTPproxy 节点更新呼叫
$ opensips-cli -x mi rtp_relay:update_callid 1-3758963@127.0.0.1 rtpproxy

## 更新呼叫以使用 RTPEngine，呼叫者使用 SRTP SDP
$ opensips-cli -x mi rtp_relay:update_callid callid=1-3758963@127.0.0.1 \
	flags='{ "caller":{"type":"SRTP", "flags":"replace-origin"},
		"callee":{"type":"RTP", "flags"="replace-origin"}}'
...
			
```


### 导出的伪变量


#### $rtp_relay


用于为当前对等方配置 RTP 后端标志。
				此变量是作用域相关的：在初始 INVITE 的主请求路由中，
				它配置呼叫者，而在初始 INVITE 的分支路由或回复中，
				它配置被呼叫者分支。


对于顺序请求，该变量表示用于生成请求的 UAC 的标志。
				当在回复中使用时，配置另一个 UAC 的标志。


当脚本需要直接寻址呼叫者或被呼叫者一侧时，
				请使用 [rtp relay caller](#pv_rtp_relay_caller) 和
				[rtp relay callee](#pv_rtp_relay_callee)，
				独立于路由作用域。


在初始 INVITE 作用域中，变量可以通过使用变量索引
				按分支配置。


对于每个 UAC/对等方，有多个可以配置的标志：


- *flags*（默认，当
					变量不带名称使用时） - 与当前 UAC 关联的标志，
					它们与 offer 命令一起传递
- *peer* - 这些标志
					在 offer 命令中传递，但它们是与另一个 UAC/对等方关联的标志
- *ip* - 应在结果 SDP 中公布的 IP。
- *type* - 当前 UAC 使用的 RTP 类型（目前仅由 *rtpengine* 使用）
- *iface* - 用于来自此 UAC 的流量的接口。
- *body* - 用于 UAC 的正文。
- *delete* - 媒体会话终止/删除时使用的标志。
- *disabled* - 配置为整数，
					用于禁用此 UAC 的 RTP 中继。


#### $rtp_relay_peer


此变量具有与 [rtp relay](#pv_rtp_relay) 变量相同的含义和参数，
				只是用于配置除当前 UAC 之外的其他 UAC 的标志。所有其他字段类似。


#### $rtp_relay_caller


此变量具有与 [rtp relay](#pv_rtp_relay) 相同的参数，
				但总是配置 RTP 中继会话的呼叫者一侧，
				独立于使用它的路由。


在初始 INVITE 的主请求路由中，这等同于 [rtp relay](#pv_rtp_relay)。
				在初始 INVITE 的分支路由或回复中，
				等同于 [rtp relay peer](#pv_rtp_relay_peer)。
				对话建立后，它直接寻址存储的呼叫者一方。


#### $rtp_relay_callee


此变量具有与 [rtp relay](#pv_rtp_relay) 相同的参数，
				但总是配置 RTP 中继会话的被呼叫者一侧，
				独立于使用它的路由。


在初始 INVITE 的主请求路由中，这等同于 [rtp relay peer](#pv_rtp_relay_peer)。
				在初始 INVITE 的分支路由或回复中，
				等同于 [rtp relay](#pv_rtp_relay)。
				对话建立后，它直接寻址存储的被呼叫者一方。


#### $rtp_relay_ctx()


此变量可用于提供有关 RTP 上下文的信息，
				这些信息与任何涉及的对等方都没有关联。


可以使用以下设置：


- *callid* - 用于与 rtp 服务器的所有通信的 callid。
					如果未指定，则从消息/对话中获取。
- *from_tag* - 用于与 rtp 服务器的所有通信的 from-tag。
					如果未指定，则从消息/对话中获取。
- *to_tag* - 用于与 rtp 服务器的所有通信的 to-tag。
					如果未指定，则从消息/对话中获取。
- *flags* - 发送到所有 offer/answer 请求的通用标志。
- *delete* - 中继会话终止时发送的标志。
<!-- CONTRIBUTORS -->

### 许可

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0 版授权
