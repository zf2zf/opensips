---
title: "qrouting（基于质量的路由）模块"
description: "*qrouting* 是一个构建在 [drouting](../drouting/doc/drouting.html)、[dialog](../dialog/doc/dialog.html) 和 [tm](../tm/doc/tm.html) 之上的模块，用于实时跟踪一系列重要的网关信令质量指标（即 ASR、CCR、PDD、AST、ACD——更多详细信息见下文）..."
---

## 管理指南


### 概述


*qrouting* 是一个构建在
	[drouting](../drouting/doc/drouting.html)、
	[dialog](../dialog/doc/dialog.html) 和
	[tm](../tm/doc/tm.html) 之上的模块，
	用于实时跟踪一系列重要的网关信令质量指标（即 ASR、CCR、PDD、AST、ACD——更多详细信息见下文）。因此，qrouting 能够通过根据网关在实时流量中的表现动态重新排序网关来在运行时调整前缀路由行为，从而：


- 表现良好的网关优先用于路由
- 显示信令质量下降的网关将被降级到路由列表的末尾


### 监控的统计信息


该模块为每个 drouting **（前缀，目标）** 对跟踪一系列统计信息，其中"目标"可以是网关或运营商。统计信息包括：


- ASR（应答成功率）- 被应答的电话呼叫百分比（200 回复状态码）。
- CCR（呼叫完成率）- 被网关应答的电话呼叫百分比，不包括 5xx、6xx 回复码和内部 408 超时。以下始终成立：CCR >= ASR。
- PDD（拨号后延迟）- 收到初始 INVITE 到收到第一个 180/183 临时回复之间的时间（以毫秒为单位）（呼叫状态推进到*"响铃"*）。
- AST（平均建立时间）- 收到初始 INVITE 到收到第一个 200 OK 回复之间的时间（以毫秒为单位）（呼叫状态推进到*"已应答"*）。以下始终成立：AST >= PDD。
- ACD（平均呼叫时长）- 收到初始 INVITE 到收到任一参与者的第一个 BYE 请求之间的时间（以秒为单位）（呼叫状态推进到*"已结束"*）。


### 依赖


#### OpenSIPS 模块


以下模块必须加载才能使此模块工作：


- *提供访问 "qr_profiles" 表的 SQL DB 模块*
- *tm*
- *dialog*
- *drouting*


### 导出的参数


#### db_url (string)


SQL 数据库 URL。


*默认值为 **NULL**。*


```c title="设置 db_url 参数"
modparam("qrouting", "db_url", "mysql://opensips:opensipsrw@localhost/opensips")
	
```


#### table_name (string)


基于质量的路由配置文件表的名称。


*默认值为 **"qr_profiles"**。*


```c title="设置 table_name 参数"
modparam("qrouting", "table_name", "qr_profiles_bak")
	
```


#### algorithm (integer)


要使用的基于质量的目标选择/负载均衡算法。


可能的值：


- **"dynamic-weights"** -
				对于每个前缀，所有目标以相等的权重开始，接收相等的流量份额。随着为目标收集信令统计信息，表现不佳的目标将根据
				*qr_profiles* 表的"penalty"列获得更少的流量。
- **"best-dest-first"** - 对于每个前缀，
				第一个（即*得分最高的*）目标将只要其质量保持不变就接收所有流量。最初，所有目标以满分开始。如果在路由期间一个或多个信令统计信息低于"warn"或"crit"阈值， 则分数可能会下降，在这种情况下，目标将相应排序，流量将被路由到列表中新确定的第一个位置。
*注意*：为获得最佳效果，当
				使用"best-dest-first"算法时，必须按预期质量降序配置目标！（即最佳质量网关必须放在列表开头附近）


*默认值为 **"dynamic-weights"**。*


```c title="设置 algorithm 参数"
modparam("qrouting", "algorithm", "best-dest-first")
	
```


#### history_span (integer)


网关对给定呼叫的统计信息将被保留的持续时间（以分钟为单位）。


*默认值为 **30** 分钟。*


```c title="设置 connection_timeout 参数"
modparam("qrouting", "history_span", 15)
	
```


#### sampling_interval (integer)


