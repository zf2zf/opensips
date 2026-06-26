---
title: "rtpproxy 模块"
description: "此模块用于 OpenSIPS 与 RTPProxy 通信，RTPProxy 是一个媒体中继代理，用于使 NAT 背后的用户代理之间的通信成为可能。"
---

## 管理指南

### 概述

此模块用于 OpenSIPS 与 RTPProxy 通信，RTPProxy 是一个媒体中继代理，用于使 NAT 背后的用户代理之间的通信成为可能。

此模块还可与 RTPProxy 一起用于在用户代理之间录制媒体流或向 UAC 或 UAS 播放媒体。

### 多个 RTPProxy 使用

目前，rtpproxy 模块可以支持多个 rtpproxy 用于负载均衡/分发和控制/选择目的。

该模块允许定义多组 rtpproxy——负载均衡将在一个集合上执行，用户可以选择应使用哪个集合。集合通过其 ID 选择——ID 与集合一起定义。请参阅 "rtpproxy_sock" 模块参数定义了解语法描述。

集合内的负载均衡由模块根据集合中每个 rtpproxy 的权重自动执行。请注意，如果 rtpproxy 的权重为 0，则仅当没有其他 rtpproxy（权重值不为 0）响应时才会使用它。默认权重为 1。

从 OpenSIPS 2.1 开始，engage_rtp_proxy()、unforce_rtp_proxy() 和 start_recording() 函数已被完全替换为 rtpproxy_engage()、rtpproxy_unforce() 和 rtpproxy_start_recording()。

重要提示：如果您使用多个集合，请确保对 rtpproxy_offer()/rtpproxy_answer() 和 rtpproxy_unforce() 使用相同的集合！

### RTPProxy 超时通知

Nathelper 模块还可以从多个 rtpproxy 接收超时通知。RTPProxy 可以配置为在一段时间（可配置的间隔）未收到任何媒体时发送通知。rtpproxy 模块实现了一个此类通知的监听器，收到通知时会终止 SIP 级别的对话（向两端发送 BYE），借助 dialog 模块的帮助。

在我们与 RTPProxy 的测试中，我们观察到一些限制，并提供了针对 git 提交 "600c80493793bafd2d69427bc22fcb43faad98c5" 的补丁。它包含一个补充，并为会话建立阶段和持续会话阶段实现了单独的超时参数。在官方代码中，单个超时参数控制会话建立和 rtp 超时，并且在会话建立阶段也会发送超时通知。这是一个问题，因为我们希望快速检测 rtp 超时，但也允许更长的会话建立时间。

