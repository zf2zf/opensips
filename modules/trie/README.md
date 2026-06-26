---
title: "Trie 模块"
---

## 管理指南

### 概述

#### 简介

Trie 是一个用于高效缓存和查找一组前缀的模块（存储在 trie 数据结构中）。

### 依赖

#### OpenSIPS 模块

以下模块必须在此模块之前加载：

- *数据库模块*

#### 外部库或应用程序

- *无*

### 导出的参数

#### trie_table(str)

存储前缀规则的数据库表名。

*默认值为 "trie_table"*

```c title="设置 trie_table 参数"
...
modparam("trie", "trie_table", "my_prefix_table")
...
```

#### no_concurrent_reload (int)

如果启用，模块将不允许并行运行多个 trie:reload MI 命令（重叠）。当现有重新加载正在进行时，任何新的重新加载都将被拒绝（并丢弃）。

如果您有一个大型路由集（数百万条规则/前缀），您应该考虑禁用并发重新加载，因为它们会耗尽共享内存（通过同时将路由数据的多个实例重新加载到内存中）。

*默认值为 "0（禁用）"*

```c title="设置 no_concurrent_reload 参数"
...
# 不允许并行重新加载操作
modparam("trie", "no_concurrent_reload", 1)
...
```

#### use_partitions (int)

配置是否为 trie 使用分区的标志。如果设置此标志，则 `db_partitions_url` 和 `db_partitions_table` 变量变为必选。

*默认值为 "0"*

```c title="设置 use_partitions 参数"
...
modparam("trie", "use_partitions", 1)
...
```

#### db_partitions_url (str)

包含分区特定信息的数据库 URL。`use_partitions` 参数必须设置为 1。

*默认值为 ""NULL""*

```c title="设置 db_partitions_url 参数"
...
modparam("trie", "db_partitions_url", "mysql://user:password@localhost/opensips_partitions")
...
```

#### db_partitions_table (str)

包含分区定义的表名。与 `use_partitions` 和 `db_partitions_url` 一起使用。

*默认值为 "trie_partitions"*

```c title="设置 db_partitions_table 参数"
...
modparam("trie", "db_partitions_table", "trie_partition_defs")
...
```

#### extra_prefix_chars (str)

前缀中额外接受的 ASCII (0-127) 字符列表。默认情况下，仅接受 '0' - '9' 字符（数字）。

*默认值为 "NULL"*

```c title="设置 extra_prefix_chars 参数"
...
modparam("trie", "extra_prefix_chars", "#-%")
...
```

### 导出的函数

#### trie_search(number, [flags], [trie_attrs_pvar], [match_prefix_pvar], [partition])

在 trie 中搜索条目（号码）的函数。

此函数可以从所有路由使用。

如果将 `use_partitions` 设置为 1，则 **partition** 最后一个参数变为必选。

所有参数都是可选的。任何参数都可以被忽略，只需正确放置必要的分隔标记 ","。

- **number** (str) - 要在 trie 中搜索的号码
- **flags** (string, 可选) - 用于控制路由行为的字母标志列表。可能的标志有：
  - **L** - 对前缀执行严格长度匹配——实际上，trie 引擎将执行完整号码匹配而不是前缀匹配。
- **trie_attrs_pvar** (var, 可选) - 一个可写变量，将被填充匹配 trie 规则的属性。
- **match_prefix_pvar** (var, 可选) - 一个可写变量，将是在 trie 中匹配的实际前缀。
- **partition** (string, 可选) - 要使用的 trie 分区的名称。此参数仅在 "use_partition" 模块参数开启时定义。

```c title="trie_search 用法"
...
if (trie_search("$rU","L",$avp(code_attrs),,"my_partition")) {
    # 我们在 trie 中找到了，它是一个匹配
    xlog("我们在 trie 中找到 $rU，属性为 $avp(code_attrs) \n");
}
```

### 导出的 MI 函数

#### trie:reload

替换已弃用的 MI 命令：*trie_reload*。

重新加载数据库中的 trie 规则命令。

- 如果 `use_partition` 设置为 0 - 所有路由规则都将重新加载。
- 如果 `use_partition` 设置为 1，参数为：
  - *partition_name* (可选) - 如果未提供，所有分区都将重新加载，否则仅重新加载作为参数给出的分区。

MI FIFO 命令格式：

```c
opensips-cli -x mi trie:reload part_1
```

#### trie:reload_status

替换已弃用的 MI 命令：*trie_reload_status*。

获取任何分区最后重新加载的时间。

- 如果 `use_partition` 设置为 0 - 函数不接受任何参数。它将列出默认（也是唯一的）分区最后重新加载的日期。
- 如果 `use_partition` 设置为 1，参数为：
  - *partition_name* (可选) - 如果未提供，函数将列出每个分区最后更新的时间。否则，函数将列出给定分区最后重新加载的时间。

```c title="当 use_partitions 为 0 时 trie:reload_status 用法"
$ opensips-cli -x mi trie:reload_status
Date:: Tue Aug 12 12:26:00 2014
```

#### trie:search

替换已弃用的 MI 命令：*trie_search*。

尝试匹配从数据库加载的现有 trie 中的号码。

- 如果 `use_partition` 设置为 1，函数将有 2 个参数：
  - *partition_name*
  - *number* - 要测试的号码
- 如果 `use_partition` 设置为 0，函数将有 1 个参数：
  - *number* - 要测试的号码

MI FIFO 命令格式：

```c
opensips-cli -x mi trie:search partition_name=part1 number=012340987
```

#### trie:number_delete

替换已弃用的 MI 命令：*trie_number_delete*。

删除 trie 中的单个条目，无需重新加载所有数据。

- 如果 `use_partition` 设置为 1，函数将有 2 个参数：
  - *partition_name*
  - *number* - 要删除的号码数组

MI FIFO 命令格式：

```c
opensips-cli -x mi trie:number_delete partition_name=part1 number=["012340987","4858345"]
```

#### trie:number_upsert

替换已弃用的 MI 命令：*trie_number_upsert*。

在 trie 中 upsert（一组号码，如果未找到则插入，如果找到则更新）数组，无需重新加载所有数据。

- 如果 `use_partition` 设置为 1，函数将有 3 个参数：
  - *partition_name*
  - *number* - 要更新的号码数组
  - *attrs* - 号码的新属性数组

MI FIFO 命令格式：

```c
opensips-cli -x mi trie:number_upsert partition_name=part1 number=["012340987"] attrs=["my_attrs"]
```

### 安装

该模块需要在 OpenSIPS 数据库中创建一些表。
您还可以在项目网页上找到完整的数据库文档：[https://opensips.org/docs/db/db-schema-devel.html](https://opensips.org/docs/db/db-schema-devel.html)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
