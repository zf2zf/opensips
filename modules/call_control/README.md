---
title: "呼叫控制模块"
description: "此模块允许限制呼叫的持续时间并在呼叫超过设定限制时自动结束它们。它的主要用例是实现预付费系统，但也可用于对代理处理的所有呼叫施加全局限制。"
---

## 管理指南


### 概述


此模块允许限制呼叫的持续时间并在呼叫超过设定限制时自动结束它们。它的主要用例是实现预付费系统，但也可用于对代理处理的所有呼叫施加全局限制。


### 描述


Callcontrol 由 3 个组件组成：


- OpenSIPS call_control 模块
- 一个名为 callcontrol 的外部应用程序，用于跟踪有时间限制的呼叫并在它们超过限制时自动结束它们。此应用程序接收来自 OpenSIPS 的请求，并向计费引擎发出请求（见下文）以确定呼叫是否需要限制。当呼叫结束（或被结束）时，它还会指示计费引擎扣除呼叫者已消费金额的余额。callcontrol 应用程序可从 http://callcontrol.ag-projects.com/ 获取
- 一个计费引擎，用于根据呼叫者信用和目的地价格计算时间限制，并在呼叫结束后扣除呼叫者的余额。这作为 CDRTool 的一部分提供，可从 http://cdrtool.ag-projects.com/ 获取


callcontrol 应用程序与 OpenSIPS 运行在同一台机器上，它们通过文件系统套接字通信，而计费引擎可以运行在不同的主机上，通过 TCP 连接与 callcontrol 应用程序通信。


Callcontrol 通过为每个我们要施加限制的呼叫的初始 INVITE 调用 call_control() 函数来调用。这将最终成为对 callcontrol 应用程序的请求，该应用程序将向计费引擎查询给定呼叫者和目的地的时限。计费引擎将确定目的地是否有相关费用，呼叫者是否有信用额度，如果有，将返回允许呼叫该目的地的时间量。否则，它将指示该呼叫没有关联限制。如果有限制，callcontrol 应用程序将保留会话并附加一个计时器，该计时器将在给定时间后过期，导致它回调 OpenSIPS 并发出结束对话框的请求。如果计费引擎返回该呼叫没有限制，则会话由 callcontrol 应用程序丢弃，并将允许其继续进行而没有任何限制。适当的响应返回给 call_control 模块，然后由 call_control() 函数调用返回，并允许脚本根据答案做出决定。


### 功能特性


- 非常简单的 API，只有一个函数，需要为每个呼叫的首次 INVITE 调用一次。其余的通过对话框回调在后台自动完成。
- 当呼叫超过时间时通过触发 dialog 模块的 dlg_end_dlg 请求优雅地结束对话框，这将向每个端点生成两个 BYE 消息，干净地结束呼叫。
- 使用每个订阅者一个余额允许多个并行会话
- 与 mediaproxy 检测呼叫何时超时未发送媒体并被关闭的能力集成。在这种情况下，由 mediaproxy 触发的 dlg_end_dlg 将在呼叫达到限制并消耗完已死亡但实际未发生的呼叫的所有信用之前结束 callcontrol 会话。为此，必须使用 mediaproxy，并且必须通过 engage_media_proxy() 启动它，以便能够跟踪呼叫的对话框并在超时时结束它。
- 即使 mediaproxy 无法结束对话框，因为它不是通过 engage_media_proxy() 启动的，callcontrol 应用程序仍然能够检测到超时未发送媒体的呼叫，方法是在 mediaproxy 记录的 RADIUS 计费记录中查找超时呼叫的条目。这些呼叫也将由 callcontrol 应用程序本身优雅地结束。
- 如果定义了 prepaid_account_flag 模块参数，外部应用程序会比较 OpenSIPS 和计费引擎关于呼叫账户是否为预付费的观点，并在它们冲突时采取适当行动。这提供了在计费引擎发生故障或数据库不一致的情况下的欺诈保护。
- 如果 call_limit_avp 定义为大于 0 的值，它将被传递给 CallControl 应用程序，这会将计费方（From 用户或转向者）能够进行的并发呼叫数量限制在该值。如果达到限制，call_control 函数将返回特定的错误值。
- call_token_avp 可用于检测具有重复 CallID 的呼叫，这可能在计费引擎中造成潜在问题。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *dialog* 模块


#### 外部库或应用程序


以下库或应用程序必须在运行加载了此模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### disable (int)


一个布尔标志，指定是否应禁用 callcontrol。当您想在两个不同的上下文中使用相同的 OpenSIPS 配置时，这很有用，一个使用 callcontrol，另一个不使用。如果 callcontrol 被禁用，对 call_control() 函数的调用将返回指示呼叫没有关联限制的代码，允许使用相同的配置而无需更改。


