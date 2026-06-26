---
title: "pike 模块"
description: "该模块提供了一种简单的 DOS 防护机制——基于网络层 flood 攻击的 DOS 防护。该模块跟踪所有（或选定的）传入 SIP 流量的 IP（作为源 IP），并阻止超过限制的 IP。同时支持 IPv4 和 IPv6 地址。"
---

## 管理指南


### 概述


该模块提供了一种简单的 DOS 防护机制——基于网络层 flood 攻击的 DOS 防护。
		该模块跟踪所有（或选定的）传入 SIP 流量的 IP（作为源 IP），
		并阻止超过限制的 IP。
		同时支持 IPv4 和 IPv6 地址。


该模块不实施任何阻止操作——它只是简单地报告某个 IP 有高流量；
		做什么决定是管理员的事（通过脚本）。


### 如何使用


有两种使用此模块的方法（作为检测 flood 攻击和采取正确行动限制对系统的影响）：


- *手动* - 在路由脚本中，您可以强制检查传入请求的源 IP，
				使用 "pike_check_req" 函数。请注意，此检查仅适用于 SIP 请求，
				您可以决定（基于脚本逻辑）要监控哪些源 IP 以及当检测到 flood 时要采取什么行动。
- *自动* - 该模块将安装内部钩子以捕获所有传入的请求和回复（即使不是格式良好的 SIP）——
				模块将监控 SIP 套接字上（从网络）传入的所有数据包。
				每次需要分析数据包的源 IP（以查看是否可信）时，
				模块将运行一个脚本路由——请参阅 "check_route" 模块参数——在那里，
				基于自定义逻辑，您可以决定该 IP 是否需要监控 flood。
				作为行动，当检测到 flood 时，模块将自动丢弃数据包。


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *无其他 OpenSIPS 模块的依赖*。


#### 外部库或应用程序


必须在运行加载了此模块的 OpenSIPS 之前安装以下库或应用程序：


- *无*。


### 导出的参数


#### sampling_time_unit (integer)


用于采样（或采样精度）的时间周期。越小越好，但会更慢。
		如果您想检测峰值，请使用较小的值。
		要限制对代理资源（例如网关）在较长时间内的访问总数，
		请使用较大的值。


重要提示：太小的值可能导致由于计时器进程过载而导致的性能损失。


*默认值为 2。*


```c title="设置 sampling_time_unit 参数"
...
modparam("pike", "sampling_time_unit", 10)
...
```


#### reqs_density_per_unit (integer)


在阻止该 IP 的所有传入请求之前，允许在 sampling_time_unit 内的请求数。
		实际上，阻止限制对于 IPv4 地址介于 x（即 reqs_density_per_unit）和 3*x 之间，
		对于 IPv6 地址介于 x 和 8*x 之间。


*默认值为 30。*


```c title="设置 reqs_density_per_unit 参数"
...
modparam("pike", "reqs_density_per_unit", 30)
...
```


#### remove_latency (integer)


在最后一次来自该 IP 的请求之后，IP 地址将在内存中保留多长时间。
		这是一 种超时值。


*注意：* 如果 *remove_latency* 的值低于 *sampling_time_unit* 的值，
		节点可能在解除阻止之前过期，从而丢失一些 UNBLOCK 事件。
		为了防止这种情况，如果 *remove_latency* 较低，
		OpenSIPS 会在内部强制其值为 *sampling_time_unit + 1*。


*默认值为 120。*


```c title="设置 remove_latency 参数"
...
modparam("pike", "remove_latency", 130)
...
```


#### check_route (integer)


脚本路由的名称，当从网络接收到数据包时，该路由将被触发（以自动方式）。
		如果您在此路由中执行 "drop"，它将向模块指示不需要监控数据包的源 IP。
		否则，源 IP 将被自动监控。


通过定义此参数，启用自动检查模式。


*默认值为 NONE（无自动模式）。*


```c title="设置 check_route 参数"
...
modparam("pike", "check_route", "pike")
...
route[pike]{
    if ($si==111.222.111.222)  /*可信，不检查*/
        drop;
    /* 所有其他 IP 都会被检查*/
}
....
```


