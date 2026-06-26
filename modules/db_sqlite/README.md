---
title: "db_sqlite 模块"
description: "这是为 OpenSIPS 提供 SQLite 支持的模块。它实现了 OpenSIPS 中定义的 DB API。"
---

## 管理指南


### 概述


这是为 OpenSIPS 提供 SQLite 支持的模块。
它实现了 OpenSIPS 中定义的 DB API。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他 OpenSIPS 模块*。


此外，此模块提供两种创建查询的方式。一种是使用
sqlite3_bind_* 函数，在 opensips 创建预处理语句查询之后。
第二种直接使用 sqlite3_snprintf 函数将值打印到
opensips 创建的查询中。理论上，第二种方式应该
更快，并且应该允许您同时对数据库进行更多查询，
因此默认情况下会激活这种方式。您可以通过简单取消注释
Makefile 中的 SQLITE_BIND 行来使用 sqlite3_bind_* 接口。


#### 外部库或应用程序


以下库或应用程序必须在运行
加载了此模块的 OpenSIPS 之前安装：


- *libsqlite3-dev* - sqlite 的开发库。


### 导出的参数


#### alloc_limit (integer)


由于库不支持返回查询行数的函数，
因此使用 "count(*)" 查询来获取此数字。如果我们使用多个进程，
存在风险，因为在 "count(*)" 查询和实际的 "select"
查询之间，结果查询中的行数可能已更改，
因此如果数字更大，将需要 realloc。
使用 *alloc_limit* 参数，您可以指定
结果中分配行数增加的次数。


*默认值为 10。*


```c title="设置 alloc_limit 参数"
...
modparam("db_sqlite", "alloc_limit", 25)
...
```


#### load_extension (string)


此参数启用扩展加载，类似于 sqlite3 中的 ".load" 功能，
允许 REGEX 函数的 sqlite3-pcre 等扩展。为了使用此功能，
您必须指定库路径（.so 文件）和入口点，
入口点表示将由 sqlite 库调用的函数
（请参阅 sqlite
[load_extension](https://www.sqlite.org/capi3ref.html#sqlite3_load_extension)
官方文档），以 ";" 分隔符分隔。
入口点参数可以省略，因此您不需要在这种情况下使用分隔符。


*默认情况下，不加载任何扩展。*


```c title="设置 load_extension 参数"
...
modparam("db_sqlite", "load_extension", "/usr/lib/sqlite3/pcre.so")
modparam("db_sqlite", "load_extension", "/usr/lib/sqlite3/pcre.so;sqlite3_extension_init")
...
```


#### busy_timeout (integer)


此参数设置 SQLite 库的默认 busy_handler，当表被锁定时，它会睡眠
指定的时间。处理程序将多次睡眠，直到至少达到指定的 "busy_timeout" 持续时间（以毫秒为单位）。
将此参数设置为小于或等于零的值将关闭所有忙处理程序。（请参阅
[SQLite 官方文档](https://www.sqlite.org/capi3ref.html#sqlite3_busy_timeout)）


*默认值为 500。*


```c title="设置 busy_timeout 参数"
...
modparam("db_sqlite", "busy_timeout", 5000)
...
```


#### exec_pragma (string)


此参数允许使用 "PRAGMA" 语句配置 SQLite 数据库（请参阅
[SQLite 官方文档](https://sqlite.org/pragma.html)）。
要使用此功能，您必须将 exec_pragma 参数值指定为
"pragma-name=pragma-value"。可以指定具有相同名称的多个参数，
它们将在每个数据库连接上一一执行。如果参数具有
不正确的名称或语法，它将被 SQLite 忽略而不会产生任何错误消息。


*默认情况下，不执行任何 PRAGMA 语句。*


```c title="设置 exec_pragma 参数"
...
modparam("db_sqlite", "exec_pragma", "journal_mode=wal")
modparam("db_sqlite", "exec_pragma", "synchronous=normal")
modparam("db_sqlite", "exec_pragma", "cache_size=-2000")
...
```


### 导出的函数


配置文件中没有导出可使用的函数。


### 安装


由于该模块依赖外部库，sqlite 模块默认不会
被编译和安装。您可以使用以下选项之一：


- 编辑 "Makefile" 并从 "excluded_modules"
列表中删除 "db_sqlite"。然后按照标准程序安装 OpenSIPS：
"make all; make install"。
- 从命令行使用：'make all include_modules="db_sqlite";
make install include_modules="db_sqlite"'。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0
