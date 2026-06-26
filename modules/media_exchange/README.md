---
title: "媒体交换模块"
description: "此模块提供了在不同SIP代理呼叫以及从媒体服务器发起或接收的呼叫之间交换媒体SDP的方法。该模块本身没有任何媒体能力，它只是暴露了在不同呼叫之间交换SDP体的原语。"
---

## 管理指南


### 概述


此模块提供了在不同SIP代理呼叫以及从媒体服务器发起或接收的呼叫之间交换媒体SDP的方法。该模块本身没有任何媒体能力，它只是暴露了在不同呼叫之间交换SDP体的原语。


该模块可以发起呼叫，将现有SDP推送到媒体服务器进行播放，或者简单地录制现有RTP，也可以获取新呼叫的SDP并将其注入到现有代理的SIP呼叫中。为了操作新呼叫（无论是生成的还是终止的），该模块充当背靠背用户代理，目标是OpenSIPS B2B实体模块。


在SDP媒体交换方面，该模块可以有两种不同的模式：


- *双向媒体* - 在此模式下，新呼叫的媒体将被推送到现有呼叫的某一侧。这将导致呼叫的一方与媒体服务器通话。默认情况下，呼叫的其他参与者将被保持，但可以在发起新侧时调整此行为。
- *媒体分叉* - 新B2B呼叫（无论是发起还是终止）的媒体将只是由媒体代理引擎分叉的RTP副本。在此模式下，代理呼叫应该在分叉呼叫开始之前已经建立了RTP relay路径。一个人只能分叉一个媒体侧，或者两个侧都可以。*注意：*目前RTPProxy不支持停止媒体流，因此如果流呼叫终止，RTPProxy将继续流传输，即使另一端没有人听。


此模块可以提供不同的功能，可用于各种用例：


- *呼叫录制* - 类似于OpenSIPS SIPREC模块，它可以分叉RTP媒体到一个新的SIP目的地，但没有SIPREC负载。
- *呼叫监听* - 人们可能想要调用OpenSIPS并开始监听一个现有呼叫。
- *呼叫公告* - 将媒体服务器的公告注入到正在进行的呼叫的参与者。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *TM* - 事务模块。
- *Dialog* - 用于跟踪代理呼叫的对话模块。
- *RTP Relay* - 可选，当初始呼叫使用RTP Relay，或者使用媒体分叉模式时。
- *B2B_ENTITIES* - 用于与媒体服务器操作呼叫的背靠背模块。


#### 外部库或应用程序


运行此模块加载的OpenSIPS之前必须安装以下库或应用程序：


- *无*。


### 导出的函数


#### media_fork_to_uri(URI[, leg][, headers][, medianum][, instance])


充当B2B用户代理客户端，向SIP URI发起呼叫，然后将媒体流式传输到200 OK响应中收到的SDP。


可以多次调用，每次调用将创建一个新呼叫。生成的呼叫可以使用*instance*参数进行标识。


参数：


- *URI* (string) - 推送当前呼叫媒体的目的地
- *leg* (string, 可选) - 将被流式传输的侧。可能的值是*caller*、*callee*和*both*。如果缺失，则使用indialog请求的方向。
- *headers* (string, 可选) - 添加到生成请求中的可选头。
- *medianum* (integer, 可选) - 将在呼叫中分叉的媒体流。第一个索引是0。如果缺失，该侧的所有媒体流都将被流式传输。
- *instance* (string, 可选) - 用于标识分叉实例的唯一名称。如果缺失，则假定为*default*名称。


此函数可用于任何路由。


```c title="使用 media_fork_to_uri() 函数将媒体分叉到媒体服务器"
...
if (!has_totag() && is_method("INVITE"))
	media_fork_to_uri("sip:record@127.0.0.1:5080");
...
	
```


#### media_fork_from_call(callid[, leg][, medianum][, instance])


开始将现有代理呼叫的媒体流式传输，媒体来自请求体中的SDP，通过*callid*参数标识。


