---
title: "sipmsgops 模块"
description: "该模块实现了对 OpenSIPS 处理的消息进行基于 SIP 的操作。SIP 是一个基于文本的协议，该模块提供了一组非常有用的函数来在 SIP 级别操作消息，例如插入新头部或删除它们、检查方法类型等。"
---

## 管理指南


### 概述


该模块实现了对 OpenSIPS 处理的消息进行基于 SIP 的操作。
SIP 是一个基于文本的协议，该模块提供了一组非常有用的函数来在
SIP 级别操作消息，例如插入新头部或删除它们、检查方法类型等。


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *无其他 OpenSIPS 模块依赖*。


#### 外部库或应用程序


运行 OpenSIPS 并加载此模块之前必须安装以下库或应用程序：


- *无*。


### 导出的函数


#### append_to_reply(txt)


将 'txt' 作为头部追加到将为该请求生成的所有回复中。


参数含义如下：


- *txt (string)* - SIP 头部字段、
				值和 CRLF 标记。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、
		BRANCH_ROUTE 和 ERROR_ROUTE。


```c title="append_to_reply 用法"
...
append_to_reply("Foo: bar\r\n");
append_to_reply("Foo: $rm at $Ts\r\n");
...
```


#### append_body_to_reply(txt)


将 'txt' 作为内容追加到将为该请求生成的所有回复中。


多次调用将覆盖已设置的内容。


注意：该函数不会添加任何 Content-Type 头部来匹配内容，
		因此您应该使用 "append_to_reply()" 来执行此操作。


参数含义如下：


- *txt (string)* - SIP 回复的内容


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、
		BRANCH_ROUTE 和 ERROR_ROUTE。


```c title="append_to_reply 用法"
...
append_body_to_reply( $var(sdp_body) );
...
```


#### append_hf(txt[, hdr_anchor])


在最后一个头部字段后追加 'txt' 作为头部。如果提供了 'hdr_anchor'，
		'txt' 将追加到 'hdr_anchor' 第一次出现之后。


参数含义如下：


- *txt (string)* - 要追加的头部字段。
- *hdr_anchor (string, 可选)* - 'txt' 将追加到其后的头部名称。


注意：在主路由中添加的头部在后续路由中无法删除
	（例如故障路由）。因此，不要在那里添加任何您以后可能想要删除的头部。
	要临时添加头部，请使用分支路由，因为在那里所做的更改是按分支进行的。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="append_hf 用法"
...
append_hf("P-hint: VOICEMAIL\r\n");
append_hf("From-username: $fU\r\n");
append_hf("From-username: $fU\r\n", "Call-ID");
...
```


#### insert_hf(txt)


在第一个头部字段前插入 'txt' 作为头部。


参数含义如下：


- *txt (string)* - 要插入的头部字段。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="insert_hf 用法"
...
insert_hf("P-hint: VOICEMAIL\r\n");
insert_hf("To-username: $tU\r\n");
...
```


#### insert_hf(txt, hdr)


在第一个 'hdr' 头部字段前插入 'txt'。


参数含义如下：


- *txt (string)* - 要插入的头部字段。
- *hdr (string, 可选)* - 'txt' 将插入到其前的头部名称。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="insert_hf 用法"
...
insert_hf("P-hint: VOICEMAIL\r\n", "Call-ID");
insert_hf("To-username: $tU\r\n", "Call-ID");
...
```


#### append_urihf(prefix, suffix)


追加包含原始 Request-URI 的头部字段名称，中间是 RURI。


参数含义如下：


- *prefix* - 字符串（通常至少是头部字段名称）。
- *suffix* - 字符串（通常至少是行终止符）。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE
		和 BRANCH_ROUTE。


```c title="append_urihf 用法"
...
append_urihf("CC-Diversion: ", "\r\n");
...
```


#### is_present_hf(hf_name)


如果消息中存在某个头部字段，则返回 true。


> [!注意]
> 该函数还能识别紧凑名称。例如 "From" 会与 "f" 匹配。


参数含义如下：


- *hf_name (string)* - 头部字段名称（长形式或紧凑形式）。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="is_present_hf 用法"
...
if (is_present_hf("From")) log(1, "From HF Present");
...
```


