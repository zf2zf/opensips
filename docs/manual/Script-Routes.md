---
title: "路由类型"
description: "请求路由块。它包含一组对 SIP 请求要采取的操作。"
---

**OpenSIPS** 路由逻辑使用多种类型的路由。每种路由类型由特定事件触发，允许您处理特定类型的消息（请求或回复）。

---

## route

请求路由块。它包含一组对 SIP 请求要采取的操作。

**触发条件**：从网络接收外部请求。

**处理**：触发的 SIP 请求。

**类型**：最初是无状态的，可能通过使用 TM 函数强制为有状态。

**默认操作**：如果请求既不被转发也不被回复，路由将在结束时简单丢弃该请求。

主 'route' 块由 'route`{...}`' 或 'route[0]`{...}`' 标识，为每个 SIP 请求执行。

主路由块执行后的隐式操作是丢弃 SIP 请求。要发送回复或转发请求，必须在路由块内调用显式操作。

使用示例：
```c

    route {
         if(is_method("OPTIONS")) {
            # send reply for each options request
            sl_send_reply(200, "OK");
            exit();
         }
         route(1);
    }
    route[1] {
         # forward according to uri
         forward();
    }

```

请注意，如果从 'branch_route[Y]' 调用 'route(X)'，则在 'route[X]' 中只是分别处理每个分支，而不是像在主路由中那样一起处理所有分支。

