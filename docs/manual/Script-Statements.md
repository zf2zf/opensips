---
title: "脚本语句"
description: "在构建路由逻辑时可以在 OpenSIPS 配置文件中使用的语句。"
---

在构建路由逻辑时可以在 **OpenSIPS** 配置文件中使用的语句。

## if

IF-ELSE 语句

原型：

```text

    if (expr) {
       actions;
    } else {
       actions;
    }

```

'expr' 应该是有效的逻辑表达式。

逻辑表达式中可使用的逻辑运算符：

* == - 等于
* != - 不等于
* =~ - 正则表达式匹配（例如 `$rU` =~ '^1800*' 是 "`$rU` 以 1800 开头"）
* !~ - 正则表达式不匹配
* \> - 大于
* \>= - 大于或等于
* \< - 小于
* \<= - 小于或等于
* && - 逻辑 AND
* || - 逻辑 OR
* ! - 逻辑 NOT
* [ ... ] - 测试运算符 - 内部可以是任何算术表达式

使用示例：

```text

    if ( is_method("INVITE") && $rp==5060 )
    {
        log("this sip message is an invite\n");
    } else {
        log("this sip message is not an invite\n");
    }

```

## switch

SWITCH 语句 - 可用于测试伪变量的值。

重要提示：'break' 只能用于标记 'case' 分支的结束（如 shell 脚本中一样）。如果您尝试在 'case' 块外部使用 'break'，脚本将返回错误——在那里您必须使用 'return'。

使用示例：
```c

    route {
        route(my_logic);
        switch ($retcode) {
        case -1:
            log("process INVITE requests here\n");
            break;
        case 1:
            log("process REGISTER requests here\n");
            break;
        case 2:
        case 3:
            log("process SUBSCRIBE and NOTIFY requests here\n");
            break;
        default:
            log("process other requests here\n");
       }

        # switch of R-URI username
        switch ($rU) {
        case "101":
            log("destination number is 101\n");
            break;
        case "102":
            log("destination number is 102\n"); # continue with 103 and 104
        case "103":
        case "104":
            log("destination number is 103 or 104\n");
            break;
        default:
            log("unknown destination number\n");
       }
    }

    route [my_logic] {
        if (is_method("INVITE"))
            return(-1);

        if (is_method("REGISTER"))
            return(1);

        if (is_method("SUBSCRIBE"))
            return(2);

        if (is_method("NOTIFY"))
            return(3);

        return(-2);
    }

```

> [!WARNING]
> 使用 'return' 时要小心——'return(0)' 停止脚本的执行。

## while

while 语句

使用示例：
```text

    $var(i) = 0;
    $var(cli) = NULL;
    while ($var(i) < 10) {
        if ($(avp(valid_clis[$var(i)]) == $fU) {
            xlog("matched the From user!\n");
            $var(cli) = $fU;
            break;
        }
        $var(i) = $var(i) + 1;
    }

```

## for each

for each 语句 - 轻松迭代索引变量或伪变量

使用示例：
```text

    $avp(arr) = 0;
    $avp(arr) = 1;
    $avp(arr) = 2;
    $avp(arr) = 3;
    $avp(arr) = 4;

    for ($var(it) in $(avp(arr)[*]))
        xlog("array value: $var(it)\n");

    # iterate through all Contact URIs from each Contact header
    for ($var(ct) in $(ct[*]))
        xlog("Contact: $var(ct)\n");

    # iterate through all Via headers of a SIP request
    for ($var(via) in $(hdr(Via)[*]))
        xlog("Found \"Via\" header: $var(via)\n");

    # iterate through all JSON documents returned by a MongoDB query
    cache_raw_query("mongodb:location", "{... find ...}", "$avp(res)");
    for ($json(contact) in $(avp(res)[*])) {
        xlog("Found: $json(contact/phone) $json(contact/email)\n");
        
        if ($json(contact/phone) =~ "^40") {
            xlog("found a cheap destination to dial\n");
            break;
        }
    }

```
