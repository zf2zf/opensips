---
title: "Core MI 函数"
description: "MI（管理接口）函数，由 OpenSIPS 核心导出。"
---

**OpenSIPS** 核心导出的 MI（管理接口）函数。

## 核心

### arg
返回 **OpenSIPS** 启动时使用的完整参数列表。与 UNIX 一样，第一个参数是可执行文件的名称。

**参数**: 无

**输出**: 一个包含多个字符串的数组，表示这些参数。

使用示例:
```text

    # opensips-mi arg
    [
        "./opensips",
        "-f",
        "/etc/openser/test.cfg"
    ]

```

### help
打印 MI 命令的使用信息。当提供 *mi_cmd* 时，响应包含命令描述和导出它的模块。

**参数**:
* *mi_cmd* (可选) - MI 命令名称

使用示例:
```text

    # opensips-mi help
    # opensips-mi help core:version

```

### kill
该命令将终止 **OpenSIPS**（并执行内部关闭）。

**参数**: 无

**输出**: 无

使用示例:
```text

    # opensips-mi kill

```

### log_level
获取或设置一个或所有 OpenSIPS 进程的日志级别。如果不向 **log_level** 命令传递参数，它将打印所有进程当前日志级别的表格。如果给定日志 **level**，它将被设置到每个进程。如果还给出了 **pid**，则日志级别将仅更改该进程。

