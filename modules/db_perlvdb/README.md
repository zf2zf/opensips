---
title: "Perl 虚拟数据库模块"
description: "Perl 虚拟数据库（VDB）为 OpenSIPS 的数据库访问提供了一个虚拟化框架。它本身不处理特定的数据库引擎，而是让用户将数据库请求中继到任意 Perl 函数。"
---

## 管理指南


### 概述


Perl 虚拟数据库（VDB）为 OpenSIPS 的数据库访问提供了一个虚拟化框架。
它本身不处理特定的数据库引擎，而是让用户将数据库请求
中继到任意 Perl 函数。


此模块不能"开箱即用"。用户必须提供
专用于客户端模块的功能。请参阅下文了解选项。


该模块可用于所有需要数据库访问的当前 OpenSIPS 模块。
支持中继 insert、update、query 和 delete 操作。


模块可以配置为使用 db_perlvdb 模块作为
数据库后端，使用 db_url_parameter：


```c
modparam("acc", "db_url", "perlvdb:OpenSIPS::VDB::Adapter::AccountingSIPtrace")
```


此配置选项告诉 acc 模块它应该使用
db_perlvdb 模块，而该模块将使用 Perl 类
OpenSIPS::VDB::Adapter::AccountingSIPtrace
来中继数据库请求。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *perl* -- Perl 模块


#### 外部库或应用程序


以下库或应用程序必须在运行
加载了此模块的 OpenSIPS 之前安装：


- *无*（除 perl 模块文档中提到的那些）。


### 导出的参数


*无*。


### 导出的函数


*无*。


## 开发者指南


### 简介


OpenSIPS 使用数据库 API 来请求多种不同类型的数据。
支持四种主要操作：


- query
- insert
- update
- delete


此模块将这些数据库请求中继到用户实现的
Perl 函数。


### 基类 OpenSIPS::VDB


客户端模块必须配置为将 db_perlvdb 模块与提供函数的
Perl 类结合使用。配置的类需要继承自基类 `OpenSIPS::VDB`。


派生类必须实现必要的函数 "query"、"insert"、"update" 和/或 "delete"。
客户端模块指定必要的函数。
要找出模块调用了哪些函数，可以评估其进程
使用 `OpenSIPS::VDB::Adapter::Describe` 类，该类将记录传入的请求（而不实际提供任何真实功能）。


虽然用户可以直接在与 OpenSIPS::VDB 派生的类中实现所需功能，
但建议将实现拆分为一个适配器，该适配器将关系结构化参数转换为纯
Perl 函数参数，并添加一个虚拟表（VTab）以提供到底层技术的中继。


### 数据类型


在介绍此模块的更高级概念之前，
将简要解释使用的数据类型。
OpenSIPS Perl 库包含一些必须在此模块中使用的数据类型：


#### OpenSIPS::VDB::Value


一个值包含数据类型标志和值。有效的数据类型为
DB_INT、DB_DOUBLE、DB_STRING、DB_STR、DB_DATETIME、DB_BLOB、DB_BITMAP。
可以用以下方式创建新变量：


```c
my $val = new OpenSIPS::VDB::Value(DB_STRING, "foobar");
```


值对象包含 type() 和 data() 方法来获取或设置类型和数据属性。


#### OpenSIPS::VDB::Pair


Pair 类派生自 Value 类，还包含列名（键）。
可以用以下方式创建新变量：


```c
my $pair = new OpenSIPS::VDB::Pair("foo", DB_STRING, "bar");
```


其中 foo 是键，bar 是值。
除了 Value 类的方法外，它还包含 key() 方法来获取或设置键属性。


#### OpenSIPS::VDB::ReqCond


ReqCond 类用于选择条件，派生自 Pair 类。
它包含一个额外的运算符属性。
可以用以下方式创建新变量：


```c
my $cond = new OpenSIPS::VDB::ReqCond("foo", ">", DB_INT, 5);
```


其中 foo 是键，"greater" 是运算符，5 是要比较的值。
除了 Pair 类的方法外，它还包含 op() 方法来获取或设置运算符属性。


#### OpenSIPS::VDB::Column


此类表示列定义或数据库模式。它包含
列名数组和列类型数组。这两个数组需要具有相同的长度。
可以用以下方式创建新变量：


```c
my @types = { DB_INT, DB_STRING };
my @names = { "id", "vals" };
my $cols = new OpenSIPS::VDB::Column(\@types, \@names);
```


该类包含 type() 和 name() 方法来获取或设置类型和名称数组。


#### OpenSIPS::VDB::Result


Result 类表示查询结果。它包含一个模式（Column 类）
和一行数组，其中每一行都是一个 Values 数组。可以使用对象方法
coldefs() 和 rows() 来获取和设置对象属性。


### 适配器


适配器应用于将关系结构化数据库请求转换为
纯 Perl 函数参数。例如 alias_db 函数 alias_db_lookup
接受 user/host 对，并将其转换为另一个 user/host 对。
Alias 适配器将 ReqCond 数组转换为两个独立标量，用作 VTab 调用的参数。


适配器类必须继承自 OpenSIPS::VDB 基类，并且可以提供一个或多个
名为 insert、update、replace、query 和/或 delete 的函数，
具体取决于要使用适配器的模块。虽然诸如 alias_db 之类的模块只需要 query 函数，
但其他（如 siptrace）仅依赖插入。


#### 函数参数


实现的函数需要处理正确的数据类型。参数和返回类型列在本节中。


*insert()* 接收 OpenSIPS::VDB::Pair 对象数组。
它应返回一个整数值。


*replace()* 接收 OpenSIPS::VDB::Pair 对象数组。
此函数目前不被任何公开可用的模块使用。
它应返回一个整数值。


*delete()* 接收 OpenSIPS::VDB::ReqCond 对象数组。
它应返回一个整数值。


*update()* 接收 OpenSIPS::VDB::ReqCond 对象数组
（要更新哪些行）和 OpenSIPS::VDB::Pair 对象数组
（新数据）。
它应返回一个整数值。


*query()* 接收 OpenSIPS::VDB::ReqCond 对象数组
（选择哪些行）、字符串数组（返回哪些列名）
和一个用于排序的列字符串。
它应返回一个 OpenSIPS::VDB::Result 类型的对象。


### VTabs


VTabs（虚拟表）为适配器提供特定实现。例如，Alias
适配器使用两个参数（user、host）调用函数，并期望返回一个包含
两个元素 username 和 domain 的哈希，或者当没有结果时返回 undef。
Alias 适配器的示例 VTab 实现通过包含别名数据的 Perl 哈希演示了此技术。


标准 Adapter/VTab 模式让用户选择三种方式来实现 VTabs：


- *单函数*。当函数用作虚拟表时，
传递操作名称（insert、replace、update、query、delete）作为其第一个参数。
该函数可以在主命名空间中实现。


- *包/类*。定义的类需要
有一个 init() 函数。它将在该 VTab 的第一次调用期间被调用。
此外，包必须定义必要的函数 insert、replace、update、delete 和/或 query。
这些函数将以函数上下文调用（第一个参数是类名）。


- *对象*。定义的类需要有一个 new() 函数，该函数将返回对新创建对象的引用。
此对象需要定义必要的函数 insert、replace、update、delete 和/或 query。
这些函数将以方法上下文调用（第一个参数是对对象的引用）。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0
