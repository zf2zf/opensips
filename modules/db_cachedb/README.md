---
title: "db_cachedb 模块"
---

## 管理指南


### 概述


#### 思路


db_cachedb 模块将公开相同的前端 DB API，但它将运行在
NoSQL 后端之上，将 SQL 调用 emulation 到后端特定的查询。

因此，任何通常需要常规基于 SQL 的数据库的 OpenSIPS 模块，
现在将能够在 NoSQL 后端上运行，从而在分布式环境中
更轻松地分发和集成现有的 OpenSIPS 模块。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *至少一个 NoSQL cachedb_* 模块*。


#### 外部库或应用程序


以下库或应用程序必须在运行
加载了此模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### cachedb_url (str)


要使用的 CacheDB 后端的 URL。可以设置多个。


```c title="设置 cachedb_url 参数"
...
modparam("db_cachedb","cachedb_url","mongodb:mycluster://127.0.0.1:27017/db.col")
...
                
```


### 使用示例


#### 分布式订阅者库


为了实现这样的设置，需要将 auth_db 模块的 db_url 参数设置为指向 DB_CACHEDB URL。


```c title="使用 DB_CACHEDB 的 OpenSIPS CFG 片段"
loadmodule "auth_db.so"
modparam("auth_db", "load_credentials", "$avp(user_rpid)=rpid")

loadmodule "db_cachedb.so"
loadmodule "cachedb_mongodb.so"
...
modparam("db_cachedb","cachedb_url","mongodb:mycluster://127.0.0.1:27017/my_db.col")
modparam("auth_db","db_url","cachedb://mongodb:mycluster")
...
                
```


通过这样的设置，auth_db 模块将从 MongoDB 集群的 'my_db' 数据库中的 'subscriber' collection 中加载订阅者。


相同的机制/设置可用于在其他模块（如 usrloc、dialog、permissions、drouting 等）上运行 cachedb 集群。


### 当前限制


#### CacheDB 模块集成


目前实现此功能的唯一 cachedb_* 模块是 cachedb_mongodb 模块，因此目前您只能向 MongoDB 实例/集群 emulation SQL 查询。


计划还将此功能扩展到其他 cachedb_* 后端，如 Cassandra 和 CouchBase。


#### 需要广泛测试


由于目前有许多 OpenSIPS 模块使用 DB 接口，测试所有模块的所有场景是不可行的，因此仍可能存在一些不兼容性。

该模块已用一些常用模块（如 usrloc、dialog、permissions、drouting）进行了测试，但非常欢迎更多测试，并感谢反馈。


#### CacheDB 特定的 'schema' 和其他不兼容性


由于 NoSQL 后端通常没有严格的 schema，
我们不提供创建此类 schema 的脚本，因为插入操作将触发 schema 和信息的动态创建。

但是，特定的数据集合需要存在，那就是 SQL 中 'version' 表的等价物。由于大多数模块在模块设置时会检查 version 表，用户有责任在相应的 NoSQL 后端中设置这样的 'version' 集合。

例如，对于 MongoDB 集群，'version' 是一个保留关键字，因此必须更改 OpenSIPS 使用的默认 version 表（通过 'db_version_table' 全局参数），然后手动插入版本号，类似于 db.my_version_table.insert({table_version : NumberInt(5), table_name : "address"})
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0
