---
title: "Regex 模块"
description: "此模块使用强大的 [PCRE](http://www.pcre.org/) 库提供正则表达式匹配操作。"
---

## 管理指南


### 概述


此模块使用强大的 [PCRE](http://www.pcre.org/) 库提供正则表达式匹配操作。


加载模块时，一个包含按组分类的正则表达式的文本文件被编译，编译后的 PCRE 对象存储在数组中。提供了一个函数，用于将字符串或伪变量与任何这些组进行匹配。文本文件可以随时通过 MI 命令修改和重新加载。该模块还提供了一个函数，用于对作为函数参数提供的正则表达式执行 PCRE 匹配操作。


有关 PCRE 功能的详细信息，请阅读库的 [man page](http://www.pcre.org/pcre.txt)。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他 OpenSIPS 模块*。


#### 外部库或应用程序


以下库或应用程序必须在运行加载了此模块的 OpenSIPS 之前安装：


- *libpcre-dev - [PCRE](http://www.pcre.org/) 的开发库*。


### 导出的参数


#### file (string)


包含正则表达式组的文本文件。必须设置此参数才能启用组匹配功能。


*默认值为 "NULL"。*


```c title="设置 file 参数"
...
modparam("regex", "file", "/etc/opensips/regex_groups")
...
```


#### max_groups (int)


文本文件中最多的正则表达式组数量。


*默认值为 "20"。*


```c title="设置 max_groups 参数"
...
modparam("regex", "max_groups", 40)
...
```


#### group_max_size (int)


文本文件中每个组的最大内容大小。


*默认值为 "8192"。*


```c title="设置 group_max_size 参数"
...
modparam("regex", "group_max_size", 16384)
...
```


#### pcre_caseless (int)


如果设置此选项，则进行不区分大小写的匹配。它等效于 Perl 的 /i 选项，可以通过 (?i) 或 (?-i) 选项设置在模式中更改。


*默认值为 "0"。*


```c title="设置 pcre_caseless 参数"
...
modparam("regex", "pcre_caseless", 1)
...
```


#### pcre_multiline (int)


默认情况下，PCRE 将主题字符串视为由一行字符组成（即使它实际上包含换行符）。"行首"元字符 (^) 仅在字符串开头匹配，而"行尾"元字符 ($) 仅在字符串末尾或终止换行符之前匹配。


设置此选项后，"行首"和"行尾"构造分别匹配主题字符串中换行符之后或之前的紧邻位置，以及字符串的最开始和最末尾。这等效于 Perl 的 /m 选项，可以通过模式中的 (?m) 或 (?-m) 选项设置进行更改。如果主题字符串中没有换行符，或者模式中没有 ^ 或 $ 的出现，设置此选项无效。


*默认值为 "0"。*


```c title="设置 pcre_multiline 参数"
...
modparam("regex", "pcre_multiline", 1)
...
```


#### pcre_dotall (int)


如果设置此选项，模式中的点元字符匹配所有字符，包括表示换行符的字符。没有此选项时，点在当前位置是换行符时不匹配。此选项等效于 Perl 的 /s 选项，可以通过模式中的 (?s) 或 (?-s) 选项设置进行更改。


*默认值为 "0"。*


```c title="设置 pcre_dotall 参数"
...
modparam("regex", "pcre_dotall", 1)
...
```


#### pcre_extended (int)


如果设置此选项，模式中的空白数据字符将被完全忽略，除非是转义的或位于字符类内部。空白不包括 VT 字符（代码 11）。此外，位于字符类外部的未转义 # 与下一个换行符之间的字符（包括换行符）也会被忽略。这等效于 Perl 的 /x 选项，可以通过模式中的 (?x) 或 (?-x) 选项设置进行更改。


*默认值为 "0"。*


```c title="设置 pcre_extended 参数"
...
modparam("regex", "pcre_extended", 1)
...
```


### 导出的函数


#### pcre_match (string, pcre_regex [, match])


将给定的字符串参数与正则表达式 pcre_regex 进行匹配，该正则表达式被编译为 PCRE 对象。如果匹配返回 TRUE，否则返回 FALSE。当提供可选的 match 参数时，它被设置为字符串的匹配部分，如果没有匹配则清除。


参数的含义如下：


- *string* - 要比较的字符串。
- *pcre_regex* (string) - 要编译为 PCRE 对象的正则表达式。
- *match* (var, 可选) - 用于存储字符串匹配部分的可用变量。


注意：要使用 pcre_regex 参数中的"行尾"符号 '$'，请使用 '$$'。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="pcre_match 用法（强制不区分大小写）"
...
if (pcre_match("$ua", "(?i)^twinkle")) {
    xlog("L_INFO", "User-Agent matches\n");
}
...
```


```c title="pcre_match 用法（使用'行尾'符号）"
...
if (pcre_match($rU, "^user[1234]$$")) {  # 将被转换为 "^user[1234]$"
    xlog("L_INFO", "RURI username matches\n");
}
...
```


#### pcre_match_group (string [, group])


使用从文本文件读取的组（参见 [文件格式 id](#file_format)）将给定的字符串参数与第 group 组的编译正则表达式进行匹配。如果匹配返回 TRUE，否则返回 FALSE。


参数的含义如下：


- *string* - 要比较的字符串。
- *group* (int) - 操作中使用的组。如果未指定，则使用 0（第一组）。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="pcre_match_group 用法"
...
if (pcre_match_group($rU, 2)) {
    xlog("L_INFO", "RURI username matches group 2\n");
}
...
```


### 导出的 MI 函数


#### regex:reload


替换已弃用的 MI 命令：*regex_reload*。


使 regex 模块重新读取文本文件内容并重新编译正则表达式。可以安全地修改文件中的组数量。


名称：*regex:reload*


参数：*无*


MI FIFO 命令格式：


```c
...
opensips-cli -x mi regex:reload
...
```


#### regex:match


替换已弃用的 MI 命令：*regex_match*。


将给定的字符串参数与正则表达式 pcre_regex 进行匹配。如果匹配返回 "Match"，否则返回 "Not Match"。


名称：*regex:match*


参数：


- string
- pcre_regex


MI FIFO 命令格式：


```c
...
opensips-cli -x mi regex:match string="1234" pcre_regex="^1234$"
"Match"
opensips-cli -x mi regex:match string="1234" pcre_regex="^1235$"
"Not Match"
...
```


#### regex:match_group


替换已弃用的 MI 命令：*regex_match_group*。


使用从文本文件读取的组将给定的字符串参数与第 group 组的编译正则表达式进行匹配。如果匹配返回 "Match"，否则返回 "Not Match"。


名称：*regex:match_group*


参数：


- string
- group


MI FIFO 命令格式：


```c
...
opensips-cli -x mi regex:match_group string="1234" group="0"
"Match"
opensips-cli -x mi regex:match_group string="1234" group="1"
"Not Match"
...
```


### 安装和运行


#### 文件格式


文件包含按组分类的正则表达式。每个组以 "[number]" 行开始。以空格、制表符、CR、LF 或 #（注释）开头的行将被忽略。每个正则表达式必须只占一行，这意味着正则表达式不能分成多行。


文件格式的示例如下：


```c title="regex 文件"
### 发布存在状态的 User-Agent 列表
[0]

# 软电话
^Twinkle/1
^X-Lite
^eyeBeam
^Bria
^SIP Communicator
^Linphone

# 桌上电话
^Snom

# 其他
^SIPp
^PJSUA


### 黑名单源 IP
[1]

^190\.232\.250\.226$
^122\.5\.27\.125$
^86\.92\.112\.


### 西班牙免费 PSTN 目的地
[2]

^1\d{3}$
^((\+|00)34)?900\d{6}$
```


模块将上述文本编译为以下正则表达式：


```c
group 0: ((^Twinkle/1)|(^X-Lite)|(^eyeBeam)|(^Bria)|(^SIP Communicator)|
          (^Linphone)|(^Snom)|(^SIPp)|(^PJSUA))
group 1: ((^190\.232\.250\.226$)|(^122\.5\.27\.125$)|(^86\.92\.112\.))
group 2: ((^1\d{3}$)|(^((\+|00)34)?900\d{6}$))
```


第一组可用于避免对已支持存在的 UA 生成自动发布的 PUBLISH（pua_usrloc 模块）：


```c title="与 pua_usrloc 一起使用"
route[REGISTER] {
    if (! pcre_match_group("$ua", 0)) {
        xlog("L_INFO", "Auto-generated PUBLISH for $fu ($ua)\n");
        pua_set_publish();
    }
    save("location");
    exit;
}
```


注意：重要的是要理解每个组头（[number]）中的数字必须从 0 开始。如果不是，真实的组号将与文件中的数字不匹配。例如，以下文本文件：


```c title="错误的组文件"
[1]
^aaa
^bbb

[2]
^ccc
^ddd
```


将生成以下正则表达式：


```c
group 0: ((^aaa)|(^bbb))
group 1: ((^ccc)|(^ddd))
```


请注意，真实的索引与文件中的组号不匹配。即，编译后的组 0 始终指向文件中的第一组，而不管其在文件中的编号是多少。实际上，文件中出现的组号仅用于分隔不同的组。


注意：包含正则表达式的行不能以 '[' 开头，因为它会被当作新组。空格、制表符或 '#' 开头的行也是如此（它们将被解析器忽略）。作为解决方法，使用括号可以工作：


```c
[0]
([0-9]{9})
( #abcde)
( qwerty)
```
<!-- CONTRIBUTORS -->

### 许可

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0 版授权