*默认值为 "0"。*


```c title="设置 disable 参数"
...
modparam("call_control", "disable", 1)
...
        
```


#### socket_name (string)


这是 callcontrol 应用程序监听模块命令的文件系统套接字的路径。


*默认值为 "/run/callcontrol/socket"。*


```c title="设置 socket_name 参数"
...
modparam("call_control", "socket_name", "/run/callcontrol/socket")
...
        
```


#### socket_timeout (int)


等待 callcontrol 应用程序回复的时间（以毫秒为单位）。


*默认值为 "500"（毫秒）。*


```c title="设置 socket_timeout 参数"
...
modparam("call_control", "socket_timeout", 500)
...
        
```


#### signaling_ip_avp (string)


此 AVP 保存 SIP 信令起源 IP 地址的规范。如果设置了这个 AVP，它将被用于获取信令 IP 地址，否则将使用接收 SIP 消息的源 IP 地址。
此 AVP 旨在在呼叫设置路径中有多个代理且实际启动 callcontrol 的代理不直接从 UA 接收 SIP 消息且无法确定信令起源的 NAT IP 地址的情况下使用。在这种情况下，在第一个代理附加 SIP 头部，然后在启动 callcontrol 的代理上将那个头部的值复制到 signaling_ip_avp 将允许它获取 SIP 信令起源的正确 NAT IP 地址。


这由计费引擎使用，该引擎根据呼叫者的 SIP URI、呼叫者的 SIP 域或呼叫者的 IP 地址（以首先产生费率的顺序）找到要应用于呼叫的费率。


*默认值为 "$avp(cc_signaling_ip)"。*


```c title="设置 signaling_ip_avp 参数"
...
modparam("call_control", "signaling_ip_avp", "$avp(cc_signaling_ip)")
...
        
```


#### canonical_uri_avp (string)


此 AVP 保存可选的应用程序定义的规范请求 URI 的规范。设置后，它将在计算呼叫价格时用作目的地，否则将使用请求 URI。当 ruri 中的用户名需要在计费引擎计算中具有与 ruri 中不同的规范形式时，这很有用。


*默认值为 "$avp(cc_can_uri)"。*


```c title="设置 canonical_uri_avp 参数"
...
modparam("call_control", "canonical_uri_avp", "$avp(cc_can_uri)")
...
        
```


#### diverter_avp (string)


此 AVP 保存可选的应用程序定义的转向者 SIP URI 的规范。设置后，计费引擎在查找给定呼叫的费率时将其用作计费方，否则将使用 From 字段中的呼叫者 URI。设置时，此 AVP 应包含 "user@domain" 形式的值（不应使用 sip: 前缀）。


当目的地转向呼叫时这很有用，从而成为新的呼叫者。在这种情况下，计费方是转向者，此 AVP 应设置为它，以允许计费引擎为呼叫选择正确的费率。例如，如果 A 呼叫 B，B 无条件地将所有呼叫转向到 C，那么 diverter AVP 应设置为 B 的 URI，因为 B 是呼叫中的计费方，而不是转向后的 A。


*默认值为 "$avp(diverter)"。*


```c title="设置 diverter_avp 参数"
...
modparam("call_control", "diverter_avp", "$avp(diverter)")

route {
  ...
  # alice@example.com 为此呼叫付费
  $avp(diverter) = "alice@example.com";
  ...
}
...
        
```


#### prepaid_account_flag (string)


用于指定呼叫账户是否为预付费的标志。设置此值为非空值将决定模块将标志的值传递给外部应用程序。这将允许外部应用程序比较 OpenSIPS 和计费引擎关于呼叫账户是否为预付费的观点，并在它们冲突时采取适当行动。标志应从 OpenSIPS 配置为预付费账户设置，为后付费账户重置。


*默认值为 NULL（未定义）。*


```c title="设置 prepaid_account_flag 参数"
...
modparam("call_control", "prepaid_account_flag", "PP_ACC_FLAG")
...
        
```


#### call_limit_avp (string)


此 AVP 保存可选的应用程序定义的呼叫限制的规范。设置后，它将被传递给 CallControl 应用程序，如果达到限制，call_control 函数将返回错误代码 -4。


*默认值为 "$avp(cc_call_limit)"。*


```c title="设置 call_limit_avp 参数"
...
modparam("call_control", "call_limit_avp", "$avp(cc_call_limit)")
...
        
```


#### call_token_avp (string)


此 AVP 保存可选的应用程序定义的令牌的规范。此令牌将用于检查具有相同 CallID 的两个呼叫是否实际引用同一个呼叫。如果为同一呼叫（因此具有相同 CallID）多次调用 call_control()，则令牌需要相同，否则 call_control 将返回 -3 错误，表示 CallID 重复。


