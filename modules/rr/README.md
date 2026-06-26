---
title: "rr Module"
description: "该模块包含记录路由逻辑"
---

## 管理指南


### 概述


该模块包含记录路由逻辑


### 对话支持


OpenSIPS 本质上只是一个事务有状态的代理，**没有内置的对话支持**。许多功能/服务实际上需要对话感知，比如在对话创建阶段存储信息，这些信息将在整个对话存在期间使用。


最迫切的例子是 NAT 穿越，处理对话内的 INVITE（re-INVITE）。当初始 INVITE 被处理时，代理检测到呼叫者或被叫者是否在某个 NAT 后面，并修复信令和媒体部分——由于并非所有检测机制都可用于对话内请求（如 usrloc），为了能够相应地修复顺序请求，代理必须记住原始请求已被 NAT 处理。还有许多其他情况需要对话感知来修复或提供帮助。


解决方案是将额外的对话相关信息存储在路由集（Record-Route/Route 头）中，这些头出现在所有顺序请求中。因此，添加到 Record-Route 头的任何信息将在 Route 头中找到（没有方向依赖）（对应于代理地址）。


作为存储容器，将使用 Record-Route / Route 头的参数——Record-Route 参数镜像由 RFC 3261 强制执行（见 12.1.1 UAS 行为）。


为此，该模块提供以下函数：


