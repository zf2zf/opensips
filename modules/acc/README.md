---
title: "ACC 模块"
description: "ACC 模块用于将事务信息记费到不同的后端，如 syslog、SQL、AAA。"
---

## 管理指南

### 概述

ACC 模块用于将事务信息记费到不同的后端，如 syslog、SQL、AAA。

要对事务进行记费并选择要使用的后端集，脚本编写者只需使用 [执行记费](#func_do_accounting) 脚本函数将事务标记为待记费。请注意，该函数此时并不会实际执行记费操作，它只是设置一个标记——实际的记费操作将在事务或对话完成后进行。

即便如此，该模块也允许脚本编写者在特殊情况下通过其他脚本函数强制立即执行记费。

默认情况下，记费模块会记录一组固定的事务属性——如果需要通过添加更多信息来定制记费内容，请参阅下一章关于额外记费的说明——[ACC 额外 ID](#extra_accounting)。

固定的最小记费信息包括：

- 请求方法名
- From 头域的 TAG 参数
- To 头域的 TAG 参数
- Call-Id
- 最终回复的 3 位状态码
- 最终回复的原因短语
- 事务完成时的时间戳

如果请求中不存在某个值，则该值将记录为空字符串。

请注意：

- 单个 INVITE 可能产生多条记费报告——这很可能是由于 SIP 分叉功能导致的。
- 从版本 2.2 开始，所有用于记费的标志都已由 do_accounting() 函数替代。无需再担心是否设置了标志或被各种标志名称搞混，现在只需调用该函数，它会完成所有工作。
- OpenSIPS 现在支持会话/对话记费。它可以自动关联 INVITE 和 BYE 以生成正确的 CDR，例如用于计费目的。
- 如果 UA 在通话过程中中途失败，代理永远不会发现此情况。通常，更好的做法是从终端设备（如 PSTN 网关）进行记费，因为这类设备最了解通话状态（包括媒体状态和 PSTN 网关情况下的 PSTN 状态）。

SQL、事件接口和 AAA 后端支持已编译到模块中。

关于记费模块的工作原理（记费范围、记费事件和记费后端），可以在这个在线 [高级记费教程](https://docs.opensips.org/tutorials-advanced-accounting) 中找到非常详细的说明。

#### 通用示例

```c
loadmodule "modules/acc/acc.so"

if ($ru=~"sip:+40") /* 拨打到罗马尼亚的电话 */ {
    if (!proxy_authorize("sip_domain.net" /* realm */,
    "subscriber" /* 表名 */))  {
        proxy_challenge("sip_domain.net" /* realm */, "0" /* no qop */ );
        exit;
    }

    if (is_method("INVITE") && $au!=$fU) {
        xlog("FROM URI != digest username\n");
        sl_send_reply(403,"Forbidden");
    }

    do_accounting("log"); /* 通过 syslog 设置记费 */
    t_relay(); /* 现在进入有状态模式 */
};
```

### 额外记费

#### 概述

除了静态默认信息外，ACC 模块还允许使用 acc_extra 伪变量动态选择要记录的其他信息。这允许您记录任何伪变量（AVP、请求的部分、回复的部分等）。

#### 定义和语法

额外信息的选择通过 *extra_field* 参数进行，方法是指定标签和日志名称以获取附加信息。这些信息通过 define 标签引用的 acc_extra 伪变量定义。如果未指定标签，其值将被视为与 log_value 相同。记费后端（log、db、aaa、evi）在定义的开头指定，用 ':' 与其余部分分隔。参数的语法如下：

- *backend : tag -> log_name (';'tag -> log_name)*
- *backend : tag (';' tag)*

额外的值在整个通话过程中保持一致。在请求期间设置的值将在所有回复期间保持可见。同样，关于 CDR 记费，在初始 INVITE 上设置的值将贯穿整个对话。

通过 *log_name* 可以定义 *data* 将被记录的方式/位置。其含义取决于所使用的记费支持：

- *LOG 记费* - log_name 将与数据一起打印，格式为 *log_name=data*；
- *DB 记费* - log_name 将是存储数据的数据库列名。*重要*：在数据库 *acc* 表中添加与每个额外数据对应的列；
- *AAA 记费* - log_name 将是用于将数据打包到 AAA 消息中的 AVP 名称。log_name 将通过字典转换为 AVP 编号。*重要*：在 AAA 字典中添加 *log_name* 属性；
- *事件记费* - log_name 将是引发的事件中参数的名称。

#### 工作原理

以以下格式声明额外字段：

```c
modparam("acc", "extra_fields", "log: a -> test_a")
```

将使您能够仅通过设置 *$acc_extra(a)* 变量来为日志的 *test_a* 字段设置值。否则，该字段将被记录为空值（null）。

#### Radius 记费依赖

如果使用 radius 记费，除了必需的 radius 客户端库外，**dictionary.rfc2866** 必须被包含以使模块正常工作。

### 多通话分支记费

#### 概述

由于转发操作，SIP 通话可以有多个分支。例如用户 A 呼叫用户 B，用户 B 将通话转接到用户 C。这只有一个 SIP 通话但有 2 个分支（A 到 B 和 B 到 C）。对通话的分支进行记费对于正确计费是必要的（如果 C 是 PSTN 号码且通话需要计费，则用户 B 作为修改通话目的地的最后一方必须支付通话费用，而不是 A 作为通话的发起者。服务器上的通话转发只是一个例子，说明了拥有支持多分支的记费引擎的必要性。

#### 配置

首先了解其工作原理：其思想是有一个变量来存储每个分支的一组值。变量内容的含义由脚本编写者严格决定——它可以是分支的起源和来源、其状态或任何其他相关信息。默认情况下只定义了一个分支。脚本编写者必须决定何时创建新分支，使用 *acc_new_leg()* 脚本函数。创建新分支时，该分支的所有值默认设置为 NULL。

当通话的记费信息被写入/发送时，所有通话-分支对都将被添加。

默认情况下，多通话分支支持是禁用的——可以通过设置 *acc_leg* 变量的 `leg_fields` 模块参数来启用。请注意，后者仅对 OpenSIPS 自动生成的 CDR 有意义。

#### 记录的数据

对于每个通话，所有来自 *acc_leg* 变量的值都将被记录。信息如何被实际记录取决于数据后端：

- *syslog* -- 所有分支集将作为一个记录字符串添加，格式为 acc_leg(leg1)=xxx, acc_leg(leg2)=xxxx，...；
- *database* -- 由于数据库数据结构限制，每对将单独记录；将写入多条记录，它们之间的区别仅在于对应于通话分支信息的字段。

  > **注意：** 您需要在数据库（所有与 acc 相关的表）中为通话分支信息添加列（为分支集的每个分支值添加一列）；
- *AAA* -- 所有集将作为 AAA AVP 添加到同一 AAA 记费消息中——对于每个通话分支，将添加一组 AAA AVP（对应于每个分支集）

  > **注意：** 您需要在字典中添加通话分支集定义中使用的 AAA AVP；
- *events* -- 每对将作为事件中不同的参数-值对出现。与数据库行为类似，将引发多个事件，它们之间的唯一区别是分支信息。

*重要！！！* 为了使用 *RADIUS*，必须包含位于 $(opensips_install_dir)/etc/dictionary.opensips 中的 AVP，并在 opensips radius 配置脚本字典和 radius 服务器字典中都包含它们。最重要的是最后三个 AVP（ID：227、228、229），您不会在任何 SIP 字典中找到它们（至少在目前），因为它们仅在 OpenSIPS 中使用。

### CDR 记费

#### 概述

ACC 模块现在还可以维护会话/对话记费。这允许您记录有用的信息，如通话时长、通话开始时间和建立时间。

#### 配置

为了进行 CDR 记费，首先需要在对话框的初始 INVITE 调用 [执行记费](#func_do_accounting) 脚本函数时设置 *cdr* 标志。

#### 工作原理

这种记费类型基于 dialog 模块。当收到初始 INVITE 时，如果设置了 *cdr* 标志，则保存对话框创建时间。一旦通话被应答并收到 ACK，其他信息（如额外值或分支值）会被保存。当收到相应的 BYE 时，计算通话时长并将所有信息存储到所需的后端。

### 依赖

#### OpenSIPS 模块

该模块依赖以下模块（换句话说，列出的模块必须在此模块之前加载）：

- *tm* -- 事务管理器
- *数据库模块* -- 如果使用 SQL 支持
- *rr* -- 记录路由，如果启用了 "detect_direction" 模块参数
- *aaa 模块*
- *dialog* -- 对话，如果使用 "cdr" 选项

#### 外部库或应用程序

运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：

- 无。

### 导出的参数

#### early_media (integer)

早期媒体（任何带有包体的临时回复）是否也需要记费？

默认值为 0（否）。

```c title="early_media 示例"
modparam("acc", "early_media", 1)
```

#### report_cancels (integer)

默认情况下，CANCEL 报告是禁用的——大多数记费应用程序希望看到 INVITE 的取消状态。如果确实要记费 CANCEL 事务，请开启。

默认值为 0（否）。

```c title="report_cancels 示例"
modparam("acc", "report_cancels", 1)
```

#### detect_direction (integer)

控制顺序请求的方向检测。如果启用（非零值），对于上游方向（从被叫方到主叫方）的顺序请求，FROM 和 TO 将被交换（方向将按照原始请求中的方式保留）。

它影响所有与 TO 和 FROM 头域相关的值（包体、URI、用户名、域名、TAG）。

默认值为 0（禁用）。

```c title="detect_direction 示例"
modparam("acc", "detect_direction", 1)
```

#### extra_fields (string)

定义用于额外字段记费的标签-log_value 集。请参阅 [ACC 额外 ID](#extra_accounting) 获取额外记费的详细说明。

如果为空，额外记费支持将被禁用。

默认值为 0（禁用）。

```c title="设置 *extra_fields* 示例："
# 对于基于 syslog 的记费，可以使用任何您想要打印的文本
# 如果设置 $acc_extra(a)，您将在日志中看到 "My_a_Field=<value>
# 如果设置 $acc_extra(b)，您将在日志中看到 "b=<value>
modparam("acc", "extra_fields", "log: a->My_a_Field; b")
# 对于基于 mysql 的记费，使用列名
# $acc_extra(a) = <value>  结果是在数据库中用 <value> 设置 col_a
modparam("acc", "extra_fields", "db: a->col_a; col_b")
# 对于基于 AAA 的记费，使用 AAA AVP 的名称
modparam("acc", "extra_fields","aaa:a->AAA_SRC;b->AAA_DST")
# evi 定义示例
modparam("acc", "extra_fields","a->2345;b->2346")
```

#### leg_fields (string)

定义用于多分支记费的标签-log_value 集。请参阅 [多通话分支](#multi_call_legs_accounting) 获取多通话分支记费的详细说明。

如果为空，多分支记费支持将被禁用。

默认值为 0（禁用）。

```c title="设置 *leg_fields* 示例："
# 对于基于 syslog 的记费，可以使用任何您想要打印的文本
# 如果设置 $(acc_leg(a)[0])，您将在日志中看到 "My_a_Field=<value>
# 如果设置 $(acc_leg(b)[0])，您将在日志中看到 "b=<value>
modparam("acc", "leg_fields", "log: a->My_a_Field; b")
# 对于基于 mysql 的记费，使用列名
# $acc_leg(a) = <value>  结果是在数据库中用 <value> 设置 col_a
modparam("acc", "leg_fields", "db: a->col_a; col_b")
# 对于基于 AAA 的记费，使用 AAA AVP 的名称
modparam("acc", "leg_fields","aaa:a->AAA_LEG_SRC;b->AAA_LEG_DST")
# evi 定义示例
modparam("acc", "leg_fields","a->2345;b->2346")
```

#### log_level (integer)

记费消息输出到 syslog 的日志级别。

默认值为 L_NOTICE。

```c title="log_level 示例"
modparam("acc", "log_level", 2)   # 设置 log_level 为 2
```

#### log_facility (string)

记费消息输出到 syslog 的日志设施。这允许您轻松地将记费特定的日志与其他日志消息分开。

默认值为 LOG_DAEMON。

```c title="log_facility 示例"
modparam("acc", "log_facility", "LOG_DAEMON")
```

#### aaa_url (string)

这是表示所使用的 AAA 协议及其配置文件位置的 URL。

如果参数设置为空字符串，AAA 记费支持将被禁用。

默认值为 "NULL"。

```c title="设置 aaa_url 参数"
...
modparam("acc", "aaa_url", "radius:/etc/radiusclient-ng/radiusclient.conf")
...
```

#### service_type (integer)

用于记费的 AAA 服务类型。

默认值为未设置。

```c title="service_type 示例"
# SIP 的默认服务类型为 15
modparam("acc", "service_type", 15)
```

#### db_table_acc (string)

成功通话记费的表名——因数据库而异。

默认值为 "acc"

```c title="db_table_acc 示例"
modparam("acc", "db_table_acc", "myacc_table")
```

#### db_table_missed_calls (string)

未接来电记费的表名——因数据库而异。

默认值为 "missed_calls"

```c title="db_table_missed_calls 示例"
modparam("acc", "db_table_missed_calls", "myMC_table")
```

#### db_url (string)

SQL 地址——因数据库而异。如果设置为 NULL 或空字符串，SQL 支持将被禁用。

默认值为 "NULL"（SQL 禁用）。

```c title="db_url 示例"
modparam("acc", "db_url", "mysql://user:password@localhost/opensips")
```

#### acc_method_column (string)

记费表中存储请求方法名的列名（字符串格式）。

默认值为 "method"。

```c title="acc_method_column 示例"
modparam("acc", "acc_method_column", "method")
```

#### acc_from_tag_column (string)

记费表中存储 From 头域 TAG 参数的列名。

默认值为 "from_tag"。

```c title="acc_from_tag_column 示例"
modparam("acc", "acc_from_tag_column", "from_tag")
```

#### acc_to_tag_column (string)

记费表中存储 To 头域 TAG 参数的列名。

默认值为 "to_tag"。

```c title="acc_to_tag_column 示例"
modparam("acc", "acc_to_tag_column", "to_tag")
```

#### acc_callid_column (string)

记费表中存储请求的 Callid 值的列名。

默认值为 "callid"。

```c title="acc_callid_column 示例"
modparam("acc", "acc_callid_column", "callid")
```

#### acc_sip_code_column (string)

记费表中以字符串格式存储最终回复的数值代码的列名。

默认值为 "sip_code"。

```c title="acc_sip_code_column 示例"
modparam("acc", "acc_sip_code_column", "sip_code")
```

#### acc_sip_reason_column (string)

记费表中存储最终回复的原因短语值的列名。

默认值为 "sip_reason"。

```c title="acc_sip_reason_column 示例"
modparam("acc", "acc_sip_reason_column", "sip_reason")
```

#### acc_time_column (string)

记费表中以日期时间格式存储事务完成时间戳的列名。

默认值为 "time"。

```c title="acc_time_column 示例"
modparam("acc", "acc_time_column", "time")
```

### 导出的伪变量

#### $acc_extra(tag_name)

可以使用使用 [额外字段](#param_extra_fields) 定义的标签名来寻址此变量。如果未调用 [执行记费](#func_do_accounting)，此变量在处理单条消息的整个过程中可见，从而可以调用 *acc_XXX_request()*。如果调用了 [执行记费](#func_do_accounting)，该变量从第一次调用此函数时起直到实际记费执行前都可见。

#### $(acc_leg(tag_name)[leg_index])

此变量可以使用使用 [分支字段](#param_leg_fields) 定义的标签名和一个有效的分支索引（<= [acc 当前分支](#pv_acc_current_leg)）来寻址。除非使用了 [执行记费](#func_do_accounting)，否则不能使用此变量。该变量也接受负索引，从 -1 开始（最后添加的分支）。

```c
# 当前分支的 "caller" 值
$acc_leg(caller)

# 最后添加的分支的 "caller" 值
$(acc_leg(caller)[-1]) # 等同于 $acc_leg(caller)
                       # 等同于 $(acc_leg(caller)[$acc_current_leg])

# 倒数第二个分支的 "caller" 值
$(acc_leg(caller)[-2])
```

#### $acc_current_leg (只读)

保存当前分支的索引，从 0 开始。调用 [新建分支](#func_acc_new_leg) 将增加此索引。

### 导出的函数

#### do_accounting(type, [flags], [table])

`do_accounting()` 替代了所有 *_flag、*_missed_flag、cdr_flag、failed transaction_flag 和 db_table_avp modparams。只需调用 do_accounting()，选择您想要记费的位置和方式，函数将为您完成所有工作。

多次调用时，该函数的行为是*附加性的*。

参数的含义如下：

- *type (string)* - 您想要执行的记费类型。所有类型必须用 '|' 分隔。可以使用以下参数：

  - *log* - syslog 记费；
  - *db* - 数据库记费；
  - *aaa* - AAA 特定记费；
  - *evi* - 事件接口记费；
- *flags (string, 可选)* - 您所选记费类型的标志。所有类型必须用 '|' 分隔。可以使用以下参数：

  - *cdr* - 启用对话级记费。OpenSIPS 将在内部检测对话终止（BYE 请求的生成/接收），并在 BYE 请求被回复时立即存储 CDR。通过启用 "cdr" 标志，以下附加字段将被填充：duration、ms_duration、setuptime、created。（需要 dialog 模块支持）
  - *missed* - 记录未接来电；请注意，此标志将在第一次未接来电后被停用；如果您想要对每个未响应通话的目的地进行记费，您必须在 *failure_route* 中重新激活它；
  - *failed* - 标志，指示在失败情况下（status>=300）是否也要记费该事务；
- *table (string, 可选)* - 执行记费的表；它替代旧的 table_avp 参数；

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE 使用。

```c title="do_accounting 用法"
		...
		if (!has_totag()) {
			if (is_method("INVITE")) {
			/* 在数据库和 syslog 中启用 cdr 和未接来电记费
			 * 数据库记费将在 "my_acc" 表中进行 */
				do_accounting("db|log", "cdr|missed", "my_acc");
			}
		}
		...
		if (is_method("BYE")) {
			/* 通过 aaa 执行正常记费 */
			do_accounting("aaa");
		}
		...
		
```

#### drop_accounting([type], [flags])

`drop_accounting()` 重置通过 do_accounting() 设置的记费标志和类型。如果不带参数调用，所有记费都将停止。如果只带一个参数调用，该类型的所有记费都将停止。如果带两个参数调用，正常记费仍将启用。

多次调用时，该函数的行为是*附加性的*。

参数的含义如下：

- *type (string, 可选)* - 您想要停止的记费类型。所有类型必须用 '|' 分隔。可以使用以下参数：

  - *log* - 停止 syslog 记费；
  - *db* - 停止数据库记费；
  - *aaa* - 停止 AAA 特定记费；
  - *evi* - 停止事件接口记费；
- *flags (string, 可选)* - 要为所选记费类型重置的标志。所有类型必须用 '|' 分隔。可以使用以下参数：

  - *cdr* - 停止 CDR 记费；
  - *missed* - 停止记录未接来电；
  - *failed* - 停止失败事务记费；

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE 使用。

```c title="drop_accounting 用法"
		...
		acc_log_request("403 Destination not allowed");
		if (!has_totag()) {
			if (is_method("INVITE")) {
			/* 在数据库和 syslog 中启用 cdr 和未接来电记费
			 * 数据库记费将在 "my_acc" 表中进行 */
				do_accounting("db|log", "cdr|missed", "my_acc");
			}
		}
		...
		/* 后来在您的脚本中 */
		if (...) { /* 您不再想要记费 */
			/* 停止所有 syslog 记费 */
			drop_accounting("log");
			/* 或停止 syslog 的未接来电和 cdr 记费；
			 * 正常记费仍将启用 */
			drop_accounting("log", "missed|cdr");
			/* 或停止所有类型的记费  */
			drop_accounting();
		}
		...
		
```

#### acc_log_request(comment)

`acc_request` 对请求进行报告，例如，它可以用于报告对离线用户（回复 404 - Not Found）的未接来电。为了避免 UDP 请求重传时的多次报告，您需要将有状态处理中的操作嵌入。

参数的含义如下：

- *comment (string)* - 描述请求如何完成的注释——此字符串必须包含一个回复代码，后跟回复原因短语（例如："480 Nobody Home"）。变量可以在此字符串中使用。

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE 使用。

```c title="acc_log_request 用法"
...
acc_log_request("403 Destination not allowed");
...
```

#### acc_db_request(comment, table)

与 `acc_log_request` 类似，`acc_db_request` 对请求进行报告。报告将发送到 "db_url" 指定的数据库，在第二个动作参数中引用的表中。

参数的含义如下：

- *comment (string)* - 描述请求如何完成的注释——此字符串必须包含一个回复代码，后跟回复原因短语（例如："480 Nobody Home"）。变量可以在此字符串中使用；
- *table (string)* - 要使用的数据库表。

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE 使用。

```c title="acc_db_request 用法"
...
acc_db_request("Some comment", "Some table");
acc_db_request("$T_reply_code $(<reply>rr)", "acc");
...
```

#### acc_aaa_request(comment)

与 `acc_log_request` 类似，`acc_aaa_request` 对请求进行报告。它按照 "aaa_url" 中的配置向 AAA 服务器报告。

参数的含义如下：

- *comment (string)* - 描述请求如何完成的注释——此字符串必须包含一个回复代码，后跟回复原因短语（例如："404 Nobody home"）。变量可以在此字符串中使用。

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE 使用。

```c title="acc_aaa_request 用法"
...
acc_aaa_request("403 Destination not allowed");
...
```

#### acc_evi_request(comment)

与 `acc_log_request` 类似，`acc_evi_request` 对请求进行报告。报告被打包为通过 OpenSIPS 事件接口发送的事件，如果回复代码是正数（小于 300），则为 *E_ACC_EVENT*，如果回复代码是负数或无代码，则为 *E_ACC_MISSED_EVENT*。更多信息请参阅 [导出的事件](#exported_events)。

参数的含义如下：

- *comment (string)* - 描述请求如何完成的注释——此字符串必须包含一个回复代码，后跟回复原因短语（例如："404 Nobody home"）

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE 使用。

```c title="acc_evi_request 用法"
...
acc_evi_request("403 Destination not allowed");
...
```

#### acc_new_leg()

创建新分支并增加 [acc 当前分支](#pv_acc_current_leg)，仅在使用多分支记费时。新分支的所有值都将初始化为 null。

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE 使用。

```c title="acc_new_leg 用法"
...
	acc_new_leg();
...
```

#### acc_load_ctx_from_dlg()

该函数加载并公开当前使用的对话框的记费上下文。通过对话框上下文，意味着从脚本层面，您将读写其他对话框的记费变量。当前的记费上下文被暂存，直到执行卸载操作。

请注意，此函数仅在与来自 dialog 模块的 *load_dialog_ctx()* 函数一起使用时才有意义。加载另一个对话框的上下文后，通过使用 *acc_load_ctx_from_dlg()* 函数，您还可以访问加载的对话框的记费上下文。

注意：在执行卸载之前不能进行新的加载——不允许嵌套加载。

此函数可以从任何类型的路由使用。

```c title="acc_load_ctx_from_dlg 用法"
...
if ( load_dialog_ctx("$var(callid)") ) {
	# 我们现在有了新对话框的对话上下文
	acc_load_ctx_from_dlg();
	# 我们现在也有了那个对话框的记费上下文
	xlog("通话 '$var(callid)' 的记费主叫方是 '$acc_extra(caller)'\n");
	acc_unload_ctx_from_dlg();
	unload_dialog_ctx();
}

...
```

#### acc_unload_ctx_from_dlg()

该函数卸载先前加载的记费上下文，暴露在执行加载之前存在的任何记费上下文。

注意：您必须从脚本中为每个加载执行显式卸载！

此函数可以从任何类型的路由使用。

用法示例，请参阅 [acc 加载对话框上下文](#func_acc_load_ctx_from_dlg)。

### 导出的事件

#### E_ACC_CDR

 CDR 生成时引发的事件。请注意，此事件仅在使用自动 CDR 记费时触发。

参数：

- *method* - 请求方法名
- *from_tag* - From 头域 tag 参数
- *to_tag* - To 头域 tag 参数
- *callid* - 消息 Call-id
- *sip_code* - 最终回复的状态码
- *sip_reason* - 最终回复的状态原因
- *time* - 通话建立时的时间戳
- *evi_extra** - 由 *evi_extra* 参数添加的附加参数
- *evi_extra_bye** - 由 *evi_extra_bye* 参数添加的附加参数
- *multi_leg_info** - 由 *multi_leg_info* 参数添加的附加参数
- *multi_leg_bye_info** - 由 *multi_leg_bye_info* 参数添加的附加参数
- *duration* - 通话时长（秒）
- *ms_duration* - 通话时长（毫秒）
- *setuptime* - 通话建立时间（秒）
- *created* - 通话创建时的时间戳（收到初始 Invite 时）

#### E_ACC_EVENT

使用旧式记费时触发此事件。当请求（INVITE 和 BYE）事务有正面最终回复时生成，或由 `acc_evi_request()` 函数在注释中包含正面回复代码时生成。

参数：

- *method* - 请求方法名
- *from_tag* - From 头域 tag 参数
- *to_tag* - To 头域 tag 参数
- *callid* - 消息 Call-id
- *sip_code* - 最终回复的状态码
- *sip_reason* - 最终回复的状态原因
- *time* - 事务创建时的时间戳
- *evi_extra** - 由 *evi_extra* 参数添加的附加参数
- *multi_leg_info** - 由 *multi_leg_info* 参数添加的附加参数

#### E_ACC_MISSED_EVENT

使用旧式记费时触发此事件。当请求（INVITE 和 BYE）事务有负面最终回复时生成，或由 `acc_evi_request()` 函数在注释中包含负面回复代码时生成。

参数：

- *method* - 请求方法名
- *from_tag* - From 头域 tag 参数
- *to_tag* - To 头域 tag 参数
- *callid* - 消息 Call-id
- *sip_code* - 最终回复的状态码
- *sip_reason* - 最终回复的状态原因
- *time* - 事务创建时的时间戳
- *evi_extra** - 由 *evi_extra* 参数添加的附加参数
- *multi_leg_info** - 由 *multi_leg_info* 参数添加的附加参数
- *created* - 通话创建时的时间戳
- *setuptime* - 通话建立时间（秒）

## 常见问题

**Q: 旧的 report_ack 参数发生了什么**

该参数已被视为过时。它被移除是因为 acc 模块进行的是基于 SIP 事务的记费，根据 SIP RFC，端到端 ACK 是不同的事务（仍属于同一对话框的一部分）。ACK 可以像任何其他顺序（对话框内）请求一样单独记费。

**Q: 旧的 log_fmt 参数发生了什么**

由于 ACC 模块记录的数据结构重组，该参数已变得过时（请参阅概述章节）。要获得类似的行为，您可以使用额外记费（请参阅相应章节）。

**Q: 旧的 multi_leg_enabled 参数发生了什么**

该参数已被新的 multi_leg_info 参数取代。当定义 multi_leg_info 时，多分支记费会自动启用。

**Q: 旧的 src_leg_avp_id 和 dst_leg_avp_id 参数发生了什么**

该参数已被更通用新参数 multi_leg_info 取代。这允许（按分支）记录比仅 dst 和 src 更多的信息。

**Q: 在哪里可以找到更多关于 OpenSIPS 的信息？**

请查看 [https://opensips.org/](https://opensips.org/)。

**Q: 在哪里可以发布关于此模块的问题？**

首先请检查您的问题是否已在我们的邮件列表中回答：

任何稳定 OpenSIPS 版本的相关邮件应发送至 users@lists.opensips.org，开发版本的相关邮件应发送至 devel@lists.opensips.org。

如果您想保持邮件私密，请发送至 users@lists.opensips.org。

**Q: 如何报告错误？**

请遵循以下指南：[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。

<!-- 贡献者 -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享许可协议 4.0 版授权。
