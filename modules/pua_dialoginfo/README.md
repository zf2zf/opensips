---
title: "pua dialoginfo"
description: "pua_dialoginfo 从 dialog 模块检索 dialog 状态信息，并使用 pua 模块 PUBLISH 对话信息。因此，结合 presence_xml 模块，这可用于从 dialog 模块获取 dialog-info 并 NOTIFY 订阅的 watchers 关于 dialog-info 的变化。这可用于例如 SNOM 和 Linksys 电话。"
---

## 管理指南


### 概述


pua_dialoginfo 从 dialog 模块检索 dialog 状态信息，并使用 pua 模块 PUBLISH 对话信息。因此，结合 presence_xml 模块，这可用于从 dialog 模块获取 dialog-info 并 NOTIFY 订阅的 watchers 关于 dialog-info 的变化。这可用于例如 SNOM 和 Linksys 电话。


注意：这根据 RFC 4235 实现 dialog-info，与 draft-anil-sipping-bla-03.txt 中定义的 BLA 功能不兼容。
（实际上 BLA 草案很糟糕，因为它改变了 SIP 语义）


该模块基于（复制/粘贴）pua_usrloc 和 nat_traversal 模块的代码。


下面您将看到从 RFC 4235 中提取的一些 dialog-info XML 文档示例。这将帮助您理解模块参数的含义：


```c
<?xml version="1.0"?>
<dialog-info xmlns="urn:ietf:params:xml:ns:dialog-info"
             version="1"
             state="full"
             entity="sip:alice@example.com">
    <dialog id="as7d900as8" 
            call-id="a84b4c76e66710"
            local-tag="1928301774" 
            remote-tag="456887766"
            direction="initiator">
        <state>early</state>
    </dialog>
</dialog-info>
```


根元素是"dialog-info"。它包含命名空间、版本（必须为每个新的 PUBLISH 递增）、状态（此模块仅支持 state=full）以及我们要发布 dialog-info 的实体。


"dialog"元素必须包含 id 参数。id 参数通常与可选的 call-id 参数（INVITE 请求的 call-id）不同，因为一个 INVITE 可以创建多个 dialog（分叉请求）。但是由于 dialog 模块不支持由单个事务创建的多个 dialog，pua_dialoginfo 模块将 id 参数设置为与 call-id 参数相同的值。"local-tag"表示本端 tag。"remote-tag"表示远端的 tag。"direction"表示该实体是 dialog 的发起者还是接收者（即该实体是发送还是接收第一个 INVITE）。


"state"元素描述了 dialog 状态机的状态，必须是以下之一：trying、proceeding、early、confirmed 或 terminated。


dialog 元素可以包含可选的"local"和"remote"元素，用于更详细地描述本地和远端方，例如：


```c
<?xml version="1.0" encoding="UTF-8"?>
<dialog-info xmlns="urn:ietf:params:xml:ns:dialog-info"
             version="1" state="full">
    <dialog id="as7d900as8" 
            call-id="a84b4c76e66710"
            local-tag="1928301774" 
            remote-tag="456887766"
            direction="initiator">
        <state>early</state>
        <local>
            <identity display="Alice">sip:alice@example.com</identity>
            <target uri="sip:alice@phone11.example.com"/>
        </local>
        <remote>
            <identity display="Bob">sip:bob@example.org</identity>
            <target uri="sip:bobster@phone21.example.org"/>
        </remote>
    </dialog>
</dialog-info>
```


local 和 remote 元素需要实现呼叫拾取。例如，如果上述 XML 文档被订阅了 Alice 的 dialog-info 的某人收到，那么它可以通过向 Bob 发送包含 Replaces 头部的 INVITE（实际上我不确定它应该使用 identity 元素中的 URI 还是 target 参数中的 URI）来拾取呼叫，该 Replaces 头部包含 call-id 和 tags。这已在 Linksys SPA962 电话和 SNOM 320 固件 7.3.7（您必须将功能键设置为"Extension"）上成功测试。


dialog-info XML 文档可以包含多个"dialog"元素，例如如果实体有多个进行中的 dialog。以下 XML 文档显示了一个已确认的 dialog 和一个 early（可能是第二个来电）的 dialog。


```c
<?xml version="1.0"?>
<dialog-info xmlns="urn:ietf:params:xml:ns:dialog-info"
             version="3"
             state="full"
             entity="sip:alice@example.com">
    <dialog id="as7d900as8" call-id="a84b4c76e66710"
            local-tag="1928301774" remote-tag="hh76a"
            direction="initiator">
        <state>confirmed</state>
    </dialog>
    <dialog id="j7zgt54" call-id="ASDRRVASDRF"
            local-tag="123456789" remote-tag="EE345"
            direction="recipient">
        <state>early</state>
    </dialog>
</dialog-info>
```


