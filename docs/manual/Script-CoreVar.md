---
title: "核心变量"
description: "OpenSIPS 变量可以很容易地在脚本中识别，因为它们的所有名称（或表示法）都以 $ 符号开头。"
---

**OpenSIPS** 提供了多种类型的变量用于路由脚本。变量类型之间的区别来自于：
* *其上下文* - 变量附加到某个上下文，例如 SIP 消息上下文、SIP 事务上下文或对话上下文。变量在该上下文存在的整个时间内都是可见的（在所有存在该上下文的脚本路由中）
* *读写状态* - 有些变量是只读的
* *值的数量* - 有些变量可以同时保持多个值

**OpenSIPS** 变量可以很容易地在脚本中识别，因为它们的所有名称（或表示法）都以 **$** 符号开头。

语法：

伪变量的完整语法是：
`$(`*`<context>`*`name`*`(subname)[index]{transformation}`*`)`

斜体写的字段是可选的。
字段含义如下：
* **name**（必需）- 伪变量名称（类型）。  
例如：var、avp、ru、DLG_status 等。
* **subname** - 给定类型的某个 pv 的标识符。  
例如：hdr(From)、avp(name)。
* **index** - 一个 pv 可以存储多个值——它可以引用值列表。如果您指定索引，则可以访问列表中的某个值。您也可以使用负值指定索引，-1 表示最后插入的，-2 表示前一个插入的。
* **transformation** - 可以对伪变量应用一系列处理操作。您可以在[此处](Script-Tran.md)找到可能的转换完整列表。转换可以级联，使用一个转换的输出作为另一个转换的输入。     
* **context** - 伪变量将在其中被求值的上下文。现在有 2 个 pv 上下文：reply 和 request。reply 上下文可以在 failure route 中使用，用于请求伪变量在回复消息的上下文中求值。如果在 reply route 中希望 pv 在相应请求的上下文中求值，则可以使用 request 上下文。

使用示例：
* 仅 **name**：`$ru`
* **Name** 和 *'subname**：`$hdr(Contact)`
* **Name** 和 **index**：`$(ct[0])`
* **Name**、**subname** 和 **index**：`$(avp(caller_dids)[2])`
* **Context** 
  * `$(<request>ru)` 从 reply route 将获取请求的 Request-URI
  * `$(<reply>hdr(Contact))` 上下文可以在 failure route 中用于访问回复中的信息

变量类型：

