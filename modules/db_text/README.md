---
title: "db_text 模块"
description: "该模块实现了一个基于文本文件的简化数据库引擎。它可以用于 OpenSIPS DB 接口来替代其他数据库模块（如 MySQL）。"
---

## 管理指南


### 概述


该模块实现了一个基于文本文件的简化数据库引擎。
它可以用于 OpenSIPS DB 接口来替代其他
数据库模块（如 MySQL）。


该模块适用于演示或不支持其他 DB 模块的小型设备。
它将所有内容保存在内存中，如果您处理大量数据，
您可能会很快耗尽内存。此外，它没有实现所有标准数据库功能（如 order by），
它包含最小功能以与 OpenSIPS 正常配合工作


注意：时间戳以 time_t 结构中的整数值打印。
如果您使用的系统无法进行此转换，它将失败（对此情况的支持在待办事项列表中）。


注意：即使在非缓存模式下，该模块也不会在更改后写回硬盘。
在此模式下，模块检查磁盘上对应的文件是否已更改，
如果是，将重新加载表。写入磁盘发生在 OpenSIPS 关闭时。


#### db_text 引擎的设计


db_text 数据库系统架构：


- 数据库由本地文件系统中的一个目录表示。
请注意，当您在 OpenSIPS 中使用 *db_text* 时，
模块的数据库 URL 必须是表文件所在目录的路径，
前面加上 "text://"，例如
"text:///var/dbtext/opensips"。如果 "text://" 后面没有
"/"，则 "CFG_DIR/" 将被插入到数据库路径的开头。
因此，您可以提供数据库目录的绝对路径或相对于 "CFG_DIR" 的相对路径。
- 表由数据库目录内的文本文件表示。


#### db_text 表的内部格式


第一行是列的定义。每个列必须按如下方式声明：


- 列名不能包含空格。
- 列定义的格式为：*name(type,attr)*。
- 两个列定义之间必须有一个空格，例如
"first_name(str) last_name(str)"。
- 列的类型可以是：
						
						
*int* - 整数。
						
						
*double* - 带两位小数的实数。
						
						
*str* - 最大大小为 4KB 的字符串。
- 列可以具有以下属性之一：
						
						
*auto* - 仅适用于 'int' 列，
如果查询中未提供此字段，则该列中的最大值将递增并存储在此字段中。
						
						
*null* - 接受列字段中的空值。
						
						
如果未设置属性，则列的字段不能有空值。
- 其他每一行都是带数据的行。该行以 "\n" 结尾。
- 字段用 ":" 分隔。
- 两个 ':' 之间（或 ':' 与行首/尾之间）没有值表示 "null" 值。
- 字符串中必须转义的字符："\n"、"\r"、"\t"、":"。
- *0* -- 零值也必须转义。


```c title="db_text 表示例"
...
id(int,auto) name(str) flag(double) desc(str,null)
1:nick:0.34:a\tgood\: friend
2:cole:-3.75:colleague
3:bob:2.50:
...
```


```c title="最小的 OpenSIPS location db_text 表定义"
...
username(str) contact(str) expires(int) q(double) callid(str) cseq(int)
...
```


```c title="最小的 OpenSIPS subscriber db_text 表示例"
...
username(str) password(str) ha1(str) domain(str) ha1b(str)
suser:supasswd:xxx:alpha.org:xxx
...
```


#### 现有限制


此数据库接口不支持带默认值的数据插入。
数据库模板中指定的所有此类值都会被忽略。
因此，建议在插入操作时指定列的所有数据。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *无*。


#### 外部库或应用程序


以下库或应用程序必须在运行
此模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### db_mode (integer)


设置缓存模式（0）或非缓存模式（1）。在缓存模式下，数据在启动时加载。
在非缓存模式下，每次请求表时，模块都会检查磁盘上对应的文件是否已更改，
如果是，将从文件重新加载表。


*默认值为 "0"。*


```c title="设置 db_mode 参数"
...
modparam("db_text", "db_mode", 1)
...
```


#### buffer_size (integer)


用于读取文本文件的缓冲区大小。


*默认值为 "4096"。*


```c title="设置 buffer_size 参数"
...
modparam("db_text", "buffer_size", 8192)
...
```


### 导出的函数


*无*。


### 导出的 MI 函数


#### db_text:dump


替换过时的 MI 命令：*dbt_dump*。


将修改后的表写回硬盘。


名称：*db_text:dump*。


参数：无


MI FIFO 命令格式：


```c
opensips-cli -x mi db_text:dump
		
```


#### db_text:reload


替换过时的 MI 命令：*dbt_reload*。


使 db_text 模块从磁盘重新加载缓存的表。
根据参数，它可以重新加载整个缓存或指定的
数据库或单个表。
如果任何表无法从磁盘重新加载 - 旧版本
将被保留并报告错误。


名称：*db_text:reload*。


参数：


- *db_name*（可选）- 要重新加载的数据库名称。
- *table_name*（可选，但不能在 db_name 参数不存在的情况下存在）
- 要重新加载的特定表。


MI FIFO 命令格式：


```c
opensips-cli -x mi db_text:reload
		
```


```c
opensips-cli -x mi db_text:reload /path/to/dbtext/database
		
```


```c
opensips-cli -x mi db_text:reload /path/to/dbtext/database table_name
		
```


### 安装和运行


编译模块并加载它来替代 mysql 或其他 DB 模块。


提醒：当您在 OpenSIPS 中使用 *db_text* 时，
模块的数据库 URL 必须是表文件所在目录的路径，
前面加上 "text://"，例如
"text:///var/dbtext/opensips"。如果 "text://" 后面没有 "/"，则 "CFG_DIR/" 将被插入到数据库路径的开头。
因此，您可以提供数据库目录的绝对路径或相对于 "CFG_DIR" 的相对路径。


```c title="加载 db_text 模块"
...
loadmodule "/path/to/opensips/modules/db_text.so"
...
modparam("module_name", "database_URL", "text:///path/to/dbtext/database")
...
```


#### 将 db_text 与基本 OpenSIPS 配置一起使用


以下是最重要的表定义以及使用 db_text 与 OpenSIPS 的基本配置文件。
表结构可能会随时间变化，您需要调整以下示例。


您必须手动填充 'subscriber' 表以及用户配置文件以进行身份验证。
要与给定的配置文件一起使用，表文件必须放置在 '/tmp/opensipsdb' 目录中。


```c title="'subscriber' 表定义（一行）"
...
username(str) domain(str) password(str) first_name(str) last_name(str) phone(str) email_address(str) datetime_created(int) datetime_modified(int) confirmation(str) flag(str) sendnotification(str) greeting(str) ha1(str) ha1b(str) perms(str) allow_find(str) timezone(str,null) rpid(str,null)
...
```


```c title="'location' 和 'aliases' 表定义（一行）"
...
username(str) domain(str,null) contact(str,null) received(str) expires(int,null) q(double,null) callid(str,null) cseq(int,null) last_modified(str) flags(int) user_agent(str) socket(str) 
...
```


```c title="'version' 表定义和示例记录"
...
table_name(str) table_version(int)
subscriber:3
location:6
aliases:6
...
```


[配置文件](./samples.md "include")


## 开发者指南


加载模块后，您可以使用 OpenSIPS DB 接口指定的 API。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0
