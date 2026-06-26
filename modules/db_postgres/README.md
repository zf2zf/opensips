---
title: "db_postgres 模块"
description: "模块描述"
---

## 管理指南


### 概述


模块描述


### 依赖


#### OpenSIPS 模块


以下模块需要在此模块之前加载：


- *不依赖其他 OpenSIPS 模块*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *PostgreSQL 库* - 例如 libpq5。
- *PostgreSQL 开发库* - 用于编译
模块（例如 libpq-dev）。


### 导出的参数


#### exec_query_threshold (integer)


如果查询时间超过 'exec_query_threshold' 微秒，
警告消息将被写入日志设施。


*默认值为 0 - 禁用。*


```c title="设置 exec_query_threshold 参数"
...
modparam("db_postgres", "exec_query_threshold", 60000)
...
```


#### max_db_queries (integer)


要执行的数据库查询的最大数量。
如果此参数设置不当，它将被设置为默认值。


*默认值为 2。*


```c title="设置 max_db_queries 参数"
...
modparam("db_postgres", "max_db_queries", 2)
...
```


#### timeout (integer)


PostgreSQL 库等待连接和查询服务器的时间（秒）。
如果连接在给定超时时间内未成功，
则连接失败。


*注意：* 如果超时为负值且
连接未成功，OpenSIPS 将阻塞，直到连接
恢复可用并成功建立。这是库的
默认行为，也是此参数添加之前的默认行为。


*默认值为 5。*


```c title="设置 timeout 参数"
...
modparam("db_postgres", "timeout", 2)
...
```


#### use_tls (integer)


连接到 Postgres 服务器时控制 SSL 支持使用方式的参数，
如下所示：


- *use_tls=0*（默认）- SSL 支持
被禁用，不会尝试使用它；
- *use_tls=1* 且 DB URL 中存在 "tls_domain"
- SSL 支持已启用，根据证书
设置，可能是 "require" 或 "verify-ca"；
- *use_tls=1* 且 DB URL 中没有 "tls_domain"
- SSL 支持以最大努力模式（或 "prefer"）启用
；如果服务器支持，则使用它，
否则回退到非 SSL。


警告：设置此参数时，不能使用
*tls_openssl* 模块。如果需要 TLS/SSL 库，
请改用 *tls_wolfssl* 模块。


设置此参数将允许您对 PostgreSQL 连接使用 TLS。
要为特定连接启用 TLS，您可以在相应
OpenSIPS 模块的 db_url 中使用
"tls_domain=*dom_name*" URL 参数。这应该放在
URL 末尾 '?' 字符之后。


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
modparam("db_postgres", "use_tls", 1)
...
modparam("usrloc", "db_url", "postgres://root:1234@localhost/opensips?tls_domain=dom1")
...
```


### 导出的函数


无


### 安装和运行


关于安装和运行的说明。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0
