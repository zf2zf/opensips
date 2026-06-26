---
title: "呼叫中心模块"
description: "呼叫中心模块实现了一个呼入呼叫中心系统，具有呼叫流程（用于对接收的呼叫进行排队）和坐席（用于接听呼叫）。"
---

## 管理指南


### 概述


呼叫中心模块实现了一个呼入呼叫中心系统，具有呼叫
		流程（用于对接收的呼叫进行排队）和坐席（用于接听
		呼叫）。


该模块实现了排队系统、呼叫分配到坐席、
		坐席管理、呼叫的 CDR、
		呼叫分配和坐席活动的统计 -
		基本上除了媒体播放（用于队列）之外的所有功能。
		此部分必须由第三方媒体服务器提供
		（FreeSwitch、Asterisk 或其他）。


这实际上是一个联系人中心，
		能够同时处理 RTP/音频呼叫和（多个）MSRP/聊天呼叫。


该模块提供了一个内置的内部呼叫分配逻辑
		（用于将呼叫/聊天发送到坐席），
		但也提供使用外部逻辑进行分配的可能性
		（参见 [MI 分配呼叫到坐席](#mi_dispatch_call_to_agent) MI 命令）。


### 工作原理


该模块中的主要实体是流程（队列）和坐席。


#### 数据库表


每个实体在数据库中都有对应的表，
		用于配置目的 - *cc_flows* 和
		*cc_agents* 表，
		请参阅 [DB schema](https://opensips.org/Documentation/Install-DBSchema--3-3#AEN2656)。
		数据在启动时加载并缓存到内存中；
		可以通过 MI 命令在运行时重新加载
		（请参阅 *call_center:reload*
		命令，参见[导出的 MI 函数](#exported_mi_functions)）。


此外，还有一个 *cc_cdrs* 表用于写入
		CDR - 此操作在呼叫完成后实时进行，
		覆盖所有可能的情况：呼叫在队列中被丢弃、
		被坐席拒绝、被坐席接受、呼叫因错误终止
		- 请注意，一个呼叫可能生成多个 CDR
		（例如被坐席 A 拒绝，然后被重新分配并被坐席 B 接受）。


*cc_calls* 表用于存储正在进行的呼叫，
		无论其状态如何（在队列中、到坐席、已结束）。
		此表在运行时由模块填充，
		并在启动时查询。
		此表不应手动配置。


#### 呼叫流程


流程由唯一的字母数字 ID 定义 - 
		流程的主要属性是 *skill* -
		这是流程对坐席的技能要求，
		坐席才能接听呼叫；
		*skills* 的概念是流程和坐席之间的联系 -
		说明哪些坐席为哪些流程服务 -
		流程需要技能，
		而坐席提供一组技能。
		与流程所需技能相匹配的坐席将自动
		接收来自该流程的呼叫。


此外，流程具有 *priority* - 
		由于坐席可能同时服务多个流程（基于技能），
		您可以在流程之间定义优先级 -
		如果流程具有更高的优先级，
		其呼叫将在队列中分配给坐席和排队时）
		被推到具有较低优先级的流程的呼叫前面。


可按流程配置，模块可以执行按流程呼叫劝阻；
		这意味着如果队列/流程过载，
		则将呼叫重定向到另一个目的地：


- 如果队列中已有的呼叫数超过 diss_qsize_th 阈值
- 如果队列的预计等待时间超过 diss_ewt_th 阈值
- 如果呼叫在队列中等待的时间超过 diss_onhold_th 阈值


可选地，流程可以定义 *prependcid* -
		在呼叫被分配给坐席时要添加到 CLI（呼叫者 ID）的前缀 -
		由于坐席可能从多个流程接收呼叫，
		因此对用户来说，看到呼叫是从哪个队列收到的是很重要的。


在媒体播报方面，流程定义了
		*message_welcome*（可选，
		在呼叫中执行任何操作之前播放）和
		*message_queue*（必需，
		提供无限等待音乐的循环消息
		重要 - 此消息必须循环播放，
		媒体服务器永远不应挂断）。
		两种播报都以 SIP URI 形式提供
		（需要将呼叫发送到这里以获取播放）。


流程还有一个可选的 *max_wrapup time*，
		它作为每个坐席/全局值的上限
		（流程为其所有呼叫强制设置 wrapup 值的天花板）。


#### 坐席


坐席由唯一的字母数字 ID 定义 -
		坐席的主要属性是其 *skills* 集合。
		这组技能将决定接收哪些呼叫
		（来自哪些流程，基于技能匹配）。


坐席可以提供不同可选媒体类型的支持，
		如 RTP/音频或 MSRP/聊天。
		每种支持的媒体类型都有
		支持的最大会话数。
		当然，对于音频，`1` 是硬编码的。
		在 SIP 端，每种媒体类型都带有一个
		*locations*。
		位置是一个 SIP URI，
		呼叫必须被发送到这里才能被坐席接听。
		至少应定义一种媒体类型。
		要指定坐席支持哪种媒体，
		只需在他的配置文件中定义相应的 SIP 位置。


因此，在某个时间，坐席可以处理单个呼叫，
		或多个聊天会话。


此外，坐席有一个初始 *logstate* -
		他是否已登录（登录是接收呼叫的必要条件）。
		登录状态可以通过专用 MI 命令
		*call_center:agent_login* 在运行时更改，
		请参阅[导出的 MI 函数](#exported_mi_functions)。


有一个可选的每个坐席 *wrapup_time*，
		定义坐席在完成一个呼叫后，
		在从系统接收下一个呼叫之前的时间间隔。
		如果没有为坐席定义值，
		则将使用全局 *wrapup_time*。
		请注意，如果定义了每个流程的
		*max_wrapup_time*，
		则结果值可能会受到其上限限制。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *b2b_logic* - B2bUA 模块
- *database* - 某个 SQL 数据库模块


#### 外部库或应用程序


以下库或应用程序必须在运行加载此模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### db_url (string)


到 DB 服务器的 SQL 地址 -- 特定于数据库。
		这必须是持有配置表的数据库
		（cc_flows、cc_agents 和 cc_calls 表）。


```c title="设置 db_url 参数"
...
modparam("call_center", "db_url", 
	"mysql://opensips:opensipsrw@localhost/opensips")
...
```


#### acc_db_url (string)


到 DB 服务器的 SQL 地址 -- 特定于数据库。
		这必须是 CDR 表（cc_cdrs）所在的数据库。


```c title="设置 acc_db_url 参数"
...
modparam("call_center", "acc_db_url", 
	"mysql://opensips:opensipsrw@localhost/opensips_cdrs")
...
```


#### rt_db_url (string)


运行时表所在的 DB 服务器（数据库特定）的 SQL 地址/URL。
		运行时表是 OpenSIPS 在运行时学习的数据填充的表。
		更具体地说，我们目前唯一的运行时表是 "cc_calls" 表。


```c title="设置 rt_db_url 参数"
...
modparam("call_center", "rt_db_url", 
	"mysql://opensips:opensipsrw@localhost/opensips_runtime")
...
```


#### wrapup_time (integer)


坐席完成一个呼叫和从系统接收下一个呼叫之间的时间。
		即使有排队的呼叫，
		模块在此 wrapup 间隔期间也不会向坐席分配呼叫。


此值可以被每个坐席的值覆盖（如果已定义），
		进一步地，可以被每个流程的值覆盖（如果已定义）。


*默认值为 "30 秒"。*


```c title="设置 wrapup_time 参数"
...
modparam("call_center", "wrapup_time", 45)
...
```


#### queue_pos_param (string)


SIP URI 参数的名称，
		用于在将呼叫发送到媒体服务器进行等待/队列播放时，
		报告在等待队列中的位置。
		位置 0 表示它是下一个将被分配给坐席的呼叫。


*默认值为 "empty（无）"。*


```c title="设置 queue_pos_param 参数"
...
modparam("call_center", "queue_pos_param", "cc_pos")
...
```


#### reject_on_no_agents (int)


一个参数，用于指示当没有登录的坐席时，
		是否应拒绝或排队传入呼叫。
		基本上，这允许在尚无坐席的流程上进行呼叫排队。


*默认值为 "1（true）"。*


```c title="设置 reject_on_no_agents 参数"
...
modparam("call_center", "reject_on_no_agents", 0)
...
```


#### chat_dispatch_policy (int)


一个参数，用于指示在向坐席分配
		聊天/MSRP 会话时应该采用什么策略，
		考虑到坐席可能同时处理多个此类会话/聊天。


选项有：


- **balancing** - 分发将尝试在坐席之间保持均匀，
			但这样做可能会浪费坐席上的聊天会话，
			并导致呼叫饥饿 - 坐席被聊天会话部分占用，
			因此无法接听电话
			（当然，如果您有混合的音频/聊天坐席）
- **full-load** - 分发将尝试在坐席处理聊天会话时
			以最佳方式利用坐席 - 一旦坐席接听聊天，
			所有后续聊天都将分配给他 -
			其想法是尝试有效地利用坐席的资源/会话，
			为呼叫留出尽可能多的空间。
			当然，这可能导致聊天坐席的负载不均 -
			一些会满，一些会空。


*默认值为 "balancing"。*


```c title="设置 chat_dispatch_policy 参数"
...
modparam("call_center", "chat_dispatch_policy", "balancing")
...
```


#### internal_call_dispatching (int)


一个参数，用于指示是否应使用内部/内置的呼叫分配给坐席。
		如果启用，模块将自动
		将排队/传入的呼叫分配（由自身）给可用的坐席。
		如果禁用，模块将不会自己进行此类分配，
		期望使用 [MI 分配呼叫到坐席](#mi_dispatch_call_to_agent)
		MI 命令将排队的呼叫分配给坐席。
		这允许实现外部自定义分配逻辑。
		此设置的值可以在运行时通过
		[MI 内部呼叫分配](#mi_internal_call_dispatching) MI 命令更改。


*默认值为 "1"（启用）。*


```c title="设置 internal_call_dispatching 参数"
...
modparam("call_center", "internal_call_dispatching", 0)
...
```


#### cc_agents_table (string)


用于保存坐席配置的表的名称。


*默认值为 "cc_agents"。*


```c title="设置 cc_agents_table 参数"
...
modparam("call_center", "cc_agents_table", "my_agents")
...
```


#### cca_agentid_column (string)


坐席表中用于 "坐席 id"（唯一 DB id）列的名称。


*默认值为 "agentid"。*


```c title="设置 cca_agentid_column 参数"
...
modparam("call_center", "cca_agentid_column", "cid")
...
```


#### cca_location_column (string)


坐席表中用于呼叫/音频 "位置"（SIP URI）列的名称。


*默认值为 "location"。*


```c title="设置 cca_location_column 参数"
...
modparam("call_center", "cca_location_column", "sip_uri")
...
```


#### cca_msrp_location_column (string)


坐席表中用于 msrp/聊天 "位置"（SIP URI）列的名称。


*默认值为 "msrp_location"。*


```c title="设置 cca_msrp_location_column 参数"
...
modparam("call_center", "cca_msrp_location_column", "sip_uri")
...
```


#### cca_msrp_max_sessions_column (string)


坐席表中用于保存坐席可处理的最大聊天会话数的列的名称。


*默认值为 "msrp_max_sessions"。*


```c title="设置 cca_msrp_max_sessions_column 参数"
...
modparam("call_center", "cca_msrp_max_sessions_column", "max_chats")
...
```


#### cca_skills_column (string)


坐席表中用于 "skills"（技能列表）列的名称。


*默认值为 "skills"。*


```c title="设置 cca_skills_column 参数"
...
modparam("call_center", "cca_skills_column", "skills")
...
```


#### cca_logstate_column (string)


坐席表中用于 "logstate"（原始登录状态）列的名称。


*默认值为 "logstate"。*


```c title="设置 cca_logstate_column 参数"
...
modparam("call_center", "cca_logstate_column", "log_state")
...
```


#### cca_wrapuptime_column (string)


坐席表中用于 "wrapuptime"（每个坐席的 wrapup 时间）列的名称。


*默认值为 "wrapup_time"。*


```c title="设置 cca_wrapuptime_column 参数"
...
modparam("call_center", "cca_wrapuptime_column", "wtime")
...
```


#### cca_wrapupend_column (string)


坐席表中用于 "wrapupend"（wrapup 结束时间戳）列的名称。


*默认值为 "wrapup_end_time"。*


```c title="设置 cca_wrapupend_column 参数"
...
modparam("call_center", "cca_wrapupend_column", "wrapup_ends")
...
```


#### cc_flows_table (string)


用于保存流程/队列定义的表的名称。


*默认值为 "cc_flows"。*


```c title="设置 cc_flows_table 参数"
...
modparam("call_center", "cc_flows_table", "queues")
...
```


#### ccf_flowid_column (string)


流程表中用于 "flow id"（唯一 DB id）列的名称。


*默认值为 "flowid"。*


```c title="设置 ccf_flowid_column 参数"
...
modparam("call_center", "ccf_flowid_column", "queue_id")
...
```


#### ccf_priority_column (string)


流程表中用于 "priority" 列的名称。


*默认值为 "priority"。*


```c title="设置 ccf_priority_column 参数"
...
modparam("call_center", "ccf_priority_column", "queue_prio")
...
```


#### ccf_skill_column (string)


流程表中用于 "skill" 列的名称。


*默认值为 "skill"。*


```c title="设置 ccf_skill_column 参数"
...
modparam("call_center", "ccf_skill_column", "queue_skill")
...
```


#### ccf_cid_column (string)


流程表中用于 "caller ID prefix" 列的名称。


*默认值为 "prependcid"。*


```c title="设置 ccf_cid_column 参数"
...
modparam("call_center", "ccf_cid_column", "queue_cli_prefix")
...
```


#### ccf_max_wrapup_column (string)


流程表中用于 "max limit for wrapup time" 列的名称。


*默认值为 "max_wrapup_time"。*


```c title="设置 ccf_max_wrapup_column 参数"
...
modparam("call_center", "ccf_max_wrapup_column", "queue_wrapup")
...
```


#### ccf_dissuading_hangup_column (string)


流程表中用于 "hangup after dissuading" 列的名称。


*默认值为 "dissuading_hangup"。*


```c title="设置 ccf_dissuading_hangup_column 参数"
...
modparam("call_center", "ccf_dissuading_hangup_column", "hangup_on_dissuading")
...
```


#### ccf_dissuading_onhold_th_column (string)


流程表中用于 "on-hold dissuading threshold" 列的名称。


*默认值为 "dissuading_onhold_th"。*


```c title="设置 ccf_dissuading_onhold_th_column 参数"
...
modparam("call_center", "ccf_dissuading_onhold_th_column", "th_diss_onhold")
...
```


#### ccf_dissuading_ewt_th_column (string)


流程表中用于 "EWT dissuading threshold" 列的名称。


*默认值为 "dissuading_ewt_th"。*


```c title="设置 ccf_dissuading_ewt_th_column 参数"
...
modparam("call_center", "ccf_dissuading_ewt_th_column", "th_diss_ewt")
...
```


#### ccf_dissuading_qsize_th_column (string)


流程表中用于 "queue size dissuading threshold" 列的名称。


*默认值为 "dissuading_qsize_th"。*


```c title="设置 ccf_dissuading_qsize_th_column 参数"
...
modparam("call_center", "ccf_dissuading_qsize_th_column", "th_diss_qsize")
...
```


#### ccf_m_welcome_column (string)


流程表中用于 "audio message on welcome" 列的名称。


*默认值为 "message_welcome"。*


```c title="设置 ccf_m_welcome_column 参数"
...
modparam("call_center", "ccf_m_welcome_column", "audio_welcome")
...
```


#### ccf_m_queue_column (string)


流程表中用于 "audio message on queueing" 列的名称。


*默认值为 "message_queue"。*


```c title="设置 ccf_m_queue_column 参数"
...
modparam("call_center", "ccf_m_queue_column", "audio_queue")
...
```


#### ccf_m_dissuading_column (string)


流程表中用于 "audio message on dissuading" 列的名称。


*默认值为 "message_dissuading"。*


```c title="设置 ccf_m_dissuading_column 参数"
...
modparam("call_center", "ccf_m_dissuading_column", "audio_dissuading")
...
```


#### ccf_m_flow_id_column (string)


流程表中用于 "audio message on identifying the flow" 列的名称。


*默认值为 "message_flow_id"。*


```c title="设置 ccf_m_flow_id_column 参数"
...
modparam("call_center", "ccf_m_flow_id_column", "audio_flow_id")
...
```


#### b2b_logic_ctx_param (string)


可用于检索传递给
		[cc handle call](#func_cc_handle_call) 函数的参数值的
		*$b2b_logic.ctx* 变量的名称。


此参数将被复制到由 call_center 模块启动的所有 B2B 场景中。
		请注意，您可以通过写入来更改当前场景的值，
		但该更改不会反映在不同的场景中。


*默认值为 "call_center"。*


```c title="设置 b2b_logic_ctx_param 参数"
...
modparam("call_center", "b2b_logic_ctx_param", "b2b_callid")
...
route[handle_call_center] {
    ...
    cc_handle_call("flow", $ci);
    ...
}
...
route[b2b_handle_request] {
    ...
    xlog("初始 Callid 是 $b2b_logic.ctx(b2b_callid)\n");
    ...
}
```


### 导出的函数


#### cc_handle_call( flowID [,param])


此函数仅用于初始 INVITE 请求 -
		该函数推送呼叫以由呼叫中心模块处理
		（通过某个流程/队列）。


此函数可用于 REQUEST_ROUTE。


参数：


- *flowID (string)* - 处理此呼叫的流程 ID
				（将呼叫推入该流程）。
- *param (string, optional)* - 一个不透明字符串，
				作为参数传递给 "callcenter" 和
				"agent" B2B 场景。
				它用于呼叫中心模块的自定义集成，
				脚本编写者对此参数的值和目的有 100% 的决定权，
				OpenSIPS 不会触碰或解释它。
				您可以使用
				*$b2b_logic.ctx* 变量
				（使用 [b2b logic ctx param](#param_b2b_logic_ctx_param)
				参数中定义的名称）
				来检索此参数的值。


如果呼叫成功被呼叫中心引擎推送和处理，
		函数返回 TRUE 到脚本。
		重要提示：
		在此点之后，您不得对呼叫进行任何信令操作（回复、转发）。


如果出错，将返回 FALSE 到脚本，返回码如下：


- **-1** - 无法从参数获取流程 ID；
- **-2** - 无法解析 FROM URI；
- **-3** - 未找到具有 FlowID 的流程；
- **-4** - 流程中没有登录的坐席；
- **-5** - 内部错误；


```c title="cc_handle_call 用法"
...
if (is_method("INVITE") and !has_totag()) {
	if (!cc_handle_call("tech_support")) {
		send_reply(403,"Cannot handle call");
		exit;
	}
}
...
```


#### cc_agent_login(agentID, state)


此函数设置坐席的登录（开或关）状态。


此函数可用于 REQUEST_ROUTE。


参数：


- *agentID (string)* - 坐席的 ID
- *state (int)* - 一个整数值，
				给出新状态 - 0 表示登出，
				其他任何值表示登录。


```c title="cc_agent_login 用法"
...
# 登出 'agentX' 坐席
cc_agent_login("agentX",0);
...
```


### 导出的统计信息


#### 全局统计信息


##### ccg_incalls


接收的呼叫总数。（计数器类型）


##### ccg_awt


呼叫的平均等待时间。（实时类型）


##### ccg_load


全局负载（跨所有流程）。（实时类型）


##### ccg_distributed_incalls


分配的呼叫总数。（计数器类型）


##### ccg_answered_incalls


坐席应答的呼叫（音频/RTP 和聊天/MSRP）总数。（计数器类型）


##### ccg_answered_inchats


坐席仅应答的聊天/MSRP 呼叫总数。（计数器类型）


##### ccg_abandonned_incalls


在坐席应答之前被呼叫者终止的呼叫总数。（计数器类型）


##### ccg_onhold_calls


队列中（等待中）的呼叫（音频/RTP 和聊天/MSRP）总数。（实时类型）


##### ccg_onhold_chats


队列中（等待中）仅聊天/MSRP 呼叫的总数。（实时类型）


##### ccg_free_agents


空闲坐席总数（跨所有流程）。（实时类型）


#### 按流程统计信息（每个流程一组）


##### ccf_incalls_flowID


该流程接收的呼叫数。（计数器类型）


##### ccf_dist_incalls_flowID


该流程中分配的呼叫数。（计数器类型）


##### ccf_answ_incalls_flowID


坐席应答的来自该流程的呼叫（音频/RTP 和聊天/MSRP）数。（计数器类型）


##### ccf_answ_incalls_flowID


坐席仅应答的来自该流程的聊天/MSRP 呼叫数。（计数器类型）


##### ccf_aban_incalls_flowID


在坐席应答之前被呼叫者终止的来自该流程的呼叫数。（计数器类型）


##### ccf_onhold_incalls_flowID


来自该流程处于等待状态的呼叫（音频/RTP 和聊天/MSRP）数。（实时类型）


##### ccf_onhold_inchats_flowID


来自该流程处于等待状态仅聊天/MSRP 呼叫数。（实时类型）


##### ccf_queued_calls_flowID


该流程排队的呼叫数。（实时类型）


##### ccf_free_agents_flowID


该流程服务的空闲坐席数。（实时类型）


##### ccf_etw_flowID


该流程的预计等待时间。（实时类型）


##### ccf_awt_flowID


该流程的平均等待时间。（实时类型）


##### ccg_load_flowID


该流程的负载（排队呼叫数与登录坐席数之比）。（实时类型）


#### 按坐席统计信息（每个坐席一组）


##### cca_dist_incalls_agnetID


分配给此坐席的呼叫数。（计数器类型）


##### cca_answ_incalls_agentID


坐席应答的呼叫（音频/RTP 和聊天/MSRP）数。（计数器类型）


##### cca_answ_inchats_agentID


坐席仅应答的聊天/MSRP 呼叫数。（计数器类型）


##### cca_aban_incalls_agentID


在被坐席应答之前被呼叫者终止的（发送到此坐席的）呼叫数。（计数器类型）


##### cca_att_agentID


此坐席的平均通话时间（实时类型）


### 导出的 MI 函数


#### call_center:reload


替换过时的 MI 命令：*cc_reload*。


重新加载数据库中的流程和坐席定义。


此命令不带参数。


MI FIFO 命令用法：


```c
opensips-cli -x mi call_center:reload
```


#### call_center:agent_login


替换过时的 MI 命令：*cc_agent_login*。


将坐席登录到呼叫中心引擎。


参数：


- *agent_id* - 坐席的 ID
- *state* - 新的登录状态（0 - 登出，1 - 登录）


MI FIFO 命令用法：


```c
opensips-cli -x mi call_center:agent_login agentX 0
```


#### call_center:list_queue


替换过时的 MI 命令：*cc_list_queue*。


列出所有排队的呼叫 -
		对于每个呼叫，将打印以下属性：
		呼叫 ID、呼叫用户信息、呼叫的流程、
		呼叫在队列中等待的时间、呼叫的 ETW、
		呼叫优先级和呼叫技能（从流程继承）。


此命令不带参数。


MI FIFO 命令用法：


```c
opensips-cli -x mi call_center:list_queue
```


#### call_center:list_flows


替换过时的 MI 命令：*cc_list_flows*。


列出所有流程 -
		对于每个流程，将打印以下属性：
		流程 ID、平均呼叫持续时间、
		已处理的呼叫数、已登录的坐席数、
		以及正在进行的呼叫数。


此命令不带参数。


MI FIFO 命令用法：


```c
opensips-cli -x mi call_center:list_flows
```


#### call_center:list_agents


替换过时的 MI 命令：*cc_list_agents*。


列出所有坐席 -
		对于每个坐席，将打印以下属性：
		坐席 ID、坐席登录状态、
		坐席状态（空闲、wrapup、接听中）以及正在进行的会话信息。


此命令不带参数。


MI FIFO 命令用法：


```c
opensips-cli -x mi call_center:list_agents
```


#### call_center:list_calls


替换过时的 MI 命令：*cc_list_calls*。


列出所有正在进行的呼叫 -
		对于每个呼叫，将打印以下属性：
		呼叫 ID、呼叫状态
		（welcome、queued、toagent、ended）、呼叫持续时间、
		所属流程、服务此呼叫的坐席（如果有）。


此命令不带参数。


MI FIFO 命令用法：


```c
opensips-cli -x mi call_center:list_agents
```


#### call_center:dispatch_call_to_agent


替换过时的 MI 命令：*cc_dispatch_call_to_agent*。


此函数将给定呼叫（从队列中）发送到给定坐席。
		要使操作成功，必须满足多个条件：


- 呼叫必须在队列中
- 坐席必须已登录
- 坐席必须支持呼叫所需的技能
- 坐席必须支持呼叫所需的媒体（RTP/MSRP）
- 坐席必须有请求媒体的可用会话


此命令带有两个参数。


- *call_id* - 呼叫的 ID，
			由 [MI list queue](#mi_list_queue) MI 命令提供
- *agent_id* - 呼叫的 ID，
			由 [MI list agents](#mi_list_agents) MI 命令提供


重要提示：为了使用此功能，您需要确保内部
		呼叫分配是禁用的，
		通过 [internal call dispatching](#param_internal_call_dispatching) 模块参数
		或 [MI internal call dispatching](#mi_internal_call_dispatching) MI 命令。


MI FIFO 命令用法：


```c
opensips-cli -x mi call_center:dispatch_call_to_agent B2B452.dee2.33 agentX
```


#### call_center:internal_call_dispatching


替换过时的 MI 命令：*cc_internal_call_dispatching*。


检查和/或更改
		[internal call dispatching](#param_internal_call_dispatching) 设置的命令


如果应更改设置的值，它需要一个可选参数 `dispatching`。
		值为 0 表示禁用内部分配，
		非零表示启用。


MI FIFO 命令用法：


```c
opensips-cli -x mi call_center:internal_call_dispatching 0
```


#### call_center:reset_stats


替换过时的 MI 命令：*cc_reset_stats*。


重置所有计数器类型的统计信息。


此命令不带参数。


MI FIFO 命令用法：


```c
opensips-cli -x mi call_center:reset_stats
```


### 导出的事件


#### E_CALLCENTER_AGENT_REPORT


当坐席状态发生变化时触发此事件。


参数：


- *agent_id* - 坐席的 ID。
- *state* - 坐席的状态：
					
					offline
					free
					incall
					wrapup
- *wrapup_ends* - wrapup 状态结束的时间戳；
				仅在状态为 "wrapup" 时发布
- *flow_id* - 为此坐席分配呼叫的流程 ID；
				仅在状态为 "incall" 时发布


### 导出的伪变量


`$cc_state`
			返回呼叫的状态。
			可能的返回值包括：
				*welcome* - 正在播放欢迎消息。
					*dissuading1* - 正在播放第一个劝阻消息。
					*dissuading2* - 正在播放第二个劝阻消息。
					*queue* - 呼叫在队列中。
					*preagent* - 正在呼叫坐席。
					*toagent* - 坐席在通话中。

		
		$rtpquery 用法
		
```c

...
	$json(reply) := $rtpquery;
	xlog("RTP 统计总数：$json(reply/totals)\n");
...
```

		
		
		无


## 开发者指南


### 可用函数


无


## 常见问题


**问：我在哪里可以找到更多关于 OpenSIPS 的信息？**


请查看 [https://opensips.org/](https://opensips.org/)。


**问：我可以在哪里发布关于此模块的问题？**


首先检查您的问题是否已在我们的邮件列表中解答：

与任何稳定 OpenSIPS 版本相关的电子邮件应发送至
			users@lists.opensips.org，
			与开发版本相关的电子邮件应发送至
			devel@lists.opensips.org。

如果您想保持邮件私密，请发送至
			users@lists.opensips.org。


**问：如何报告错误？**


请按照以下指南操作：
			[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享署名 4.0 国际许可协议。
