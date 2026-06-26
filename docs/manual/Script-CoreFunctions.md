---
title: "核心函数"
description: "本节列出了 OpenSIPS 核心为脚本使用（用于 opensips.cfg）导出的所有函数。"
---

本节列出了 **OpenSIPS** 核心为脚本使用（用于 opensips.cfg）导出的所有函数。

## add_local_rport()

向服务器生成的 Via 头添加 'rport' 参数（有关其含义，请参阅 RFC3581）。它仅影响当前处理的请求。

使用示例：

```text
add_local_rport()
```

## assert(statement, [description])

仅在 [enable_asserts](https://docs.opensips.org/manual/devel/script-coreparameters#mpath) 设置为 *true* 时有效。如果给定表达式求值为 *false*，则停止脚本执行，并执行 [error_route](https://docs.opensips.org/manual/devel/script-routes#error_route)。如果启用了 [abort_on_assert](https://docs.opensips.org/manual/devel/script-coreparameters#dns_try_ipv6)，OpenSIPS 也将关闭。

使用示例：
```text

    $var(i) = "1";
    $var(i) += "11";
    assert($var(i) == "111");

    $var(i) = 1;
    $var(i) += 11;
    assert($var(i) == 12);

    assert($ua != "friendly-scanner", "Forbidden UA: \"friendly-scanner\"");

```

## append_branch([uri], [qvalue])

> [!WARNING]
> 即将废弃，由 [append_msg_branch()](#append_msg_branch) 替代。

添加一个新的消息分支，从而通过新条目扩展目标集合。不同之处在于，当前 URI 被用作新条目。

不带参数时，函数将当前 URI 复制到一个新分支。因此，保留主分支（URI）供进一步操作。

带参数时，函数将参数中的 URI 复制到一个新分支。因此，当前 URI 不会被操作。

请注意，如果在 previously received 6XX 响应后，在 "on_failure_route" 块中附加新分支是不可能的（这将违反 RFC 3261）。

参数：
* *uri* (string, 可选)
* *qvalue* (string, 可选)

使用示例：
```text

    # if someone calls B, the call should be forwarded to C too.
    #
    if ($rm=="INVITE" && $ru=~"sip:B@xx.xxx.xx ")
    {
        # copy the current branch (branches[0]) into
        # a new branch (branches[1])
        append_branch();
        # all URI manipulation functions work on branches[0]
        # thus, URI manipulation does not touch the 
        # appended branch (branches[1])
        seturi("sip:C@domain");
        
        # now: branch 0 = C@domain
        #      branch 1 = B@xx.xx.xx.xx
        
        # and if you need a third destination ...
        
        # copy the current branch (branches[0]) into
        # a new branch (branches[2])
        append_branch();
        
        # all URI manipulation functions work on branches[0]
        # thus, URI manipulation does not touch the 
        # appended branch (branches[1-2])
        seturi("sip:D@domain");
        
        # now: branch 0 = D@domain
        #      branch 1 = B@xx.xx.xx.xx
        #      branch 2 = C@domain
        
        t_relay();
        exit;
    };

    # You could also use append_branch("sip:C@domain") which adds a branch with the new URI:
    
    
    if(method=="INVITE" && uri=~"sip:B@xx.xxx.xx ") {
        # append a new branch with the second destination
        append_branch("sip:user@domain");
        # now: branch 0 = B@xx.xx.xx.xx
        # now: branch 1 = C@domain

        t_relay();
        exit;
}

```

## append_msg_branch(uri, [qvalue], [flags])

添加一个新的消息分支。最少需要提供 SIP URI。可选地可以提供 q 值。

"inherite" 可选标志可以决定其他分支属性（duri, q, path, socket, bflags）是否从 RURI 分支继承。如果不继承，所有这些属性将在新创建的分支中为 NULL（并且该分支将只有一个 RURI 字段，没有其他内容）。

## avp_print()

打印内存中所有 AVP 的列表。这只是一个辅助/调试函数。

## cache_store(storage_id, attribute, value, [timeout])

在内存缓存式存储系统中设置属性的新值。如果属性在 memcache 中不存在，它将以给定值插入；如果已存在，其值将被新值替换。该函数可以可选地接受一个额外的参数，即属性的超时时间（或生存时间）——超过生存时间后，属性会自动从 memcache 中清除。如果 "timeout" 省略或值为 0，则该属性/值对永不过期。

如果新属性成功插入，函数返回 true。

参数：
* *storage_id* (string)
* *attribute* (string)
* *value* (string)
* *timeout* (int, 可选)

```c

cache_store("local", "total_minutes_$fU", "$avp(mins)", 1200);

OR

modparam("cachedb_redis", "cachedb_url", "redis:cluster1://194.168.4.134:6379/")
...
cache_store("redis:cluster1", "passwd_$tu", "$var(x)");

```

更多复杂示例请参阅 [Key-Value Interface Tutorial](https://docs.opensips.org/tutorials-keyvalueinterface)。

## cache_remove(storage_id, attribute)

从内存缓存式存储系统中移除一个属性。仅当 *storage_id* 无效时函数返回 false。

参数：
* *storage_id* (string)
* *attribute* (string)

```c

cache_remove("local", "total_minutes_$fU");

OR

modparam("cachedb_redis", "cachedb_url", "redis:cluster1://194.168.4.134:6379/")
...
cache_remove("redis:cluster1", "total_minutes_$fU");

```

更多复杂示例请参阅 [Key-Value Interface Tutorial](https://docs.opensips.org/tutorials-keyvalueinterface)。

## cache_fetch(storage_id, attribute, result)

从内存缓存式存储系统中获取属性的值。成功获取时，结果将存储在 **result_pv** 指定的变量中。

如果找到属性且其值成功返回，函数返回 *true*。

参数：
* *storage_id* (string)
* *attribute* (string)
* *result_pv* (var)

```c

cache_fetch("local", "credit_$fU", $var(ret));

OR

modparam("cachedb_redis", "cachedb_url", "redis:cluster1://194.168.4.134:6379/")
...
cache_fetch("redis:cluster1", "credit_$fU", $var(ret));

```

更多复杂示例请参阅 [Key-Value Interface Tutorial](https://docs.opensips.org/tutorials-keyvalueinterface)。

## cache_counter_fetch(storage_id, counter_attribute, result)

此函数从内存缓存式存储系统中获取计数器的值。结果（如果有）将存储在 **result** 指定的变量中。

如果找到属性且其值返回，函数返回 true。

参数：
* *storage_id* (string)
* *attribute* (string)
* *result* (var)

```c

cache_counter_fetch("local", "my_counter", $var(counter_val));

OR

modparam("cachedb_redis", "cachedb_url", "redis:cluster1://194.168.4.134:6379/")
...
cache_fetch("redis:cluster1", "my_counter", $var(redis_counter_val));

```

## cache_add( storage_id, attribute, increment, expire, [new_val])

在支持此操作的内存缓存式存储系统中递增一个属性。如果属性不存在，它将以 **increment** 的值创建。

如果递增失败，函数返回 false。

参数：
* *storage_id* (string)
* *attribute* (string)
* *increment* (int)
* *expire* (int) - 如果大于 0，密钥也将在指定秒数后过期
* *new_val* (var, 可选) - 用于获取计数器新值的变量。

```c

modparam("cachedb_redis", "cachedb_url", "redis:cluster1://194.168.4.134:6379/")
...
cache_add("redis:cluster1", "my_counter", 5, 0);

```

更多复杂示例请参阅 [Key-Value Interface Tutorial](https://docs.opensips.org/tutorials-keyvalueinterface)。

## cache_sub(storage_id, attribute, decrement, expire, [new_val])

在支持此操作的内存缓存式存储系统中递减一个属性。

如果递减失败，函数返回 false。

参数：
* *storage_id* (string)
* *attribute* (string)
* *increment* (int)
* *expire* (int) - 如果大于 0，密钥也将在指定秒数后过期
* *new_val* (var, 可选) - 用于获取计数器新值的变量。

```c

modparam("cachedb_redis", "cachedb_url", "redis:cluster1://194.168.4.134:6379/")
...
cache_sub("redis:cluster1", "my_counter", 5, 0);

```

更多复杂示例请参阅 [Key-Value Interface Tutorial](https://docs.opensips.org/tutorials-keyvalueinterface)。

## cache_raw_query(storage_id, raw_query, result)

函数运行提供的原始查询（使用后端相关语言），并将结果（如有）返回到 *result* 提供的 AVP（或 AVP 列表）中。如果查询没有结果，此参数可能缺失。

如果查询失败，函数返回 false。

参数：
* *storage_id* (string)
* *raw_query* (string)
* *result* (string, 可选, 不展开)

```text

...
cache_raw_query("mongodb", "{ \"op\" : \"count\",\"query\": { \"username\" : $rU} }", "$avp(mongo_count_result)");
...

```

更多复杂示例请参阅 [Key-Value Interface Tutorial](https://docs.opensips.org/tutorials-keyvalueinterface)。

## break()

自 v0.10.0-dev3 起，'break' 不能再来停止路由的执行。唯一可以使用的地方是结束 'switch' 语句中的 'case' 块。现在必须使用 'return' 来代替旧的 'break'。

'return' 和 'break' 现在具有与 c/shell 中相似的含义。

## construct_uri(proto,[user],domain,[port],[extra],result)
该函数根据接收到的参数构建一个有效的 SIP URI。结果（如有）将存储在 **result** AVP 变量中。
如果您想省略 SIP URI 的某部分，只需省略相应的参数。

参数：
* *proto* (string)
* *user* (string, 可选)
* *domain* (string)
* *port* (string, 可选)
* *extra* (string, 可选)
* *result* (var)

使用示例：
```text

construct_uri("$var(proto)", "vlad", "$var(domain)", "", "$var(params)",$avp(s:newuri));
xlog("Constructed URI is <$avp(s:newuri)> \n");

```

## drop()

停止执行配置脚本并改变之后执行的隐式操作。

如果函数在 'branch_route' 中被调用，则该分支被丢弃（'branch_route' 的隐式操作是转发请求）。

如果函数在 'onreply_route' 中被调用，则任何临时响应都被丢弃（'onreply_route' 的隐式操作是根据 Via 头将响应发送回上游）。

使用示例：

```c
onreply_route {
if($rs=="183") {
drop();
}
}
```

## exit()

停止执行配置脚本——它的行为与 return(0) 相同。它不影响脚本执行后要采取的隐式操作。

```bash
route {
if (route(2)) {
xlog("L_NOTICE","method $rm is INVITE\n");
} else {
xlog("L_NOTICE","method is $rm\n");
};
}
```

```c
route[2] {
if (is_method("INVITE")) {
return(1);
} else if (is_method("REGISTER")) {
return(-1);
} else if (is_method("MESSAGE")) {
sl_send_reply("403","IM not allowed");
exit;
};
}
```

## force_rport()
Force_rport() 将 rport 参数添加到第一个 Via 头。因此，**OpenSIPS** 将把接收到的 IP 端口添加到 SIP 消息中最上面的 Via 头，即使客户端没有表明支持 rport。这使得后续 SIP 消息能够稍后在 SIP 事务中返回到正确的端口。

rport 参数在 RFC 3581 中定义。

使用示例：

```text
force_rport();
```

## force_send_socket(proto:address[:port])

强制 **OpenSIPS** 从指定套接字发送消息（它必须是 **OpenSIPS** 正在监听的套接字之一）。如果协议不匹配（例如 UDP 消息"强制"到 TCP 套接字），则使用相同协议的最接近的套接字。

参数：
* *socket* (string)

使用示例：

```text
force_send_socket("tcp:10.10.10.10:5060");
```

## force_tcp_alias([port_alias])

为当前 TLS（或 WSS、TCP、WS）连接（源 IP + **源端口** + 传输协议）启用 TCP 连接重用（RFC 5923），无论 Via 头字段是否包含 *";alias"* 参数。所有向相同（源 IP + **Via 端口** + 传输协议）对发送的后向 SIP 请求都将被强制通过此连接，只要它保持打开状态。此函数（以及 RFC 5923）的主要目的是最小化 SIP 代理必须设置的 TLS 连接数，因为 TLS 密码协商阶段的 CPU 开销很大。

参数：
* *port_alias* (int, 可选)

  

> [!WARNING]
> 不要对最终用户发起的连接执行 **force_tcp_alias()**（他们很可能按一个或多个公共 IP 分组），因为这会为呼叫劫持创建一个开放向量！

## forward(destination)

以无状态模式将 SIP 请求转发到给定目的地。格式为 [proto:]host[:port]。Host 可以是 IP 或主机名；支持的协议有 UDP、TCP 和 TLS。（对于 TLS，您需要将 TLS 支持编译到核心中）。
如果未指定 proto 或 port，将使用 NAPTR 和 SRV 查找来确定它们（如果可能）。

参数：
* *destination* (string, 可选) - 如果缺失，转发将基于 RURI 进行。

使用示例：

```text
forward("10.0.0.10:5060");
#or
forward();
```

## get_timestamp(sec_avp,usec_avp)

从单个系统调用返回当前时间戳、当前秒的秒数和微秒数。

参数：
* *sec_avp* (var)
* *usec_avp* (var)

使用示例：

```text
get_timestamp($avp(sec),$avp(usec));
```

## isdsturiset()

测试 dst_uri 字段（下一跳地址）是否已设置。

使用示例：

```text
if(isdsturiset()) {
log("dst_uri is set\n");
};
```

## isflagset(string)

测试当前处理的请求是否设置了标志。

更多信息请参阅 [Flags Documentation](Script-Flags.md)。

参数：
* *flag* (string, 静态)

使用示例：

```text

    if (isflagset("NAT_PING"))
        log("flag NAT_PING is set\n");

```

## isbflagset(flag, [branch_idx])

测试特定分支是否设置了标志。"branch_idx" 标识要测试标志的分支——它必须是一个正数。分支索引 0 指向 RURI 分支。如果此参数缺失，默认使用 0 分支索引。

有关脚本标志的更多信息，请参阅 [Flags Documentation](Script-Flags.md)。

参数：
* *flag* (string, 静态)
* *branch_idx* (int, 可选)

使用示例：

```text

    if (isbflagset(1, "NAT_PING"))
        log("flag NAT_PING is set in branch 1\n");

```

## is_myself(host, [port])

测试主机和可选端口是否代表 OpenSIPS 正在监听的地址之一。这检查 OpenSIPS 配置文件中设置的本地 IP 地址、主机名和别名的列表。

参数：
* host (string)
* port (int, 可选)

使用示例：

```bash
if (is_myself($rd, $rp)
xlog("the request is for local processing\n");
```

## log([level,] string)

将文本消息写入标准错误终端或 syslog。您可以将日志级别指定为第一个参数。

使用示例：

```text
log("just some text message\n");
```

## move_branch([src_idx], [dst_idx] [, keep])

将附加到 **src_idx** 分支的全部信息移动到 **dst_idx** 分支。**src_idx** 和 **dst_idx** 都应该是整数值，并且应该表示一个有效的分支索引。如果未提供或具有负值，则考虑主/消息分支。
默认情况下，函数在移动后删除 **src_idx** 分支，并移动所有后续分支。但是，如果函数的第三个参数是 **keep** 字符串，则不会删除该分支，而只是复制到 **dst_idx** 分支。

## next_branches()

向请求添加一个新的目标集，其中包含序列化分支中所有最高优先级类联系人（基于 'q' 值）（请参阅 serialize_branches()）。如果从路由块调用，它会用第一个联系人重写请求 URI，并将剩余联系人添加为并行分支。如果从失败路由块调用，则将所有联系人添加为并行分支。所有使用的联系人都会从序列化分支中删除。

如果至少为一个联系人添加了请求的目标集则返回 true——如果其他分支仍待处理返回 1，如果没有其他分支剩余用于未来处理则返回 2——简而言之，如果为 2：这是最后一个分支，如果为 1：其他将跟随。如果没有做任何事情则返回 false（没有更多序列化的分支）。

使用示例：

```text
next_branches();
```

## prefix(str)

在 R-URI 的用户名前面添加字符串参数。

参数：
* *str* (string)

使用示例：

```text
prefix("00");
```

## pv_printf(pv, fmt_str)

将格式字符串 'fmt_str' 打印到 AVP 'pv' 中。'fmt_str' 参数可以包含 **OpenSIPS** 中定义的任何伪变量。'pv' 可以是任何可写的伪变量——例如：AVP、VAR、 `$ru`、`$rU`、`$rd`、`$du`、`$br`、`$fs`。'

参数：
* *pv* (var)
* *string* (string)

使用示例：

```text
pv_printf($var(x), "r-uri: $ru");
pv_printf($avp(i:3), "from uri: $fu");
```

## raise_event(event, [attrs], [vals])

通过 OpenSIPS 事件接口从脚本引发事件。

此函数为该事件的所有订阅者触发事件，不管使用的传输模块是什么。

参数：
* *event* (string) - 应该引发的事件的名称
* *attrs* (var, 可选) - 包含属性名称的 AVP；如果此参数缺失且提供了 *vals*，属性将被写为数组（位置）参数在 JSON-RPC payload 中
* *vals* (var, 可选) - 附加到事件的值的 AVP；如果此参数缺失，即使提供了 *attrs* 参数，引发的事件也不会有任何属性。

使用示例（引发没有属性的事件）：

```text

raise_event("E_NO_PARAM");

```

使用示例（引发带有两个属性的事件）：

```text

$avp(attr-name) = "param1";
$avp(attr-name) = "param2";
$avp(attr-val) = 1;
$avp(attr-val) = "2";
raise_event("E_TWO_PARAMS", $avp(attr-name), $avp(attr-val));

```

使用示例（引发带有两个未命名属性的事件）：

```text

$avp(attr-val) = 1;
$avp(attr-val) = "2";
raise_event("E_TWO_PARAMS", , $avp(attr-val));

```

## remove_msg_branch(branch_idx)

移除给定的分支。
一旦分支被移除，所有后续分支都会移位（即如果移除分支 n，则旧的 n+1 分支成为新的 n 分支，旧的 n+2 分支成为 n+1，依此类推）。

参数：
* *branch_idx* (int)

使用示例（移除所有 URI 主机名为 "127.0.0.1" 的分支）：

```bash

$var(i) = 0;
while ($(branch(uri)[$var(i)]) != null) {
   xlog("L_INFO","$$(branch(uri)[$var(i)])=[$(branch(uri)[$var(i)])]\n");
   if ($(branch(uri)[$var(i)]{uri.host}) == "127.0.0.1") {
       xlog("L_INFO","removing branch $var(i) with URI=[$(branch(uri)[$var(i)])]\n");
       remove_msg_branch($var(i));
   } else {
       $var(i) = $var(i) + 1;
   }
}

```

## return(int)

return() 函数允许您从调用的 route() 块返回任何整数值。
您可以使用 "`$retcode`" 变量测试 route 返回的值。

return(0) 与 "exit()" 相同。

在布尔表达式中：

  * 负数和零为 FALSE
  * 正数为 TRUE

使用示例：

```text

route {
  if (route(2)) {
    xlog("L_NOTICE","method $rm is INVITE\n");
  } else {
    xlog("L_NOTICE","method $rm is REGISTER\n");
  };
}

```
```c

route[2] {
  if (is_method("INVITE")) {
    return(1);
  } else if (is_method("REGISTER")) {
    return(-1);
  } else {
    return(0);
  };
}

```

## resetdsturi()

将 dst_uri filed 的值设置为 NULL。dst_uri 字段通常在 loose_route() 或 lookup("location") 之后设置，如果联系人地址在 NAT 后面。

使用示例：

```text
resetdsturi();
```

## resetflag(flag)

重置当前处理消息的标志（取消设置其值）。

更多信息请参阅 [Flags Documentation](Script-Flags.md)。

参数：
* *flags* (string, 静态)

使用示例：

```text

    resetflag("NAT_PING");

```

## resetbflag(flag, [branch_idx])

重置特定分支的标志（取消设置其值）。"branch_idx" 标识要重置标志的分支——它必须是一个正数。分支索引 0 指向 RURI 分支。如果此参数缺失，默认使用 0 分支索引。

参数：
* *flag* (string, 静态)
* *branch_idx* (int, 可选)

有关脚本标志的更多信息，请参阅 [Flags Documentation](Script-Flags.md)。

使用示例：
```text

    resetbflag(1, "NAT_PING");
    # or
    resetbflag("NAT_PING"); # same as resetbflag(0, "NAT_PING")

```

## revert_uri()

将 R-URI 设置为请求被服务器接收时的 R-URI 值（撤销对 R-URI 的所有更改）。

使用示例：

```text
revert_uri();
```

## set_via_handling(flags)

使用参数的值重写 R-URI 的域部分。R-URI 的其他部分（如用户名、端口和 URI 参数）保持不变。

参数：
* *flags* (string) - 逗号分隔的命名标志列表
  * `force-rport` - 向第一个 Via 头添加 rport 参数；因此，**OpenSIPS** 将把接收到的 IP 端口添加到 SIP 消息中最上面的 Via 头，即使客户端没有表明支持 rport。这使得后续 SIP 消息能够稍后在 SIP 事务中返回到正确的端口。
  * `add-local-rport ` - 向服务器生成的 Via 头添加 'rport' 参数（有关其含义，请参阅 RFC3581）；它仅影响当前处理的请求。
  * `reply-to-via` - 将回复路由回顶部 VIA 中的 IP:port，而不是请求的 src IP:port
  * `force-tcp-alias` - 请参阅 [force_tcp_alias()](#force_tcp_alias) 函数

使用示例：

```text
set_via_handling("force-rport,reply-to-via");
```

## sethost(host)

使用参数的值重写 R-URI 的域部分。R-URI 的其他部分（如用户名、端口和 URI 参数）保持不变。

参数：
* *host* (string)

使用示例：

```text
sethost("1.4.1.4");
```

## sethostport(hostport)

使用参数的值重写 R-URI 的域部分和端口。R-URI 的其他部分（如用户名和 URI 参数）保持不变。

参数：
* *hostport* (string)

使用示例：

```text
sethostport("1.4.1.4:5080");
```

## setuser(user)

使用参数的值重写 R-URI 的用户部分。

参数：
* *user* (string)

使用示例：

```text
setuser("newuser");
```

## setuserpass(pass)

使用参数的值重写 R-URI 的密码部分。

参数：
* *pass* (string)

使用示例：

```text
setuserpass("my_secret_passwd");
```

## setport(port)

使用参数的值重写/设置 R-URI 的端口部分。

参数：
* *port* (string)

使用示例：

```text
setport("5070");
```

## seturi(str)

重写请求 URI。

参数：
* *uri* (string)

使用示例：

```text
seturi("sip:test@opensips.org");
```

## route(name [, param1 [, param2 [, ...] ] ] )

此函数用于运行脚本中声明的 'name' 路由的代码。可选地，它可以接收多个参数（最多 7 个），这些参数可以使用 '`$param(idx)`' 伪变量检索。

路由名称是标识符格式，参数可以是整数、字符串或伪变量。

使用示例：

```text
route(HANDLE_SEQUENTIALS);
route(HANDLE_SEQUENTIALS, 1, "param", $var(param));
```

## script_trace([log_level, pv_format_string, [info]])

此函数启动脚本跟踪——这有助于更好地理解 OpenSIPS 脚本中的执行流程，例如执行了什么函数、在哪一行等。此外，随着脚本执行的进展，您还可以跟踪伪变量的值。

脚本中启用脚本跟踪的块将为每个单独的操作打印一行（例如赋值、条件测试、模块函数、核心函数等）。可以通过指定 **pv_format_string** 来监控多个伪变量（例如 "`$ru`---`$avp(var1)`"）。

通过将额外的纯字符串——**info_string**——指定为第三个参数，可以区分（标记）脚本不同区域产生的日志。

要禁用脚本跟踪，只需执行 script_trace()。否则，跟踪将在顶级路由结束时自动停止。

参数：
* *log_level* (int, 可选)
* *pv_format_string* (string, 可选)
* *info* (string, 静态, 可选)

使用示例：
```text
script_trace( 1, "$rm from $si, ruri=$ru", "me");
```

将产生：
```text

    [line 578][me][module consume_credentials] -> (INVITE from 127.0.0.1 , ruri=sip:111211@opensips.org)
    [line 581][me][core setbflag] -> (INVITE from 127.0.0.1 , ruri=sip:111211@opensips.org)
    [line 583][me][assign equal] -> (INVITE from 127.0.0.1 , ruri=sip:111211@opensips.org)
    [line 592][me][core if] -> (INVITE from 127.0.0.1 , ruri=sip:tester@opensips.org)
    [line 585][me][module is_avp_set] -> (INVITE from 127.0.0.1 , ruri=sip:tester@opensips.org)
    [line 589][me][core if] -> (INVITE from 127.0.0.1 , ruri=sip:tester@opensips.org)
    [line 586][me][module is_method] -> (INVITE from 127.0.0.1 , ruri=sip:tester@opensips.org)
    [line 587][me][module trace_dialog] -> (INVITE 127.0.0.1 , ruri=sip:tester@opensips.org)
    [line 590][me][core setflag] -> (INVITE from 127.0.0.1 , ruri=sip:tester@opensips.org) 

```

## send(destination [, headers])

以无状态模式将原始 SIP 消息发送到特定目的地。这被定义为 [proto:]host[:port]。不会对接收到的消息进行任何更改，不会添加 Via 头，除非指定了 headers 参数。Host 可以是 IP 或主机名；支持的协议有 UDP、TCP 和 TLS。（对于 TLS，您需要将 TLS 支持编译到核心中）。如果未指定 proto 或 port，将使用 NAPTR 和 SRV 查找来确定它们（如果可能）。headers 参数应该以 '\r\n' 结尾。

参数：
* *destination* (string)
* *headers* (string, 可选)

使用示例：

```text
send("udp:10.10.10.10:5070");
send("udp:10.10.10.10:5070", "Server: opensips\r\n");
```

## serialize_branches(clear_previous[, keep_order])

获取当前为并行分叉添加的所有分支（例如使用 lookup() 或 append_branch()），以及当前分支（R-URI (`$ru`) / 出站代理 (`$du`) / q 值 (`$ru_q`) / 分支标志 / 强制路径头 / 强制发送套接字），并准备将它们改为串行分叉。排序按 "q" 降序进行。序列化的分支内部存储在 "`$avp(serial_branch)`" AVP 中——这允许它们被 "next_branches()" 函数操作，通常在失败路由中。

  

请注意，（根据 RFC3261），具有相同 "q" 值的分支在串行分叉的某个步骤中仍将并行分叉（这将导致串行与并行分叉的组合）。换句话说，此函数将清除所有添加的分支，并持续重新添加它们，只要它们具有相同的最高 "q" 值，同时将所有其他"低于最高 q"的分支扔到 "`$avp(serial_branch)`" 中。在每次 "next_branches()" 函数调用期间会发生类似的分组过程。

  

请注意，此函数不会改变当前分支（R-URI、出站代理等）——它只是使用上述分支准备串行分叉集。您可能需要在调用此函数后立即调用 "next_branches()"，请参阅下面的示例。

参数：
* *clear_previous* (int) - 如果设置为非零，在开始新集合之前将删除另一个 "serialize_branches()" 的所有先前结果（不再需要的串行分叉集）
* *keep_order* (int, 可选) - 如果设置为非零，添加的分支以及当前分支将按找到的顺序精确序列化。

使用示例：

```text

    if (!lookup("location")) {
        t_reply("480", "Temporarily Unavailable");
        exit;
    }

    serialize_branches(1);
    next_branches(); # Pop the R-URI from the serialized branches set

```

## set_advertised_address(adv_addr)

与 'advertised_address' 相同，但仅影响当前消息。如果也设置了 'advertised_address'，则此设置优先。

参数：
* *adv_addr* (string)

使用示例：

```text
set_advertised_address("opensips.org");
```

## set_advertised_port(adv_port)

与 'advertised_port' 相同，但仅影响当前消息。它优先于 'advertised_port'。

参数：
* *adv_port* (string)

使用示例：

```text
set_advertised_port("5080");
```

## setdsturi(uri)

将 dst_uri 字段显式设置为参数的值。参数必须是有效的 SIP URI。

参数：
* *uri* (string)

使用示例：

```text
setdsturi("sip:10.10.10.10:5090");
```

## setflag(flag)

为当前处理的消息设置标志。标志用于标记消息进行特殊处理（例如 ping NAT'ed 联系人、TCP 连接行为等）或保持某些状态（例如消息已认证）。OpenSIPS 脚本最多支持 32 个唯一的字符串标志。

参数：
* *flag* (string, 静态)

使用示例：

```text

    setflag("NAT_PING");

```

## setbflag(flag, [branch_idx])

为特定分支设置标志。"branch_idx" 标识要设置标志的分支——它必须是一个正数。分支索引 0 指向 RURI 分支。如果此参数缺失，默认使用 0 分支索引。OpenSIPS 脚本最多支持 32 个唯一的字符串分支标志。

有关脚本标志的更多信息，请参阅 [Flags Documentation](Script-Flags.md)。

参数：
* *flag* (string, 静态)
* *branch_idx* (int, 可选)

使用示例：

```text

    setbflag(1, "NAT_PING");
    # or
    setbflag("NAT_PING"); # same as setbflag(0, "NAT_PING")

```

## socket_belongs_to_bond( socket, bond)

此函数检查 SIP 套接字是否属于某个绑定套接字（请参阅 [绑定套接字的定义](Script-CoreParameters.md#socket)）。

参数：
* *socket* (string) 一个套接字定义，如 "proto:ip:port"
* *bond* (string) 绑定套接字的名称

使用示例：

```bash

if (socket_belongs_to_bond( $si, "internal") {
  # came from internal, must go to external
  $socket_out = "bond:external";
} else
if (socket_belongs_to_bond( $si, "external") {
  # came from external, must go to internal
  $socket_out = "bond:internal";
} else {
   send_reply(403,"Forbidden");
   exit;
}

```

## sr_check_status( group, [identifier])

检查 'status/report' 标识符状态的函数。在脚本级别确定模块或核心组件的就绪状态（如果能够提供其全部功能）非常有用。

参数：
* *group* (string)，'status/report' 组的名称（OpenSIPS 核心导出的组名为 "core"，而模块可以以其名称导出组）。
* *identifier* (string, 可选)，要检查的标识符的名称（有哪些可用的标识符取决于导出该组的各方）。此标识符的可能值为：
  * (1) 标识符的名称
  * (2) NULL，引用默认（每组）标识符（内部转换为 "main" 标识符
  * (3) "all" 引用组中的所有标识符

返回值，取决于提供的标识符值，可能是：
* (1) 给定标识符的状态
* (2) "main" 标识符的状态
* (3) 所有标识符的聚合状态，如果至少有一个标识符具有负状态则为 -1（如果所有标识符都具有正状态则为 1）

使用示例：

```text

    # check if the "pstn" identifier (the "pstn" partition) from "drouting" module is ready (data is fully loaded)
    if (st_check_status( "drouting", "pstn") ) {}

    # check if the all identifiers (all partitions) from "drouting" module are ready (data is fully loaded)
    if (st_check_status( "drouting", "all") ) {}
    

```

## strip(n)

从 R-URI 的用户名中剥离前 N 个字符（N 是参数的值）。

参数：
* *n* (int)

使用示例：

```text

    strip(3);

```

## strip_tail(n)

从 R-URI 的用户名中剥离最后 N 个字符（N 是参数的值）。

参数：
* *n* (int)

使用示例：

```text
strip_tail(3);
```

## subscribe_event(string, string [, int])

为 OpenSIPS 事件接口订阅外部应用程序的某个事件。这用于无法自行订阅的传输协议（例如 event_rabbitmq）。如果订阅不会过期，此函数应在 startup_route 中只调用一次；如果订阅应该定期续订，则应在计时器路由中调用。

参数：
* *event* (string) - 外部应用程序应收到通知的事件名称。
* *socket* (string) - 外部应用程序的套接字。请注意，此套接字应遵循已加载的事件接口传输模块的语法（例如：event_datagram, event_rabbitmq）。
* *expire* (int, 可选) - 订阅的过期时间。如果不存在，则订阅永不过期。

使用示例（永不过期的订阅者，由 RabbitMQ 模块通知）：

```c

startup_route {
    subscribe_event("E_PIKE_BLOCKED", "rabbitmq:127.0.0.1/pike");
}

```

使用示例（每 5 秒过期的订阅者，通过 UDP 通知）：

```c

timer_route[event_subscribe, 4] {
    subscribe_event("E_PIKE_BLOCKED", "udp:127.0.0.1:5051", 5);
}

```

## swap_branches([br1_idx], [br2_idx])

交换两个分支之间的信息，由 **br1_idx** 和 **br2_idx** 表示。两个值都应该是整数值，并且应该表示一个有效的分支索引。如果未提供或具有负值，则考虑主/消息分支。

## use_blacklist(bl_name)

启用作为参数接收的 DNS 黑名单名称。它的主要目的是防止由于 DNS 原因向关键 IP（如 GW）发送请求，或避免向已知不可用的目的地发送请求（临时或永久）。

参数：
* *bl_name* (string)

```text

    use_blacklist("pstn-gws");

```

## unuse_blacklist(bl_name)

禁用作为参数接收的 DNS 黑名单名称。

参数：
* *bl_name* (string)

```text

    unuse_blacklist("pstn-gws");

```

## check_blacklist_rule([bl_name], ip[, port [, proto]])

检查特定 proto:ip:port+pattern 是否匹配黑名单，或者如果未指定 *bl_name* 则匹配所有黑名单。

参数：
* *bl_name* (string, 可选) - 如果缺失，规则将与所有使用的黑名单匹配
* *ip* (string) - 要检查的 IP
* *port* (integer, 可选) - 要检查的端口；如果缺失，则认为 0，这只会匹配 0 端口规则
* *proto* (string, 可选) - 要检查的协议，或者如果应该检查任何协议则为 "any"；如果缺失，则认为 "any"，这只会匹配任何协议规则
* *pattern* (string, 可选) - 要检查的模式

```text

    if (check_blacklist("pstn-gws", $dd, $dp, $dP))
        xlog("REQUEST will be blocked\n");

```

## add_blacklist_rule([bl_name], ip[, port [, proto [, expire]]])

向黑名单添加 proto:ip:port+pattern 规则。

参数：
* *bl_name* (string) - 要添加规则的黑名单
* *ip* (string) - 要添加的 IP；如果 IP 以 '!' 开头，则整个规则被否定
* *port* (integer, 可选) - 要添加的端口；如果缺失，则使用 0/任何端口
* *proto* (string, 可选) - 要添加的协议，或者任何协议则为 "any"；如果缺失，则使用 "any"
* *pattern* (string, 可选) - 要添加的模式
* *expire* (integer, 可选) - 如果指定，以秒为单位提供规则的过期时间

```text

    add_blacklist_rule("filter", $si, $sp, "udp");

```

## del_blacklist_rule([bl_name], ip[, port [, proto]])

从黑名单中移除 proto:ip:port+pattern 规则。

参数：
* *bl_name* (string) - 要移除规则的黑名单
* *ip* (string) - 要移除的 IP；如果 IP 以 '!' 开头，则整个规则被否定
* *port* (integer, 可选) - 要移除的端口；如果缺失，则使用 0/任何端口
* *proto* (string, 可选) - 要移除的协议，或者任何协议则为 "any"；如果缺失，则使用 "any"
* *pattern* (string, 可选) - 要移除的模式

```text

    del_blacklist_rule("filter", $si, $sp, "udp");

```

## xlog([log_level, ]format_string)

允许在执行 OpenSIPS 脚本时打印各种调试/运行时/关键消息。*format_string* 参数中包含的所有伪变量都会被展开。有几个可选的日志级别可以指定。它们按照 syslog 的严重级别工作。级别名称如下：

* L_ALERT (-3)
* L_CRIT (-2)
* L_ERR (-1) - 如果省略 log_level，这是默认使用的
* L_WARN (1)
* L_NOTICE (2)
* L_INFO (3)
* L_DBG (4)

  

```text

    # a few xlog scripting examples
    xlog("Received $rm from $fu (callid: $ci)\n");
    xlog("L_ERR", "key $var(username) not found in cache!\n");

```
