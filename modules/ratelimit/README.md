---
title: "限速模块"
description: "此模块实现 SIP 请求的速率限制。与 PIKE 模块不同，它基于每个 SIP 请求类型而不是每个源 IP 进行流量限制。"
---

## 管理指南

### 概述

此模块实现 SIP 请求的速率限制。与 PIKE 模块不同，它基于每个 SIP 请求类型而不是每个源 IP 进行流量限制。最新版本允许您动态地将多个消息分组为某些实体并基于它们进行流量限制。MI 接口可用于在运行 OpenSIPS 时更改可调参数。

此模块与 OpenSIPS 键值接口集成，提供使用 Redis 或 Memcached CacheDB 后端的分布式速率限制支持。内部限制数据将不再保存在每个 OpenSIPS 实例上。它将存储在分布式键值数据库中，并在决定是否应阻止或通过 SIP 消息之前由每个实例查询。

### 使用场景

限制消息在系统上处理的速率直接影响负载。ratelimit 模块可用于保护单个主机或保护 OpenSIPS 集群（在前面分配框中运行时）。

### 静态速率限制算法

ratelimit 模块支持两种不同的静态算法，供 rl_check 使用以确定是否应阻止消息。

#### 尾丢弃算法（TAILDROP）

这是一种简单算法，与长定时器间隔一起使用时存在一些风险。在每个间隔开始时，内部计数器被重置并为每个传入消息递增。一旦计数器达到配置的限制，rl_check 返回错误。

#### 随机早期检测算法（RED）

随机早期检测尝试通过测量平均负载并动态调整丢弃率来规避尾丢弃算法带来的同步问题。

#### 基于时隙的尾丢弃（SBT）

SBT 拥有一个或多个时隙的窗口。您可以设置 *window_size* 参数（秒）表示我们应该回溯多长时间来计算呼叫次数，以及 *slot_period* 参数（毫秒）表示算法应该有多精细。

#### 网络算法（NETWORK）

该算法依赖于网络接口提供的信息。每隔 timer_interval 秒检索一次所有网络接口上等待消耗的字节总量。

### 动态速率限制算法

#### 反馈算法（FEEDBACK）

使用 PID 控制器模型（参阅维基百科页面），丢弃率根据负载因子动态调整，以便负载因子始终朝着指定限制（或设定点）漂移。

### 依赖

#### OpenSIPS 模块

以下模块必须在此模块之前加载：无依赖。

#### 外部库或应用程序

无。

### 导出的参数

#### timer_interval (integer)

网络和反馈算法运行查询以及其他算法重置其计数器的计时器间隔（秒）。

*默认值为 10。*

#### limit_per_interval (integer)

配置管道限制在 *rl_check* 函数中的指定方式，仅影响尾丢弃和 RED 算法。值为 1 表示限制是按-*timer_interval* 设置的，而值为 0 表示按秒设置。

*默认值为 0（每秒限制）。*

#### default_algorithm (string)

指定在 *rl_check* 函数中未明确指定算法时应假设的算法。

*默认值为 "TAILDROP"。*

#### cachedb_url (string)

启用分布式速率限制并指定 CacheDB 接口应使用的后端。

*默认值为 "disabled"。*

```c title="设置 cachedb_url 参数"
...
modparam("ratelimit", "cachedb_url", "redis://root:root@127.0.0.1/")
...
```

#### hash_size (integer)

用于保持管道的内部哈希表的大小。较大的表速度更快但消耗更多内存。哈希大小必须是 2 的幂次方。

*默认值为 1024。*

### 导出的函数

#### rl_check(name, limit[, algorithm])

根据名称标识的管道检查当前请求并更改/更新限制。如果未找到管道，则使用指定限制和算法（如果指定）创建一个新管道。如果算法参数不存在，则使用默认值。

```c title="rl_check 用法"
...
# 对所有 INVITE 方法使用 RED 算法执行管道匹配
if (is_method("INVITE")) {
    if (!rl_check("pipe_INVITE", 100, "RED")) {
        sl_send_reply(503, "服务不可用");
        exit;
    };
};
...
```

#### rl_dec_count(name)

减少先前由 *rl_check* 函数增加的计数器。

```c title="rl_dec_count 用法"
...
if (!rl_check("gw_$ru", 100, "TAILDROP")) {
    exit;
} else {
    rl_dec_count("gw_$ru");
};
...
```

#### rl_reset_count(name)

重置先前由 *rl_check* 函数增加的计数器。

### 导出的 MI 函数

#### ratelimit:list

列出限速模块中的参数和变量。

```c
opensips-cli -x mi ratelimit:list pipe=gw_10.0.0.1
opensips-cli -x mi ratelimit:list filter=gw_*
```

#### ratelimit:reset_pipe

重置指定管道的计数器。

```c
opensips-cli -x mi ratelimit:reset_pipe gw_10.0.0.1
```

### 导出的伪变量

#### $rl_count(name)

返回管道的计数器。该变量是只读的。如果管道不存在则返回 NULL。

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
