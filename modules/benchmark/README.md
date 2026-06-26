---
title: "基准测试模块"
description: "此模块帮助开发人员对模块函数进行基准测试。通过通过配置文件或其 API 添加此模块的函数，OpenSIPS 可以为每个函数记录性能分析信息。"
---

## 管理指南


### 概述


此模块帮助开发人员对模块函数进行基准测试。通过通过配置文件或其 API 添加此模块的函数，OpenSIPS 可以为每个函数记录性能分析信息。


start_timer 和 log_timer 调用之间的持续时间通过 OpenSIPS 的日志工具存储和记录。请注意，所有持续时间均以微秒为单位（不要与毫秒混淆！）。


重要提示：由于此基准测试旨在测量执行脚本不同部分/块所花费的时间（而不是测量 SIP 信令所导致的时间），基准测试模块应在同一顶级路由（请求路由、失败路由、分支路由、回复路由等）内使用。它不设计用于跨不同类型的顶级路由使用（例如在请求路由中启动并在失败路由中结束）！


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *无其他 OpenSIPS 模块的依赖*。


#### 外部库或应用程序


以下库或应用程序必须在运行加载了此模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### enable (int)


即使加载了模块，默认也不启用基准测试。此变量可以有三个不同的值：


- -1 - 全局禁用基准测试
- 0 - 启用按计时器启用。单个计时器默认处于非活动状态，一旦实现该功能，可以通过 MI 接口激活。
- 1 - 全局启用基准测试


*默认值为 "0"。*


```c title="设置 enable 参数"
...
modparam("benchmark", "enable", 1)
...
```


#### granularity (int)


日志记录通常不是每次调用 log_timer() 函数时都进行，而是每 n 次调用进行一次。n 通过此变量定义。合理的粒度似乎是 100。


如果粒度设置为 0，则不会自动记录任何内容。相反，可以使用 benchmark:poll_results MI 命令来检索结果并清除本地值。


*默认值为 "100"。*


```c title="设置 granularity 参数"
...
modparam("benchmark", "granularity", 500)
...
```


#### loglevel (int)


设置基准测试日志的日志级别。应使用以下级别：


- -3 - L_ALERT
- -2 - L_CRIT
- -1 - L_ERR
- 1 - L_WARN
- 2 - L_NOTICE
- 3 - L_INFO
- 4 - L_DBG


*默认值为 "3"（L_INFO）。*


```c title="设置 loglevel 参数"
...
modparam("benchmark", "loglevel", 4)
...
```


这将把日志级别设置为 L_DBG。


### 导出的函数


#### bm_start_timer(name)


启动计时器 "name"。随后调用 "bm_log_timer()" 记录此计时器。


```c title="bm_start_timer 使用示例"
...
bm_start_timer("test");
...
```


#### bm_log_timer(name)


记录具有给定 ID 的计时器。记录以下数据：


- *Last msgs* 是上次日志记录间隔内的调用次数。这等于 granularity 变量。


- *Last sum* 是当前日志记录间隔内的累积持续时间（即最近 "granularity" 次调用）。


- *Last min* 是上次间隔内 start/log_timer 调用之间的最小持续时间。


- *Last max* - 最大持续时间。


- *Last average* 是自上次记录以来 bm_start_timer() 和 bm_log_timer() 之间的平均持续时间。


- *Global msgs* 调用 log_timer 的次数。


- *Global sum* 微秒为单位的总持续时间。


- *Global min*... 你懂的。 :)


- *Global max* 同样显而易见。


- *Global avg* 可能是最有趣的值。


```c title="bm_log_timer 使用示例"
...
bm_log_timer("test");
...
```


### 导出的伪变量


导出的伪变量在下一节中列出。


#### $BM_time_diff


*$BM_time_diff* - bm_start_timer(name) 和 bm_log_timer(name) 调用之间经过的时间差。如果未调用 bm_log_timer()，则值为 0。


### 导出的 MI 函数


#### benchmark:enable_global


替换已弃用的 MI 命令：*bm_enable_global*。


启用/禁用模块。


参数：


- *enable* - 值可以为 -1、0 或 1。请参阅 "enable" 参数的描述。


MI FIFO 命令格式：


```c
			opensips-cli -x mi benchmark:enable_global 1
			
```


#### benchmark:enable_timer


替换已弃用的 MI 命令：*bm_enable_timer*。


启用或禁用单个计时器。


参数：


- *timer* - 计时器名称
- *enable* - 启用 (1) 或禁用 (0) 计时器


MI FIFO 命令格式：


```c title="启用计时器"
...
opensips-cli -x mi benchmark:enable_timer test 1
...
```


#### benchmark:granularity


替换已弃用的 MI 命令：*bm_granularity*。


修改基准测试粒度。


参数：


- *benchmark:granularity* - 请参阅 "granularity" 参数的描述。


MI FIFO 命令格式：


```c
			opensips-cli -x mi benchmark:granularity 300
			
```


#### benchmark:loglevel


替换已弃用的 MI 命令：*bm_loglevel*。


修改模块日志级别。


参数：


- *log_level* - 请参阅 "loglevel" 参数的描述。


MI FIFO 命令格式：


```c
			opensips-cli -x mi benchmark:loglevel 4
			
```


#### benchmark:poll_results


替换已弃用的 MI 命令：*bm_poll_results*。


返回每个计时器的当前和全局结果。此命令仅在 "granularity" 变量设置为 0 时可用。它可用于以稳定的时间间隔获取结果，而不是每 N 条消息获取一次。每个计时器将有 2 个节点 - 本地和全局值。值的格式与日志文件中通常使用的格式相同。这种获取结果的方式允许与外部图形应用程序（如 Munin）接口。


如果自上次检查以来没有对 *bm_log_timer* 的新调用，则计时器的所有当前值都将等于 0。每次调用 *benchmark:poll_results* 将重置当前值（但不会重置全局值）。


```c title="通过 FIFO 接口获取结果"
...
opensips-cli -x mi benchmark:poll_results
register_timer
	3/40/12/14/13.333333
	9/204/12/97/22.666667
security_check_timer
	3/21/7/7/7.000000
	9/98/7/41/10.888889
...
```


### 使用示例


测量用户位置查找的持续时间。


```c title="基准测试使用示例"
...
bm_start_timer("usrloc-lookup");
lookup("location");
bm_log_timer("usrloc-lookup");
...
```


## 开发者指南


基准测试模块提供供其他 OpenSIPS 模块使用的内部 API。可用的函数与用户导出的函数相同。


请注意，此模块主要用于开发人员。在生产环境中应谨慎使用。


### 可用函数


#### bm_register(name, mode, id)


此函数注册一个新的计时器和/或返回与该计时器关联的内部 ID。mode 控制如果未找到新计时器时是否创建。id 将由启动和记录计时器函数使用。


#### bm_start(id)


此函数等同于用户导出的函数 bm_start_timer。不过，id 作为整数传递。


#### bm_log(id)


此函数等同于用户导出的函数 bm_log_timer。不过，id 作为整数传递。


### 基准测试 API 示例


```c title="从另一个模块使用基准测试模块的 API"
...
#include "../benchmark/benchmark.h"
...
struct bm_binds bmb;
...
...
/* 加载基准测试 API */
if (load_bm_api( &bmb )!=0) {
    LM_ERR("can't load benchmark API\n");
    goto error;
}
...
...
/* 在（通常是用户导出的）模块函数期间启动/记录计时器 */
bmb.bm_register("test", 1, &id)
bmb.bm_start(id);
do_something();
bmb.bm_log(id);
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0 版授权