请注意，RTPProxy 版本 [v2.0.0](http://www.rtpproxy.org/post/v2release/) 已将此功能集成到上游，因此不再需要此补丁。

要启用超时通知，您必须遵循几个步骤：通过在配置脚本中设置 "rtpp_notify_socket" 模块参数来启动 OpenSIPS 超时检测。这是将从 rtpproxy 接收进一步通知的套接字。此套接字必须是 TCP 或 UNIX 套接字。此外，对于需要通知的所有调用，必须使用 "n" 标志调用 rtpproxy_engage()、rtpproxy_offer() 和 rtpproxy_answer() 函数。
配置 RTPProxy 使用超时通知，添加以下命令行参数：

- " -n timeout_socket" - 指定通知将发送到的位置。此套接字必须与 "rtpp_notify_socket" OpenSIPS 模块参数相同。此参数是必需的。
- " -T ttl" - 将 rtp 会话超时限制为 "ttl"。此参数是可选的，默认值为 60 秒。
- " -W ttl" - 将会话建立超时限制为 "ttl"。此参数是可选的，默认值为 60 秒。

所有先前的参数都可以与官方 RTPProxy 版本一起使用，除了最后一个。它与 RTPProxy 的其他修改一起添加，以便正常工作。补丁位于模块的 *patches* 目录中。
要从 git 获取打补丁的版本，您必须遵循以下步骤：

- 获取最新的源代码："git clone git://sippy.git.sourceforge.net/gitroot/sippy/rtpproxy"
- 从提交创建分支："git checkout -b branch_name 600c80493793bafd2d69427bc22fcb43faad98c5"
- 修补 RTPProxy："patch < path_to_rtpproxy_patch"

打补丁的版本也可以在以下位置找到：https://opensips.org/pub/rtpproxy/

### 依赖

#### OpenSIPS 模块

以下模块必须在此模块之前加载：

- *数据库* 模块——仅当您想使用数据库表加载 rtp proxy 集合时。
- *dialog* 模块——如果使用 rtpproxy_engage 函数或 RTPProxy 超时通知。

#### 外部库或应用程序

运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：

- *无*。

### 导出的参数

#### rtpproxy_sock (string)

用于连接（一组）RTPProxy 的套接字定义。它可以指定 UNIX 套接字、IPv4/IPv6 UDP 套接字或 IPv4/IPv6 TCP 套接字。如果缺少协议部分（即 "udp:"），则套接字被视为 UNIX 套接字。

该定义还支持指定不同的 IP 来广告，而不是 RTPProxy 返回的 IP。当有多个 RTPProxy 服务器位于 NAT 背后、仅监听私有接口但需要广告一个公有接口时，这很有用。

*默认值为 "NONE"（禁用）。*

```c title="设置 rtpproxy_sock 参数"
...
# 具有特定权重的单个 rtpproxy
modparam("rtpproxy", "rtpproxy_sock", "udp:localhost:22222=2")

# 具有广告地址 + 权重的单个 rtpproxy
modparam("rtpproxy", "rtpproxy_sock", "udp:localhost:22222|8.8.8.8=2")

# 用于 LB 的多个 rtpproxy
modparam("rtpproxy", "rtpproxy_sock",
	"udp:localhost:22222 udp:localhost:22223 tcp:remote1:33422 tcp6:remote2:32322")

# 多组多个 rtpproxy
modparam("rtpproxy", "rtpproxy_sock", "1 == udp:localhost:22222 udp:localhost:22223")
modparam("rtpproxy", "rtpproxy_sock", "2 == udp:localhost:22223")
modparam("rtpproxy", "rtpproxy_sock", "2 == udp:localhost:22223|8.8.8.8")
...
```

#### rtpproxy_disable_tout (integer)

一旦 RTPProxy 被确定为不可达并被标记为禁用，rtpproxy 将在 rtpproxy_disable_tout 秒内不尝试与 RTPProxy 建立通信。

*默认值为 "60"。*

```c title="设置 rtpproxy_disable_tout 参数"
...
modparam("rtpproxy", "rtpproxy_disable_tout", 20)
...
```

#### rtpproxy_timeout (string)

等待 RTPProxy 回复的超时值。

*默认值为 "1"。*

```c title="将 rtpproxy_timeout 设置为 200ms"
...
modparam("rtpproxy", "rtpproxy_timeout", "0.2")
...
```

#### rtpproxy_autobridge (integer)

启用自动桥接功能。在执行串行/并行分叉时无法正常工作！

*默认值为 "0"。*

```c title="启用自动桥接功能"
...
modparam("rtpproxy", "rtpproxy_autobridge", 1)
...
```

#### rtpproxy_retr (integer)

rtpproxy 应在发生超后重试发送和接收的次数。

*默认值为 "5"。*

```c title="设置 rtpproxy_retr 参数"
...
modparam("rtpproxy", "rtpproxy_retr", 2)
...
```

#### default_set (integer)

该参数指示在配置文件中配置引擎时未指定显式集合时，或调用 *rtpproxy_*() 函数时未指定显式集合时要使用的默认 RTPProxy 集合。

*默认值为集合 "0"。*

```c title="设置 default_set 参数"
...
modparam("rtpproxy", "default_set", 1)
...
```

#### nortpproxy_str (string)

该参数设置 rtpproxy 用于标记数据包 SDP 信息已被修改的 SDP 属性。

如果为空字符串，则不会添加或检查标记。

> [!NOTE]
> 该字符串必须是完整的 SDP 行，包括 EOH（\r\n）。

*默认值为 "a=nortpproxy:yes\r\n"。*

```c title="设置 nortpproxy_str 参数"
...
modparam("rtpproxy", "nortpproxy_str", "a=sdpmangled:yes\r\n")
...
```

#### db_url (string)

数据库 URL。如果您想使用数据库表来加载或重新加载用于连接（一组）RTPProxy 的套接字定义，则应设置此参数。数据库表的记录将在启动时读取（添加到使用 rtpproxy_sock 模块参数定义的记录），并在发出 MI 命令 rtpproxy_reload 时读取（定义将被数据库表中的定义替换）。

*默认值为 "NULL"。*

```c title="设置 db_url 参数"
...
modparam("rtpproxy", "db_url", 
		"mysql://opensips:opensipsrw@192.168.2.132/opensips")
...
```

#### db_table (string)

包含用于连接（一组）RTPProxy 的套接字定义的数据库表名称。

*默认值为 "rtpproxy_sockets"。*

```c title="设置 db_table 参数"
...
modparam("rtpproxy", "db_table", "nh_sockets") 
...
```

#### rtpp_socket_col (string)

数据库表中 rtpp 套接字列的名称。

*默认值为 "rtpproxy_sock"。*

```c title="设置 rtpp_socket_col 参数"
...
modparam("rtpproxy", "rtpp_socket_col", "rtpp_socket") 
...
```

#### set_id_col (string)

数据库表中集合 ID 列的名称。

*默认值为 "set_id"。*

```c title="设置 set_id 参数"
...
modparam("rtpproxy", "set_id_col", "rtpp_set_id") 
...
```

#### rtpp_notify_socket (string)

OpenSIPS 监听 RTPProxy 通知的套接字。目前 OpenSIPS 可以接收 RTP 超时和 DTMF 事件。

*默认值为 "NULL" - 不接收通知。*

```c title="设置 rtpp_notify_socket 参数"
...
modparam("rtpproxy", "rtpp_notify_socket", "tcp:10.10.10.10:9999")

# 使用 UNIX 套接字
modparam("rtpproxy", "rtpp_notify_socket", "unix:/tmp/rtpproxy.unix")
# 或
modparam("rtpproxy", "rtpp_notify_socket", "/tmp/rtpproxy.unix")
...
```

#### generated_sdp_port_min (integer)

当 RTPProxy 模块需要生成 SDP 正文时，使用此值作为端口的最小值。

*默认值为 "35000"。*

```c title="设置 generated_sdp_port_min 参数"
...
modparam("rtpproxy", "generated_sdp_port_min", 10000)
...
		
```

#### generated_sdp_port_max (integer)

当 RTPProxy 模块需要生成 SDP 正文时，使用此值作为端口的最大值。

*默认值为 "65000"。*

```c title="设置 generated_sdp_port_max 参数"
...
modparam("rtpproxy", "generated_sdp_port_max", 30000)
...
		
```

#### generated_sdp_media_ip (string)

当 RTPProxy 模块需要生成 SDP 正文时，使用此值作为 *c=* 和 *o=* 中的 media_ip。

*默认值为 "127.0.0.1"。*

```c title="设置 generated_sdp_media_ip 参数"
...
modparam("rtpproxy", "generated_sdp_media_ip", "10.0.0.1")
...
		
```

### 导出的函数

#### rtpproxy_engage([[flags][, [ip_address][, [set_id][, [sock_var][, ret_var]]]]])

重写 SDP 正文以确保媒体通过 RTP 代理。它使用 dialog 模块功能来跟踪何时需要更新 rtpproxy 会话。函数只能为初始 INVITE 调用，并内部负责重写 200 OK 和 ACK 的正文。请注意，当在桥接模式下使用时，此函数可能在 SDP 中广告错误的接口（由于 OpenSIPS 不知道 RTPProxy 配置），因此您可能面临未定义的行为。

参数的含义如下：

- *flags(string，可选)* - 用于开启某些功能的标志：
  - *a* - 标志表示收到消息的 UA 不支持对称 RTP。
  - *l* - 强制"查找"，即，仅当相应会话已在 RTP 代理中存在时才重写 SDP。默认情况下，当会话将要完成时启用（在非交换模式的回复或交换模式的 ACK 中）。
  - *k* - 仅创建 RTPProxy 会话，但不修改 SDP 正文。当您只想注入一些媒体但不想在整个呼叫中参与 RTPProxy 时，这很有用。
  - *i/e* - 当 RTPProxy 用于桥接模式时，这些标志用于指示当前请求/回复的媒体流方向。'i' 指的是 LAN（内部网络），对应于 RTPProxy 的第一个接口（如 -l 参数所指定）。'e' 指的是 WAN（外部网络），对应于 RTPProxy 的第二个接口。这些标志应始终一起使用。例如，来自 Internet（WAN）到本地媒体服务器（LAN）的 INVITE（offer）应使用 'ei' 标志。应答应使用 'ie' 标志。根据场景，也支持 'ii' 和 'ee' 组合。仅在 RTPProxy 以桥接模式运行时才有意义。
  - *注意：*当在桥接模式下使用 RTPProxy 时，所有会话都被视为非对称的（与在正常模式下使用的对称相反）。如果您有对称客户端（这是最常见的场景），您将必须强制使用 *s*！
  - *f* - 指示 rtpproxy 忽略另一个 rtpproxy 在中继插入的标记，以指示会话已经通过另一个代理。允许创建代理链。
  - *r* - 标志表示 SDP 中的 IP 地址应该是可信的。没有此标志，rtpproxy 忽略 SDP 中的地址，使用 SIP 消息的源地址作为传递给 RTP 代理的媒体地址。
  - *o* - 标志表示也应该更改源描述（o=）中的 IP。
  - *c* - 标志用于在媒体描述也包含连接信息时更改会话级 SDP 连接（c=）IP。
  - *s/w* - 标志用于强制收到消息的 UA 支持对称 RTP。
  - *n[<SOCKET>]* - 标志为此会话启用超时通知。可以选择在 < 和 > 标签之间指定可选的"广告"套接字。如果未指定套接字，则使用 *rtpp_notify_socket* 的值。
  - *d[NNN]* - 为此呼叫启用 DTMF 通知。可以选择指定 DTMF 将用于此呼叫的有效载荷类型——如果未指定，RTPProxy 使用 *101* pt。请注意，此功能目前仅在 RTPProxy *rtpp_2_1_dtmf* 分支中可用。
  - *tNN* - 可用于为呼叫方指定 RTP ttl。NN 表示该流的超时秒数。这在呼叫保持场景中很有用，因为只有一个客户端在发送 RTP。
  - *TNN* - 与 *tNN* 参数类似，但用于调整被呼叫方的 RTP ttl。
  - *zNN* - 请求 RTPproxy 执行来自已发送当前消息的 UA 的 RTP 流量的重新打包，以尽可能增加或减少每个 RTP 数据包转发的有效载荷大小。NN 是目标有效载荷大小（以毫秒为单位），对于大多数编解码器，其值应为 10 毫秒的增量，但是对于某些编解码器，增量可能不同（例如 GSM 为 30 毫秒，G.723 为 20 毫秒）。RTPproxy 将选择编解码器支持的最接近的值。此功能可用于显著降低低比特率编解码器的带宽开销，例如 G.729 从 10ms 到 100ms 可节省三分之二的网络带宽。
- *ip_address(string，可选)* - 新的 SDP IP 地址。
- *set_id(int，可选)* - 此呼叫使用的集合。
- *sock_var(var，可选)* - 用于存储为此呼叫选择的 RTPProxy 套接字的变量。请注意，变量仅在初始请求中填充。
- *ret_var(var，可选)* - 用于打印 RTPProxy 服务器用于此呼叫的 IP 和端口的变量。这在使用 *rtp_cluster* 时特别有用，它可以广告其背后的多个服务器。返回值的格式为 *IP:port*。请注意，变量仅在初始请求中填充。

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。

```c title="rtpproxy_engage 用法"
...
if (is_method("INVITE") && has_totag()) {
	if ($var(setid) != 0) {
		rtpproxy_engage(,,$var(setid), $var(proxy));
		xlog("脚本: 使用的 RTPProxy 服务器是 $var(proxy)\n");
	} else {
		rtpproxy_engage();
		xlog("脚本: 使用默认 RTPProxy 集合\n");
	}
}
...
		
```

#### rtpproxy_offer([[flags][, [ip_address][, [set_id][, [sock_var][, [ret_var][, [body_var][, [bind_local]]]]]]]])

重写 SDP 正文以确保媒体通过 RTP 代理。应在 SDP 在 INVITE 和 200 OK 中时对 INVITE 调用，以及 SDP 在 200 OK 和 ACK 中时对 200 OK 调用。

该函数接收与 `rtpproxy_engage()` 相同的参数，以及名为 *body_var* 和 *bind_local* 的额外参数。*body_var* 参数用作挑战 RTP 代理服务器应使用的正文的输入输出变量。如果指定了变量，函数使用其内容作为挑战的正文，并在其中返回结果正文。如果未使用，则使用消息的正文，并且更改传出正文。

可选的 *bind_local* 参数直接在整个呼叫上提供本地绑定/接口值。当设置为字符串时，其值作为 *l<value>* 附加到 RTPProxy U/L 命令（例如，"[1:2:3]" 用于 IPv6）。这适用于 `rtpproxy_offer()` 和 `rtpproxy_answer()`。

此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。

```c title="rtpproxy_offer 用法"
route {
...
    if (is_method("INVITE")) {
        if (has_body("application/sdp")) {
            if (rtpproxy_offer())
                t_on_reply("1");
        } else {
            t_on_reply("2");
        }
    }
    if (is_method("ACK") && has_body("application/sdp"))
        rtpproxy_answer();
...
}

onreply_route[1]
{
...
    if (has_body("application/sdp"))
        rtpproxy_answer();
...
}

onreply_route[2]
{
...
    if (has_body("application/sdp"))
        rtpproxy_offer();
...
}
```

#### rtpproxy_answer([[flags][, [ip_address][, [set_id][, [sock_var][, [ret_var][, [body_var][, [bind_local]]]]]]]])

重写 SDP 正文以确保媒体通过 RTP 代理。应在 SDP 在 INVITE 和 200 OK 中时对 200 OK 调用，以及 SDP 在 200 OK 和 ACK 中时对 ACK 调用。

有关参数含义，请参阅上面的 `rtpproxy_offer()` 函数描述。

此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。

上面的 rtpproxy_offer() 函数示例请参见该函数示例。

#### rtpproxy_unforce([[set_id][, sock_var]])

拆除当前呼叫的 RTPProxy 会话。

参数的含义如下：

- *set_id(int，可选)* - 此呼叫使用的集合。
- *sock_var(var，可选)* - 用于存储为此呼叫选择的 RTPProxy 套接字的变量。

此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。

```c title="rtpproxy_unforce 用法"
...
rtpproxy_unforce();
...
```

#### rtpproxy_stream2uac(prompt_name, count[, [set_id][, sock_var]]), rtpproxy_stream2uas(prompt_name, count[, [set_id][, sock_var]])

指示 RTPproxy 流式传输使用 RTPproxy 分发中的 makeann 命令预编码的提示/公告。uac/uas 后缀选择谁将听到与当前事务相关的公告——UAC 或 UAS。例如，在请求处理块中对 ACK 事务调用 `rtpproxy_stream2uac` 将向生成原始 INVITE 和 ACK 的 UA 播放提示，而在 183 回复处理块中调用 `rtpproxy_stop_stream2uas` 将向生成 183 的 UA 播放提示。

除了生成公告，此函数的另一个可能应用是实现呼叫保持（MOH）功能。当 count 为 -1 时，流将无限循环，直到发出适当的 `rtpproxy_stop_stream2xxx`。

为了正确工作，函数要求会话已存在于 RTPproxy 中。此外，这些函数不修改 SDP，因此它们不能替代调用 `rtpproxy_offer` 或 `rtpproxy_answer`。

此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE 使用。

参数的含义如下：

- *prompt_name* (string) - 要流式传输的提示名称。应该是绝对路径名或相对于 RTPproxy 运行目录的路径名。
- *count* (int) - 提示应重复的次数。值 -1 表示它将无限循环流式传输，直到发出适当的 `rtpproxy_stop_stream2xxx`。
- *set_id(int，可选)* - 此呼叫使用的集合。
- *sock_var(var，可选)* - 用于存储为此呼叫选择的 RTPProxy 套接字的变量。

```c title="rtpproxy_stream2xxx 用法"
...
    if (is_method("INVITE")) {
        rtpproxy_offer();
        if ($rb=~ "0\.0\.0\.0") {
            rtpproxy_stream2uas("/var/rtpproxy/prompts/music_on_hold", -1);
        } else {
            rtpproxy_stop_stream2uas();
        };
    };
...
	    
```

#### rtpproxy_stop_stream2uac([[set_id][, sock_var]]), rtpproxy_stop_stream2uas([[set_id][, sock_var]])

停止之前由相应的 `rtpproxy_stream2xxx` 启动的公告/提示/MOH 流式传输。uac/uas 后缀选择应停止哪个与当前事务相关的公告——UAC 或 UAS。

参数的含义如下：

- *set_id(int，可选)* - 此呼叫使用的集合。
- *sock_var(var，可选)* - 用于存储为此呼叫选择的 RTPProxy 套接字的变量。

这些函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE 使用。

#### rtpproxy_start_recording([[set_id][, [sock_var][, [flags][, [destination][, mediastream]]]]])

此命令将向 RTP-Proxy 发送信号以在 RTP-Proxy 上录制 RTP 流。

参数的含义如下：

- *set_id(int，可选)* - 此呼叫使用的集合。
- *sock_var(var，可选)* - 用于存储为此呼叫选择的 RTPProxy 套接字的变量。
- *flags(string，可选)* - 传递给 RTPProxy 用于录制的标志列表。目前仅支持 *s*，它指示 RTPProxy 应将两个音频腿录制在单个文件中。请注意，此功能从 RTPProxy 2.0 开始可用。
- *destination(string，可选)* - 录制的目的地。如果格式为 *udp:IP:port*，RTPProxy 将 RTP 流发送到该 *IP:port* 远程目的地。否则，目的地表示录制目录中的文件名。
- *mediastream(int，可选)* - 仅当指定了 *destination* 时才使用此参数，表示要录制/拷贝的媒体流的索引，从 1 开始。如果此参数缺失，OpenSIPS 指示 RTPProxy 拷贝所有流。

此函数可以从 REQUEST_ROUTE 和 ONREPLY_ROUTE 使用。

```c title="rtpproxy_start_recording 用法"
...
rtpproxy_start_recording();

# 将 RTP 流拷贝到不同的监听器
rtpproxy_start_recording(,,,"udp:127.0.0.1:60000");

# 仅拷贝第一个 RTP 流（音频流）
rtpproxy_start_recording(,,,"udp:127.0.0.1:60000", 1);
...
		
```

#### rtpproxy_stats(up_pvar, down_var, sent_var, fail_var[, [set_id][, sock_var]])

此命令从 RTP-Proxy 收集呼叫 RTP 统计信息。

参数的含义如下：

- *up_var* (var) - 用于返回此呼叫的 *上游* 发送的数据包数的变量。
- *down_var* (var) - 用于返回此呼叫的 *下游* 发送的数据包数的变量。
- *sent_var* (var) - 用于返回此呼叫发送的数据包总数的变量。
- *up_var* (var) - 用于返回此呼叫失败的数据包数的变量。
- *set_id(int，可选)* - 此呼叫使用的集合。
- *sock_var(var，可选)* - 用于存储为此呼叫选择的 RTPProxy 套接字的变量。

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE 使用。

```c title="rtpproxy_stats 用法"
...
rtpproxy_stats($var(up),$var(down),$var(sent),$var(fail));
xlog("$ci 的 RTP 统计信息: up=$var(up) down=$var(down) sent=$var(sent) fail=$var(fail)\n");
...
		
```

#### rtpproxy_all_stats(stats_avp[, [set_id][, sock_var]])

此命令从 RTP-Proxy 收集所有可用的 RTP 统计信息。所有返回值存储在一个 AVP 中，可以通过索引进一步读取。

此命令仅在 RTPProxy 2.1 发布版开始可用。

参数的含义如下：

- *stats_avp* (var) - 将存储统计信息的 AVP。可以进一步索引此 AVP 以获取特定统计信息。
- *set_id(int，可选)* - 此呼叫使用的集合。
- *sock_var(var，可选)* - 用于存储为此呼叫选择的 RTPProxy 套接字的变量。

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE 使用。

每个统计信息按以下特定索引存储：

- *ttl* - *$avp(ret)* / *$(avp(ret)[0])*
- *pkts_ia* - *$(avp(ret)[1])*
- *pkts_io* - *$(avp(ret)[2])*
- *relayed* - *$(avp(ret)[3])*
- *dropped* - *$(avp(ret)[4])*
- *rtpa_set* - *$(avp(ret)[5])*
- *rtpa_rcvd* - *$(avp(ret)[6])*
- *rtpa_dups* - *$(avp(ret)[7])*
- *rtpa_lost* - *$(avp(ret)[8])*
- *rtpa_perrs* - *$(avp(ret)[9])*

```c title="rtpproxy_all_stats 用法"
...
rtpproxy_all_stats($avp(stats));
xlog("$ci 的 RTP 统计信息: dropped=$(avp(stats)[4])\n");
...
		
```

### 导出的 MI 函数

#### rtpproxy:enable

替换已弃用的 MI 命令：*rtpproxy_enable*。

启用/禁用 rtp 代理。

参数：

- *url* - rtp 代理 URL（与配置文件中定义的方式完全相同）。
- *rtpproxy:enable* - 1 启用，0 禁用 RTPproxy 节点，2 将 RTPproxy 节点置于探测模式。
- *setid* (可选) - rtpproxy 集合 ID（用于更好地识别要启用的 rtpproxy 实例，例如当 rtpproxy 在多个集合中使用时）。

注意：如果 rtpproxy 被多次定义（在同一或不同集合中），如果未提供集合 ID（作为第二个参数），所有实例都将被启用/禁用。

```c title="rtpproxy:enable 用法"
...
## 仅通过 URL 禁用 RTPProxy
$ opensips-cli -x mi rtpproxy:enable udp:192.168.2.133:8081 0
## 通过 URL 和集合 ID (3) 禁用 RTPProxy
$ opensips-cli -x mi rtpproxy:enable udp:192.168.2.133:8081 0 3
...
			
```

#### rtpproxy:show

替换已弃用的 MI 命令：*rtpproxy_show*。

显示所有 rtp 代理及其信息：集合和状态（是否禁用、权重和重新检查滴答数）。

无参数。

```c title="rtpproxy:show 用法"
...
$ opensips-cli -x mi rtpproxy:show
...
			
```

#### rtpproxy:reload

替换已弃用的 MI 命令：*rtpproxy_reload*。

从数据库重新加载 rtp 代理集合。该函数将删除所有先前的记录，并用数据库表中的条目填充列表。如果您想使用此命令，则必须设置 db_url 参数。

无参数。

```c title="rtpproxy:reload 用法"
...
$ opensips-cli -x mi rtpproxy:reload
...
			
```

### 导出的事件

#### E_RTPPROXY_STATUS

当 RTPProxy 服务器状态变为启用/禁用时触发此事件。

参数：

- *socket* - 标识 RTPProxy 实例的套接字。
- *status* - 如果 RTPProxy 实例响应探测，则为 *active*；如果实例被停用，则为 *inactive*。

#### E_RTPPROXY_DTMF

当 RTPProxy 服务器向 OpenSIPS 发送 DTMF 通知时触发此事件。为了捕获 RFC 2833/4733 DTMF 事件，您需要向 *rtpproxy_offer()*/ *rtpproxy_answer()* 提供 *d* 标志。

参数：

- *digit* - 按下的数字。
- *duration* - 事件的持续时间。
- *volume* - 事件的音量。
- *id* - 表示接收事件的呼叫的标识符。
- *is_callid* - 当 *id* 参数表示 Dialog ID 时为 *0*，当它是 callid 时为 *1*。
- *stream* - 指示 RTPProxy 会话的流索引。通常为 0（如果呼叫方发送了 DTMF），或 1（如果被呼叫方发送了 DTMF）。

## 常见问题

**Q: "rtpproxy_disable" 参数发生了什么？**

它被移除了，因为它已过时——现在 "rtpproxy_sock" 可以使用空值来禁用 rtpproxy 功能。

**Q: 在哪里可以找到更多关于 OpenSIPS 的信息？**

请查看 [https://opensips.org/](https://opensips.org/)。

**Q: 在哪里可以发布关于此模块的问题？**

首先请检查您的问题是否已在我们的邮件列表中回答：

任何稳定 OpenSIPS 版本的相关邮件应发送至 users@lists.opensips.org，开发版本的相关邮件应发送至 devel@lists.opensips.org。

如果您想保持邮件私密，请发送至 users@lists.opensips.org。

**Q: 如何报告错误？**

请遵循以下指南：[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
