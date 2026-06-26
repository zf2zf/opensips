---
title: "核心参数"
description: "本节列出了 OpenSIPS 核心导出的所有脚本参数（用于 opensips.cfg）。"
---

本节列出了 **OpenSIPS** 核心导出的所有脚本参数（用于 opensips.cfg）。

## 核心参数

可以在配置文件中设置的全局参数。接受的值取决于实际参数——字符串、数字和 yes/no。如果您需要将 "yes" 或 "no" 指定为字符串的一部分，请用双引号将其包装。

### abort_on_assert
默认值：false

  

仅在启用 [asserts](https://docs.opensips.org/manual/devel/script-corefunctions#assert) 时相关。设置为 *true* 以使 OpenSIPS 在脚本 assert 失败时立即关闭。

用法示例：
```text

    abort_on_assert = true

```

### advertised_address

它可以是 IP 地址或字符串，代表在 Via 头和其他目标 lumps（例如 RR 头）中通告的地址。如果为空或未设置（默认值），则使用发送请求的套接字地址。

> [!WARNING]
> 除非您知道自己在做什么（例如 NAT 穿越），否则不要设置它。您可以在这里设置任何内容，不做任何检查（例如 foo.bar 会被接受，即使 foo.bar 不存在）。

用法示例：
```text

    advertised_address="opensips.org"

```

> [!NOTE]
> 除了这种全局方法，您还可以按接口方式定义通告 IP 和端口（请参阅 [socket](#socket) 参数）。当按接口定义通告值时，这些值仅用于离开该接口的流量。

### advertised_port

在 Via 头和其他目标 lumps（例如 RR）中通告的端口。如果为空或未设置（默认值），则使用发送消息的端口。与 'advertised_address' 相同的警告。

用法示例：
```text

    advertised_port=5080

```

> [!NOTE]
> 除了这种全局方法，您还可以按接口方式定义通告 IP 和端口（请参阅 [socket](#socket) 参数）。当按接口定义通告值时，这些值仅用于离开该接口的流量。

### alias

用于设置服务器别名主机名的参数。它可以设置多次，每个值都被添加到一个列表中，以便在检查 'myself' 时匹配主机名。

如果省略 ":port" 部分，则给定 "hostname" 的**所有**端口都将被视为别名（类似于端口 0 的行为）。

它可以接受一个可选的 **accept_subdomain** 指示符，以说明是否也应匹配所定义域的任何子域。

> [!IMPORTANT]
> 有必要在别名定义中包含端口（"socket=" 定义中使用的端口值），否则 loose_route() 函数在本地转发时不会按预期工作！


用法示例：

```text

    alias=udp:other.domain.com:5060
    alias=tcp:another.domain.com:5060
    # accept subdomanins like sip.domainX.com
    alias=udp:domainX.com:5060 accept_subdomain

```

### auto_aliases

此参数控制是否在修复监听套接字时自动发现和添加别名。自动发现的别名是 DNS 查找的结果（如果 'socket' 定义有名称而非 IP），或者是套接字 IP 的反向 DNS 查找的结果。

出于向后兼容性，默认值为 "off"/0。

用法示例：
```text

    auto_aliases=yes
    auto_aliases=1

```

### auto_scaling_cycle
定义自动缩放周期的秒数——自动缩放引擎在每个周期评估组的内部负载，并决定需要创建更多进程还是需要终止现有进程。另请参阅 [auto_scaling_profile](#auto_scaling_profile) 以获取更多关于自动缩放工作原理的详细信息。

默认值为 1 秒。
用法示例：
```text

    auto_scaling_cycle=3  # 每 3 秒执行一次自动缩放检查

```

### auto_scaling_profile
定义自动缩放支持的行为，包括应允许多少个进程以及何时终止或创建新进程。这些配置文件可用于 UDP 进程（请参阅 [udp_workers](#udp_workers) 或 [socket](#socket) 选项）、TCP 进程（请参阅 [tcp_workers](#tcp_workers) 选项）或 TIMER 进程（请参阅 [timer_workers](#timer_workers) 选项）。

更多详情，请参阅[自动缩放的外部描述](https://blog.opensips.org/2019/02/25/auto-process-scaling-a-cure-for-load-and-resources-concerns/)。

用法示例：
```text

    auto_scaling_profile = PROFILE_SIP
     scale up to 6 on 70% for 4 cycles within 5   
     scale down to 2 on 18% for 10 cycles

```
此配置文件将允许组最多分叉 6 个进程。当组整体负载在 5 个周期监测窗口内超过 70% 超过 4 个周期时，将分叉一个新进程。周期是用于监测的时间单位（例如 2 秒）。

此外，配置文件将允许组缩放到最少 2 个进程。当组整体负载在 10 个周期内低于 20% 时，进程将被终止。配置文件的缩放部分是可选的。如果未定义，OpenSIPS 将永远不会缩容，只会上扩。

### check_via

检查回复中最顶层 Via 的地址是否为本地。默认值为 0（检查禁用）。

用法示例：

```text
check_via=1 
```

### chroot

值必须是系统中的有效路径。如果设置，**OpenSIPS** 将 chroot（更改根目录）到其值。

用法示例：

```text
chroot=/other/fakeroot
```

### debug_mode
启用 **debug_mode** 选项是调试 **OpenSIPS** 的快速方法。此选项将自动强制：
* 保持在前台（不与控制台分离）
* 设置日志级别为 4（debug）
* 设置日志输出到标准错误
* 启用 core dumping
* 设置 UDP worker 进程为 2
* 设置 TCP worker 进程为 2

默认值为 false/0（禁用）。

请注意，启用此选项将覆盖所有其他单独参数，如前台模式、日志级别、udp_workers、tcp_workers 等。

### db_version_table

DB API 使用的表版本的名称。

默认值为 **"version"**

用法示例：

```text
db_version_table="version_1_8"
```

### db_default_url

如果模块没有提供每个模块的 URL，则由模块使用的默认 DB URL。默认为 NULL（未定义）

用法示例：

```text
db_default_url="mysql://opensips:opensipsrw@localhost/opensips"
```

### db_max_async_connections

从单个 OpenSIPS worker 打开到每个 SQL 后端的最大 TCP 连接数。默认值为 10。

各个后端从 DB URL 确定，如下所示：
```text
[ scheme, user, pass, host, port, database ]
```

用法示例：

```text

    db_max_async_connections=220

```

### disable_503_translation

如果为 'yes'，OpenSIPS 将不会把收到的 503 回复翻译成 500 回复（RFC 3261 明确说明代理不应转发 503 响应，而是必须将其转换为 500）。

默认值为 'no'（进行翻译）。

### disable_core_dump

可以是 'yes' 或 'no'。默认情况下 core dump 限制设置为无限制或足够高的值。将此配置变量设置为 'yes' 可禁用 core dump（将 core 限制设置为 0）。

默认值为 'no'。

用法示例：

```c
disable_core_dump=yes
```

### disable_dns_blacklist

DNS 解析器在配置了故障转移时，可以自动将失败的目标存储在临时黑名单中。这将防止（在有限的时间内）**OpenSIPS** 向已知失败的目标发送请求。因此，黑名单可用作 DNS 解析器的内存。

DNS 解析器创建的临时黑名单名为 "dns"，默认情况下被选中使用（无需使用 use_blacklist() 函数）。此列表中的规则生命周期为 4 分钟——您可以在编译时从 resolve.c 中更改。

可以是 'yes' 或 'no'。默认情况下黑名单是禁用的（默认值为 'yes'）。

用法示例：

```text
disable_dns_blacklist=no
```

### disable_dns_failover

可以是 'yes' 或 'no'。默认情况下基于 DNS 的故障转移是启用的。将此配置变量设置为 'yes' 可禁用基于 DNS 的故障转移。这是一个全局选项，影响核心和模块。

默认值为 'no'。

用法示例：

```text
disable_dns_failover=yes
```

### disable_stateless_fwd

可以是 'yes' 或 'no'。此参数控制无状态回复的处理：
```text

    yes - 如果脚本中未使用无状态转发函数（如 forward），则丢弃无状态回复
    no - 转发无状态回复

```
默认值为 'yes'。

### dns

此参数控制 SIP 服务器是否应在 DNS 中查找其自己的域名。如果此参数设置为 yes 且域名不在 DNS 中，则会在 syslog 中打印警告，并在 via 头中添加 "received=" 字段。

默认为 no。

### dns_retr_time

重试 DNS 请求前的秒数。默认值是系统特定的，也取决于 '/etc/resolv.conf' 的内容（通常为 5 秒）。

用法示例：

```text
dns_retr_time=3
```

### dns_retr_no

放弃前的 DNS 重传次数。默认值是系统特定的，也取决于 '/etc/resolv.conf' 的内容（通常为 4）。

用法示例：

```text
dns_retr_no=3
```

### dns_servers_no

将从 '/etc/resolv.conf' 中定义的那些 DNS 服务器中使用多少个。默认值是使用所有服务器。

用法示例：

```text
dns_servers_no=2
```

### dns_try_ipv6

可以是 'yes' 或 'no'。如果设置为 'yes' 且 DNS 查找失败，它将重试 ipv6（AAAA 记录）。默认值为 'no'。

用法示例：

```text
dns_try_ipv6=yes
```

### dns_try_naptr

在基于 DNS 的 SIP 请求路由中禁用 NAPTR 查找——如果禁用，DNS 查找将从 SRV 查找开始。
可以是 'yes' 或 'no'。默认情况下它是启用的，值为 'yes'。

用法示例：

```text
dns_try_naptr=no
```

### dns_use_search_list

可以是 'yes' 或 'no'。如果设置为 'no'，则忽略 '/etc/resolv.conf' 中的搜索列表（=> 更少的查找 => 更快放弃）。默认值为 'yes'。

提示：即使您没有定义搜索列表，将此选项设置为 'no' 仍然会"更快"，因为空搜索列表实际上是搜索 ""（因此即使搜索列表为空/缺失，仍然会有 2 个 DNS 查询，例如 foo+'.' 和 foo+""+'.'）

用法示例：

```text
dns_use_search_list=no
```

### dst_blacklist

IP/目标黑名单的定义。这些列表可以在脚本中（在运行时）选择，以根据 IP、协议、端口等过滤传出请求。

其主要目的是防止向关键 IP（如 GW）发送请求（由于错误的 DNS 条目），或避免向已知不可用（临时或永久）的目标发送请求。

指定列表的语法如下：

```text

  "dst_blacklist" = id [/bl_flags] [: bl_rules] 

```

* **id** 是黑名单的唯一标识符
* **bl_flags** 包含一组可选修饰符：
```text

  bl_flags = bl_flag [, bl_flag]*
  bl_flag = "expire" | "default" | "readonly"

```

* **bl_rules** 包含一个或多个黑名单规则
```text

  bl_rules = [!] ipnet | { bl_rule [, bl_rule]* }
  bl_rule = [!] ( [bl_proto, ] ipnet [, port [, bl_pattern]] )

```

黑名单修饰符的含义如下：
* "expire"：黑名单可能包含过期的条目
* "default"：黑名单在发送请求时默认使用，无需显式设置（使用 **use_blacklist** 函数）
* "readonly"：黑名单在脚本中静态定义，运行时无法更改

当 **dst_flags** 缺失时，会显式设置 "readonly" 标志。

规则由以下属性定义：
* 如果 "!" 在规则开头，则否定整个规则
* bl_proto：任何支持的协议，或 "any" 表示任何协议；如果缺失，默认为 "any"
* ipnet：应匹配规则的 IP 或 IP/MASK
* port：数字或 0 表示任意
* bl_pattern - 是类似于文件名的匹配（请参阅 "man 3 fnmatch"），应用于传出请求缓冲区（first_line+hdrs+body）

用法示例：

```text

   # filter out requests going to ips of my gws
   dst_blacklist = gw:{( tcp , 192.168.4.100 , 5060 , "" ),( any , 192.168.4.101 , 0 , "" )}
   # block requests going to "evil" networks
   dst_blacklist = net_filter:{ ( any , 192.168.1.120/255.255.255.0 , 0 , "" )}
   # block message requests with nasty words
   dst_blacklist = msg_filter:{ ( any , 192.168.20.0/255.255.255.0 , 0 , "MESSAGE*ugly_word" )}
   # block requests not going to a specific subnet
   dst_blacklist = net_filter2:{ !( any , 194.168.30.0/255.255.255.0 , 0 , "" )}
   # define a dynamic list that is built at runtime and has expire entries
   dst_blacklist = net_dynamic/expire

```

### enable_asserts
默认值：false

  

设置为 *true* 以启用 [assert](https://docs.opensips.org/manual/devel/script-corefunctions#assert) 脚本语句。

用法示例：
```text

    enable_asserts = true

```

### event_pkg_threshold

一个数字，表示触发 E_CORE_PKG_THRESHOLD 事件的百分比阈值，用于警告可用专用内存不足。它接受 0 到 100 之间的整数值。

默认值为 0（事件禁用）。

用法示例：

```text
event_pkg_threshold = 90
```

### event_shm_threshold

一个数字，表示触发 E_CORE_SHM_THRESHOLD 事件的百分比阈值，用于警告可用共享内存不足。它接受 0 到 100 之间的整数值。

默认值为 0（事件禁用）。

用法示例：

```text
event_shm_threshold = 90
```

### exec_dns_threshold

一个数字，表示 DNS 查询预期持续的最大微秒数。超过设定数量的任何内容都将触发日志设施的警告消息。

默认值为 0（日志记录禁用）。

用法示例：

```text
exec_dns_threshold = 60000
```

### exec_msg_threshold

一个数字，表示处理 SIP 消息预期持续的最大微秒数。超过设定数量的任何内容都将触发日志设施的警告消息。
除了消息和处理时间，脚本中耗时最多的函数调用也会被记录。

默认值为 0（日志记录禁用）。

用法示例：

```text
exec_msg_threshold = 60000
```

### include_file

可以从路由块外部调用以加载额外的路由/块，或从内部调用以简单地执行更多功能。文件路径可以是相对路径或绝对路径。如果是相对路径，首先尝试相对于启动 OpenSIPS 的目录来定位它。如果失败，第二次尝试相对于包含它的文件目录。如果找不到文件将抛出错误。

用法示例：

```text

    include_file "proxy_regs.cfg"

```

### import_file

与 include_file 相同。

用法示例：

```text

    import_file "proxy_regs.cfg"

```

[#log_event_enabled]]
### log_event_enabled

为 opensips 生成的每条日志消息启用触发 E_CORE_LOG 事件。默认情况下这是禁用的。

用法示例：

```text

    log_event_enabled = yes

```

### log_event_level_filter

E_CORE_LOG 事件的额外日志级别过滤。当需要在 syslog/标准错误日志和通过 E_CORE_LOG 事件传递的日志之间获得不同的详细程度时，此参数可能很有用。

*log_event_level_filter* 应与 [log_level](Script-CoreParameters.md#log_level) 参数一致使用，即级别低于 *log_level*。

默认值为 *0*（不过滤）。

用法示例：

```text

    log_event_level_filter = 3

```

### log_json_buf_size

默认值：6144

打印与日志消息对应的 JSON 文档所用缓冲区的大小。当使用 *json* 或 *json_cee* 日志格式时，此参数才有用。如果缓冲区太小，日志消息将被截断。

用法示例：
```text

    log_json_buf_size = 8192 # given in bytes

```

### log_level

设置日志级别（OpenSIPS 应有多详细）。更高的值使 **OpenSIPS** 打印更多消息。

用法示例：

```text

    log_level=1 -- 只打印重要消息（如错误或更关键的情况） 
    - 推荐作为守护进程运行

    log_level=4 -- 打印大量调试消息 - 仅在调试会话时使用

```

实际值为：
* -3 - Alert 级别
* -2 - Critical 级别
* -1 - Error 级别
* 1 - Warning 级别
* 2（默认）- Notice 级别
* 3 - Info 级别
* 4 - Debug 级别

*log_level* 参数的值也可以使用 [log_level](Interface-CoreMI.md#log_level) Core MI 函数或 [`$log_level`](Script-CoreVar.md#log_level) 脚本变量动态获取和设置。

### log_msg_buf_size

默认值：4096

用于打印日志消息 payload 的缓冲区大小。这用于在使用 *json* 或 *json_cee* 日志格式或触发 *E_CORE_LOG* 事件时打印 JSON 文档中的 "message" 字段。如果缓冲区太小，日志消息将被截断。

用法示例：
```text

    log_msg_buf_size = 8192 # given in bytes

```

### log_stdout

尽管所有 OpenSIPS 日志都通过标准错误完成，但启用此参数在尝试从第三方库提取日志时仍然有用。

- "no"（默认）- 丢弃所有标准输出日志

- "yes" - 让所有标准输出日志通过

用法示例：

```text

    log_stdout = yes

```

### log_prefix

将添加到 OpenSIPS 生成的所有日志（来自 C 代码和脚本 xlog() 语句）的字符串前缀。默认值：*""*

用法示例：

```text

    log_prefix = "opensips-backup"

```

### max_while_loops

设置 "while" 中可执行的最大循环次数。作为保护措施以避免配置文件执行中的无限循环。默认值为 100。

用法示例：

```text
max_while_loops=200
```

### maxbuffer

在发现接收 UDP 消息最大缓冲区大小的自动探测过程中不超过的字节数。默认值为 262144。

用法示例：

```text
maxbuffer=65536
```

### mem-group

按名称定义模块组以获取单独的内存统计信息。OpenSIPS 将提供每组内存信息——分配的碎片数量、已使用内存量和实际已使用内存量（带内存管理器开销）。如果您想监控某个模块（或一组模块）的内存使用情况，这很有用。

要使此功能正常工作，您必须运行 "make generate-mem-stats" 并在编译时定义变量 SHM_EXTRA_STATS。

用法示例：
```text

    mem-group = "interest": "core" "tm"
    mem-group = "runtime": "dialog" "usrloc" "tm"

```

对于上述示例，生成的统计信息将命名为：shmem_group_interest:fragments、shmem_group_interest:memory_used、shmem_group_interest:real_used。

可以定义多个组，但它们不能有相同的名称。

如果您想为默认组（所有未包含在组中的其他模块）生成统计信息，您必须在编译时定义变量 SHM_SHOW_DEFAULT_GROUP。

### mem_warming

默认值：off

  

仅在启用 HP_MALLOC 编译标志时相关。如果设置为 "on"，每次启动时，OpenSIPS 将尝试恢复之前停止/重启时的内存碎片模式。如果找不到上次运行的 [pattern_file](https://docs.opensips.org/manual/devel/script-coreparameters#sip_warning)，则跳过内存预热，内存分配器就像其他分配器一样从一大块内存开始。

  

内存预热在处理高流量时很有用（多核机器上每秒数千次 cps——核心越多，越有用），因为进程在切分初始大内存块时必须相互排斥。通过在启动时执行碎片化，OpenSIPS 也将在重启后的第一分钟表现出最佳性能。碎片化通常持续几秒钟（例如在 8GB shm 池和 4.1Ghz CPU 上约 5 秒）——在此期间流量根本不会被处理。

用法示例：
```text

    mem_warming = on

```

### mem_warming_percentage

默认值：75

  

重启时应使用上次运行的模式对 OpenSIPS 内存进行碎片化的比例。如果启用了 [mem_warming](https://docs.opensips.org/manual/devel/script-coreparameters#shm_memlog_size)，则在启动时使用。

用法示例：
```text

    mem_warming_percentage = 50

```

### mem_warming_pattern_file

默认值："CFG_DIR/mem_warming_pattern"

  

仅在 [mem_warming](https://docs.opensips.org/manual/devel/script-coreparameters#shm_memlog_size) 启用时相关。它包含上次 OpenSIPS 运行的内存碎片模式。此文件在每次 OpenSIPS 关闭时覆盖，并在启动时使用，以便尽快恢复服务行为。

用法示例：
```text

    mem_warming_pattern_file = "/var/tmp/my_memory_pattern"

```

### memdump | mem_dump

打印内存状态信息的日志级别（运行时和关闭）。它必须小于 'log_level' 参数的值（如果您希望记录内存信息）。默认：memdump=L_DBG (4)

用法示例：

```text
memdump=2
```

请注意，设置 memlog（见下文）也会自动设置 memdump 参数——如果您希望 memlog 和 memdump 有不同的值，您需要先设置 memlog，然后再设置 memdump。

### memlog | mem_log

打印内存调试信息的日志级别。它必须小于 'log_level' 参数的值（如果您希望记录内存信息）。默认：memlog=L_DBG (4)

用法示例：

```text
memlog=2
```

> [!NOTE]
> 通过设置 memlog 参数，memdump 将自动设置为相同的值（请参阅 memdump 文档）。

### mcast_loopback

可以是 'yes' 或 'no'。如果设置为 'yes'，多播数据报通过环回发送。默认值为 'no'。

用法示例：

```text
mcast_loopback=yes
```

### mcast_ttl

设置多播 ttl 的值。默认值是特定于操作系统的（通常为 1）。

用法示例：

```text
mcast_ttl=32
```

### mhomed

设置服务器在多宿主主机上尝试定位出站接口。默认情况下不启用（0）——因为这相当耗时。

用法示例：

```text
mhomed=1
```

### mpath

设置模块搜索路径。这可用于简化 loadmodule 参数

用法示例：

```c

    mpath="/usr/local/lib/opensips/modules"
    loadmodule "mysql.so"
    loadmodule "uri.so"
    loadmodule "uri_db.so"
    loadmodule "sl.so"
    loadmodule "tm.so"
    ...

```

此参数可以设置多次，评估按声明顺序进行。

### open_files_limit

如果设置且大于当前打开文件限制，**OpenSIPS** 将尝试将其打开文件限制增加到此数字。注意：**OpenSIPS** 必须以 root 身份启动才能将限制增加到超过硬限制（对于打开的文件，大多数系统上为 1024）。

用法示例：

```text
open_files_limit=2048
```

### poll_method

I/O 内部反应器使用的 poll 方法——默认选择当前操作系统的最佳方法。可用类型有：poll、epoll、sigio_rt、select、kqueue、/dev/poll。

用法示例：

```text
poll_method=select
```

### port

SIP 服务器监听的端口。其默认值为 5060。

用法示例：

```text
port=5080
```

### pv_print_buf_size

包含变量和/或伪变量的扩展格式化字符串的最大大小。默认值：20,000 字节。

用法示例：

```text
pv_print_buf_size = 60000
```

### query_buffer_size

如果设置为大于 1 的值，插入 DB 不会逐个刷新。等待插入的行将保存在内存中，直到积累到 query_buffer_size 行，然后才会刷新到数据库。

用法示例：

```text
query_buffer_size=5
```

### query_flush_time

如果 query_buffer_size 设置为大于 1 的值，定时器将每隔 query_flush_time 秒触发一次，确保没有行在内存中保存太久。

用法示例：

```text
query_flush_time=10
```

### restart_persistency_cache_file

此参数控制用于存储重启持久性内存的缓存文件的名称。

默认值为 ".restart_persistency.cache"。

### restart_persistency_size

此参数控制缓存文件的大小。如果未指定此参数，默认为共享内存的大小。

默认值为共享内存的值，即 32MB。

### rev_dns

此参数控制 SIP 服务器是否应在 DNS 中查找其自己的 IP 地址。如果此参数设置为 yes 且 IP 地址不在 DNS 中，则会在 syslog 中打印警告，并在 via 头中添加 "received=" 字段。

默认为 no。

### server_header

**OpenSIPS** 作为 UAS 发送请求时生成的 Server 头字段的正文。它默认为 "OpenSIPS (`<version>` (`<arch>`/`<os>`))"。

用法示例：

```text

server_header="Server: My Company SIP Proxy"

```

请注意，您必须添加头名称 "Server:"，否则 **OpenSIPS** 只写一个类似这样的头：

```text

My Company SIP Proxy

```

### server_signature

此参数控制任何本地生成消息中的 "Server" 头。

用法示例：

```text
server_signature=no
```

如果启用（默认=yes），则按以下示例生成头：

```text
Server: OpenSIPS (0.9.5 (i386/linux))
```

### shm_hash_split_percentage

仅在启用 HP_MALLOC 编译标志时相关。它控制将优化多少个内存桶。（例如，设置它为 2% 将优化前 81 个最常用的桶作为频率）。默认值为 1。

### shm_memlog_size

配置在内存历史中保留的最大 shm 操作数。将分配一个专用的内存块用于此 shm 调试信息。因此，OpenSIPS 实际上将占用比配置的 shm 池（*-m* 命令行选项）更多的系统内存。例如，对于 shm_memlog_size=1000000，大约会额外使用 750 MB。此选项用于调试目的，默认情况下是禁用的，即 shm_memlog_size=0。

### shm_secondary_hash_size

仅在启用 HP_MALLOC 编译标志时相关。它代表单个桶的优化因子（例如，设置它为 4 将导致优化的桶进一步拆分为 4）。默认值为 8。

### sip_warning

可以是 0 或 1。如果设置为 1（默认值为 0），则在 **OpenSIPS** 生成的每个回复中添加 'Warning' 头。
该头包含多个有助于使用网络流量捕获进行故障排除的详细信息。

用法示例：

```text
sip_warning=0
```

### socket

设置 OpenSIPS 服务器应监听的网络地址/套接字。其语法为 `protocol:address[:port|portrange]`，其中：
* protocol：应为加载到配置文件中的传输模块之一（例如 udp、tcp、tls、bin、hep）
* address：可以是 IP 地址、主机名、网络接口 id，或 ***** 通配符，使 OpenSIPS 监听该协议的所有可能接口
* port：可选的，监听套接字使用的端口——如果缺失，则使用传输模块导出的默认端口。
此参数可以在同一配置文件中设置多次，服务器监听所有指定套接字。
* portrange：可选的，一组端口，应在同一 IP 地址上监听。

*socket* 定义可以接受几个可选参数：
* "AS ip:port" - 仅为一个接口配置通告的 IP 和端口。示例 "AS 11.24.14.14:5060"
* "USE_WORKERS n" - 为此套接字设置不同数量的 worker（仅适用于 UDP、SCTP 和 HEP_UDP 接口）。这将覆盖全局 "udp_worker" 参数。示例 "use_workers 5"
* "ANYCAST" - 将套接字标记为 anycast IP
* "USE_AUTO_SCALING_PROFILE" - 强制执行某种策略来控制运行时拥有多少 UDP worker。动态地，根据负载/流量，UDP 进程可能被创建或终止。此参数仅可用于 UDP 套接字。请注意，按套接字定义的自动缩放配置文件将覆盖此全局 UDP 自动缩放配置文件。
* "TAG" - 在跨 OpenSIPS 集群复制套接字标识时使用的非 SIP 名称/标签，与其他 OpenSIPS 节点一起。通过使用相同的 TAG 值，您可以关联/链接不同 OpenSIPS 节点上具有不同 IP 的监听套接字。这在具有不同 IP 的 OpenSIPS 实例之间复制 dialog 时很有用。
* "FRAG" - 表示套接字不应使用 PMTU（Path MTU）发现来确定是否应进行分片，而是一直允许分片（即不在 UDP 数据包中强制设置 DF 位为 1）。
* "REUSE_PORT" - 仅适用于基于 TCP 的套接字；它允许传出 TCP 连接重用监听套接字的端口作为源端口（而不是获取一个临时端口）。
* "TOS" - 可选的 TOS（服务类型）值，用于通过此接口发送 SIP 流量。此值覆盖全局 [TOS](#tos) 核心参数。如果未设置，将使用全局值。
* "ACCEPT_SUBDOMAIN" - 可选指示符，说明子域是否也应匹配此 SIP 域（如果套接字在此处定义为 FQDN）
* "ALLOW_PROXY_PROTOCOL" - 表示套接字允许接收 Proxy Protocol 信息。
* "SEND_PROXY_PROTOCOL" - 套接字将在出站 UDP 消息/连接上提供 Proxy Protocol 信息。
* "PROXY_PROTOCOL" - 套接字将同时允许代理协议，并在出站消息上提供信息。

请记住，上述参数仅影响为其配置的套接字；如果未为给定套接字定义，则使用全局值。

用法示例：

```text

    socket = udp:*
    socket = udp:eth1
    socket = tcp:eth1:5062
    socket = tls:localhost:5061
    socket = hep_udp:10.10.10.10:5064
    socket = ws:127.0.0.1:5060 use_workers 5
    socket = sctp:127.0.0.1:5060 as 99.88.44.33:5060 use_workers 3
    socket = udp:10.10.10.10:5060 anycast
    socket = udp:10.10.10.10:5060 use_workers 4 use_auto_scaling_profile PROFILE_SIP
    

```

启动时，OpenSIPS 会报告它正在监听的所有套接字。

### socket bond

这是 OpenSIPS [sockets](#socket) 的特殊情况。bond 套接字实际上是常规套接字的集合。当使用（用于出站路由）时，bond 套接字会自动评估，并选择一个匹配的（协议和 AF）常规套接字进行发送。更多详情，请参阅此[博客文章](https://blog.opensips.org/2026/03/11/bond-sockets-in-opensips-4-1/)。

```bash

# the external interface
socket=udp:1.2.3.4:5060
socket=tcp:1.2.3.9:5060
socket=tls:[2001:db8:1234:5678::1]:5061

# define the "external" bond socket, over all external sockets
socket=bond:extern {"udp:10.10.0.3:5060", "tcp:10.10.0.5:5060", "tls:[2001:db8:1234:5678::1]:5061"}

```

### stderror_enabled

启用将日志消息写入标准错误。默认值为 *yes*/*1*。

用法示例：

```text

    stderror_enabled = no

```

### stderror_level_filter

写入标准错误的消息的额外日志级别过滤。当需要对 syslog 和标准错误日志使用不同的详细程度时，此参数可能很有用。

*stderror_level_filter* 应与 [log_level](Script-CoreParameters.md#log_level) 参数一致使用，即级别低于 *log_level*。

默认值为 *0*（不过滤）。

用法示例：

```text

    stderror_level_filter = 2

```

### syslog_enabled

启用将日志消息写入 syslog。默认值为 *no*/*禁用*。

用法示例：

```text

    syslog_enabled = yes

```

### stderror_log_format

打印到标准错误的日志消息格式。可能的值为：

* *plain_text*（默认）- 标准的普通文本日志消息；

* *json* - 基本 JSON 文档

* *json_cee* - 遵循 [CEE(Common Event Expression)](https://cee.mitre.org/language/1.0-beta1/core-profile.html) 架构的 JSON 文档。

默认值为 *plain_text*。

用法示例：

```text

    stderror_log_format = "json"

```

### syslog_facility

如果 **OpenSIPS** 记录到 syslog，您可以控制日志记录的工具。当您想将所有 **OpenSIPS** 日志转移到不同的日志文件时非常有用。
有关更多详细信息，请参阅 syslog(3) 手册页。

默认值为 LOG_DAEMON。

用法示例：

```text
syslog_facility=LOG_LOCAL0
```

### syslog_level_filter

发送到 syslog 的消息的额外日志级别过滤。当需要对 syslog 和标准错误日志使用不同的详细程度时，此参数可能很有用。

*stderror_level_filter* 应与 [log_level](Script-CoreParameters.md#log_level) 参数一致使用，即级别低于 *log_level*。

默认值为 *0*（不过滤）。

用法示例：

```text

    syslog_level_filter = 1

```

### syslog_log_format

发送到 syslog 的日志消息格式。可能的值为：

* *plain_text*（默认）- 标准的普通文本日志消息；

* *json* - 基本 JSON 文档

* *json_cee* - 遵循 [CEE(Common Event Expression)](https://cee.mitre.org/language/1.0-beta1/core-profile.html) 架构的 JSON 文档。

默认值为 *plain_text*。

用法示例：

```text

    syslog_log_format = "json"

```

### syslog_name

设置要打印在 syslog 中的 ID。值必须是字符串，仅在 **OpenSIPS** 以守护进程模式运行（fork=yes）时生效，在 daemonize 之后。
默认值为 argv[0]。

用法示例：

```text
syslog_name="osips-5070"
```

### tcp_workers
用于从 TCP 连接读取的 worker 进程数量。这些 worker 负责处理任何基于 TCP 的协议（如 SIP-TCP、SIP-TLS、SIP-WS、SIP-WSS、BIN 或 HEP）上的任何流量。
如果未显式设置值，将创建 8 个 TCP worker。
您可以选择定义一个自动缩放配置文件来动态管理 TCP worker 的数量（通过根据负载创建或终止进程）。请参阅 [auto_scaling_profile](#auto_scaling_profile) 参数了解更多。

用法示例：

```text
tcp_workers= 4
tcp_workers= 3 use_auto_scaling_profile PROFILE_SIP
```

### tcp_accept_aliases

默认值 *0*（禁用）。如果启用，OpenSIPS 将在检测到 *";alias"* Via 头字段参数时强制执行 RFC 5923 行为，并将重用为此类 SIP 请求打开的任何 TCP（或 TLS、WS、WSS）连接（源 IP + Via 端口 + 协议）来发送其他 SIP 请求，反向发送至相同的（源 IP + Via 端口 + 协议）对。毕竟，RFC 5923 的最终目的是最小化 SIP 代理必须打开的 TLS 连接数量，因为连接建立阶段会产生大量 CPU 开销。

  

除了 RFC 5923 的连接重用（别名）机制外，OpenSIPS 中的 TCP 连接也在多个 SIP dialog 中保持持久。这可以通过 [tcp_connection_lifetime](#tcp_connection_lifetime) 全局参数来控制。

  

> [!WARNING]
> 为最终用户发起的连接（他们很可能按一个或多个公共 IP 分组）启用全局 **tcp_accept_aliases** 参数（RFC 5923）是呼叫劫持的开放载体！在此类平台上，我们建议使用 [force_tcp_alias()](https://docs.opensips.org/manual/devel/script-corefunctions#force_tcp_alias) 核心函数，以便仅在与相邻 SIP 代理结合时才采用 RFC 5923 行为。

### tcp_connect_timeout

在终止持续的阻塞连接尝试之前的毫秒数。默认值为 100ms。

用法示例：
```text

    tcp_connect_timeout = 5

```

### tcp_connection_lifetime

TCP 会话的生命周期（秒）。如果 TCP 会话不活跃超过 tcp_connection_lifetime，将被 **OpenSIPS** 关闭。默认值在 tcp_conn.h 中定义：#define DEFAULT_TCP_CONNECTION_LIFETIME 120。将此值设置为 0 将很快关闭 TCP 连接；-)。您还可以将 TCP 生命周期设置为 REGISTER 的 expire 值，使用 registrar 模块的 tcp_persistent_flag 参数。

用法示例：
```text

    tcp_connection_lifetime = 3600

```

### tcp_max_connections

最大活动 TCP **已接受**连接数（即由远程端点发起的）。达到限制后，任何新的传入 TCP 连接都将被拒绝。默认为 **2048**。对于传出 TCP 连接（由 OpenSIPS 发起的），目前没有限制。

用法示例：
```text

    tcp_max_connections = 4096

```

### tcp_max_msg_time

预期通过 TCP 到达的 SIP 消息的最大秒数。如果单个 SIP 数据包在这么多秒后仍未完全接收，则连接被丢弃（要么连接非常过载导致高度分片——要么我们是持续攻击的受害者，攻击者以非常分片的方式发送流量以降低我们的性能）。默认值为 4

用法示例：
```text

    tcp_max_msg_time = 8

```

### tcp_no_new_conn_bflag

一个分支标志，用作标记，指示 OpenSIPS 在传递请求时不尝试打开新的 TCP 连接，而只重用现有连接（如果有的话）。如果没有现有连接，将返回通用发送错误。

这旨在用于 NAT 场景，在 NAT 后面的目标打开 TCP 连接没有意义（例如注册期间创建的 TCP 连接丢失，因此在设备重新 REGISTER 之前无法联系设备）。这也可用作检测 NAT 注册用户是否丢失了 TCP 连接，以便 opensips 可以禁用其注册（因为已无用）。

用法示例：
```text

     tcp_no_new_conn_bflag = TCP_NO_CONNECT
     ...
     route {
         ...
         if (isflagset(DST_NATED) && $socket_in(proto) == "TCP")
             setbflag(TCP_NO_CONNECT);
         ...
         t_relay("no-auto-477 ");
         $var(retcode) = $rc;
         if ($var(retcode) == -6) {
             #send error
             xlog("unable to send request to destination");
             send_reply("404", "Not Found");
             exit;
         } else if ($var(retcode) < 0) {
             sl_reply_error();
             exit;
         }
     }

```

### tcp_no_new_conn_rplflag

一个消息标志，类似于 [tcp_no_new_conn_bflag](#tcp_no_new_conn_bflag)，用于阻止 OpenSIPS 在发送当前请求的回复时尝试打开新的 TCP 连接（如果没有可用连接）。

用法示例：
```text

     tcp_no_new_conn_msgflag = TCP_NO_RPL_CONNECT
     ...
     route {
         ...
         # if source is detected as NAT'ed, prevent opening back
         # TCP conns for replying
         if (isflagset(SRC_NATED) && $socket_in(proto) == "TCP")
             setbflag(TCP_NO_RPL_CONNECT);
         ...
         # this may fail at transport layer if no
         # TCP conn exists
         t_reply(302,"Redirected");         
     }

```

### tcp_parallel_read_on_workers

此选项将允许 TCP 连接从不同进程执行读取操作，而不仅仅是从一个进程执行。到目前为止，创建时，TCP 连接被分配给执行所有读取的 TCP worker。这可能成为瓶颈。通过 "tcp_parallel_read_on_workers"，完成一次读取后，TCP 连接被传回 TCP 主进程，主进程将对下一次读取操作执行重新平衡，将 TCP 连接传递给另一个 worker。

> [!NOTE]
> 在 TCP 连接级别，读取操作仍以串行方式执行，一次一个（即使来自不同进程）

### tcp_socket_backlog

backlog 参数定义 TCP 监听套接字挂起连接队列可能增长到的最大长度。如果连接请求在队列满时到达，客户端可能收到带有 ECONNREFUSED 指示的错误，或者如果底层协议支持重传，请求可能被忽略，以便稍后重试连接成功。

默认配置值为 10。

### tcp_threshold
一个数字，表示发送 TCP 请求预期持续的最大微秒数。超过设定数量的任何内容都将触发日志设施的警告消息。

默认值为 0（日志记录禁用）。

用法示例：

```text
tcp_threshold = 60000
```

### tcp_keepalive

启用或禁用 TCP keepalive（操作系统级别）。

默认启用。

用法示例：

```text

    tcp_keepalive = 1

```

### tcp_keepcount

关闭连接前发送的 keepalive 数量（仅限 Linux）。默认值取决于操作系统，可使用 `cat /proc/sys/net/ipv4/tcp_keepalive_probes` 查找。常见值为 *9*。

设置 [tcp_keepcount](Script-CoreParameters.md#xlog_buf_size) 为任何值将启用 [tcp_keepalive](Script-CoreParameters.md#wdir)。

用法示例：
```text

    tcp_keepcount = 5

```

### tcp_keepidle

如果连接空闲，OpenSIPS 开始发送 keepalive 之前的时间（仅限 Linux）。默认值取决于操作系统，可使用 `cat /proc/sys/net/ipv4/tcp_keepalive_time` 查找。常见值为 *7200* 秒。

设置 [tcp_keepidle](Script-CoreParameters.md#xlog_force_color) 为任何值将启用 [tcp_keepalive](Script-CoreParameters.md#wdir)。

用法示例：
```text

    tcp_keepidle = 30

```

### tcp_keepinterval

如果前一个 keepalive 失败，keepalive探测之间的时间间隔（仅限 Linux）。默认值取决于操作系统，可使用 `cat /proc/sys/net/ipv4/tcp_keepalive_intvl` 查找。常见值为 *75* 秒。

设置 [tcp_keepinterval](Script-CoreParameters.md#xlog_level) 为任何值将启用 [tcp_keepalive](Script-CoreParameters.md#wdir)。

用法示例：
```text

    tcp_keepinterval = 10

```

### timer_workers
为定时器相关任务/处理专门创建的 worker 进程数量。默认值为 '1'。
您可以选择定义一个自动缩放配置文件来动态管理 timer worker 的数量（通过根据负载创建或终止进程）。请参阅 [auto_scaling_profile](#auto_scaling_profile) 参数了解更多。

用法示例：
```text

    timer_workers = 3
    timer_workers = 3 use_auto_scaling_profile PROFILE_TIMER

```

### tos

用于发送 IP 包（包括 TCP 和 UDP）的 TOS（服务类型）。默认值为 *IPTOS_LOWDELAY*。要禁用 TOS 设置，请将其设置为 0。
请注意，此全局值可以被每个套接字 TOS 设置覆盖（请参阅 [socket](#socket) 参数）。

用法示例：

```text

    tos=IPTOS_LOWDELAY
    tos=0x10
    tos=IPTOS_RELIABILITY

```

### udp_workers

为**每个**已定义的 UDP 或 SCTP 接口创建的 worker 进程数量。默认值为 8。
您可以选择定义一个自动缩放配置文件来动态管理 UDP worker 的数量（通过根据负载创建或终止进程）。请注意，按接口定义的自动缩放配置文件将覆盖此全局 UDP 自动缩放配置文件。
请参阅 [auto_scaling_profile](#auto_scaling_profile) 参数了解更多。

用法示例：
```text

    udp_workers=16
    udp_workers=4 use_auto_scaling_profile PROFILE_SIP 

```

> [!NOTE]
> 此全局值（适用于所有 UDP/SCTP 接口）可以通过在特定接口定义中设置不同的 worker 数量来覆盖——因此实际上您可以为每个接口定义不同数量的 worker（请参阅 [listen](#listen) 参数的语法）。

### user_agent_header

**OpenSIPS** 作为 UAC 发送请求时生成的 User-Agent 头字段的正文。默认为 "OpenSIPS (`<version>` (`<arch>`/`<os>`))"。
用法示例：

```text

user_agent_header="User-Agent: My Company SIP Proxy"

```

请注意，您必须包含头名称 "User-Agent:"，因为 **OpenSIPS** 不会添加它，否则您将得到一个错误的头，如：
```text

My Company SIP Proxy

```

### wdir

**OpenSIPS** 在运行时使用的工作目录。当涉及到生成 core 文件时，您可能会觉得它有用：）

用法示例：
```text

     wdir="/usr/local/opensips"
     or
     wdir=/usr/opensips_wd

```

### xlog_buf_size

默认值：4096

  

用于在 OpenSIPS 所选日志设施上打印单行的缓冲区大小。如果缓冲区太小，将打印溢出错误，并跳过相关行。

用法示例：
```text

    xlog_buf_size = 8388608 # given in bytes

```

### xlog_force_color

默认值：false

  

仅在 [xlog](https://docs.opensips.org/manual/devel/script-corefunctions#strip_tail) 设置为 *true* 时相关。启用 [color escape sequences](https://docs.opensips.org/manual/devel/script-corevar#sdp) 的使用，否则它们将不起作用。

用法示例：
```text

    xlog_force_color = true

```

### xlog_level

类似于 [log_level](#log_level)，此参数独立控制（从 OpenSIPS 代码的其余部分）xlog() 函数的详细程度。这使您可以分别控制来自代码的日志与来自 xlog() 的日志的详细级别。

默认值为 2 / L_NOTICE

用法示例：
```text

    xlog_level = 3 #L_DBG

```

### xlog_print_level

默认值：2 (L_NOTICE)

  

当省略 log_level 参数时，打印由 [xlog](https://docs.opensips.org/manual/devel/script-corefunctions#xlog) 核心函数生成的日志的默认级别。

用法示例：
```text

    xlog_print_level = 2 #L_NOTICE

```
