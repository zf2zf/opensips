---
title: "TM 模块"
description: "TM 模块启用 SIP 事务的有状态处理。有状态逻辑的主要用途（代价高昂的内存和 CPU）是某些服务本身需要状态。例如，基于事务的计费（acc 模块）需要处理事务状态而不是单个消息，任何类型的分叉都必须以有状态方式实现。有状态处理的另一个用途是用内存换取因重传处理而消耗的 CPU。"
---

## 管理指南

### 概述

TM 模块启用 SIP 事务的有状态处理。有状态逻辑的主要用途（代价高昂的内存和 CPU）是某些服务本身需要状态。例如，基于事务的计费（acc 模块）需要处理事务状态而不是单个消息，任何类型的分叉都必须以有状态方式实现。有状态处理的另一个用途是用内存换取因重传处理而消耗的 CPU。

但这只有在每个请求的 CPU 消耗巨大的情况下才有意义。例如，如果您想避免对每个重传请求到不可解析的目标进行昂贵的 DNS 解析，请使用有状态模式。这样，只有初始消息会占用服务器的 DNS 查询资源，后续重传将被丢弃，不会导致更多进程阻塞在 DNS 解析上。代价是更多的内存消耗和更高的处理延迟。

从用户的角度来看，主要功能是 t_relay()。它设置事务状态，吸收来自上游的重传，生成下游重传，并将回复关联到请求。

一般来说，如果使用 TM，它会在共享内存中复制接收到的 SIP 消息的克隆。这会消耗内存和 CPU 时间（memcpy、查找、shmem 锁等）。请注意，非 TM 函数在私有内存中操作接收到的消息，这意味着在创建事务状态后，任何核心操作都不会影响有状态处理的消息。例如，在 t_relay() 之后调用 record_route 是毫无用处的，因为 RR 被添加到私有保存的消息中，而其 TM 克隆正在被转发。

TM 相当庞大且难以编程——大量的互斥锁、共享内存访问、malloc 和 free、定时器——您在做任何事情时都需要非常小心。为了简化 TM 编程，有一种称为回调的工具。回调机制允许程序员注册他们的函数到特定事件。请参阅 t_hooks.h 获取可能的事件列表。

程序员可能想了解的其他内容是 UAC——它是一个非常简单的代码，允许您生成自己的事务。对于 NOTIFY 或 IM 网关之类的事情特别有用。UAC 负责所有事务机制：重传、FR 超时、分叉等。有关更多详细信息，请参阅 uac.h 中的 t_uac 原型。想要查看事务结果的人可以注册回调。

#### 分支标志

首先，分支概念的想法是什么：分支路由是在发送之前为每个分支单独执行的路由——该路由中的更改应该只反映在该分支上。

OpenSIPS 中有几种类型的标志：

- *消息/事务* 标志——它们在事务中处处可见（在所有路由和所有顺序回复/请求中）。
- *分支* 标志——仅从特定分支可见的标志——在所有连接到此分支的回复和路由中可见。
- *脚本* 标志——仅在脚本执行期间存在的标志。它们不存储在任何地方，一旦离开顶级路由就会丢失。

例如：我有一个并行分叉呼叫到网关和用户。我想知道从哪个分支我会得到最终负面回复（如果有的话）。我将在转发呼叫之前设置分支路由（带有 2 个分支）。分支路由将为每个分支单独执行；在去往网关的分支中（我可以通过查看 RURI 来识别它），我将设置一个分支标志。此标志将仅出现在为来自网关的回复运行的 onreply 路由中。如果最终选定的回复属于网关分支，它也将在 failure 路由中可见。此标志不会在另一个分支中可见（在与另一个分支的回复执行的路由中）。

