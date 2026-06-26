---
title: "异步语句"
description: "异步语句是 OpenSIPS 2.X 的关键特性之一。使用它们的主要原因之一是它们允许 OpenSIPS 脚本的性能随着高数量的每秒请求数扩展，即使在执行阻塞式 I/O 操作时..."
---

## 描述

异步语句是 OpenSIPS 2.X 的关键特性之一。使用它们的主要原因之一是它们允许 OpenSIPS 脚本的性能随着高数量的每秒请求数扩展，即使在执行 MySQL 查询、exec 命令或 HTTP 请求等阻塞式 I/O 操作时。

  

使用异步的"suspend-resume"逻辑而不是分叉大量进程来扩展还有一个优点，即优化系统资源使用，提高其最大吞吐量。通过使用更少的进程在相同时间内完成相同数量的工作，进程上下文切换被最小化，整体 CPU 使用得到改善。更少的进程也会消耗更少的系统内存。

## 串行异步操作，async()

OpenSIPS 脚本的 **async()** 语句可用于脚本编写者需要执行阻塞式 I/O 且依赖于此操作结果的情况。一些示例场景：

* 从数据库获取 SIP 认证数据
* 执行 HTTP 查询并根据其结果采取行动
* 暂停脚本执行 X 秒
* exec 外部脚本并使用其结果

### 要求

**async()** 语句依赖于事务模块（**tm**）——必须加载它。当异步操作启动时，SIP 事务将自动透明地创建（如果需要）。此事务包含暂停脚本执行所需的所有信息（例如，它存储更新的 SIP 消息以及所有 `$avp` 变量）。

### 脚本语法和用法

