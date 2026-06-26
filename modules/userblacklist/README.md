---
title: "userblacklist 模块"
description: "userblacklist 模块允许 OpenSIPS 按用户处理黑名单。此信息存储在数据库表中，通过查询该表来决定号码（更确切地说是请求 URI 用户）是否在黑名单上。"
---

## 管理指南


### 概述


userblacklist 模块允许 OpenSIPS 按用户处理黑名单。
		此信息存储在数据库表中，
		通过查询该表来决定号码（更确切地说是请求 URI 用户）是否在黑名单上。


此模块提供的附加功能是处理全局黑名单的能力。
		这些列表在启动时加载到内存中，
		因此比 userblacklist 情况提供更好的性能。
		这些全局黑名单可用于仅允许呼叫到某些国际目的地，
		即阻止所有未列入白名单的号码。
		它们也可用于防止将重要号码列入黑名单，
		因为也支持列入白名单。例如，这在防止客户阻止紧急呼叫号码或服务热线时很有用。


该模块导出两个函数，*check_blacklist*
		和 *check_user_blacklist*，用于配置文件。
		此外，它还提供一个 FIFO 函数来重新加载全局黑名单缓存。


### 依赖


#### OpenSIPS 模块


该模块依赖以下模块（换句话说，
			列出的模块必须在此模块之前加载）：


- *database* -- 任何数据库模块


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- *无*


### 导出的参数


#### db_url (string)


包含路由数据的数据库的 URL。


*默认值为 "mysql://opensipsro:opensipsro@localhost/opensips"。*


```c title="设置 db_url 参数"
...
modparam("userblacklist", "db_url", "dbdriver://username:password@dbhost/dbname")
...

```


#### db_table (string)


存储用户黑名单数据的表名。


*默认值为 "userblacklist"。*


```c title="设置 db_table 参数"
...
modparam("userblacklist", "db_table", "userblacklist")
...
		    
```


#### use_domain (boolean)


如果启用，表查找中也将匹配 "domain" 列，
			以进行更严格的匹配。


*默认值为 *true*（启用）。*


```c title="设置 use_domain 参数"
...
modparam("userblacklist", "use_domain", true)
...
		    
```


### 导出的函数


#### check_user_blacklist (user, domain, [number], [table])


在数据库中查找与给定用户和域名的请求 URI 用户
		（或 number 参数）匹配的最长前缀。
		如果找到匹配且未设置为白名单，则返回 false。
		否则返回 true。number 参数可用于检查例如 from URI 用户。


参数：


- *user* (string) - 描述
- *domain* (string) - 描述
- *number* (string, 可选) - 如果省略，
		    		使用默认值。
- *table* (string, 可选) - 如果省略，
		    		使用默认值。


```c title="check_user_blacklist 使用示例"
...
if (!check_user_blacklist("user", "domain.com"))
	sl_send_reply(403, "Forbidden");
	exit;
}
...

```


#### check_blacklist (table)


在给定表中查找与请求 URI 匹配的最长前缀。
		如果找到匹配且未设置为白名单，则返回 false。
		否则返回 true。


参数：


- *table* (string)


```c title="check_blacklist 使用示例"
...
if (!check_blacklist("global_blacklist")))
	sl_send_reply(403, "Forbidden");
	exit;
}
...

```


### 导出的 MI 函数


#### userblacklist:reload


替换已弃用的 MI 命令：*reload_blacklist*。


重新加载内部全局黑名单缓存。
		这是在全局黑名单的数据库表发生更改后必需的。


```c title="reload_blacklists 使用示例"
...
opensips-cli -x mi userblacklist:reload
...

```


### 安装和运行


#### 数据库设置


在运行带有 userblacklist 的 OpenSIPS 之前，
			您必须设置模块将读取黑名单数据的数据库表。
			因此，如果表不是由安装脚本创建的，
			或者您选择自己安装所有内容，
			您可以使用 opensips/scripts 文件夹中数据库目录中的
			userblacklist-create.sql SQL 脚本作为模板。
			数据库和表名可以通过模块参数设置，
			因此可以更改，但列名必须与 SQL 脚本中的名称相同。
			您还可以在项目网页上找到完整的数据库文档，
			https://opensips.org/docs/db/db-schema-devel.html。


```c title="示例数据库内容 - globalblacklist 表"
...
+----+-----------+-----------+
| id | prefix    | whitelist |
+----+-----------+-----------+
|  1 |           |         0 |
|  2 | 1         |         1 |
|  3 | 123456    |         0 |
|  4 | 123455787 |         0 |
+----+-----------+-----------+
...

```


此表将为所有号码设置全局黑名单，仅允许以 "1" 开头的呼叫。
		以 "123456" 和 "123455787" 开头的号码也被列入黑名单，
		因为将匹配最长前缀。


```c title="示例数据库内容 - userblacklist 表"
...
+----+----------------+-------------+-----------+-----------+
| id | username       | domain      | prefix    | whitelist |
+----+----------------+-------------+-----------+-----------+
| 23 | 49721123456788 |             | 1234      |         0 |
| 22 | 49721123456788 |             | 123456788 |         1 |
| 21 | 49721123456789 |             | 12345     |         0 |
| 20 | 494675231      |             | 499034133 |         1 |
| 19 | 494675231      | test        | 499034132 |         0 |
| 18 | 494675453      | test.domain | 49901     |         0 |
| 17 | 494675454      |             | 49900     |         0 |
+----+----------------+-------------+-----------+-----------+
...

```


此表将为某些用户名设置用户特定的黑名单。例如
		对于用户 "49721123456788"，前缀 "1234" 将不被允许，
		但号码 "123456788" 是允许的。
		此外，如果设置了 "use_domain" 参数，
		可以指定用于用户名匹配的域。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
