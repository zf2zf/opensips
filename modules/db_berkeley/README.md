---
title: "Berkeley DB 模块"
description: "这是一个将 Berkeley DB 集成到 OpenSIPS 的模块。它实现了 OpenSIPS 中定义的 DB API。"
---

## 管理指南


### 概述


这是一个将 Berkeley DB 集成到 OpenSIPS 的模块。
它实现了 OpenSIPS 中定义的 DB API。


### 依赖


#### OpenSIPS 模块


以下模块需要在此模块之前加载：


- *不依赖其他 OpenSIPS 模块*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *Berkeley Berkeley DB 4.6* - 一个嵌入式数据库。


### 导出的参数


#### auto_reload (integer)


当文件 inode 发生变化时，自动重新加载将关闭并重新打开 Berkeley DB。
该操作仅在查询期间发生。其他操作（如插入或删除）不会触发自动重新加载。


*默认值为 0（1 - 开启 / 0 - 关闭）。*


```c title="设置 auto_reload 参数"
...
modparam("db_berkeley", "auto_reload", 1)
...
		
```


#### log_enable (integer)


log_enable 布尔值控制何时创建日志文件。
以下操作可以被记录：
INSERT、UPDATE、DELETE。其他操作（如 SELECT）则不会。
如果您需要从损坏的 DB 文件中恢复，则需要此日志记录功能。
也就是说，bdb_recover 需要这些日志来重建 db 文件。
如果您觉得此日志功能有用，您可能还对每个表拥有的 METADATA_LOGFLAGS 位字段感兴趣。
它允许您控制哪些操作被记录，以及日志的目标位置（如 syslog、stdout、本地文件）。
请参阅 bdblib_log() 和 METADATA 文档。


*默认值为 0（1 - 开启 / 0 - 关闭）。*


```c title="设置 log_enable 参数"
...
modparam("db_berkeley", "log_enable", 1)
...
		
```


#### journal_roll_interval (integer 秒)


journal_roll_interval 将关闭并打开一个新的日志文件。
滚动操作仅在写入日志结束时发生，
因此不能保证"准时"滚动。


*默认值为 0（关闭）。*


```c title="设置 journal_roll_interval 参数"
...
modparam("db_berkeley", "journal_roll_interval", 3600)
...
		
```


### 导出的函数


配置文件中没有导出可使用的函数。


### 导出的 MI 函数


#### db_berkeley:reload


替换过时的 MI 命令：*bdb_reload*。


使 db_berkeley 模块重新读取指定表（或 dbenv）的内容。
db_berkeley DB 实际上是在需要时加载每个表，而不是在 mod_init 时全部加载。
db_berkeley:reload 操作实现为关闭后重新打开。
注意 - 如果表之前未被访问过，则 db_berkeley:reload 将失败（因为关闭会失败）。


名称：*db_berkeley:reload*


参数：


- *table_path* - 要重新加载特定表
提供表名作为参数；要重新加载
所有表，请提供 db_path 到 db 文件。路径可以在
opensipsc-cli 配置变量中找到。


MI FIFO 命令格式：


```c
		opensips-cli -x mi db_berkeley:reload subscriber
		
```


### 安装和运行


首先下载、编译和安装 Berkeley DB。
这超出了本文档的范围。此
过程的文档可在互联网上找到。


接下来，准备使用 db_berkeley 模块编译 OpenSIPS。
在 /modules/db_berkeley 目录中，修改 Makefile 以指向
您的 Berkeley DB 发行版。您也可以定义 'BDB_EXTRA_DEBUG'
来编译额外的调试日志。但是，不建议将其用于
生产服务器部署。


由于该模块依赖于外部库，db_berkeley 模块默认不会
被编译和安装。您可以使用以下选项之一：


- 编辑 "Makefile" 并从 "excluded_modules"
列表中删除 "db_berkeley"。然后按照标准程序安装 OpenSIPS：
"make all; make install"。
- 从命令行使用：'make all include_modules="db_berkeley";
make install include_modules="db_berkeley"'。


OpenSIPS 的安装只需以 root 用户身份运行主目录中的 make install
即可。这会将二进制文件安装到 /usr/local/sbin/。
如果成功，OpenSIPS 控制引擎文件现在应该已安装为 /usr/local/sbin/opensipsdbctl。