- add_rr_param() - 见 [添加 rr 参数](#func_add_rr_param)
- check_route_param() - 见 [检查路由参数](#func_check_route_param)


```c title="RR 模块中的对话支持"
  
UAC                       OpenSIPS PROXY                          UAS

---- INVITE ------>       record_route()          ----- INVITE ---->
                     add_rr_param(";foo=true")

--- reINVITE ----->        loose_route()          ---- reINVITE --->
                    check_route_param(";foo=true")

<-- reINVITE ------        loose_route()          <--- reINVITE ----
                    check_route_param(";foo=true")

<------ BYE -------        loose_route()          <----- BYE -------
                    check_route_param(";foo=true")
  
```


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *无其他 OpenSIPS 模块的依赖*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### append_fromtag (integer)


如果开启，请求的 from-tag 将被附加到 record-route；这有助于理解后续请求（如 BYE）是来自呼叫者（route 的 from-tag == BYE 的 from-tag）还是被叫者（route 的 from-tag == BYE 的 to-tag）


*默认值为 1（是）。*


```c title="设置 append_fromtag 参数"
...
modparam("rr", "append_fromtag", 0)
...
```


#### enable_double_rr (integer)


在某些情况下，服务器需要插入两个 Record-Route 头字段而不是一个。例如，当使用两个断开连接的网络或进行跨协议转发（UDP->TCP）时。此参数启用插入 2 个 Record-Route。服务器稍后会删除它们。


*默认值为 1（是）。*


```c title="设置 enable_double_rr 参数"
...
modparam("rr", "enable_double_rr", 0)
...
```


#### add_username (integer)


如果设置为非 0 值（表示是），用户名部分也将被添加到 Record-Route URI 中。


*默认值为 0（否）。*


```c title="设置 add_username 参数"
...
modparam("rr", "add_username", 1)
...
```


#### enable_socket_mismatch_warning (integer)


当在 OpenSIPS 配置中强制使用预设的 record-route 头，且 record-route 头中的主机与服务器主机不同时，将在日志中打印警告。
'enable_socket_mismatch_warning' 参数启用或禁用该警告。当 OpenSIPS 在 NATed 防火墙后面时，我们不希望为每个桥接呼叫打印此警告。


*默认值为 1（是）。*


```c title="enable_socket_mismatch_warning 使用示例"
...
modparam("rr", "enable_socket_mismatch_warning", 0)
...
```


### 导出的函数


#### loose_route()


该函数对包含路由集的 SIP 请求进行路由。名称有点令人困惑，因为此函数也路由"严格路由器"格式的请求。


此函数通常用于路由对话内请求（如 ACK、BYE、reINVITE）。然而，对话外请求也可以有"预加载路由集"，并可以通过 loose_route 进行路由。它还负责在严格路由器和宽松路由器之间进行转换。


loose_route() 函数分析请求中的 Route 头。如果没有 Route 头，函数返回 FALSE，路由应仅通过 RURI 完成。如果找到 Route 头，函数返回 TRUE 并按 RFC 3261 第 16.12 节中的描述执行。唯一的例外是预加载 Route 头的请求（携带 Route 头的初始请求）：如果只有一个指向本地代理的 Route 头，则该 Route 头被移除，函数返回 FALSE。


该函数能够自动检测是否处理'严格'或'宽松'路由场景（区别在于 SIP 路径如何跨 RURI 和 Route 头存储）。为了区分这两种场景，OpenSIPS 必须确定哪个 SIP URI 包含其地址/域——RURI（那么它是严格路由场景）或顶层 Route URI（那么它是宽松路由场景）。为了检查 SIP URI 是否包含其地址/域，OpenSIPS 将主机 URI 与监听 IP/接口（作为静态组件）和从 "domain" 模块/表列出的域（作为动态组件）进行检查。


如果存在 Route 头但发生其他解析错误（如解析 TO 头获取 TAG），函数也返回 FALSE。


确保你的 loose_route 函数不能被攻击者用来绕过代理授权。


宽松路由主题非常复杂。有关更多详细信息，请参阅 RFC3261（在这个综合 RFC 中搜索"route set"是一个很好的起点）。


此函数可以从 REQUEST_ROUTE 使用。


```c title="loose_route 使用示例"
...
loose_route();
...
```


#### record_route() 和 record_route(string)


该函数添加一个新的 Record-Route 头字段。该头字段将被插入在任何其他 Record-Route 头字段之前。


如果传递任何字符串作为参数，它将作为 URI 参数附加到 Record-Route 头。字符串必须遵循 ";name=value" 方案。


此函数可以从 REQUEST_ROUTE、BRANCH_ROUTE 和 FAILURE_ROUTE 使用。


```c title="record_route 使用示例"
...
record_route();
...
```


#### record_route_preset(string [, string2])


此函数会将字符串放入 Record-Route，除非你知道自己在做什么，否则不要使用。


参数含义如下：


- *string* - 要插入第一个头字段的字符串；它可以包含伪变量。
- *string2* (可选) - 要插入第二个头字段的字符串。


注意：如果存在 'string2'，则 'string' 参数指向出站接口，'string2' 参数指向入站接口。


此函数可以从 REQUEST_ROUTE、BRANCH_ROUTE 和 FAILURE_ROUTE 使用。


```c title="record_route_preset 使用示例"
...
record_route_preset("1.2.3.4:5090");
...
```


#### add_rr_param(param)


向 Record-Route URI 添加参数（参数必须采用 ";name=value" 格式）。该函数也可以在 record_route() 调用之前或之后调用（见 [record route](#func_record_route)）。


参数含义如下：


- *param* (string) - 要添加的 URI 参数。它必须遵循 ";name=value" 方案。


此函数可以从 REQUEST_ROUTE、BRANCH_ROUTE 和 FAILURE_ROUTE 使用。


```c title="add_rr_param 使用示例"
...
add_rr_param(";nat=yes");
...
```


#### check_route_param(re)


该函数检查本地 Route 头（对应于本地服务器）的 URI 参数是否与给定的正则表达式匹配。必须在 loose_route() 之后调用（见 [loose route](#func_loose_route)）。


参数含义如下：


- *re* (string) - 要与 Route URI 参数进行检查的正则表达式。


此函数可以从 REQUEST_ROUTE 使用。


```c title="check_route_param 使用示例"
...
if (check_route_param("nat=yes")) {
    setflag(6);
}
...
```


#### is_direction(dir)


该函数检查请求的流向方向。作为检查使用的是 "ftag" Route 头参数，必须启用 append_fromtag（见 [append fromtag](#param_append_fromtag) 模块参数。而且这只能在 loose_route() 之后调用（见 [loose route](#func_loose_route)）。


如果 "dir" 与请求的流向方向相同，函数返回 true。


"下游"（UAC 到 UAS）方向是相对于创建对话的初始请求。


参数含义如下：


- *dir* (string) - 要检查的方向。它可以是 "upstream"（从 UAS 到 UAC）或 "downstream"（UAC 到 UAS）。


此函数可以从 REQUEST_ROUTE 使用。


```c title="is_direction 使用示例"
...
if (is_direction("upstream")) {
    xdbg("上游请求 ($rm)\n");
}
...
```


#### 导出的伪变量


导出的伪变量在下一节中列出。


##### $rr_params


*$rr_params* - Route 参数的整个字符串——这仅在调用 loose_route() 之后可用


## 开发者指南


RR 模块提供了一个供其他 OpenSIPS 模块使用的内部 API。该 API 提供基于 SIP 对话的功能支持——有关 RR 模块提供的对话支持的更多信息，请参阅 [RR 对话 ID](#dialog_support)。


对于内部（非脚本）使用，RR 模块向其他模块提供注册回调函数的可能性，每次处理本地 Route 头时都会执行该回调函数。回调函数将接收注册参数和 Route 头参数字符串作为参数。


### 可用函数


#### add_rr_param( msg, param)


向请求的 Record-Route URI 添加参数（参数必须采用 ";name=value" 格式）。


成功时函数返回 0。否则返回 -1。


参数含义如下：


- *struct sip_msg* msg* - 将向其 Record-Route 头添加参数 "param" 的请求。
- *str* param* - 要添加到 Record-Route 头的参数——它必须采用 ";name=value" 格式。


#### check_route_param( msg, re)


对于请求 "msg"，该函数检查本地 Route 头（对应于本地服务器）的 URI 参数是否与给定的正则表达式 "re" 匹配。必须在 loose_route 完成后调用。


成功时函数返回 0。否则返回 -1。


参数含义如下：


- *struct sip_msg* msg* - 将检查其 Route 头参数的请求。
- *regex_t* param* - 要与 Route 头参数进行检查的已编译正则表达式。


#### is_direction( msg, dir)


该函数检查请求 "msg" 的流向方向。作为检查使用的是 "ftag" Route 头参数，必须启用 append_fromtag（见 [append fromtag](#param_append_fromtag) 模块参数。而且这只能在 loose_route 完成后调用。


如果 "dir" 与请求的流向方向相同，函数返回 0。否则返回 -1。


参数含义如下：


- *struct sip_msg* msg* - 将检查其方向的请求。
- *int dir* - 要检查的方向。它可以是 "RR_FLOW_UPSTREAM" 或 "RR_FLOW_DOWNSTREAM"。


#### get_route_param( msg, name, val)


该函数在 "msg" 的 Route 头参数中搜索名为 "name" 的参数，并将其值返回到 "val"。只能在 loose_route 完成后调用。


如果找到参数（即使它没有值），函数返回 0。否则返回 -1。


参数含义如下：


- *struct sip_msg* msg* - 将搜索其 Route 头参数的请求。
- *str *name* - 包含要搜索的 Route 头参数。
- *str *val* - 如果找到搜索的 Route 头参数，则返回其值。如果没有值，可能为空字符串。


#### register_rrcb( callback, param, prior)


该函数注册一个新回调（及其参数）。当对本地地址执行宽松路由时，将调用该回调。


成功时函数返回 0。否则返回 -1。


参数含义如下：


- *rr_cb_t callback* - 要注册的回调函数。
- *void *param* - 要传递给回调函数的参数。
- *short prior* - 设置优先级的参数。如果回调依赖于另一个模块，此参数应该大于该模块的优先级。否则应为 0。


### 示例


```c title="从另一个模块加载 RR 模块的 API"
...
#include "../rr/api.h"
...
struct rr_binds my_rrb;
...
...
/* 加载 RR API */
if (load_rr_api( &my_rrb )!=0) {
    LM_ERR("无法加载 RR API\n");
    goto error;
}
...
...
/* 注册 RR 回调 */
if (my_rrb.register_rrcb(my_callback,0,0))!=0) {
    LM_ERR("无法注册 RR 回调\n");
    goto error;
}
...
```


## 常见问题


**Q: 旧的 enable_full_lr 参数怎么了？**


该参数已被视为过时。它只是为了允许与较旧的 SIP 实体兼容，这些实体抱怨没有值的 lr 参数。
这种行为违反了 RFC 3261，而且如今大多数 SIP 栈都已修复以符合 RFC，因此该参数已被移除。


**Q: 在哪里可以找到更多关于 OpenSIPS 的信息？**


请查看 [https://opensips.org/](https://opensips.org/)。


**Q: 在哪里可以发布关于此模块的问题？**


首先检查你的问题是否已在我们某个邮件列表中回答：

关于任何稳定 OpenSIPS 版本的电子邮件应发送至 users@lists.opensips.org，关于开发版本的电子邮件应发送至 devel@lists.opensips.org。

如果你想私下保持邮件，请发送至 users@lists.opensips.org。


**Q: 如何报告错误？**


请遵循以下指南：[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享署名 4.0 国际许可协议授权。