路由可以返回一组值，这些值随后可以使用 [`$return`](https://docs.opensips.org/manual/devel/script-corevar#return) 变量从路由的调用上下文中检索。

传递值示例：
```c

    route {
         route(query);
         xlog("Query returned id $return(0) with $return(1) values\n");
    }
    route[query] {
         # perform a query for information and store the information in $var(id) and $var(values)
         return(1, $var(id), $var(values));
    }

```
请注意，return 的第一个参数始终是返回代码，不能使用 `$return()` 变量检索。

---

## branch_route

请求分支路由块。它包含一组对 SIP 请求的每个分支要采取的操作。

**触发条件**：准备一个新分支（请求的分支）；分支格式良好，但尚未发出。

**处理**：SIP 请求（带有分支特性，如 RURI、分支标志）

**类型**：有状态

**默认操作**：如果分支未被丢弃（通过 "drop" 语句），分支将自动发出。

它仅在通过 t_on_branch("branch_route_index") 配置后由 TM 模块执行。

使用示例：
```c

    route {
        lookup("location");
        t_on_branch("1");
        if(!t_relay()) {
            sl_send_reply(500, "Internal Server Error");
        }
    }
    branch_route[1] {
        if($ru=~"10\.10\.10\.10") {
            # discard branches that go to 10.10.10.10
            drop();
        }
    }

```

---

## failure_route

失败事务路由块。它包含一组对每个仅收到负面回复（>=300）的分支事务要采取的操作。

**触发条件**：收到或生成（内部）完成事务的负面回复（所有分支都以负面回复终止）

**处理**：原始 SIP 请求（已发出）

**类型**：有状态

**默认操作**：如果没有生成新分支或没有强制回复，默认情况下，胜出的回复将被发送回 UAC。

'failure_route' 仅在通过 t_on_failure("failure_route_index") 配置后由 TM 模块执行。

请注意，在 'failure_route' 中，处理的是发起事务的请求，而不是其回复。

使用示例：
```c

    route {
        lookup("location");
        t_on_failure("1");
        if(!t_relay()) {
            sl_send_reply(500, "Internal Server Error");
        }
    }
    failure_route[1] {
        if(is_method("INVITE")) {
             # call failed - relay to voice mail
             t_relay("udp:voicemail.server.com:5060");
        }
    }

```

---

## onreply_route

回复路由块。它包含一组对 SIP 回复要采取的操作。

**触发条件**：从网络收到回复

**处理**：收到的回复

**类型**：有状态（如果绑定到事务）或无状态（如果是全局回复路由）。

**默认操作**：如果回复未被丢弃（只有临时回复可以），它将被注入并由事务引擎处理。

有三种类型的 onreply 路由：

* **全局** - 它捕获 OpenSIPS 收到的所有回复，不需要任何特殊配置（简单定义即可）——命名为 'onreply_route `{...}`' 或 'onreply_route[0] `{...}`'。注意：此路由不知道 SIP 事务（回复未与事务匹配），因此此路由中不可用事务数据。

* **per request/transaction** - 它捕获属于某个事务的所有收到的回复，需要在请求时间的 REQUEST ROUTE 中通过 "t_on_reply()" 配置（通过）——命名为 'onreply_route[N] `{...}`'。

* **per branch** - 它仅捕获属于事务中某个分支的回复。它也需要在请求时间的 BRANCH ROUTE 中（当处理某个传出分支时）通过 "t_on_reply()" 配置——命名为 'onreply_route[N] `{...}`'。

某些 'onreply_route' 块可以由 TM 模块为特殊回复执行。为此，必须为应在其内处理回复的 SIP 请求配置 'onreply_route'，通过 t_on_reply("onreply_route_index")。

```c

route {
        $ru = "sip:bob@opensips.org";  # first branch
        $msg.branch = "sip:alice@opensips.org"; # second branch

        t_on_reply("global"); # the "global" reply route
                              # is set the whole transaction
        t_on_branch("1");

        t_relay();
}

branch_route[1] {
        if ($rU=="alice")
                t_on_reply("alice"); # the "alice" reply route
                                      # is set only for second branch
}

onreply_route {
        xlog("OpenSIPS received a reply from $si\n");
}

onreply_route[alice] {
        xlog("received reply on the branch from alice\n");
}

onreply_route[global] {
        if (t_check_status("1[0-9][0-9]")) {
                setflag("PROVISIONAL_REPLY");
                log("provisional reply received\n");
                if (t_check_status("183"))
                        drop;
        }
}

```

---

## error_route

当 SIP 请求处理期间发生解析错误，或脚本 [assert](https://docs.opensips.org/manual/devel/script-corefunctions#assert) 失败时，会自动执行错误路由。它允许管理员决定如何处理此类错误情况。

> [!IMPORTANT]
> 由于这仅对 SIP 请求触发，OpenSIPS 必须能够正确解析 SIP 消息的第一行。因此，第一行中的任何语法错误都不会触发此路由（因为 OpenSIPS 将无法判断是回复还是请求）。

**触发条件**："route" 中的解析错误

**处理**：失败的请求

**类型**：无状态（推荐）

**默认操作**：丢弃请求。

在 error_route 中，以下伪变量可用于获取错误详情：
* `$(err.class)` - 错误类别（现在对于解析错误为 '1'）
* `$(err.level)` - 错误严重级别
* `$(err.info)` - 描述错误的文本
* `$(err.rcode)` - 建议的回复代码
* `$(err.rreason)` - 建议的回复原因短语

```text

  error_route {
     xlog("--- error route class=$(err.class) level=$(err.level)
            info=$(err.info) rcode=$(err.rcode) rreason=$(err.rreason) ---\n");
     xlog("--- error from [$si:$sp]\n+++++\n$mb\n++++\n");
     sl_send_reply($err.rcode, $err.rreason);
     exit;
  }

```

---

## local_route

当 TM 内部生成新的 SIP 请求时（无 UAC 端），会自动执行本地路由。这是一个用于消息检查、计费和应用于消息头的最后更改的路由。不允许使用路由和信令功能。

**触发条件**：TM 生成全新请求

**处理**：新请求

**类型**：有状态

**默认操作**：发送请求

```c

  local_route {
     if (is_method("INVITE") && $ru=~"@foreign.com") {
        append_hf("P-hint: foreign request\r\n");
        exit;
     }
     if (is_method("BYE") ) {
        acc_log_request("internally generated BYE");
     }
  }

```

---

## startup_route

**startup_route** 仅在 OpenSIPS 启动时执行一次，在 SIP 消息处理开始之前。如果需要一些初始化操作，比如在缓存中加载一些数据以简化未来的处理，这很有用。请注意，与其他路由不同，此路由不是由消息接收触发的，因此这里可以调用的函数必须不处理消息。

**触发**：启动时，在监听器进程启动之前。

**处理**：初始化函数。

```c

  startup_route {
    sql_query_one("SELECT gwlist FROM routing_rules WHERE ruleid = 1", "$avp(gateway_list)");
    cache_store("local", "rule1", "$avp(gateway_list)");
  }

```

---

## timer_route

**timer_route** 是一个按配置的时间间隔定期执行的路由（在名称旁边指定，以秒为单位）。与 *startup_route* 类似，此路由不处理 SIP 消息。允许有多个计时器路由（可能在不同的运行间隔）。

**触发条件**：*timer* 工作进程。

**处理**：执行周期性、重复处理的函数。

> [!NOTE]
> 当 OpenSIPS 启动时，每个 timer_route 在 `<interval>` 秒后**首次执行**！

```c

  timer_route[gw_update, 300] {
    sql_query_one("SELECT gwlist FROM routing_rules WHERE ruleid = 1", "$avp(gateway_list)");
    $shv(gateway_list) = $avp(gateway_list);
  }

```

---

## event_route
**event_route** 由 OpenSIPS 事件接口使用，在触发事件时执行脚本代码。路由名称是必须由该路由处理的事件。路由本身相对于触发时刻异步执行。

**触发条件**：当事件接口引发具有相同名称的事件时，由 OpenSIPS 核心触发

**处理**：触发的事件

**类型**：无状态（推荐）

**默认操作**：当事件引发时不执行任何脚本代码。

```text

  event_route[E_PIKE_BLOCKED] {
    xlog("The E_PIKE_BLOCKED event was raised\n");
  }

```
