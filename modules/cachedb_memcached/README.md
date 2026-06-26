---
title: "cachedb_memcached 模块"
description: "本模块是缓存系统的实现，旨在与 memcached 服务器配合工作。它使用 libmemcached 客户端库连接到多个存储数据的 memcached 服务器。它使用了 OpenSIPS 核心导出的 Key-Value 接口。"
---

## 管理指南


### 概述


本模块是缓存系统的实现，旨在与 memcached 服务器配合工作。它使用 libmemcached 客户端库连接到多个存储数据的 memcached 服务器。它使用了 OpenSIPS 核心导出的 Key-Value 接口。


### 优势


- *内存成本不再由服务器承担*
- *可以使用多台服务器，因此内存实际上是无限的*
- *缓存是持久化的，因此服务器重启不会影响缓存*
- *memcached 是开源项目，因此可用于与各种其他应用程序交换数据*
- *服务器可以分组在一起
			（例如出于安全目的：一些可以在专用网络中，一些可以在公共网络中）*


### 限制


- *键（键值对中的键）不能包含空格或控制字符*


### 依赖


#### OpenSIPS 模块


无。


#### 外部库或应用程序


运行 OpenSIPS 并加载本模块之前，必须安装以下库或应用程序：


- *libmemcached:*
libmemcached 可从以下地址下载：http://tangent.org/552/libmemcached.html。
			下载压缩包，解压源码，运行 ./configure，make，sudo make install。
...
			wget http://download.tangent.org/libmemcached-0.31.tar.gz 
			tar -xzvf libmemcached-0.31.tar.gz
			cd libmemcached-0.31
			./configure
			make
			sudo make install
			...


### 导出的参数


#### cachedb_url (字符串)


OpenSIPS 将连接到的服务器组 URL，以便在脚本中使用 cache_store、cache_fetch 等操作。
可以多次设置此参数。
URL 的前缀部分将是脚本中使用的标识符。


```c title="设置 cachedb_url 参数"
...
modparam("cachedb_memcached", "cachedb_url","memcached:group1://localhost:9999,127.0.0.1/");
modparam("cachedb_memcached", "cachedb_url","memcached:y://random_url:8888/");
...

```


```c title="使用 memcached 服务器"
...
cache_store("memcached:group1","key","$ru value");
cache_fetch("memcached:y","key",$avp(10));
cache_remove("memcached:group1","key");
...

```


#### exec_threshold (整数)


本地缓存查询可以持续的最大微秒数。
超过此阈值将触发日志中的警告消息。


*默认值为 "0（无限制 - 无警告）"。*


```c title="设置 exec_threshold 参数"
...
modparam("cachedb_memcached", "exec_threshold", 100000)
...

```


### 导出的函数


本模块不导出在配置脚本中使用的函数。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享许可证 4.0 版授权