#### append_time()


在请求的回复中添加时间头部。您必须在可能发送回复的函数之前使用它，
		例如 'registrar' 模块的 save()。
	头部格式为："Date: %a, %d %b %Y %H:%M:%S GMT"，含义如下：


- *%a* 星期名称缩写（ locale）
- *%d* 月份中的日期作为十进制数
- *%b* 月份名称缩写（ locale）
- *%Y* 带世纪的年份
- *%H* 小时
- *%M* 分钟
- *%S* 秒


如果成功追加了头部，则返回 true。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、
		BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="append_time 用法"
...
append_time();
...
```


#### is_method(name)


检查消息的方法是否与名称匹配。
如果名称是已知方法（invite、cancel、ack、bye、options、info、update、register、
		message、subscribe、notify、refer、prack），
		则该函数执行方法 ID 测试（整数比较）而不是忽略大小写的字符串比较。


'name' 可以是列表形式的方法：'method1|method2|...'。
在这种情况下，如果 SIP 消息的方法是列表中的一个，函数返回 true。
重要提示：列表中只能包含在 OpenSIPS 中定义了 ID 的方法（invite、cancel、ack、
		bye、options、info、update、register、message、subscribe、notify、
		refer、prack、publish；更多请参见：
		[https://www.iana.org/assignments/sip-parameters](https://www.iana.org/assignments/sip-parameters))。


如果是用于回复，函数测试 CSeq 头中的方法字段值。


参数含义如下：


- *name (string)* - SIP 方法名称


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="is_method 用法"
...
if(is_method("INVITE"))
{
    # 在此处理 INVITE
}
if(is_method("OPTION|UPDATE"))
{
    # 在此处理 OPTION 和 UPDATE
}
...
```


#### remove_hf(hname)


从消息中删除所有名称为 "hname" 的头部


如果找到并删除了至少一个头部，则返回 true。


参数含义如下：


- *hname (string)* - 要删除的头部名称。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="remove_hf 用法"
...
if(remove_hf("User-Agent"))
{
    # User Agent 头部已删除
}
...
```


#### remove_hf_re(hname_expr)


从消息中删除所有匹配 "hname_expr" POSIX 正则表达式的头部。


如果找到并删除了至少一个头部，则返回 true。


参数含义如下：


- *hname_expr (string)* - 正则表达式。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="remove_hf_re 用法"
...
remove_hf_re("^X-g.+[0-9]");
...
```


#### remove_hf_glob(hname_pattern)


从消息中删除所有匹配 "hname_pattern" glob 模式的头部。


如果找到并删除了至少一个头部，则返回 true。


参数含义如下：


- *hname_pattern (string)* - glob 模式


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="remove_hf_glob 用法"
...
# 删除 X-Billing-Account、X-Billing-Price、X-Billing-rateplan 等
remove_hf_glob("X-Billing*");
...
```


#### has_totag()


检查 To 头部字段 URI 是否包含 tag 参数。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="has_totag 用法"
...
if (has_totag()) {
	...
};
...
```


#### ruri_has_param(param[,value])


查找 Request URI 是否有给定参数。如果没有给定值，
		函数将查找没有值的参数，否则将搜索具有匹配值的参数。


参数含义如下：


- *param (string)* - 要查找的参数名称。
- *value (string, 可选)* - 要匹配的参数值。


此函数可用于 REQUEST_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="ruri_has_param 用法"
...
if (ruri_has_param("user","phone")) {
	...
};
...
```


#### ruri_add_param(param)


向 RURI 添加格式为 "name=value" 的 URI 参数。


参数含义如下：


- *param (string)* - 要以 "name=value" 格式追加的参数。


此函数可用于 REQUEST_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="ruri_add_param 用法"
...
ruri_add_param("nat=yes");
...
```


#### ruri_del_param(param)