可以多次调用，每次调用将接受一个新呼叫。呼叫可以使用*instance*参数进行标识。


参数：


- *callid* (string) - 要流式传输/分叉媒体的呼叫标识符
- *leg* (string, 可选) - 将被流式传输的侧。可能的值是*caller*、*callee*和*both*。如果缺失，两侧都将被流式传输。
- *medianum* (integer, 可选) - 将在呼叫中分叉的媒体流。第一个索引是0。如果缺失，该侧的所有媒体流都将被流式传输，前提是请求体中有足够的媒体流。*注意：*RTPProxy不进行任何媒体混合，因此您需要确保INVITE有足够的SDP流来处理所有选定为分叉的媒体流。
- *instance* (string, 可选) - 用于标识分叉实例的唯一名称。如果缺失，则假定为*default*名称。


此函数可用于REQUEST_ROUTE、BRANCH_ROUTE、FAILURE_ROUTE和ONREPLY_ROUTE。


*注意：*此呼叫的请求完全由B2B引擎处理。因此，运行此函数后，请确保不再转发消息，否则会出现意外行为。最好的做法是在运行函数后退出处理。


```c title="使用 media_fork_from_call() 函数分叉呼叫的所有媒体流"
...
if (!has_totag() && is_method("INVITE") && $hdr(X-CallID) != NULL)
	media_fork_from_call($hdr(X-CallID));
...
	
```


```c title="使用 media_fork_from_call() 函数仅分叉第一个呼叫者的流"
...
if (!has_totag() && is_method("INVITE") && $hdr(X-CallID) != NULL)
	media_fork_from_call($hdr(X-CallID), "caller", 0);
...
	
```


#### media_fork_pause([leg][, medianum][, instance])


暂停现有的RTP媒体流会话。此函数不会终止分叉呼叫，只是停止发送RTP。它还会重新邀请媒体服务器通知有关更改。


参数：


- *leg* (string, 可选) - 将被暂停的侧。可能的值是*caller*、*callee*和*both*。如果缺失，所有正在进行的媒体会话都将被暂停。
- *medianum* (integer, 可选) - 要暂停的媒体流。第一个索引是0。如果缺失，与所选侧关联的所有正在进行的媒体流都将被暂停。
- *instance* (string, 可选) - 要暂停的分叉实例。如果缺失，所有实例都将被暂停。


此函数可用于任何路由。


```c title="使用 media_fork_pause() 函数临时停止呼叫的整个媒体流"
...
if (has_totag() && is_method("INVITE"))
	media_fork_pause();
...
	
```


#### media_fork_resume([leg][, medianum][, instance])


恢复现有会话/呼叫的RTP媒体流。此函数依赖于之前已启动媒体分叉会话的事实。


参数：


- *leg* (string, 可选) - 将被恢复的侧。可能的值是*caller*、*callee*和*both*。如果缺失，所有已停止的现有媒体侧都将被启动。
- *medianum* (integer, 可选) - 要暂停的媒体流。第一个索引是0。如果缺失，与所选侧关联的所有正在进行的媒体流都将被暂停。
- *instance* (string, 可选) - 要恢复的分叉实例。如果缺失，所有实例都将被恢复。


此函数可用于任何路由。


```c title="使用 media_fork_resume() 函数恢复之前停止的分叉"
...
if (has_totag() && is_method("INVITE"))
	media_fork_resume();
...
	
```


#### media_exchange_from_uri(URI[, leg][, body][, headers][, nohold])


向指定URI发起呼叫。获取响应中的SDP并将其推送到呼叫的一侧，导致正在进行的呼叫的参与者与新呼叫之间进行双向音频。默认情况下，另一参与者侧被保持。


可以为indialog请求调用，例如重新INVITE（例如当将实体保持时），或INFO请求（由DTMF触发）。


参数：