**参数**:
* *level* (可选) - 日志级别 (-3...4)（参见[值的含义](Script-CoreParameters.md#log_level)）
* *pid* (可选) - Unix pid（由 OpenSIPS 验证）

使用示例:
```bash

    # opensips-mi log_level
    {
        "Processes": [
            {
                "PID": 10670,
                "Log level": 2,
                "Type": "attendant"
            },
            {
                "PID": 10672,
                "Log level": 3,
                "Type": "MI FIFO"
            },
            {
                "PID": 10673,
                "Log level": 1,
                "Type": "SIP receiver udp:194.168.4.133:5060"
            },
        ]
    }
    # opensipsctl fifo log_level 1
    {
        "New global log level": 1
    }
    # opensipsctl fifo log_level 4 10670
    {
        "Log level": 1
    }

```

### log_level_filter
获取或设置应用于特定日志"消费者"(*stderror*、*syslog* 或 *event*)的日志消息的额外过滤级别。如果未给出 **log_level_filter**，该命令将打印指定消费者的当前级别过滤器。

**参数**:
* *consumer* (可选) - 日志消费者: *stderror*、*syslog* 或 *event*;
* *log_level_filter* (可选) - 日志级别过滤器。

使用示例:
```text

    # opensips-mi log_level_filter stderror
    {
        "Log level filter": 3
    }
    # opensips-mi log_level_filter stderror 1
    "OK"

```

### log_mute_state
获取或设置特定日志"消费者"(*stderror*、*syslog* 或 *event*)的静音状态（打印启用/禁用）。如果未给出 **mute_state**，该命令将打印指定消费者的当前静音状态。

**参数**:
* *consumer* (可选) - 日志消费者: *stderror*、*syslog* 或 *event*;
* *mute_state* (可选) - 新的静音状态: *1* - 静音或 *0* - 取消静音（启用）

使用示例:
```text

    # opensips-mi log_mute_state syslog
    {
        "mmute state": 0
    }
    # opensips-mi log_mute_state syslog 1
    "OK"

```

### profiling_proc
全局或按进程获取或设置性能分析级别。如果未给出 **level**，该函数将列出指定进程的当前性能分析级别。如果给出了 **level**，则提供递增的详细级别 - 从最低到最高级别依次为: **0** 关闭，**1** SIP 级别（I/O  reactor、SIP stack -TM、dialog、b2b-、scripting），**2** 额外进程（MI、RTPproxy、HTTPD 等）和 **3** TIMER/FULL（定时器作业执行）。
受影响的进程可通过 **ID**（内部 ID）或 **PID** 控制。如果未给出任何一项，所有进程都将受到 set/get 操作的影响。
另请参阅用于报告性能分析数据的 [E_PROFILING_PROC 事件](Interface-CoreEvents.md#E_PROFILING_PROC)。

**参数**:
* *ID* 或 *PID* (可选) - 要处理的进程;
* *level* (可选) - 新的详细级别（如果要设置）
使用示例:
```text

    # opensips-mi mi core:profiling_proc id=8
    {
        "Processes": [
            {
                "ID": 8,
                "PID": 3568378,
                "Profiling level": 0,
                "Type": "SIP receiver udp:127.10.0.1:5060"
            }
         ]
    }
    # opensips-mi core:profiling_proc id=8 level=2
    "OK"

```

### ps
该命令将列出所有 **OpenSIPS** 进程及其类型和描述。

**参数**: 无

**输出**: 多个对象，每个对象包含进程 ID（内部）、PID（操作系统）和类型。

使用示例:
```text

    # opensips-mi ps
{
    "Processes": [
        {
            "ID": 0,
            "PID": 27271,
            "Type": "attendant"
        },
        {
            "ID": 1,
            "PID": 27272,
            "Type": "MI FIFO"
        },
        {
            "ID": 2,
            "PID": 27273,
            "Type": "time_keeper"
        },
        {
            "ID": 3,
            "PID": 27274,
            "Type": "timer"
        },
        {
            "ID": 4,
            "PID": 27275,
            "Type": "SIP receiver udp:127.0.0.1:5060"
        },
        {
            "ID": 5,
            "PID": 27276,
            "Type": "Timer handler"
        }
    ]
}

```

### pwd
打印 **OpenSIPS** 实例的工作目录。

**参数**: 无

**输出**: 一个包含工作目录完整路径的单个项目。

使用示例:
```text

    # opensips-mi pwd
    {
        "WD": "/"
    }

```

### reload_routes
在运行时触发从脚本重新加载路由块（路由）。
**参数**: 无

**输出**: 无

请注意， reload 是否可能存在一些限制。根据模块的初始配置，reload 可能会被拒绝，因为新脚本中函数的使用与原始模块设置和初始化不兼容。

如果 reload 失败，请查看日志以了解原因 - 可能是语法错误或模块相关的约束。无论如何，如果 reload 失败，不会影响正在运行的 OpenSIPS。

### uptime
打印 **OpenSIPS** 的各种时间信息 - 何时开始运行、运行了多长时间。

**参数**: 无

**输出**: 三个项目: "Now" - 当前时间; "Up since" - 启动时间; "Up time" - 自启动以来的秒数。

使用示例:
```text

    # opensips-mi uptime
{
    "Now": "Mon Jul 21 17:41:03 2008",
    "Up since": "Mon Jul 21 17:36:33 2008",
    "Up time": "270 [sec]"
}

```

### version
打印正在运行的 **OpenSIPS** 的版本字符串。

**参数**: 无

**输出**: 一个名为 "Server" 的项目，包含版本字符串。

使用示例:
```text

    # opensips-mi version
{
    "Server": "OpenSIPS (4.1.0-dev (x86_64/linux))"
}

```

### which
打印来自查询的 **OpenSIPS** 实例的所有可用 MI 命令。

**参数**: 无

**输出**: 可用 MI 命令名称的数组。请注意，可用 MI 命令列表可能因 **OpenSIPS** 使用的模块不同而有所差异。

使用示例:
```text

    # opensips-mi which
[
    "statistics:get",
    "statistics:list",
    "statistics:reset",
    "uptime",
    "version",
    "pwd",
    "arg",
    "which",
    "ps",
    "kill",
    "log_level",
    "xlog_level",
    "mem:shm_check",
    "cache:store",
    "cache:fetch",
    "cache:remove",
    "evi:subscribe",
    "evi:list",
...

```

### xlog_level [level]
获取或设置 OpenSIPS 进程中的全局 xlog 级别。如果不向 **xlog_level** 命令传递参数，它将打印当前的 **xlog_level**。如果给定了日志 **level**，它将被全局设置到所有 OpenSIPS 进程。

**参数**:
* *level* (可选)

使用示例:
```text

    # opensips-mi xlog_level -2

```

## 黑名单

### blacklists:list
该命令列出 **OpenSIPS** 中所有已定义（静态或学习的）的黑名单。

**参数**:
* *name* (可选) - 仅过滤并打印特定黑名单中的规则
**输出**: 一个数组，每个对象描述一个列表（名称、所有者、标志）; "Rules" 项目是一个数组，每个对象成员描述每个列表的规则（IP/mask、protocol、port、matching regexp、flags）。

使用示例:
```text

    # opensips-mi blacklists:list

```

### blacklists:check_all
该命令返回与 proto:IP:port+pattern 匹配的所有黑名单。

**参数**:
* *proto* (可选) - 检查规则的协议 - 如果缺失，使用"any"协议。注意，"any"协议检查只能匹配"any"协议规则。
* *ip* - 用于匹配规则的必需 IP
* *port* (可选) - 检查规则的端口 - 如果缺失，使用 0/any 端口。注意，0 端口只能匹配 0 端口规则。
* *pattern* (可选) - 要检查规则的可选模式
**输出**: 每个匹配的黑名单名称数组。

使用示例:
```text

    # opensips-mi blacklists:check_all 127.0.0.1
    # opensips-mi blacklists:check_all udp 127.0.0.1 5060

```

### blacklists:check
该命令检查 proto:IP:port+pattern 是否匹配黑名单的任何规则。

**参数**:
* *name* = 要检查的黑名单名称
* *proto* (可选) - 检查规则的协议 - 如果缺失，使用"any"协议。注意，"any"协议检查只能匹配"any"协议规则。
* *ip* - 用于匹配规则的必需 IP
* *port* (可选) - 检查规则的端口 - 如果缺失，使用 0/any 端口。注意，0 端口只能匹配 0 端口规则。
* *pattern* (可选) - 要检查规则的可选模式
**输出**: 包含第一个匹配规则的对象，如果没有匹配则返回错误。

使用示例:
```text

    # opensips-mi blacklists:check net_dynamic 127.0.0.1
    # opensips-mi blacklists:check_all net_dynamic udp 127.0.0.1 5060

```

### blacklists:add_rule
向非只读黑名单添加规则。

**参数**:
* *name* - 要添加到的黑名单名称
* *rule* - 包含黑名单规则的字符串，根据 [**dst_blacklist**](https://docs.opensips.org/manual/devel/script-coreparameters#dst_blacklist) 参数
* *expire* (可选) - 规则过期的时间（秒）
**输出**: 成功或失败对象。

使用示例:
```text

    # opensips-mi blacklists:add_rule net_dynamic '!tcp,127.0.0.1,5060'
    # opensips-mi blacklists:add_rule net_dynamic '!tcp,127.0.0.1,5060' 3600

```

### blacklists:del_rule
从非只读黑名单中删除规则。

**参数**:
* *name* - 要删除的黑名单名称
* *rule* - 包含黑名单规则的字符串，根据 [**dst_blacklist**](https://docs.opensips.org/manual/devel/script-coreparameters#dst_blacklist) 参数
**输出**: 成功或失败对象。

使用示例:
```text

    # opensips-mi blacklists:del_rule net_dynamic '!tcp,127.0.0.1,5060'

```

## TCP 连接

### tcp:list
该命令列出 **OpenSIPS** 中所有正在进行的 TCP/TLS 连接。

**参数**:

* *proto* (可选) - 列出该特定协议的 TCP 连接
**输出**: 一个数组，每个连接有一个对象，包含以下属性: ID、type、state、source、destination、lifetime、alias port。对于 TLS 连接，还会转储密码信息。

使用示例:
```text

    # opensips-mi tcp:list

```

### tcp:close
终止 **OpenSIPS** 中正在进行的 TCP/TLS 连接的命令。

**参数**:

* *ipport* - 连接的 **ip:port** 坐标

使用示例:
```text

    # opensips-mi tcp:close 127.0.0.1:9

```
您也可以通过 id 终止:
```text

    # opensips-mi tcp:close 31646848

```
## 状态报告

### status_report:get
[ sr_check_status() 脚本函数](https://docs.opensips.org/manual/devel/script-corefunctions#sr_check_status) 的 MI 等效命令 - 获取'status/report' 标识符/组的状态。

**参数**: 必需的 *group* 和可选的 *identifier*，请参阅 [sr_check_status() 脚本函数](https://docs.opensips.org/manual/devel/script-corefunctions#sr_check_status) 的参数。
**输出**: 标识符/组的就绪状态、状态和详细信息（请参阅 [sr_check_status() 脚本函数](https://docs.opensips.org/manual/devel/script-corefunctions#sr_check_status) 返回码的聚合说明）。

使用示例:
```bash

# opensips-mi status_report:get core
{
    "Readiness": true,
    "Status": 1,
    "Details": "running"
}

# opensips-mi status_report:get drouting all
{
    "Readiness": true,
    "Status": 1,
    "Details": "aggregated"
}

```

### status_report:status
列出单个或所有'status/report' 组内标识符状态的命令。

**参数**: 可选的'status/report' *group*，请参阅 [sr_check_status() 脚本函数](https://docs.opensips.org/manual/devel/script-corefunctions#sr_check_status) 了解更多详情。
**输出**: 请求组内或所有已定义/注册组内所有标识符的就绪状态、状态和详细信息。

使用示例:
```text

#opensips-mi status_report:status 
[
    {
        "Name": "drouting",
        "Identifiers": [
            {
                "Name": "Default",
                "Readiness": true,
                "Status": 1,
                "Details": "data available"
            }
        ]
    },
    {
        "Name": "test",
        "Identifiers": [
            {
                "Name": "main",
                "Readiness": true,
                "Status": 1
            }
        ]
    },
    {
        "Name": "core",
        "Identifiers": [
            {
                "Name": "main",
                "Readiness": true,
                "Status": 1,
                "Details": "running"
            }
        ]
    }
]

```

### status_report:reports
列出由'status/report' 标识符收集的完整报告（日志）集的命令。

**参数**:
* 可选的'status/report' *group*，请参阅 [sr_check_status() 脚本函数](https://docs.opensips.org/manual/devel/script-corefunctions#sr_check_status) 了解更多详情。如果缺失，将列出所有组。
* 可选的'identifier'。如果缺失，将列出组内的所有标识符。
**输出**: 请求标识符的报告/日志，或组内所有标识符的报告/日志。

使用示例:
```text

#opensips-mi status_report:reports 
[
    {
        "Name": "drouting",
        "Identifiers": [
            {
                "Name": "Default",
                "Reports": [
                    {
                        "Timestamp": 1644396830,
                        "Date": "Wed Feb  9 10:53:50 2022",
                        "Log": "starting DB data loading"
                    },
                    {
                        "Timestamp": 1644396830,
                        "Date": "Wed Feb  9 10:53:50 2022",
                        "Log": "DB data loading successfully completed"
                    },
                    {
                        "Timestamp": 1644396830,
                        "Date": "Wed Feb  9 10:53:50 2022",
                        "Log": "2 gateways loaded (0 discarded), 2 carriers loaded (0 discarded), 1 rules loaded (0 discarded)"
                    }
                ]
            }
        ]
    },
    {
        "Name": "test",
        "Identifiers": [
            {
                "Name": "main",
                "Reports": []
            }
        ]
    },
    {
        "Name": "core",
        "Identifiers": [
            {
                "Name": "main",
                "Reports": [
                    {
                        "Timestamp": 1644396830,
                        "Date": "Wed Feb  9 10:53:50 2022",
                        "Log": "initializing"
                    },
                    {
                        "Timestamp": 1644396830,
                        "Date": "Wed Feb  9 10:53:50 2022",
                        "Log": "initialization completed, ready now"
                    }
                ]
            }
        ]
    }
]

```

### status_report:identifiers
列出 OpenSIPS 中所有现有标识符或仅来自特定组的标识符的命令。

**参数**:
* 可选的'status/report' *group*，请参阅 [sr_check_status() 脚本函数](https://docs.opensips.org/manual/3-3/script-corefunctions#sr_check_status) 了解更多详情。如果缺失，将列出所有组的标识符。
**输出**: 组数组，每个组是标识符数组。

使用示例:
```text

#opensips-mi status_report:identifiers
[
    {
        "Group": "clusterer",
        "Identifiers": [
            "sharing_tags"
        ]
    },
    {
        "Group": "dispatcher",
        "Identifiers": [
            "default;events",
            "default"
        ]
    },
    {
        "Group": "drouting",
        "Identifiers": [
            "Default;events",
            "Default"
        ]
    },
    {
        "Group": "dialplan",
        "Identifiers": [
            "default"
        ]
    },
    {
        "Group": "core",
        "Identifiers": [
            "main"
        ]
    }
]
#opensips-mi status_report:identifiers drouting
{
    "Group": "drouting",
    "Identifiers": [
        "Default;events",
        "Default"
    ]
}

```

## 统计

### statistics:get
打印统计（全部、组或单个）的实时值。

**参数**:
* *statistics* - 包含以下可能值的数组:
  * "all" - 打印所有可用统计;
  * "group_name:" - 仅打印名为 "group_name" 的组的统计; **OpenSIPS** 核心定义以下组: *core*、*shmem*; 模块导出的组通常以模块本身命名。
  * "name" - 仅打印名为 "name" 的统计。
**输出**: 包含统计变量名称和值的对象。

使用示例:
```text

    # opensips-mi statistics:get rcv_requests
   {
       "core:rcv_requests": 35243
   }
    # opensipsc-cli -x mi statistics:get shmem:      
    {
        "shmem:total_size": 1073741824,
        "shmem:max_used_size": 3389232,
        "shmem:free_size": 1070352592,
        "shmem:used_size": 2808952,
        "shmem:real_used_size": 3389232,
        "shmem:fragments": 3769
    }
    # opensips-mi statistics:get shmem: core:
    ....

```

### statistics:list
打印当前 OpenSIPS 配置中可用统计的列表。
**参数**:
* *statistics* (可选) - 与 **statistics:get** MI 命令相同的可能值数组，但 "all" 除外。省略该参数将列出所有可用统计。

使用示例:
```text

    # opensips-mi statistics:list
{
    "shmem:total_size": "non-incremental",
    "shmem:max_used_size": "non-incremental",
    "shmem:free_size": "non-incremental",
    "shmem:used_size": "non-incremental",
    "shmem:real_used_size": "non-incremental",
    "shmem:fragments": "non-incremental",
    "rpmem:rpm_total_size": "non-incremental",
    "rpmem:rpm_used_size": "non-incremental",
...

```

### statistics:reset
将统计变量的值重置（为零）。请注意，并非所有变量都允许重置（取决于它们携带的信息性质 - 例如 "shmem:used_size"）。

**参数**: 
* *statistics* - 要重置的变量名称数组。
**输出**: 无。

使用示例:
```text

    # opensips-mi statistics:get received_replies
   {
       "tm:received_replies": 14543
   }
    # opensips-mi statistics:reset received_replies
    # opensips-mi statistics:get received_replies
   {
       "tm:received_replies": 0
   }

```

### statistics:reset_all
将所有可重置的统计变量的值重置（为零）。请注意，并非所有变量都允许重置（取决于它们携带的信息性质 - 例如 "shmem:used_size"）。

**输出**: 无。

使用示例:
```text

    # opensips-mi statistics:reset_all

```

## CacheDB 接口

### cache:store
该命令在缓存系统中存储字符串值。

**参数**:
* *system* - 要使用的缓存系统 - 对于 **OpenSIPS** 模块 'localcache' 实现的缓存系统，此参数的值应为 'local';
* *attr* - 要与此值关联的标签;
* *value* - 要存储的字符串;
* *expire* (可选) - 存储值的过期时间;
**输出**: 无。

使用示例:
```text

    # opensips-mi cache:store local password_user1 password

```

### cache:fetch
该命令查询存储的值。

**参数**:
* *system* - 要使用的缓存系统 - 对于 **OpenSIPS** 模块 'localcache' 实现的缓存系统，此参数的值应为 'local'
* *attr* - 与值关联的标签
**输出**: 如果找到记录则包含值的对象，否则为 'Value not found' 字符串。

使用示例:
```text

    # opensips-mi cache:fetch local password_user1

```

### cache:remove
该命令从缓存系统中删除记录。

**参数**:
* *system* - 要使用的缓存系统;
* *attr* - 与存储值关联的标签;
**输出**: 无。

使用示例:
```text

    # opensips-mi cache:remove local password_user1

```

## 事件接口

### evi:subscribe
将外部应用程序订阅到某个事件。

**参数**:
* *event* - 事件名称
* *socket* - 外部应用程序 socket
* *expire* (可选) - 过期时间，以秒为单位 - 如果不存在，订阅仅在一小时内有效（3600 秒）
**输出**: 无。

使用示例:
```text

    # opensips-mi evi:subscribe E_PIKE_BLOCKED udp:127.0.0.1:8888 1200

```

### evi:list
列出通过事件接口发布的所有事件。

**参数**: 无。

**输出**: 无。

使用示例:
```text

    # opensips-mi evi:list
{
    "Events": [
        {
            "name": "E_CORE_THRESHOLD",
            "id": 0
        },
        {
            "name": "E_CORE_SHM_THRESHOLD",
            "id": 1
        },
        {
            "name": "E_CORE_PKG_THRESHOLD",
            "id": 2
        },
...

```

### evi:raise
使用 MI 命令通过事件接口引发事件。

**参数**:
* *event* - 事件名称
* *params* (可选) - 元素数组，或包含键值对的 JSON 对象字符串
**输出**: 无。

使用示例:
```bash

    # opensips-mi evi:raise E_PIKE_BLOCKED 127.0.0.1 # 数组模式
    # opensips-mi evi:raise -j '{"event":"E_PIKE_BLOCKED", "params": {"ip":"127.0.0.1"}}' # json 模式
    # opensips-cli -x mi -j evi:raise event=E_PIKE_BLOCKED params='{"ip":"127.0.0.1"}' # cli json 模式

```

### evi:subscribers
列出有关订阅者的信息。

**参数**:
* *event* - 事件名称
* *socket* (可选) - 外部应用程序 socket
**输出**: 如果未指定参数，则返回所有事件及其订阅者的信息。如果指定了事件，则仅返回订阅该事件的外部应用程序。如果还指定了 socket，则仅返回一个订阅者信息。

使用示例:
```text

    # opensips-mi evi:subscribers
{
  "Events": [{
	  "name": "E_RTPPROXY_STATUS",
	  "id": 1,
	  "subscribers": [
		...
	  ]
	},
	{
	  "name": "E_PIKE_BLOCKED",
	  "id": 2,
	  "subscribers": [
		...
	  ]
	}
  ]
}

    # opensips-mi evi:subscribers E_RTPPROXY_STATUS
{
  "Event": {
	"name": "E_RTPPROXY_STATUS",
	"id": 1,
	"subscribers": [{
		  "socket": "unix:/tmp/event.sock",
		  "expire": "never",
		},
		{
		  "socket": "udp:127.0.0.1:8888",
		  "expire": 1100,
		  "ttl": 1046
		}
	]
  } 
}

    # opensips-mi evi:subscribers E_RTPPROXY_STATUS unix:/tmp/event.sock
{
  "Event": {
	"name": "E_RTPPROXY_STATUS",
	"id": 1,
	"Subscriber": {
	  "socket": "unix:/tmp/event.sock",
	  "expire": "never"
	}
  } 
}

```

## 内存

### mem:pkg_dump
为给定进程触发 pkg 内存转储。内存转储将使用 'memdump' 日志级别写入 OpenSIPS 的日志（syslog 或 stderr）。全局 'memdump' 日志级别可以被覆盖为作为此命令参数提供的自定义值。

**参数**:
* *pid* - 要执行 pkg 转储的进程的 PID
* *log_level* (可选) - 用于此转储的日志级别
**输出**: 无。

使用示例:
```text

    # opensips-mi mem:pkg_dump 11854 -1

```

> [!IMPORTANT]
> 不支持 IPC 的进程（如 timer 和 per-module 进程）将无法生成内存转储。

### mem:rpm_dump
触发重启持久内存转储。内存转储使用 `memdump` 日志级别写入 OpenSIPS 的日志（syslog 或 stderr）。可选参数可以覆盖全局 `memdump` 级别。

**参数**:
* *log_level* (可选) - 用于此转储的日志级别

使用示例:
```text

    # opensips-mi mem:rpm_dump
    # opensips-mi mem:rpm_dump -1

```

### mem:shm_dump
触发 shm 内存转储。内存转储将使用 'memdump' 日志级别写入 OpenSIPS 的日志（syslog 或 stderr）。全局 'memdump' 日志级别可以被覆盖为作为此命令参数提供的自定义值。

**参数**:
* *log_level* (可选) - 用于此转储的日志级别
**输出**: 无。

使用示例:
```text

    # opensips-mi mem:shm_dump -1

```

### mem:shm_check
仅在 *QM_MALLOC* + *DBG_MALLOC* 下可用。为了定位任何不一致性，完全扫描共享内存池。如果检测到任何内存损坏迹象，OpenSIPS 将立即中止。

**参数**: 无

**输出**: 当前碎片数量。

使用示例:
```text

    # opensips-mi mem:shm_check

```
