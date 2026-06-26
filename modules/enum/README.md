---
title: "ENUM 模块"
description: "Enum 模块实现了 [i_]enum_query 函数，该函数基于当前 Request-URI 的用户部分执行 enum 查询。这些函数假定用户部分由 +十进制数字形式的国际电话号码组成，其中数字位数至少为 2 位，最多 15 位。"
---

## 管理指南

### 概述

Enum 模块实现了 [i_]enum_query 函数，该函数基于当前 Request-URI 的用户部分执行 enum 查询。这些函数假定用户部分由 +十进制数字形式的国际电话号码组成，其中数字位数至少为 2 位，最多 15 位。`enum_query` 根据此号码形成一个域名，其中数字以相反顺序排列，用点分隔，后跟域名后缀，默认为 "e164.arpa."。例如，如果用户部分是 +35831234567，则域名将为 "7.6.5.4.3.2.1.3.8.5.3.e164.arpa."。`i_enum_query` 以类似方式操作。唯一的区别是它添加了一个标签（默认为 "i"），以从默认的用户 ENUM 树分支到基础设施 ENUM 树。

形成域名后，`enum_query` 向 DNS 查询其 NAPTR 记录。从可能的响应中，`enum_query` 选择那些 flags 字段字符串值为 "u"、services 字段字符串值为 "e2u+[service:]sip" 或 "e2u+type[:subtype][+type[:subype]..."（两种情况下都忽略大小写）、regexp 字段格式为 !pattern!replacement! 的记录。

然后，`enum_query` 根据其 <order, preference> 对所选的 NAPTR 记录进行排序。排序后，`enum_query` 通过将最优先的 NAPTR 记录的 regexp 应用于其用户部分来替换当前 Request URI，并通过将每个剩余 NAPTR 记录的 regexp 应用于当前 Request URI 的用户部分来向请求追加新分支。如果新 URI 是 tel URI，`enum_query` 将 tel_uri_params 模块参数的值作为 tel URI 参数追加到它。最后，`enum_query` 根据相应 NAPTR 记录的 <order, preference> 为每个新 URI 关联一个 q 值。

当不带任何参数使用 `enum_query` 时，它在默认 enum 树中搜索服务类型为 "e2u+sip" 的 NAPTR。当使用带单个参数的 `enum_query` 时，此参数将用作 enum 树。当使用带两个参数的 `enum_query` 时，功能取决于第二个参数中的第一个字母。当第一个字母不是 '+' 符号时，第二个参数将用于搜索服务类型为 "e2u+parameter:sip" 的 NAPTR。当第二个参数以 '+' 符号开头时，ENUM 查找还支持复合 NAPTR（例如 "e2u+voice:sip+video:sip"）并在一个查找中搜索多种服务类型。多种服务类型必须用 '+' 符号分隔。

大多数时候您希望基于 RURI 进行路由。很少有情况下您可能希望基于其他内容进行路由。函数 `enum_pv_query` 模仿 `enum_query` 函数的行为，只是使用其伪变量参数中的 E.164 号码进行 enum 查找，而不是 RURI 的用户部分。显然，RURI 的用户部分仍用于 NAPTR regexp。

如果当前 Request URI 被替换，enum 查询返回 1；如果没有，则返回 -1。

除了标准 ENUM，还支持 ISN（ITAD 订户号码）。要允许 ISN 查找解析，DNS 服务器需要不同的格式算法。ENUM NAPTR 记录期望的 DNS 查询形式为 9.8.7.6.5.4.3.2.1.suffix，而 ISN 方法期望的 DNS 查询形式为 6.5.1212.suffix。也就是说，有效的 ISN 号码在示例中包含 '56' 前缀。号码的其余部分是 ITAD（互联网电话管理域），如 RFC 3872 和 2871 中所定义，并在 http://www.iana.org/assignments/trip-parameters 中由 IANA 分配。ITAD 保持不变，不像 ENUM 那样反转。要了解更多关于 ISN 的信息，请参阅 www.freenum.org 上的文档。

要在 Request-URI 的用户部分上完成 ISN 查找，使用 isn_query() 而不是 enum_query()。

Enum 模块还实现了 is_from_user_enum 函数。此函数对 from 用户执行 enum 查找，如果找到则返回 true，否则返回 false。

### 依赖

该模块依赖以下模块（换句话说，列出的模块必须在此模块之前加载）：

- 无依赖。

### 导出的参数

#### domain_suffix (string)

添加到从 E164 数字获取的域名的域名后缀。可以被 enum_query 的参数覆盖。

默认值为 "e164.arpa."

```c title="设置 domain_suffix 模块参数"
modparam("enum", "domain_suffix", "e1234.arpa.")
```

#### tel_uri_params (string)

作为 tel URI 参数追加到请求中每个新 tel URI 的内容。

> [!NOTE]
> 目前 OpenSIPS 不支持 tel URI。这意味着目前 tel_uri_params 作为 URI 参数追加到每个 URI。

默认值为 ""

```c title="设置 tel_uri_params 模块参数"
modparam("enum", "tel_uri_params", ";npdi")
```

#### i_enum_suffix (string)

用于 i_enum_query() 查找的域名后缀。可以被 i_enum_query 的参数覆盖。

默认值为 "e164.arpa."

```c title="设置 i_enum_suffix 模块参数"
modparam("enum", "i_enum_suffix", "e1234.arpa.")
```

#### isn_suffix (string)

用于 isn_query() 查找的域名后缀。可以被 isn_query 的参数覆盖。

默认值为 "freenum.org."

```c title="设置 isn_suffix 模块参数"
modparam("enum", "isn_suffix", "freenum.org.")
```

#### branchlabel (string)