用法很简单：如果您的阻塞函数支持异步模式（请阅读模块文档了解这一点），那么您可以将其放入以下函数调用中：
```text

async(blocking_function(...), resume_route [,timeout]);

```
*请注意，resume_route 必须是一个 **[简单路由](https://docs.opensips.org/manual/devel/script-routes#route)***。

  

因为 **async()** 语句与脚本执行是串行的（见下文），调用它时脚本将立即停止，因此任何放在 async() 调用之后的代码都将被忽略！当前 OpenSIPS worker 将启动异步操作，之后继续处理其他待处理任务（排队的 SIP 消息、定时作业或其他可能的异步操作！）。一旦所有数据可用，它将运行 resume route——因此以最小的空闲时间恢复脚本执行。

  

在 resume route 开头，async() 模式中执行的函数的返回代码可在 `$rc` 或 `$retcode` 变量中获取。同样，所有输出参数（函数参数中用于携带输出值的变量）也将在 resume route 中可用。

  

可选的 'timeout' 参数控制脚本应等待阻塞函数完成的时间（独立于其实现）。如果阻塞式 I/O 在给定超时之前未完成，async 层将强制函数完成其 I/O（超时）并恢复脚本。

  

```c

route
{
    /* preparation code */
    ...
    async(avp_db_query("SELECT credit FROM users WHERE uid='$avp(uid)'", "$avp(credit)"), resume_credit);
    /* script execution is paused right away! */
}

route [resume_credit]
{
    if ($rc < 0) {
        xlog("error $rc in avp_db_query()\n");
        exit;
    }

    xlog("Credit of user $avp(uid) is $avp(credit)\n");
    ...
    t_relay();
}

```

  

数据按如下方式复制到 resume route：

  

> [!NOTE]
> 保留的数据（仍在 resume route 中可用）
>
> * **所有 `$avp` 变量**
> * **当前 SIP 消息中的所有更改**


> [!IMPORTANT]
> 忽略的数据（不再在 resume route 中可用）
>
> * **所有 `$var` 变量**


## 并行异步操作，launch()

OpenSIPS 脚本的 **launch()** 语句可用于脚本编写者需要执行阻塞式 I/O 但不依赖于此操作结果来继续当前 SIP 路由决策流程的情况。一些示例场景：

* 执行外部推送通知触发器
* 将数据推送到自定义数据库（例如呼叫统计、CDR 等）
* 通知 HTTP 服务发生了某个事件（例如 SIP 流量模式、欺诈检测等）

  

**launch()** 语句没有额外的模块依赖。

### 脚本语法和用法

与 **async()** 语句类似，如果您的阻塞函数支持异步模式（请阅读模块文档了解这一点），那么您可以将其放入以下函数调用中：
```c

launch(blocking_function(...));
or
launch(blocking_function(...), report_route);
route[report_route] {}
or
launch(blocking_function(...), report_route, "Something with $var(xx) to be passed to report route");
route[report_route] {
   xlog("received as input the <$param(1)> string\n");
}

```
*请注意，report_route 必须是一个 **[简单路由](https://docs.opensips.org/manual/devel/script-routes#route)***。

  

**launch()** 语句与其后的脚本执行既是异步的也是并行的（见下文）。请注意，"report_route" 可以省略，因为脚本执行不依赖于它。此路由可能在以下时间点中的任何一个被触发：

* 紧接在 **launch()** 调用之后的下一行代码之前
* 在当前 SIP 消息的路由期间
* 在当前 SIP 消息的路由之后

  

在 report route 开头，async 模式中执行的函数的返回代码可在 `$rc` 或 `$retcode` 变量中获取。同样，只有输出参数（函数参数中用于携带输出值的变量）将在此路由中可用。

  

```c

route
{
    /* preparation code */
    ...

    # send a push notification asynchronously, in parallel
    launch(exec("/usr/local/bin/send-google-pn.py"), pn_counter);
    t_relay();
}

route [pn_counter]
{
    if ($rc < 0) {
        xlog("error $rc in pn script!\n");
        update_stat("pn-failure", "1");
        exit;
    }

    update_stat("pn-success", "1");
}

```

  

> [!NOTE]
> 保留的数据（仍在 report route 中可用）
>
> * 异步函数设置的输出变量


> [!IMPORTANT]
> 忽略的数据（不再在 report route 中可用）
>
> * **任何其他变量**
> * **初始 SIP 消息**


## 异步函数列表

以下函数也可以异步调用：

* [avp_db_query](../../modules/avpops/README.md#id294986)
* [rest_get](../../modules/rest_client/README.md#id293741)
* [rest_post](../../modules/rest_client/README.md#id293886)
* [rest_put](../../modules/rest_client/README.md#id293886)
* [exec](../../modules/exec/README.md#id294052)
* [ldap_search](../../modules/ldap/README.md#afunc_ldap_search)
* [sleep](../../modules/cfgutils/README.md#id294676)

异步实现不限于上述函数，但这些是首批迁移到异步支持的函数。更多 I/O 相关函数将被移植到异步支持。

## 限制

### 异步引擎兼容性

异步引擎严重依赖于底层库公开的非阻塞 I/O 功能——诸如 HTTP 或 SQL 查询之类的阻塞 I/O 操作，仅在库还额外提供以下两者时才能成为异步：

* 相同的、最初为阻塞函数的非阻塞等价物
* 在非阻塞等价函数启动后，库还必须提供一个机制来提取与刚刚启动的数据传输操作对应的有效 Linux 文件描述符。OpenSIPS 异步引擎将轮询此 fd，并在每次有新数据可用时触发内部状态更新。当阻塞操作完成时，"resume route" 被调用，异步操作最终完成。
```

### TCP 连接问题

尽管一些库提供异步功能，但其中一些仅对 I/O 操作的"传输"部分进行异步，而非初始 TCP 连接。因此，在某些边缘情况下（例如 TCP 连接由于无响应服务器、中间防火墙丢弃数据包而不是拒绝等而挂起），异步操作实际上可能会阻塞！

  

受此限制影响的模块示例：

* rest_client - 尽管它在后续请求中重用 TCP 连接，但 libcurl 将阻塞，直到从给定 OpenSIPS worker 建立 TCP 连接。如果这些 TCP 连接挂起，对应的 OpenSIPS worker 也会挂起。

* db_mysql - 类似于 rest_client：尽管它大量重用 DB 连接，但建立每个连接都是一个阻塞操作，由于库的性质，无法成为异步。

**缓解措施**：根据您的特定设置，您可能会严重受到这些阻塞 TCP 连接的影响，或者几乎不受影响。对于前者，我们建议分叉负责阻塞操作的外部进程，并使用以下构造异步调用它们：

  

```bash
 async(exec("curl my_host", $var(response_body)), resume_route); 
```

或

```text
 async(exec("mysql-query 'SELECT * FROM subscriber...'", $var(result_row)), resume_route); 
```

### 允许的路由

由于 **async** 操作与事务引擎紧密耦合，它们只能在与 SIP 事务存在并等待完成的地方执行：

* request_route
* branch_route（*未来可能包含*）
* onreply_route（*未来可能包含*）
* local_route（*未来可能包含*）

另一方面，**launch** 语句应该可以从**任何路由**工作，因为它不依赖于底层 SIP 事务。
