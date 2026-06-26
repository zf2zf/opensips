---
title: "cachedb_local 模块"
description: "本模块是作为哈希表实现的本地缓存系统。它使用了 OpenSIPS 核心导出的 Key-Value 接口。从版本 2.3 开始，该模块可以有多个哈希表，称为集合。cachedb_local 模块的每个 URL 指向一个集合..."
---

## 管理指南


### 概述


本模块是作为哈希表实现的本地缓存系统。它使用了 OpenSIPS 核心导出的 Key-Value 接口。
从版本 2.3 开始，该模块可以有多个哈希表，称为集合。cachedb_local 模块的每个 URL 指向一个集合。
一个集合可以由多个 URL 共享。


### 集群


Cachedb_local 集群是一种用于将本地缓存更改镜像到其他一个或多个 OpenSIPS 实例的机制，
无需第三方依赖。
该过程通过使用 clusterer 模块简化，该模块便于管理 OpenSIPS 节点集群
并发送复制相关的 BIN 数据包（使用 proto_bin 的二进制编码）。这对于实现
热备份系统很有用，备用实例可以接管而无需自己填充缓存。


以下缓存操作将在集群内部分发：


- cache_store
- cache_remove
- cache_add
- cache_sub


除了事件驱动的复制，OpenSIPS 实例在启动时首先会尝试从集群中的另一个节点学习所有本地缓存信息。
数据同步机制需要将集群中的一个节点定义为"**种子**"节点。
有关如何执行此操作以及为何需要它，请参阅 [clusterer](../clusterer#capabilities) 模块。


*注意：*当您设置 [cache collections](#param_cache_collections) 时，必须明确指定要复制的集合。


**限制：** 集群操作不是原子性的，
且不保证集群节点之间的一致性。


### 依赖


#### OpenSIPS 模块


以下模块必须在本模块之前加载：


- *如果设置了 [cluster id](#param_cluster_id)，则需要 clusterer 模块。*


#### 外部库或应用程序


运行 OpenSIPS 并加载本模块之前，必须安装以下库或应用程序：


- *无*


### 导出的参数


#### cachedb_url (字符串)


用于脚本和 MI cacheDB 操作的本地缓存组 URL。该参数可以多次设置。


一个集合可以属于多个 URL，但一个 URL 只能有一个集合。
使用相同的 schema 和组名重新定义 URL 将导致覆盖该 URL。
URL 定义中使用的每个集合必须使用 *cachedb_collection* 参数定义。
集合应作为普通数据库定义，在 URL 末尾定义，如示例所示。
在脚本中，应使用 schema 和（如果存在）组名来标识集合。


*"如果未定义 URL，则将使用没有组名且集合为 "default" 的 URL。"*


```c title="设置 cachedb_url 参数"
...
### 对于此示例，如果未定义集合，则应使用名为 "default" 的默认集合
modparam("cachedb_local", "cachedb_url", "local://")
### 此 URL 将使用名为 collection1 的集合；它将覆盖之前的 url 定义（使用 "default" 集合）
modparam("cachedb_local", "cachedb_url", "local:///collection1")
### 此 URL 将使用 collection2；它将从脚本中以 "local:group2" 引用
modparam("cachedb_local", "cachedb_url", "local:group2:///collection2")

## 如何从脚本中使用 URL
## 如上定义，此调用将使用 collection1
cache_store("local", ...)
## 如上定义，此调用将使用 collection2
cache_store("local:group2", ...)
...

## 导出的参数

#### cache_collections (字符串)

使用此参数可以定义集合（哈希表）及其大小。每个集合定义必须使用 ';' 相互分隔。
哈希的默认大小为 512。大小必须使用 '=' 与集合名称分隔。

如果启用了集群，您必须使用 */r* 后缀指定要复制的集合。

*"default"* 集合始终会被创建，
即使未包含在此集合列表中。

```c title="设置 cache_collections 参数"
...
## 创建 collection1（默认大小 512）和自定义大小为 2^5 (32) 的 collection2
## 我们还更改了默认集合的大小，从 2^9 - 512（默认值）改为 2^4 - 16
## 此外，collection1 和 collection2 将在集群中复制，而 default 集合将是本地的
modparam("cachedb_local", "cache_collections", "collection1/r; collection2/r = 5; default = 4")
...

#### cache_clean_period (整数)

清除过期记录的时间间隔（秒）。

*默认值为 "600（10 分钟）"。*

```c title="设置 cache_clean_period 参数"
...
modparam("cachedb_local", "cache_clean_period", 1200)
...

#### cluster_id (整数)

指定此实例将向其发送和接收缓存数据的集群 ID。

此 OpenSIPS 集群公开 **"cachedb-local-repl"** 功能，
用于将节点标记为在任意同步请求期间有资格成为数据捐赠者。
因此，集群必须至少有**一个节点**在 *clusterer.flags* 列/属性中标记为 **"seed"** 值，
才能完全正常运行。
请参阅 [clusterer - 功能](../clusterer#capabilities) 章节了解更多详情。

默认值为 0（禁用复制）。

```c title="设置 cluster_id 参数"
...
modparam("cachedb_local", "cluster_id", 1)
...

#### cluster_persistency (字符串)

控制 OpenSIPS 本地 cachedb 集群在重启后的行为。

此参数可采用以下值：

- *"none"* - 重启后没有明确的数据
			同步。节点以空状态启动。
- *"sync-from-cluster"* - 启用
			基于集群的重启持久性。重启后，
			OpenSIPS 集群节点将搜索健康的"捐赠者"节点，
			通过直接集群同步（基于 TCP 的二进制编码数据传输）镜像整个用户位置数据集。
			这需要配置集群中的一个或多个"种子"
			节点。

*默认值为
			*"sync-from-cluster"*。*

```c title="设置 cluster_persistency 参数"
...
modparam("cachedb_local", "cluster_persistency", "sync-from-cluster")
...

#### enable_restart_persistency (整数)

使用持久内存机制启用重启持久性。数据存储在映射到 OpenSIPS 内存的缓存文件中。

请注意，您必须保持与上次运行相同的集合定义，以便将缓存数据用于相应的集合。

如果同时启用了集群持久性，从持久性缓存加载的密钥
如果未在集群同步数据中收到，将被丢弃。

*默认值为 "0（禁用）"。*

```c title="设置 enable_restart_persistency 参数"
...
modparam("cachedb_local", "enable_restart_persistency", yes)
...

### 导出的函数

#### cache_remove_chunk([collection,] glob)

从本地缓存中删除所有与特定 *collection* 或默认集合（如果未定义）的 *glob* 模式匹配的键。
请注意，集合名称与组名称不同，组名称在 cachedb 操作中标识引擎。

参数：

- *collection* (字符串，可选)
- *glob* (字符串)

此函数可用于所有路由。

```c title="cache_remove_chunk 使用方法"
	...
	cache_remove_chunk("myinfo_*");
	cache_remove_chunk("collection1", "myinfo_*");
	...

### 导出的 MI 函数

#### cachedb_local:remove_chunk

替换已弃用的 MI 命令：*cache_remove_chunk*。

删除所有与提供的 glob 参数匹配的本地缓存条目。

参数：

- *glob* - 将删除匹配的键
- *collection*（可选）- 要从中删除键的集合；如果未设置集合，将使用默认集合；

MI FIFO 命令格式：

```c
opensips-cli -x mi cachedb_local:remove_chunk "keyprefix*" collection
		
```

#### cachedb_local:fetch_chunk

替换已弃用的 MI 命令：*cache_fetch_chunk*。

获取所有与提供的 glob 参数匹配的本地缓存条目。

参数：

- *glob* - 将返回匹配的键
- *collection*（可选）- 要从中获取键的集合；如果未设置集合，将使用默认集合；

MI FIFO 命令格式：

```c
opensips-cli -x mi cachedb_local:fetch_chunk "keyprefix*" collection
{
    "keys": [
        {
            "name": "keyprefix_1",
            "value": "key 1 data here"
        },
        {
            "name": "keyprefix_2",
            "value": "key 2 data here"
        }
    ]
}

## 常见问题

**Q: 旧的 cache_table_size 参数发生了什么？**

该参数已被删除，因为它是多余的。自
	添加集合以来，旧哈希现在属于
	默认集合。此集合每次都会创建，
	默认大小为 512。可以通过使用 cache_collections 参数设置默认集合大小来更改大小。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享许可证 4.0 版授权