* [**脚本变量**](#script_variables) - 顾名思义，这些变量严格绑定到脚本路由。

* [**AVP - 属性值对**](#avp_variables) - AVP 是动态变量（作为名称），可以创建并附加到 SIP 消息或事务（如果使用有状态处理）。因此，您可以将它们视为事务级变量。

* [**引用变量**](#reference_variables) - 提供从当前上下文访问信息的变量——当前 SIP 消息、事务、对话，或从当前进程（非 SIP 信息）。

* [**转义序列**](#escape_sequences) - 用于格式化字符串的转义序列；它们实际上不是变量，而是格式化器。


## 脚本变量

**命名**：`$var(name)`

这些变量附加到脚本，在整个顶级路由执行期间（包括所有子路由）持久化。一旦顶级路由执行结束，脚本变量就会丢失，不会再被使用。另外，在首次使用时要小心初始化它们（在一个顶级路由中），因为您可能继承了垃圾数据。
脚本变量可读写，它们可以有整数值或字符串值。
脚本变量只能保存单个值。新赋值（或写操作）将覆盖现有值。


**提示**：
* 如果您想在路由中开始使用脚本变量，最好初始化为相同的值（或重置它），否则您可能会从前一个由同一进程执行的路由继承一个值。
* 脚本变量只能保存一个值。

使用示例：

```bash

$var(a) = 2;  # sets the value of variable 'a' to integer '2'
$var(a) = "2";  # sets the value of variable 'a' to string '2'
$var(a) = 3 + (7&(~2)); # arithmetic and bitwise operation
$var(a) = "sip:" + $au + "@" + $fd; # compose a value from authentication username and From URI domain

# using a script variable for tests
if( [ $var(a) & 4 ] ) {
  xlog("var a has third bit set\n");
}

```


## AVP 变量

**命名**：`$avp(name)` 或 `$(avp(name)[N])`

消息或事务最初（接收或创建时）会附加一个空的 AVP 列表。在路由脚本期间，脚本可以直接创建新的 AVP，或从脚本调用的函数可以创建新的 AVP，它们将自动附加到消息/事务。AVP 在处理事务的任何消息（回复或请求）的所有路由中都是可见的——`branch_route`、`failure_route`、`onreply_route`（对于最后一个路由，您需要启用 TM 参数 *onreply_avp_mode*）。
AVP 可读写，现有的 AVP 甚至可以被删除（移除）。
AVP 可能包含多个值——新赋值（或写操作）将向 AVP 添加一个新值；值按"最后添加先使用"的顺序保存（堆栈）。

当使用索引 "N" 时，您可以强制 AVP 返回特定值（第 N 个值）。如果未给定索引，则返回第一个值。
定义了一个特殊的索引 **append**，允许您在列表末尾添加新值（在堆栈底部）——`$(avp(name)[append])` = "last value";


**提示**：
* 要在 onreply_route 中启用 AVP，请使用 "modparam("tm", "onreply_avp_mode", 1)"
* 如果单个 AVP 使用多个值，则值的索引顺序与添加顺序相反
* AVP 是事务上下文的一部分，因此它们在事务存在的任何地方都可见。
* AVP 的值可以被删除

使用示例：
* 事务持久化示例
```c

# enable avps in onreply route
modparam("tm", "onreply_avp_mode", 1)
...
route{
...
$avp(tmp) = $Ts ; # store the current time (at request processing)
...
t_onreply("handle_reply");
t_relay();
...
}

onreply_route[handle_reply] {
	if (t_check_status("200")) {
		# calculate the setup time
		$var(setup_time) = $Ts - $avp(tmp);
	}
}

```

* 多值示例
```bash

$avp(demo) = "one";
# we have a single value

$avp(demo) = "two";
# we have two values ("two","one")

$avp(demo) = "three";
# we have three values ("three","two","one")

xlog("accessing values with no index: $avp(demo)\n");
# this will print the first value, which is the last added value -> "three"

xlog("accessing values with no index: $(avp(demo)[2])\n");
# this will print the index 2 value (third one), -> "one"

# remove the first value of the avp (lastly added one); if there is only one value, the AVP itself will be destroyed
$avp(demo) = NULL;

# delete all values and destroy the AVP
$avp(demo) := NULL;

# delete the value located at a certain index 
$(avp(demo)[1]) = NULL;

# overwrite the value at a certain index
$(avp(demo)[0]) = "zero";

```



## 引用变量

**命名**：`$name`

它们提供从 SIP 消息/事务/对话框或 OpenSIPS 内部信息访问。例如，引用变量可以允许访问处理的 SIP 消息（头、RURI、传输级信息等）或 **OpenSIPS** 内部信息（时间值、进程 PID、函数的返回代码）。根据它们提供的信息，PV 要么绑定到消息，要么什么也不绑定（全局）。
大多数引用变量是只读的，只有少数允许写操作。引用变量可能返回多个值或只有一个值，这取决于所引用信息的性质（如果可以有多个值或不能）。  
标准引用变量是只读的，返回单个值（除非文档另有说明）。

**提示**：
* 大多数引用变量由 **OpenSIPS** 核心提供，但也有模块导出此类变量（以提供特定于该模块的信息）——请查看模块文档。
* 引用变量也被称为 *伪变量* 或 *PV*。这是一个旧术语。

核心预定义的 PV 按字母顺序列出：

### SIP 请求 P-Asserted-Identity 头中的 URI - $ai

`$ai` - 请求的 P-Asserted-Identity 头中的 URI 引用（请参阅 RFC 3325）

### 认证 Digest URI - $adu

`$adu` - Authorization 或 Proxy-Authorization 头中的 URI。此 URI 用于计算 HTTP Digest Response。

### 认证领域 - $ar

`$ar` - Authorization 或 Proxy-Authorization 头中的领域

### 认证用户名用户 - $au

`$au` - Authorization 或 Proxy-Authorization 头中用户名的用户部分

### 认证用户名域 - $ad

`$ad` - Authorization 或 Proxy-Authorization 头中用户名的域部分

### 认证随机数 - $an

`$an` - Authorization 或 Proxy-Authorization 头中的随机数

### 认证响应 - $auth.resp

`$auth.resp` - Authorization 或 Proxy-Authorization 头中的认证响应

### 认证随机数 - $auth.nonce

`$auth.nonce` - Authorization 或 Proxy-Authorization 头中的随机数字符串

### 认证 cnonce - $auth.cnonce

`$auth.cnonce` - Authorization 或 Proxy-Authorization 头中的客户端随机数字符串

### 认证 opaque - $auth.opaque

`$auth.opaque` - Authorization 或 Proxy-Authorization 头中的 opaque 字符串

### 认证算法 - $auth.alg

`$auth.alg` - Authorization 或 Proxy-Authorization 头中的算法字符串

### 认证 QOP - $auth.qop

`$auth.qop` - Authorization 或 Proxy-Authorization 头中 qop 参数的值

### 认证随机数计数 (nc) - $auth.nc

`$auth.nc` - Authorization 或 Proxy-Authorization 头中随机数计数参数的值

### 认证完整用户名 - $aU

`$aU` - Authorization 或 Proxy-Authorization 头中的完整用户名

### 计费用户名 - $Au

`$Au` - 用于计费的用户名。它是一个选择性伪变量（从 acc 模块继承）。如果存在则返回 `$au`，否则返回 From 用户名。

### 参数选项 - $argv

`$argv` - 提供对使用 '-o' 选项指定的命令行参数的访问。
示例：
```text

   # for option '-o foo=0'
   xlog("foo is $argv(foo) \n");

```

### 认证挑战算法 - $challenge.algorithm

`$challenge.algorithm` - 从 WWW-Authorize 或 Proxy-Authorize 头获取的算法值。

### 认证挑战领域 - $challenge.realm

`$challenge.realm` - 从 WWW-Authorize 或 Proxy-Authorize 头获取的领域值。

### 认证挑战随机数 - $challenge.nonce

`$challenge.nonce` - 从 WWW-Authorize 或 Proxy-Authorize 头获取的随机数值。

### 认证挑战 Opaque - $challenge.opaque

`$challenge.opaque` - 从 WWW-Authorize 或 Proxy-Authorize 头获取的 opaque 值。

### 认证挑战 QOP - $challenge.qop

`$challenge.qop` - 从 WWW-Authorize 或 Proxy-Authorize 头获取的 qop 值。

### 认证挑战 IK - $challenge.ik

`$challenge.ik` - 从 WWW-Authorize 或 Proxy-Authorize 头获取的 ik 值。

### 认证挑战 CK - $challenge.ck

`$challenge.ck` - 从 WWW-Authorize 或 Proxy-Authorize 头获取的 ck 值。

### Call-Id - $ci

`$ci` - call-id 头正文的引用

### Content-Length - $cl

`$cl` - content-length 头正文的引用

### CSeq 号码 - $cs

`$cs` - cseq 头中 cseq 号码的引用

### Contact 实例 - $ct

`$ct` - contact 头中 contact 实例/正文的引用。contact 实例是 display_name + URI + contact_params。由于 contact 头可能包含多个 Contact 实例，并且一条消息可能包含多个 Contact 头，因此为 `$ct` 变量添加了索引：
* `$ct` - 消息中的第一个 contact 实例
* `$(ct[n])` - 从消息开头的第 n 个 contact 实例，从索引 0 开始
* `$(ct[-n])` - 从消息末尾的第 n 个 contact 实例，从索引 -1 开始（最后一个 contact 实例）

### Contact 实例的字段 - $ct.fields(field)

`$ct.fields()` - 引用 contact 实例/正文的字段（见上文）。支持的字段有：
* name - 显示名称
* uri - contact URI
* q - q 参数（仅值）
* expires - expires 参数（仅值）
* methods - methods 参数（仅值）
* received - received 参数（仅值）
* params - 所有参数（包括名称）

示例：
* `$ct.fields(uri)` - 第一个 contact 实例的 URI
* `$(ct.fields(name)[1])` - 第二个 contact 实例的显示名称

### Content-Type - $cT

`$cT` - 引用 Content-Type 头正文以及多部分正文内的 content-type 头
* `$cT` - 消息的主要 Content-Type；在头中的那个
* `$(cT[n])` - 从消息开头的多部分正文中的第 **n** 个 Content-Type，从索引 0 开始
* `$(cT[-n])` - 从消息末尾的多部分正文中的第 **n** 个 Content-Type，从索引 -1 开始（最后一个 contact 实例）
* `$(cT[*])` - 包括主要的和来自多部分正文的所有 Content-Type 头

### 目标 URI 的域 - $dd

`$dd` - 目标 uri 域的引用

> [!IMPORTANT]
> 它是 R/W 变量（您可以从路由逻辑为其赋值）


### Diversion 头 URI - $di

`$di` - Diversion 头 URI 的引用

### Diversion "privacy" 参数 - $dip

`$dip` - Diversion 头 "privacy" 参数值的引用

### Diversion "reason" 参数 - $dir

`$dir` - Diversion 头 "reason" 参数值的引用

### 目标 URI 的端口 - $dp

`$dp` - 目标 uri 端口的引用

> [!IMPORTANT]
> 它是 R/W 变量（您可以从路由逻辑为其赋值）


### 目标 URI 的传输协议 - $dP

`$dP` - 目标 uri 传输协议的引用

### 目标集 - $ds

`$ds` - 目标集的引用

### 目标 URI - $du

`$du` - 目标 uri 的引用（用于发送请求的出站代理）
如果 loose_route() 返回 TRUE，则根据第一个 Route 头设置目标 uri。

别名：`$duri`

> [!IMPORTANT]
> 它是 R/W 变量（您可以从路由逻辑为其赋值）


### 错误类别 - $err.class

`$err.class` - 错误类别（现在对于解析错误为 '1'）

### 错误级别 - $err.level

`$err.level` - 错误的严重级别

### 错误信息 - $err.info

`$err.info` - 描述错误的文本

### 错误回复代码 - $err.rcode

`$err.rcode` - 建议的回复代码

### 错误回复原因 - $err.rreason

`$err.rreason` - 建议的回复原因短语

### From URI 域 - $fd

`$fd` - 'From' 头 URI 中域的引用

别名：`$from.domain`

### From 显示名称 - $fn

`$fn` - 'From' 头显示名称的引用

### From 标签 - $ft

`$ft` - 'From' 头标签参数的引用

### From URI - $fu

`$fu` - 'From' 头 URI 的引用

别名：`$from`

### From URI 用户名 - $fU

`$fU` - 'From' 头 URI 中用户名的引用

别名：`$from.user`

### OpenSIPS 日志级别 - $log_level

`$log_level` - 更改当前进程的日志级别；日志级别可以设置为新值（请参阅[可能的值](Script-CoreParameters.md#log_level)），或者可以重置回全局日志级别。
如果您仅跟踪和调试特定代码段，此函数非常有用。

使用示例：

```text
log_level= -1 # errors only
.....
{
......
$log_level = 4; # set the debug level of the current process to DBG
uac_replace_from(....);
$log_level = NULL; # reset the log level of the current process to its default level
.......
}
```

### SIP 消息缓冲区 - $mb

`$mb` - SIP 消息缓冲区的引用

### 消息标志 - $mf

`$mf` - 显示为当前 SIP 请求设置的消息/事务标志列表

### SIP 消息 ID - $mi

`$mi` - SIP 消息 id 的引用

### SIP 消息长度 - $ml

`$ml` - SIP 消息长度的引用

### 消息分支 - $msg.branch

`$msg.branch` - 类似于 [`$branch`](#branch)，此变量用于通过写入 SIP URI 值来创建新的消息分支。通过读取此变量，您可以获取当前/最后添加的分支的 SIP URI（如果没有添加额外分支，则是 RURI 分支）。
```text

   # creates a new branch
   $msg.branch = "sip:new@domain.org";
   # print its URI
   xlog("last added branch has URI $msg.branch \n");

```

### 消息分支的 SIP URI - $msg.branch.uri

`$msg.branch.uri` -  提供对现有消息分支的 SIP URI（作为字符串）的读/写访问。消息分支通过 [append_msg_branch()](Script-CoreFunctions.md#append_branch) 核心函数或各种模块（如 "registrar" 模块）创建。消息分支由 TM "t_relay()" 函数消耗（它们被转换为 TM 分支）。

该变量支持索引——它从 0 开始，表示 RURI（或消息）分支。新添加的分支将从 1 开始。因此，分支 0 始终存在，无需创建它。如果未指定索引，则考虑当前/最后添加的分支（如果没有添加额外分支，则是 RURI 分支）。也接受负值，表示从最后一个分支（-1 是最新/最高的分支）到 RURI 分支的索引。****/ALL 索引将返回所有分支的逗号分隔值列表。

该变量可以在 REQUEST 和 FAILURE 路由中使用。
```text

   # creates a new branch
   $msg.branch = "sip:new@domain.org";
   # change its URI
   $msg.branch.uri = "sip:new_new@domain.org"
   # change its URI of RURI branch
   $(msg.branch.uri[0]) = "sip:new_RURI@domain.org"

```

### 消息分支的目标 URI - $msg.branch.duri

`$msg.branch.duri` -  100% 类似于 [`$msg.branch.uri`](#msg.branch.uri)，但操作消息分支的 Destination-URI 值。

### 消息分支的 PATH - $msg.branch.path

`$msg.branch.path` -  100% 类似于 [`$msg.branch.uri`](#msg.branch.uri)，但操作消息分支的 PATH 值。

### 消息分支的 Q - $msg.branch.q

`$msg.branch.q` -  100% 类似于 [`$msg.branch.uri`](#msg.branch.uri)，但操作消息分支的 Q 值。

### 消息分支的标志 - $msg.branch.flags

`$msg.branch.flags` -  100% 类似于 [`$msg.branch.uri`](#msg.branch.uri)，但操作分支标志列表（逗号分隔）（为分支设置的）。

### 消息分支的 SIP 套接字 - $msg.branch.socket

`$msg.branch.socket` -  100% 类似于 [`$msg.branch.uri`](#msg.branch.uri)，但操作消息分支的（强制）套接字值。

### 消息分支的标志 - $msg.branch.flag()

`$msg.branch.flag()` -  类似于 [`$msg.branch.uri`](#msg.branch.uri)，但操作单个分支标志（对于当前分支）。

接受的值为 0 表示 FALSE，正非零表示 TRUE。返回值 0 表示 FALSE，1 表示 TRUE。

> [!NOTE]
> 此处不能使用 */ALL 索引。

```text

   # creates a new branch
   $msg.branch = "sip:new@domain.org";
   # set the "pstn" named flag for this branch
   $msg.branch.flag(pstn) = 1;
   $msg.branch.flag(foo) = 1;
   # print all the set flags
   xlog("Flags are <$msg.branch.flags>\n");

```

### 消息分支的属性 - $msg.branch.attr()

`$msg.branch.attr()` -  类似于 [`$msg.branch.uri`](#msg.branch.uri)，但操作单个分支属性（附加到当前分支）。

属性可以有任何名称（无需预定义），并且可以具有单个值（字符串或整数）。

> [!NOTE]
> 此处不能使用 */ALL 索引。

```text

   # creates a new branch
   $msg.branch = "sip:new@domain.org";
   # set the "pstn" named flag for this branch
   $msg.branch.attr(name) = "one";
   $msg.branch.attr(num) = 5;

```

### 最后消息分支的索引 - $msg.branch.last_idx

`$msg.branch.last_idx` -  返回最后消息分支的索引。如果没有添加额外分支，它将返回 0，即 RURI 分支的索引。然后返回的值将随每次 append_msg_branch() 递增。

### 消息标志 - $msg.flag

`$msg.flag(flag_name)` - 此变量提供对单个特定消息标志（按名称标识）值的读/写访问。写入接受的值是 1（设置）和 0（取消设置）。返回值是 1/"true"（设置）和 0/"false"（取消设置）。
```text

  setflag("X");
  xlog("---- flag value is $msg.flag(X) \n");
  $msg.flag(X) = off;
  xlog("---- flag value is $msg.flag(X) \n");

```

### 消息是请求 - $msg.is_request

`$msg.is_request` - 此变量指示当前 SIP 消息是否是请求。返回值是 1/"true"（请求）和 0/"false"（回复）。
```text

  xlog("---- this message is a request:  $msg.is_request \n");
  if ( $msg.is_request )
    xlog("---- yes, it is a request\n");

```

### 消息类型 - $msg.type

`$msg.type` - 此变量返回当前消息的类型。返回值是 "request"（请求）或 "reply"（回复）。
```text

  xlog("---- this message is a SIP $msg.type \n");

```

### SIP 请求原始 URI 中的域 - $od

`$od` - 请求原始 R-URI 中域的引用

### SIP 请求原始 URI 的端口 - $op

`$op` - 原始 R-URI 端口的引用

### SIP 请求原始 URI 的传输协议 - $oP

`$oP` - 原始 R-URI 传输协议的引用

### SIP 请求的原始 URI - $ou

`$ou` - 请求原始 URI 的引用

别名：`$ouri`

### SIP 请求原始 URI 中的用户名 - $oU

`$oU` - 请求原始 URI 中用户名的引用

### Path 头 - $path

`$path` - Path 头正文的引用。

### 路由参数 - $param
`$param(idx)` - 检索路由的参数。索引可以是整数或伪变量（索引从 1 开始）。

示例：
```c

   route {
      ...
      $var(debug) = "DBUG:"
      route(PRINT_VAR, $var(debug), "param value");
      ...
   }

   route[PRINT_VAR] {
      $var(index) = 2;
      xlog("$param(1): The parameter value is <$param($var(index))>\n");
   }

```

### SIP 请求 P-Preferred-Identity 头 URI 中的域 - $pd

`$pd` - 请求的 P-Preferred-Identity 头 URI 中的域引用（请参阅 RFC 3325）

### 传输层的代理协议 - $proxy_protocol
`$proxy_protocol(field)` - 从传输层检索代理协议信息。支持的字段有：**src_ip**、**src_port**、**dst_ip**、**dst_port**、**af**

示例：
```text

   route {
      ...
      if ($proxy_protocol(af) != NULL)
          xlog("$proxy_protocol(src_ip):$proxy_protocol(src_port) -> $proxy_protocol(dst_ip):$proxy_protocol(dst_port)\n");
      ...
   }

```

### SIP 请求 P-Preferred-Identity 头中的显示名称 - $pn

`$pn` - 请求的 P-Preferred-Identity 头中的显示名称引用（请参阅 RFC 3325）

### 进程 ID - $pp

`$pp` - 进程 id (pid) 的引用

### SIP 请求 P-Preferred-Identity 头 URI 中的用户 - $pU

`$pU` - 请求的 P-Preferred-Identity 头 URI 中的用户引用（请参阅 RFC 3325）

### SIP 请求 P-Preferred-Identity 头中的 URI - $pu

`$pu` - 请求的 P-Preferred-Identity 头中的 URI 引用（请参阅 RFC 3325）

### SIP 请求 URI 中的域 - $rd

`$rd` - 请求 URI 中域的引用

别名：`$ruri.domain`

> [!IMPORTANT]
> 它是 R/W 变量（您可以从路由脚本为其赋值）


### 请求/回复正文 - $rb

`$rb` - SIP 消息正文或正文部分的引用
* `$rb` - 消息的整个正文（带所有部分）
* `$(rb[*])` - 与 `$rb` 相同
* `$(rb[n])` - 从消息开头的多部分正文中第 n 个正文，从索引 0 开始
* `$(rb[-n])` - 从消息末尾的多部分正文中第 n 个正文，从索引 -1 开始（最后一个 contact 实例）
* `$rb(application/sdp)` - 获取第一个 SDP 正文部分
* `$(rb(application/isup)[-1])` - 获取最后一个 ISUP 正文部分

### 返回代码 - $rc

`$rc` - 最后调用函数的返回代码引用

`$retcode` - 与 `$rc` 相同

### Remote-Party-ID 头 URI - $re

`$re` - Remote-Party-ID 头 URI 的引用

### 返回值 - $return

`$return` - 返回先前执行的路由的值。

该变量接受一个索引，从 0 开始，指示需要读取的返回值。

### SIP 请求的方法 - $rm

`$rm` - 请求方法的引用

### SIP 请求的端口 - $rp

`$rp` - R-URI 端口的引用

> [!IMPORTANT]
> 它是 R/W 变量（您可以从路由脚本为其赋值）


### SIP 请求 URI 的传输协议 - $rP

`$rP` - R-URI 传输协议的引用

### SIP 回复的原因 - $rr

`$rr` - 回复原因的引用

### SIP 回复的状态 - $rs

`$rs` - 回复状态的引用

### Refer-to URI - $rt

`$rt` - refer-to 头 URI 的引用

### SIP 请求的 URI - $ru

`$ru` - 请求 URI 的引用

别名：`$ruri`

> [!IMPORTANT]
> 它是 R/W 变量（您可以从路由脚本为其赋值）


### SIP 请求 URI 中的用户名 - $rU

`$rU` - 请求 URI 中用户名的引用

别名：`$ruri.user`

> [!IMPORTANT]
> 它是 R/W 变量（您可以从路由脚本为其赋值）


### SIP 请求 URI 的 Q 值 - $ru_q

`$ru_q` - R-URI 的 q 值引用

> [!IMPORTANT]
> 它是 R/W 变量（您可以从路由脚本为其赋值）


### SDP 正文 - $sdp

`$sdp` - 当前 SIP 消息的 SDP 正文的读/写引用

```bash

# READ operation on the SIP msg SDP
$sdp

# WRITE operation (assign a new SDP)
$sdp = $var(rtpengine_sdp);

# READ operation on the SIP reply SDP
$(<reply>sdp)

# WRITE operation (assign a new SDP to SIP reply)
$(<reply>sdp) = $var(rtpengine_sdp);

```

### SDP 正文行 - $sdp.line

`$sdp.line` - SDP 正文行的读/写引用，支持过滤

```bash

# Fetch the 1st, 2nd, 3rd, etc. attribute line (starting with "a=")
$sdp.line(a=)         # fetch first "a=" line
$sdp.line(a=[0])      # equivalent, "a=" line at index 0
$sdp.line(a=ptime[1]) # "a=ptime" line at index 1
$sdp.line(a=[100])    # will likely yield NULL

# Token-based filtering, inside a line
$sdp.line(m=audio[1])         # m=audio 27292 RTP/AVP 9 8 0 2 102 100 99 101
$sdp.line(m=audio[1]/[0])     # audio
$sdp.line(m=audio[1]/[1])     # 27292
$sdp.line(m=audio[1]/[2])     # RTP/AVP
$sdp.line(m=audio[1]/[10])    # 101
$sdp.line(m=audio[1]/[11])    # NULL
$sdp.line(m=audio[1]/RTP)         # RTP/AVP
$sdp.line(m=audio[1]/RTP\/AVP)    # RTP/AVP
$sdp.line(m=audio[1]/RTP\/AVP[0]) # RTP/AVP
$sdp.line(m=audio[1]/RTP\/AVP[1]) # NULL
$sdp.line(m=audio[1]/RTQ)         # NULL

```

### SDP 正文流 - $sdp.stream

`$sdp.stream` - SDP 正文流的读/写引用，支持过滤

```bash

# Within a desired stream, you can first filter by line...
$sdp.stream(/a=ptime);         # first "a=ptime" line from Stream #0 ("m=", matching any stream type)
$sdp.stream([1]/a=ptime);      # first "a=ptime" line from Stream #1 ("m=", matching any stream type))
$sdp.stream(audio[1]/a=ptime); # first "a=ptime" line from Audio Stream #1 ("m=audio...")
$sdp.stream(a[1]/a=ptime);     # first "a=ptime" line from Audio Stream #1 ("m=a...")
$sdp.stream(video[1]/a=nortpproxy) = NULL;  # delete entire line starting with "a=nortpproxy" from Video Stream #1
$sdp.stream(v[1]/a=nortpproxy:/[0]) = "yes";   # set first "a=nortpproxy" line "yes" value, in Video Stream #1

# ... and, additionally, by token
$sdp.stream(video[1]/a=fmtp:115/bitrate=) = 48000; # set "bitrate=" to 48000, under "a=fmtp:115" line #0, as part of Video Stream #1
$sdp.stream(video[1]/a=fmtp:115[3]) = NULL; # delete the 4th occurrence (if any) of "a=fmtp:115" line, but only within Video Stream #1
$sdp.stream(video[1]/a=fmtp:115/bitrate=) = 48000; # set "bitrate=" to 48000, under "a=fmtp:115" line #0, as part of Video Stream #1

```

### SDP 正文会话 - $sdp.session

`$sdp.session` - SDP 正文会话的读/写引用，支持过滤

```bash

# Within the SDP session (i.e. until the 1st "m=" line), you can first filter by line...
$sdp.session(a=ptime);            # 1st "a=ptime" line at Session level
$sdp.session(a=ptime[0]);         # same as above
$sdp.session(a=ptime[1]);         # 2nd "a=ptime" line at Session level
$sdp.session(a=ptime[0]) = NULL;  # delete 1st "a=ptime" line at Session level

# ... but also filter and edit by token:
$sdp.session(a=rtpmap/telephone-event\/) = "8000";  # Match 1st "a=rtpmap" line which describes telephone-event at Session level, and force bitrate to 8000

```

### SDP 流索引 - $sdp.stream.idx

`$sdp.stream.idx` - 匹配 SDP 流的索引的只读引用。匹配失败时返回 NULL。

此变量特别有用，用于匹配具有特定属性的行（例如"PCMU codec 的 rtpmap= 行"），然后更改同一流中的不同属性。示例：

```text

$var(line_idx) = $sdp.stream.idx(video/a=fmtp/packetization-mode=); # locate index of first "a=fmtp" line, containing a packetization-mode= attribute
$var(data) = $sdp.line([$var(line_idx)]); # grab the full line data
... perform processing on that line ...
$sdp.line([$var(line_idx)]) = $var(data); # re-write the line

```

### IP 源地址 - $si

`$si` - 消息 IP 源地址的引用

别名：`$src_ip`

### 入站套接字 - $socket_in / $socket_in(field)

`$socket_in` - 获取入站套接字（用于接收消息）的描述（proto:ip:port 格式）的只读变量。


该变量还提供对套接字各种属性/子字段的详细只读访问，如 `$socket_in()`。套接字的子字段有：
* ip - 套接字的 IP 部分
* port - 套接字的端口部分
* proto - 套接字协议名称（如 "UDP"、"TCP" 等）
* advertised_ip - 套接字的 advertised IP 部分（如果在特定套接字上没有进行广告，则可能为 NULL）
* advertised_port - 套接字的 advertised 端口部分（如果在特定套接字上没有进行广告，则可能为 NULL）
* tag - 套接字内部 tag/别名
* anycast - 套接字是否使用 anycast IP（如果不是返回 0，如果是返回 1）
* af - 套接字 IP 的地址家族。其值为 "INET"（如果是 IPv4）或 "INET6"（如果是 IPv6）。
有关这些子字段含义的更多详细信息，请还阅读[套接字定义](Script-CoreParameters.md#shm_memlog_size)。

### 出站套接字 - $socket_out / $socket_out(field)

`$socket_out` - 用于读取或更改消息出站套接字的读写变量。最初（写入/更改之前），它将返回与 [`$socket_in`](#socket_in) 相同的套接字描述（入站套接字也将用作出站套接字）。此外，它还支持 `forced` 子字段，仅在明确强制套接字时返回套接字描述；因此，与常规 [`$socket_out`](#socket_out) 相比，如果没有明确强制套接字，变量返回 NULL。


该变量还提供对套接字各种属性/子字段的详细只读访问，如 `$socket_out()`。**它提供与 [`$socket_in`](#socket_in) 变量相同的子字段。**

```text

   $socket_out = "udp:11.11.11.11:5060";
   xlog("The outbound port is $socket_out(port)\n");

```

### 源端口 - $sp

`$sp` - 消息源端口的引用

### To URI 域 - $td

`$td` - 'To' 头 URI 中域的引用

别名：`$to.domain`

### To 显示名称 - $tn

`$tn` - 'To' 头显示名称的引用

### To 标签 - $tt

`$tt` - 'To' 头标签参数的引用

### To URI - $tu

`$tu` - 'To' 头 URI 的引用

别名：`$to`

### To URI 用户名 - $tU

`$tU` - 'To' 头 URI 中用户名的引用

别名：`$to.user`

### 格式化日期和时间 - $time

`$time(format)` - 根据 UNIX 日期返回格式化时间字符串（请参阅：**man date**）。

### 分支索引 - $T_branch_idx

`$T_branch_idx` - 执行 branch_route[] 的分支的索引（第一个分支从 1 开始）。如果在 branch_route[] 块外部使用，值为 '0'。这是由 TM 模块导出的。

### 字符串格式化时间 - $Tf

`$Tf` - 字符串格式化时间的引用

### 当前 unix 时间戳（秒）- $Ts

`$Ts` - 当前 unix 时间戳（秒）的引用

### 当前秒的微秒 - $Tsm

`$Tsm` - 当前秒的微秒引用

### 启动 unix 时间戳 - $TS

`$TS` - 启动 unix 时间戳的引用

### 用户代理头 - $ua

`$ua` - 用户代理头字段的引用

### SIP 头 - $hdr

`$(hdr(name)[N])` - 表示由 'name' 标识的第 N 个头的正文。如果省略 [N]，则打印第一个头的正文。第一个头在 N=0 时检索，第二个在 N=1 时检索，依此类推。要打印该类型的最后一个头，请使用 -1，目前不支持其他负值。在规范符内部不允许有空格（在 `}` 之前，在 `{` 之前或之后，在 [、] 符号之前或之后）。当 N='*' 时，打印该类型的所有头。

该模块应该识别大多数压缩头名称（OpenSIPS 识别的名称，此时应该全部识别），如果不识别，必须明确指定压缩形式。建议使用专用规范符来获取头（如可用，例如 %ua 用于用户代理头）——它们更快。

`$(hdr_name[N])` - 返回第 N 个头的名称。第一个头名称在 N=0 时获取，第二个在 N=1 时获取，依此类推。要打印最后一个头名称请使用 -1，倒数第二个使用 -2，依此类推。在规范符内部不允许有空格（在 `}` 之前，在 `{` 之前或之后，在 [、] 符号之前或之后）。当 N='*' 时，打印所有头名称。

`$(hdrcnt(name))` -- 返回给定 'name' 类型头的数量。使用与上述 `$hdr(name)` 相同的规则指定头名称。许多头（例如 Via、Path、Record-Route）可能在消息中出现多次。此变量返回给定类型头的数量。

请注意，某些头（例如 Path）可能用逗号连接在一起并显示为单个头行。此变量计算头行的数量，而不是头值的数量。

对于下面的消息片段，`$hdrcnt(Path)` 将有值 2，`$(hdr(Path)[0])` 将有值 **`<a.com>`**：
```text

    Path: <a.com>
    Path: <b.com>

```

对于下面的消息片段，`$hdrcnt(Path)` 将有值 1，`$(hdr(Path)[0])` 将有值 **`<a.com>`,`<b.com>`**：
```text

    Path: <a.com>,<b.com>

```

请注意，上面两个示例在语义上是等效的，但变量呈现不同的值。

### 路由名称（完整）- $route
`$route` - 访问当前路由调用堆栈的路由名称。使用示例（假设路由调用堆栈为 "route > route[A] > route[B]"）：

* `$route` 和 `$(route[0])` 都返回 **"route[B]"**（当前路由）
* `$(route[1])` 返回 **"route[A]"**（父路由）
* `$(route[2])` 返回 **"route"**（前父路由）
* `$(route[-1])` 返回 **"route"**（最顶层路由）
* `$(route[-2])` 返回 **"route[A]"**（下一个顶层路由）
* `$(route[-3])` 返回 **"route[B]"**（下下一个顶层路由）
* `$(route[3])` 和 `$(route[-4])` 都返回 **NULL**（索引超出范围）
* `$(route[*])` 返回 **"route > route[A] > route[B]"**（整个调用堆栈）

### 路由类型 - $route.type
`$route.type` - 访问当前路由的类型。可以使用正索引或负索引进行索引。

* `$route.type` 和 `$(route.type[0])` 都返回当前路由类型
* `$(route.type[1])` 返回父路由类型
* `$(route.type[-1])` 返回最顶层路由类型
* `$(route.type[-2])` 返回下一个顶层路由类型

### 路由名称 - $route.name
`$route.name` - 访问当前路由的名称。可以使用正索引或负索引进行索引。

* `$route.name` 和 `$(route.name[0])` 都返回当前路由名称
* `$(route.name[1])` 返回父路由名称
* `$(route.name[-1])` 返回最顶层路由名称
* `$(route.name[-2])` 返回下一个顶层路由名称

### 当前脚本行和文件 - $cfg_line
`$cfg_line` - 保存正在执行的操作的脚本当前行，可用于日志记录目的

`$cfg_file` - 保存正在执行的 cfg 文件的当前名称，当使用 include 语句使用多个脚本时很有用

### xlog() 的日志级别 - $xlog_level

`$xlog_level` - 允许设置/重置每个进程的 xlog() 日志级别。简而言之，您可以读取 xlog() 调用的详细程度级别，或者临时更改每个进程的级别。

示例：
```text

xlog("current verbosity is $xlog_level \n");
$xlog_level = L_DBG; # force local xlogging limit to DBG
...
(set of xlogs)
...
$xlog_level = NULL;  # reset to initial value

```

## 转义序列

这些序列由 xlog 模块导出和使用，主要用于使用转义序列以多种颜色（前景和背景）打印消息。

### 前景色和背景色

`$C(xy)` - 转义序列的引用。¿x¿ 表示前景色，¿y¿ 表示背景色。

颜色可以是：

* x : 终端的默认颜色
* s : 黑色
* r : 红色
* g : 绿色
* y : 黄色
* b : 蓝色
* p : 紫色
* c : 青色
* w : 白色

### 示例

一些使用示例。

```text

...
route {
...
    $avp(uuid)="caller_id";
    $avp(tmp)= $avp(uuid) + ": " + $fu;
    xlog("$C(bg)$avp(tmp)$C(xx) [$avp(tmp)] $C(br)$cs$C(xx)=[$hdr(cseq)]\n");
...
}
...

```
