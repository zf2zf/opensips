---
title: "dns_cache 模块"
description: "该模块是专为 DNS 记录设计的缓存系统的实现。对于所有类型的成功 DNS 查询，模块将在缓存/数据库后端存储映射，有效期为 DNS 回答中收到的 TTL 秒数。失败的 DNS 查询也将存储在后端，TTL 可由用户指定。"
---

## 管理指南


### 概述


该模块是专为 DNS 记录设计的缓存系统的实现。
对于所有类型的成功 DNS 查询，模块将在缓存/数据库后端存储映射，有效期为 DNS 回答中收到的 TTL 秒数。
失败的 DNS 查询也将存储在后端，TTL 可由用户指定。
该模块使用从核心导出的 Key-Value 接口。


### 依赖


#### OpenSIPS 模块


在加载 dns_cache 模块之前必须加载 cachedb_* 类型的模块。


### 导出的参数


#### cachedb_url (string)


将用于存储 DNS 记录的键值后端的 URL。


```c title="设置 cachedb_url 参数"
...
# 使用内部 cachedb_local 模块
modparam("dns_cache", "cachedb_url","local://")
# 使用 cachedb_memcached 模块，memcached 服务器位于 192.168.2.130
modparam("dns_cache", "cachedb_url","memcached://192.168.2.130:8888/")
...
		
```


#### blacklist_timeout (int)


失败的 DNS 查询将在缓存中保留的秒数。
默认值为 3600。


```c title="设置 blacklist_timeout 参数"
...
modparam("dns_cache", "blacklist_timeout",7200) # 2 小时
...
		
```


#### min_ttl (int)


DNS 记录将在缓存中保留的最小秒数。如果 DNS 回答中收到的 TTL 低于此值，
记录将以 min_ttl 秒缓存。


*默认值为 **0** 秒（不强制执行最小 TTL）。*


```c title="设置 min_ttl 参数"
...
modparam("dns_cache", "min_ttl",300) # 5 分钟
...
		
```


### 导出的函数


该模块不导出供配置脚本使用的函数。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0 版授权
