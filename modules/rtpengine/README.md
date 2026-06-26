---
title: "RTPengine 模块"
description: "这是一个通过 RTP 代理代理媒体流的模块。目前已知唯一与此模块配合使用的 RTP 代理是 Sipwise rtpengine [https://github.com/sipwise/rtpengine](https://github.com/sipwise/rtpengine)。rtpengine 模块是原始 rtpproxy 模块的修改版本，使用了新的控制协议。"
---

## 管理指南


### 概述


这是一个通过 RTP 代理代理媒体流的模块。目前已知唯一与此模块配合使用的 RTP 代理是 Sipwise rtpengine
		[https://github.com/sipwise/rtpengine](https://github.com/sipwise/rtpengine)。
		rtpengine 模块是原始 rtpproxy 模块的修改版本，使用了新的控制协议。该模块设计为从配置文件的角度来看是旧模块的替代品，
		但由于控制协议不兼容，它仅与专门支持该协议的 RTP 代理配合使用。


### 多 RTP 代理使用


rtpengine 模块可以支持多个 RTP 代理进行负载均衡/分发和控制/选择。


该模块允许定义多个 rtpengine 组。将在一个组上执行负载均衡，
		管理员可以选择使用哪个组。该组通过其 ID 选择 - ID 与组一起定义。请参阅
		"[rtpengine sock](#param_rtpengine_sock)" 模块参数定义以了解语法描述。


组内的负载均衡由模块基于该组中每个 RTP 代理的权重自动执行。


组的选择在脚本中使用 rtpengine_delete()、rtpengine_offer() 或 rtpengine_answer()
		函数之前进行 - 请参阅 rtpengine_use_set() 函数。


另一种选择组的方法是定义 setid_avp
	        模块参数并在调用 rtpengine_offer() 或 rtpengine_manage()
	        函数之前为定义的 avp 分配 setid。如果请求转发失败并且
	        有另一个分支要尝试，请记住在调用 rtpengine_delete() 函数后取消设置 avp。


出于向后兼容性，没有 ID 的组默认采用 ID 0。同样，如果在
	        rtpengine_delete()、rtpengine_offer() 或 rtpengine_answer()
	        之前未明确设置组，则将使用 ID 0 的组。


重要提示：如果使用多个组，请注意在 rtpengine_offer()/rtpengine_answer()
	        和 rtpengine_delete() 中使用相同的组！如果使用 setid_avp 选择了组，
	        则只需在 rtpengine_offer() 或 rtpengine_manage() 调用之前设置一次 avp。


该模块能够在所选节点出现通信问题时故障转移到组内的新节点。此外，
		如果节点返回以下错误之一，它也将进行故障转移：


- 并行会话限制已达到
- 端口用尽
- CPU 使用限制超出
- 负载限制超出
- 带宽限制超出


您可以使用 [extra failover error](#func_extra_failover_error) 参数
		来扩展上述列表。


许多 rtpengine_* 函数接受一个"sock_var"参数，该参数将填充为
		为特定操作选择的 RTPEngine 的套接字。存储在"sock_var"中的数据格式为："proto:ip:port"。
		如果指定了"sock_var"且非 NULL，则它将用于确定要使用的特定 RTPEngine。
		请注意，"sock_var"指定的套接字必须是当前 RTPEngine Set 上下文的成员。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *tm 模块* -（可选）如果您希望 rtpengine_manage() 完全功能化


#### 外部库或应用程序


以下库或应用程序必须在运行加载了此模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### rtpengine_sock (string)


用于连接到（一组）RTP 代理的套接字定义。它可以指定 UNIX 套接字或 IPv4/IPv6 UDP 套接字。
		如果缺少协议部分（即 "udp:"），则该套接字被视为 UNIX 套接字。


*默认值为 "NONE"（禁用）。*


```c title="设置 rtpengine_sock 参数"
...
# 单个 rtproxy
modparam("rtpengine", "rtpengine_sock", "udp:localhost:12221")
# 用于负载均衡的多个 rtproxy
modparam("rtpengine", "rtpengine_sock",
	"udp:localhost:12221 udp:localhost:12222")
# 多组多个 rtproxy
modparam("rtpengine", "rtpengine_sock",
	"1 == udp:localhost:12221 udp:localhost:12222")
modparam("rtpengine", "rtpengine_sock",
	"2 == udp:localhost:12225")
...
```


#### rtpengine_disable_tout (integer)


一旦 RTP 代理被发现不可达并被标记为禁用，rtpengine
		模块将在 rtpengine_disable_tout 秒内不尝试与该 RTP 代理建立通信。


*默认值为 "60"。*


```c title="设置 rtpengine_disable_tout 参数"
...
modparam("rtpengine", "rtpengine_disable_tout", 20)
...
```


#### rtpengine_tout (integer)


等待 RTP 代理回复的超时值。


*默认值为 "1"。*


```c title="设置 rtpengine_tout 参数"
...
modparam("rtpengine", "rtpengine_tout", 2)
...
```


#### rtpengine_retr (integer)


生成超时后模块应重试发送和接收的次数。


*默认值为 "5"。*


```c title="设置 rtpengine_retr 参数"
...
modparam("rtpengine", "rtpengine_retr", 2)
...
```


#### rtpengine_timer_interval (integer)


扫描 rtpengine 组以探测禁用节点的频率。探测在 SIP 处理上下文之外进行，
    并在单独的计时器例程中执行。禁用节点在 rtpengine_disable_tout 秒后被探测以重新启用。
    如果将此值设置得太高，可能导致意外的较大禁用间隔，因为探测前的最大间隔
    为 (rtpengine_timer_interval + rtpengine_disable_tout) 秒。


默认值为 "5"。


```c title="设置 rtpengine_timer_interval 参数"
...
modparam("rtpengine", "rtpengine_timer_interval", 1)
...
```


#### notification_sock (string)


格式为 *IP:port* 的 UDP 套接字，
		指示 OpenSIPS 将绑定的监听 IP 和端口以接收来自 RTPengine 的通知（如 DTMF 事件）。


从 RTPengine 收到的每个通知都会触发 *E_RTPENGINE_NOTIFICATION* 事件。


*默认值为 "none" - 通知被忽略。*


```c title="设置 notification_sock 参数"
...
modparam("rtpengine", "notification_sock", "127.0.0.1:9999")
...
```


#### extra_id_pv (string)


该参数设置 PV 定义，用于在 rtpengine_delete()、rtpengine_offer()、
			rtpengine_answer() 或 rtpengine_manage() 命令上使用"via-branch=extra"选项时。


默认为空，此时不能使用"via-branch=extra"选项。


```c title="设置 extra_id_pv 参数"
...
modparam("rtpengine", "extra_id_pv", "$avp(extra_id)")
...
```


#### setid_avp (string)


该参数定义一个 AVP，如果设置，该 AVP
			决定 rtpengine_offer()、rtpengine_answer()、
			rtpengine_delete() 和 rtpengine_manage()
			函数使用哪个 RTP 代理组。


没有默认值。


```c title="设置 setid_avp 参数"
...
modparam("rtpengine", "setid_avp", "$avp(setid)")
...
```


#### error_pv (string)


该参数定义一个变量，当 rtpengine_* 函数之一失败时，
			应由 RTP 填充该变量。


没有默认值。


```c title="设置 error_pv 参数"
...
modparam("rtpengine", "error_pv", "$var(rtpengine_error)")
...
```


#### db_url (string)


数据库 URL，用于从数据库加载 RTPEngine 套接字，
			而不是在脚本中指定它们（[rtpengine sock](#param_rtpengine_sock)
			模块参数）。


默认值为 "NULL"，不使用数据库。


```c title="设置 db_url 参数"
...
modparam("rtpengine", "db_url", 
		"mysql://opensips:opensipsrw@localhost/opensips")
...
```


#### db_table (string)


存储 RTPEngine 套接字的表。
			当配置了数据库 URL 时使用。


默认值为 "rtpengine"。


```c title="设置 db_table 参数"
...
modparam("rtpengine", "db_table", "rtpengine_new")
...
```


#### socket_column (string)


数据库表中 rtpengine 套接字列的名称。


默认值为 "socket"。


```c title="设置 socket_column 参数"
...
modparam("rtpengine", "socket_column", "sock")
...
```


#### set_column (string)


数据库表中 rtpengine set 列的名称。


默认值为 "set_id"。


```c title="设置 set_column 参数"
...
modparam("rtpengine", "set_column", "set_new")
...
```


#### ping_enabled (integer)


该参数指示是否也应该对已启用的节点进行探测。


如果设置此参数，则每个已启用的节点每隔 [rtpengine timer interval](#param_rtpengine_timer_interval) 秒被 ping 一次，
			除非自上一个间隔以来与该节点有任何通信。


*默认值为 "0"（禁用）。*


```c title="设置 ping_enabled 参数"
...
modparam("rtpengine", "ping_enabled", yes)
...
```


### 导出的函数


#### rtpengine_use_set(setid)


设置用于下一个 rtpengine_delete()、rtpengine_offer()、rtpengine_answer()
		或 rtpengine_manage() 命令的 RTP 代理组 ID。该参数是一个整数。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE。


```c title="rtpengine_use_set 用法"
...
rtpengine_use_set(2);
rtpengine_offer();
...
```


#### rtpengine_offer([flags[, sock_var[, sdp_pvar[, body]]]])


重写 SDP 正文以确保媒体通过 RTP 代理传递。
                在 INVITE 时调用，适用于 SDP 在 INVITE 和 200 OK 中的情况；
                在 200 OK 时调用，适用于 SDP 在 200 OK 和 ACK 中的情况。


参数的含义如下：


- *flags(string, 可选)* - 开启某些功能的标志。
"flags" 字符串是一个空格分隔的项目列表。
			每个项目可以是单个标记，也可以是"key=value"格式的标记。
			可能的标记在下面描述。
当传递 OpenSIPS 不了解的选项时，它将被盲目发送到 rtpengine 守护进程进行处理。
Values can also use *bracket syntax* to
			pass structured data (lists and dictionaries) to the RTP
			daemon. This enables features of the rtpengine ng protocol that
			require nested parameters, such as
			*sdp-media-remove*,
			*codec*, and
			*sdp-attr*.
包含在方括号中的值
			("[...]") 被解析为
			*空格分隔项目的列表*。如果括号内顶层的任何项目包含等号
			("=")，则整个值被解析为键值对的
			*字典*。
			括号可以嵌套以构建某些 rtpengine 参数期望的多级结构。
括号语法在模块端解析并在发送到 RTP 守护进程之前转换为原生 bencode 列表和字典结构。
			这适用于所有 rtpengine 守护进程版本，不需要任何特殊的守护进程
			配置。
遗留的前缀样式编解码器标志
			(*transcode-CODEC*,
			*codec-strip-CODEC*,
			*codec-mask-CODEC*) 继续像以前一样工作，
			并作为标志字符串发送。不要在同一次调用中混合前缀样式和括号样式的编解码器标志，
			因为它们是独立处理的，可能产生意外结果。
括号内需要包含字面空格或等号的值可以使用转义序列：
			".."（双点）被转义为空格
			字符，"--"（双破折号）被转义为
			等号。单点和单破折号保持不变。此约定与 rtpengine
			守护进程自己的转义处理相匹配。
嵌套限制为 8 级深度，单独的
			括号值限制为 4096 字节。这些限制足以满足所有有据可查的 rtpengine 用例。

  - *via-branch=...* - 在请求到 RTP 代理的"Via"头之一中包含"branch"
				值。可能的值为：
				"1" - 使用第一个"Via"头；
				"2" - 使用第二个"Via"头；
				"auto" - 如果是请求则使用第一个"Via"头，如果是回复则使用第二个；
				"extra" - 不从头中获取值，而是使用
				"[extra id pv](#param_extra_id_pv)" 变量的值。
				这可用于在 RTP 代理上为每个分支创建一个媒体会话。
				当向 RTP 代理发送后续的"delete"命令时，您可以通过
				在"rtpengine_delete"中传递'1'或'2'标志来仅停止特定分支的会话，
				或者在不传递这两个标志之一时停止呼叫的所有会话。当您有串行分叉呼叫场景时，
				这特别有用，因为 RTP 代理会为新分支获取"offer"命令，
				然后为之前的分支获取"delete"命令，否则这会删除整个呼叫，
				破坏新分支的后续"answer"。*此标志目前仅由 Sipwise rtpengine RTP 代理支持！*
  - *via-branch-param=...* - 为 *via-branch* 参数提供自定义值。
  - *call-id* - 为会话提供自定义 Call-ID。如果
				缺失，则使用请求/回复的 Call-Id。
  - *from-tag* - 为会话提供自定义 from-tag。如果
				缺失，则使用请求的 from-tag。
  - *to-tag* - 为会话提供自定义 to-tag。如果
				缺失，则使用请求/回复的 to-tag（如果有）。
  - *asymmetric* - 标志表示接收消息的 UA 不支持对称 RTP。（自动设置'r'标志）
  - *force-answer* - 强制"answer"，即，
				仅在相应会话已存在于 RTP 代理中时重写 SDP。默认情况下，当会话即将完成时启用。
  - *in-iface=..., out-iface=...* - 这些标志指定 SIP 消息的方向。
				这些标志仅在 RTP 代理以桥接模式运行时才有意义。"in-iface"应指示代理的入站
				接口，"out-iface"对应 RTP 代理的出站接口。您始终必须指定两个标志来定义
				传入网络和传出网络。例如，
				"in-iface=internal out-iface=external"应用于
				从本地接口接收并在外接口上发送的 SIP 消息。
  - *internal, external* - 这些是用于指定呼叫方向的旧标志。
				它们现已过时，被"in-iface=internal out-iface=external"配置取代。
  - *auto-bridge* - 此标志是"internal"和"external"标志的替代方案，
				用于在"内部网络"上的 IPv4 和"外部网络"上的 IPv6 之间进行自动桥接。
				而不是明确指示 RTP 代理选择特定地址族，
				区别由 RTP 代理自己根据 SDP 正文中的给定 IP 完成。
				不支持 Sipwise rtpengine。
  - *address-family=...* - 指示 RTP 代理接收者希望在此 SDP 正文中看到特定家族的地址。
				可能的值为"IP4"和"IP6"。例如，
				如果 SDP 正文包含 IPv4 地址但接收者仅支持 IPv6，
				您将使用"address-family=IP6"来桥接两个地址族。
Sipwise rtpengine 会记住每方在看到其 SDP 正文后的地址族偏好。
				这意味着通常只需要在"offer"中明确指定地址族，
				而无需在"answer"中指定。
注意：请注意，这仅在与非双栈用户代理或符合 RFC6157（建议双栈实现使用 ICE）的双栈客户端配合使用时才能正常工作。
				此快捷方式不能与符合 RFC4091 (ANAT) 的客户端正常工作，
				后者建议将具有不同 IP 协议的 m-lines 分组在一起。
  - *received-from=...* - 设置接收带 SDP 的 SIP 数据包的地址。
				此标志始终自动设置，除非您有理由否则不要使用它。
  - *force* - 指示 RTP 代理忽略另一个 RTP 代理在传输过程中插入的标记，
				以指示会话已经通过另一个代理。允许创建代理链。不支持 Sipwise rtpengine 并被忽略。
  - *trust-address* - 标志表示应信任 SDP 中的 IP 地址。
				没有此标志，RTP 代理忽略 SDP 中的地址，
				使用 SIP 消息的源地址作为传递给 RTP 代理的媒体地址。
				从 rtpengine 3.8 开始，这是默认行为。
  - *SIP-source-address* - trust-address 的相反操作。
				恢复忽略 SDP 正文中的端点地址的旧默认行为。
  - *replace-origin* - 标志表示 origin 描述 (o=) 中的 IP 也应更改。
  - *replace-session-connection* - 标志用于更改会话级 SDP 连接 (c=) IP，
				如果媒体描述也包含连接信息。
  - *replace-zero-address* - 标志用于将零地址替换为真实地址。
				使用零端点地址是表示静音或 sendonly 流的过时方式。
				具有零地址的流通常被标记为 sendonly，SDP 中的零地址被传递过去。
  - *symmetric* - 标志表示对于接收消息的 UA，
				必须强制支持对称 RTP。您不需要明确指定此值，因为它是默认值，
				只有在使用 *asymmetric* 时才会更改行为。
  - *repacketize=NN* - 请求 RTP 代理对发送当前消息的 UA 产生的
				RTP 流量进行重新打包，以在可能的情况下增加或减少每个转发的 RTP 数据包的有效载荷大小。
				NN 是以毫秒为单位的目標有效载荷大小，对于大多数编解码器，
				其值应为 10ms 的增量，但对于某些编解码器，增量可能不同（如 GSM 为 30ms，G.723 为 20ms）。
				RTP 代理将选择编解码器支持的最接近的值。
				此功能可用于显著降低低比特率编解码器的带宽开销，
				例如使用 G.729 从 10ms 到 100ms 可以节省三分之二的网络带宽。
				不支持 Sipwise rtpengine。
  - *loop-protect* - 标志指示 RTP 避免在循环同一消息时重写 SDP。
  - *ICE=...* - 控制 RTP 代理关于 SDP 正文中 ICE 属性的行为。
				可能的值为："force" - 
				丢弃 SDP 正文中已有的任何 ICE 属性，
				然后生成并插入新的 ICE 数据，将其自身作为 *唯一* ICE 候选；
				"remove"指示 RTP 代理丢弃
				任何 ICE 属性，不在 SDP 中插入任何新的。
				默认（如果根本没有给出"ICE=..."），
				仅当 SDP 最初没有 ICE 时才会生成新的 ICE 数据；
				否则 RTP 代理仅将自身插入为*额外* ICE 候选。
				其他 SDP 替换（c=、m= 等）不受此标志影响。
  - *RTP, SRTP, AVP, AVPF* - 这些标志控制应向
				SDP 接收者使用的 RTP 传输协议。如果未指定其中任何一个，
				则 SDP 中的协议保持不变。否则，"SRTP"标志表示应使用 SRTP，
				而"RTP"表示不应使用 SRTP。
				"AVPF"表示应使用带有反馈消息的高级 RTCP 配置文件，
				"AVP"表示应使用常规 RTCP 配置文件。另请参阅下面的下一组标志。
  - *RTP/AVP, RTP/SAVP, RTP/AVPF, RTP/SAVPF* - 这些作为
				选择 RTP 代理支持的不同 RTP 协议和配置文件的更明确的方式。
				例如，给出标志"RTP/SAVPF"与给出两个标志"SRTP AVPF"具有相同的效果。
  - *to-tag* - 强制包含"To"标签。
				通常，"To"标签始终在存在时包含，除非是"delete"消息。
				在"delete"消息中包含"To"标签允许您更有选择性地拆除呼叫中的哪些对话。
  - *to-tag=...* - 使用指定字符串作为"To"
				标签，而不是 SIP 消息中的实际"To"标签，
				并根据上述规则强制包含该标签。
  - *from-tag=...* - 使用指定字符串作为
				"From"标签，而不是 SIP 消息中的实际"From"
				标签。
  - *call-id=...* - 使用指定字符串作为
				"Call-ID"，而不是 SIP 消息中的实际"Call-ID"。
  - *rtcp-mux-demux* - 如果提供了 rtcp-mux (RFC 5761)，
				则 RTP 代理接受该选项，但不将其提供给此消息的接收者。
  - *rtcp-mux-reject* - 如果提供了 rtcp-mux，
				则 RTP 代理拒绝该选项，但仍然将其提供给接收者。
				可以与"rtcp-mux-offer"组合以始终提供它。
  - *rtcp-mux-offer* - 使 RTP 代理向此消息的接收者提供 rtcp-mux，
				无论最初是否提供。
  - *rtcp-mux-require* - 类似于 offer，但假定客户端已接受 rtcp-mux。
				这违反 RFC 5761，不会广告单独的 RTCP 端口。此选项对 WebRTC 客户端是必需的。
  - *rtcp-mux-accept* - 如果提供了 rtcp-mux，
				则 RTP 代理接受该选项，也将其提供给此消息的接收者。
				可以与"rtcp-mux-offer"组合以始终提供它。
  - *media-address=...* - 强制在 SDP 正文中使用特定媒体地址。
				地址族自动检测。
  - *record-call=yes/no* - 指示 rtpengine 是否应录制呼叫。
				使用此参数时，您可以在"metadata"中传递更多信息。
  - *transcode-CODEC* - 仅用于 offer，表示
				rtpengine 应向 B 方转码 CODEC。示例：
				*transcode-PCMA* 将向 B 方呈现 PCMA 编解码器。
  - *codec-strip-CODEC* - 仅用于 offer，表示
				A 方的呼叫将不会使用 CODEC。示例：
				*codec-strip-PCMA* 将阻止 A 方接收 PCMA 编解码器。
  - *codec-mask-CODEC* - 仅用于 offer，表示
				A 方将使用 CODEC，但不会呈现给 B 方。示例：
				*codec-mask-PCMA* 将使 A 方接收 PCMA 编解码器，
				但 B 方将使用其他编解码器。
- *sock_var(var, 可选)* - 用于存储此次呼叫选择的 rtpengine 套接字的变量。
- *sdp_var(var, 可选)* - 用于存储从 rtpengine 接收的完整 SDP 的变量。
		您可以对此字符串执行任何其他更改。*重要：*当提供此变量时，
		消息正文不再更改，因此您必须手动替换它！
- *body(string, 可选)* - 用于向 rtpengine_* 函数提供特定正文。
		如果此参数缺失，则使用当前消息的正文。


此函数可用于 ALL_ROUTES。


```c title="rtpengine_offer 用法"
route {
...
    如果（是方法("INVITE")）{
        如果（has_body("application/sdp")）{
            如果（rtpengine_offer()）
                t_on_reply("1");
        } 否则 {
            t_on_reply("2");
        }
    }
    如果（是方法("ACK") && has_body("application/sdp")）
        rtpengine_answer();
...
}

onreply_route[1]
{
...
    如果（has_body("application/sdp")）
        rtpengine_answer();
...
}

onreply_route[2]
{
...
    如果（has_body("application/sdp")）
        rtpengine_offer();
...
}
```


```c title="带正文替换的 rtpengine_offer 用法"
...
如果（rtpengine_offer(, $var(socket), $var(body), $rb)）{
    xlog("使用 rtpengine $var(socket)\n");
    # 对 $var(body) 中结果 SDP 进行所有更改
    ...
    remove_body_part();
    add_body_part($var(body), "application/sdp");
}
...
```


```c title="带呼叫录制的 rtpengine_offer 用法"
...
$var(rtpengine_flags) = $var(rtpengine_flags) + " record-call=yes";

$json(recording_keys) := "{}";
$json(recording_keys/callId) = $ci;
$json(recording_keys/fromUser) = $dlg_val(recording_from_user);
$json(recording_keys/fromDomain) = $dlg_val(recording_from_domain);
$json(recording_keys/fromTag) = $dlg_val(recording_from_tag);
$json(recording_keys/toUser) = $dlg_val(recording_to_user);
$json(recording_keys/toDomain) = $dlg_val(recording_to_domain);

$var(rtpengine_flags) = $var(rtpengine_flags) + " metadata=" + $(json(recording_keys){s.encode.hexa});
rtpengine_offer($var(rtpengine_flags));
...
```


```c title="用于转码的 rtpengine_offer 用法（前缀样式）"
...
# 目标：使 A 方使用 PCMA，B 方使用 opus
# * 不向 B 方呈现 PCMA：codec-mask-PCMA，但在 A 侧使用它
# * 不为 A 方使用 opus：codec-strip-opus
# * 向 B 方提供 opus：transcode-opus
rtpengine_offer("... codec-mask-PCMA codec-strip-opus transcode-opus ...");
...
```


```c title="使用括号语法的 rtpengine_offer 用法"
...
# 从 SDP 中移除视频和消息媒体流
# (sdp-media-remove 期望媒体类型列表)
rtpengine_offer("sdp-media-remove=[video message image]");

# 使用括号语法操作编解码器
# (codec 期望带有子键的字典：transcode、strip、accept 等)
rtpengine_offer("codec=[transcode=[PCMA PCMU] accept=[AMR-WB AMR] strip=[EVS]]");

# 括号语法可以与同一调用中的常规标志混合使用
rtpengine_offer("trust-address replace-origin ICE=remove codec=[transcode=[PCMA]]");

# 使用转义序列的 SDP 属性操作
# '..' 变为空格，'--' 变为等号
# 这为音频流添加了 SDP 属性 "fmtp:96 useinbandfec=1"
rtpengine_offer("sdp-attr=[audio=[add=[fmtp:96..useinbandfec--1]]]");
...
```


##### extra_failover_error (string)


包含一个（XDB）正则表达式，可用于
			匹配从 RTPEngine 节点收到的错误。如果匹配，
			模块会尝试使用新节点来处理受影响的命令。


此参数可用于扩展模块隐式故障转移的错误列表
			（请参阅 [failover](#param_failover)）。


*注意* 每个声明将定义一个表达式/匹配规则。
			如果要定义多个规则，需要多次定义该参数。


默认值为空，不使用额外错误。


```c title="设置 extra_failover_error 参数"
...
modparam("rtpengine", "extra_failover_error", "Parallel session limit reached")
...
```


#### rtpengine_answer([flags[, sock_pvar[, sdp_pvar[, body]]]])


重写 SDP 正文以确保媒体通过 RTP 代理传递。
		在 200 OK 时调用，适用于 SDP 在 INVITE 和 200 OK 中的情况；
		在 ACK 时调用，适用于 SDP 在 200 OK 和 ACK 中的情况。


有关参数的含义，请参见上面的 rtpengine_offer() 函数描述。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE。


有关示例，请参见上面的 rtpengine_offer() 函数示例。


#### rtpengine_delete([flags[, sock_var]])


拆除当前呼叫的 RTPEngine 会话。


有关参数的含义，请参见 rtpengine_offer() 函数描述。
			请注意，并非所有标志对"delete"都有意义。


此函数可用于 ALL_ROUTES。


```c title="rtpengine_delete 用法"
...
rtpengine_delete();
...
```


#### rtpengine_manage([flags[, sock_var[, sdp_var[, body]]]])


管理 RTPEngine 会话 - 它结合了 rtpengine_offer()、rtpengine_answer()
		和 rtpengine_delete() 的功能，根据消息类型和方法在内部检测要执行哪个。


它可以采用与 `rtpengine_offer().` 相同的参数。
		rtpengine_manage() 的 flags 参数可以是包含字符串形式标志的配置变量。


功能：


- 如果是带 SDP 的 INVITE，则执行 `rtpengine_offer()`
- 如果是带 SDP 的 ACK，则执行 `rtpengine_answer()`
- 如果是 BYE 或 CANCEL，或在 FAILURE_ROUTE[] 中调用，则执行 `rtpengine_delete()`
- 如果是对 INVITE 的回复且代码 >= 300，则执行 `rtpengine_delete()`
- 如果是对带 SDP 的 INVITE 的 1xx 和 2xx 回复，
			则如果请求有 SDP 或 tm 未加载则执行 `rtpengine_answer()`，
			否则执行 `rtpengine_offer()`


此函数可用于 ALL_ROUTES。


```c title="rtpengine_manage 用法"
...
rtpengine_manage();
...
```


#### rtpengine_start_recording([flags [, sock_var]])


此函数将向 RTP 代理发送信号以在 RTP 代理上录制 RTP 流。


参数的含义如下：


- *flags(string, 可选)* - 用于更改录制器行为的标志。
		要设置的重要值是 *call-id* 值，
		可用于开始录制与请求的呼叫不同的呼叫。
- *sock_var(var, 可选)* - 用于存储此次呼叫选择的 rtpengine 套接字的变量。


此函数可用于任何路由。


```c title="rtpengine_start_recording 用法"
...
rtpengine_start_recording();
...
		
```


#### rtpengine_stop_recording([flags [, sock_var]])


此函数将向 RTP 代理发送信号以停止在 RTP 代理上录制 RTP 流。


参数的含义如下：


- *flags(string, 可选)* - 用于更改录制器行为的标志。
		要设置的重要值是 *call-id* 值，
		可用于开始录制与请求的呼叫不同的呼叫。
- *sock_var(var, 可选)* - 用于存储此次呼叫选择的 rtpengine 套接字的变量。


此函数可用于任何路由。


```c title="rtpengine_stop_recording 用法"
...
rtpengine_stop_recording();
...
		
```


#### rtpengine_pause_recording([flags [, sock_var]])


此函数将向 RTP 代理发送信号以暂停在 RTP 代理上录制 RTP 流。
		除了指示录制守护进程不要关闭录制文件而是保持打开状态以便稍后可以通过另一个开始录制消息恢复录制外，
		这与停止录制相同。


参数的含义如下：


- *flags(string, 可选)* - 用于更改录制器行为的标志。
		要设置的重要值是 *call-id* 值，
		可用于开始录制与请求的呼叫不同的呼叫。
- *sock_var(var, 可选)* - 用于存储此次呼叫选择的 rtpengine 套接字的变量。


此函数可用于任何路由。


```c title="rtpengine_pause_recording 用法"
...
rtpengine_stop_recording();
...
		
```


#### rtpengine_play_media(flags, [duration_spec[, sock_var[, sockvar]]])


此函数将开始向其中一个端点播放媒体文件。


参数的含义如下：


- *flags(string)* - 与其他函数类似的标志列表。
			必须指定 *file*、*blob* 或 *db-id* 参数之一
			来指示要播放的媒体文件的内容。
			*file* 是指定 rtpengine 从文件路径获取媒体的常见选择，
			*blob* 用于从内联字符串获取内容，
			*db-id* 用于从数据库获取内容。
			媒体流的方向由 *from-tag* 参数、*address*
			（SDP 中的媒体地址）或 *label* 控制（如果
			媒体流包含标签）。如果所有这些都缺失，
			媒体文件将播放给 SIP 请求的发起者，类似于回铃音。
- *duration_spec(var, 可选)* - 将包含播放文件时长的伪变量。
			如果无法确定时长，则设置为 *-1*。
- *sock_var(var, 可选)* - 用于存储此次呼叫选择的 rtpengine 套接字的变量。


此函数可用于任何路由。


```c title="使用 rtpengine_play_media 的回铃音"
...
如果（是方法("INVITE") && !has_totag()）
	rtpengine_play_media("file=/path/to/ringback_tone_file.wav");
...
		
```


```c title="使用 rtpengine_play_media 管理呼叫保持音乐"
...
如果（是方法("INVITE") && has_totag()）{
	如果（is_audio_on_hold()）{
		$dlg_val(on_hold) = "1";
		rtpengine_play_media("from-tag=$tt file=/path/to/moh_file.wav");
	} 否则如果（$dlg_val(on_hold) == "1"）{
		$dlg_val(on_hold) = "0";
		rtpengine_stop_media("from-tag=$tt");
	}
}
...
		
```


#### rtpengine_stop_media(flags[, [sock_var[, sockvar]], [last_frame_pos]])


此函数将停止播放先前由 `rtpengine_play_media()` 调用开始的媒体文件。
			其参数的含义与前面的函数类似。
			请注意，此函数应以与其匹配的 `rtpengine_play_media()` 调用类似的参数调用，
			否则 RTPEngine 将无法停止媒体播放。


参数的含义如下：


- *flags(string)* - 与其他函数类似的标志列表。
- *last_frame_pos(var, 可选)* - 将包含文件最后播放帧的伪变量。


此函数可用于任何路由。


```c title="使用 rtpengine_stop_media 停止回铃音"
...
如果（是方法("INVITE") && $rs == 200）
	rtpengine_stop_media();
...
		
```


```c title="rtpengine_stop_media 的 last-frame-pos 参数使用示例"
...
如果（是方法("INVITE") && has_totag()）{
	如果（is_audio_on_hold()）{
		$dlg_val(on_hold = "1";
		rtpengine_play_media("from-tag=$tt start-pos=$avp(last_frame_pos) file=/path/to/moh_file.wav");
	} 否则如果（$dlg_val(on_hold) == "1"）{
		rtpengine_stop_media("from-tag=$tt", , $avp(last_frame_pos));
		$dlg_val(on_hold = "0";
	}
}
	rtpengine_stop_media();
...
		
```


#### rtpengine_block_media([flags[, sockvar]])


此函数将阻止从一个端点发送的媒体。
			要阻止的方向由 *flags* 参数和 *from-tag* 值控制。


此函数可用于任何路由。


```c title="rtpengine_block_media 用法示例"
...
rtpengine_block_media();
...
		
```


#### rtpengine_unblock_media([flags[, sockvar]])


此函数将恢复/解除阻止从一个端点发送的媒体。
			要阻止的方向由 *flags* 参数和 *from-tag* 值控制。


此函数可用于任何路由。


```c title="rtpengine_unblock_media 用法示例"
...
rtpengine_unblock_media();
...
		
```


#### rtpengine_block_dtmf([flags[, sockvar]])


此函数将阻止从一个端点发送的 DTMF 媒体。
			要阻止的方向由 *flags* 参数和 *from-tag* 值控制。


此函数可用于任何路由。


```c title="rtpengine_block_dtmf 用法示例"
...
rtpengine_block_dtmf();
...
		
```


#### rtpengine_unblock_dtmf([flags[, sockvar]])


此函数将恢复/解除阻止从一个端点发送的 DTMF 媒体。
			要阻止的方向由 *flags* 参数和 *from-tag* 值控制。


此函数可用于任何路由。


```c title="rtpengine_unblock_dtmf 用法示例"
...
rtpengine_unblock_dtmf();
...
		
```


#### rtpengine_start_forwarding([flags[, sockvar]])


此函数将开始将媒体转发到 RTPEngine 中 *tls-send-to* 参数指定的 TLS 目的地。
			此函数允许您通过指定要转发媒体的实体的 *from-tag* 来选择要转发的媒体流。
			如果缺失，所有媒体流都将被转发。


此函数可用于任何路由。


```c title="rtpengine_start_forwarding 用法示例"
...
rtpengine_start_forwarding();
...
		
```


#### rtpengine_stop_forwarding([flags[, sockvar]])


此函数将停止转发先前使用 *rtpengine_start_forwarding()* 函数开始的媒体转发。


此函数可用于任何路由。


```c title="rtpengine_stop_forwarding 用法示例"
...
rtpengine_stop_forwarding();
...
		
```


#### rtpengine_play_dtmf(code, [flags[, sockvar]])


此函数指示 RTP 发送 DTMF *code*
			给呼叫的参与者。*code* 可以是数字（"0-9"）
			或特殊字符（"*、#、A、B、C、D"之一）。
			可以使用 *flags* 参数配置其他参数。
			有关更多信息，请参阅 RTP 文档。


*注意：*如果您计划在会话中注入 DTMF，
			则必须在创建会话时指定 *inject-DTMF* 标志。


此函数可用于将 SIP INFO DTMF 按键转换为 RTP DTMF。


此函数可用于任何路由。


```c title="rtpengine_play_dtmf 用法示例"
...
rtpengine_play_dtmf("0"); # 发送 0 代码到上游
...
		
```


### 导出的异步函数


#### rtpengine_offer([flags[, sock_pvar[, sdp_pvar[, body]]]])


[rtpengine offer](#func_rtpengine_offer) 函数的异步版本。
			它接收相同的参数，含义相同。


```c title="异步 rtpengine_offer() 用法示例"
...
如果（是方法("ACK") && has_totag() && has_body_part("application/sdp")）{
	async(rtpengine_offer(), resume_invite);
}
...
route[resume_invite] {
	t_relay();
}
...
		
```


#### rtpengine_answer([flags[, sock_pvar[, sdp_pvar[, body]]]])


[rtpengine answer](#func_rtpengine_answer) 函数的异步版本。
			它接收相同的参数，含义相同。


```c title="异步 rtpengine_answer() 用法示例"
...
如果（是方法("ACK") && has_body_part("application/sdp")）{
	# 延迟协商
	async(rtpengine_answer(), resume_ack);
}
...
route[resume_ack] {
	t_relay();
}
...
		
```


#### rtpengine_delete([flags[, sock_var]])


[rtpengine delete](#func_rtpengine_delete) 函数的异步版本。
			它接收相同的参数，含义相同。


```c title="异步 rtpengine_delete() 用法示例"
...
如果（是方法("BYE")）{
	launch(rtpengine_delete());
}
...
		
```


### 导出的伪变量


#### $rtpstat


返回来自 RTP 代理的 RTP 统计数据。来自 RTP 代理的 RTP 统计数据
			以字符串形式提供，包含多个数据包计数器。


```c title="$rtpstat 用法"
...
    append_hf("X-RTP-Statistics: $rtpstat\r\n");
...
		
```


#### $rtpstat(STAT)[index]


返回下面列出的预定义统计数据之一：


- *MOS-average* - 没有索引时，返回所有参与呼叫的 RTP 流
					的平均 MOS 值，以 0 到 50 之间的整数表示，包括呼叫者和被呼叫者。
					如果指定了索引，它必须是参与呼叫的 *from-tag*
					或 *to-tag* 之一。
					在这种情况下，变量将返回该端点生成的所有流的平均 MOS，
					具有相关的标签值。如果您需要更细粒度的统计数据，
					请查看 *$rtpquery* 变量。
- *jitter-average* - 与 *MOS-average* 类似的行为，
					但返回平均抖动。
- *roundtrip-average* - 与 *MOS-average* 类似的行为，
					但返回平均往返时间。
- *packetloss-average* - 与 *MOS-average* 类似的行为，
					但返回平均数据包丢失。
- *MOS-min* - 没有索引时，返回参与呼叫的所有 RTP 流
					的最小 MOS 值（0 到 50 之间的整数值），包括呼叫者和被呼叫者。
					如果指定了索引，其效果与 *MOS-average* 相同。
- *jitter-min* - 与 *MOS-min* 类似的行为，
					但返回一条腿/呼叫的最小抖动。
- *roundtrip-min* - 与 *MOS-min* 类似的行为，
					但返回一条腿/呼叫的最小往返时间。
- *packetloss-min* - 与 *MOS-min* 类似的行为，
					但返回一条腿/呼叫的最小数据包丢失。
- *MOS-max* - 没有索引时，返回参与呼叫的所有 RTP 流
					的最大 MOS 值（0 到 50 之间的整数值），包括呼叫者和被呼叫者。
					如果指定了索引，其效果与 *MOS-average* 相同。
- *jitter-max* - 与 *MOS-max* 类似的行为，
					但返回一条腿/呼叫的最大抖动。
- *roundtrip-max* - 与 *MOS-max* 类似的行为，
					但返回一条腿/呼叫的最大往返时间。
- *packetloss-max* - 与 *MOS-max* 类似的行为，
					但返回一条腿/呼叫的最大数据包丢失。
- *MOS-min-at* - 没有索引时，返回从呼叫开始到现在
					MOS 值最小的时间（以秒为单位）。
					如果指定了索引，其效果与 *MOS-average* 相同。
- *jitter-min-at* - 与 *MOS-min-at* 类似的行为，
					但返回检测到最小抖动的时间。
- *roundtrip-min-at* - 与 *MOS-min-at* 类似的行为，
					但返回检测到最小往返时间的时间。
- *packetloss-min-at* - 与 *MOS-min-at* 类似的行为，
					但返回检测到一条腿/呼叫的最小数据包丢失的时间。
- *MOS-max-at* - 没有索引时，返回从呼叫开始到现在
					MOS 值最大的时间（以秒为单位）。
					如果指定了索引，其效果与 *MOS-average* 相同。
- *jitter-max-at* - 与 *MOS-max-at* 类似的行为，
					但返回检测到最大抖动值的时间。
- *roundtrip-max-at* - 与 *MOS-max-at* 类似的行为，
					但返回检测到最大往返时间值的时间。
- *packetloss-min-at* - 与 *MOS-max-at* 类似的行为，
					但返回检测到一条腿/呼叫的最大数据包丢失的时间。


*注意：*所有这些统计数据都是基于 RTPEngine 生成的统计数据计算的。
				某些统计数据可能并非对所有呼叫都可用（即，如果呼叫太短，
				或者电话不正确地通过 RTCP 报告 RTP 统计数据，则无法计算 MOS）。
				在这些情况下，变量返回 *NULL* 值。


```c title="$rtpstat(STAT)"
...
    xlog("整个呼叫的平均 MOS 是 $rtpstat(MOS-average)\r\n");
    xlog("呼叫者的平均 MOS 是 $(rtpstat(MOS-average)[$ft])\r\n");
    xlog("被呼叫者的平均 MOS 是 $(rtpstat(MOS-average)[$tt])\r\n");
    xlog("呼叫者的最小 MOS 是 $(rtpstat(MOS-min)[$ft])，在 $(rtpstat(MOS-min-at)[$ft]) 报告\r\n");
...
		
```


#### $rtpquery


对 RTP 代理执行查询命令并以 JSON 格式返回答案。
			您可以使用此变量从 RTP 代理获取任意数据，
			例如呼叫的原始统计数据或其他指标。


您可以使用 *$json()* 变量来解析其输出并从查询中提取任何信息，
			例如 RTP 统计数据或 MOS 值。


```c title="$rtpquery 用法"
...
	$json(reply) := $rtpquery;
	xlog("总 RTP 统计：$json(reply/totals)\n");
...
		
```


### 导出的 MI 函数


#### rtpengine:enable


替换已弃用的 MI 命令：*rtpengine_enable*。


启用/禁用 RTP 代理。


参数：


- *url* - RTP 代理 url（与配置文件中定义的确切相同）。
- *rtpengine:enable* - 1 - 启用，0 - 禁用 RTP 代理，2 - 将 RTP 节点置于探测模式。
- *setid*（可选）要更新的节点的集合 ID。如果提供，则仅更新所提供集合中的节点。


注意：如果 RTP 代理被多次定义（在同一集合或不同集合中），
			如果未提供集合 ID，则其所有实例都将被启用/禁用。


```c title="rtpengine:enable 用法"
...
## 通过 URL 禁用所有 rtpengine
$ opensips-cli -x mi rtpengine:enable udp:192.168.2.133:8081 0
## 通过 URL 和集合 ID (3) 启用 rtpengine
$ opensips-cli -x mi rtpengine:enable url=udp:192.168.2.133:8081 enable=1 setid=3
...
			
```


#### rtpengine:show


替换已弃用的 MI 命令：*rtpengine_show*。


显示所有 RTP 代理及其信息：集合和
			状态（是否禁用、权重和 recheck_ticks）。


无参数。


```c title="rtpengine:show 用法"
...
$ opensips-cli -x mi rtpengine:show
...
			
```


#### rtpengine:reload


替换已弃用的 MI 命令：*rtpengine_reload*。


从数据库重新加载所有 rtpengine 组。仅在设置了
			"[db url](#param_db_url)" 参数时使用。


参数：


- *type*（可选）soft - 从数据库重新加载节点时，
					重用任何现有套接字并保持现有节点禁用状态。
					如果未提供，则所有节点和套接字将首先被拆除，
					然后从数据库加载节点。


无参数。


```c title="rtpengine:reload 用法"
...
$ opensips-cli -x mi rtpengine:reload
$ opensips-cli -x mi rtpengine:reload type=soft
...
			
```


#### teardown


终止给定参数作为 SIP Call-ID 的 SIP 对话。


参数：


- *callid* - SIP Call-ID。


请注意，这只是 "dialog" 模块提供的 
			"dlg_end_dlg" MI 函数的一个包装函数。
			进行此包装只是为了在根据 RTP 超时尝试终止 SIP 呼叫时让 rtpengine 满意。


```c title="teardown 用法"
...
$ opensips-cli -x mi teardown Y2IwYjQ2YmE2ZDg5MWVkNDNkZGIwZjAzNGM1ZDY0ZDQ
...
			
```


### 导出的事件


#### E_RTPENGINE_NOTIFICATION


当从 RTPengine 收到通知时触发此事件。


参数表示从 RTPengine 收到的 Json 请求中的节点。
			常见值为：


- *type* - 标识通知类型（即 DTMF）
- *callid* - 触发此事件的呼叫的 callid
- *source_tag* - 触发此事件的呼叫的 from tag
- *timestamp* - 触发事件的时间戳


对于收到的 DTMF 事件，您还将获得以下节点：


- *source_ip* - 触发 DTMF 的 IP
- *event* - 事件/按下的按键
- *duration* - 按下按键的持续时间
- *volume* - 音调音量


#### E_RTPENGINE_STATUS


当 RTPEngine 服务器将其状态更改为主动/非主动时触发此事件。


参数：


- *socket* - 标识 RTPEngine 实例的套接字
- *status* - *active* 如果
				RTPEngine 实例响应探测，
				或 *inactive* 如果实例被停用。
- *set* - 此 RTPEngine 实例所属的集合的数值 ID。


## 常见问题


**Q: 如何从"rtpproxy"或"rtpproxy-ng"迁移到"rtpengine"？**


在大多数情况下，只有函数的名称发生了变化，
			每个名称中的"rtpproxy"被替换为"rtpengine"。
			例如，"rtpproxy_manage()"变成了"rtpengine_manage()"。
			一些重复的名称也得到了解决，例如现在有一个单一的"rtpengine_delete()"
			而不是"unforce_rtp_proxy()"和相同的"rtpproxy_destroy()"。


与旧模块最大的区别是如何将标志传递给"rtpengine_offer()"、"rtpengine_answer()"、
			"rtpengine_manage()"和"rtpengine_delete()"。
			它们不再采用一串单字母标志，
			而是采用一串空格分隔的项目，每个项目可以是单个标记（单词）
			或"key=value"对。


例如，如果您有调用"rtpproxy_offer("FRWOC+PS");"，
			这将变为：


最后，如果您正在使用任何一个函数的第二个参数（显式媒体地址），
			这已被第一个标志字符串中的"media-address=..."选项取代。


**Q: 在哪里可以找到更多关于 OpenSIPS 的信息？**


请查看 [https://opensips.org/](https://opensips.org/)。


**Q: 在哪里可以发布关于此模块的问题？**


首先检查您的问题是否已在我们的某个邮件列表中得到解答：


关于任何稳定 OpenSIPS 版本的电子邮件应发送至
			users@lists.opensips.org，关于开发版本的电子邮件应发送至 devel@lists.opensips.org。


如果您想保持邮件私密，请发送至 users@lists.opensips.org。


**Q: 如何报告错误？**


请遵循以下指南：
			[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。
<!-- CONTRIBUTORS -->

### 许可

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0 版授权
