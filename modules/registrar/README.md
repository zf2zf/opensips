---
title: "registrar 模块"
description: "registrar 模块包含 SIP REGISTER 请求处理逻辑,按照 RFC 3261 标准。在此基础上,还提供了多个扩展功能:"
---

## 管理指南

### 概述

registrar 模块包含 SIP REGISTER 请求处理逻辑,按照 RFC 3261 标准。在此基础上,还提供了多个扩展功能:

#### Path 支持 (RFC 3327)

registrar 模块包括 SIP Path 首部字段支持,根据
[RFC 3327](https://tools.ietf.org/html/rfc3327),
用于注册商和家庭代理。

如果 path 支持在 registrar 模块中启用,调用 *save()* 会将 Path
首部的值与 Contact 信息一起存储到 usrloc 中。对于包含一个或多个 Path 首部字段的 REGISTER 消息的回复构建,有三种模式:

- *off* - 将 Path 首部的值存储到 usrloc 中,但不将其传回给
UAC 的回复中。
- *lazy* - 存储 Path 首部,但只有当 Supported 首部中的
"path" 参数表示支持 Path 时,才将其传回给 UAC。
- *strict* - 如果存在 Path 首部但 UAC 没有表示支持,
则使用"420 Bad Extension"拒绝注册。否则将其存储并传回给 UAC。

调用 *lookup()* 时,如果找到 Path 首部,始终使用它,
并将其作为 Route 首部插入到第一个 Route 首部之前,
或者如果没有 Route,则插入到最后一个 Via 首部之后。它还将目标 URI 设置为第一个 Path URI,
从而覆盖收到的 URI,因为 NAT 必须由 UAC 的出站代理处理(客户端 NAT 之后的下一跳)。

整个过程对用户是透明的,因此除了在调用 *save()* 时启用"p0"/"p1"/"p2"标志之一外,不需要更改配置。

#### GRUU 支持 (RFC 5627)

registrar 模块包括对全局可路由用户代理 URI 的支持,根据 [RFC 5627](https://tools.ietf.org/html/rfc5627)。

如果电话支持 GRUU,调用 *save()* 会将 SIP Instance 的值与 contact 一起存储到 usrloc 中。模块将生成两种类型的 GRUU:

- *public* - 公开底层 AOR,只需将 SIP Instance 作为 ;gr 参数值附加即可构建。这些是持久化的,只要 contact 注册有效就有效。
- *temporary* - 隐藏底层 AOR。每次新的 Register 请求都会生成一个新的临时 GRUU,而具有不同 Call-ID 的 Register 请求会使所有先前生成的临时 GRUU 失效。

调用 *lookup()* 将尝试检测 R-URI 是否包含 GRUU。如果是,它将仅路由到该特定 AOR 所属的 Contact,而不附加任何其他分支。

即使 GRUU 在注册过程中的处理对用户是透明的,不需要配置更改,但在处理会话中请求时需要注意 GRUU 的具体细节。

由于 GRUU 会出现在 GRUU 启用设备生成的初始请求的 contact 首部中,您在收到带有 RURI 中 GRUU 指示的会话中请求时也需要执行 lookup()。

#### SIP 推送通知支持 (RFC 8599)

registrar 模块包括对基于标准的 SIP 推送通知的支持,按照
[RFC 8599](https://tools.ietf.org/html/rfc8599)。
可以通过将 [pn enable](#param_pn_enable) 设置为 *true* 来启用草案基本版本的支持。该模块还包括在长期会话中发送推送通知的可选支持([见 RFC 第 6 节](https://tools.ietf.org/html/rfc8599#page-23)),
通过 [pn enable purr](#param_pn_enable_purr) 开关。

推送通知(PN)支持的核心机制:

- PN 支持与现有逻辑完全兼容,启用它不会带来任何限制,因为 registrar 可以同时处理 SIP PN 兼容和标准 SIP 用户代理
- OpenSIPS 会在任何时候向 PN 启用的 contact 发送推送通知时引发 [E_UL_CONTACT_REFRESH](../usrloc#event_E_UL_CONTACT_REFRESH) 事件。该事件包含 contact 的 PN 坐标 -- 可以从 Contact URI('uri' 事件参数)中找到,并可以使用 {uri.param,name} 转换提取。从此以后,由脚本开发者决定如何触发推送通知(例如可能通过发送带有 [rest_client](../rest_client) 模块的 HTTP POST),从而强制设备重新注册。
- REGISTER 处理保持不变 -- PN 启用的 UA 与常规 UA 一样保存,前者额外在 contact 的"Flags"字段中设置 *4* 标志位,以便区分
- 初始 INVITE 处理几乎不变,但如果找到的 contact 只有 PN 启用的 contact,所有这些都需要推送通知,则 *lookup()* 函数现在额外返回 **2**。这意味着已为每个 contact 触发了 PN,并且不需要 t_relay(),因为在它们重新注册之前无法联系!
- 使用 event_routing 模块,OpenSIPS 将透明地从当前 INVITE 在这些 contact 在接受的 [pn refresh timeout](#param_pn_refresh_timeout) 内重新注册时派生一个新分支
- 会话中请求:在某些情况下(例如长期会话),在能够路由会话中请求到 SIP UA 之前可能需要 PN。[afunc pn process purr](#afunc_pn_process_purr) 异步函数将负责触发 PN 事件,并在收到相关 contact 的重新注册后恢复脚本。

有关更多信息或示例,请参阅"pn_xxx"模块参数的文档或 OpenSIPS 关于"SIP 推送通知"主题的博客文章。

### 依赖

#### OpenSIPS 模块

以下模块必须在此模块之前加载:

- *usrloc - 用户位置模块*。
- *signaling - 信令模块*。
- *event_routing*,
如果 [pn enable](#param_pn_enable) 设置为 *true*。

#### 外部库或应用程序

运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序:

- *无*。

### 导出的参数

#### default_expires (整数)

如果处理的消息既不包含 Expires 首部也不包含 expires contact 参数,则此值将用于新创建的 usrloc 记录。该参数包含过期秒数(例如,使用 3600 表示一小时)。

*默认值为 3600。*

```c title="设置 default_expires 参数"
...
modparam("registrar", "default_expires", 1800)
...
```

#### min_expires (整数)

Contact 的最小过期值,低于此最小值的值将自动设置为最小值。值 0 禁用检查。

*默认值为 60。*

```c title="设置 min_expires 参数"
...
modparam("registrar", "min_expires", 60)
...
```

#### max_expires (整数)

Contact 的最大过期值,高于此最大值的值将自动设置为最大值。值 0 禁用检查。

*默认值为 0。*

```c title="设置 max_expires 参数"
...
modparam("registrar", "max_expires", 120)
...
```

#### default_q (整数)

该参数表示新 contact 的默认 q 值。因为 OpenSIPS 不支持浮点参数类型,所以参数中的值除以 1000 并存储为浮点。例如,如果您希望 default_q 为 0.38,请在此使用值 380。

*默认值为 0。*

```c title="设置 default_q 参数"
...
modparam("registrar", "default_q", 1000)
...
```

#### tcp_persistent_flag (字符串)

该参数指定用于控制模块关于 TCP 连接行为的消息标志。如果通过 TCP 包含 TCP contact 的 REGISTER 设置了该标志,则模块通过"save()"函数将 TCP 连接的生命周期设置为 contact 过期值。通过这样做,只要 contact 有效,TCP 连接就会保持开启。

*默认值为 -1(禁用)。*

```c title="设置 tcp_persistent_flag 参数"
...
modparam("registrar", "tcp_persistent_flag", "TCP_PERSIST_DURATION")
...
```

#### realm_prefix (字符串)

要从 realm 中自动剥离的前缀。作为 SRV 记录的替代方案(并非所有 SIP 客户端都支持 SRV 查找),可以为 SIP 目的定义主域的子域(例如 sip.mydomain.net 指向与 mydomain.net 的 SRV 记录相同的 IP 地址)。通过忽略 realm_prefix"sip.",在注册时,sip.mydomain.net 将等同于 mydomain.net。

*默认值为 NULL(无)。*

```c title="设置 realm_prefix 参数"
...
modparam("registrar", "realm_prefix", "sip.")
...
```

#### case_sensitive (整数)

如果设置为 1,则 AOR 比较将区分大小写(按照 RFC3261 的指示),如果设置为 0,则 AOR 比较将不区分大小写。

*默认值为 1。*

```c title="设置 case_sensitive 参数"
...
modparam("registrar", "case_sensitive", 0)
...
```

#### received_avp (str)

Registrar 将存储由该参数配置的 AVP 的值到用户位置数据库的 received 列中。如果 AVP 为空,则该列将留空。AVP 应该包含一个 SIP URI,由正在处理的 REGISTER 消息的源 IP、端口和协议组成。

> [!NOTE]
> 此参数的值应与 nathelper 模块的相应参数的值相同。

*默认值为"NULL"(禁用)。*

```c title="设置 received_avp 参数"
...
modparam("registrar", "received_avp", "$avp(rcv)")
...
```

#### received_param (字符串)

当 nathelper 模块设置了 received URI 时,要在 200 OK 的 Contacts 中附加的参数名称。

*默认值为"received"。*

```c title="设置 received_param 参数"
...
modparam("registrar", "received_param", "rcv")
...
```

#### allow_dup_cseq (布尔值)

某些 SIP 堆栈将使用相同的 Call-ID 和 CSeq 值重新注册。虽然拒绝此类请求符合 RFC 3261 § 10.3.7,但启用此参数会指示 registrar 接受它们,从而提高互操作性。

*默认值为 *true*(接受重复的 CSeq)。*

```c title="设置 allow_dup_cseq 参数"
...
# 严格遵循 RFC 3261:拒绝具有重复 CSeq 的 REGISTER 请求
modparam("
```

#### expires_max_deviation (整数)

设置此参数是为了在新建 contact 的过期时间间隔上添加一个随机 +/- 偏差,偏差值可达给定值。例如,，如果此参数设置为 *100* 并且电话注册了 1800 秒,则最终过期时间将是 [1700, 1900] 区间内的随机数。通过对 contact 的注册生命周期进行随机化,服务器能够更好地处理重启后的*注册风暴*,当所有 TCP 连接丢失并且大量 UA 将同时重新注册时。由于 contact 生命周期随机化,注册风暴只会发生一次,而不是例如每 1800 秒发生一次。

*默认值为 0(无偏差)。*

```c title="设置 expires_max_deviation 参数"
...
# 每个注册生命周期添加 0-100 秒的随机 +/- 秒数
modparam("
```

#### max_contacts (整数)

该参数可用于限制用户位置数据库中每个 AOR(Address of Record)的 contact 数量。值 0 禁用检查。这是默认值,仅在未向 save() 函数传递其他 max_contacts 值时使用。也就是说 - 函数参数会覆盖此全局参数。

*默认值为 0。*

```c title="设置 max_contacts 参数"
...
# 每个 AOR 最多允许 10 个 contact
modparam("
```

#### retry_after (整数)

registrar 可以在多种情况下生成 5xx 回复给 REGISTER。例如,当设置了 `max_contacts` 参数并且处理 REGISTER 请求将超过限制时就会发生这种情况。在这种情况下,registrar 将生成"503 Service Unavailable"响应。

如果您想在 5xx 回复中添加 Retry-After 首部字段,请将此参数设置为大于零的值(0 表示不添加该首部字段)。有关更多详细信息,请参阅 RFC3261 的第 20.33 节。

*默认值为 0(禁用)。*

```c title="设置 retry_after 参数"
...
modparam("registrar", "retry_after", 30)
...
```

#### sock_hdr_name (字符串)

包含套接字描述(proto:IP:port)的首部,用于覆盖收到的套接字信息。该首部仅在"save()"时设置's'(套接字首部)标志时才会被查找和使用。

这仅在多个复制服务器场景中才有意义。

*默认值为 NULL。*

```c title="设置 sock_hdr_namer 参数"
...
modparam("registrar", "sock_hdr_name", "Sock-Info")
...
```

#### mcontact_avp (字符串)

AVP 用于存储在缓存注册场景中设置的修改后的绑定/contact(当 REGISTER 被转发到另一个 registrar 时)。AVP 将用于提取主 registrar 返回的 200 OK 中的"expires"值。

这仅在缓存注册场景中有意义,在该场景中,您的 OpenSIPS 在将注册转发到主 registrar 之前缓存注册。

*默认值为 NULL。*

```c title="设置 mcontact_avp 参数"
...
modparam("registrar", "mcontact_avp", "$avp(orig_ct)")
...
route {
   ...
   # 在转发 REGISTER 请求之前,保存传出的 contact。
   # 确保在完成所有可能的 contact 更改后执行此操作,
   # 如 fix_nated_contact()
   $avp(orig_ct) = $ct.fields(uri);
   t_on_reply("do_save");
   t_relay("udp:ip:port");
   ...
}
...
onreply_route[do_save] {
	if ($rs=="200")
		save("location");
}
...
```

#### attr_avp (字符串)

AVP 用于存储每个注册的特定附加信息。此信息从 AVP 读取,并在每次 registrar 'save()' 时存储(在内存中、数据库中或两者)。当调用 registrar 'lookup()' 或 'is_registered()' 函数时,存储的信息会被推送到与 *attr_avp* 同名的消息分支属性中(参见 $msg.branch.attr() 核心变量)。

在进行并行呼叫分叉时,contact 属性将被推送到相应分支的属性中。

*默认值为 NULL。*

```c title="设置 attr_avp 参数"
# 从执行并行分叉时的 attr_pvar 读取属性
...
modparam("registrar", "attr_avp", "$avp(attr)")

...
if (is_method("REGISTER")) {
	$avp(attr) = "contact_info";
	save("location");
	exit;
}
...
lookup("location");
# 列出所有结果分支及其属性
$var(i) = 0;
while ($(msg.branch.uri[$var(i)])!=NULL) {
	xlog("branch $var(i): $(msg.branch.uri[$var(i)]), attr=$(msg.branch.attr(attr)[$var(i)])\n");
	$var(i) = $var(i) + 1;
}
....
t_on_branch("parallel_fork");
t_relay();
...
branch_route [parallel_fork] {
	xlog("Branch $T_branch_idx 的属性: $tm.branch.attr(attr)\n");
}
```

#### gruu_secret (字符串)

生成临时 GRUU 时用于 XOR 操作的字符串。

*如果未设置,'OpenSIPS' 是默认密钥。*

```c title="设置 gruu_secret 参数"
...
modparam("registrar", "gruu_secret", "top_secret")
...
```

#### disable_gruu (整数)

全局禁用 GRUU 处理

*默认值为 1(将不处理 GRUU)。*

```c title="设置 gruu_secret 参数"
...
modparam("registrar", "disable_gruu", 0)
...
```

#### pn_enable (布尔值)

启用 SIP 推送通知支持([RFC 8599](https://tools.ietf.org/html/rfc8599))。如果启用,包含所有 [pn ct match params](#param_pn_ct_match_params) 的 Contact 首部字段 URI 将仅使用这些参数与现有绑定进行匹配。否则,模块将尝试按常规方式匹配它们,使用当前的 usrloc [matching_mode](../usrloc#param_matching_mode)。

*默认值为 **false**。*

```c title="设置 pn_enable 参数"
...
modparam("
```

#### pn_providers (字符串)

支持的推送通知提供商列表。虽然 RFC 8599 只定义了三个可能的值("apns"、"fcm" 和"webpush"),但也可以指定非标准值。

*默认值为 **NULL**
(未设置)。*

```c title="设置 pn_providers 参数"
...
modparam("
```

#### pn_ct_match_params (字符串)

RFC 8599 参数的最小必需列表(也接受自定义参数),这些参数必须存在于 Contact URI 中并与现有绑定完全匹配,以便在 SIP 重新 REGISTER 期间刷新绑定。如果 Contact 首部字段 URI 中缺少至少一个此类参数,模块将回退到执行常规 contact 匹配。

请注意,如果所有上述 PN Contact URI 参数都与现有绑定匹配,则认为匹配成功,无论 SIP URI 的其他部分是否不匹配(例如主机名、端口、其他 URI 参数等)。

调用 *lookup()* 或 [afunc pn process purr](#afunc_pn_process_purr) 后,上述 PN 相关参数将从结果请求和 Contact URI 事件参数中自动剥离。

*默认值为 **"pn-provider, pn-prid, pn-param"**。*

```c title="设置 pn_ct_match_params 参数"
...
modparam("
```

#### pn_pnsreg_interval (整数)

对于能够自行唤醒并刷新其绑定的设备(通过 *";+sip.pnsreg"* Contact 首部字段参数表示),此设置表示服务器在设备应该发出绑定刷新请求之前广告的距过期时间。

*默认值为 **130**
(过期前秒数)。*

```c title="设置 pn_pnsreg_interval 参数"
...
modparam("
```

#### pn_trigger_interval (整数)

如果来自给定 SIP 端点的绑定刷新 REGISTER 请求未在至少 [pn trigger interval](#param_pn_trigger_interval) 秒前到达(例如因为设备不支持 *";+sip.pnsreg"* 或由于其他错误条件),则将触发 [E_UL_CONTACT_REFRESH](../usrloc#event_E_UL_CONTACT_REFRESH) usrloc 事件。

一旦触发 [E_UL_CONTACT_REFRESH](../usrloc#event_E_UL_CONTACT_REFRESH),脚本编写者应使用 Contact URI 中的 RFC 8599 参数向设备的 PN 提供商生成推送通知请求,以便唤醒设备并使其重新注册。

*默认值为 **120**
(过期前秒数)。*

```c title="设置 pn_trigger_interval 参数"
...
modparam("
```

#### pn_skip_pn_interval (整数)

在成功进行 contact 的(重新)注册后,此设置表示一个时间间隔(以秒为单位),在此期间,contact 被认为是可以到达的,因此任何推送通知都将被跳过。

*默认值为 **0** 秒
(始终生成推送通知)。*

```c title="设置 pn_skip_pn_interval 参数"
...
modparam("
```

#### pn_refresh_timeout (整数)

此超时从触发推送通知的 *lookup()* 或 [afunc pn process purr](#afunc_pn_process_purr) 开始计时。该值表示推送通知发送所需持续时间与设备相应重新注册到达所需持续时间之和的最大允许值。

一旦超过此超时的初始或会话中请求,任何与待处理推送通知匹配的重新注册都将不再产生预期效果。例如:

- 待处理的初始 INVITE 事务将完成,不再为被叫方发送的每个 REGISTER 自动派生额外分支
- 待处理的 BYE 消息将超时,OpenSIPS 将尝试路由它们,尽管没有收到目标设备实际可到达的确认

*默认值为 **6** 秒。*

```c title="设置 pn_refresh_timeout 参数"
...
modparam("
```

#### pn_enable_purr (布尔值)

为长期会话启用 SIP 推送通知机制。如果启用,registrar 将在对 REGISTER 请求的 200 OK 回复中包含 *"+sip.pnspurr"* Feature-Caps 首部字段标签。此标签表示注册的唯一定位符(PURR - Proxy Unique Registration Reference)。

在会话建立期间,每个 UA 可以在其 Contact 首部中包含 OpenSIPS 在注册期间返回的 PURR 值。通过包含 PURR(例如";pn-purr=XXX"),代理表示期望在能够接收另一方发送的会话中请求之前首先被 PN 唤醒。

启用此参数时,请确保也添加 [afunc pn process purr](#afunc_pn_process_purr) 的逻辑。

*默认值为 **false**。*

```c title="设置 pn_enable_purr 参数"
...
modparam("
```

### 导出的函数

#### save(domain[, flags[, aor[, ownership_tag]]])

该函数处理 REGISTER 消息。它可以根据 REGISTER 消息中的 Contact 和 Expires 首部添加、删除或修改 usrloc 记录。成功时,将返回 200 OK,列出当前在 usrloc 中的所有 contact。出错时,将发送带有原因短语中简短描述的错误消息。

参数含义如下:

- *domain (静态字符串)* - registrar 内的逻辑域。如果使用数据库,这是存储 contact 的表名。
- *flags (字符串,可选)* - 由一个或多个以下标志组成的字符串,逗号分隔:

  - *'memory-only'* - (旧 *m* 标志)
	仅将 contact 保存到内存缓存中,不进行数据库操作;
  - *'no-reply'* - (旧 *r* 标志)
	不生成 SIP 回复到当前 REGISTER 请求。
  - *'max-contacts=[int]'* - (旧 *c*
	标志)此标志可用于限制此 AOR 在用户位置数据库中的 contact 数量。
	值 0 禁用检查。此参数覆盖全局"max_contacts"模块参数。
  - *'force-registration'* - (旧 *f*
	标志)此标志可用于强制注册新的 contact,即使已达到最大 contact 数量。在这种情况下,将删除较旧的 contact 以便为新的 contact 腾出空间,而不会超过允许的最大数量。
	此标志仅在使用"max-contacts"时有意义。
  - *'matching-mode=[val]'* - (旧 *M*
	标志)如何执行上传的 contact(通过当前处理的 REGISTER)与已知 contact(在内存或数据库中)之间的匹配。此选项仅用于当前操作,可以是:
	
	*'0'* - 仅 contact URI 匹配
	
	*'1'* - contact URI 和 SIP Call-ID 匹配
	
	*'<param_name>'* - 仅使用给定 URI 参数的值进行匹配(例如 <rinstance>)
  - *'path-off'* - (旧 *p0* 标志)
	(Path 支持 - 'off' 模式) - Path 首部保存到 usrloc,但从不包含在回复中。
  - *'path-lazy'* - (旧 *p1* 标志)
	(Path 支持 - lazy 模式) Path 首部保存到 usrloc,但仅当"Supported"首部的"path"选项表示支持 Path 时才包含在回复中。
  - *'path-strict'* - (旧 *p2* 标志)
	(Path 支持 - strict 模式) - 仅当"Supported"首部的"path"选项表示支持 Path 时,Path 首部才保存到 usrloc。如果没有表示支持 Path,请求将被拒绝,并返回"420 - Bad Extension",同时在回复中包含"Unsupported: path"首部和收到的"Path"首部。此模式是 RFC-3327 推荐的模式。
  - *'path-received'* - (旧 *v* 标志)
	如果设置,注册的第一个 Path URI 的"received"参数被设置为 received-uri,并为该 contact 设置 NAT 分支标志。如果 registrar 位于 SIP 负载均衡器之后,这很有用,负载均衡器将 NAT'ed UAC 地址作为"received"参数传递到其 Path URI 中。
  - *'only-request-contacts'* - (旧 *o*
	标志)如果注册成功,仅在 200 OK 回复中包含 REGISTER 请求的 Contact。虽然这违反 RFC 3261,但在某些场景中可能有用。
  - *'socket-header'* - (旧
					*s* 标志)在 REGISTER 请求中查找包含套接字
					描述(proto:IP:port)的首部。此套接字信息将存储为收到的套接字信息。
  - *'min-expires=[int]'* - (旧
					*e* 标志)此
					标志可用于设置最小注册过期时间。低于此最小值的值将自动设置为最小值。值 0 禁用检查。
					此参数覆盖全局
					[min expires](#param_min_expires) 模块参数。
  - *'max-expires=[int]'* - (旧
					*E* 标志)此
					标志可用于设置最大注册过期时间。高于此最大值的值将自动设置为最大值。值 0 禁用检查。
					此参数覆盖全局
					[max expires](#param_max_expires) 模块参数。
此参数是由一组标志组成的字符串。
- *aor (字符串,可选)* - 自定义 AOR;如果缺失,AOR 将从默认位置获取 - To 首部 URI。
- *ownership_tag (字符串,可选)* - 一个集群共享标签(有关更多详细信息,请参阅 clusterer 模块文档),它将附加到从当前请求保存的每个 contact。此标签仅在集群用户位置场景中相关,有助于确定 contact 的当前逻辑所有者节点。这反过来对于限制当前不负责此 contact 的节点执行某些操作很有用(例如:从不拥有的虚拟 IP 地址错误地发起 ping 的高可用性设置)。

此函数可以从 REQUEST_ROUTE 和 ONREPLY_ROUTE 使用。

如果您计划在回复路由中使用"save()"函数,请参阅 [mcontact avp](#param_mcontact_avp) 模块参数。

```c title="save 使用示例"
...
# 保存到 'location',无标志,使用默认 AOR(TO URI)
save("location");
...
# 保存到 'location',不更新数据库,每个 AOR 最多 5 个 contact,
# 使用默认 AOR(TO URI)
save("location","memory-only, max-contacts=5");
...
# 保存到 'location',无标志,使用 FROM URI 作为 AOR
save("location","",$fu);
...
# 保存到 'location',不更新数据库,强制注册,从 AVP 获取 AOR
save("location","memory-only, no-reply", $avp(aor));
...
# 保存到 'location',使用"vip"所有权标签标记 contact,并
# 将这些 contact 复制到当前不拥有"vip"的备份节点
save("location", , , "vip");
...
```

#### remove(domain, AOR[, [contact][, [next_hop][, [sip_instance], [bflag]]]])

显式删除给定地址记录背后的 contact。

参数含义如下:

- *domain (静态字符串* - registrar 内的逻辑域。
		如果使用数据库,这是存储 contact 的表名。
- *AOR (字符串)* - 要搜索的地址记录(SIP URI)
- *contact (字符串,可选)* - 要删除的 contact 的 SIP URI 过滤器。这必须是注册时使用的完整 SIP URI。
- *next_hop (字符串,可选)* - 返回到此 contact 路径上的下一个 SIP IP 地址/主机名。请参阅下面的部分了解如何计算下一跳。主机名在匹配之前会被解析。
- *sip_instance (字符串,可选)* -
			"+sip.instance" 值,用于过滤目的。
- *blfag (字符串,可选)* -
			用于过滤目的的分支标志。

**重要:**每个 contact 的 IP 地址(用于匹配)计算如下:

- a. 如果存在 Path 首部,则 Path URI 的主机名部分将被解析为 contact 的 IP 地址。
- b. 否则,如果使用 nathelper 设置了 contact 的"Received"值(下一跳的源 IP),则这成为要解析为 contact IP 地址的主机名。
- c. 否则,选择 Contact 首部字段 URI 的"hostname"部分解析为 contact 的 IP 地址。

此函数可以从 REQUEST_ROUTE 和 ONREPLY_ROUTE 使用。

```c title="remove 使用示例"
...
# 删除属于"bob" AOR 的所有 contact
remove("location", "sip:bob@atlanta.com");
...
# 仅删除 bob 的家庭电话 contact
remove("location", "sip:bob@atlanta.com", "sip:bob@46.50.64.78");
...
# 删除所有位于"50.60.50.60"之后的 bob 的电话
# 注意,即使未使用,也必须使用 NULL 值指定"contact"参数
$var(next_hop) = "50.60.50.60"
remove("location", "sip:bob@atlanta.com", , $var(next_hop));
...
# 删除 contact"sip:bob@46.50.64.78"位于"50.60.50.60"之后的 bob 的电话
remove("location", "sip:bob@atlanta.com", "sip:bob@46.50.64.78", "50.60.50.60");
...
# 删除 bob 移动设备 X 后面的所有 contact
remove("location", "sip:bob@atlanta.com", , , "<urn:uuid:e5e68d40-f08a-4600-b82e-ff4d5d8c1a8f>")
```

#### remove_ip_port(IP,Port, domain, [AOR])

删除特定 IP 和 Port 后面的所有 contact,可按 AOR 过滤。

参数含义如下:

- *IP (字符串)* - 要删除的 Contact 的 IP
- *Port (整数)* - 要删除的 Contact 的 Port
- *domain (静态字符串* - registrar 内的逻辑域。
		如果使用数据库,这是存储 contact 的表名。
- *AOR (字符串,可选)* - 要搜索的地址记录(SIP URI)

此函数可以从所有路由使用。

```c title="remove_ip_port 使用示例"
...
# 删除 8.8.8.8 port 43213 后面的所有 contact
remove_ip_port("8.8.8.8",43213,"location");
...
# 仅删除 8.8.8.8:43213 主机后面的 bob 的 contact
remove_ip_port("8.8.8.8",43213,"location","sip:bob@atlanta.com");
...
```

#### lookup(domain [, flags [, aor]])

该函数从 Request-URI 中提取用户名,并尝试在 usrloc 中找到该用户名的所有 contact。如果没有此类 contact,将返回 -1。如果存在此类 contact,Request-URI 将被具有最高 q 值的 contact 覆盖,其余的将根据 append_branches 参数值附加到消息中。

如果启用了 method_filtering 选项,lookup 函数将仅返回支持处理请求方法的 contact。

参数含义如下:

- *domain (静态字符串)* - 应该用于查找的表名。
- *flags (字符串,可选) - 由一个或多个以下标志组成的字符串,逗号分隔:*

  - *'no-branches'* - (旧 *b* 标志)
	此标志控制 *lookup()* 函数如何处理多个 contact。
	如果 usrloc 中有多个给定用户名的 contact,并且未设置此标志,则 Request-URI 将被最高 q 值 rated contact 覆盖,其余的将附加到 sip_msg 结构中,稍后可由 tm 用于分叉。如果设置了该标志,仅 Request-URI 将被最高 q 值 rated contact 覆盖,其余的将保持未处理状态。
  - *'to-branches-only'* - (旧 *B* 标志)
	此标志强制所有找到的 contact 仅作为分支上传(在目标集中),完全不放在当前消息的 R-URI 中。使用此选项, *lookup()* 函数也可以在 SIP 回复的上下文中使用。
  - *'branch'* - (旧 *r* 标志)此标志
	启用搜索现有分支的 aor 并将其扩展到 contact。例如,您在 ruri 中有 AOR A,但您也想将呼叫转发到 AOR B。为此,您必须将 AOR B 放在一个分支中,如果启用此标志,该函数还将把 AOR B 扩展到 contact,这将放回分支中。函数调用之前的分支中的 AOR 将被删除。
  - *'method-filtering'* - (旧 *m* 标志)
	设置此标志将启用基于注册时"Allow"首部字段中列出的支持方法的 contact 过滤。在注册时未显示"Allow"首部字段的 contact 被假定为支持所有标准 SIP 方法。
  - *'ua-filtering=[val]'* (旧 *u* 标志)
	(用户代理过滤) - 此标志启用按用户代理的正则表达式过滤。它与启用的 append_branches 参数一起使用很有用。值必须使用 '/regexp/' 格式。
  - *'case-insensitive'* (旧 *i* 标志) -
	此标志为'ua-filtering'标志启用不区分大小写的过滤。
  - *'extended-regexp'* - (旧 *e* 标志)
	此标志为'ua-filtering'标志启用扩展正则表达式格式。
  - *'global'* (旧 *g* 标志)(全局
	查找) - 此标志仅与联合用户位置集群相关。如果设置, *lookup()* 函数不仅执行经典的内存"搜索-AoR-推送分支"操作,还将执行元数据查找并为每个返回结果附加一个额外分支。"内存分支"对应于本地 contact(当前位置),而"元数据分支"对应于平台其他位置上可用的 contact。
	AoR 元数据由VoIP 平台的位置(数据中心)需要的最少信息组成,以便为全局平台广告本地注册的 AoR 的存在。具体来说,这包括两条信息:
	
	
		AoR(例如"vladimir@federation-cluster")
	
	
		主 IP(例如"10.0.0.223")
  - *'max-ping-latency=[int]'* - (旧 *y*
	标志)最大可接受的 contact ping 延迟(微秒)。具有更高延迟的 AoR 的 contact 将在 *lookup()* 期间被丢弃。
  - *'sort-by-latency'* - (旧 *Y* 标志)
	contact 将按其上次成功 ping 延迟的升序选择(最快的 ping -> 最慢的 ping)。此标志可与"max-ping-latency"标志一起使用。
- *AOR (字符串,可选)* - 要查找的 AOR;如果缺失,使用 RURI 作为 AOR;

返回值:

- **1** - 找到 contact 并成功推送为分支。需要在此之前被唤醒的 contact 通过异步推送通知收到通知。
- **2** - 成功为找到的 contact 启动了至少一个异步推送通知,但没有填充额外分支(即不需要调用 t_relay())。
- **-1** - 未找到 contact。
- **-2** - 找到 contact,但它们都不支持当前 SIP 方法。
- **-3** - 处理过程中的内部错误。

此函数可以从 REQUEST_ROUTE, FAILURE_ROUTE 使用。

```c title="lookup 使用示例"
...
lookup("location");  # 简单查找
   # 或
lookup("location", "method-filtering"); # 带方法过滤的查找
   # 或
lookup("location", "branch"); # 带 aor 分支搜索的查找;
						# 除第一个外的所有 contact 都应放在分支中
   # 或
lookup("location", "ua-filtering=/phone/i"); # 带用户代理过滤的查找
   # 或
lookup("location", "", $var(aor)); # 使用 AOR 变量的简单查找
switch ($retcode) {
    case -1:
    case -3:
        sl_send_reply(404, "Not Found");
        exit;
    case -2:
        sl_send_reply(405, "Not Found");
        exit;
};
...
```

#### is_registered(domain ,[AOR])

如果 AOR 已注册则返回 true,否则返回 false。该函数不修改正在处理的消息。

注意:如果为回复调用(来自 onreply_route),您必须传递一个 AOR(作为参数),否则函数将失败。

参数含义如下:

- *domain (静态字符串)* - 应该用于查找的表名。
- *AOR (字符串,可选)* - 要查找的 AOR;如果缺失,AOR 的来源是 REGISTER 请求的"To"首部,其他 sip 请求的"From"首部。

此函数可以从 REQUEST_ROUTE, FAILURE_ROUTE,
			BRANCH_ROUTE, ONREPLY_ROUTE, LOCAL_ROUTE 使用。

```c title="is_registered 使用示例"
...
/**/
if (is_method("REGISTER")) {
	/* 自动使用 To 首部中的 URI */
	if (is_registered("location")) {
		xlog("此 AOR 已注册\n")
		...
	}
};
/* 检查 From uri 无论此 aor 是否已注册 */
if (is_registered("location",$fu)) {
	xlog("呼叫者已注册\n");
}
...
```

#### is_contact_registered(domain ,[AOR],[contact],[callid])

如果某个 AOR 的 contact 和/或 callid 已注册则返回 true,否则返回 false。该函数不修改正在处理的消息。

参数含义如下:

- *domain (静态字符串)* - 应该用于查找的表名。
- *AOR (字符串,可选)* - 要查找的 AOR;如果缺失,AOR 的来源是 REGISTER 请求的"To"首部,其他 sip 请求的"From"首部。
- *contact (contact,可选)* (可选)- SIP
			URI,用于检查是否有以此 URI 作为 cotact 的注册(这可以帮助您区分同一用户/AOR 的多个注册)。
- *callid (字符串,可选)* - callid 用于检查 contact
			是否以此 callid 注册(这可以帮助您区分新注册的 contact(之前未注册的 callid)和重新注册(已注册的 callid))。

此函数可以从 REQUEST_ROUTE, FAILURE_ROUTE,
			BRANCH_ROUTE, ONREPLY_ROUTE, LOCAL_ROUTE 使用。

```c title="is_contact_registered 使用示例"
...
/* 阻止未注册的用户... */
if (is_method("INVITE")) {
	if (!is_contact_registered("location")) {
		sl_send_reply(401, "Unauthorized");
		...
	}
}

/* ... 或检查第二个 Contact URI 是否已注册 */
if (is_method("INVITE")) {
	if (is_contact_registered("location", $fu, $(ct.fields(uri)[1])))
		xlog("呼叫者已注册\n");
}
...
```

#### is_ip_registered(domain ,[AOR],IPvar,[PORTvar])

如果至少有从一个 IP 注册的 contact(和可选的 PORTvar 变量),则返回 true。IP 与收到的 host 匹配(如果存在),否则与 contact host 匹配。此函数不修改正在处理的消息。此函数替换旧的"is_other_contact"函数。

参数含义如下:

- *domain (静态字符串)* - 应该用于查找的表名。
- *AOR (字符串,可选)* - 要查找的 AOR;如果缺失,AOR 的来源是 REGISTER 请求的"To"首部,其他 sip 请求的"From"首部。
- *IPvar (var)* - 包含要与 contact host 或收到的 host 匹配的 IP 的变量(见上文)。如果 *IPvar* 是包含多个值/IP 的 AVP,则会检查所有值。
- *PORTvar (var,可选)* - 包含要与 contact host 或收到的 host 匹配的端口的变量(见上文)。如果 *IPvar* 是包含多个值/IP 的 AVP,则 PORTvar 预计包含相同数量的条目,并且所有值都会被检查。

此函数可以从 REQUEST_ROUTE, FAILURE_ROUTE,
			BRANCH_ROUTE, ONREPLY_ROUTE, LOCAL_ROUTE 使用。

```c title="is_ip_registered 使用示例"
...
/* 检查源 IP 是否已注册 */
if (is_method("REGISTER")) {
	if (is_ip_registered("location",$tu,$si)) {
		xlog("从此 IP 已注册\n");
		...
	}
};
...
```

#### add_sock_hdr(hdr_name)

向当前 REGISTER 请求添加一个包含收到套接字(proto:ip:port)描述的新首部"hdr_name"。

这仅在多个复制服务器场景中才有意义。

参数含义如下:

- *hdr_name (字符串)* - 要使用的首部名称。

此函数可以从 REQUEST_ROUTE 使用。

```c title="add_sock_hdr 使用示例"
...
add_sock_hdr("Sock-Info");
...
```

### 导出的异步函数

#### pn_process_purr(domain)

根据 RFC 8599 执行会话中请求处理。对于此类请求,在 R-URI 和最顶层 Route 首部字段 URI 中搜索 *";pn-purr"* 参数值,该值既匹配 OpenSIPS PURR 格式又对应于 usrloc 注册。一旦找到 usrloc contact,就触发 [E_UL_CONTACT_REFRESH](../usrloc#event_E_UL_CONTACT_REFRESH) 事件,并将请求置于异步保持状态,最长可达 [pn refresh timeout](#param_pn_refresh_timeout) 秒,直到收到匹配的 REGISTER 请求。

如果在触发推送通知之前处理结束,请求将不再被置于异步保持状态,将立即调用恢复路由。

参数含义如下:

- *domain (静态字符串)* - registrar 内的逻辑域。
		如果使用数据库,这是存储 contact 的表名。

**返回值**

- **1** - 成功,PN 已启动。
- **2** - 成功,但未启动 PN(由于缺少 PURR、外部 PURR 或离线 contact)
- **-1** - 内部错误

```c title="async pn_process_purr() 使用示例"
route {
	...
	if (has_totag()) {
		if (is_method("ACK") && t_check_trans()) {
			t_relay();
			exit;
		}

		if (!loose_route()) {
			send_reply(404, "Not Found");
			exit;
		}

		if (!is_method("ACK"))
			async (pn_process_purr("location"), resume_route);

		route(relay);
		exit;
	}
}

route [resume_route] {
	$var(rc) = $rc;
	xlog("pn_process_purr() 完成,返回码 $var(rc)\n");

	...
}
```

### 导出的统计信息

#### max_expires

max_expires 参数的值。

#### max_contacts

max_contacts 参数的值。

#### defaults_expires

default_expires 参数的值。

#### accepted_regs

接受的注册数量。

#### rejected_regs

拒绝的注册数量。

## 常见问题

**Q: 旧的"append_branch"模块参数发生了什么?**

它作为全局选项被移除,因为"lookup" 函数通过"b"标志(附加分支)接受此选项
请参阅"lookup"函数的文档。

**Q: 旧的"method_filtering"模块参数发生了什么?**

它作为全局选项被移除,因为"lookup" 函数通过"m"标志(方法过滤)接受此选项
请参阅"lookup"函数的文档。

**Q: 旧的"sock_flag"模块参数发生了什么?**

它作为全局选项被移除,因为"save" 函数通过"s"标志(套接字首部)接受此选项
请参阅"save"函数的文档。

**Q: 旧的"use_path"和"path_mode"模块参数发生了什么?**

它们作为全局选项被移除,因为"save" 函数通过"px"标志(path 支持)接受这些选项
请参阅"save"函数的文档。

**Q: 旧的"path_use_received"模块参数发生了什么?**

它作为全局选项被移除,因为"save" 函数通过"v"标志(path receiVed)接受此选项
请参阅"save"函数的文档。

**Q: 旧的"nat_flag"模块参数发生了什么?**

它被移除了,因为模块从"USRLOC"模块内部加载此值(请参阅"nat_bflag" USRLOC 参数)。

**Q: 旧的"use_domain"模块参数发生了什么?**

它被移除了,因为模块从"USRLOC"模块内部加载此选项。这是为了简化配置。

**Q: 旧的"save_noreply"和"save_memory"函数发生了什么?**

这些函数被合并到新的 "save(domain,flags)" 函数中。是否发送回复或是否更新数据库也通过 flags 控制。

**Q: 在哪里可以找到更多关于 OpenSIPS 的信息?**

请查看 [https://opensips.org/](https://opensips.org/)。

**Q: 在哪里可以发布关于此模块的问题?**

首先检查您的问题是否已在我们某个邮件列表中得到解答:

关于任何稳定 OpenSIPS 版本的电子邮件应发送到 users@lists.opensips.org,关于开发版本的电子邮件应发送到 devel@lists.opensips.org。

如果您想保持邮件私密,请发送至 users@lists.opensips.org。

**Q: 如何报告错误?**

请遵循以下指南:
[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。

**Q: desc_time_order 参数发生了什么?**

它被移除了,因为其功能已迁移到 usrloc 模块,在那里有一个同名的参数。

### 许可证

所有文档文件(即 .md 扩展名)均采用知识共享 4.0 许可证授权。