此参数决定 i_enum_query() 将使用哪个标签从用户 ENUM 树分支到基础设施 ENUM 树。

默认值为 ""i""

```c title="设置 branchlabel 模块参数"
modparam("enum", "branchlabel", "i")
```

#### bl_algorithm (string)

此参数决定 i_enum_query() 将使用哪种算法来选择在 DNS 树中基础设施树从用户 ENUM 树分支的位置。

如果设置为 "cc"，i_enum_query() 将始终在国家代码级别插入标签。
示例：i.1.e164.arpa, i.3.4.e164.arpa, i.2.5.3.e164.arpa

如果设置为 "txt"，i_enum_query() 将在 [branchlabel].[reverse-country-code].[i_enum_suffix] 查找 TXT 记录，以指示标签应插入在多少个数字之后。

```c title="区域文件示例"
i.1.e164.arpa.                     IN TXT   "4"
9.9.9.8.7.6.5.i.4.3.2.1.e164.arpa. IN NAPTR "NAPTR content for  +1 234 5678 999"
```

如果设置为 "ebl"，i_enum_query() 将在 [branchlabel].[reverse-country-code].[i_enum_suffix] 查找 EBL（ENUM 分支标签）记录。有关该记录和字段含义的描述，请参阅 http://www.ietf.org/internet-drafts/draft-lendl-enum-branch-location-record-00.txt。EBL 的 RR 类型尚未分配。此代码版本使用 65300。请参阅 resolve.h。

```c title="区域文件示例"
i.1.e164.arpa.     TYPE65300  \# 14 (
                              04    ; position
                              01 69 ; separator
                              04 65 31 36 34 04 61 72 70 61 00 ; e164.arpa
;                               )
9.9.9.8.7.6.5.i.4.3.2.1.e164.arpa. IN NAPTR "NAPTR content for  +1 234 5678 999"
```

默认值为 "cc"

```c title="设置 bl_algorithm 模块参数"
modparam("enum", "bl_algorithm", "txt")
```

### 导出的函数

#### enum_query([suffix], [service], [number])

该函数对给定的 E.164 "number"（如果缺少 "number" 则为 R-URI 用户名）执行 ENUM 查询，并使用查询结果重写 Request-URI。有关更多信息，请参阅[概述](#overview)。

参数的含义如下：

- *suffix (string, 可选)* - 追加到域名的后缀，如果缺失则使用[域名后缀](#param_domain_suffix)
- *service (string, 可选)* - 服务字段中使用的服务字符串
- *number (string, 可选)* - 作为字符串打包的特定 E.164 号码，用于执行 ENUM 查询（如果缺失则使用 R-URI 用户名 ($rU)）

此函数可以从 REQUEST_ROUTE 使用。

```c title="enum_query 用法"
...
# 在 freenum.org 中搜索 "e2u+sip"
enum_query("freenum.org.", , $avp(number));
...
# 在默认树中搜索 "e2u+sip"（配置为参数）
enum_query();
...
# 在 e164.arpa 中搜索 "e2u+voice:sip"
enum_query("e164.arpa.", "voice");
...
# 搜索服务类型 "sip" 或 "voice:sip" 或 "video:sip"
# 注意第二个参数前面的 '+' 符号
enum_query("e164.arpa.", "+sip+voice:sip+video:sip", $avp(number));
...
# 查询 sip 和 voice:sip 服务
enum_query("e164.arpa.");
enum_query("e164.arpa.", "voice");
# 或使用
enum_query("e164.arpa.", "+sip+voice:sip");
...
```

#### i_enum_query([suffix], [service])

该函数执行 enum 查询并使用查询结果重写 Request-URI。这是 enum_query() 的基础设施 ENUM 版本。与 enum_query() 的唯一区别在于计算查找 NAPTR 记录的 FQDN 的方式。

参数的含义如下：

- *suffix (string, 可选)* - 追加到域名的后缀，如果缺失则使用[i enum 后缀](#param_i_enum_suffix)
- *service (string, 可选)* - 服务字段中使用的服务字符串

有关此函数背后的原理，请参阅 ftp://ftp.rfc-editor.org/in-notes/internet-drafts/draft-haberler-carrier-enum-01.txt。

#### isn_query([suffix], [service])

该函数执行 ISN 查询并使用查询结果重写 Request-URI。有关更多信息，请参阅[概述](#overview)。

参数的含义如下：

- *suffix (string, 可选)* - 追加到域名的后缀，如果缺失则使用[isn 后缀](#param_isn_suffix)
- *service (string, 可选)* - 服务字段中使用的服务字符串

此函数可以从 REQUEST_ROUTE 使用。

有关 ISN 字符串的 ITAD 部分的更多信息，请参阅 ftp://www.ietf.org/rfc/rfc3872.txt 和 ftp://www.ietf.org/rfc/rfc2871.txt。

```c title="isn_query 用法"
...
# 在 freenum.org 中搜索 "e2u+sip"
isn_query("freenum.org.");
...
# 在默认树中搜索 "e2u+sip"（配置为参数）
isn_query();
...
# 在 freenum.org 中搜索 "e2u+voice:sip"
isn_query("freenum.org.", "voice");
...
```

#### is_from_user_enum([suffix], [service])

检查 from URI 的用户部分是否在 enum 查找中找到。
如果是则返回 1，否则返回 -1。

参数的含义如下：

- *suffix (string, 可选)* - 追加到域名的后缀，如果缺失则使用[域名后缀](#param_domain_suffix)
- *service (string, 可选)* - 服务字段中使用的服务字符串

此函数可以从 REQUEST_ROUTE 使用。

```c title="is_from_user_enum 用法"
...
if (is_from_user_enum()) {
	....
};
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
