---
title: "textops Module"
description: "该模块实现对 OpenSIPS 处理的 SIP 消息的基于文本的操作。SIP 是一个基于文本的协议，该模块提供了一组丰富的非常有用的函数来在文本级别上操作消息，例如正则表达式搜索和替换、类似 Perl 的替换等。"
---

## 管理指南


### 概述


该模块实现对 OpenSIPS 处理的 SIP 消息的基于文本的操作。SIP 是一个基于文本的协议，该模块提供了一组丰富的非常有用的函数来在文本级别上操作消息，例如正则表达式搜索和替换、类似 Perl 的替换等。


注意：所有 SIP 感知的函数如 *insert_hf*、
*append_hf* 或 *codec* 操作已移至 *sipmsgops* 模块。


#### 已知限制


搜索会忽略折叠的行。例如，
search("(From|f):.*@foo.bar")
不会匹配以下 From 头字段：


```c
From: medabeda 
 <sip:medameda@foo.bar>;tag=1234
```


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *无其他 OpenSIPS 模块的依赖*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *无*。


### 导出的函数


#### search(re)


在消息中搜索 re。


参数含义如下：


- *re* (string) - 正则表达式。


此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。


```c title="search 使用示例"
...
if ( search("[Ss][Ii][Pp]") ) { /*....*/ };
...
```


#### search_body(re)


在消息的正文中搜索 re。


参数含义如下：


- *re* (string) - 正则表达式。


此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。


```c title="search_body 使用示例"
...
if ( search_body("[Ss][Ii][Pp]") ) { /*....*/ };
...
```


#### search_append(re, txt)


搜索 re 的第一个匹配项并在其后追加 txt。


参数含义如下：


- *re* (string) - 正则表达式。
- *txt* (string) - 要追加的字符串。


此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。


```c title="search_append 使用示例"
...
search_append("[Oo]pen[Ss]er", " SIP Proxy");
...
```


#### search_append_body(re, txt)


在消息正文中搜索 re 的第一个匹配项并在其后追加 txt。


参数含义如下：


- *re* (string) - 正则表达式。
- *txt* (string) - 要追加的字符串。


此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。


```c title="search_append_body 使用示例"
...
search_append_body("[Oo]pen[Ss]er", " SIP Proxy");
...
```


#### replace(re, txt)


用 txt 替换 re 的第一个匹配项。


参数含义如下：


- *re* (string) - 正则表达式。
- *txt* (string)


此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。


```c title="replace 使用示例"
...
replace("opensips", "Open SIP Server");
...
```


#### replace_body(re, txt)


将消息正文中 re 的第一个匹配项替换为 txt。


参数含义如下：


- *re* (string) - 正则表达式。
- *txt* (string)


此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。


```c title="replace_body 使用示例"
...
replace_body("opensips", "Open SIP Server");
...
```


#### replace_all(re, txt)


用 txt 替换 re 的所有匹配项。


参数含义如下：


- *re* - (string) 正则表达式。
- *txt* (string)


此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。


```c title="replace_all 使用示例"
...
replace_all("opensips", "Open SIP Server");
...
```


#### replace_body_all(re, txt)


将消息正文中 re 的所有匹配项替换为 txt。按行进行匹配。


参数含义如下：


- *re* (string) - 正则表达式。
- *txt* (string)


此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。


```c title="replace_body_all 使用示例"
...
replace_body_all("opensips", "Open SIP Server");
...
```


#### replace_body_atonce(re, txt)


将消息正文中 re 的所有匹配项替换为 txt。对整个正文进行匹配。


参数含义如下：


- *re* (string) - 正则表达式。
- *txt* (string)


此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。


```c title="replace_body_atonce 使用示例"
...
# 从消息中剥离整个正文：
if(has_body() && replace_body_atonce("^.+$", ""))
        remove_hf("Content-Type"); 
...
```


#### subst('/re/repl/flags')


用 repl 替换 re（sed 或 perl 风格）。


参数含义如下：


- *'/re/repl/flags'* (string) - sed 风格正则表达式。flags 可以是 i（不区分大小写）、g（全局）或 s（匹配换行符，不将其视为行尾）的组合。
're' - 是正则表达式
'repl' - 是替换字符串——可以包含伪变量
'flags' - 替换标志（i - 忽略大小写，g - 全局）


此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。


```c title="subst 使用示例"
...
# 将 to: 中的 uri 替换为消息 uri（仅作为示例）
if ( subst('/^To:(.*)sip:[^@]*@[a-zA-Z0-9.]+(.*)$/t:\1\u\2/ig') ) {};

/# 将 to: 中的 uri 替换为 avp sip_address 的值（仅作为示例）
if ( subst('/^To:(.*)sip:[^@]*@[a-zA-Z0-9.]+(.*)$/t:\1$avp(sip_address)\2/ig') ) {};

...
```


#### subst_uri('/re/repl/flags')


对消息 uri 运行 re 替换（如 subst，但仅对 uri 工作）


参数含义如下：


- *'/re/repl/flags'* (string) - sed 风格正则表达式。flags 可以是 i（不区分大小写）、g（全局）或 s（匹配换行符，不将其视为行尾）的组合。
're' - 是正则表达式
'repl' - 是替换字符串——可以包含伪变量
'flags' - 替换标志（i - 忽略大小写，g - 全局）


此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。


```c title="subst_uri 使用示例"
...
# 为数字 uri 添加 3463 前缀，并将原始 uri（\0 匹配）保存为参数：orig_uri（仅作为示例）
if (subst_uri('/^sip:([0-9]+)@(.*)$/sip:3463\1@\2;orig_uri=\0/i')){$

# 将 avp 'uri_prefix' 添加为数字 uri 的前缀，并将原始 uri（\0 匹配）保存为参数：orig_uri（仅作为示例）
if (subst_uri('/^sip:([0-9]+)@(.*)$/sip:$avp(uri_prefix)\1@\2;orig_uri=\0/i')){$

...
```


#### subst_user('/re/repl/flags')


对消息 uri（如同 subst_uri，但仅对 uri 的用户部分工作）运行 re 替换


参数含义如下：


- *'/re/repl/flags'* (string) - sed 风格正则表达式。flags 可以是 i（不区分大小写）、g（全局）或 s（匹配换行符，不将其视为行尾）的组合。
're' - 是正则表达式
'repl' - 是替换字符串——可以包含伪变量
'flags' - 替换标志（i - 忽略大小写，g - 全局）


此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。


```c title="subst 使用示例"
...
# 为以 3642 结尾的 uri 添加 3463 前缀（仅作为示例）
if (subst_user('/3642$/36423463/')){$

...
# 为 r-uri 中以 3642 结尾的用户名添加 avp 'user_prefix' 作为前缀
if (subst_user('/(.*)3642$/$avp(user_prefix)\13642/')){$

...
```


#### subst_body('/re/repl/flags')


在消息正文中用 repl 替换 re（sed 或 perl 风格）。


参数含义如下：


- *'/re/repl/flags'* (string) - sed 风格正则表达式。flags 可以是 i（不区分大小写）、g（全局）或 s（匹配换行符，不将其视为行尾）的组合。
're' - 是正则表达式
'repl' - 是替换字符串——可以包含伪变量
'flags' - 替换标志（i - 忽略大小写，g - 全局）


此函数可以从 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。


```c title="subst_body 使用示例"
...
if (subst_body("/^o=([^ ]*) /o=$fU /"))
	xlog("成功准备了 "o" 行更新！\n");

...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享署名 4.0 国际许可协议授权。