- *URI* (string) - 用于发起新呼叫的目的地。
- *leg* (string, 可选) - 新媒体SDP将被推送到的侧。可能的值是*caller*和*callee*。如果缺失，模块认为是保持重新INVITE，并交换另一侧的媒体SDP。
- *body* (string, 可选) - 用于生成INVITE的自定义消息体。如果缺失，将使用与所涉及侧关联的对话中存储的消息体。
- *headers* (string, 可选) - 添加到生成请求中的可选头。
- *nohold* (integer, 可选) - 如果设置为true，另一参与者将不会被保持。当为另一侧也将生成新呼叫时，这很有用。


此函数可用于任何路由。


```c title="使用 media_exchange_from_uri() 函数从媒体服务器的呼叫获取媒体"
...
if (has_totag() && is_method("INVITE") && is_audio_on_hold())
	media_exchange_from_uri("sip:moh@127.0.0.1:5080");
...
	
```


#### media_exchange_to_call(callid[, leg][, nohold])


将在现有代理呼叫中收到的新呼叫的SDP推送，导致发起呼叫的媒体服务器与现有代理呼叫的参与者之间进行双向音频。


参数：


- *callid* (string) - 要交换媒体的呼叫标识符
- *leg* (string) - 将被流式传输的侧。可能的值是*caller*和*callee*。
- *nohold* (integer, 可选) - 如果设置为true，另一参与者将不会被保持。当为另一侧也将生成新呼叫时，这很有用。


此函数可用于REQUEST_ROUTE、BRANCH_ROUTE、FAILURE_ROUTE和ONREPLY_ROUTE。


*注意：*此呼叫的请求完全由B2B引擎处理。因此，运行此函数后，请确保不再转发消息，否则会出现意外行为。最好的做法是在运行函数后退出处理。


```c title="使用 media_exchange_to_call() 函数进行公告"
...
if (!has_totag() && is_method("INVITE") && $hdr(X-CallID) != NULL)
	media_exchange_to_call($hdr(X-CallID), "caller");
...
	
```


#### media_terminate([leg][, nohold][, instance])


终止正在进行的媒体会话交换，无论是仅流式传输还是双向音频流动。如果参与者侧涉及不同的媒体交换，当前侧被保持。


参数：


- *leg* (string, 可选) - 要终止媒体交换的侧。可能的值是*caller*和*callee*。如果缺失，则使用indialog请求的方向。
- *nohold* (integer, 可选) - 如果设置为true，并且另一参与者涉及不同的媒体交换，当前侧不再被保持。*注意：*如果终止媒体交换的请求是dialog内的重新INVITE，此函数不会取消保持另一侧，因为重新INVITE本身应该被转发以执行此操作。可以通过显式设置*nohold*参数来更改此行为。
- *instance* (string, 可选) - 仅在终止分叉实例时使用，表示要终止的实例。终止流会话时必须省略。但是，为了向后兼容，如果参数缺失且未找到流会话，命令将终止*default*分叉实例（如果存在）。


此函数可用于任何路由。


```c title="使用 media_terminate() 函数终止公告"
...
if (has_totag() && is_method("INVITE") && !is_audio_on_hold())
	media_terminate();
...
	
```


#### media_handle_indialog()


搜索为任何侧启动的现有媒体会话，如果找到正在进行的会话，它会执行处理该请求的其他逻辑。例如，如果媒体以分叉模式启动，并且INVITE是用于激活保持的，则函数也将暂停分叉的流。


根据此函数的返回码，必须在脚本中执行其他逻辑。可能的返回码是：


- *1* - 表示消息已被处理，但脚本中没有其他任务要执行。
- *-1* - 表示该呼叫没有正在进行的媒体交换或分叉，或者该请求没有其他逻辑要执行。
- *-2* - 表示请求的所有其他处理都已执行，请求不应转发到用户代理，而应被丢弃。
- *-3* - 表示内部错误。


此函数可用于REQUEST_ROUTE、BRANCH_ROUTE和ONREPLY_ROUTE。


```c title="使用 media_terminate() 函数终止公告"
...
if (has_totag() && loose_route()) {
	# 处理顺序
	media_handle_indialog();
	switch ($rc) {
	case -2:
		drop;
	case -1:
		xlog("该呼叫没有正在进行的媒体会话！\n");
	case 1:
		break;
}
...
	
```