#### pike_log_level (integer)


模块用于自动报告被检测为 flood 源头的 IP 的阻止（仅第一次）
		和解除阻止时使用的日志级别。


*默认值为 1（L_WARN）。*


```c title="设置 pike_log_level 参数"
...
modparam("pike", "pike_log_level", -1)
...
```


### 导出的函数


#### pike_check_req()


处理当前请求的源 IP，如果 IP 超过阻止限制则返回 false。


返回码：


- *1 (true)* - IP 不应被阻止或发生内部错误。

  > **警告：**
- *-1 (false)* - IP 是 flood 源头，已被先前检测到。
- *-2 (false)* - IP 被检测为新的 flood 源头——首次检测。


此函数可用于 REQUEST_ROUTE。


```c title="pike_check_req 使用示例"
...
if (!pike_check_req()) { exit; };
...
```


### 导出的 MI 函数


#### pike:list


替换过时的 MI 命令：*pike_list*。


列出 pike 树中的节点。


名称：*pike:list*


参数：*无*


MI FIFO 命令格式：


```c
		opensips-cli -x mi pike:list
		
```


#### pike:rm


替换过时的 MI 命令：*pike_rm*。


按 IP 地址从 pike 树中移除节点。


名称：*pike:rm*


参数：


- *IP* - 当前被阻止的 IP 地址。


MI FIFO 命令格式：


```c
		opensips-cli -x mi pike:rm 10.0.0.106
		
```


### 导出的事件


#### E_PIKE_BLOCKED


当 *pike* 模块决定应阻止 IP 时触发此事件。


参数：


- *ip* - 被阻止的 IP 地址。


### 提供状态/报告标识符


该模块提供 "pike" 状态/报告组，只有 "main"/默认 SR 标识符。


该模块没有发布有用的状态。


在报告/日志方面，以下事件将被报告：


- IP X.Y.Z.W 被检测为 flood


关于如何访问和使用状态/报告信息，请参见
		[https://www.opensips.org/Documentation/Interface-StatusReport-3-3](>https://www.opensips.org/Documentation/Interface-StatusReport-3-3)。


## 开发者指南


使用单一树（IPv4 和 IPv6 共用）。每个节点包含一个字节，从根到叶子的 IP 地址展开。


```c title="IP 地址树"
	   / 193 - 175 - 132 - 164
tree root /                  \ 142
		  \ 195 - 37 - 78 - 163
		   \ 79 - 134
```


为了检测完整地址，从根到叶子逐步展开，IP 地址的每个字节对应的节点被扩展。
		为了被展开，一个节点必须被命中给定次数（可能来自不同地址；
		在前面的例子中，节点 "37" 被 195.37.78.163 和 195.37.79.134 命中）。


对于 193.175.132.164，x = reqs_density_per_unit：


- 第一次请求命中后 -> 构建 "193" 节点。
- 再命中 x 次后，构建 "175" 节点；"193" 节点的命中在自身及其子节点之间分配——两者都是 x/2。
- 依此类推，节点 "132" 和 "164"。
- 一旦 "164" 构建完成，整个地址可以在树中找到。"164" 成为叶子。
		作为叶子被命中 x 次后，它将变为 "RED"（来自此地址的进一步请求将被阻止）。


因此，构建和阻止此地址需要 3*x 次命中。现在，如果请求开始来自 193.175.132.142，
		前三个字节已在树中（它们与前一个地址共享），
		所以我只需要 x 次命中（构建节点 "142" 并使其变为 "RED"）
		就可以阻止此地址。这就是阻止 IP 所需命中次数可变的原因。


将地址变为红色所需的最大命中次数为（n 是地址的字节数）：


1（第一个字节）+ x（第二个字节）+ (x / 2) * (n - 2)（其余字节）+ (n - 1)
	（变为红色）。


因此，对于 IPv4（n = 4）将是 3x，对于 IPv6（n = 16）将是 9x。
		将地址变为红色的最小命中次数是 x。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
