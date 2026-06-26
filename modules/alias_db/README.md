---
title: "ALIAS_DB 模块"
description: "ALIAS_DB 模块可用作用户别名的替代方案，通过 usrloc 实现。其主要特点是不会像用户位置那样存储所有相关数据，并且始终使用数据库进行搜索（无内存缓存）。"
---

## 管理指南


### 概述


ALIAS_DB 模块可用作用户别名的替代方案，通过 usrloc 实现。其主要特点是不会像用户位置那样存储所有相关数据，并且始终使用数据库进行搜索（无内存缓存）。


由于没有内存缓存，搜索速度可能会降低，但配置更简单。对于像 MySQL 这样的快速数据库，速度惩罚可以降低。此外，可以在同一脚本中对不同的表进行搜索。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *数据库模块*（mysql、dbtext 等）。


#### 外部库或应用程序


运行 OpenSIPS 加载此模块前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### db_url (str)


数据库 URL。


*默认值为 "mysql://opensipsro:opensipsro@localhost/opensips"。*


```c title="设置 db_url 参数"
...
modparam("alias_db", "db_url", "dbdriver://username:password@dbhost/dbname")
...
```


#### user_column (str)


保存用户名的列名。


*默认值为 "username"。*


```c title="设置 user_column 参数"
...
modparam("alias_db", "user_column", "susername")
...
```


#### domain_column (str)


保存用户域名的列名。


*默认值为 "domain"。*


```c title="设置 domain_column 参数"
...
modparam("alias_db", "domain_column", "sdomain")
...
```


#### alias_user_column (str)


保存别名用户名的列名。


*默认值为 "alias_username"。*


```c title="设置 alias_user_column 参数"
...
modparam("alias_db", "alias_user_column", "auser")
...
```


#### alias_domain_column (str)


保存别名域名的列名。


*默认值为 "alias_domain"。*


```c title="设置 alias_domain_column 参数"
...
modparam("alias_db", "alias_domain_column", "adomain")
...
```


#### domain_prefix (str)


指定在执行搜索之前从 R-URI 中剥离的域名前缀。


*默认值为 "NULL"。*


```c title="设置 domain_prefix 参数"
...
modparam("alias_db", "domain_prefix", "sip.")
...
```


#### append_branches (int)


如果别名解析为多个 SIP ID，第一个替换 R-URI，其余作为分支添加。


*默认值为 "0"（0 - 不添加分支；1 - 添加分支）。*


```c title="设置 append_branches 参数"
...
modparam("alias_db", "append_branches", 1)
...
```


### 导出的函数


#### alias_db_lookup(table_name, [flags])


该函数获取 R-URI 并搜索它是否是别名。如果它是本地用户的别名，则 R-URI 将被替换为用户的 SIP URI。


如果 R-URI 是别名并被替换为用户的 SIP URI，则函数返回 TRUE。


参数含义如下：


- *table_name (string)* - 搜索别名的表名
- *flags (string, 可选)* - 控制别名查找过程的字符标志集：

  - **d** - 在别名查找查询中不使用域名 URI 部分（仅使用基于用户名的查找）。默认情况下，用户名和域名都会被使用。
  - **r** - 执行反向别名查找 - 查找映射到当前 URI 的别名（URI 到别名的转换）；通常，该函数查找映射到别名的 URI（别名到 URI 的转换）。


此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE 使用。


```c title="alias_db_lookup() 使用示例"
...
alias_db_lookup("dbaliases", "rd");
alias_db_lookup("dba_$(rU{s.substr,0,1})");
...
```


#### alias_db_find(table_name, input_uri, output_var, [flags])


该函数与 `alias_db_lookup()` 非常相似，但能够从伪变量获取输入 SIP URI 并将结果也放回伪变量，而不是使用固定输入（RURI）和输出（RURI）。


该函数很有用，因为别名查找不会影响请求本身（不更改 RURI），可以在回复上下文中使用（因为它不仅处理 RURI），并且可以用于 RURI 以外的 URI（To URI、From URI、自定义 URI）。


如果找到任何别名映射则返回 TRUE。


参数含义如下：


- *table_name (string)* - 搜索别名的表名
- *input_uri (string)* - 要查找的 SIP URI
- *output_var (var)* - 保存 SIP URI 结果的变量
- *flags (string, 可选) （可选） - 控制别名查找过程的标志集（基于字符的标志）：

  - *d* - 在别名查找查询中不使用域名 URI 部分（仅使用基于用户名的查找）。默认情况下，用户名和域名都会被使用。
  - *r* - 执行反向别名查找 - 查找映射到当前 URI 的别名（URI 到别名的转换）；通常，该函数查找映射到别名的 URI（别名到 URI 的转换）。


此函数可以从 REQUEST_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE、STARTUP_ROUTE、FAILURE_ROUTE 和 ONREPLY_ROUTE 使用。


```c title="alias_db_find() 使用示例"
...
# 执行反向别名查找并查找 FROM URI 的别名
alias_db_find("dbaliases", $fu, $avp(from_alias), "r");
...
```


## 常见问题


**Q: 旧的 use_domain 参数怎么了**




全局参数（影响整个模块）已被每个查找参数（仅影响当前查找）取代。
			参见 db_alias_lookup() 和 db_alias_find() 函数中的"d"（不使用域名部分）标志。


**Q: 如何报告 bug？**


请遵循以下指南：
			[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用 Creative Common License 4.0 许可证。
