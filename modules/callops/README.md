---
title: "呼叫操作模块"
description: "此模块提供一组允许用户控制正在进行的呼叫的函数。它可用于触发呼叫（盲转或 attended 转）转移，或从代理端而非终端设备端将呼叫置于保持状态。该模块绑定在 OpenSIPS Dialog 模块之上以获取有关正在进行的呼叫的信息，以及存储有关将启动的新呼叫的信息。"
---

## 管理指南


### 概述


此模块提供一组允许用户控制正在进行的呼叫的函数。它可用于触发呼叫（盲转或 attended 转）转移，或从代理端而非终端设备端将呼叫置于保持状态。
该模块绑定在 [OpenSIPS Dialog 模块](../dialog) 之上以获取有关正在进行的呼叫的信息，以及存储有关将启动的新呼叫的信息。


该模块还通过事件接口触发一组事件，向外部应用程序提供有关呼叫如何被转移以及它们如何相互链接的详细信息。这些事件可用于跟踪呼叫转移中涉及的所有分支。


在呼叫转移场景中，最大的挑战之一是将新呼叫与被转移的旧呼叫链接起来，特别是在盲呼叫转移场景中。为了解决这个挑战，可以将模块配置为使用两种不同模式中的一种来引用旧分支，可通过 [mode](#param_mode) 参数更改：


- 自动（默认模式），通过在发送的 REFER 中的目标 URI 添加特殊参数。当新呼叫返回时，该参数将出现在新呼叫的 Request URI 中。模块将找到它，将新呼叫链接到旧呼叫，并从 URI 中删除该参数。
- 手动，通过使用自定义/外部逻辑（如数据库或本地存储）来匹配旧呼叫。在此模式下，用户必须显式调用 [call blind replace](#func_call_blind_replace) 函数将两个呼叫链接在一起。


该模块还可用于捕获 *Notify refer* 事件并从 OpenSIPS 级别回复它们。但是请注意，在 *auto* 模式下，即使在对话框匹配时处理了 NOTIFY，请求仍将继续执行脚本，这与使用 [call transfer notify](#func_call_transfer_notify) 函数的 *manual* 模式不同。为了避免将 NOTIFY 发送到端点，您必须丢弃它，如下所示：


```c title="丢弃自动处理的 NOTIFY refer 事件"
...
if (has_totag() && loose_route() &&
		is_method("NOTIFY") && $hdr(Event) == "refer")
	drop;
...
```


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *TM* - 事务模块。
- *Dialog* - 用于跟踪代理呼叫的对话框模块。


#### 外部库或应用程序


以下库或应用程序必须在运行加载了此模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### mode (string/integer)


此参数可用于更改模块用于匹配被转移分支的模式。支持的值为：


- *param* / *0* - 当进行盲转移时，refer 消息中发送的目标将包含一个用于识别被替换对话框的参数。当收到新呼叫时，此参数将被自动删除。
- *manual* / *1* - 用户将创建自己的逻辑来匹配新呼叫，并将调用 [call blind replace](#func_call_blind_replace) 函数使 OpenSIPS 知道该配对。请注意，此模式也不会自动处理 *Notify refer*，因此您还必须使用 [call transfer notify](#func_call_transfer_notify) 函数来处理它们。
- *callid* / *2* - 与 *param* 值类似，只是使用实际的 callid 作为标识符，而不是存储在 Request URI 中被转移呼叫的对话框 id。


*默认值为 "0"（使用参数自动模式）。*


```c title="设置 mode 参数"
...
modparam("callops", "mode", "manual") # 使用您自己的逻辑
...
```


#### match_param (string)


用于将不同呼叫匹配在一起的参数。这主要在 *param* 模式中使用，但也用于在内部存储被转移对话框中的不同值 - 确保它不与现有对话框值重叠。


*默认值为 "osid"。*


```c title="设置 match_param 参数"
...
modparam("callops", "match_param", "call")
...
```


### 导出的函数


#### call_blind_replace(callid[, leg])


当使用 *manual mode* 时，调用此函数在被转移呼叫和转移呼叫之间创建映射。当 OpenSIPS 收到正在转移现有呼叫的新呼叫时应调用它。


参数：


- *callid* (string) - 正在被转移的现有呼叫。
- *leg* (string, optional) - 正在被转移的分支。如果未指定，且 OpenSIPS 无法根据其目标确定分支，则应使用 *unknown* 标签。


此函数只能从请求路由使用。


```c title="使用 call_blind_replace() 函数匹配现有分支。"
...
if (!has_totag() && is_method("INVITE")) {
	if (cache_fetch("local", "callid_$si", $avp(callid))) {
		call_blind_replace($avp(callid));
	}
}
...
	
```


#### call_transfer_notify()


当使用 *manual mode* 时，应在 *Event: refer* 头的对话框内 NOTIFY 请求上调用此函数来相应地处理它们。


请注意，如果函数成功处理了 NOTIFY 请求，脚本将不再继续执行。


此函数可用于请求路由、失败路由和本地路由。


```c title="使用 call_transfer_notify() 函数处理 NOTIFY refer 请求。"
...
if (has_totag() && is_method("NOTIFY") && loose_route()) {
	call_transfer_notify();
}
...
	
```


#### call_transfer(leg, destination) 或


此函数通过在进行的呼叫期间发送 REFER 消息来触发盲呼叫转移。函数需要在您正在转移的对话框上下文中运行。


参数：


- *leg* (string) - 正在被转移的分支。必须是 *caller* 或 *callee* 之一。
- *destination* (string) - 分支正在被转移到的目标 SIP URI。


此函数可用于任何具有对话框上下文的路由。


```c title="使用 call_transfer() 函数将呼叫者盲转到新目的地。"
...
if (has_totag() && && loose_route()) {
	call_transfer("caller", "sip:announcement@127.0.0.1");
}
...
	
```


#### call_transfer(leg, transfer_callid, transfer_leg[, destination]) 或


此函数通过在进行的呼叫期间发送 REFER 消息来触发 attended 呼叫转移。函数需要在您正在转移的对话框上下文中运行。


参数：


- *leg* (string) - 正在被转移的分支。必须是 *caller* 或 *callee* 之一。
- *transfer_callid* (string) - 正在被转移的第二个对话框的 callid。
- *transfer_leg* (string) - 将被转移给 *leg* 的第二个呼叫中的分支。必须是 *caller* 或 *callee* 之一。
- *destination* (string, optional) - 分支正在被转移到的目标 SIP URI。如果缺失，则使用初始呼叫的 From/To URI。


此函数可用于任何具有对话框上下文的路由。


```c title="使用 call_transfer() 函数将呼叫者转移到不同呼叫的被叫方。"
...
if (has_totag() && && loose_route()) {
	call_transfer("caller", "ba55b1b3-459d-4e84-a6f8-14c40e4f6ace", "callee");
}
...
	
```


### 导出的 MI 函数


#### callops:transfer


替换已弃用的 MI 命令：*call_transfer*。


用于将进行的呼叫转移到他处的 MI 命令。


根据使用的参数，此命令可以执行盲转移和 attended 转移场景。当使用 *transfer_callid* 时，执行 attended 转移，否则发出盲转移。


名称：*callops:transfer*


参数


- *callid* (string) - 正在被转移的对话框的 callid。
- *leg* (string) - 指示正在被转移的 *callid* 呼叫的哪个分支/保留在新的转移呼叫中。可能的值为 "caller"、"callee" 或 "both"。
- *destination* (string, optional) - 呼叫正在被转移到的 URI。对于盲转移此参数是必需的，对于 attended 转移则是可选的。在 attended 转移的情况下，如果缺失，呼叫的目标取自转移对话框中的 URI。
- *transfer_callid* (string, optional) - 在 attended 转移的情况下是必需的，以指定新呼叫中 Bleg 的呼叫。
- *transfer_leg* (string, optional) - 在 attended 转移的情况下，它指定 *transfer_callid* 呼叫的参与者将与 *callid* 的 *leg* 桥接。如果缺失，必须使用 *transfer_fromtag* 和 *transfer_totag* 来识别标签。
- *transfer_fromtag* 和 *transfer_totag* (string, optional) - 这些参数应始终一起指定，用于在 attened 转移场景中，被转移的 Bleg 对话框不是由 OpenSIPS 管理的。请注意，对于这些场景，只有 A-leg 对话框将收到有关呼叫转移的事件。


MI FIFO 命令格式：


```c
# 盲转移到 sip:agent@127.0.0.1
opensips-cli -x mi callops:transfer \
	callid=4b664b48-5639-40bf-bff8-3a866c145c3b \
	leg=caller \
	destination=sip:agent@217.0.0.1
			
```


```c
# 两个呼叫之间的 attended 转移
opensips-cli -x mi callops:transfer \
	callid=e8d024db-78e5-4d18-9794-5b8ba837bed4
	leg=caller \
	transfer_callid=559abf97-9834-4380-bba1-a036eb245450 \
	transfer_leg=calee
			
```


#### callops:hold


替换已弃用的 MI 命令：*call_hold*。


用于将进行的呼叫置于保持状态的 MI 命令。


如果呼叫的任何分支被置于保持状态，命令返回 *OK*。如果呼叫已经在保持状态，则返回错误。


名称：*callops:hold*


参数


- *callid* (string) - 正在被置于保持状态的对话框的 callid。
- *leg* (string, optional) - 仅将特定参与者置于保持状态。可能的值为 *caller*、*callee* 和 *bold*，指示正在被置于保持状态的分支。如果未使用，则两个分支都被置于保持状态。
- *headers* (string 或 array, optional) - 要添加到传出 re-INVITE 的额外头部。如果提供字符串，头部将同时发送到呼叫者和被叫者。如果提供两个字符串元素的数组，第一个元素代表发送到呼叫者的头部，第二个代表发送到被叫者的头部。对呼叫者使用空字符串表示不传递任何头部。


MI FIFO 命令格式：


```c
# 将呼叫置于保持状态
opensips-cli -x mi callops:hold \
	callid=921b00e4-fec0-4a36-9397-a40ab74e1893
			
```


#### callops:unhold


替换已弃用的 MI 命令：*call_unhold*。


用于从 [mi hold](#mi_hold) 呼叫放置的保持状态恢复呼叫的 MI 命令。


如果任何分支被恢复，命令返回 *OK*，如果没有分支之前被置于保持状态，则返回错误。


名称：*callops:unhold*


参数


- *callid* (string) - 正在被恢复的对话框的 callid。
- *leg* (string, optional) - 仅恢复特定的保持参与者。可能的值为 *caller*、*callee* 和 *bold*，指示正在被恢复的分支。如果未使用，则两个分支都被恢复。
- *headers* (string 或 array, optional) - 要添加到传出 re-INVITE 的额外头部。如果提供字符串，头部将同时发送到呼叫者和被叫者。如果提供两个字符串元素的数组，第一个元素代表发送到呼叫者的头部，第二个代表发送到被叫者的头部。对呼叫者使用空字符串表示不传递任何头部。


MI FIFO 命令格式：


```c
opensips-cli -x mi callops:unhold \
	callid=921b00e4-fec0-4a36-9397-a40ab74e1893
			
```


### 导出的事件


#### E_CALL_TRANSFER


此事件在呼叫转移场景期间触发。


对于特定的呼叫转移，多个事件被触发，从转移开始到转移完成。*state* 参数指示呼叫转移的状态。


对于盲转移场景，只触发一组事件，而对于 attended 转移，如果两者都通过 OpenSIPS 代理，您将获得涉及转移的两个对话框的各一组事件。


参数：


- *callid* - 正在被转移的呼叫的 callid。
- *leg* - 正在被转移的呼叫的分支（*caller* 或 *callee*）。
- *transfer_callid* - 正在转移旧 *callid* 呼叫的新呼叫的 callid。
- *destination* - *leg* 正在被转移到的 URI 目的地。
- *state* - 转移的状态：
					
				*start* - 当 REFER 消息被发送到被转移的参与者时触发。
				*notify* - 当收到被转移参与者的 NOTIFY refer 事件时触发。*status* 参数包含有关转移呼叫状态的额外信息。
				*ok* - 转移完成时触发 - 呼叫被被转移的参与者应答。
				*fail* - 当转移因各种原因失败时触发。如果我们无法启动呼叫转移（即发送 REFER），*status* 参数为空，否则它包含有关失败的信息。
- *status* - 包含有关呼叫成功或失败的额外信息。


#### E_CALL_HOLD


在将呼叫置于保持状态或从保持状态恢复呼叫的过程中触发。


此事件为呼叫的每个分支触发两次 - 首先是分支开始被置于保持状态时，然后是分支接受或拒绝状态时。


参数：


- *callid* - 正在被置于保持状态或恢复的呼叫的 callid。
- *leg* - 受呼叫保持或恢复影响的分支（*caller* 或 *callee*）。
- *action* - 正在执行的 *hold* 或 *unhold* 操作。
- *state* - 正在执行的操作的状态。
					
				*start* - 当 re-INVITE 被发送到正在被置于保持状态的参与者时触发。
				*ok* - 保持/恢复操作成功完成时触发。
				*fail* - 操作失败时触发。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0 版授权
