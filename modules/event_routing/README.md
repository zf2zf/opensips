---
title: "基于事件的路由模块"
description: "基于事件的路由模块（或简称 EBR 模块）提供了一种机制，允许通过 OpenSIPS Events（参见 https://opensips.org/Documentation/Interface-Events-2-3）实现脚本中不同 SIP 处理之间的通信和同步。"
---

## 管理指南


### 概述


基于事件的路由模块（或简称 EBR 模块）提供了一种机制，允许通过 OpenSIPS Events（参见 https://opensips.org/Documentation/Interface-Events-2-3）实现脚本中不同 SIP 处理之间的通信和同步。


此机制基于订阅-通知概念。任何 SIP 处理都可以订阅各种 OpenSIPS Events。引发事件时，订阅者将收到通知，因此可以使用附加到事件的数据。请注意，事件引发可能发生在完全不同的 SIP 处理上下文中，与订阅者处理完全无关。


此外，事件可以由 OpenSIPS 内部生成（预定义事件），也可以从脚本级别生成（自定义事件）。请参阅 Event Interface 文档以获取更多关于事件如何生成的信息（https://opensips.org/Documentation/Interface-Events-2-3）。


根据通知的处理方式，我们可以区分两种主要场景：


- 订阅者以异步模式等待接收通知；订阅者的处理将被挂起，并在收到通知时（或发生超时时）完全恢复。
- 订阅者在订阅后继续处理，无需任何等待。当收到通知时，将执行由订阅设置的脚本路由。请注意，此通知路由在原始处理的上下文之外执行（此路由中不继承任何内容）。触发通知的事件通过 AVP 变量在通知路由中公开。


因此，EBR 允许您的 SIP 处理进行同步或信息交换，即使这些处理在 SIP、时间或处理方面完全无关。


