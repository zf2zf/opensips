---
title: "mysql 模块"
description: "这是一个为 OpenSIPS 提供 MySQL 连接功能的模块。它实现了 OpenSIPS 中定义的 DB API。"
---

## 管理指南


### 概述


这是一个为 OpenSIPS 提供 MySQL 连接功能的模块。
它实现了 OpenSIPS 中定义的 DB API。


### 依赖


#### OpenSIPS 模块


以下模块需要在此模块之前加载：


- *如果定义了 [use tls](#param_use_tls)，则还需要加载 **tls_mgm** 模块*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *libmysqlclient-dev* - mysql-client 的开发库。


### 导出的参数


#### exec_query_threshold (integer)


如果查询时间超过 'exec_query_threshold' 微秒，
警告消息将被写入日志设施。


*默认值为 0 - 禁用。*


```c title="设置 exec_query_threshold 参数"
...
modparam("db_mysql", "exec_query_threshold", 60000)
...
```


#### timeout_interval (integer)


连接尝试（读取或写入请求）被中止的时间间隔。
该值会计算三次，因为驱动在放弃之前会进行多次重试。


在驱动版本早于 "5.1.12"、"5.0.25" 和 "4.1.22" 时，
读取超时参数会被忽略。
在版本早于 "5.1.12" 和 "5.0.25" 时，写入超时参数会被忽略，
"4.1" 版本根本不支持此功能。


*默认值为 2（6 秒）。*


```c title="设置 timeout_interval 参数"
...
modparam("db_mysql", "timeout_interval", 2)
...
```


#### max_db_queries (integer)


连接问题导致查询失败时执行重试的最大次数。
如果此参数设置不当，它将被设置为默认值。


*默认值为 2。*


```c title="设置 max_db_queries 参数"
...
modparam("db_mysql", "max_db_queries", 2)
...
```


#### max_db_retries (integer)


数据库连接重试的最大次数。如果此参数
设置不当，它将被设置为默认值。


*默认值为 3。*


```c title="设置 max_db_retries 参数"
...
modparam("db_mysql", "max_db_retries", 2)
...
```


#### ps_max_col_size (integer)


使用预编译语句获取时列数据的最大大小。
对于可变长度数据特别重要，如
CHAR、BLOB 等。


注意：如果列数据超过此限制，值将被
静默截断以适应缓冲区，不会报告任何错误！


*默认值为 *1024（字节）*。*


```c title="设置 ps_max_col_size 参数"
...
modparam("db_mysql", "ps_max_col_size", 4096)
...
```


#### use_tls (integer)


设置此参数将允许您对 MySQL 连接使用 TLS。
要为特定连接启用 TLS，您可以在相应
OpenSIPS 模块的 db_url 中使用
"**tls_domain=**dom_name" URL 参数。这应该放在
URL 末尾 **'?'** 字符之后。此外，
查询字符串可能包含 "**tls_opts=**
PKEY,CERT,CA,CA_DIR,CIPHERS" CSV 参数，以控制/限制
传递给 TLS 库的 TLS 选项数量。


使用此参数时，还必须确保
*tls_mgm* 已加载并正确配置。请参阅
该模块以获取有关 TLS 客户端域的更多信息。


请注意，如果您想使用此功能，TLS 域必须在
配置文件中配置，*不是*
在数据库中。如果您从数据库加载 TLS 证书，
则必须在配置脚本中至少定义一个域，
以用于到数据库的初始连接。


此外，您*不能*为 *tls_mgm* 模块
自己的数据库连接启用 TLS。


*默认值为 **0**（未启用）*


```c title="设置 use_tls 参数"
...
modparam("tls_mgm", "client_domain", "dom1")
modparam("tls_mgm", "certificate", "[dom1]/etc/pki/tls/certs/opensips.pem")
modparam("tls_mgm", "private_key", "[dom1]/etc/pki/tls/private/opensips.key")
modparam("tls_mgm", "ca_list",     "[dom1]/etc/pki/tls/certs/ca.pem")
...
modparam("db_mysql", "use_tls", 1)
...
modparam("usrloc", "db_url", "mysql://root:1234@localhost/opensips?tls_domain=dom1")
...
modparam("usrloc", "db_url", "mysql://root:1234@localhost/opensips?tls_domain=dom1&tls_opts=PKEY,CERT,CA,CA_DIR,CIPHERS")
...
```


### 导出的函数


配置文件中没有导出可使用的函数。


### 安装


由于依赖外部库，mysql 模块默认不会
被编译和安装。您可以使用以下选项之一：


- - 编辑 "Makefile" 并从 "excluded_modules"
列表中删除 "db_mysql"。然后按照标准程序安装 OpenSIPS：
"make all; make install"。
- - 从命令行使用：'make all include_modules="db_mysql";
make install include_modules="db_mysql"'。


### 导出的事件


#### E_MYSQL_CONNECTION


当 MySQL 连接丢失或恢复时触发此事件。


参数：


- *url* - 由 *db_url* 参数指定的连接 URL。
- *status* - 如果连接恢复，则为 *connected*，
如果连接丢失，则为 *disconnected*。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0
