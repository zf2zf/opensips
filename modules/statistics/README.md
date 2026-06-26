---
title: "统计模块"
description: "统计模块是内部统计管理器的包装器，允许脚本编写者动态定义和使用统计变量。"
---

## 管理指南


### 概述


统计模块是内部统计管理器的包装器，
		允许脚本编写者动态定义和使用统计变量。


通过将统计支持引入脚本，它利用了脚本定义逻辑的灵活性，
		使实现任何类型的统计场景成为可能。


### 统计组


从 OpenSIPS 2.3 开始，统计信息可以通过使用所需组的名称
		以及冒号分隔符（即 **$stat(method:invite)** 或
**update_stat("packets:$var(ptype)", "+1")**）来前缀统计名称进行分组。
		为了使其工作，必须在 OpenSIPS 启动之前使用
		**[stat groups](#param_stat_groups)**
		模块参数定义组。


该模块允许使用
		**[stat iter init](#func_stat_iter_init)**
		和 **[stat iter next](#func_stat_iter_next)**
		函数轻松遍历组的统计信息。


默认情况下，所有统计信息都属于
		**"dynamic"** 组。


### 统计序列


统计序列提供在预定义时间窗口内累积统计数据的能力。
		数据存储在循环缓冲区中，将新数据推送到顶部，
		并从底部移除过期值（超出时间范围的值）。
		这些统计信息可用于提供按时间统计的数据，
		如 ACD、ASR、AST 等，可以通过经典统计接口读取，
		即通过 *$stat()* 变量。


统计序列配置文件描述了用于存储数据的时间范围，
		以及如何累积和解释数据。根据配置的算法，
		统计序列有几种类型可以使用：


- *accumulate* - 在计数器中累积指定值；
			类似于经典统计方式工作，只是会在指定时间范围后重置
- *average* - 返回时间范围内所有输入数据的平均值；
			在计算 PDD、AST、ACD 统计时很有用。
- *percentage* - 表示一组值占总值的百分比；
			在计算 ASR、NER、CCR 统计时很有用。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他 OpenSIPS 模块*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### variable (string)


新统计变量的名称。名称后面可以跟随描述变量行为的附加标志：


- *no_reset* : 变量不能重置。


```c title="variable 示例"
modparam("statistics", "variable", "register_counter")
modparam("statistics", "variable", "active_calls/no_reset")
```


#### stat_groups (string)


一个逗号分隔的值字符串，指定可以在 OpenSIPS 脚本中使用的统计组。
		组不能包含前导或尾随空白字符。


```c title="设置 stat_groups 参数"
modparam("statistics", "stat_groups", "method, packet, response")
```


#### stat_series_profile (string)


用于定义统计序列配置文件。格式为：*name: [attr=value]**，
		其中 *name* 是配置文件的名称，
		*attr=value* 包含所定义配置文件的多个设置。
		可能的属性及其值如下：


- *algorithm* - 指示数据应如何在指定时间范围内
			存储和累积。可能的值有：
			*accumulate*、*average* 和
			*percentage*，如
			**[统计序列部分](#statistic_series)**
			段落所述（默认为 *accumulate*）
- *hash_size* - 每个定义/使用的统计信息都存储在
			附加到配置文件的哈希映射中；此设置调整哈希的大小
			（默认为：8）
- *group* - 指示属于此配置文件的统计信息
			所在的组（如同
			**[stat groups](#param_stat_groups)**
			中所述
			（默认为使用与配置文件相同的组）
- *window* - 时间范围包含的秒数；
			所有旧值（超出指定窗口）将被丢弃
			（默认为 *60* 秒）
- *slots* - 每个窗口的槽数；用于调整
			循环缓冲区的粒度；槽数越高，
			得到的统计信息越准确；
			（默认为与 *window* 参数相同的值）
- *percentage_factor* - 用于
			*percentage* 算法配置文件以指定
			要使用的百分比因子（默认为 *100*）


可以为每个需要的配置文件多次设置此参数。


```c title="设置 stat_series_profile 参数"
...
# 定义一个在最后一分钟累积平均值的统计
modparam("statistics", "stat_series_profile", "avg: algorithm=average")
...
# 定义一个在 10 分钟内累积平均值，粒度为 1 分钟的统计
# （600 秒窗口中的 10 个槽）
modparam("statistics", "stat_series_profile", "avg_10m: algorithm=average window=600 slots=10")
...
# 定义一个计算最后一小时内值百分比的统计，粒度为 10 分钟
# （3600 秒窗口中的 6 个槽）
modparam("statistics", "stat_series_profile", "perc_1h: algorithm=percentage window=3600 slots=6")
...
```


### 导出的函数


#### update_stat(variable, value)


用新值更新统计变量的值。


参数的含义如下：


- *variable* (string) - 要更新的变量；
- *value* (int) - 要更新的值；也可以为负。


此函数可用于 REQUEST_ROUTE、BRANCH_ROUTE、
		FAILURE_ROUTE 和 ONREPLY_ROUTE。


```c title="update_stat 使用示例"
...
update_stat("register_counter", 1);
...
$var(a_calls) = "active_calls";
update_stat($var(a_calls), -1);
...
```


#### reset_stat(variable)


将统计变量的值重置为零。


参数的含义如下：


- *variable* (string) - 要重置的变量


此函数可用于 REQUEST_ROUTE、BRANCH_ROUTE、
		FAILURE_ROUTE 和 ONREPLY_ROUTE。


```c title="reset_stat 使用示例"
...
reset_stat("register_counter");
...
$var(reg_counter) = "register_counter";
update_stat($var(reg_counter));
...
```


#### stat_iter_init(group, iter)


重新初始化 "iter" 以便开始遍历属于给定 "group" 的所有统计信息。


参数的含义如下：


- *group* (string)
- *iter* (string) - 在内部与相应的迭代器匹配


此函数可用于 REQUEST_ROUTE、BRANCH_ROUTE、
		FAILURE_ROUTE 和 ONREPLY_ROUTE。


```c title="stat_iter_init 使用示例"
...
stat_iter_init("packet", "iter");
...
```


#### stat_iter_next(name, val, iter)


尝试获取 "iter" 指向的当前统计信息。
		如果成功，相关信息将写入 "name" 和 "val"，
		同时推进 "iter"。到达迭代末尾时返回负值。


参数的含义如下：


- *name* (var)
- *val* (var)
- *iter* (string) - 在内部与相应的迭代器匹配


此函数可用于 REQUEST_ROUTE、BRANCH_ROUTE、
		FAILURE_ROUTE 和 ONREPLY_ROUTE。


```c title="stat_iter_next 使用示例"
...
# 定期清除数据包相关数据
timer_route [clear_packet_stats, 7200] {
	stat_iter_init("packet", "iter");
	while (stat_iter_next($var(stat), $var(val), "iter"))
		reset_stat("packet:$var(stat)");
}
...
```


#### update_stat_series(profile, variable, value)


更新序列统计信息的值。


参数的含义如下：


- *profile* (string) - 如
			**[stat series profile](#param_stat_series_profile)**
			中所定义的配置文件
- *variable* (string) - 要更新的变量；
- *value* (int) - 要更新的值；也可以为负；
			当使用 *percentage* 算法时，
			结果值表示正值占总值的百分比（正值 + 负值）


此函数可用于任何路由。


```c title="update_stat_series 使用示例"
...
# 记录失败呼叫
update_stat_series("perc_1h", "ASR_1h", -1);

# 记录成功呼叫
update_stat_series("perc_1h", "ASR_1h", 1);

# 计算平均 PDD
update_stat_series("avg", "PDD", $var(pdd_ms));
...
```


### 导出的伪变量


#### $stat


允许对给定统计信息进行 "获取" 或 "重置" 操作。


统计信息的名称可以选择性地以搜索组和冒号分隔符为前缀。


如果未提供搜索组，统计信息首先在核心组中搜索。
		如果未找到，搜索将继续在 "dynamic" 组中进行，
		默认情况下，该组包含所有未明确分组且未由 OpenSIPS 核心导出的统计信息。


```c title="$stat 使用示例"
...
xlog("SHM 已用大小 = $stat(used_size), 无邀请 = $stat(method:invite)\n");
...
$stat(err_requests) = 0;
...

```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