### 导出的MI函数


#### media_exchange:fork_from_call_to_uri


替换已废弃的MI命令：*media_fork_from_call_to_uri*。


MI命令与media fork to uri具有相同的行为，只是触发不是脚本驱动的，而是外部驱动的。用于开始监听呼叫。


名称：*media_exchange:fork_from_call_to_uri*


参数


- *callid* (string) - 其RTP将被流式传输到新呼叫到媒体服务器的对话的callid
- *uri* (string) - 新呼叫的目标URI
- *leg* (string, 可选) - 指示其RTP将在新呼叫中被流式传输的参与者侧。可能的值是"caller"、"callee"或"both"。如果缺失，两条媒体流都被分叉
- *headers* (string, 可选) - 添加到传出请求的额外头
- *medianum* (integer, 可选) - 将在呼叫中分叉的媒体流。第一个索引是0。如果缺失，该侧的所有媒体流都将被流式传输。
- *instance* (string, 可选) - 分叉实例的唯一名称。如果缺失，则假定为*default*名称。


MI FIFO命令格式：


```c
# 开始将呼叫流式传输到录制媒体服务器
opensips-cli -x mi media_exchange:fork_from_call_to_uri \
	callid=c6fdb0f9-47dc-495d-8d38-0f37e836a531 \
	uri=sip:record@127.0.0.1:5080
	
```


#### media_exchange:from_call_to_uri


替换已废弃的MI命令：*media_exchange_from_call_to_uri*。


MI命令与media exchange from uri具有相同的行为，只是触发不是脚本驱动的，而是外部驱动的。用于在呼叫期间注入媒体公告。


名称：*media_exchange:from_call_to_uri*


参数


- *callid* (string) - 其侧将与媒体服务器的新呼叫混合的对话的callid
- *uri* (string) - 新呼叫的目标URI
- *leg* (string) - 指示其媒体将被固定到新呼叫的参与者。可能的值是"caller"和"callee"。
- *headers* (string, 可选) - 添加到传出请求的额外头
- *nohold* (integer, 可选) - 如果设置为非零值，模块避免在媒体交换开始时将另一参与者保持


MI FIFO命令格式：


```c
# 开始向呼叫者播放公告
opensips-cli -x mi media_exchange:from_call_to_uri \
	callid=c6fdb0f9-47dc-495d-8d38-0f37e836a531 \
	uri=sip:announcement@127.0.0.1:5080 \
	leg=caller
	
```


#### media_exchange:from_call_to_uri_body


替换已废弃的MI命令：*media_exchange_from_call_to_uri_body*。


MI命令执行与mi from call to uri MI函数相同的操作，但还允许您在传出请求中指定自定义消息体。消息体必须在强制性的*body*参数中指定，所有其他参数与mi from call to uri中的参数相同。


#### media_exchange:terminate


替换已废弃的MI命令：*media_terminate*。


终止正在进行的媒体交换的MI命令。


名称：*media_exchange:terminate*


参数


- *callid* (string) - 将终止媒体交换的对话的callid。
- *leg* (string, 可选) - 为其终止媒体交换的侧。可接受的值是*caller*、*callee*和*both*。如果缺失，所有媒体会话都被终止。
- *nohold* (integer, 可选) - 如果指定且具有非零值，正在被终止的侧如果另一参与者仍有正在进行的媒体会话则不会被保持。
- *instance* (string, 可选) - 仅在终止分叉实例时使用，表示要终止的实例。终止流会话时必须省略。但是，为了向后兼容，如果参数缺失且未找到流会话，命令将终止*default*分叉实例（如果存在）。


MI FIFO命令格式：


```c
# 终止呼叫者公告
opensips-cli -x mi media_exchange:terminate \
	callid=c6fdb0f9-47dc-495d-8d38-0f37e836a531 \
	leg=caller
	
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即.md扩展名）均采用知识共享署名4.0许可证。