决定在文件系统上要将 Berkeley DB 文件安装到哪里。
例如，'/usr/local/etc/opensips/db_berkeley' 目录。
请记下此目录，因为我们需要将此路径添加到 opensips-cli 配置文件中。
注意：OpenSIPS 没有这些 DB 文件将无法启动。


（可选）预创建步骤 - 自定义您的元数据。
DB 文件最初使用必要的元数据进行填充。
这是查看元数据部分详细信息的好时机，
在修改表 dbschema 之前。
默认情况下，文件安装在 '/usr/local/share/opensips/db_berkeley/opensips'
默认情况下，这些表创建为读写模式且没有任何日志，如
所示。这些设置可以按表进行修改。
注意：如果您计划使用 bdb_recover，必须更改 LOGFLAGS。


```c
	METADATA_READONLY
	0
	METADATA_LOGFLAGS
	0
	
```


执行 opensipsdbctl - 根据您的实际情况，您可能需要三（3）组表。


```c
	opensipsdbctl create   		（必需）
	opensipsdbctl presence 		（可选）
	opensipsdbctl extra    		（可选）
	
```


修改 OpenSIPS 配置文件以使用 db_berkeley 模块。
模块的数据库 URL 必须是 Berkeley DB 表文件所在目录的路径，
前面加上 "berkeley://"，例如 "berkeley:///usr/local/etc/opensips/db_berkeley"。


还需要考虑其他两个重要事项：'db_mode' 和 'use_domain'
modparams。这些参数的说明在 usrloc 文档中。


关于 db_mode 的注意事项 -
db_berkeley 模块只会在 usrloc 写回 DB 时记录日志。
最安全的模式是模式 3，因为 db_berkeley 日志文件将始终
是最新的。关键是 db_mode 与日志文件恢复之间的交互。

写入日志条目是"尽力而为"的。因此，如果硬盘驱动器已满，
写入日志条目的尝试可能会失败。


关于 use_domain 的注意事项 -
db_berkeley 模块在执行查询时将尝试自然连接。
这本质上是使用提供的键进行词法字符串比较。
在大多数 db_berkeley dbschema 位置（除非您自定义），domainname
被识别为自然键。
考虑一个 use_domain = 0 的示例。在 subscriber 表中，数据库将使用
'username|NULL' 作为键，因为当未提供该键列时将使用默认值。
这实际上意味着后续查询必须一致地使用用户名（不含域）
才能找到对该特定订阅者查询的结果。
关键是，一旦 db_berkeley 设置完成，'use_domain' 就无法更改。


### 数据库架构和元数据


所有 Berkeley DB 表都通过 opensipsdbctl 脚本创建。
本节提供有关 DB 文件创建时的内容和
格式的详细信息。


由于 Berkeley DB 存储键值对，数据库使用几个元数据行进行填充。
这些行的键必须以 'METADATA' 开头。
以下是一个表示表元数据的示例，取自 'version' 表。


关于保留字符的注意事项 -
'|' 管道字符在 Berkeley DB 实现中用作记录分隔符，
不得出现在任何 DB 字段中。


```c title="METADATA_COLUMNS"
METADATA_COLUMNS
table_name(str) table_version(int)
METADATA_KEY
0
	
```


在上面的示例中，行 METADATA_COLUMNS 定义列名
和类型，行 METADATA_KEY 定义哪些列构成键。
这里的值 0 表示第 0 列是键（即 table_name）。
关于列类型，db_berkeley 模块只有以下
类型：string、str、int、double 和 datetime。默认类型是 string，
当未指定其他类型时使用。列的
元数据用空格分隔。


实际的列数据存储为字符串值，并用
'|' 管道字符分隔。由于代码在此分隔符上进行标记化，
重要的是此字符不应出现在任何有效数据字段中。
以下是 'db_berkeley.sh dump version' 命令的输出。
它以纯文本形式显示 'version' 表的内容。


```c title="version 表的内容"
VERSION=3
format=print
type=hash
h_nelem=21
db_pagesize=4096
HEADER=END
 METADATA_READONLY
 1
 address|
 address|3
 aliases|
 aliases|1004
 dbaliases|
 dbaliases|1
 domain|
 domain|1
 speed_dial|
 speed_dial|2
 subscriber|
 subscriber|6
 uri|
 uri|1
 METADATA_COLUMNS
 table_name(str) table_version(int)
 METADATA_KEY
 0
 acc|
 acc|4
 grp|
 grp|2
 location|
 location|1004
 missed_calls|
 missed_calls|3
 re_grp|
 re_grp|1
 silo|
 silo|5
 trusted|
 trusted|4
 usr_preferences|
 usr_preferences|2
DATA=END
	
```