有关如何定义分支标志并通过脚本使用的更多信息，请参阅 [t on branch](#func_t_on_branch) 以及 setbflag()、resetbflag() 和 isbflagset() 脚本函数。

此外，模块可以在事务创建之前设置分支标志（目前脚本中此功能不可用）。REGISTRAR 模块是第一个使用此类标志的模块。NAT 标志被推入分支标志而不是消息标志。

#### 基于超时故障转移

超时可用于触发故障转移行为。例如，如果我们向网关发送呼叫而网关在 3 秒内没有发送临时回复，我们想取消此呼叫并将其发送到另一个网关。另一个示例是仅响铃 SIP 客户端 30 秒，然后将呼叫重定向到语音邮件。

事务模块导出两种类型的超时：

- **[fr timeout](#param_fr_timeout)** ——用于未收到回复时。如果在 *[fr timeout](#param_fr_timeout)* 秒后没有回复，定时器将触发（如果调用了 t_on_failure()，将执行 failure 路由）。对于 INVITE 事务，如果收到临时回复，超时将重置为 *[fr inv timeout](#param_fr_inv_timeout)* 秒，对于所有其他事务重置为 RT_T2。一旦收到最终回复，事务就完成了。
- **fr_inv_timeout** ——此超时在收到 INVITE 事务的临时回复后开始倒计时。

例如：如果在 3 秒后没有临时回复您想要故障转移，但您想响铃 60 秒。因此，将 *[fr timeout](#param_fr_timeout)* 设置为 3，将 *fr_inv_timeout* 设置为 60。

#### DNS 故障转移

DNS 故障转移可用于有状态转发请求时。根据 RFC 3263，DNS 故障转移应在传输层或事务层完成。TM 模块两者都支持。

传输层的故障转移可能在发送请求消息失败时触发。如果找到发送请求的相应接口、TCP 连接被拒绝或在发送过程中发生通用内部错误，则会发生故障。没有 ICMP 错误报告支持。

事务层的故障转移可能在事务以 503 回复完成或超时且未收到任何回复时触发。在这种情况下，如果有任何其他目标 IP 可用于传递请求，将自动分叉一个新分支。新分支将是获胜分支的克隆。

目标 IP 集是基于目标域的 NAPTR、SRV 和 A 记录逐步（按需）构建的。

DNS 故障转移默认应用，除非该故障转移被全局禁用（请参阅核心参数 disable_dns_failover）或设置了中继标志（每个事务）（请参阅 t_relay() 函数）。

#### Anycast 场景

使用 [Anycast IPs](https://en.wikipedia.org/wiki/Anycast) 进行负载均衡场景时，可能会遇到这样一个问题：事务请求出现在一个实例上，而回复（或回复）出现在不同的实例上。这通常会破坏事务状态，因为本地事务将开始重新传输，最终会超时。此外，从 UA 的角度来看，回复已经发送，但由于它到达的代理不知道该事务，它不会被转发（INVITE 情况下也不会被 ACK）。从这里开始，事情可能会迅速升级。

为了解决这些问题，该模块使用了一种分布式机制来确定特定回复的事务是在哪里创建的。当实例收到没有关联事务的回复时，它会被复制以由"拥有"它的实例处理。这是通过 *clusterer* 模块支持实现的。

设置 anycast 场景非常简单：所有属于 anycast 场景的实例都必须设置在一个集群中（更多信息请参阅 [tm replication cluster](#param_tm_replication_cluster) 参数）。创建事务时，会向分支参数附加一个特殊标识符，即创建事务的实例。当回复到达时，事务模块检查谁"拥有"该事务。如果标识符是实例自己的 id，则回复在本地处理。否则，它会被复制到 id 指定的节点。复制以非常有效的方式完成，使用 *proto_bin* 传输。

对 *CANCEL* 和 *ACK* 方法应用特殊处理。由于这些方法不在分支参数中包含特殊标识符（因为它们是由 UAC 生成的而不是由我们生成的），因此无法确定谁"拥有"该事务。因此，如果我们没有找到这些请求的本地事务，我们会使用 [t anycast replicate](#func_t_anycast_replicate) 函数将它们广播到所有其他实例。同样，这是使用 *proto_bin* 传输以非常有效的方式完成的。

#### 使用范围

事务函数和变量仅设计为在可以创建事务的 SIP 请求消息上调用，或在事务感知的路由中调用，例如 *branch_route[name]*、*failure_route[name]* 或 *onreply_route[name]*。在非事务感知的路由（如通用 *onreply_route*、*error_route* 或 *timer_route[name, timer]*）中使用 TM 函数或变量可能导致未定义行为，并且在大多数情况下会导致虚假或格式错误的信令。因此，强烈建议避免在非 tm 上下文感知路由中使用它们。

### 依赖

#### OpenSIPS 模块

以下模块必须在此模块之前加载：

- *clusterer* 模块，如果启用了 anycast 场景（请参阅 [tm replication cluster](#param_tm_replication_cluster) 参数了解更多信息的 param）。

#### 外部库或应用程序

运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：

- *无*。

### 导出的参数

#### fr_timeout (integer)

如果在请求的 ACK 或对负面 INVITE 回复的最终回复没有到达，则触发的超时（以秒为单位）。

*默认值为 30 秒。*

```c title="设置 fr_timeout 参数"
...
modparam("tm", "fr_timeout", 10)
...
```

#### fr_inv_timeout (integer)

在收到临时消息后，对 INVITE 的最终回复未到达时触发的超时（以秒为单位）。此超时在收到第一个临时回复后开始倒计时。因此，通过将 *[fr timeout](#param_fr_timeout)* 设置为较低值可以实现快速故障转移（网关没有 100 trying）。请参阅下面的示例。

*默认值为 120 秒。*

```c title="设置 fr_inv_timeout 参数"
...
modparam("tm", "fr_inv_timeout", 200)
...
```

#### wt_timer (integer)

事务在完成后保持在内存中以吸收延迟消息的时间；此外，当此定时器触发时，本地取消的重传将停止（一种纯粹但复杂的行为是在本地分支被最终回复或 FR 定时器完成之前不进入等待状态——我们简化了）。

对于非 INVITE 事务，此定时器与 RFC 3261 第 17.2.2 节的定时器 J 相关。根据 RFC，此定时器应为 64*T1（= 32 秒）。但这会增加内存使用，因为事务在内存中保留的时间很长。

*默认值为 5 秒。*

```c title="设置 wt_timer 参数"
...
modparam("tm", "wt_timer", 10)
...
```

#### delete_timer (integer)

进程当前引用的待删除事务将再次尝试删除的时间。

*默认值为 2 秒。*

```c title="设置 delete_timer 参数"
...
modparam("tm", "delete_timer", 5)
...
```

#### T1_timer (integer)

重传 T1 周期，以毫秒为单位。

*默认值为 500 毫秒。*

```c title="设置 T1_timer 参数"
...
modparam("tm", "T1_timer", 700)
...
```

#### T2_timer (integer)

最大重传周期，以毫秒为单位。

*默认值为 4000 毫秒。*

```c title="设置 T2_timer 参数"
...
modparam("tm", "T2_timer", 8000)
...
```

#### ruri_matching (integer)

是否应将 request-uri 匹配用作标准要求的 pre-3261 事务匹配的一部分？仅在为与发送不同 CANCEL/ACK 中的 r-uri 的损坏设备进行更好的交互而关闭。

*默认值为 1（true）。*

```c title="设置 ruri_matching 参数"
...
modparam("tm", "ruri_matching", 0)
...
```

#### via1_matching (integer)

是否应将最顶层 VIA 匹配用作标准要求的 pre-3261 事务匹配的一部分？仅在为与发送不同 CANCEL/ACK 中最顶层 VIA 的损坏设备进行更好的交互而关闭。

*默认值为 1（true）。*

```c title="设置 via1_matching 参数"
...
modparam("tm", "via1_matching", 0)
...
```

#### unix_tx_timeout (integer)

使用 UNIX 套接字的函数（如 t_write_unix）使用的发送超时。

*默认值为 2 秒。*

```c title="设置 unix_tx_timeout 参数"
...
modparam("tm", "unix_tx_timeout", 5)
...
```

#### restart_fr_on_each_reply (integer)

如果为 true（非零值），最终回复定时器将为每个收到的临时回复重新触发。在这种情况下，最终回复超时可能在比 *[fr inv timeout](#param_fr_inv_timeout)* 更长的时间后发生（如果 UAS 继续发送临时回复）。

*默认值为 1（true）。*

```c title="设置 restart_fr_on_each_reply 参数"
...
modparam("tm", "restart_fr_on_each_reply", 0)
...
```

#### tw_append (string)

t_write_req 和 t_write_unix 函数追加的附加信息列表。

*默认值为空字符串。*

参数的语法如下：

- *tw_append = append_name':' element (';'element)*
- *element = ( [name '='] variable)*

每个元素将以 "name: value" 格式每行追加。元素 "$rb（消息体）" 是唯一不接受名称的元素；它将始终在最后打印，不管其在定义字符串中的位置如何。

```c title="设置 tw_append 参数"
...
modparam("tm", "tw_append",
   "test: ua=$hdr(User-Agent) ;avp=$avp(avp);$rb;time=$Ts")
...
```

#### pass_provisional_replies (integer)

启用/禁用向 FIFO 应用程序传递临时回复。

*默认值为 0。*

```c title="设置 pass_provisional_replies 参数"
...
modparam("tm", "pass_provisional_replies", 1)
...
```

#### syn_branch (integer)

启用/禁用生成 Via 头中有状态同义分支 ID。它们更快，但重启不安全。

*默认值为 1（使用同义分支）。*

```c title="设置 syn_branch 参数"
...
modparam("tm", "syn_branch", 0)
...
```

#### onreply_avp_mode (integer)

描述在回复路由中应如何处理 AVP：

- *0* ——AVP 将仅按消息可见；它们不会干扰存储在事务中的 AVP；最初会有一个空列表，在路由结束时，所有创建的 AVP 将被丢弃。
- *1* ——AVP 将是事务 AVP；最初事务 AVP 可见；在路由结束时，列表将附加回事务（并包含所有更改）

在模式 1 中，您可以看到在请求路由、分支路由或失败路由中设置的 AVP。副作用是性能，因为需要更多锁定来保持 AVP 列表完整性。

*默认值为 0。*

```c title="设置 onreply_avp_mode 参数"
...
modparam("tm", "onreply_avp_mode", 1)
...
```

#### disable_6xx_block (integer)

告诉应如何内部处理 6xx 回复：

- *0* ——6xx 回复将阻止任何进一步的串行分叉（添加新分支）。这是 RFC3261 行为。
- *1* ——6xx 回复将像任何其他负面回复一样处理——允许串行分叉。如果你想做重定向到公告和语音邮件服务，则需要破坏 RFC3261。

*默认值为 0。*

```c title="设置 disable_6xx_block 参数"
...
modparam("tm", "disable_6xx_block", 1)
...
```

#### enable_stats (integer)

在 TM 模块中启用统计支持——如果启用，TM 模块将在内部保留多个统计并通过 MI（管理接口）导出它们。

*默认值为 1（启用）。*

```c title="设置 enable_stats 参数"
...
modparam("tm", "enable_stats", 0)
...
```

#### minor_branch_flag (string/integer)

脚本中用于标记次要分支（在 t_relay() 之前）的分支标志索引。

次要分支是 OpenSIPS 在并行分叉期间不会等待完成的分支。因此，如果其他分支被负面回复，OpenSIPS 不会等待次要分支的最终答案，而是直接取消它。

次要分支的主要适用场景是分叉一个分支到媒体服务器以通过 183 早期媒体注入一些呼叫前媒体——当然，此分支对于其余呼叫分支（从分支选择点的角度来看）是透明的。

*默认值为无（禁用）。*

```c title="设置 minor_branch_flag 参数"
...
modparam("tm", "minor_branch_flag", "MINOR_BFLAG")
...
```

#### timer_partitions (integer)

内部 TM 定时器（重传、删除、等待等）的分区数量。分区定时器通过并行处理定时器事件而不是全部串行处理来提高重负载下的吞吐量。

建议的定时器分区范围是最大 16（软限制）。

*默认值为 1（禁用）。*

```c title="设置 timer_partitions 参数"
...
# 启用两个定时器分区
modparam("tm", "timer_partitions", 2)
...
```

#### auto_100trying (integer)

此参数控制 TM 模块是否应在创建 INVITE 事务时自动生成 100 Trying 有状态回复。

如果您想从脚本级别控制 100 Trying 的发送时间，您可能希望禁用此行为。

*默认值为 1（启用）。*

```c title="设置 auto_100trying 参数"
...
# 禁用自动 100 Trying
modparam("tm", "auto_100trying", 0)
...
```

#### tm_replication_cluster (integer)

此参数应用于 anycast 设置，指定所有使用 anycast IP 的节点的集群 ID。

有关更多详细信息，请参阅 [tm anycast](#anycast_scenario) 部分。

*默认情况下，Anycast 复制被禁用。*

```c title="设置 tm_replication_cluster 参数"
...
# 在集群 1 中复制 anycast 消息
modparam("tm", "tm_replication_cluster", 1)
...
```

#### cluster_param (string)

此参数应用于 anycast 设置，指定在 VIA 分支参数中用于指定创建事务的实例 id 的参数名称。

有关更多详细信息，请参阅 [tm anycast](#anycast_scenario) 部分。

*默认值为 *cid*。*

```c title="设置 cluster_param 参数"
...
modparam("tm", "cluster_param", "tid")
...
```

#### cluster_auto_cancel (boolean)

此参数应用于 anycast 设置，指定是否应自动处理在标记为 anycast 的监听器上收到的 *CANCEL* 消息，或者是否应进入 OpenSIPS 脚本。如果此参数启用（默认），在 anycast 监听器上收到的 *CANCEL* 消息将永远不会进入脚本，从而使脚本更清晰。

有关更多详细信息，请参阅 [tm anycast](#anycast_scenario) 部分。

*默认值为 *yes*（启用）。*

```c title="设置 cluster_auto_cancel 参数"
...
# 禁用自动取消处理
modparam("tm", "cluster_auto_cancel", no)
...
```

#### local_request_route (string)

此参数指向一个路由，每当 TM 即将发送本地生成的请求时（例如，通过 B2B 模块或通过 MI）就会执行。

此路由的目的仅限于将请求的内容作为 SIP 消息公开。

该路由使用 TM 生成的消息执行，结合了该路由中的所有修改。

重要提示：此路由在 local_route（如果已定义）之后执行，并且它公开了该路由的所有更改。

重要提示：此路由应以只读方式使用，仅供检查。您在此处所做的任何更改都将被丢弃。

重要提示：此路由不提供任何消息、事务或对话框上下文，因此不要依赖任何有作用域的变量（如 AVP）。

```c title="设置 local_request_route 参数"
...
# 发送请求时执行路由 "local_request_route"
modparam("tm", "local_request_route", "tm_local_request")

route[tm_local_request] {
	if (is_method("INVITE") && $rb(application/sdp) && !has_totag()) {
		$avp(sdp_request) := $rb(application/sdp);
	}
}
...
```

#### local_reply_route (string)

此参数指向一个路由，每当 TM 即将发送本地生成的回复时（例如，通过 B2B 模块或通过 MI）就会执行。

此路由的目的仅限于将回复的内容作为 SIP 消息公开。

重要提示：此路由应以只读方式使用，仅供检查。您在此处所做的任何更改都将被丢弃。

重要提示：此路由不提供任何消息、事务或对话框上下文，因此不要依赖任何有作用域的变量（如 AVP）。

```c title="设置 local_reply_route 参数"
...
# 发送请求时执行路由 "tm_local_reply"
modparam("tm", "local_reply_route", "tm_local_reply")

route[tm_local_reply] {
	if (is_method("BYE")) {
		$var(rc) = rest_get("http://localhost/qos/delete",
					$var(recv_body), $var(recv_ct), $var(rcode));
	}
}

...
```

### 导出的函数

#### t_relay([flags],[outbound_proxy])

将有状态消息转发到当前 URI 指示的目标。（如果原始 URI 被 UsrLoc、RR、strip/prefix 等重写，将采用新 URI。）失败时返回负值——您可能仍想向上游无状态发送负面回复，以免让上游 UAC 陷入困境。

相应的事务可能已经创建也可能尚未创建。如果尚未创建，该函数将自动创建它。

该函数可以接受两个可选参数。

第一个参数是用于控制内部行为的字符串标志的逗号分隔列表。支持的标志如下：

- *no-auto-477* ——（旧 *0x02* 标志）在全局转发失败（即每个分支的转发由于内部错误、错误 R-URI、错误消息、网络不可达等原因失败）的情况下，不内部生成并发送 "477 Send failed (477/TM)" SIP 回复。

  此标志仅在事务之前未由 [t newtran](#func_t_newtran) 创建时适用。当发生全局转发失败时，不会转发 SIP 请求，因此不会在 failure_route 中显示负面 SIP 回复或超时（如果设置了一个）。
  如果您想为当前创建的所有分支都无法转发的情况实现故障转移逻辑，这很有用。
- *no-dns-failover* ——（旧 *0x04* 标志）禁用事务的 DNS 故障转移。将仅使用第一个 IP。它在传输层和事务层都禁用故障转移。
- *pass-reason-hdr* ——（旧 *0x08* 标志）如果请求是 CANCEL，则信任并传递接收到的 CANCEL 中的 Reason 头——简而言之，将传播 Reason 头。
- *allow-no-cancel* ——（旧 *0x10* 标志）允许 OpenSIPS 检查并遵循 Content-Disposition "no-cancel" 指示（如果存在）。根据 RFC3841 第 9.1 节，TM 模块可以被指示在收到 2xx 回复时不取消所有进行中的分支。它将保持待定分支进行中，直到 (1) 所有分支收到最终回复或 (2) 事务达到超时。

第二个参数是表示出站代理（固定目的地）的字符串，消息应被发送到哪里。目的地指定为 "[proto:]host[:port]"。如果在此函数调用之前为此消息设置了目标 URI "$du"，则将使用该值而不是函数参数。

出错时，函数返回以下代码：

- *-1* ——通用内部错误
- *-2* ——错误消息（解析错误）
- *-3* ——没有可用目的地（未添加分支或请求已取消）
- *-4* ——错误目的地（无法解析的地址）
- *-5* ——目的地被过滤（列入黑名单）
- *-6* ——通用发送失败

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE 使用。

```c title="t_relay 使用示例"
...
if (!t_relay()) {
    sl_reply_error();
    exit;
}
...
t_relay( ,"tcp:192.168.1.10:5060");
...
t_relay(0x1, "mydomain.com:5070");
...
```

#### t_reply(code, reason_phrase)

向当前处理的请求发送有状态 SIP 回复。请注意，如果事务尚未创建，它将自动通过内部使用 `t_newtran` 函数创建。

参数的含义如下：

- *code (int)* ——回复代码编号。
- *reason_phrase (string)* ——原因字符串。

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE 使用。

```c title="t_reply 使用示例"
...
t_reply(404, "Use $rU not found");
...
```

#### t_reply_with_body(code, reason_phrase, body)

向当前处理的请求发送带有包体的有状态 SIP 回复。请注意，如果事务尚未创建，它将自动通过内部使用 `t_newtran` 函数创建。

参数的含义如下：

- *code (int)* ——回复代码编号。
- *reason_phrase (string)* ——原因字符串。
- *body (string)* ——回复包体。

此函数可以从 REQUEST_ROUTE 和 FAILURE_ROUTE 使用。

```c title="t_reply_with_body 使用示例"
...
	if(is_method("INVITE"))
	{
		append_to_reply("Contact: $var(contact)\r\n"
				"Content-Type: application/sdp\r\n");
		t_reply_with_body(200, "Ok", $var(body));
		exit;
	}
...
```

#### t_newtran()

为当前处理的 SIP 请求创建 SIP 事务，从而切换到有状态处理。对于 INVITE 请求，除非 [auto 100trying](#param_auto_100trying) 被禁用，否则将立即发送 100 Trying 回复。一旦 SIP 事务被创建，对重传请求调用 [t newtran](#func_t_newtran) 将结束 OpenSIPS 脚本执行，最后发送的回复将被重传到上游。

此函数可以从 REQUEST_ROUTE 使用。

```c title="t_newtran 使用示例"
...
t_newtran();  # 100 Trying 在此触发
xlog("执行我的复杂路由逻辑\n");
....
t_relay(); # 进一步发送呼叫
...
```

#### t_check_trans()

如果当前请求与事务相关联，则返回 true。请求和事务之间的关系定义如下：

- *非 CANCEL/非 ACK 请求* ——如果请求属于事务（它是重传），函数将执行标准重传处理，并将 break/stop 脚本。如果请求不是重传，函数返回 false。
- *CANCEL 请求* ——如果被取消的 INVITE 事务存在，则为 true。
- *ACK 请求* ——如果 ACK 是（对负面回复的）逐跳 ACK（对应于先前的 INVITE 事务），则为 true。重要提示：对于端到端 ACK（对来自不同事务的 2xx 回复），此函数返回 false（返回代码 *-2*）。

注意：要使用此函数检测重传，您必须确保初始请求已经创建了事务，例如通过使用 t_relay()。如果请求处理可能需要很长时间（例如数据库查找）并且重传在调用 t_relay() 之前到达，您可以使用 t_newtran() 函数手动创建事务。

此函数可以从 REQUEST_ROUTE 和 BRANCH_ROUTE 使用。

```c title="t_check_trans 使用示例"
...
if ( is_method("CANCEL") ) {
	if ( t_check_trans() )
		t_relay();
	exit;
}
...
```

#### t_check_status(re)

如果正则表达式 "re" 匹配响应消息的回复代码，则返回 true，如下所示：

- *在路由块中* ——最后发送的回复代码。
- *在 on_reply 块中* ——当前收到的回复代码。
- *在 on_failure 块中* ——选定的负面最终回复代码。

此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE 和 BRANCH_ROUTE 使用。

```c title="t_check_status 使用示例"
...
if (t_check_status("(487)|(408)")) {
    log("487 或 408 负面回复\n");
}
...
```

#### t_local_replied(reply)

如果所有或最后（取决于参数）回复都是本地生成的（而不是收到的），则返回 true。

参数可以是 "all" 或 "last"。

此函数可以从 REQUEST_ROUTE、BRANCH_ROUTE、FAILURE_ROUTE 和 ONREPLY_ROUTE 使用。

```c title="t_local_replied 使用示例"
...
if (t_local_replied("all")) {
	log ("未收到回复\n");
}
...
```

#### t_was_cancelled()

如果为被 UAC 端通过 CANCEL 请求明确取消的 INVITE 事务调用，则返回 true。

此函数可以从 ONREPLY_ROUTE、FAILURE_ROUTE 使用。

```c title="t_was_cancelled 使用示例"
...
if (t_was_cancelled()) {
    log("事务被 UAC 取消\n");
}
...
```

#### t_cancel_branch([flags])

当收到取消当前呼叫的一组分支（请参阅标志）的回复时调用此函数。

参数的含义如下：

- *flags (string, optional)* ——一组标志（基于字符的标志）用于控制要取消哪些分支：

  - *a* ——全部——取消所有进行中的分支
  - *o* ——其他——取消除当前分支外的所有其他进行中分支
  - *空* ——当前——仅取消当前分支

此函数可以从 ONREPLY_ROUTE 使用。

```c title="t_cancel_branch 使用示例"
onreply_route[3] {
...
	if (t_check_status(183)) {
		# 不支持早期媒体
		t_cancel_branch();
	}
...
}
```

#### t_new_request( method, RURI, from, to [, body[, ctx]])

生成并发送一个新的 SIP 请求（以有状态方式）。新请求与当前处理的 SIP 消息完全无关。

参数的含义如下（所有参数都接受变量）：

- *method (string)* ——SIP 方法
- *RURI (string)* ——SIP Request URI（请求将被发送到此目的地）
- *from (string)* ——SIP From 头信息，格式为 "[display ]URI"
- *to (string)* ——SIP To 头信息，格式为 "[display ]URI"
- *body (string, optional)* ——SIP 包体内容，以内容类型字符串开头："content_type body"
- *ctx (string, optional)* ——将作为 AVP 添加到新事务的上下文字符串，名称为 "uac_ctx"（可能在本地路由中可见）

```c title="t_new_request 使用示例"
...
	# 发送 MESSAGE 请求
	t_new_request("MESSAGE","sip:alice@192.168.2.2","BOB sip:userB@mydomain.net","ALICE sip:userA@mydomain.net","text/plain Hello Alice!")) {
...
```

#### t_on_failure(failure_route)

设置回复路由块，当事务以负面结果完成但在发送最终回复之前控制权将传递给它。在所引用的块中，您可以启动新分支（适用于 forward_on_no_reply 等服务）或自行发送最终回复（适用于例如消息存储库，它从上游收到负面回复并想告诉上游"202 我来处理它"）。

由于并非所有函数都可从 failure 路由使用，请查看每个函数的文档以了解权限。任何其他命令可能导致不可预测的行为和可能的服务器故障。

只能为请求设置一个 failure_route。如果您多次使用 t_on_failure()，只有最后一个有效。

请注意，每当初入 failure_route 时，RURI 被设置为获胜分支的值。

参数的含义如下：

- *failure_route (string)* ——要调用的回复路由块。

此函数可以从 REQUEST_ROUTE、BRANCH_ROUTE、ONREPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="t_on_failure 使用示例"
...
route { 
	t_on_failure("1"); 
	t_relay();
} 

failure_route[1] {
	seturi("sip:user@voicemail");
	t_relay();
}
...
```

#### t_on_reply(reply_route)

设置回复路由块，每次为事务收到回复（临时或最终）时控制权将传递给它。本地生成的回复不会调用此路由！ 在所引用的块中，您可以检查回复并对其执行文本操作。

由于并非所有函数都可从这种路由使用，请查看每个函数的文档以了解权限。任何其他命令可能导致不可预测的行为和可能的服务器故障。

如果从分支路由调用，回复路由将仅设置为当前分支——也就是说，它将仅对属于该特定分支的回复调用。当然，从分支路由，您可以为每个分支设置不同的回复路由。

如果从非分支路由调用，回复路由将全局设置为当前事务——它将对属于该事务的所有回复调用。请注意，一个事务只能设置一个 onreply_route。如果您多次使用 t_on_reply()，只有最后一个有效。

如果处理的回复是临时回复（1xx 代码），通过调用 drop() 函数（由核心导出），路由的执行将结束，回复将不会进一步转发。

参数的含义如下：

- *reply_route (string)* ——要调用的回复路由块。

此函数可以从 REQUEST_ROUTE、BRANCH_ROUTE、ONREPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="t_on_reply 使用示例"
...
route {
	seturi("sip:bob@opensips.org");  # 第一个分支
	append_branch("sip:alice@opensips.org"); # 第二个分支

	t_on_reply("global"); # "global" 回复路由设置为整个事务
	t_on_branch("1");

	t_relay();
}

branch_route[1] {
	if ($rU=="alice")
		t_on_reply("alice"); # "alice" 回复路由仅设置为第二个分支
}

onreply_route[alice] {
	xlog("收到来自 alice 的回复\n");
}

onreply_route[global] {
	if (t_check_status("1[0-9][0-9]")) {
		setflag(LOG_FLAG);
		log("收到临时回复\n");
		if (t_check_status("183"))
			drop;
	}
}
...
```

#### t_on_branch(branch_route)

设置一个分支路由，为事务的每个分支在发送之前单独执行——该路由中的更改应仅反映在该分支上。

由于并非所有函数都可从这种路由使用，请查看每个函数的文档以了解权限。任何其他命令可能导致不可预测的行为和可能的服务器故障。

只能为请求设置一个 branch_route。如果您多次使用 t_on_branch()，只有最后一个有效。

通过调用 drop() 函数（由核心导出），分支路由的执行将结束，分支将不会进一步转发。

参数的含义如下：

- *branch_route (string)* ——要调用的分支路由块。

此函数可以从 REQUEST_ROUTE、BRANCH_ROUTE、ONREPLY_ROUTE 和 FAILURE_ROUTE 使用。

```c title="t_on_branch 使用示例"
...
route { 
	t_on_branch("1"); 
	t_relay();
} 

branch_route[1] {
	if ($ru=~"bad_uri") {
		xlog("丢弃分支 $ru \n");
		drop;
	}
	if ($ru=~"GW_uri") {
		append_rpid();
	}
}
...
```

#### t_inject_branches(source[,flags])

此函数向现有事务添加新的 SIP 分支（目的地）并触发它们（发送出去）。事务可能已经有进行中的分支（如响铃状态），不会受到新分支注入的影响。也可以在注入时事务没有任何进行中的分支（尽管事务必须等待新分支，即使所有现有分支都完成了——请参阅 [t 等待新分支](#func_t_wait_for_new_branches) 函数）。

此函数（以及它与 [t relay](#func_t_relay) 的区别）的主要使用场景是能够从与事务无关的脚本路由（如 timer route、event route、notification route 等）向进行中的事务添加新分支。在这样的路由中，在注入之前使用的其他函数/模块将指向将受此注入影响的事务——请参阅 *event_routing* 模块。

参数：

- *source (string)* ——从何处获取要注入的新分支的描述。它可以是：

  *event* ——分支将从事件通知路由中公开的事件属性中获取（请参阅 *event_routing* 模块）。

  *msg* ——分支将从 SIP 消息的 RURI 和附加分支（由 append_branch() 函数或类似函数创建）中获取。
- *flags (string, optional)* ——与注入过程相关的一些附加标志：

  *cancel* 或 *c* ——在注入新分支之前取消事务中所有进行中的现有分支。

  *l* (last) ——这是此事务上最后注入的分支，不等待任何其他要注入的分支。

```c title="t_inject_branches 使用示例"
...
route[event_notification] {
	t_inject_branches("event");
}
...
```

#### t_wait_for_new_branches([branches])

此函数指示现有 SIP 事务在现有分支完成后等待注入新分支。这种等待将持续到事务的最终响应 INVITE 定时器（fr_inv_timeout）命中，或者直到注入了最大数量的分支（请参阅参数）；当然，如果事务从某个分支收到 2xx 最终回复，等待将终止。

通常，如果您有一个带有两个分支的事务，并且它们收到（比如）404 和 486 回复，分支将完成，事务将通过向呼叫者发送 404 回复来终止。但是，如果在转发事务之前执行 *t_wait_for_new_branches*，事务不会在分支完成时终止，也不会向呼叫者发送 404——它将等待新分支被注入（请参阅 [t 注入分支](#func_t_inject_branches) 函数），直到 fr_inv 定时器命中。

参数：

- *branches (integer, options)* ——要等待的最大分支数。

```c title="t_wait_for_new_branches 使用示例"
...
t_newtran();
t_wait_for_new_branches();
t_relay();
...
```

#### t_wait_no_more_branches()

此函数指示现有 SIP 事务停止等待任何新分支被注入。此函数应用于通过 [t 等待新分支](#func_t_wait_for_new_branches) 函数等待动态分支的事务。

使用场景：您的事务正在等待动态新分支（作为推送通知的结果）。在某一点，在一个进行中的分支上您收到最终回复——而分支失败转化为停止等待任何更多分支（这是一个关于根据从各种设备获得的答案决定等待多长时间的逻辑示例，固定或移动）。

```c title="t_wait_no_more_branches 使用示例"
...
t_wait_no_more_branches();
...
```

#### t_add_hdrs("sip_hdrs")

将一组头附加到现有事务——这些头将被追加到与事务相关的所有请求（外出分支、本地 ACK、CANCEL）。

参数：

- *sip_hdrs (string)*

```c title="t_add_hdrs 使用示例"
...
t_add_hdrs("X-origin: 1.1.1.1\r\n");
...
```

#### t_add_cancel_reason("Reason_hdr")

此函数用于从脚本级别强制在 CANCEL 请求中包含自定义 "Reason" 头。通常，Reason 头是从收到的 CANCEL 继承的（请注意，CANCEL 以逐跳方式传播——它在每一跳重新生成），但此函数可以覆盖它。它必须在转发 CANCEL 请求之前调用，其输入必须是格式正确的 Reason 头，包含名称、正文和 CRLF。

参数：

- *reason_hdr (string)*

```c title="t_add_cancel_reason 使用示例"
...
t_add_cancel_reason("Reason: SIP ;cause=200 ;text=\"Call completed elsewhere\"\r\n");
t_relay();
...
```

#### t_replicate(URI,[flags])

将请求复制到另一个目的地。不会将关于复制请求的信息（如回复代码）转发到原始 SIP UAC。

目的地由 SIP URI 指定。如果要使用多个目的地，附加的 SIP URI 必须设置为分支。

参数：

- *uri (string)*
- *flags (string, optional)* ——用于控制内部行为的一组标志——有关说明请参阅上面的 "t_relay([flags])" 函数。请注意，这里仅适用 *no-dns-failover*。

此函数可以从 REQUEST_ROUTE 使用。

```c title="t_replicate 使用示例"
...
t_replicate("sip:1.2.3.4:5060");
t_replicate("sip:1.2.3.4:5060;transport=tcp");
t_replicate("sip:1.2.3.4",0x4);
...
```

#### t_write_req(info,fifo) t_write_unix(info,sock)

通过 FIFO 文件或 UNIX 套接字写入关于请求的大量信息。可以通过 "tw_append" 参数控制应写入哪些信息。

参数：

- *info (string)*
- *path (string)*

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE 和 BRANCH_ROUTE 使用。

```c title="t_write_req/unix 使用示例"
...
modparam("tm","tw_append","append1:Email=$avp(email);UA=$ua")
modparam("tm","tw_append","append2:body=$rb")
...
t_write_req("voicemail/append1","/tmp/appx_fifo");
...
t_write_unix("logger/append2","/var/run/logger.sock");
...
```

#### t_flush_flags()

将当前请求的标志刷新到已创建的事务中。它仅在通过 t_newtran() 创建事务的路由块中有意义，并且标志自创建以来已被更改。

此函数可以从 REQUEST_ROUTE 和 BRANCH_ROUTE 使用。

```c title="t_flush_flags 使用示例"
...
t_flush_flags();
...
```

#### t_anycast_replicate()

此函数用于 anycast 设置，以复制 *CANCEL* 或 *ACK* 方法，对于这些方法没有找到本地事务。该函数将消息广播到集群中的所有其他节点，但只有事务的"所有者"能够处理它。

```c title="t_anycast_replicate 使用示例"
...
if (is_method("ACK|CANCEL") && !t_check_trans()) {
	t_anycast_replicate();
	exit;
}
...
```

#### t_reply_by_callid(code, reason_phrase, [callid], [cseq])

此函数用于向现有 INVITE 事务发送回复。常见的用例是当 OpenSIPS 用作 UAS 时，收到 INVITE 后，通过回复 "t_reply(180, "Ringing")" 或 "t_reply(183, "Session Progress")" 将其"停放"在本地 OpenSIPS 上，稍后我们需要处理其 CANCEL 或 BYE 并发送 '487 Request Terminated' 到原始 INVITE 事务。

用于识别事务的 callid 和 cseq 将从当前正在处理的消息中获取。但它们可以显式传递，例如我们可以处理 BYE，其中 cseq 必须是 INVITE 的 cseq 减一。

此函数可以从 REQUEST_ROUTE 使用。

```c title="t_reply_by_callid 使用示例"
...
route{
	if($rU == "LOCAL_PARK") {
		if(is_method("INVITE")) {
			$T.fr_timeout = 10;
			$T.fr_inv_timeout = 10;
			append_to_reply("Contact: sip:LOCAL_PARK@$socket_in(ip):$socket_in(port)\r\n");
			t_reply(180, "Ringing");
			t_wait_for_new_branches();
		} else if(is_method("CANCEL")) {
			if(!t_reply_by_callid(487, "Request Terminated")) {
				sl_send_reply(481, "Call Leg/Transaction Does Not Exist");
			} else {
				sl_send_reply(200, "OK");
			}
		} else if(is_method("BYE")) {
			$var(prev_cseq) = ($(cs{s.int}) - 1);
			if(!t_reply_by_callid(487, "Request Terminated", , $var(prev_cseq))) {
				sl_send_reply(481, "Call Leg/Transaction Does Not Exist");
			} else {
				sl_send_reply(200, "OK");
			}
		} else if(is_method("ACK")) {
			t_relay();
		}
		exit;
	}
}
...
```

#### t_get_branch_idx_by_attr(attr, [val_str], [val_int], [result_var], [offset])

此函数可用于搜索当前事务的另一个分支的索引。搜索基于每分支属性——您至少需要提供属性的名称。可选地，您可以为用于搜索的属性提供一个值（字符串或整数）。作为输入，函数可以接受一个可选的分支偏移量（绝对值，涵盖事务的所有分支），搜索应从该偏移量开始。

如果找到具有给定名称和属性值的分支，函数返回 true。分支的状态（如进行中、已完成）无关紧要。如果找到，"result_var" 变量将被填充分支索引（作为整数）。

此函数可以从 ONREPLY_ROUTE、BRANCH_ROUTE 和 FAILURE_ROUTE 使用。

```c title="t_get_branch_idx_by_attr 使用示例"
...
	# 搜索具有字符串值 "pstn" 的 "name" 属性的分支
	if (t_get_branch_idx_by_attr("name", "pstn", , $var(idx))) {
		xlog("找到分支索引为 $var(idx)\n");
	}
...
```

### 导出的伪变量

导出的变量在下一节中列出。

#### $T_branch_idx

*$T_branch_idx* ——当前处理的分支的索引（从 0 开始用于第一个分支）。此索引仅在 BRANCH 和 REPLY 路由中有意义（其中处理是按分支进行的），在 FAILURE 路由中指向事务上最后最终回复的分支。在所有其他类型的路由中，此索引的值将为 NULL。

#### $T_reply_code

*$T_reply_code* ——回复代码，如下所示：在 request_route 中将是最后有状态发送的回复；在 reply_route 中是当前处理的回复；在 failure_route 中是负面获胜回复。如果没有回复或错误，返回 '0' 值。

#### $T_fr_timeout

*$T_fr_timeout (R/W)* ——当前事务最终回复的超时。

每次收到不同的请求，*$T_fr_timeout* 最初将等于 **[fr timeout](#param_fr_timeout)** 参数。

*"$T_fr_timeout = NULL;"* 将将其重置为 **[fr timeout](#param_fr_timeout)**。

#### $T_fr_inv_timeout

*$T_fr_inv_timeout (R/W)* ——收到 1XX 回复后，对 INVITE 请求的最终回复的超时。此变量也可以在 onreply_route 中设置（例如在 180 Ringing、100 Trying 之后），仍然有效。

每次收到不同的请求，*$T_fr_inv_timeout* 最初将等于 **[fr inv timeout](#param_fr_inv_timeout)** 参数。

*"$T_fr_inv_timeout = NULL;"* 将将其重置为 **[fr inv timeout](#param_fr_inv_timeout)**。

#### $T_ruri

*$T_ruri* ——当前分支的 ruri；此信息从事务结构中获取，因此您可以访问任何有事务的 SIP 消息（请求/回复）的此信息。

#### $bavp(name)

*$bavp(name)* ——一种特殊类型的 avp，可以为每个分支具有不同的值。它们只能用于 BRANCH、REPLY 和 FAILURE 路由。否则返回 NULL 值。

#### $T_id

*$T_id* ——返回当前事务的 ID。该 ID 是一个不透明的十六进制字符串，对每个事务唯一。如果没有当前事务，返回 NULL 值。

#### $T_branch_last_reply_code

*$T_branch_last_reply_code* ——返回为作为参数指定的分支收到的最后一个回复代码。如果未指定参数，则检索当前分支的最后回复。

#### $tm.branch.uri[]

*$tm.branch.uri* ——提供对 TM 现有分支的 Request URI（作为字符串）的只读访问。分支的状态（已完成、进行中等）无关紧要。

TM（UAC 端）分支在通过 "t_relay()" 或 "t_inject()" 将请求发送到新目的地时创建。

分支的索引从 0 开始，访问事务的所有分支（过去和活动）。尽管索引支持两个可选后缀以简化脚本：

- */active* ——索引也从 0 开始，但它是相对于最后一套分支的——由最后一次 "t_relay()" 创建的并行分支。
- */all* ——类似于"无后缀"情况，意味着它是绝对索引，涵盖事务的所有分支（由对事务执行的所有 "t_relay()" 结果）。

如果未指定索引，则使用当前分支。这取决于脚本上下文。在回复路由中，当前分支是回复来自的分支；在分支路由中，当前分支是要发送出的分支；在失败路由中，当前分支是获胜分支。

注意：

- 不支持索引 ALL（"*"）；
- 在分支路由中，只有 "$tm.branch.attr" 和 "$tm.branch.flag" 变量对当前分支有效（其他分支相关变量将返回 NULL）
- 接受负值，意味着从末尾索引（-1 是最新的/最高的分支）

该变量可用于 BRANCH、ONREPLY 和 FAILURE 路由。

#### $tm.branch.duri[]

*$tm.branch.duri* ——与 **[tm branch uri](#pv_tm_branch_uri)** 100% 相似，但返回分支的 Destination-URI 值。

#### $tm.branch.path[]

*$tm.branch.path* ——与 **[tm branch uri](#pv_tm_branch_uri)** 100% 相似，但返回分支的 PATH 值。

#### $tm.branch.q[]

*$tm.branch.q* ——与 **[tm branch uri](#pv_tm_branch_uri)** 100% 相似，但返回分支的 Q 值。

#### $tm.branch.flags[]

*$tm.branch.flags* ——与 **[tm branch uri](#pv_tm_branch_uri)** 100% 相似，但返回为分支设置的分支部标志列表（逗号分隔）。

#### $tm.branch.socket[]

*$tm.branch.socket* ——与 **[tm branch uri](#pv_tm_branch_uri)** 100% 相似，但返回用于发送分支的套接字描述（proto:ip:port）。

#### $tm.branch.flag()[]

*$tm.branch.flag(name)* ——类似于 **[tm branch uri](#pv_tm_branch_uri)**，但提供对单个分支标志（按名称）的读/写访问。

接受的值：0 表示 FALSE，正非零表示 TRUE。返回的值：0 表示 FALSE，1 表示 TRUE。

这里操作的标志与您可以通过 "[re]setbflag()" 函数操作的 bflags 相同。

#### $tm.branch.attr()[]

*$tm.branch.attr(name)* ——类似于 **[tm branch uri](#pv_tm_branch_uri)**，但提供对附加到分支的属性的读/写访问。

属性可以有任意名称（无需预定义），并且可以具有单个值（一次），字符串或整数。

#### $tm.branch.last_received[]

*$tm.branch.last_received* ——与 **[tm branch uri](#pv_tm_branch_uri)** 100% 相似，但返回在此分支上收到的最后一个回复代码（来自网络）。如果尚未收到任何回复，返回 NULL。

#### $tm.branch.type[]

*$tm.branch.type* ——与 **[tm branch uri](#pv_tm_branch_uri)** 100% 相似，但返回当前分支的类型。如果它不是真正的分支（没有 SIP 信令，用于等待分支注入），则可能是 "phone"；如果是真正的信令分支，则是 "sip"。

### 导出的 MI 函数

#### tm:uac_dlg

替换已弃用的 MI 命令：*t_uac_dlg*。

生成并发送本地 SIP 请求。

参数：

- *method* ——请求方法
- *ruri* ——请求 SIP URI
- *headers* ——要添加到请求的一组附加头；至少必须指定 "From" 和 "To" 头）
- *next_hop* (optional) ——下一跳 SIP URI（OBP）。
- *socket* (optional) ——用于发送请求的本地套接字。
- *body* (optional) ——请求正文（如果存在，需要 "Content-Type" 和 "Content-length" 头）

MI FIFO 命令格式：

```c
		opensips-cli -x mi tm:uac_dlg method=INVITE ruri="sip:alice@127.0.0.1:7050" headers="From: sip:bobster@127.0.0.1:1337\r\nTo: sip:alice@127.0.0.1:7050\r\nContact: sip:bobster@127.0.0.1:1337\r\n"
			
```

#### tm:uac_cancel

替换已弃用的 MI 命令：*t_uac_cancel*。

为现有 SIP 请求生成并发送 CANCEL。

参数：

- *callid* ——要取消的 INVITE 请求的 callid。
- *cseq* ——要取消的 INVITE 请求的 cseq。

MI FIFO 命令格式：

```c
		opensips-cli -x mi tm:uac_cancel "1-23454@127.0.0.1" "1 INVITE"
			
```

#### tm:hash

替换已弃用的 MI 命令：*t_hash*。

获取有关 TM 内部哈希表负载的信息。

参数：

- *无*

MI FIFO 命令格式：

```c
		opensips-cli -x mi tm:hash
			
```

#### tm:reply

替换已弃用的 MI 命令：*t_reply*。

为现有入站 SIP 事务生成并发送回复。

参数：

- *code* ——回复代码
- *reason* ——原因短语。
- *trans_id* ——事务标识符（具有 hash_entry:label 格式）
- *to_tag* ——要添加到 TO 头的 To tag
- *new_headers* (optional) ——要追加到回复的附加头。
- *body* ——(optional) 回复正文（如果存在，需要 "Content-Type" 和 "Content-length" 头）

MI FIFO 命令格式：

```c
		opensips-cli -x mi tm:reply 403 Forbidden 46961:1279687637 abcde .
			
```

### 导出的统计信息

导出的统计信息在下一节中列出。除 "inuse_transactions" 外，所有统计信息都可以重置。

#### received_replies

TM 模块收到的回复总数。

#### relayed_replies

TM 模块收到并转发的回复总数。

#### local_replies

TM 模块本地生成的回复总数。

#### UAS_transactions

由接收到的请求创建的事务总数。

#### UAC_transactions

由本地生成的请求创建的事务总数。

#### 2xx_transactions

以 2xx 回复完成的事务总数。

#### 3xx_transactions

以 3xx 回复完成的事务总数。

#### 4xx_transactions

以 4xx 回复完成的事务总数。

#### 5xx_transactions

以 5xx 回复完成的事务总数。

#### 6xx_transactions

以 6xx 回复完成的事务总数。

#### inuse_transactions

当前内存中存在的事务数。

#### retransmission_req_T1_1

由于 T1 1 定时器导致的请求重传数量，第一次重传间隔（通常为 500ms）。

#### retransmission_req_T1_2

由于 T1 2 定时器导致的请求重传数量，第二次重传间隔（通常为 1s）。

#### retransmission_req_T1_3

由于 T1 3 定时器导致的请求重传数量，第三次重传间隔（通常为 2s）。

#### retransmission_req_T2

由于 T2 导致的请求重传数量，最终重传间隔（通常为 4s）。

#### retransmission_rpl_T2

回复重传的数量，都以相同的重传间隔 T2 完成，通常为 4s。

#### timeout_finalresponse

未收到任何类型回复（甚至临时回复）的超时事务数量（来自 B 侧）。此类超时表示通信/可达性问题。请注意，由于分叉，单个事务可能计算多次此类超时。

#### timeout_finalresponse

未收到 FINAL 回复（可能收到临时回复）的 INVITE 超时事务数量（来自 B 侧）。此类超时表示"无应答"事件，这不是信令问题。请注意，由于分叉，单个事务可能计算多次此类超时。

## 开发者指南

### 函数

#### load_tm(*import_structure)

仅供编程使用——导入 TM API。请参阅 cpl_c、acc 或 jabber 模块以了解其工作原理。

参数的含义如下：

- *import_structure* ——指向导入结构的指针——请参阅 modules/tm/tm_load.h 中的 "struct tm_binds"

## 常见问题

**Q: 旧的 cancel_call() 函数发生了什么**

该函数已被取消_branch("a") - 取消所有分支（替换为功能）。

**Q: 如何报告错误？**

请遵循以下指南：[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。

<!-- 贡献者 -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