借助 EBR 支持，现在可以实现更高级的路由场景，这些场景需要在不同类型和时间处理和组合不同的处理，例如处理各种呼叫与处理注册或 DTMF 提取。更多信息，请参阅[示例](#usage_examples)部分。


### 依赖


#### OpenSIPS 模块


以下模块是此模块所必需的：


- *TM - 事务模块*


#### 外部库或应用程序


运行加载此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *无*。


### 导出的参数


此模块不提供任何脚本参数。


### 导出的函数


#### notify_on_event(event, filter, route, timeout)


此函数创建对给定事件的订阅。可以使用过滤器（基于事件的属性）来进一步过滤所需的通知（只有匹配过滤器的事件才会通知此订阅者）。


引发事件时，将执行给定的脚本路由（通常称为通知路由）。从订阅者处理到通知路由中，不会继承任何变量、SIP 消息、SIP 事务/对话框或任何其他上下文相关的内容。


事件属性将通过 AVP 变量在通知路由中公开，如 *$avp(attr_name) = attr_value*。


作为例外，在通知路由中，EBR 模块将提供订阅者上下文中的事务 ID。请注意，这不是事务本身，而是其 ID。有一些 TM 函数（如 *t_inject_branches*）可以基于事务 ID 对事务进行操作。当然，您需要在调用 *notify_on_event()* 函数之前在订阅者处理中创建事务。


此函数可用于 REQUEST_ROUTE。


参数：


- *event* (string) - 要订阅的事件名称
- *filter* (var) - 一个 AVP 变量，作为多值数组保存要应用于事件的所有过滤器（在通知之前）。过滤器值格式为 "key=value"，其中 "key" 必须与事件的属性名称匹配。"value" 是属性的期望值；它可以是 shell 通配符模式。例如："aor=bob@*"
- *route* (string) - 事件通知时要执行的脚本路由名称
- *timeout* (int) - 订阅在过期前保持活动的时间（秒）。注意：在其生命周期内，订阅可能会被通知多次或零次。


```c title="notify_on_event() 使用示例"
...
$avp(filter) = "aor=*@opensips.org"
notify_on_event("E_UL_AOR_INSERT",$avp(filter),"reg_done",60);
...
route[reg_done] {
	xlog("新用户 $avp(aor) 已注册到 opensips.org 域\n");
}
```


#### wait_for_event(event,filter,timeout)


与异步 [afunc wait for event](#afunc_wait_for_event) 函数完全相同，但为同步/阻塞版本。脚本执行将阻塞并等待，直到事件被传递或超时发生。


成功时函数返回 1（收到事件），错误情况返回 -1，超时情况返回 -2（未收到事件）。


此函数可用于任何类型的路由。


```c title="wait_for_event 使用示例"
...
# 阻塞直到被叫方注册
$avp(filter) = "aor="+$rU+"@"+$rd
wait_for_event("E_UL_AOR_INSERT",$avp(filter), 40);
if ($rc>0) {
	xlog("用户 $avp(aor) 现已注册\n");
	lookup("location");
	t_relay();
}
```


### 导出的异步函数


#### wait_for_event(event,filter,timeout)


与此函数类似 *notify_on_event*，此函数为给定事件和过滤器创建事件订阅者。但此函数将进行异步等待（挂起和恢复）以接收所需事件的通知。


参数的含义与 *notify_on_event* 相同。


```c title="wait_for_event 使用示例"
...
# 等待被叫方注册
$avp(filter) = "aor="+$rU+"@"+$rd
async( wait_for_event("E_UL_AOR_INSERT",$avp(filter), 40),  resume_call);
# 完成
...
route[resume_call] {
	xlog("用户 $avp(aor) 现已注册\n");
	lookup("location");
	t_relay();
}
```


### 使用示例


#### 推送通知


我们使用 *notify_on_event* 捕获被叫方新联系人注册的事件。发送呼叫到被叫方后，基于（新联系人的）通知，我们将新注册的联系人作为新分支注入到正在处理的事务中。


示意图：当我们向用户发送呼叫时，我们订阅以查看用户注册的任何新联系人。收到此类通知时，我们将新联系人作为新分支添加到（正在响铃的）用户原始事务中。


```c title="推送通知脚本"
...
route[route_to_user] {

    # 为分支注入准备事务；在订阅前创建事务是强制性的
    # 否则 EBR 模块不会将事务 ID 传递到
    # 通知路由
    t_newtran();

    # 保持事务活跃（即使所有分支都将终止），直到 FR INVITE 计时器触发（我们希望等待可能注册的新联系人）
    t_wait_for_new_branches();

    # 订阅新联系人注册事件，
    # 但仅针对我们的被叫方
    $avp(filter) = "aor="+$rU;
    notify_on_event("E_UL_CONTACT_INSERT",$avp(filter),
        "fork_call", 20);

    # 获取已注册的联系人并转发（如果有）
    if (lookup("location"))
        route(relay);
    # 如果没有可用的联系人（因此到目前为止没有创建分支），创建的事务将仍然等待新分支，由于 t_wait_for_new_branches() 函数的使用

    exit;
}

route[fork_call]
{
    xlog("用户 $avp(aor) 注册了新联系人 $avp(uri)，正在注入\n");
    # 获取 E_UL_CONTACT_INSERT 事件描述的联系人
    # 并将其作为新分支注入到原始事务中
    t_inject_branches("event");
}
...
```


#### 呼叫拾取


场景是 Alice 呼叫 Bob，Bob 没有接听，Charlie 执行呼叫拾取（从 Alice 获取呼叫）。


我们使用 *notify_on_event* 链接两个呼叫：一个从 Alice 到 Bob，另一个从 Charlie 到呼叫拾取服务。


示意图：当我们向拾取组内的用户发送呼叫时，我们订阅以查看是否有任何呼叫到拾取服务（来自同一拾取组的另一个成员）。当我们有呼叫到拾取服务时，我们从脚本引发一个事件——此事件将通知第一个呼叫，我们取消到 Bob 的分支，并注入呼叫拾取组用户（Charlie）的已注册联系人。


```c title="呼叫拾取脚本"
...
route[handle_call]
    if ($rU=="33") {
        ## 这是到拾取服务的呼叫
        ## (Charlie 呼叫 33)

        # 拒绝传入呼叫，因为我们将从原始呼叫（Alice 到 Bob）生成回拨
        t_newtran();
        send_reply(480, "Gone");

        # 引发拾取自定义事件
        # 拾取组为 1，拾取者为 Charlie（呼叫者）
        $avp(attr-name) = "group";
        $avp(attr-val) = "1";
        $avp(attr-name) = "picker";
        $avp(attr-val) = $fu;
        raise_event("E_CALL_PICKUP", $avp(attr-name), $avp(attr-val));

        exit;
    } else {

        ## 这是到订阅者的呼叫
        ## (Alice 呼叫 Bob)

        # 应用用户位置
        if (!lookup("location", "method-filtering")) {
            send_reply(404, "Not Found");
            exit;
        }

        # 为分支注入准备事务；在订阅前创建事务是强制性的
        # 否则 EBR 模块不会将事务 ID 传递到
        # 通知路由
        t_newtran();

        # 订阅呼叫拾取事件，但仅针对我们的组
        $avp(filter) = "group=1";
        notify_on_event("E_CALL_PICKUP",$avp(filter),
            "handle_pickup", 20);

        t_relay();
    }
    exit;
}

route[handle_pickup]
{
    xlog("呼叫被 $avp(picker) 拾取，正在获取其联系人\n");
    if (lookup("location","", $avp(picker))) {
        # 获取 lookup() 返回的联系人（针对 Charlie）
        # 并将它们注入到原始呼叫中，但也取消
        # 任何现有的正在响铃到 Bob 的分支
        t_inject_branches("msg","cancel");
    }
}
```


## 开发者指南


此模块不导出任何内部 API。


## 常见问题


**Q: 在哪里可以找到更多关于 OpenSIPS 的信息？**


请查看 [https://opensips.org/](https://opensips.org/)。


**Q: 在哪里可以发布关于此模块的问题？**


首先检查您的问题是否已在我们的邮件列表中得到解答：

		关于任何稳定版 OpenSIPS 版本的电子邮件应发送至
			users@lists.opensips.org，关于开发版本的电子邮件
			应发送至 devel@lists.opensips.org。

如果您希望保密邮件，请发送至
			users@lists.opensips.org。


**Q: 如何报告 bug？**


请按照以下指南操作：
			[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用 Creative Common License 4.0 许可证
