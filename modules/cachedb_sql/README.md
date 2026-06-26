---
title: "cachedb_sql 模块"
description: "本模块是缓存系统的实现，旨在与常规基于 SQL 的服务器配合工作。它使用内部 DB 接口连接到后端，并实现了 OpenSIPS 核心导出的 Key-Value 接口。"
---

## 管理指南


### 概述


本模块是缓存系统的实现，旨在与常规基于 SQL 的服务器配合工作。
它使用内部 DB 接口连接到后端，并实现了 OpenSIPS 核心导出的 Key-Value 接口。


### 优势


- *内存成本不再由服务器承担*
- *缓存是 100% 持久化的。OpenSIPS 服务器的重启不会影响 DB。DB 也是持久化的，
			因此也可以在不失数据的情况下重启。*
- *多个 OpenSIPS 实例可以通过常规基于 SQL 的数据库轻松共享键值信息*


### 限制


- *模块的计数器操作（ADD 和 SUB）目前仅支持 MySQL*


### 依赖


#### OpenSIPS 模块


无。


#### 外部库或应用程序


运行 OpenSIPS 并加载本模块之前，必须安装以下库或应用程序：


- *无：*


### 导出的参数


#### cachedb_url (字符串)


OpenSIPS 将连接到的数据库 URL，以便在脚本中使用 cache_store、cache_fetch 等操作。


格式为：sql:[conn_id]-dburl


可以为多个连接设置此参数，使其可从 OpenSIPS 脚本访问。


```c title="设置 db_url 参数"
...
modparam("cachedb_sql", "cachedb_url", "sql:1st-mysql://root:vlad@localhost/opensips_sql")
...

```


```c title="使用示例"
...
modparam("cachedb_sql", "cachedb_url", "sql:1st-mysql://root:vlad@localhost/opensips_sql")
modparam("cachedb_sql", "cachedb_url", "sql:2nd-postgres://root:vlad@localhost/opensips_pg")
...
...
cache_store("sql:1st-mysql","key","$ru value");
cache_store("sql:2nd-postgres","counter","10");
...

```


#### db_table (字符串)


OpenSIPS 将连接到的数据库表，以便在脚本中使用 cache_store、cache_fetch 等操作。


```c title="设置 db_url 参数"
...
modparam("cachedb_sql", "db_table","my_table");
...

```


#### key_column (字符串)


存储键的列。


```c title="设置 key_column 参数"
...
modparam("cachedb_sql", "key_column","some_name");
...

```


#### value_column (字符串)


存储值的列。


```c title="设置 value_column 参数"
...
modparam("cachedb_sql", "value_column","some_name");
...

```


#### counter_column (字符串)


存储计数器值的列。


```c title="设置 counter_column 参数"
...
modparam("cachedb_sql", "counter_column","some_name");
...

```


#### expires_column (字符串)


存储过期时间的列。


```c title="设置 expires_column 参数"
...
modparam("cachedb_sql", "expires_column","some_name");
...

```


#### cache_clean_period (整数)


从数据库中删除过期键的时间间隔（秒）。默认值为 60（秒）。


```c title="设置 cache_clean_period 参数"
...
modparam("cachedb_sql", "cache_clean_period",10);
...

```


### 导出的函数


本模块不导出在配置脚本中使用的函数。


## 常见问题


**Q: 旧的 "db_url" 模块参数发生了什么？**


它已被 "cachedb_url" 参数替换。
		请参阅 "cachedb_url" 参数的文档以了解其用法。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享许可证 4.0 版授权
