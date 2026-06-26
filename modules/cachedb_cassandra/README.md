---
title: "cachedb_cassandra 模块"
description: "本模块是缓存系统的实现，旨在与 Cassandra 服务器配合工作。它使用了 OpenSIPS 核心导出的 Key-Value 接口。"
---

## 管理指南


### 概述


本模块是缓存系统的实现，旨在与 Cassandra 服务器配合工作。它使用了 OpenSIPS 核心导出的 Key-Value 接口。


底层客户端库兼容 Cassandra 2.1+ 版本。


### 优势


- *内存成本不再由服务器承担*
- *可以在集群内使用多台服务器，因此内存实际上是无限的*
- *缓存是 100% 持久化的。OpenSIPS 服务器的重启不会影响 DB。Cassandra DB 也是持久化的，因此也可以在不失数据的情况下重启。*
- *Cassandra 是开源项目，因此可用于与各种其他应用程序交换数据*
- *通过创建 Cassandra 集群，多个 OpenSIPS 实例可以轻松共享键值信息*


### 限制


- *键（键值对中的键）不能包含空格或控制字符*


### 依赖


#### OpenSIPS 模块


无。


#### 外部库或应用程序


运行 OpenSIPS 并加载本模块之前，必须安装以下库或应用程序：


- *libuv*
- *cassandra-cpp-driver*


DataStax C/C++ driver for Cassandra 和 libuv 依赖可从以下地址下载：[http://downloads.datastax.com/cpp-driver/](http://downloads.datastax.com/cpp-driver/)。


### 导出的参数


#### cachedb_url (字符串)


OpenSIPS 将连接到的服务器组 URL，以便在脚本中使用 cache_store、cache_fetch 等操作。
可以多次设置此参数。
URL 的前缀部分将是脚本中使用的标识符。


Cassandra 不支持在包含 counter 列的表中使用常规列，因此为了在 Key-Value 接口中使用 add()/sub()/get_counter() 方法，您可以指定一个额外的表专门用于 counter。


URL 的数据库部分格式为 *Keyspace.Table[.CountersTable]*。


```c title="设置 cachedb_url 参数"
...
modparam("cachedb_cassandra", "cachedb_url",
	"cassandra:group1://localhost:9042/keyspace1.users.counters")

# 为 Cassandra 集群定义多个连接点
modparam("cachedb_cassandra", "cachedb_url",
	"cassandra:cluster1://10.0.0.10,10.0.0.15/keyspace2.keys.counters")
...
	
```


```c title="使用 Cassandra 服务器"
...
cache_store("cassandra:group1","key","$ru value");
cache_fetch("cassandra:cluster1","key",$avp(10));
cache_remove("cassandra:cluster1","key");
...
	
```


#### connect_timeout (整数)


连接尝试失败时触发的超时时间（毫秒）。


*默认值为 "5000"。*


```c title="设置 connect_timeout 参数"
...
modparam("cachedb_cassandra", "connect_timeout",1000);
...
	
```


#### query_timeout (整数)


Cassandra 查询时间过长时触发的超时时间（毫秒）。


*默认值为 "5000"。*


```c title="设置 query_timeout 参数"
...
modparam("cachedb_cassandra", "query_timeout",1000);
...
	
```


#### wr_consistency_level (整数)


写操作所需的一致性级别。选项包括：


- *all* - 写操作必须写入该分区所有副本节点的 commit log 和 memtable。
- *each_quorum* - 强一致性。写操作必须写入每个数据中心中法定数量副本节点的 commit log 和 memtable。
- *quorum* - 写操作必须写入所有数据中心中法定数量副本节点的 commit log 和 memtable。
- *local_quorum* - 强一致性。写操作必须写入与协调器相同数据中心的法定数量副本节点的 commit log 和 memtable。避免数据中心间通信延迟。
- *one* - 写操作必须写入至少一个副本节点的 commit log 和 memtable。
- *two* - 写操作必须写入至少两个副本节点的 commit log 和 memtable。
- *three* - 写操作必须写入至少三个副本节点的 commit log 和 memtable。
- *local_one* - 写操作必须发送到本地数据中心至少一个副本节点并成功收到确认。
- *any* - 写操作必须写入至少一个节点。如果给定分区密钥的所有副本节点都宕机，写操作仍可以在写入 hinted handoff 后成功。如果在写入时所有副本节点都宕机，ANY 写入在副本节点恢复之前是不可读的。


默认值为 *one*。


```c title="设置 wr_consistency_level 参数"
...
modparam("cachedb_cassandra", "wr_consistency_level", "each_quorum");
...
	
```


#### rd_consistency_level (整数)


读操作所需的一致性级别。选项包括：


- *all* - 在所有副本响应后返回记录。如果副本未响应，读操作将失败。
- *quorum* - 在所有数据中心的法定数量副本响应后返回记录。
- *local_quorum* - 在当前数据中心作为协调器的法定数量副本报告后返回记录。避免数据中心间通信延迟。
- *one* - 从最近的副本返回响应（由 snitch 确定）。默认情况下，读修复在后台运行以使其他副本保持一致。
- *two* - 从两个最近的副本返回最新数据。
- *three* - 从三个最近的副本返回最新数据。
- *local_one* - 从本地数据中心最近的副本返回响应。
- *serial* - 允许读取数据的当前（可能是未提交的）状态，而不提议新的添加或更新。如果 SERIAL 读发现未提交的事务正在进行，它将作为读的一部分提交该事务。类似于 QUORUM。
- *local_serial* - 与 SERIAL 相同，但限制在数据中心内。类似于 LOCAL_QUORUM。


默认值为 *one*。


```c title="设置 rd_consistency_level 参数"
...
modparam("cachedb_cassandra", "rd_consistency_level", "quorum");
...
	
```


#### exec_threshold (整数)


超过此阈值的 Cassandra 缓存查询将触发日志中的警告消息。


此值（如果设置）仅在低于[查询超时](#param_query_timeout)时才有意义，因为超过该值的任何查询都将被丢弃。


*默认值为 "0（无限制 - 无警告）"。*


```c title="设置 exec_threshold 参数"
...
modparam("cachedb_cassandra", "exec_threshold", 100000)
...
	
```


### 导出的函数


本模块不导出在配置脚本中使用的函数。


### 表结构


支持 Key-Value 接口的 cache_store()/cache_fetch()/cache_remove() 函数所需的表至少需要以下列：


- *opensipskey* - 作为主键，类型为 "text"
- *opensipsval* - 类型为 "text"


支持 Key-Value 接口的 cache_add()/cache_sub()/cache_counter_fetch() 函数所需的表至少需要以下列：


- *opensipskey* - 作为主键，类型为 "text"
- *opensipsval* - 类型为 "counter"
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享许可证 4.0 版授权
