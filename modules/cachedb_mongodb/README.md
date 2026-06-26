---
title: "cachedb_mongodb 模块"
description: "本模块是缓存系统的实现，旨在与 MongoDB 服务器配合工作。它实现了 OpenSIPS 核心公开的 Key-Value 接口。"
---

## 管理指南


### 概述


本模块是缓存系统的实现，旨在与 MongoDB 服务器配合工作。
它实现了 OpenSIPS 核心公开的 Key-Value 接口。


底层客户端库兼容以下任何 MongoDB 服务器版本：2.4、2.6、3.0、3.2 和 3.4，
如 [MongoDB 文档](https://docs.mongodb.com/ecosystem/drivers/driver-compatibility-reference/) 中所述。


### 优势


- *内存成本不再由服务器承担*
- *可以在集群内使用多台服务器，因此内存实际上是无限的*
- *缓存是 100% 持久化的。OpenSIPS 服务器的重启不会影响 DB。MongoDB 也是持久化的，因此也可以在不失数据的情况下重启。*
- *MongoDB 是开源项目，因此可用于与各种其他应用程序交换数据*
- *通过创建 MongoDB 集群，多个 OpenSIPS 实例可以轻松共享键值信息*
- *本模块还实现了 CacheDB 原始查询功能，
			因此您可以运行 MongoDB 后端支持的任何查询，充分利用它。*


### 限制


- *键（键值对中的键）不能包含空格或控制字符*


### 依赖


#### OpenSIPS 模块


无。


#### 外部库或应用程序


运行 OpenSIPS 并加载本模块之前，必须安装以下软件包：


```c title="运行 'cachedb_mongodb' 的运行时要求"
# Debian / Ubuntu
sudo apt-get install libjson-c2 libmongoc-1.0

# Red Hat / CentOS
sudo yum install json-c mongo-c-driver
					
```


编译此模块需要以下软件包：


```c title="编译 'cachedb_mongodb' 的要求"
# Debian / Ubuntu
sudo apt-get install libjson-c-dev libmongoc-dev libbson-dev

# Red Hat / CentOS
sudo yum install json-c-devel mongo-c-driver-devel
					
```


### 导出的参数


#### cachedb_url (字符串)


OpenSIPS 将连接到的服务器组 URL，以便从 OpenSIPS 脚本中使用 cache_store()、cache_fetch() 等函数。
可以多次设置此参数。
URL 的前缀部分将是脚本中使用的标识符。


URL 语法与 MongoDB 使用的语法相同，包括连接字符串选项。
有关更多信息，请参阅 [官方 MongoDB 连接字符串文档](https://docs.mongodb.com/manual/reference/connection-string/)。


```c title="设置 cachedb_url 参数"
...
# 连接到单个
```


```c title="引用 MongoDB 连接"
...
cache_store("mongodb", "key", "$ru value");
cache_remove("mongodb:cluster", "key");
cache_fetch("mongodb:instance1", "key", $avp(10));
...

```


#### exec_threshold (整数)


MongoDB 查询可以持续的最大微秒数。
超过此阈值将触发日志中的警告消息。


*默认值为 "0（无限制 - 无警告）"。*


```c title="设置 exec_threshold 参数"
...
modparam("cachedb_mongodb", "exec_threshold", 100000)
...

```


#### compat_mode_2.4 (整数)


将模块切换为 MongoDB 2.4 服务器的兼容模式。
具体来说，这允许"插入/更新/删除"原始查询不会失败，
因为它们是在 MongoDB 2.6 中引入的。模块将解析原始查询 JSON，
将其转换为相应的命令并运行。


注意：此模式下仅支持最少需要的原始查询选项。


*默认值为 "0（禁用）"。*


```c title="设置 compat_mode_2.4 参数"
...
modparam("cachedb_mongodb", "compat_mode_2.4", 1)
...

```


#### compat_mode_3.0 (整数)


将模块切换为 MongoDB 2.6/3.0 服务器的兼容模式。
具体来说，这允许"查找"原始查询不会失败，
因为它们是在 MongoDB 3.2 中引入的。模块将解析"查找"原始查询 JSON，
将其转换为相应的命令并运行。


注意：此模式下仅支持"查找"原始查询的最少所需选项。


*默认值为 "0（禁用）"。*


```c title="设置 compat_mode_3.0 参数"
...
modparam("cachedb_mongodb", "compat_mode_3.0", 1)
...

```


### 导出的函数


本模块不导出在配置脚本中使用的函数。


### 原始查询语法


cachedb_mongodb 模块支持原始查询，因此可以充分利用后端的功能，
包括特定于查询的选项，如读/写偏好、超时、
过滤选项等。


查询语法与 mongo cli 相同。文档可在
[MongoDB 网站](https://docs.mongodb.com/manual/reference/command/nav-crud/) 上找到。
查询结果作为 JSON 文档返回，可以通过使用 JSON 模块在 OpenSIPS 脚本中进一步处理。


一些原始查询示例：


```c title="MongoDB 原始插入"
...
cache_raw_query("mongodb:cluster", "{ \
    \"insert\": \"ip_blacklist\", \
    \"documents\": [{ \
        \"username\": \"$fU\", \
        \"ip\": \"$si\", \
        \"attempts\": 1 \
     }]}",
 "$avp(out)");
xlog("INSERT RAW QUERY returned $rc, output: '$avp(out)'\n");
...

			
```


```c title="MongoDB 原始更新"
...
cache_raw_query("mongodb:cluster", "{ \
    \"update\": \"ip_blacklist\", \
    \"updates\": [{ \
        \"q\": { \
            \"username\": \"$fU\", \
            \"ip\": \"$si\" \
         }, \
        \"u\": { \
            \"$$inc\": {\"attempts\": 1} \
         } \
      }]}",
 "$avp(out)");
xlog("UPDATE RAW QUERY returned $rc, output: '$avp(out)'\n");
...

			
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享许可证 4.0 版授权
