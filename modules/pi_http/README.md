---
title: "pi_http 模块"
description: "此模块为 OpenSIPS 提供 HTTP 配置接口。它使用 OpenSIPS 的内部数据库 API 提供了一种操作 OpenSIPS 表中记录的简单方法。该模块提供：通过 OpenSIPS 的 db API 连接到多个/不同数据库的能力；..."
---

## 管理指南


### 概述


此模块为 OpenSIPS 提供 HTTP 配置接口。它使用 OpenSIPS 的内部
		数据库 API 提供了一种操作 OpenSIPS 表中记录的简单方法。
		该模块提供：
			
			通过 OpenSIPS 的 db API 连接到多个/不同数据库的能力；
			（支持所有 OpenSIPS 的数据库）；
			通过 OpenSIPS API 执行数据输入验证的能力；
			通过 mi 命令接口从 xml 框架重新加载配置来动态调整接口布局的能力。
		注意：当使用 *db_text* 配置表时，
		对 *db_text* 表的任何更改都不会反映在实际的文本文件中。
		为了强制将缓存表写出到磁盘，必须使用 db_text 的 mi 命令
		*dbt_dump*。


### 用法


配置接口的布局通过外部 xml 文件控制（请参阅 framework 参数）。
		框架 xml 文件的示例在 pi_http 模块的 examples 目录中提供。
		可以通过 opensips-cli 命令生成简单的框架文件：


```c
opensips-cli pframework create
			
```


生成的框架将保存在 OpenSIPS 的配置目录中，名为 pi_framework_sample。
		可配置表的列表将基于 opensips-cli.cfg 的 "database_modules" 设置（如果存在），
		否则将使用一组默认的可配置表。


### 框架


xml 框架文件由三个独特的块组成：


- 数据库连接定义块
- 表定义块
- 命令定义块


#### 数据库连接定义块


到特定数据库的每个连接必须在此定义，并带有唯一的数据库连接 ID。
		连接参数遵循所有使用数据库的 OpenSIPS 模块的 db_url 参数模式。


支持的数据库：


- berkeley
- flatstore
- http
- mysql
- oracle
- postgres
- text
- unixodbc
- virtual


#### 表定义块


通过 OpenSIPS 配置接口管理的每个表必须在此定义，并带有唯一的表 ID。
		对于每个表，必须指定数据库连接 ID。
		每个表必须列出将由 OpenSIPS 配置接口管理的所有列。
		每列必须有一个唯一的字段名和类型。
		每列可以有一个用于验证输入数据的验证标签。


支持的列类型：


- DB_INT
- DB_BIGINT
- DB_DOUBLE
- DB_STRING
- DB_STR
- DB_DATETIME

  - 注意：输入字段必须以
					'YEAR-MM-DD HH:MM:SS' 格式提供。
- DB_BLOB
- DB_BITMAP


支持的验证方法：


- IPV4 - 表示 IPv4 地址
- URI - 表示 SIP URI
- URI_IPV4HOST - 表示以 IPV4 作为主机的 SIP URI
- P_HOST_PORT - 表示 [proto:]host[:port]
- P_IPV4_PORT - 表示 [proto:]IPv4[:port]


#### 命令定义块


多个配置命令可以分组在一起。
		每个组可以有多个命令。
		组中的每个命令定义必须具有所操作表的表 ID 以及要执行的命令类型。


命令类型最多可以有三种类型的列参数：


- 子句列
- 查询列
- 排序列


每个列参数必须定义列的名称（必须与表 ID 标识的描述表中的字段名匹配）。
		列可以接受一系列强加值。
		每个强加值都有一个 ID，将显示在 Web 界面上，以及将用于 db 操作的实际值。
		子句列必须定义运算符。
		以下是支持的运算符列表：
		'<'、'>'、'='、'<='、'>='、'!='。


支持的数据库命令类型：


- DB_QUERY - 执行 SQL 查询
			并支持三种类型的列：

  - 子句：0 或多个列
  - 查询：1 列
  - 排序：0 或 1 列
- DB_INSERT - 执行 SQL 插入
			并支持一种类型的列：

  - 查询：1 或多个列
- DB_DELETE - 执行 SQL 删除
			并支持一种类型的列：

  - 子句：1 或多个列
- DB_UPDATE - 执行 SQL 更新
			并支持两种类型的列：

  - 子句：0 或多个列
  - 查询：1 或多个列
- DB_REPLACE - 执行 SQL 替换
			并支持一种类型的列：

  - 查询：1 或多个列


请注意，某些数据库的命令类型集有限制。


### 待办事项


将来要添加的功能：


- 具有自动 ha1/ha1b 字段的完整订户配置。


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *httpd* 模块。


#### 外部库或应用程序


必须在运行加载了此模块的 OpenSIPS 之前安装以下库或应用程序：


- *libxml2*


### 导出的参数


#### pi_http_root(string)


指定 pi HTTP 请求的根路径。
		OpenSIPS 配置 Web 接口的链接必须使用以下模式构建：
		http://[opensips_IP]:[opensips_mi_port]/[pi_http_root]


*默认值为 "pi"。*


```c title="设置 pi_http_root 参数"
...
modparam("pi_http", "pi_http_root", "opensips_pi")
...
```


#### framework(string)


指定 xml 框架描述符的完整路径。


*没有默认值。此参数是必需的。*


```c title="设置 framework 参数"
...
modparam("pi_http", "framework", "/usr/local/etc/opensips/pi_framework.xml")
...
```


#### pi_http_method(integer)


指定要使用的 HTTP 请求方法：


- 0 - 使用 GET HTTP 请求
- 1 - 使用 POST HTTP 请求


*默认值为 0。*


```c title="设置 pi_http_method 参数"
...
modparam("pi_http", "pi_http_method", 1)
...
```


### 导出的 MI 函数


#### pi_http:reload_tbls_and_cmds


替换过时的 MI 命令：*pi_reload_tbls_and_cmds*。


从框架文件重新加载配置接口的布局。


名称：*pi_http:reload_tbls_and_cmds*


参数：无


MI FIFO 命令格式：


```c
opensips-cli -x mi pi_http:reload_tbls_and_cmds
			
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
