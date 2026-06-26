---
title: "unixodbc 模块"
description: "此模块允许在 OpenSIPS 中使用 unixodbc 包。它已使用 mysql 和 odbc 连接器进行了测试，但应该也适用于其他数据库。auth_db 模块可以工作。"
---

## 管理指南


### 概述


此模块允许在 OpenSIPS 中使用 unixodbc 包。它已使用
mysql 和 odbc 连接器进行了测试，但应该也适用于其他数据库。auth_db 模块可以工作。


有关更多信息，请参阅 [http://www.unixodbc.org/](http://www.unixodbc.org/) 项目网页。


要查看可以通过 unixodbc 使用哪些 DB 引擎，请查看
[http://www.unixodbc.org/drivers.html](http://www.unixodbc.org/drivers.html)。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他 OpenSIPS 模块*。


#### 外部库或应用程序


以下库或应用程序必须在运行
加载了此模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### auto_reconnect (int)


开启或关闭自动重连模式。


*默认值为 "1"，表示已启用。*


```c title="设置 'auto_reconnect' 参数"
...
modparam("db_unixodbc", "auto_reconnect", 0)
...
```


#### use_escape_common (int)


使用内部 escape_common() 函数转义查询中的值。
它转义单引号 '''、双引号 '"'、反斜杠 '\' 和 NULL 字符。


如果您知道 ODBC 驱动程序将上述字符视为特殊字符（用于标记值的开始和结束、转义其他字符...），则应启用此参数。这可以防止 SQL 注入攻击。


*默认值为 "0"（0 = 禁用；1 = 启用）。*


```c title="设置 'use_escape_common' 参数"
...
modparam("db_unixodbc", "use_escape_common", 1)
...
```


### 导出的函数


无


### 安装和运行


#### 安装


先决条件：您应该首先安装 unixodbc（或其他实现 odbc 标准的程序，如 iodbc）、您的数据库和正确的连接器。在 odbc.ini 文件中设置 DSN，在 odbcinst.ini 文件中设置连接器驱动程序。


#### 配置和运行


在 opensips.conf 文件中，添加以下行：


```c
....
loadmodule "/usr/local/lib/opensips/modules/db_unixodbc.so"
....
```


您还应该取消注释以下内容：


```c
....
loadmodule "/usr/local/lib/opensips/modules/auth.so"
loadmodule "/usr/local/lib/opensips/modules/auth_db.so"
modparam("usrloc", "working_mode_preset", "single-instance-sql-write-back")
modparam("auth_db", "calculate_ha1", yes)
modparam("auth_db", "password_column", "password")
....
```


并设置 odbc.ini 中指定的 DSN，将此行与 url 一起添加：


```c
....
modparam("usrloc|auth_db", "db_url", 
    "unixodbc://opensips:opensipsrw@localhost/my_dsn")
....
```


将 my_dsn 替换为正确的值。


提示：如果 unixodbc 无法连接到 mysql 服务器，请尝试使用以下命令重启 mysql 服务器：


```c
shell>safe_mysqld --user=mysql --socket=/var/lib/mysql/mysql.sock
```


连接器在 /var/lib/mysql/mysql.sock 中搜索套接字，而不是在 /tmp/mysql.sock 中


## 开发者指南


该模块实现了 OpenSIPS DB API，以供其他模块使用。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0
