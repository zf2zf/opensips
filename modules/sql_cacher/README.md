---
title: "SQL Cacher 模块"
description: "sql_cacher 模块引入了将数据从基于 SQL 的数据库（使用实现 DB API 的不同 OpenSIPS 模块）缓存到通过 CacheDB Interface 在 OpenSIPS 中实现的缓存系统中的可能性。这是通过在 OpenSIPS 配置脚本中指定数据库 URL、要使用的 SQL 表、要缓存的所需列和其他详细信息来完成的。"
---

## 管理指南

### 概述

sql_cacher 模块引入了将数据从基于 SQL 的数据库（使用实现 DB API 的不同 OpenSIPS 模块）缓存到通过 CacheDB Interface 在 OpenSIPS 中实现的缓存系统中的可能性。这是通过在 OpenSIPS 配置脚本中指定数据库 URL、要使用的 SQL 表、要缓存的所需列和其他详细信息来完成的。

缓存的数据在脚本中可通过只读伪变量 "$sql_cached_value" 访问，类似于键值系统。SQL 表中的指定列扮演"键"的角色，因此此列的值以及所需列的名称作为"参数"提供给伪变量，返回列的相应值。

有两种类型的缓存可用：

- *完全缓存* - 整个 SQL 表（所有行）在 OpenSIPS 启动时加载到缓存中；
- *按需缓存* - SQL 表的行在运行时在请求相应键时加载。

对于按需缓存，存储的值具有可配置的过期周期，之后它们会被永久删除，除非为特定键调用 MI 重新加载函数。对于完全缓存，数据会在可配置的时间间隔自动重新加载。因此，如果 SQL 数据库中的数据发生变化并且调用了 MI 重新加载函数，旧数据仅保留在缓存中直到过期。

### 依赖

以下模块必须在此模块之前加载：

- *提供实际数据库后端连接的 OpenSIPS 模块*

### 导出的参数

#### cache_table (string)

可以多次设置此参数以缓存多个 SQL 表，甚至是同一表但配置不同。模块通过"id"字符串来区分这些不同的条目。

