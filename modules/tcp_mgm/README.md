---
title: "TCP 管理模块 (tcp_mgm)"
description: "此模块提供可选的、基于 SQL 的支持，用于对 OpenSIPS 上发生的所有 TCP 连接进行细粒度管理。"
---

## 管理指南


### 概述


此模块提供可选的、基于 SQL 的支持，
		用于对 OpenSIPS 上发生的所有 TCP 连接进行细粒度管理。


### 依赖


#### OpenSIPS 模块


必须至少加载一个 SQL 数据库模块（例如 "db_xxx"）。


#### 外部库或应用程序


无。


### 导出的参数


#### db_url (string)


SQL 数据库的强制性 URL。


```c title="设置 db_url 参数"
modparam("tcp_mgm", "db_url", "mysql://opensips:opensipsrw@localhost/opensips")
```


#### db_table (string)


保存 TCP 路径（规则）的表名称。


默认值为 *"tcp_mgm"*。


```c title="设置 db_table 参数"
modparam("tcp_mgm", "db_table", "tcp_mgm")
```


#### [column-name]_col (string)


使用不同名称表示 *"column-name"* 列。


```c title="设置 [column-name]_col 参数"
modparam("tcp_mgm", "connect_timeout_col", "connect_to")
```


### 导出的 MI 函数


#### tcp_mgm:reload


替换已弃用的 MI 命令：*tcp_reload*。


重新加载 *tcp_mgm* 表中的所有 TCP 路径，
		而不会中断正在进行的流量。请注意，
		重新加载的规则不会立即应用于现有 TCP 连接，
		而只会应用于新建立的连接。


示例：


```c
# 重新加载所有 TCP 路径
$ opensips-cli -x mi tcp_mgm:reload
$ "OK"

```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
