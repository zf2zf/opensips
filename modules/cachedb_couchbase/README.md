---
title: "cachedb_couchbase 模块"
description: "本模块是缓存系统的实现，旨在与 Couchbase 服务器配合工作。它使用 libcouchbase 客户端库连接到服务器实例。它使用了 OpenSIPS 核心导出的 Key-Value 接口。"
---

## 管理指南


### 概述


本模块是缓存系统的实现，旨在与 Couchbase 服务器配合工作。它使用 libcouchbase 客户端库连接到服务器实例。
它使用了 OpenSIPS 核心导出的 Key-Value 接口。


### 优势


- *内存成本不再由服务器承担*
- *可以在集群内使用多台服务器，因此内存实际上是无限的*
- *缓存是 100% 持久化的。OpenSIPS 服务器的重启不会影响 DB。CouchBase DB 也是持久化的，因此也可以在不失数据的情况下重启。*
- *CouchBase 是开源项目，因此可用于与各种其他应用程序交换数据*
- *通过创建 CouchBase 集群，多个 OpenSIPS 实例可以轻松共享键值信息*


### 限制


- *键（键值对中的键）不能包含空格或控制字符*


### 依赖


#### OpenSIPS 模块


无。


#### 外部库或应用程序


运行 OpenSIPS 并加载本模块之前，必须安装以下库或应用程序：


- *libcouchbase >= 3.0:*
libcouchbase 可从 http://www.couchbase.com/develop/c/current 下载


### 导出的参数


#### cachedb_url (字符串)


OpenSIPS 将连接到的服务器组 URL，以便在脚本中使用 cache_store、cache_fetch 等操作。
可以多次设置此参数。
URL 的前缀部分将是脚本中使用的标识符。
URL 格式为：
couchbase[:identifier]://[username:password@]IP:Port/bucket_name


```c title="设置 cachedb_url 参数"
...
modparam("cachedb_couchbase", "cachedb_url","couchbase:group1://localhost:6379/default")
modparam("cachedb_couchbase", "cachedb_url","couchbase:cluster1://random_url:8888/my_bucket")
# 多个主机
modparam("cachedb_couchbase", "cachedb_url","couchbase:cluster1://random_url1:8888,random_url2:8888,random_url3:8888/my_bucket")
...
	
```


#### timeout (整数)


Couchbase 操作预期的最大持续时间（微秒）。
默认值为 3000000（3 秒）。


```c title="设置 timeout 参数"
...
modparam("cachedb_couchbase", "timeout",5000000);
...
	
```


#### exec_threshold (整数)


Couchbase 查询可以持续的最大微秒数。
超过此阈值将触发日志中的警告消息。


*默认值为 "0（无限制 - 无警告）"。*


```c title="设置 exec_threshold 参数"
...
modparam("cachedb_couchbase", "exec_threshold", 100000)
...
	
```


#### lazy_connect (整数)


延迟连接到存储桶，直到第一次使用它。
启动时连接多个存储桶可能非常耗时。此选项允许通过延迟连接直到需要时来实现更快的启动。
对于未测试的存储桶配置/设置，此选项可能很危险。请始终先不使用 lazy_connect 进行测试。
此选项将在首次访问存储桶时在日志中显示错误。
默认值为 0（启动时连接所有存储桶）。


```c title="设置 lazy_connect 参数"
...
modparam("cachedb_couchbase", "lazy_connect", 1);
...
	
```


```c title="使用 CouchBase 服务器"
...
cache_store("couchbase:group1","key","$ru value");
cache_fetch("couchbase:cluster1","key",$avp(10));
cache_remove("couchbase:cluster1","key");
...
	
```


#### 导出的函数


本模块不导出在配置脚本中使用的函数。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享许可证 4.0 版授权