从当前 SIP 消息的 Request-URI 中删除参数、它的值以及任何前导 ";"。


参数含义如下：


- *param (string)* - 要删除的参数


成功删除返回 **1**，否则返回 **-1**。


此函数可用于 REQUEST_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="ruri_del_param 用法"
...
ruri_del_param("user");
...
```


#### ruri_tel2sip()


如果 RURI 是 tel URI，则将其转换为 SIP URI。
仅当转换成功或不需要转换（如 RURI 不是 tel URI）时返回 true。


此函数可用于 REQUEST_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="ruri_tel2sip 用法"
...
ruri_tel2sip();
...
```


#### is_uri_user_e164(uri)


检查给定 URI 的用户名部分是否是 E164 号码。


参数含义如下：


- *uri (string)* - 一个 SIP URI


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE
		和 LOCAL_ROUTE。


```c title="is_uri_user_e164 用法"
...
if (is_uri_user_e164($fu)) {  # 检查 From 头部 URI 用户部分
   ...
}
if (is_uri_user_e164($avp(uri)) {
   # 检查存储在 avp uri 中的 URI 的用户部分
   ...
};
...
```


#### has_body_part([mime])


如果 SIP 消息具有给定 MIME 的任何内容部分，则函数返回 *true*。
如果没有给出 MIME，如果找到至少一个内容部分（具有任何 MIME），它将返回 true。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="has_body_part 用法"
...
if(has_body_part("application/sdp"))
{
    # 在此执行有趣的操作
}
...
```


#### is_audio_on_hold()


如果 SIP 消息附加了 SDP 内容并且至少有一个音频流处于保持状态，
		则函数返回 *true*。
函数的返回代码指示检测到的保持类型：


- *1* - RFC2543 保持类型：
			检测到空连接 IP
- *2* - RFC3264 保持类型：
			检测到 inactive 或 sendonly 属性


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="is_audio_on_hold 用法"
...
if(is_audio_on_hold())
{
    switch ($rc) {
    case 1:
        # RFC2543 保持类型
    	# 在此执行有趣的操作
        break;
    case 2:
        # RFC3264 保持类型
    	# 在此执行有趣的操作
        break;
}
...
```


#### is_privacy(privacy_type)


如果 SIP 消息包含 Privacy 头部字段且其隐私值中包含给定的 privacy_type，
		则函数返回 *true*。