### METADATA_COLUMNS（必需）


METADATA_COLUMNS 行包含列名和类型。
每个条目用空格分隔。以下是从 subscriber 表中获取的数据示例：


```c title="METADATA_COLUMNS"
METADATA_COLUMNS
username(str) domain(str) password(str) ha1(str) ha1b(str) first_name(str) last_name(str) email_address(str) datetime_created(datetime) timezone(str) rpid(str)
 	
```


相关的（硬编码的）限制：


- 每个表最多 32 列。
- 表名最大大小为 64。
- 最大数据长度为 2048。


目前支持这五种类型：str、datetime、int、double、string。


### METADATA_KEYS（必需）


METADATA_KEYS 行表示键列的索引，
相对于 METADATA_COLUMNS 中指定的顺序。
以下是从 subscriber 表中获取的一个示例，它提出了一个要点：


```c title="METADATA_KEYS"
 METADATA_KEY
 0 1
 	
```


要点是用户名和域名都需要
作为这条记录的键。因此，必须设置 usrloc modparam
use_domain = 1 才能使其工作。


### METADATA_READONLY（可选）


METADATA_READONLY 行包含布尔值 0 或 1。
默认情况下，其值为 0。在启动时，DB 将
最初以读写模式打开（加载元数据），然后如果此
设置为 1，它将关闭并以只读模式重新打开（ro）。
我发现这很有用，因为只读模式对内部
db 锁定等有影响。


### METADATA_LOGFLAGS（可选）


METADATA_LOGFLAGS 行包含一个位字段，用于自定义
每个表的日志记录。如果不存在，默认值
为 0。以下是目前已有的掩码（取自 bdb_lib.h）：


```c title="METADATA_LOGFLAGS"
#define JLOG_NONE 0
#define JLOG_INSERT 1
#define JLOG_DELETE 2
#define JLOG_UPDATE 4
#define JLOG_STDOUT 8
#define JLOG_SYSLOG 16
	
```


这意味着如果您想将 INSERT 记录到本地文件和 syslog，值
应设置为 1+16=17。或者如果您根本不想记录日志，请将此设置为 0。


### DB 恢复：bdb_recover


db_berkeley 模块使用并发数据存储（CDS）架构。
因此，DB 原生不提供事务或日志记录。
应用程序 bdb_recover 是专门为从
OpenSIPS 创建的日志文件中恢复数据而编写的。
bdb_recover 应用程序需要一个额外的文本文件，其中包含
表模式。


模式使用 '-s' 选项加载，是所有操作必需的。
提供 db_berkeley 纯文本模式文件的路径。默认情况下，这些
安装到 '/usr/local/share/opensips/db_berkeley/opensips/'。


'-h' home 选项是 DB_PATH 路径。与 Berkeley 实用程序不同，
此应用程序不会查找 DB_PATH 环境变量，
因此您必须指定它。如果未指定，它将假定当前
工作目录。最后一个参数是操作。
从根本上说，只有两个操作 - create 和 recover。


以下说明了管理员可用的四个操作。


```c title="bdb_recover 用法"
usage: ./bdb_recover -s schemadir [-h home] [-c tablename]
	这将创建一个全新的 DB 文件及其元数据。

usage: ./bdb_recover -s schemadir [-h home] [-C all]
	这将创建所有核心表，每个表都带有元数据。

usage: ./bdb_recover -s schemadir [-h home] [-r journal-file]
	这将重建一个 DB 并用 journal-file 中的操作填充它。
	表名按惯例嵌入在 journal-file 名称中。

usage: ./bdb_recover -s schemadir [-h home] [-R lastN]
	这将遍历所有枚举的核心表。如果 'home' 中存在日志文件，
	将创建一个新的 DB 文件，并用最后 N 个文件中找到的数据填充。
	文件按时间顺序"重放"（从最旧到最新）。这
	允许管理员在需要时使用所有可能
	操作的子集重建数据库。例如，您可能只对
	table location 中最近一小时的数据感兴趣。
	
```


重要注意事项 - 在执行 bdb_recover 之前，必须将损坏的 DB 文件移出。


### 已知限制


Berkeley DB 原生不支持自动递增（或序列）机制。
因此，此版本不支持 dbschema 中的代理键。这些
是表中的 id 列。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0