统计信息采样窗口的持续时间（以秒为单位）。每
		*[采样间隔](#param_sampling_interval)* 秒，
		最近采样窗口期间累积的统计信息将被添加到每个网关，而最旧的采样间隔统计信息将从每个网关中减去（轮转出去）。


较低的值会导致更接近实时的流量变化调整，但也会增加 CPU 使用率和内部争用（由于锁定）。


*默认值为 **5** 秒。*


```c title="设置 connect_poll_interval 参数"
modparam("qrouting", "sampling_interval", 5)
	
```


#### extra_stats (string)


模块额外保持和监控的自定义统计信息的分号分隔列表。为了收集这些统计信息，模块期望脚本编写者在想要为（前缀，目标）元组增加自定义统计信息时调用
		[qr set xstat](#func_qr_set_xstat)。


额外统计信息有两种风格：*positive*（值越高越好，例如 ASR）或 *negative*（值越低越好，例如 PDD）。风格决定了要用于与统计信息阈值进行比较的比较运算符，
		可通过在统计信息名称前分别加 **"+"** 或 **"-"** 来指定（见下文示例）。


每个统计信息可接受的最小采样数可通过可选的 **/<min_samples>**
		后缀更改。默认值：**30** 个采样（最小）。


自定义统计信息的阈值和惩罚必须通过 *qr_profiles* 表提供，
		通过为每个额外统计信息扩展 4 列，名称按以下模板：


- warn_threshold_*<STAT>*
- crit_threshold_*<STAT>*
- warn_penalty_*<STAT>*
- crit_penalty_*<STAT>*


*默认值为 **NULL**。*


```c title="设置 extra_stats 参数"
modparam("qrouting", "extra_stats", "+mos/60; +r_factor; -503_replies/100")
	
```


#### min_samples_asr (integer)


在考虑之前，每个（前缀，目标）对可接受的最少采样 ASR 统计信息量。只要采样数保持在此限制以下，该对的 ASR 统计信息被视为健康的。


*默认值为 **30**。*


```c title="设置 min_samples_asr 参数"
modparam("qrouting", "min_samples_asr", 50)
	
```


#### min_samples_ccr (integer)


在考虑之前，每个（前缀，目标）对可接受的最少采样 CCR 统计信息量。只要采样数保持在此限制以下，该对的 CCR 统计信息被视为健康的。


*默认值为 **30**。*


```c title="设置 min_samples_ccr 参数"
modparam("qrouting", "min_samples_ccr", 50)
	
```


#### min_samples_pdd (integer)


在考虑之前，每个（前缀，目标）对可接受的最少采样 PDD 统计信息量。只要采样数保持在此限制以下，该对的 PDD 统计信息被视为健康的。


*默认值为 **10**。*


```c title="设置 min_samples_pdd 参数"
modparam("qrouting", "min_samples_pdd", 15)
	
```


#### min_samples_ast (integer)


在考虑之前，每个（前缀，目标）对可接受的最少采样 AST 统计信息量。只要采样数保持在此限制以下，该对的 AST 统计信息被视为健康的。


*默认值为 **10**。*


```c title="设置 min_samples_ast 参数"
modparam("qrouting", "min_samples_ast", 15)
	
```


#### min_samples_acd (integer)


在考虑之前，每个（前缀，目标）对可接受的最少采样 ACD 统计信息量。只要采样数保持在此限制以下，该对的 ACD 统计信息被视为健康的。


*默认值为 **20**。*


```c title="设置 min_samples_acd 参数"
modparam("qrouting", "min_samples_acd", 30)
	
```


#### event_bad_dst_threshold (string)


给定（前缀，目标）组合可接受的最小质量，以 [0, 1] 区间内的带引号浮点数给出。每当（前缀，目标）组合的分数低于此阈值时，将触发 [E QROUTING BAD DST](#event_e_qrouting_bad_dst) 事件。


*默认值为 **NULL**（未设置）。*


```c title="设置 event_bad_dst_threshold 参数"
modparam("qrouting", "event_bad_dst_threshold", "0.5")
	
```


#### decimal_digits (string)


日志或 MI 输出中使用的小数位数。


*默认值为 **2**。*


```c title="设置 decimal_digits 参数"
modparam("qrouting", "decimal_digits", 4)
	
```


### 导出的函数


#### qr_set_xstat(rule_id, gw_name, stat_name, inc_by, [part], [inc_total])


为给定（前缀，网关）组合的额外统计信息提供新的采样值。额外统计信息可使用
		[extra stats](#param_extra_stats) 模块参数定义。


参数：


- *rule_id (integer)* - 持有前缀及其目标的 drouting 规则的数据库 ID
- *gw_name (string)* - 要统计的网关。该网关必须是上述规则目标的一部分。
- *stat_name (string)* - 要统计的统计信息
- *inc_by (string)* - 带引号的浮点数，表示要添加到统计信息的量
- *part (string, 可选, 默认值: 'Default')* -
				要使用的 drouting 分区
- *inc_total (string, 可选, 默认值: 1)* -
				要添加到 total 统计信息计数器的量。通常此值应为 1，但当需要在同一已建立呼叫期间第二次、第三次等设置自定义统计信息时，可以将其设置为 0。


此函数可用于任何路由。


```c title="qr_set_xstat() 使用示例"
# MoS 每个呼叫只设置一次，所以我们可以省略 "inc_total"
$var(rule_id) = 1574;
$var(gw_name) = "GW-28";
$var(mos_score) = "4.28";
qr_set_xstat($var(rule_id), $var(gw_name), "mos", $var(mos_score));
	
```


#### qr_disable_dst(rule_id, dst_name, [part])


在给定的路由规则内，暂时从路由中移除指定的网关或运营商，直到通过
		[qr enable dst](#func_qr_enable_dst) 或 [mi enable dst](#mi_enable_dst) 重新启用。重启 OpenSIPS 后此移除效果将丢失。


参数：


- *rule_id (integer)* - drouting 规则的数据库 ID
- *dst_name (string)* - 要禁用的网关或运营商
- *part (string, 可选)* - drouting 分区


此函数可用于任何路由。


```c title="qr_disable_dst() 使用示例"
# 通过 @rule_id 到 @dst_name 的信令质量正在下降，移除它！
event_route [E_QROUTING_BAD_DST]
{
	qr_disable_dst($param(rule_id), $param(dst_name), $param(partition));
}
	
```


#### qr_enable_dst(rule_id, dst_name, [part])


在给定的路由规则内，重新将指定的网关或运营商引入路由过程。


参数：


- *rule_id (integer)* - drouting 规则的数据库 ID
- *dst_name (string)* - 要禁用的网关或运营商
- *part (string, 可选)* - drouting 分区


此函数可用于任何路由。


```c title="qr_enable_dst() 使用示例"
# 禁令已过期，让我们重新启用此网关并观察其表现
qr_enable_dst($param(rule_id), $param(dst_name), $param(partition));
	
```


### 导出的 MI 函数


#### qrouting:reload


替代已废弃的 MI 命令：*qr_reload*。


从 SQL 数据库重新加载所有基于质量的路由规则。


MI FIFO 命令格式：


```c
opensips-cli -x mi qrouting:reload
		
```


#### qrouting:status


替代已废弃的 MI 命令：*qr_status*。


检查所有分区中所有 drouting 网关在当前
		[历史跨度](#param_history_span) 内的信令质量统计信息，具有多种过滤级别。


参数：


- *partition (可选)* - 列出统计信息的特定 drouting 分区
- *rule_id (可选)* - 列出统计信息的特定 drouting 规则数据库 ID
- *dst_name (可选)* - 列出统计信息的特定网关或运营商名称


MI FIFO 命令格式：


```c
opensips-cli -x mi qrouting:status
opensips-cli -x mi qrouting:status pstn
opensips-cli -x mi qrouting:status pstn 11 MY-GW-3
opensips-cli -x mi qrouting:status pstn 17 MY-CARR-7
		
```


#### qrouting:disable_dst


替代已废弃的 MI 命令：*qr_disable_dst*。


在给定的路由规则内，暂时从路由中移除指定的网关或运营商，直到手动重新启用。重启 OpenSIPS 后此移除效果将丢失。


参数：


- *partition (可选)* - drouting 分区
- *rule_id* - drouting 规则的数据库 ID
- *dst_name* - 要禁用的网关或运营商


MI FIFO 命令格式：


```c
opensips-cli -x mi qrouting:disable_dst 14 MY-CARR-7
opensips-cli -x mi qrouting:disable_dst pstn 81 MY-GW-3
		
```


#### qrouting:enable_dst


替代已废弃的 MI 命令：*qr_enable_dst*。


在给定的路由规则内，重新将指定的网关或运营商引入路由过程。


参数：


- *partition (可选)* - drouting 分区
- *rule_id* - drouting 规则的数据库 ID
- *dst_name* - 要启用的网关或运营商


MI FIFO 命令格式：


```c
opensips-cli -x mi qrouting:enable_dst 14 MY-CARR-7
opensips-cli -x mi qrouting:enable_dst pstn 81 MY-GW-3
		
```


### 导出的事件


#### E_QROUTING_BAD_DST


在路由期间，每当（前缀，目标）对的分数低于
		[event bad dst threshold](#param_event_bad_dst_threshold) 时，可能会异步引发此事件。


参数：


- *partition* - drouting 分区名称
- *rule_id* - drouting 规则的数据库 ID
- *dst_name* - 相关网关或运营商的名称
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0（Creative Common License 4.0）授权。