有关可能的隐私类型值，请参见
				[https://www.iana.org/assignments/sip-parameters/sip-parameters.xhtml#sip-parameters-8](https://www.iana.org/assignments/sip-parameters/sip-parameters.xhtml#sip-parameters-8)。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="is_privacy 用法"
...
if(is_privacy("id"))
{
    # 在此执行有趣的操作
}
...
```


#### remove_body_part([mime[, revert]])


从消息体中删除所有具有给定 mime 的内容部分。
Content-Type 和 Content-Length 头部的必要更正会自动完成。


如果给出了 MIME 类型，它将仅删除具有该 mime 的内容部分。
如果没有给出 MIME，则所有部分（整个内容）都将被删除。


参数含义如下：


- *mime (string, 可选)* - 要与内容部分检查的 MIME 类型；
				如果未给出，所有部分都将被删除；
- *revert (string, 可选)* - 仅在指定了 MIME 时有用。
				如果在此处给出 "revert" 字符串，
				函数将删除除具有给定 MIME 之外的所有内容部分。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="remove_body_part() 用法"
...
# 删除整个消息内容（所有部分）
remove_body_part();
# 删除所有 MIME 为 "application/isup" 的内容部分
remove_body_part("application/isup");
# 删除除 "application/sdp" 之外的所有内容部分
remove_body_part("application/sdp","revert")
...
```


#### add_body_part(body, mime[, headers])


此函数可用于向消息体添加新的内容部分。
如果已存在另一个部分，消息体将自动转换为多部分内容。


参数含义如下：


- *body (string)* - 要添加的内容部分的内容
- *mime (string)* - 要添加的内容部分的 mime 字符串
- *headers (string, 可选)* - 可选的 SIP 头部列表
			（完全定义，包括头部分隔符），将推送到此部分中
			位于 *Content-Type* 头部旁边。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="add_body_part 用法"
...
add_body_part("Hello World!", "text/plain");
...
```


#### get_updated_body_part( [mime], variable)


此函数将重新生成的内容部分返回到一个变量中，
		意味着内容部分已应用了迄今为止由 OpenSIPS 进行的所有更改。
	如果您想对内容部分执行一系列操作，
	并且某些操作要求应用所有先前的更改（如首先执行一些编解码器相关的更改，
	然后再进行 rtpengine 插入），这很有帮助。


注意：实际的 SIP 消息不会因此操作而受到影响！


参数含义如下：


- *mime (string)* - 要重新生成并返回的内容的 mime 字符串。
			如果缺失，整个内容（及其所有部分）将被重新生成。
- *variable* - 用于返回重新生成的内容部分（作为文本）的变量。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="get_updated_body_part 用法"
...
	codec_delete_re("PCMA|PCMU");

	get_updated_body_part( "application/sdp", $var(new_sdp));

	xlog("------ 更新的 SDP 是 ----\n$var(new_sdp)\n-----------\n");
	exit;
...
```


#### sipmsg_validate([flags[, result_pvar]])


如果 SIP 消息根据 SIP RFC3261 正确构建，则函数返回 *true*。
它验证每个请求/回复的必需头部，还可以检查头部内容的格式。


flags 参数是可选的，可以由以下值组成：


- *'s'* - 检查 SDP 内容的完整性（如果存在）
- *'h'* - 检查每个头部内容的格式和完整性。
- *'m'* - 不检查 Max-Forwards 头部。
- *'r'* - 检查 R-URI 及其域名是否包含有效字符。
- *'f'* - 检查 'From' 字段的 URI 及其域名是否包含有效字符。
- *'t'* - 检查 'To' 字段的 URI 及其域名是否包含有效字符。
- *'c'* - 检查 'Contact' 字段的值及其是否是一个 URI，
				对于设置了 Expires 头部的 REGISTER 请求为 Star。


result_pvar 参数在负面结果时设置包含文本错误原因的 pvar 变量，
			便于日志记录或将拒绝原因返回给有问题的 UA。


此函数可以返回以下代码：


- *1* - 消息符合 RFC3261 并已成功验证。
- *-1* - 无 SIP 消息
- *-2* - 头部解析错误
- *-3* - 无 Call-ID 头部
- *-4* - 对于需要它的传输没有 Content-Length 头部（例如 TCP）
- *-5* - 无效的 Content-Length，与实际内容大小不同
- *-6* - SDP 内容解析错误。
- *-7* - 无 Cseq 头部。
- *-8* - 无 From 头部。
- *-9* - 无 To 头部。
- *-10* - 无 Via 头部。
- *-11* - Request URI 解析错误。
- *-12* - R-URI 中的主机名格式错误。
- *-13* - 无 Max-Forwards 头部。
- *-14* - 无 Contact 头部。
- *-15* - 非 Register 请求的 Path 用户。
- *-16* - 405 回复中无 Allow 头部。
- *-17* - 423 回复中无 Min-Expire 头部。
- *-18* - 407 回复中无 Proxy-Authorize 头部。
- *-19* - 420 回复中无 Unsupported 头部。
- *-20* - 401 回复中无 WWW-Authorize 头部。
- *-21* - 无 Content-Type 头部
- *-22* - To 头部解析错误
- *-23* - To 头部中的主机名格式错误
- *-24* - From 头部解析错误
- *-25* - From 头部中的主机名格式错误
- *-26* - Contact 头部解析错误
- *-27* - URI 用户名格式错误
- *-28* - From URI 用户名格式错误
- *-29* - To URI 用户名格式错误
- *-30* - 非 Register 请求的 Contact 头部包含 *
- *-255* - 未定义的错误。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE 和 BRANCH_ROUTE。


```c title="sipmsg_validate 用法"
...
if(!sipmsg_validate())
{
	send_reply(400, "Bad Request");
	exit;
}
...

...
# 还检查 SDP 和头部内容
if(!sipmsg_validate("sh", $var(err_reason)))
{
	send_reply(400, "Bad Request/Body");
	exit;
}
...

...
# 检查 200 Ok 回复的 Contact 头部，并在为 * 时记录
if(!sipmsg_validate("c"))
{
	if ($rc == -30)
		xlog("发现无效的 * Contact 头部\n");
}
...
```


#### codec_exists (name[, clock])


此函数可用于验证 SDP 内容中是否存在编解码器。
它将在所有 SDP 会话的所有流中搜索编解码器。
如果在任何地方找到，它将返回 TRUE，否则返回 FALSE。


参数：


- *name* (string) - 参数不区分大小写。
- *clock* (string, 可选) - 如果未提供，
				任何时钟速率都将匹配。参数不区分大小写。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="codec_exists 用法"
...
codec_exists("speex");
或
codec_exists("GSM", "8000");
...
```


#### codec_delete(name[, clock])


此函数可用于从 SDP 内容中删除编解码器。
它将在所有 SDP 会话的所有流中搜索编解码器。
如果在任何地方找到，它将从映射 ("a=...") 和索引列表 ("m=...") 中删除它。
如果发生任何删除则返回 TRUE，否则返回 FALSE。


- *name* (string) - 参数不区分大小写。
- *clock* (string, 可选) - 如果未提供，
				任何时钟速率都将匹配，所有编解码器都将被删除。参数不区分大小写。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="codec_delete 用法"
...
codec_delete("speex");
或
codec_delete("GSM", "8000");
...
```


#### codec_move_up(name[, clock])


此函数可用于将编解码器在索引列表 ("m=...") 中上移。
它将在所有 SDP 会话的所有流中搜索编解码器。
如果在任何地方找到，它将被移动到索引列表的顶部。
如果发生任何移动则返回 TRUE，否则返回 FALSE。


- *name* (string) - 参数不区分大小写。
- *clock* (string, 可选) - 如果未提供，
				任何时钟速率都将匹配，所有编解码器
				将被移动到前面，同时保持其原始顺序。
				参数不区分大小写。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="codec_move_up 用法"
...
codec_move_up("speex");
或
codec_move_up("GSM", "8000");
...
```


#### codec_move_down(name[, clock])


此函数可用于将编解码器在索引列表 ("m=...") 中下移。
它将在所有 SDP 会话的所有流中搜索编解码器。
如果在任何地方找到，它将被移动到索引列表的底部。
如果发生任何移动则返回 TRUE，否则返回 FALSE。
第二个参数是可选的，
如果未提供，任何时钟速率都将匹配，所有编解码器
将被移动到底部，同时保持其原始顺序。
参数不区分大小写。


- *name* (string) - 参数不区分大小写。
- *clock* (string, 可选) - 如果未提供，
				任何时钟速率都将匹配，所有编解码器
				将被移动到底部，同时保持其原始顺序。
				参数不区分大小写。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="codec_move_down 用法"
...
codec_move_down("speex");
或
codec_move_down("GSM", "8000");
...
```


```c title="codec_move_down 用法"
...
/*
  此示例将把 speex 与 8000 编解码器移动到列表末尾，
  然后删除 GSM 与 8000 时钟，最后将所有 speex 编解码器移动到列表前面。
  Speex/8000 将在任何其他 speex 之后。
*/
codec_move_down("speex", "8000");
codec_delete("GSM", "8000");
codec_move_up("speex");
...
```


#### codec_exists_re ( regexp )


此函数具有与 codec_exists 相同的效果（没有 clock 参数），
		唯一区别是它接受 POSIX 正则表达式作为参数。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="codec_exists_re 用法"
...
codec_exists_re("sp[a-z]*");
...
```


#### codec_delete_re ( regexp )


此函数具有与 codec_delete 相同的效果（没有 clock 参数），
		唯一区别是它接受 POSIX 正则表达式作为参数。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="codec_delete_re 用法"
...
codec_delete_re("PCMA|PCMU");
...
```


#### codec_delete_except_re ( regexp )


此函数删除除正则表达式指定之外的所有编解码器。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="codec_delete_except_re 用法"
...
codec_delete_except_re("PCMA|PCMU");#将删除除 PCMA 和 PCMU 之外的所有编解码器
...
```


#### codec_move_up_re ( regexp )


此函数具有与 codec_move_up 相同的效果（没有 clock 参数），
		唯一区别是它接受 POSIX 正则表达式作为参数。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="codec_move_up_re 用法"
...
codec_move_up_re("sp[a-z]*");
...
```


#### codec_move_down_re ( regexp )


此函数具有与 codec_move_down 相同的效果（没有 clock 参数），
		唯一区别是它接受 POSIX 正则表达式作为参数。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="codec_move_down_re 用法"
...
codec_move_down_re("sp[a-z]*");
...
```


```c title="codec_move_down 用法"
...
/*
  此示例将把 speex 与 8000 编解码器移动到列表末尾，
  然后删除 GSM 与 8000 时钟，最后将所有 speex 编解码器移动到列表前面。
  Speex/8000 将在任何其他 speex 之后。
*/
codec_move_down("speex","8000");
codec_delete("GSM","8000");
codec_move_up("speex");
...
```


#### change_reply_status(code, reason)


拦截 SIP 回复（在任何 onreply_route 中）并在传播之前更改其状态码和原因短语。


参数含义如下：


- *code (int)* - 状态码。
- *reason (string)* - 原因短语。


此函数可用于 ONREPLY_ROUTE。


```c title="change_reply_status 用法"
...
onreply_route {
    if ($rs == "603") {
        change_reply_status(404, "Not Found");
        exit;
    }
}
...

```


#### stream_exists(regexp[,regexp2])


此函数可用于验证 SDP 内容中是否存在流。
它将在所有 SDP 会话中搜索流。
如果在任何地方找到则返回 TRUE，否则返回 FALSE。


参数含义如下：


- *regexp* - 用于匹配流媒体名称的 POSIX 正则表达式
- *regexp2* - 用于匹配流传输名称的可选 POSIX 正则表达式


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="stream_exists 用法"
...
# 检查 FAX
stream_exists("image");
...
stream_exists("audio","SAVP");
...
```


#### stream_delete(regexp[,regexp2])


此函数可用于从 SDP 内容中删除整个流。
它将在所有 SDP 会话中搜索流。
如果在任何地方找到，它将连同所有属性一起被删除。
如果发生任何删除则返回 TRUE，否则返回 FALSE。


参数含义如下：


- *regexp* - 用于匹配流媒体名称的 POSIX 正则表达式
- *regexp2* - 用于匹配流传输名称的可选 POSIX 正则表达式


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="stream_delete 用法"
...
# 防止使用视频
stream_delete("video");
...
```


#### list_hdr_has_option(hdr_name, option)


检查并返回给定选项/令牌是否列在给定头部的正文中。
该头部的正文必须格式化为令牌/选项的 CSV 列表
（如 Supported、Require、Content-Disposition 头部）的正文格式


参数含义如下：


- *hdr_name (string)* - 要检查的头部的名称。
		请注意，将检查该头部的所有实例（如果 SIP 消息中该头部有多个实例）。
		支持任何类型的头部名称 - RFC3261 标准、RFC 扩展或自定义名称。
- *opt (string)* - 要搜索的选项/令牌。


如果在其中一个头部实例中找到该选项，函数返回 true。
如果没有找到头部，如果未找到该选项，或者如果存在解析或运行时错误，将返回 false。
此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="list_hdr_has_option 用法"
...
# 检查是否广告了 100rel
if (list_hdr_has_option("Supported", "100rel"))
	xlog("找到 100rel 选项\n");
...
```


#### list_hdr_add_option(hdr_name, option)


在给定头部的正文列表末尾添加新选项/令牌。
该头部的正文必须格式化为令牌/选项的 CSV 列表
（如 Supported、Require、Content-Disposition 头部）正文格式


可以对同一个头部执行多次添加/删除操作。


参数含义如下：


- *hdr_name (string)* - 要添加选项的头部的名称。
		如果该头部在 SIP 消息中有多个实例，
		添加将在第一个实例上执行。
		支持任何类型的头部名称 - RFC3261 标准、RFC 扩展或自定义名称。
- *opt (string)* - 要添加到 CSV 列表的选项/令牌。
		请注意，不会验证重复项（如果新添加的选项不在头部中）。


如果选项成功添加到给定头部的列表中，函数返回 true。
如果没有找到头部，或者如果存在解析或运行时错误，将返回 false。
此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="list_hdr_add_option 用法"
...
# 添加 100rel 用于广告
if (!list_hdr_has_option("Supported", "100rel"))
    list_hdr_add_option("Supported", "100rel");
```


#### list_hdr_remove_option(hdr_name, option)


从给定头部的正文中移除列表内的选项/令牌。
该头部的正文必须格式化为令牌/选项的 CSV 列表
（如 Supported、Require、Content-Disposition 头部）的正文格式


可以对同一个头部执行多次添加/删除操作。


参数含义如下：


- *hdr_name (string)* - 要从中移除选项的头部的名称。
		如果该选项在同一头部中重复，只有最后一个会被移除。
		如果该头部在 SIP 消息中有多个实例，
		移除将在所有实例上执行。
		支持任何类型的头部名称 - RFC3261 标准、RFC 扩展或自定义名称。
- *opt (string)* - 要从 CSV 列表中移除的选项/令牌。
		请注意，如果这是头部中唯一的选项，整个头部将被移除。


如果选项成功从至少一个头部实例中移除，函数返回 true。
如果没有找到头部，或者该令牌未找到，或者如果存在解析或运行时错误，将返回 false。
此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="list_hdr_remove_option 用法"
...
# 添加 100rel 用于广告
if (list_hdr_has_option("Supported", "100rel"))
    list_hdr_remove_option("Supported", "100rel");
list_hdr_add_option("Supported", "optionX");
```


#### get_glob_headers_values(hdr_name_glob, hdr_names_avp,hdr_vals_avp)


用与 hdr_name_glob 模式匹配的所有头部名称和值填充 hdr_names_avp 和 hdr_vals_avp AVP。


参数含义如下：


- *hdr_name_glob (string)* - 用于匹配头部名称的 glob 模式
- *hdr_names_avp (var)* - 将填充所有与 glob 模式匹配的头部名称的 AVP
- *hdr_vals_avp (var)* - 将填充与 glob 模式匹配的头部名称对应的所有头部值的 AVP


如果找到至少 1 个与 glob 模式匹配的头部，函数返回 true；
如果未找到匹配，则返回 false。
此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="get_glob_headers_values 用法"
...
       if (get_glob_headers_values("X-*",$avp(names),$avp(values))) {
           xlog("所有 X- 名称是 $(avp(names)[*])，X- 值是 $(avp(values)[*])\n");
       }
...
```


#### sip_to_json(out_var)


返回当前 SIP 消息的 JSON 格式表示，包含 first_line、headers 和 body json 成员。
		当您想要将通用 SIP 消息传递给 SIP 不可知的实体时很有用，
		但在发送完整消息之前仍想提供一定程度的 SIP 解析。


参数含义如下：


- *out_var (string)* - 输出 JSON 格式的 SIP 消息变量


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、
		FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="sip_to_json 用法"
...
       if (sip_to_json($var(out_sip_json))) {
           xlog("当前 SIP 消息的 JSON 格式是 $var(out_sip_json) \n");
       }
...
```


### 已知限制


搜索函数应用于当前消息，因此
		对 sdp 的修改将对 codec_exists 函数可见
		（例如在调用 codec_delete("speex") 后，
		codec_exists("speex") 将返回 false）。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可证 4.0 版授权