*默认值为 "$avp(cc_call_token)"。*


```c title="设置 call_token_avp 参数"
...
modparam("call_control", "call_token_avp", "$avp(cc_call_token)")
...
$avp(cc_call_token) := $RANDOM;
...
        
```


#### init (string)


此参数用于描述自定义呼叫控制初始化消息。它代表一个键值对列表，格式如下：


- "string1 = var1 [string2 = var2]*"


赋值的左侧可以是任何字符串。


赋值的右侧必须是脚本伪变量或脚本 AVP。有关更多信息，请参阅[烹饪书 - 脚本变量](https://opensips.org/Resources/DocsCoreVar15)。


如果未设置参数，则发送默认初始化消息。


*默认值为 "NULL"。*


```c title="设置 init 参数"
	
...
modparam("call_control", "init", "call-id=$ci to=$tu from=$fu 
			authruri=$du another_field = $avp(10)")
...
        
```


#### start (string)


此参数用于描述自定义呼叫控制启动消息。它代表一个键值对列表，格式如下：


- "string1 = var1 [string2 = var2]*"


赋值的左侧可以是任何字符串。


赋值的右侧必须是脚本伪变量或脚本 AVP。有关更多信息，请参阅[烹饪书 - 脚本变量](https://opensips.org/Resources/DocsCoreVar15)。


如果未设置参数，则发送默认启动消息。


*默认值为 "NULL"。*


```c title="设置 start 参数"
	
...
modparam("call_control", "start", "call-id=$ci to=$tu from=$fu 
			authruri=$du another_field = $avp(10)")
...
        
```


#### stop (string)


此参数用于描述自定义呼叫控制停止消息。它代表一个键值对列表，格式如下：


- "string1 = var1 [string2 = var2]*"


赋值的左侧可以是任何字符串。


赋值的右侧必须是脚本伪变量或脚本 AVP。有关更多信息，请参阅[烹饪书 - 脚本变量](https://opensips.org/Resources/DocsCoreVar15)。


如果未设置参数，则发送默认停止消息。


*默认值为 "NULL"。*


```c title="设置 stop 参数"
	
...
modparam("call_control", "stop", "call-id=$ci to=$tu from=$fu 
			authruri=$du another_field = $avp(10)")
...
        
```


### 导出的函数


#### call_control()


对此函数被调用的 INVITE 启动的对话框启用 callcontrol（此函数应仅在为呼叫的首次 INVITE 时调用）。进一步的对话框内请求将使用与对话框状态机的内部绑定自动处理，允许 callcontrol 在对话框进行时更新其内部状态，而无需脚本的其他干预。


此函数应在使用 t_relay() 发送消息之前调用，此时所有请求 URI 修改都已结束并且已确定最终目的地。


此函数具有以下返回代码：


- +2 - 呼叫没有限制
- +1 - 呼叫有限制并被 callcontrol 跟踪
- -1 - 信用不足，无法进行呼叫
- -2 - 呼叫被另一个进行中的呼叫锁定
- -3 - 重复的 callid
- -4 - 呼叫限制已达到
- -5 - 内部错误（消息解析、通信、...）


此函数可用于 REQUEST_ROUTE。


```c title="使用 call_control 函数"
...
if ($avp(805) != NULL) {
    # diverter AVP 已设置，用作计费方
    $avp(billing_party_domain) = $(avp(805){uri.domain});
} else {
    $avp(billing_party_domain) = $fd;
}

if (is_method("INVITE") && !has_totag() &&
    is_domain_local($avp(billing_party_domain))) {
    call_control();
    switch ($retcode) {
    case 2:
        # 无限制的呼叫
    case 1:
        # 有限制且受 callcontrol 管理的呼叫
        break;
    case -1:
        # 信用不足（预付费呼叫）
        sl_send_reply(402, "Not enough credit");
        exit;
        break;
    case -2:
        # 被另一个进行中的呼叫锁定（预付费呼叫）
        sl_send_reply(403, "Call locked by another call in progress");
        exit;
        break;
    case -3:
        # 重复的 callid
        sl_send_reply(400, "Duplicated callid");
        exit;
        break;
    case -4:
        # 达到呼叫限制
        sl_send_reply(503, "Too many concurrent calls");
        exit;
        break;
    default:
        # 内部错误（消息解析、通信、...）
        if (PREPAID_ACCOUNT) {
            xlog("Call control: internal server error\n");
            sl_send_reply(500, "Internal server error");
            exit;
        } else {
            xlog("L_WARN", "Cannot set time limit for postpaid call\n");
        }
    }
}
t_relay();
...
        
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0 版授权