要为某个 dialog 启用 dialoginfo 通知，必须为该 dialog 调用 [dialoginfo set](#func_dialoginfo_set) 函数。
此函数可以接受一个参数，通过该参数可以告诉模块仅为呼叫的一方发布 dialoginfo。这很有用，因为您可能只想为本地用户存储 dialoginfo，并且您可以从脚本中判断呼叫方是否是本地用户，并为此函数提供正确的参数以告诉它仅为本地用户生成 dialoginfo。可能的值为："A" - 仅为主叫方生成 dialoginfo，"B" - 仅为主叫方生成 dialoginfo。如果未给出参数，模块将为双方生成 dialoginfo。

可以通过在调用 [dialoginfo set](#func_dialoginfo_set) 函数之前设置名为"caller_spec_param"和"callee_spec_param"模块参数的伪变量来指定应为主叫方和被叫方使用的 URI。
请在[导出参数](#exported_parameters)部分中阅读这些参数的描述。如果未设置这些参数，将使用默认值：主叫方使用 From 头部，被叫方使用 To 头部的显示名称 + RURI。


由于 dialog 模块回调仅针对某个特定 dialog，pua_dialoginfo 始终 PUBLISH 包含单个"dialog"元素的 XML 文档。如果一个实体有多个并发的 dialog，pua_dialoginfo 模块将为每个 dialog 发送 PUBLISH。这些多个"presentities"可以被 presence_dialoginfo 模块聚合成包含多个"dialog"元素的单个 XML 文档。请参阅 presence_dialoginfo 模块的描述以了解聚合的详细信息。


如果 dialog 模块的回调出现问题且您想调试它们，请在 pua_dialoginfo.c 中定义 PUA_DIALOGINFO_DEBUG 并重新编译。


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *dialog*。
- *pua*。


#### 外部库或应用程序


在运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *libxml*。


### 导出的参数


#### include_callid (int)


如果设置此参数，可选的 call-id 将被放入 dialog 元素中。这用于呼叫拾取功能。


默认值为 "1"。


```c title="设置 include_callid 参数"
...
modparam("pua_dialoginfo", "include_callid", 0)
...
```


#### include_tags (int)


如果设置此参数，本地和远程 tag 将被放入 dialog 元素中。这用于呼叫拾取功能。


默认值为 "1"。


```c title="设置 include_tags 参数"
...
modparam("pua_dialoginfo", "include_tags", 0)
...
```


#### include_localremote (int)


如果设置此参数，可选的 local 和 remote 元素将被放入 dialog 元素中。这用于呼叫拾取功能。


默认值为 "1"。


```c title="设置 include_localremote 参数"
...
modparam("pua_dialoginfo", "include_localremote", 0)
...
```


#### caller_confirmed (int)


通常主叫方的 dialog-info 将是"trying -> early -> confirmed"，而被叫方的 dialog-info 将是"early -> confirmed"。在某些电话上，功能 LED 将在 early 状态时开始闪烁，无论它是主叫方还是被叫方（由"direction"参数指示）。
为避免主叫方的 LED 闪烁，您可以启用此参数。然后即使在"early"状态，主叫方的状态也将显示为"confirmed"。这是针对有问题的 Linksys SPA962 电话的解决方法。SNOM 电话使用默认设置效果良好。


默认值为 "0"。


```c title="设置 caller_confirmed 参数"
...
modparam("pua_dialoginfo", "caller_confirmed", 1)
...
```


#### publish_on_trying (int)


通常主叫方的 dialog-info 将是"trying -> early -> confirmed"。"trying"状态将在您对主叫方调用 [dialoginfo set](#func_dialoginfo_set) 时立即触发，而"early"在被叫方振铃时触发（通过 180 或 183 临时回复触发）。
有时，只在被叫方达到 early 状态时收到通知而不是之前是可取的。在其他情况下，通知 early 状态是可取的。此设置允许控制行为。


此参数的预期用途是减少通知速率（请参阅 RFC4235，第 3.10 节通知速率）。


默认值为 "0"。


```c title="将 publish_on_trying 参数设置为 0"
...
modparam("pua_dialoginfo", "publish_on_trying", 0)

# 成功呼叫场景：
#
# UAC       proxy       UAS     presence server
#  |--INVITE->|          |            |
#  |<-100-----|--INVITE->|            |
#  |          |<-100-----|            |
#  |          |          |            |
#  |          |<-18x-----|            |
#  |<-18x-----|--PUBLISH(early)------>|
#  |          |          |            |
#  |          |<-200-----|            |
#  |<-200-----|--PUBLISH(confirmed)-->|
#  |--ACK---->|          |            |
#  |          |--ACK---->|            |
#  |          |          |            |
#
#
# 不成功呼叫场景：
#
# UAC       proxy       UAS     presence server
#  |--INVITE->|          |            |
#  |<-100-----|--INVITE->|            |
#  |          |<-100-----|            |
#  |          |          |            |
#  |          |<-456xx---|            |
#  |<-456xx---|--ACK---->|            |
#  |--ACK---->|          |            |
...
```


```c title="将 publish_on_trying 参数设置为 1"
...
modparam("pua_dialoginfo", "publish_on_trying", 1)

# 成功呼叫场景：
#
# UAC       proxy       UAS     presence server
#  |--INVITE->|          |            |
#  |<-100-----|--INVITE->|            |
#  |          |--PUBLISH(trying)----->|
#  |          |<-100-----|            |
#  |          |          |            |
#  |          |<-18x-----|            |
#  |<-18x-----|--PUBLISH(early)------>|
#  |          |          |            |
#  |          |<-200-----|            |
#  |<-200-----|--PUBLISH(confirmed)-->|
#  |--ACK---->|          |            |
#  |          |--ACK---->|            |
#  |          |          |            |
#
#
# 不成功呼叫场景：
#
# UAC       proxy       UAS     presence server
#  |--INVITE->|          |            |
#  |<-100-----|--INVITE->|            |
#  |          |--PUBLISH(trying)----->|
#  |          |<-100-----|            |
#  |          |          |            |
#  |          |<-456xx---|            |
#  |          |--PUBLISH(terminated)->|
#  |<-456xx---|--ACK---->|            |
#  |--ACK---->|          |            |
...
```


#### nopublish_flag (str)


默认情况下，reINVITE 将触发 PUBLISH。它们实际上是唯一有意义的 in-dialog 请求。
在某些情况下，重新发布 dialog 状态没有意义。（例如处理 B2BUA reINVITE 时）。
此设置定义了在请求路由中需要设置的 flag，以防止特定 reINVITE 情况下生成 PUBLISH 请求。


```c title="设置 nopublish_flag 参数"
...
modparam("pua_dialoginfo", "nopublish_flag", "no_publish")
...
```


#### presence_server (string)


presence 服务器的地址，PUBLISH 消息应发送到的位置（非强制）。


```c title="设置 presence_server 参数"
...
modparam("pua_dialoginfo", "presence_server", "sip:ps@opensips.org:5060")
...
```


#### caller_spec_param (string)


将保存自定义主叫方 URI 的伪变量名称。
如果未设置此变量，则使用 From 头部中的信息。
如果您想使用其他主叫方定义，必须在调用 [dialoginfo set](#func_dialoginfo_set) 函数之前填充此伪变量。字符串格式类似于 To/From SIP 头部的格式：
"display_name<sip_uri>" 或 "sip_uri"。


```c title="设置 caller_spec_param 参数"
...
modparam("pua_dialoginfo", "caller_spec_param", "$avp(10)")
...
		
```


#### callee_spec_param (string)


将保存被叫方 URI 的伪变量名称。
如果未设置此变量，则使用的被叫方信息由 To 显示 URI + RURI 组成。设置此伪变量的字符串格式与 caller_spec_param 部分中描述的格式相同。


```c title="设置 caller_spec_param 参数"
...
modparam("pua_dialoginfo", "callee_spec_param", "$avp(11)")
...
		
```


#### osips_ps (int)


建议通过将此参数设置为 0 来指定是否使用与 OpenSIPS presence 服务器不同的 presence 服务器。
默认情况下，在与 OpenSIPS Presence Server 一起工作时使用一个技巧（Publish body 中的版本设置为'0000000'）以加快处理速度，这可能不被其他 presence 服务器接受。


默认值为 "1"。


```c title="设置 osips_ps 参数"
...
modparam("pua_dialoginfo", "osips_ps", 0)
...
		
```


### 导出的函数


#### dialoginfo_set([side])


必须为初始化 dialog 的 INVITE 消息调用此函数，以便发布该 dialog 的 dialoginfo 信息。


参数含义：


- *side* (string, optional) - 可以是"A"或"B"仅为主叫方或被叫方 PUBLISH - 如果缺失，双方都将被发布。


```c title="dialoginfo_set 用法"
...
	if(is_method("INVITE"))
		if($ru =~ "opensips.org")
			dialoginfo_set();
...
	
```


#### dialoginfo_set_branch_callee(callee)


此函数仅从分支路由使用，用于设置每个分支的被叫方/对等方规范。此对等值将仅用于为该特定分支创建的 dialoginfo 记录。


此函数仅在呼叫分叉（串行/并行）场景中有意义，在这些场景中，主叫方可能与多个不同的被叫方相关联。


参数含义：


- *callee* (string) - 被叫方的 SIP nams addr 描述（name_addr 格式是'[display] <uri>' 或 'uri'，如 To 或 From 头部中所示）


```c title="dialoginfo_set_branch_callee 用法"
...
branch_route[out]
{
....
	# 将发布的 info 与分支的 RURI 对齐
	dialoginfo_set_branch_callee("sip:$rU@opensips.org");
...
}
		
```


#### dialoginfo_mute_branch([side])


必须为 INVITE 消息调用此函数，仅在分支路由中，以便静默该分支中涉及的主叫方/被叫方/双方的信息发布。


参数含义：


- *side* (string, optional) - 可以是"A"或"B"仅为主叫方或被叫方静默 - 如果缺失，双方都将被静默。


```c title="dialoginfo_mute_branch 用法"
...
	branch_route[out] {
		# 如果不是本地域，则静默被叫方的发布
		if (!is_domain_local("$rd"))
			dialoginfo_mute_branch("B");
	}
...
		
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享 4.0 许可证。