缓存条目通过此参数指定，它有自己的子参数。每个参数由 [spec delimiter](#param_spec_delimiter) 配置的分隔符分隔，格式如下：*param_name=param_value*。参数如下：

- *id* : 缓存条目 id
- *db_url* : SQL 数据库的 URL
- *cachedb_url* : CacheDB 数据库的 URL
- *table* : SQL 数据库表名
- *key* : SQL 数据库"键"列的列名
- *key_type* : SQL "键"列的数据类型：

  string
  int

  如果不存在，默认值为 "string"
- *columns* : 要从 SQL 数据库缓存的列名，由 [columns delimiter](#param_columns_delimiter) 配置的分隔符分隔。如果不存在，将缓存表中的所有列。
- *on_demand* : 指定缓存类型：

  0 : 完全缓存
  1 : 按需

  如果不存在，默认值为 "0"
- *expire* : 按需缓存类型存储在缓存中的值的过期时间（秒）。如果不存在，默认值为 "1 小时"。

参数必须按上面指定的精确顺序给出。

总的来说，该参数没有默认值，必须至少设置一次才能缓存任何表。

```c title="cache_table 参数使用"
modparam("sql_cacher", "cache_table",
"id=caching_name
db_url=mysql://root:opensips@localhost/opensips_2_2
cachedb_url=mongodb:mycluster://127.0.0.1:27017/db.col
table=table_name
key=column_name_0
columns=column_name_1 column_name_2 column_name_3
on_demand=0")
```

#### spec_delimiter (string)

用于在 *cache_table* 参数中提供的缓存条目规范中分隔子参数的分隔符。它必须是单个字符。

默认值为换行符。

```c title="spec_delimiter 参数使用"
modparam("sql_cacher", "spec_delimiter", "\n")
```

#### pvar_delimiter (string)

用于在 "$sql_cached_value" 伪变量中分隔缓存 id、所需列名和键值的分隔符。它必须是单个字符。

默认值为 ":"。

```c title="pvar_delimiter 参数使用"
modparam("sql_cacher", "pvar_delimiter", " ")
```

#### columns_delimiter (string)

用于在 *cache_table* 参数中提供的缓存条目规范的 *columns* 子参数中分隔所需列名的分隔符。它必须是单个字符。

默认值为 " "（空格）。

```c title="columns_delimiter 参数使用"
modparam("sql_cacher", "columns_delimiter", ",")
```

#### sql_fetch_nr_rows (integer)

从 SQL 数据库驱动程序一次获取到 OpenSIPS 私有内存的行数。查询大表时，请相应调整此参数，以避免填满 OpenSIPS 私有内存。

默认值为 "100"。

```c title="sql_fetch_nr_rows 参数使用"
modparam("sql_cacher", "sql_fetch_nr_rows", 1000)
```

#### full_caching_expire (integer)

完全缓存类型存储在缓存中的值的过期时间（秒）。这是删除或修改的数据保留在缓存中的最长时间。

默认值为 "24 小时"。

```c title="full_caching_expire 参数使用"
modparam("sql_cacher", "full_caching_expire", 3600)
```

#### reload_interval (integer)

此参数表示在数据过期之前（对于完全缓存）触发自动重新加载的秒数。

默认值为 "60 秒"。

```c title="reload_interval 参数使用"
modparam("sql_cacher", "reload_interval", 5)
```

#### bigint_to_str (integer)

控制 bigint 转换。默认情况下，bigint 值作为 int 返回。如果存储在 bigint 中的值超出 int 范围，通过启用 bigint 到字符串转换，bigint 值将作为字符串返回。

默认值为 "0"（禁用）。

```c title="bigint_to_str 参数使用"
modparam("sql_cacher", "bigint_to_str", 1)
```

### 导出的函数

#### sql_cache_dump(caching_id, columns, result_avps)

转储给定 *caching_id* 内缓存的所有 *columns*，并将它们写入相应的 *result_avps*。

参数：

- *caching_id* (string) - SQL 缓存的标识符
- *columns* (string) - 要转储的所需 SQL 列，指定为逗号分隔的值
- *result_avps* (string) - 将写入结果的 AVP 逗号分隔列表

返回代码：

- **-1** - 内部错误
- **-2** - 返回零结果
- **1, 2, 3, ...** - 返回到每个输出 AVP 的结果数量

此函数可以从任何路由使用。

```c title="sql_cache_dump 使用示例"
...
# 拉取所有缓存的 CNAM 记录的示例
$var(n) = sql_cache_dump("cnam", "caller,callee,calling_name,fraud_score",
                "$avp(caller),$avp(callee),$avp(cnam),$avp(fraud)");
$var(i) = 0;
while ($var(i) < $var(n)) {
	xlog("Caller $(avp(caller)[$var(i)]) has CNAM $(avp(cnam)[$var(i)])\n");
	$var(i) += 1;
}
...
```

### 导出的 MI 函数

#### sql_cacher:reload

替换已弃用的 MI 命令：*sql_cacher_reload*。

在 *完全缓存* 模式下重新加载整个缓存表或单个键（如果提供了键）。

在 *按需缓存* 模式下重新加载给定键或使缓存中的所有键失效。

参数：

- *id* - 缓存条目的 id
- *key* (可选) - 要重新加载的特定键。

```c title="sql_cacher:reload 使用示例"
...
$ opensips-cli -x mi sql_cacher:reload subs_caching
...
$ opensips-cli -x mi sql_cacher:reload subs_caching alice@domain.com
...
```

### 导出的伪变量

#### $sql_cached_value(id{sep}col{sep}key)

缓存数据通过此只读 PV 访问。格式如下：

- *sep* : 由 [pvar delimiter](#param_pvar_delimiter) 配置的分隔符
- *id* : 缓存条目 id
- *col* : 所需列的名称
- *key* : "键"列的值

```c title="$sql_cached_value(id{sep}col{sep}key) 伪变量使用示例"
...
$avp(a) = $sql_cached_value(caching_name:column_name_1:key1);
...
				 
```

### 使用示例

本节提供 SQL 表缓存的使用示例。

假设有兴趣缓存 OpenSIPS 数据库的 carrierfailureroute 表中的 "host_name"、"reply_code"、"flags" 和 "next_domain" 列。

```c title="示例数据库内容 - carrierfailureroute 表"
...
+----+---------+-----------+------------+--------+-----+-------------+
| id | domain  | host_name | reply_code | flags | mask | next_domain |
+----+---------+-----------+------------+-------+------+-------------+
|  1 |      99 |           | 408        |    16 |   16 |             |
|  2 |      99 | gw1       | 404        |     0 |    0 | 100         |
|  3 |      99 | gw2       | 50.        |     0 |    0 | 100         |
|  4 |      99 |           | 404        |  2048 | 2112 | asterisk-1  |
+----+---------+-----------+------------+-------+------+-------------+
...
			
```

首先，必须通过在 OpenSIPS 配置脚本中设置模块参数 "cache_table" 来提供缓存的详细信息。

```c title="设置 cache_table 参数"
modparam("sql_cacher", "cache_table",
"id=carrier_fr_caching
db_url=mysql://root:opensips@localhost/opensips
cachedb_url=mongodb:mycluster://127.0.0.1:27017/my_db.col
table=carrierfailureroute
key=id
columns=host_name reply_code flags next_domain")
			
```

接下来，缓存列的值可以通过 "$sql_cached_value" PV 访问。

```c title="访问缓存的值"
...
$avp(rc1) = $sql_cached_value(carrier_fr_caching:reply_code:1);
$avp(rc2) = $sql_cached_value(carrier_fr_caching:reply_code:2);
...
var(some_id)=4;
$avp(nd) = $sql_cached_value(carrier_fr_caching:next_domain:$var(some_id));
...
xlog("host name is: $sql_cached_value(carrier_fr_caching:host_name:2)");
...
			
```

### 导出的状态/报告标识符

该模块提供 "sql_cacher" 状态/报告组，其中每个完全缓存被定义为单独的 SR 标识符。请注意，按需缓存不会创建标识符。

#### [cache_entry_id]

这些标识符的状态反映缓存数据的就绪/状态（加载时是否可用）：

- *-2* - 完全没有数据（初始状态）
- *-1* - 没有数据，正在进行初始加载
- *1* - 数据已加载，分区就绪
- *2* - 数据可用，正在进行重新加载

在报告/日志方面，以下事件将被报告：

- 开始 DB 数据加载
- DB 数据加载失败，丢弃
- DB 数据加载成功完成
- 已加载 N 条记录

有关如何访问和使用状态/报告信息，请参阅 [https://www.opensips.org/Documentation/Interface-StatusReport-3-3](>https://www.opensips.org/Documentation/Interface-StatusReport-3-3)。

<!-- 贡献者 -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
