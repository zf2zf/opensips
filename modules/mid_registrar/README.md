---
title: "mid_registrar 模块"
description: "mid_registrar 是 SIP 平台的中间组件,设计位于最终用户与平台主注册组件之间。它开辟了利用现有基础设施持续增长(无论是从用户数还是注册流量)的新可能性,同时保持一个现有的低资源 registrar 服务器。"
---

## 管理指南


### 概述


*mid_registrar* 是 SIP 平台的中间组件,设计位于最终用户与平台主注册组件之间。

它开辟了利用现有基础设施持续增长(无论是从用户数还是注册流量)的新可能性,同时保持一个现有的低资源 registrar 服务器。


作为主 SIP registrar 的注册前端,mid-registrar 能够:


- 将传入的高速率注册流量转换为面向主 registrar 层的高速率变体。通过适当的配置,它可以吸收超过 90% 的现有注册流量,同时正确管理后端的用户位置状态,有效地减少相应层的资源使用。
- 与主 registrar(从用户位置角度)保持同步,正确接受其决定的联系人状态和过期时间。


#### 路径支持 (RFC 3327)


mid_registrar 模块包含根据
[RFC 3327](https://tools.ietf.org/html/rfc3327) 的 SIP Path 头字段支持,用于 registrar 和 home-proxy。


调用 *mid_registrar_save()* 时,如果 Path 支持在 mid_registrar 模块中启用,会将 Path 头字段的值与联系人信息一起存储到 usrloc 中。对于包含一个或多个 Path 头字段的 REGISTER 消息,构建回复有三种模式:


- *off* - 将 Path 头字段的值存储到 usrloc,但不将其传回给
UAC 的回复中。
- *lazy* - 存储 Path 头,并在 Supported 头中由 "path" 参数指示支持时,
将其传回给 UAC。
- *strict* - 如果存在 Path
头但 UAC 未指示支持,则以 "420 Bad Extension" 拒绝注册。
否则将其存储并传回给 UAC。


调用 *mid_registrar_lookup()* 时,如果找到 Path 头,始终使用它,并将其作为 Route 头字段插入到第一个 Route 头字段之前,如果没有 Route,则插入到最后一个 Via 头字段之后。它还会将目标 URI 设置为第一个 Path URI,从而覆盖收到的 URI,因为 NAT 必须在 UAC 的出站代理(客户端 NAT 之后的第一个跃点)处理。


整个过程对用户透明,因此除了在调用 *mid_registrar_save()* 时启用 "p0"/"p1"/"p2" 标志之一外,不需要任何配置更改。


#### GRUU 支持 (RFC 5627)


mid_registrar 模块包含根据 [RFC 5627](https://tools.ietf.org/html/rfc5627) 的全局可路由用户代理 URI 支持。


调用 *mid_registrar_save()* 时,如果手机支持 GRUU,会将 SIP 实例的值与联系人一起存储到 usrloc。该模块将生成两种类型的 GRUU:


- *public* - 公开底层 AOR,
仅通过将 SIP 实例附加为 ;gr 参数值来构建。只要联系人注册有效,这些就是持久的。
- *temporary* - 隐藏底层 AOR
每次新的 Register 请求都会导致构建一个新的临时 GRUU,而具有不同 Call-ID 的 Register 请求会导致所有先前生成的临时 GRUU 无效。


调用 *mid_registrar_lookup()* 时,将尝试检测 R-URI 是否包含 GRUU。如果是,它将仅为特定 AOR 所属的联系人路由请求,而不会附加任何其他分支。


即使 GRUU 在注册过程中对用户透明,因此不需要配置更改,但在处理中期对话请求时,您需要注意 GRUU 的细节。


由于 GRUU 将存在于 GRUU 启用设备生成的初始请求的联系人头中,当收到带有 RURI 中 GRUU 指示的中期对话请求时,您也必须执行 lookup()。


#### SIP 推送通知支持 (RFC 8599)


mid_registrar 模块包含根据
[RFC 8599](https://tools.ietf.org/html/rfc8599) 的标准 SIP 推送通知支持。
可以通过将 [pn enable](#param_pn_enable) 切换为 *true* 来启用草稿基本版本的支持。该模块还包括在长期对话期间发送推送通知的可选支持([见 RFC 第 6 节](https://tools.ietf.org/html/rfc8599#page-23)),
通过 [pn enable purr](#param_pn_enable_purr) 开关。


推送通知 (PN) 支持背后的基本机制:


- PN 支持与现有逻辑完全兼容,启用它不会带来任何限制,因为
mid_registrar 可以同时处理符合 SIP PN 的和标准 SIP 用户代理
- OpenSIPS 会在任何时候向 PN 启用的联系人发送推送通知时引发
[E_UL_CONTACT_REFRESH](../usrloc#event_E_UL_CONTACT_REFRESH)
事件。该事件包含联系人的 PN 坐标 -- 它们可以在联系人 URI 中找到('uri' 事件参数),可以使用 {uri.param,name}
转换提取。从此以后,由脚本开发者决定触发推送通知(例如可能通过发送带有
[rest_client](../rest_client) 模块的 HTTP POST),
从而强制设备重新注册。
- REGISTER 处理未更改 -- PN 启用的 UA 与常规 UA 一样保存,前者额外在
任何 MI 联系人列表的 "Flags" 字段中设置 *4* 位标志,以便区分
- 初始 INVITE 处理几乎不变,*mid_registrar_lookup()*
函数现在还会在唯一找到的联系人都是 PN 启用的联系人时额外返回 **2**,
所有这些都需要推送通知。这意味着每个联系人都已触发 PN,并且不需要 t_relay(),因为它们在重新注册之前无法到达!
使用 event_routing 模块,OpenSIPS 将透明地从当前 INVITE 在
[pn refresh timeout](#param_pn_refresh_timeout)
内每个来自这些联系人的重新注册时分叉一个新分支
- 中期对话请求:在某些情况下(例如长期对话),
在能够将中期对话请求路由到 SIP UA 之前可能需要 PN。[afunc pn process purr](#afunc_pn_process_purr)
异步函数将负责触发 PN 事件,并在收到受影响联系人的重新注册后尽快恢复脚本。


有关更多信息或示例,请参阅 "pn_xxx" 模块参数的文档或 OpenSIPS 围绕 "SIP 推送通知" 主题的博客文章。


### 工作模式


mid_registrar 可以以多种模式之一运行:


#### 联系人镜像 (默认)


在 "联系人镜像" 模式下,mid-registrar 仅通过更改 Contact 头字段值将自己插入到最终用户和主 registrar 之间的 SIP 流量中。请参阅
[sip 流量插入](#auto_insertion_into_future_sip_flows) 部分,了解可能的基于联系人的插入模式的详细说明。传入的 REGISTER 请求将被代理到主 registrar;注册的联系人将仅根据主 registrar 返回的信息在 2xx 回复时存储在 mid-registrar 中。


例如,此模式的一种可能用途是在 SIP 前端上克隆注册,该前端以新服务(例如添加 IM/消息路由)扩展主平台。


#### 联系人限流


在 "联系人限流" 模式下,mid-registrar 可以显著降低主 registrar 端(介于
mid-registrar 和主 registrar 之间)的注册速率,同时处理最终用户端(介于最终用户和 mid-registrar 之间)的高注册速率。这在最终用户非常动态且寿命短(例如移动设备)但主 registrar 无法处理大量注册流量的场景中很有用。


流量转换以 *"按设备"*
方式完成,根据每个唯一的 SIP Contact 头字段值。它通过在将注册代理到主 registrar 时增加每个联系人的 "expires" 参数值来实现。一旦这样的注册完成,后续对相同 SIP Contact 头字段值的注册将被 mid-registrar 持续吸收,直到最终远程注册的 lifetime 减少到需要刷新(即简单转发下一个 REGISTER 请求)的地步。


一些 SIP 用户代理丢失网络连接(特别是在处理移动设备时)是常见现象,因此它们不会从 mid-registrar 正确注销。在这种情况下,为了避免主 registrar 上的过时注册(其中包含大大延长寿命的 SIP 联系人!),mid-registrar 将在认为这些联系人已过期时适当生成 De-REGISTER 请求,并从主 registrar 的位置服务中删除这些联系人。


此模式的主要实际用途是注册流量转换。通过最小化在主 registrar 上处理注册的压力,我们允许它将更多系统资源投入到平台的关键区域,例如高级 SIP 呼叫功能和/或媒体处理。


#### AOR 限流


在 "AOR 限流" 模式下,mid-registrar 帮助处理每个用户/AOR 的多个注册。这是通过将来自单个 AOR 的所有最终用户注册联系人聚合到主 registrar 的单个注册下来实现的。这可以显著降低传入的注册速率(降至每个 AOR 单个注册),但也有助于处理无法实现并行分叉/振铃的 registrar 服务器。


流量转换以 *"按用户"*
方式完成,根据每个唯一的 SIP AOR。它通过在将注册代理到主 registrar 时提供一个具有较大 "expires" 参数值的联系人来实现。一旦这样的注册完成,后续对相同地址记录的注册将被 mid-registrar 持续吸收,直到最终远程注册的 lifetime 减少到需要刷新(即简单转发下一个 REGISTER 请求)的地步。


一些 SIP 用户代理丢失网络连接(特别是在处理移动设备时)是常见现象,因此它们不会从 mid-registrar 正确注销。在这种情况下,为了避免主 registrar 上的过时注册(其中包含大大延长寿命的 SIP AOR!),
mid-registrar 将在认为这些联系人已过期时适当生成 De-REGISTER 请求,并从主 registrar 的位置服务中删除这些联系人。


在这三种模式中,"AOR 限流" 可能提供通往主 registrar 的最佳流量减少。通过聚合联系人,它还具有减少主 registrar 必须处理的联系人数量的额外好处。


关于此模式中的 SIP 请求处理,模块在将注册代理到主 registrar 时将始终用单个 Contact 头字段值替换所有 Contact 头字段值,指示 AOR 在前端本地,其联系人可以在那里找到。


此模式的主要实际用途是面向主 registrar 的注册流量转换,以及接管其呼叫分叉职责。通过最小化在主 registrar 上处理注册/分叉呼叫的压力,我们允许它将更多系统资源投入到平台的关键区域,例如高级 SIP 呼叫功能和/或媒体处理。


### 自动插入到未来 SIP 流量中


mid-registrar 的定义特性是它必须易于集成,理想情况下是一个 "即插即用" SIP 组件。它不应在任何平台层上强加任何 "出站代理" 配置,并在成功注册后自动将自己插入呼叫流程。


无论其配置的工作 [mode](#param_mode) 如何,mid_registrar 都会对所有转发的 REGISTER 请求的 Contact 头字段 URI 进行处理,并用其监听接口之一替换 Contact URI 的原始 "hostname" 和 "port" 部分。


此外,在模式 "0" 和 "1" 中,每个联系人将被分配一个唯一标识符,该标识符将用于未来的基于联系人的查找操作。此信息将包含在每个转发的 Contact URI 中。[contact id insertion](#param_contact_id_insertion) modparam 控制此信息的包含方式。


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块:


- *usrloc*
- *signaling*
- *tm*
- *event_routing*, 如果 [pn enable](#param_pn_enable) 设置为 *true*。


#### 外部库或应用程序


运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序:


- *无*


### 导出的参数


#### mode (integer)


模块的工作模式。
请参阅 [工作模式章节](#working_modes) 了解更多详情。


以下对 **所有** 工作模式都适用:


- 当收到 REGISTER 时,脚本编写者必须调用
*[mid registrar save](#func_mid_registrar_save)*
- mid-registrar 会根据
*[contact id insertion](#param_contact_id_insertion)*
将自身插入所有注册的呼叫流程中。
- mid-registrar 转发的注册仅在下游 registrar 的回复状态码为 2xx 时才会透明地导致用户位置更新。


每种工作模式的行为不同,如下所示:


- *0 (联系人镜像模式)*
mid-registrar 仅将自身插入呼叫流程。
联系人过期时间保持不变。
- *1 (联系人限流模式)*
联系人限流是降低注册流量速率的第一步。这是通过使用
*[outgoing expires](#param_outgoing_expires)* 模块
参数或 *[mid registrar save](#func_mid_registrar_save)* 的相应参数来实现的,
允许脚本编写者延长在通往主 registrar 的注册生命周期。

在此模式下,mid-registrar 可能会根据
*[outgoing expires](#param_outgoing_expires)*
在转发注册时更改初始请求中的 Expires 头字段值或 "expires" Contact
头字段参数。
- *2 (AOR 限流模式)*
AOR 限流是 "联系人限流" 的进一步发展,因为主 registrar 仅被告知 AOR 的网络存在,而不是
联系人。这种行为也是通过
*[outgoing expires](#param_outgoing_expires)* 模块
参数或 *[mid registrar save](#func_mid_registrar_save)* 的相应参数来实现的,
允许脚本编写者延长在通往主 registrar 的注册生命周期。
在此模式下,mid-registrar 将完全替换所有转发的注册的 Contact
集,用单个 Contact 广告 AOR 对主 registrar 可用。此 Contact 的过期值由
*[outgoing expires](#param_outgoing_expires)* 给出。


默认值为 **0**(联系人镜像模式)


```c title="设置 *mode* 模块参数"
modparam("mid_registrar", "mode", 2)
```


#### contact_id_insertion (integer)


仅在 "镜像" 或 "联系人限流"
[mode](#param_mode) 中相关。控制额外
唯一联系人识别信息(64 位,十六进制编码整数)
将放置在传出 Contact 头字段 URI 中的位置。请参阅
[sip 流量插入](#auto_insertion_into_future_sip_flows) 了解更多详情。


可能的值:


- *"ct-param" (默认)* - 联系人 ID 将作为 ";ctid=" 参数附加到传出的 Contact URI。
- *"ct-username"* - 联系人 ID 将替换传出 Contact URI 的 "username" 部分。


```c title="设置 *contact_id_insertion* 模块参数"
modparam("mid_registrar", "contact_id_insertion", "ct-username")
```


#### contact_id_param (string)


仅在 "镜像" 或 "联系人限流"
[mode](#param_mode) 中相关。指定模块用于匹配联系人和路由 SIP 请求的
Contact URI 参数的名称。


默认值为 **"ctid"**


```c title="设置 *contact_id_param* 模块参数"
modparam("mid_registrar", "contact_id_param", "ctid")

# 生成的 Contact 头字段示例:
# Contact: <sip:liviu@10.0.0.10:5060;ctid=619244948763447138>;expires=180.
```


#### at_escape_str (string)


仅在 "AoR 限流" [mode](#param_mode) 且 usrloc [use_domain](../usrloc#param_use_domain)
设置启用时相关。此字符串表示 "@" 字符的转义序列,必须以某种方式包含在
mid-registrar 生成的 Contact URI 用户名中。


将此参数设置为不同的值在后台 registrar 与默认转义字符串不兼容的情况下很有用。


默认值为 **"%40"**


```c title="设置 *at_escape_str* 模块参数"
modparam("mid_registrar", "at_escape_str", "___")

# mid-registrar 生成的 Contact 头字段示例:
# Contact: <sip:zach%40sipdomain.invalid@127.0.0.1:5060>;expires=120
```


#### outgoing_expires (integer)


仅在联系人/AOR 限流模式中相关。设置传出联系人的过期时间间隔的最小值。


默认值为 **3600**(秒)


```c title="设置 *outgoing_expires* 模块参数"
modparam("mid_registrar", "outgoing_expires", 3600)
```


#### received_avp (string)


模块会将此参数配置的 AVP 值存储在用户
位置表的 *received* 列中。如果 AVP 为空,它将保留列为空。
AVP 应包含正在处理的 REGISTER 消息的源 IP、端口和协议的 SIP URI。


> [!NOTE]
> 此参数的值应与 nathelper 模块相应参数的值相同。


默认值为 **"NULL"**(禁用)


```c title="设置 *received_avp* 模块参数"
modparam("mid_registrar", "received_avp", "$avp(rcv)")
```


#### received_param (string)


如果 nathelper 模块设置了 received URI,则为添加到 200 OK 回复联系人的参数名称。


> [!NOTE]
> 此参数的值应与 nathelper 模块相应参数的值相同。


默认值为 **"received"**


```c title="设置 *received_param* 模块参数"
modparam("mid_registrar", "received_param", "rcv")
```


#### extra_contact_params_avp (string)


AVP 规范。此 AVP 在
*[mid registrar save](#func_mid_registrar_save)* 期间进行评估:
如果它持有有效字符串,其内容将附加到 mid-registrar 为传出请求构建的
*每个* 新 Contact URI。


默认值为 **None**(未使用)


```c title="设置 *extra_contact_params_avp* 模块参数"
# NB: AVP 会在每个新的 SIP 请求时清除
modparam("mid_registrar", "extra_contact_params_avp", "$avp(extra_ct_params)")

# 在 SIP 消息处理期间设置 AVP
$avp(extra_ct_params) = ";transport=tls";
```


#### attr_avp (string)


AVP 用于存储每个注册的特定附加信息。
此信息从 AVP 读取,并在 [mid registrar save](#func_mid_registrar_save) 时存储(在内存、数据库或两者中)。
当调用 [mid registrar lookup](#func_mid_registrar_lookup) 或 'is_registered()'(registrar)
函数时,*attr_avp* 将被填充在 [重新]注册时保存的值。


执行呼叫分叉时,AVP 将持有多个值。相应属性信息在 *attr_avp* 中的位置等于分支索引。下面给出一个示例场景。


*默认值为 NULL。*


```c title="设置 attr_avp 参数"
# 从进行并行分叉时的 attr_pvar 读取属性
...
modparam("mid_registrar", "attr_avp", "$avp(attr)")

...
if (is_method("REGISTER")) {
	$avp(attr) = "contact_info";
	mid_registrar_save("location");
	exit;
}
...
mid_registrar_lookup("location");
t_on_branch("parallel_fork");
...
branch_route [parallel_fork] {
	xlog("分支 $T_branch_idx 的属性: $(avp(attr)[$T_branch_idx])\n");
}

		
```


#### min_expires (integer)


Contact 的最小过期值,低于此最小值的值将自动设置为最小值。值 0 禁用检查。


默认值为 **10**(秒)


```c title="设置 *min_expires* 模块参数"
modparam("mid_registrar", "min_expires", 600)
```


#### default_expires (integer)


如果正在处理的消息既不包含 Expires HFs 也不包含过期联系人参数,
此值将用作任何新创建的 usrloc 记录的过期时间间隔。


默认值为 **3600**(秒)


```c title="设置 *default_expires* 模块参数"
modparam("mid_registrar", "default_expires", 1800)
```


#### max_expires (integer)


Contact 的最大过期值,高于此最大值的值将自动设置为最大值。值 0 禁用检查。


默认值为 **3600**(秒)


```c title="设置 *max_expires* 模块参数"
modparam("mid_registrar", "max_expires", 7200)
```


#### default_q (integer)


为新联系人设置默认 *"q"* 值。
因为 OpenSIPS 不支持浮点模块参数,
提供的 *"q"* 值必须乘以 1000。
例如,如果您希望
*[default q](#param_default_q)*
为 0.38,请将此参数设置为 380。


默认值为 **0**


```c title="设置 *default_q* 模块参数"
modparam("mid_registrar", "default_q", 380)
```


#### tcp_persistent_flag (string)


指定用于控制模块关于 TCP 连接行为的message标志。如果为包含 TCP 联系人的 TCP REGISTER 设置了此标志,
则模块通过
*[mid registrar save](#func_mid_registrar_save)*
函数会将 TCP 连接的 lifetime 设置为联系人过期值。通过这样做,
只要其联系人有效,TCP 连接就会保持。


默认值为 **-1**(未设置)


```c title="设置 *tcp_persistent_flag* 模块参数"
modparam("mid_registrar", "tcp_persistent_flag", "TCP_PERSIST_REGISTRATIONS")
```


#### realm_prefix (string)


在多域用户位置场景中
(**"use_domain"** usrloc 模块参数
设置为 *"1"*),
此参数表示在进行保存时从 *To* 头字段 URI 的主机名部分,或在执行查找时从 *Request-URI* 自动剥离的前缀。


它是 DNS SRV 记录的替代方案(并非所有 SIP 客户端都支持 SRV 查询),
可以为 SIP 目的定义主域的子域(例如
"sip.mydomain.net" 指向与 "mydomain.net" 的 SRV 记录相同的 IP 地址)。通过忽略 realm_prefix "sip.",在注册时,
"sip.mydomain.net" 将被翻译为 "mydomain.net"。


默认值为 **NULL**(无)


```c title="设置 *realm_prefix* 模块参数"
modparam("mid_registrar", "realm_prefix", "sip.")
```


#### case_sensitive (integer)


如果设置为 1,则 AOR 比较将区分大小写(如 RFC3261 指示),如果设置为 0,则 AOR 比较将不区分大小写。


默认值为 **1**(true)


```c title="设置 *case_sensitive* 模块参数"
modparam("mid_registrar", "case_sensitive", 0)
```


#### allow_dup_cseq (boolean)


某些 SIP 堆栈将使用相同的 Call-ID 和 CSeq 值重新 REGISTER。
虽然拒绝此类请求符合 RFC 3261 § 10.3.7,但启用此参数会指示 mid_registrar 接受它们,从而提高互操作性。


*默认值为 *true*(接受重复的 CSeq)。*


```c title="设置 allow_dup_cseq 参数"
...
# 严格的 RFC 3261 合规性:拒绝具有重复 CSeq 的 REGISTER 请求
modparam("
```


#### expires_max_deviation (integer)


设置此参数是为了向新注册联系人的过期时间间隔添加随机 +/- 偏差,最多可达给定值。例如,如果此参数设置为
*100*,而手机注册了 1800 秒,则最终过期时间将是 [1700, 1900] 区间中的随机数。
通过随机化联系人的注册生命周期,服务器能够更好地处理重启后的 *注册风暴*,当所有 TCP 连接丢失且大部分 UA 将同时重新注册时。由于联系人生命周期随机化,注册风暴只会发生一次,而不是例如在重启后每 1800 秒发生一次。


*默认值为 0(无偏差)。*


```c title="设置 expires_max_deviation 参数"
...
# 向每个注册生命周期添加随机 +/- 0-100 秒
modparam("
```


#### max_contacts (integer)


此参数可用于限制用户位置数据库中每个 AOR(地址记录)的联系人数量。值 0 禁用检查。
这是默认值,仅在未将其他值(对于 max_contacts)作为参数传递给 save() 函数时使用。
也就是说 - 函数参数覆盖此全局参数。


*默认值为 0。*


```c title="设置 max_contacts 参数"
...
# 允许每个 AOR 最多 10 个联系人
modparam("
```


#### max_username_len (integer)


地址记录 SIP URI "username" 部分的最大长度。


默认值为 **64**。


```c title="设置 *max_username_len* 模块参数"
modparam("
```


#### max_domain_len (integer)


地址记录 SIP URI "domain" 部分的最大长度。


默认值为 **64**。


```c title="设置 *max_domain_len* 模块参数"
modparam("
```


#### max_aor_len (integer)


地址记录 SIP URI 的最大长度。


默认值为 **256**。


```c title="设置 *max_aor_len* 模块参数"
modparam("
```


#### max_contact_len (integer)


Contact 头字段 SIP URI 的最大长度。


默认值为 **255**。


```c title="设置 *max_contact_len* 模块参数"
modparam("
```


#### retry_after (integer)


mid-registrar 可以在各种情况下对注册生成 5xx 回复。例如,当
*[max contacts](#param_max_contacts)* 参数
被设置且 REGISTER 请求的处理将超出限制时,就会发生这种情况。
在这种情况下,OpenSIPS 将回复 "503 Service Unavailable"。


如果您想在 5xx 回复中添加 Retry-After 头字段,请将此参数设置为大于零的值(0 表示:不添加头字段)。有关更多详细信息,请参阅 RFC3261 的 20.33 节。


默认值为 **0**(禁用)


```c title="设置 *retry_after* 模块参数"
modparam("mid_registrar", "retry_after", 30)
```


#### disable_gruu (integer)


全局禁用 GRUU 处理。


默认值为 **1**(将不处理 GRUU)


```c title="设置 *gruu_secret* 模块参数"
modparam("mid_registrar", "disable_gruu", 0)
```


#### gruu_secret (string)


生成临时 GRUU 时用于 XOR 操作的字符串。


默认值为 **"0p3nS1pS"**


```c title="设置 *gruu_secret* 模块参数"
modparam("mid_registrar", "gruu_secret", "my_secret")
```


#### pn_enable (boolean)


启用 SIP 推送通知支持([RFC 8599](https://tools.ietf.org/html/rfc8599))。
如果启用,包含所有
[pn ct match params](#param_pn_ct_match_params) 的 Contact 头字段 URI 将仅使用这些参数与现有绑定进行匹配。否则,
模块将尝试按常规方式匹配它们,使用当前的 usrloc [matching_mode](../usrloc#param_matching_mode)。


*默认值为 **false**。*


```c title="设置 pn_enable 参数"
...
modparam("
```


#### pn_providers (string)


支持的推送通知提供商列表。虽然 RFC 8599 仅定义了三个可能的值("apns"、"fcm" 和 "webpush"),
但也可以指定非标准值。


*默认值为 **NULL**
(未设置)。*


```c title="设置 pn_providers 参数"
...
modparam("
```


#### pn_ct_match_params (string)


RFC 8599 所需的最少参数列表(也接受自定义参数),这些参数必须存在于 Contact URI 中并与现有绑定完全匹配,以便在 SIP 重新 REGISTER 时刷新绑定。如果 Contact 头字段 URI 中至少缺少一个此类参数,模块将回退到执行常规联系人匹配。


请注意,如果所有上述 PN Contact URI 参数都与现有绑定匹配,则认为匹配成功,无论 SIP URI 的其他部分是否不匹配(例如主机名、端口、其他 URI 参数等)。


调用 *mid_registrar_lookup()* 或
[afunc pn process purr](#afunc_pn_process_purr) 后,上述 PN 相关参数将自动从生成的 Request 和 Contact URI 事件参数中剥离。


*默认值为 **"pn-provider, pn-prid, pn-param"**。*


```c title="设置 pn_ct_match_params 参数"
...
modparam("
```


#### pn_pnsreg_interval (integer)


对于能够自行唤醒并刷新其绑定的设备(由 *";+sip.pnsreg"*
Contact 头字段参数表示),此设置表示服务器在设备应发出绑定刷新请求之前广告的距过期前的时间间隔。


*默认值为 **130**
(距过期的秒数)。*


```c title="设置 pn_pnsreg_interval 参数"
...
modparam("
```


#### pn_trigger_interval (integer)


如果来自给定 SIP 端点的绑定刷新 REGISTER 请求未在距过期至少 [pn trigger interval](#param_pn_trigger_interval)
秒之前到达(例如因为设备不支持 *";+sip.pnsreg"* 或由于其他错误条件),
则将触发 [E_UL_CONTACT_REFRESH](../usrloc#event_E_UL_CONTACT_REFRESH)
usrloc 事件。


一旦触发 [E_UL_CONTACT_REFRESH](../usrloc#event_E_UL_CONTACT_REFRESH),
脚本编写者应使用 Contact URI 中的 RFC 8599 参数向设备的 PN 提供商生成推送通知请求,
以使设备唤醒并重新注册。


*默认值为 **120**
(距过期的秒数)。*


```c title="设置 pn_trigger_interval 参数"
...
modparam("
```


#### pn_skip_pn_interval (integer)


在成功(重新)注册联系人后,此设置表示一个以秒为单位的时间间隔,在此期间联系人被认为是可达的,因此任何推送通知都将被跳过。


*默认值为 **0** 秒
(始终生成推送通知)。*


```c title="设置 pn_skip_pn_interval 参数"
...
modparam("
```


#### pn_refresh_timeout (integer)


此超时在 *mid_registrar_lookup()* 或
[afunc pn process purr](#afunc_pn_process_purr) 触发推送通知后开始计时。该值表示推送通知发送所需持续时间与相应设备重新注册到达所需持续时间之和的最大允许值。


一旦初始或中期对话请求超过此超时,任何匹配待处理推送通知的后续重新注册都将不再产生预期效果。例如:


- 待处理的初始 INVITE 事务将完成,不再为每个来自被叫方的 REGISTER
自动分叉额外分支
- 待处理的 BYE 消息将超时,OpenSIPS 将尝试路由它们,尽管未收到目标设备实际可达的确认


*默认值为 **6** 秒。*


```c title="设置 pn_refresh_timeout 参数"
...
modparam("
```


#### pn_enable_purr (boolean)


为长期对话启用 SIP 推送通知机制。
如果启用,mid_registrar 将在对 REGISTER 请求的 200 OK 回复中包含
*"+sip.pnspurr"*
Feature-Caps 头字段标签。此标签表示注册的唯一标识符(PURR - Proxy Unique Registration Reference)。


在对话设置期间,每个 UA 可以在其 Contact 头中包含 OpenSIPS 在注册期间返回的 PURR 值。通过包含 PURR(例如 ";pn-purr=XXX"),代理表示它期望在其他方发送的中期对话请求之前首先被 PN 唤醒。


启用此参数时,请确保也为
[afunc pn process purr](#afunc_pn_process_purr) 添加逻辑。


*默认值为 **false**。*


```c title="设置 pn_enable_purr 参数"
...
modparam("
```


### 导出的函数


#### mid_registrar_save(domain[, flags[, aor[, outgoing_expires[, ownership_tag]]]])


在处理 REGISTER 请求时调用的函数。此函数决定是否应将 REGISTER 转发到主 registrar,并对已注册的联系人执行所有必要的更改。该函数还涵盖处理 2xx REGISTER 回复 -- 由主 registrar 确认的联系人将自动保存在本地用户位置(无需任何额外的脚本)。"


在联系人/AOR 限流模式时(在 [工作模式章节](#working_modes) 中了解更多信息),
此函数的返回值指示脚本编写者是否必须将 REGISTER 请求转发到主 registrar,
还是只需结束任何剩余处理并退出脚本执行,因为当前 REGISTER 请求已以 200 OK 回答(
已在 mid-registrar 级别吸收)。


根据当前工作
*[mode](#param_mode)* 和
*[contact id insertion](#param_contact_id_insertion)*,
该函数在转发 REGISTER 请求时可能还会执行以下系列转换:


- 在 *"联系人限流"* 模式中

  - 将 *Expires*
头字段的值更改为
*outgoing_expires*(如果提供)的值,
否则为
*[outgoing expires](#param_outgoing_expires)*
模块参数给出的值。
同样适用于任何 *";expires"*
Contact URI 参数。
  - 用 OpenSIPS 监听接口替换传入 REGISTER 请求的所有 Contact URI 的 "host:port" 部分
  - 向每个
*Contact* URI 附加一个参数,
该参数将允许模块匹配回复联系人并路由呼叫。此 URI
参数的名称可通过
*[contact id param](#param_contact_id_param)* 配置
- 在 *"AOR 限流"* 模式中

  - 将 *Expires*
头字段的值更改为
*outgoing_expires*(如果提供)的值,
否则为
*[outgoing expires](#param_outgoing_expires)*
模块参数给出的值。
  - 用单个 *Contact* 头字段替换请求的所有 *Contact* 头字段,
其中将包含以下 SIP URI: "sip:address-of-record@proxy_ip:proxy_port"


参数的含义如下:


- *domain* (静态字符串) - registrar 中的逻辑域。
如果使用数据库,这是存储联系人的 *usrloc*
表的名称
- *flags* (字符串,可选) - 由以下一个或多个标志组成的字符串,逗号分隔:

  - *'memory-only'* - (旧 *m* 标志)
仅保存到内存缓存,无 DB 操作;
  - *'no-reply'* - (旧 *r* 标志)
不对当前 REGISTER 请求生成 SIP 回复。
  - *'max-contacts=[int]'* - (旧 *c* 标志)
此标志可用于限制此 AOR(地址记录)在用户位置数据库中的联系人数量。
值 0 禁用检查。此参数覆盖全局 "max_contacts" 模块参数。
  - *'force-registration'* - (旧 *f* 标志)
即使达到最大联系人数,此标志也可用于强制注册新联系人。
在这种情况下,旧联系人将被删除以为新联系人腾出空间,而不会超过允许的最大数量。
此标志仅在使用 "max-contacts" 时才有意义。
  - *'matching-mode=[val]'* - (旧 *M* 标志)
如何在上传的联系人(由当前处理的 REGISTER)和已知的联系人(在内存或数据库中)之间执行匹配。此选项仅用于当前操作,可以是:
  
  
*'0'* - 仅联系人 URI 匹配
  
  
*'1'* - 联系人 URI 和 SIP Call-ID 匹配
  
  
*'<param_name>'* - 仅使用给定 URI 参数的值进行匹配(例如 <rinstance>)
  - *'path-off'* - (旧 *p0* 标志)
(Path 支持 - 'off' 模式) - Path 头保存到 usrloc,但从不包含在回复中。
  - *'path-lazy'* - (旧 *p1* 标志)
(Path 支持 - lazy 模式) Path 头保存到 usrloc,但仅在注册请求中由 "Supported" 头的 "path" 选项指示路径支持时才包含在回复中。
  - *'path-strict'* - (旧 *p2* 标志)
(Path 支持 - strict 模式) - 仅在注册请求中由 "Supported" 头的 "path" 选项指示路径支持时,path 头才保存到 usrloc。如果未指示路径支持,请求将以 "420 - Bad Extension" 拒绝,并且回复中包含 "Unsupported: path" 头以及收到的 "Path" 头。此模式是 RFC-3327 推荐的模式。
  - *'path-received'* - (旧 *v* 标志)
如果设置,注册的第一个 Path URI 的 "received" 参数将设置为 received-uri,并为此联系人设置 NAT 分支标志。如果 registrar 位于 SIP 负载均衡器后面,这很有用,该负载均衡器将其 nat'ed UAC 地址作为其 Path uri 中的 "received" 参数传递。
  - *'only-request-contacts'* - (旧 *o* 标志)
如果注册成功,仅在 200 OK 回复中包含 REGISTER 请求的联系人。虽然这违反 RFC 3261,但在某些场景中可能有用。
- *aor (字符串,可选)* - 自定义地址记录。
如果未提供,AOR 将从 *To* 头 URI 获取
- *outgoing_expires (int,可选)* - 仅在联系人/AOR 限流模式中相关,这是传出 REGISTER 请求的联系人过期间隔的自定义值,它覆盖默认的
*[outgoing expires](#param_outgoing_expires)* 模块参数。
- *ownership_tag* (字符串,可选) - 集群共享标签(有关更多详细信息,请参阅 clusterer 模块文档),它将附加到从当前请求保存的每个联系人。此标签仅在集群用户位置场景中相关,有助于确定联系人的当前逻辑所有者节点。这反过来对于限制当前不负责此联系人的节点执行某些操作很有用(例如:在高可用性设置中从非拥有的虚拟 IP 地址错误地发起 ping)。


**返回值**


- 1 (成功) - 当前 REGISTER 请求必须由脚本编写者转发到主 registrar
- 2 (成功) - 当前 REGISTER 请求已被 mid-registrar 吸收;已向上游发送 200 OK 回复
- -1 (错误) - 通用错误代码;日志应提供更多帮助


此函数只能从请求路由中使用。


```c title="mid_registrar_save 使用示例"
...
if (is_method("REGISTER")) {
	mid_registrar_save("location");
	switch ($retcode) {
	case 1:
		xlog("L_INFO", "正在将 REGISTER 转发到主 registrar...\n");
		$ru = "sip:10.0.0.3:5070";
		if (!t_relay()) {
			send_reply(500, "服务器内部错误 1");
		}

		break;
	case 2:
		xlog("L_INFO", "REGISTER 已被吸收!\n");
		break;
	default:
		xlog("L_ERR", "mid-registrar 错误!\n");
		send_reply(500, "服务器内部错误 2");
	}

	exit;
}
...
```


#### mid_registrar_lookup(domain[, [flags][, [aor]]])


在从主 registrar 接收请求时调用(要路由到最终用户)。它执行本地查找(在用户位置中)和必要的 RURI 处理,以便将请求进一步路由到最终用户注册的联系人(请注意,查找后可能产生多个分支/目的地)。


根据当前工作
*[mode](#param_mode)*,
该函数的行为如下:


- 在 *"镜像"* 模式中

  - 从 Request-URI 中提取用户名(地址记录),并查找存储在用户位置中的所有其联系人绑定。Request-URI(**$ru** 变量)将被最高 q 值的联系人覆盖,根据 *flags* 参数,可选择为每个其他联系人创建额外分支。
- 在 *"联系人限流"* 模式中

  - 从 Request-URI 中提取 *[contact id param](#param_contact_id_param)*,
从中派生目标 SIP URI 并将其设置为 INVITE 的新 Request-URI(**$ru** 变量)。
- 在 *"AOR 限流"* 模式中

  - 从 Request-URI 中提取用户名(地址记录),并查找存储在用户位置中的所有其联系人绑定。Request-URI(**$ru** 变量)将被最高 q 值的联系人覆盖,根据 *flags* 参数,可选择为每个其他联系人创建额外分支。


参数的含义如下:


- *domain (静态字符串)* - registrar 中的逻辑域。
如果使用数据库,这是存储联系人的 *usrloc*
表的名称
- *flags (字符串,可选) - 由以下一个或多个标志组成的字符串,逗号分隔:*

  - *'no-branches'* - (旧 *b* 标志)
此标志控制 *mid_registrar_lookup()* 函数如何处理多个联系人。
如果 usrloc 中有多个给定用户名的联系人且未设置此标志,
Request-URI 将被最高 q 值联系人覆盖,其余的将被追加到
sip_msg 结构中,可供 tm 用于分叉。如果设置了此标志,
只有 Request-URI 将被最高 q 值联系人覆盖,其余的将被保留不处理。
  - *'to-branches-only'* - (旧 *B* 标志)
此标志强制将所有找到的联系人仅作为分支(在目的地集中)上传,根本不上传到当前消息的 R-URI。使用此选项还允许 *mid_registrar_lookup()* 函数在 SIP 回复的上下文中使用。
  - *'branch'* - (旧 *r* 标志)
此标志启用通过现有分支搜索 AOR 并将其扩展到联系人的功能。例如,您的 ruri 中有 AOR A,但您也想将呼叫转发到 AOR B。为此,您必须将 AOR B 放在分支中,如果此标志启用,函数也会将 AOR B 扩展到联系人,这将放回分支中。函数调用之前在分支中的 AOR 将被删除。
**警告:**
*如果您想启用此标志,'no-branches' 标志必须未设置,因为通过设置该标志,您将不允许 *mid_registrar_lookup()* 写入分支。*
  - *'method-filtering'* - (旧 *m* 标志)
设置此标志将启用基于注册期间列出的 "Allow" 头字段中支持的方法的联系人过滤。
在注册期间未显示 "Allow" 头字段的联系人被认为支持所有标准 SIP 方法。
  - *'ua-filtering=[val]'* (旧 *u* 标志)
(用户代理过滤) - 此标志启用按用户代理的正则表达式过滤。它与启用的 append_branches 参数一起使用很有用。值必须使用 '/regexp/' 格式。
  - *'case-insensitive'* (旧 *i* 标志) -
此标志为 'ua-filtering' 标志启用不区分大小写的过滤。
  - *'extended-regexp'* - (旧 *e* 标志)
此标志为 'ua-filtering' 标志启用扩展正则表达式格式。
  - *'global'* (旧 *g* 标志)(全局查找) - 此标志仅与联合用户位置集群相关。如果设置,*mid_registrar_lookup()* 函数不仅会执行经典的内存 "搜索-AoR-推送分支" 操作,还会执行元数据查找并为每个返回结果追加额外分支。"内存分支" 对应本地联系人(当前位置),而 "元数据分支" 对应平台上其他位置可用的联系人。AoR 元数据包含一个 VoIP 平台位置(数据中心)为全球平台广告本地注册的 AoR 存在所需的最少信息。具体来说,这由两部分组成:


AoR(例如 "vladimir@federation-cluster")


主 IP(例如 "10.0.0.223")
  - *'max-ping-latency=[int]'* - (旧 *y* 标志)最大可接受的联系人 ping 延迟(微秒)。在 *mid_registrar_lookup()* 期间,延迟较高的 AoR 的联系人将被丢弃。
  - *'sort-by-latency'* - (旧 *Y* 标志)
联系人将按其上次成功 ping 延迟的升序选择(最快 ping -> 最慢 ping)。此标志可与 "max-ping-latency" 标志一起使用。
- *aor (字符串,可选)* - 自定义地址记录。
如果未提供,AOR 将从 *Request-URI* 获取


返回码:


- **1** - 找到联系人并成功推送为分支。需要唤醒才能可达的联系人正在通过异步推送通知通知。
- **2** - 成功为找到的联系人启动了至少一个异步推送通知,但未填充额外分支(即不需要调用 t_relay())。
- **-1** - 未找到联系人。
- **-2** - 找到联系人,但都不支持当前 SIP 方法。
- **-3** - 处理期间发生内部错误。


此函数只能从请求路由中使用。


```c title="mid_registrar_lookup 使用示例"
...
	# 来自主 registrar 的初始邀请 - 需要查找它们!
	if (is_method("INVITE") and $si == "10.0.0.3" and $sp == 5070) {
		if (!mid_registrar_lookup("location")) {
			t_reply(404, "未找到");
			exit;
		}

		if (!t_relay())
			send_reply(500, "服务器内部错误 3");

	    exit;
	}
...
```


### 导出的异步函数


#### pn_process_purr(domain)


根据 RFC 8599 执行中期对话请求处理。对于此类请求,在 R-URI 和最顶层 Route 头字段 URI 中搜索 *";pn-purr"* 参数值,该值既符合 OpenSIPS PURR 格式又对应于某个 usrloc 注册。找到 usrloc 联系人后,触发 [E_UL_CONTACT_REFRESH](../usrloc#event_E_UL_CONTACT_REFRESH) 事件,并将请求置于异步等待状态,最长等待 [pn refresh timeout](#param_pn_refresh_timeout) 秒,直到收到匹配的 REGISTER 请求。


如果在触发推送通知之前处理结束,请求将不再被置于异步等待状态,恢复路由将立即被调用。


参数的含义如下:


- *domain (静态字符串)* - registrar 中的逻辑域。
如果使用数据库,这是存储联系人的表的名称。


**返回码**


- **1** - 成功,PN 已启动。
- **2** - 成功,但 PN 未启动(由于缺少 PURR、外部 PURR 或离线联系人)
- **-1** - 内部错误


```c title="异步 pn_process_purr() 使用示例"
route {
	...
	if (has_totag()) {
		if (is_method("ACK") && t_check_trans()) {
			t_relay();
			exit;
		}

		if (!loose_route()) {
			send_reply(404, "未找到");
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
	xlog("pn_process_purr() 完成,返回 $var(rc)\n");

	...
}
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)均采用 Creative Common License 4.0 授权
