---
title: "核心事件"
description: "事件通过事件接口由 OpenSIPS 核心导出。"
---

事件通过事件接口由 **OpenSIPS** 核心导出。

---

## E_CORE_THRESHOLD

超过阈值限制。

当某个操作花费的时间超过特定阈值时触发此事件。当 MySQL 或 DNS 查询花费时间过长，或 SIP 消息处理超过特定限制时都会触发。更多信息请参阅[此帖子](http://lists.opensips.org/pipermail/users/2011-February/016918.html)。

参数:
* **source**: 事件来源: mysql 模块，core（用于 DNS 或消息处理警告）。
* **time**: 操作花费的时间（微秒）
* **extra**: 额外信息，取决于事件来源

## E_CORE_PKG_THRESHOLD

私有内存阈值超出。

当私有内存使用量超过由 **event_pkg_threshold** 核心参数指定的阈值限制时触发此事件。它警告外部应用程序可用私有内存的低值。

参数:
* **usage**: 私有内存使用百分比。值可在 **event_pkg_threshold** 和 100 之间。
* **threshold**: 脚本中指定的 **event_pkg_threshold**。
* **used**: 已使用的私有内存量。
* **size**: 私有内存总量。
* **pid**: 触发事件的进程的 pid。

> [!NOTE]
> 如果未指定 event_pkg_threshold 或为 0，则此事件被禁用。

## E_CORE_SHM_THRESHOLD

共享内存阈值超出。

当共享内存使用量超过由 **event_shm_threshold** 核心参数指定的阈值限制时触发此事件。它警告外部应用程序可用共享内存的低值。

参数:
* **usage**: 共享内存使用百分比。值可在 **event_shm_threshold** 和 100 之间。
* **threshold**: 脚本中指定的 **event_shm_threshold**。
* **used**: 已使用的共享内存量。
* **size**: 共享内存总量。

> [!NOTE]
> 如果未指定 event_shm_threshold 或为 0，则此事件被禁用。

## E_CORE_PROC_AUTO_SCALE

进程自动缩放（扩展和收缩）。

每当由于自动缩放逻辑创建新进程（fork）或终止进程时触发此事件。要使此事件触发，必须在配置中启用[自动缩放](https://docs.opensips.org/manual/devel/script-coreparameters#auto_scaling_profile)。

参数:
* **group_type**: 缩放组的类型/名称（UDP/TCP/TIMER）。
* **group_filter**: 缩放组的过滤器（通常为 UDP 的 socket/interface）。
* **group_load**: 缩放组上的负载。
* **scale**: "up" 或 "down"
* **process_id**: 被缩放（扩展或收缩）进程的进程 ID（在 OpenSIPS 级别）。
* **pid**: 被缩放进程的 PID（操作系统级别）。

## E_CORE_TCP_DISCONNECT

TCP 连接断开。

当 TCP 连接被终止/断开时触发此事件。

参数:
* **src_ip**: TCP 连接的源 IP
* **src_port**: TCP 连接的源端口
* **dst_ip**: TCP 连接的目的 IP
* **dst_port**: TCP 连接的目的端口
* **proto**: 底层 TCP 连接的协议（即 tcp、tls、ws、wss 等）

## E_CORE_SR_STATUS_CHANGED

状态/报告状态更改。

当 SR 标识符的状态发生变化时触发此事件。

参数:
* **group**: SR 组名称
* **identifier**: SR 标识符名称
* **status**: SR 标识符的新状态（数值）
* **details**: 附加到新状态的详情/文本
* **old_status**: SR 标识符的旧状态（数值）

## E_CORE_LOG

产生的日志消息。

每当 OpenSIPS 产生日志消息时触发此事件。要使此事件触发，必须在配置中启用 [log_event_enabled](https://docs.opensips.org/manual/3-4/script-coreparameters#log_event_enabled)。

参数:
* **time**: 产生日志消息的时间
* **pid**: 产生此日志消息的进程的 PID
* **level**: 此消息的日志级别（"DBG"、"INFO" 等）
* **module**: 产生此日志消息的模块; 对于由 **xlog()** 函数从脚本触发的日志则不存在
* **function**: 产生此日志消息的内部函数; 对于由 **xlog()** 函数从脚本触发的日志则不存在
* **prefix**: 日志前缀，通过 [log_prefix](https://docs.opensips.org/manual/3-4/script-coreparameters#log_prefix) 参数配置。如果未配置该参数则不存在。
* **message**: 实际日志消息内容

## E_PROFILING_PROC

进程性能分析事件。

当进程性能分析被激活时生成此事件。它报告在进程内部发生的不同操作。

参数:
* **sec**: UNIX 时间戳，秒
* **usec**: 秒内微秒
* **session**: 会话 ID，用于对属于性能分析会话的所有事件进行分组
* **verb**: 性能分析操作，如 'start'、'enter'、'exit' 和 'end'
* **name**: 性能分析操作的描述
* **type**: 生成性能分析数据的进程类型
* **depth**: 执行深度 - 'start' 为级别 1，每次 'enter' 增加，每次 'exit' 减少。
* **file**: 进行性能分析的配置文件名或 C 函数; 仅对 'enter' 和 'exit' 设置
* **line**: 'file' 中的行号; 仅对 'enter' 和 'exit' 设置
* **status**: 仅对 'exit' 和 'end'，'name' 操作的状态/返回码（高度依赖于其性质）

使用示例:
```text

{'sec': 1776767469, 'usec': 200446, 'session': 3463978, 'verb': 'start', 'name': 'SIP receiver udp:127.0.0.1:5060', 'type': 1, 'depth': 0}
{'sec': 1776767469, 'usec': 201035, 'session': 3463978, 'verb': 'enter', 'name': 'udp proto reading', 'type': 1, 'depth': 1, 'file': 'handle_io', 'line': 317}
{'sec': 1776767469, 'usec': 201485, 'session': 3463978, 'verb': 'enter', 'name': 'receive_msg', 'type': 1, 'depth': 2, 'file': 'receive_msg', 'line': 120}
{'sec': 1776767469, 'usec': 202558, 'session': 3463978, 'verb': 'enter', 'name': 'request_script', 'type': 1, 'depth': 3, 'file': 'receive_msg', 'line': 235}
{'sec': 1776767469, 'usec': 203201, 'session': 3463978, 'verb': 'exit', 'name': 'request_script', 'type': 1, 'depth': 2, 'file': 'receive_msg', 'line': 237, 'status': 1}
{'sec': 1776767469, 'usec': 203533, 'session': 3463978, 'verb': 'exit', 'name': 'receive_msg', 'type': 1, 'depth': 1, 'file': 'receive_msg', 'line': 316, 'status': 0}
{'sec': 1776767469, 'usec': 203663, 'session': 3463978, 'verb': 'exit', 'name': 'reading done', 'type': 1, 'depth': 0, 'file': 'handle_io', 'line': 324, 'status': 0}
{'sec': 1776767469, 'usec': 203786, 'session': 3463978, 'verb': 'end', 'name': 'SIP receiver udp:127.0.0.1:5060', 'type': 1, 'depth': 0, 'status': 0}

```

## E_PROFILING_SCRIPT

脚本性能分析事件。

类似于 E_PROFILING_PROC，但与脚本（路由）执行相关。它使用与 E_PROFILING_PROC 相同的参数。
