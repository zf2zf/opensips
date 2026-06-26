---
title: "SQLops 模块"
description: "SQLops（SQL-operations）模块实现了一组用于通用 SQL 标准查询（原始查询或结构化查询）的脚本函数。它还提供了一组专用的函数，用于数据库操作（加载/存储/删除）用户 AVP（偏好设置）。"
---

## 管理指南

### 概述

SQLops（SQL-operations）模块实现了一组用于通用 SQL 标准查询（原始查询或结构化查询）的脚本函数。它还提供了一组专用的函数，用于数据库操作（加载/存储/删除）用户 AVP（偏好设置）。

### 依赖

#### OpenSIPS 模块

以下模块必须在此模块之前加载：

- *数据库模块*

#### 外部库或应用程序

运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：

- *无*

### 导出的参数

#### db_url (string)

数据库连接的 DB URL。由于该模块允许使用多个 DB（DB URL），实际 DB URL 可以前面带有参考编号。此参考编号要传递给希望明确使用此 DB 连接的 AVPOPS 函数。如果未给出参考编号，则假定为 0 - 这是默认的 DB URL。

*此参数是可选的，其默认值为 NULL。*

```c title="设置 db_url 参数"
...
# 默认 URL
modparam("sqlops","db_url","mysql://user:passwd@host/database")
# 额外的 DB URL
modparam("sqlops","db_url","1 postgres://user:passwd@host2/opensips")
...
					
```

#### usr_table (string)

用于用户偏好设置（AVP）的 DB 表。

*此参数是可选的，其默认值为 "usr_preferences"。*

```c title="设置 usr_table 参数"
...
modparam("sqlops","usr_table","avptable")
...
					
```

#### db_scheme (string)

用于访问非标准用户偏好设置（如表）的 DB 方案定义。

方案定义。方案语法如下：

- *db_scheme = name':'element[';'element]**
- *element* =

  'uuid_col='string
  'username_col='string
  'domain_col='string
  'value_col='string
  'value_type='('integer'|'string')
  'table='string

*默认值为 "NULL"。*

```c title="设置 db_scheme 参数"
...
modparam("sqlops","db_scheme",
"scheme1:table=subscriber;uuid_col=uuid;value_col=first_name")
...
					
```

#### use_domain (boolean)

SIP URI 的域部分是否应该用于在 DB 操作中识别 AVP。

*默认值为 *true*（启用）。*

```c title="设置 use_domain 参数"
...
modparam("sqlops", "use_domain", true)
...
					
```

#### ps_id_max_buf_len (integer)

用于构建查询 ID 的缓冲区最大大小，这些 ID 用于在使用 "sql_select|update|insert|replace|delete()" 函数时管理预处理语句。

如果超出大小（在尝试构建 PS 查询 ID 时），对该查询的 PS 支持将被删除。如果设置为 0，PS 支持将完全禁用。

*默认值为 1024。*

```c title="设置 ps_id_max_buf_len 参数"
...
modparam("sqlops","ps_id_max_buf_len", 2048)
...
					
```

#### bigint_to_str (int)

控制 bigint 转换。默认情况下，bigint 值作为 int 返回。如果存储在 bigint 中的值超出 int 范围，通过启用 bigint 到字符串转换，bigint 值将作为字符串返回。

*默认值为 "0"。*

```c title="设置 bigint_to_str 参数"
...
# 将 bigint 作为字符串返回
modparam("sqlops","bigint_to_str",1)
...
					
```

#### uuid_column (string)

包含 uuid（唯一用户 ID）的列名。

*默认值为 "uuid"。*

```c title="设置 uuid_column 参数"
...
modparam("sqlops","uuid_column","uuid")
...
					
```

#### username_column (string)

包含用户名的列名。

*默认值为 "username"。*

```c title="设置 username_column 参数"
...
modparam("sqlops","username_column","username")
...
					
```

#### domain_column (string)

包含域名名的列名。

*默认值为 "domain"。*

```c title="设置 domain_column 参数"
...
modparam("sqlops","domain_column","domain")
...
					
```

#### attribute_column (string)

包含属性名称（AVP 名称）的列名。

*默认值为 "attribute"。*

```c title="设置 attribute_column 参数"
...
modparam("sqlops","attribute_column","attribute")
...
					
```

#### value_column (string)

包含 AVP 值的列名。

*默认值为 "value"。*

```c title="设置 value_column 参数"
...
modparam("sqlops","value_column","value")
...
					
```

#### type_column (string)

包含 AVP 类型的列名。

*默认值为 "type"。*

```c title="设置 type_column 参数"
...
modparam("sqlops","type_column","type")
...
					
```

### 导出的函数

#### sql_query(query, [res_col_avps], [db_id])

进行数据库查询并将结果存储在 AVP 中。

参数的含义和用法：

- *query (string)* - 必须是有效的 SQL 查询。参数可以包含伪变量。您必须手动转义任何伪变量以防止 SQL 注入攻击。您可以使用现有的转换 *escape.common* 和 *unescape.common* 来转义和非转义任何伪变量的内容。如果不转义查询中使用的变量，您将容易受到 SQL 注入攻击，例如外部攻击者可能更改您的数据库内容。如果查询成功，函数返回 true；如果查询返回空结果集则返回 -2；对于所有其他类型错误则返回 -1。
- *res_col_avps (string, 可选, 不展开)* - 要存储结果的 AVP 名称列表。格式为 "$avp(name1);$avp(name2);..."。如果省略此参数，结果存储在 "$avp(1);$avp(2);..."。如果结果包含多行，则将添加具有相应名称的多个 AVP。AVP 的值类型（字符串或整数）将从列的类型派生。如果数据库中的值为 *NULL*，返回的 avp 将是值为 *<null>* 的字符串。
- *db_id (int, 可选)* - 定义的 DB URL 的引用（数字 id）——请参阅 "db_url" 模块参数。它可以是常量，也可以是字符串/整数变量。

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE 和 ONREPLY_ROUTE 使用。

```c title="sql_query 使用示例"
...
sql_query("SELECT password, ha1 FROM subscriber WHERE username='$tu'",
	"$avp(pass);$avp(hash)");
sql_query("DELETE FROM subscriber");
sql_query("DELETE FROM subscriber", , 2);

$avp(id) = 2;
sql_query("DELETE FROM subscriber", , $avp(id));
...
					
```

#### sql_query_one(query, [res_col_vars], [db_id])

类似于 [sql query](#func_sql_query)，它进行通用原始数据库查询并返回结果，但有以下区别：

- *仅返回一行* - 即使查询结果是多行结果，也只将第一行返回给脚本。
- *返回变量不限于 AVP* - 返回查询结果的变量可以是任何类型的变量，当然只要它是可写的。请注意，返回变量的数量必须与返回列的数量匹配（就数量而言）。如果提供的变量较少，查询将失败。
- *返回 NULL* - 查询产生的任何 DB NULL 值将作为 NULL 指示符推送（而不是 *<null>* 字符串）到脚本变量。

此函数可以从任何类型的路由使用。

```c title="sql_query_one 使用示例"
...
sql_query_one("SELECT password, ha1 FROM subscriber WHERE username='$tU'",
	"$var(pass);$var(hash)");
# 如果相应列未填充，$var(pass) 或 $var(hash) 可能为 NULL
...
sql_query_one("SELECT value, type FROM usr_preferences WHERE username='$fU' and attribute='cfna'",
	"$var(cf_uri);$var(type)");
# 即使用户有多个 `cfna` 属性，上面的查询也只返回一行
...
					
```

#### sql_select([columns],table,[filter],[order],[res_col_avps], [db_id])

执行结构化（非原始）SQL SELECT 操作的函数。查询通过 OpenSIPS 内部 SQL 接口执行，利用预处理语句支持的优势（如果 db 后端提供类似功能）。所选列返回到一组 AVP（与所选列一一对应）。

> [!WARNING]
> 如果在构造查询时使用变量，您必须手动转义它们的值以防止 SQL 注入攻击。您可以使用现有的转换 *escape.common* 和 *unescape.common* 来转义和非转义任何伪变量的内容。如果不转义查询中使用的变量，您将容易受到 SQL 注入攻击，例如外部攻击者可能更改您的数据库内容。

如果查询成功，函数返回 true；如果查询返回空结果集则返回 -2；对于所有其他类型错误则返回 -1。

参数的含义和用法：

- *columns (string,可选)* - 包含要返回的列的 JSON 格式字符串数组。例如："["col1","col2"]"。如果缺失，将执行 "*"（所有列）选择。
- *table (string, 必需)* - 要查询的表名。
- *filter (string, 可选)* - 包含查询"where"过滤器的 JSON 格式字符串。这必须是（列，运算符，值）对的数组。确切 JSON 语法为 "{"column":{"operator":"value"}}"; 运算符可以是 `>`、`<`、`=`、`!=` 或自定义字符串；值可以是字符串、整数或 `null`。为简化与 `=` 运算符的使用，您可以使用 "{"column":"value"}"。如果缺失，将选择所有行。
- *order (string, 可选)* - 要排序的列名（仅升序）。
- *res_col_avps (string, 可选, 不展开)* - 要存储结果的 AVP 名称列表。格式为 "$avp(name1);$avp(name2);..."。如果省略此参数，结果存储在 "$avp(1);$avp(2);..."。如果结果包含多行，则将添加具有相应名称的多个 AVP。AVP 的值类型（字符串或整数）将从列的类型派生。如果数据库中的值为 *NULL*，返回的 avp 将是值为 *<null>* 的字符串。
- *db_id (int, 可选)* - 定义的 DB URL 的引用（数字 id）——请参阅 [db url](#param_db_url) 模块参数。它可以是常量，也可以是字符串/整数变量。

此函数可以从任何类型的路由使用。

```c title="sql_select 使用示例"
...
sql_select('["password","ha1"]', 'subscriber',
	'[ {"username": "$tu"}, {"domain": {"!=", null}}]', ,
	'$avp(pass);$avp(hash)');
...
					
```

#### sql_select_one([columns],table,[filter],[order],[res_col_vars], [db_id])

类似于 [sql select](#func_sql_select)，它执行 SELECT SQL 查询并返回结果，但有以下区别：

- *仅返回一行* - 即使查询结果是多行结果，也只将第一行返回给脚本。
- *返回变量不限于 AVP* - 返回查询结果的变量可以是任何类型的变量，当然只要它是可写的。请注意，返回变量的数量必须与返回列的数量匹配（就数量而言）。如果提供的变量较少，查询将失败。
- *返回 NULL* - 查询产生的任何 DB NULL 值将作为 NULL 指示符推送（而不是 *<null>* 字符串）到脚本变量。

此函数可以从任何类型的路由使用。

```c title="sql_select_one 使用示例"
...
sql_select_one('["value","type"]', 'usr_preferences',
	'[ {"username": "$tu"}, {"attribute": "cfna"}]', ,
	'$var(cf_uri);$var(type)');
# 即使用户有多个 `cfna` 属性，上面的查询也只返回一行
...
					
```

#### sql_update(columns,table,[filter],[db_id])

执行结构化（非原始）SQL UPDATE 操作的函数。重要提示：请参阅 [sql select](#func_sql_select) 函数的所有一般说明。

如果查询成功，函数返回 true。

参数的含义和用法：

- *columns (string,必需)* - 包含要由查询更新的（列，值）对的 JSON 格式字符串数组。例如："[{"col1":"val1"},{"col2":"val1"}]"。
- *table (string, 必需)* - 要查询的表名。
- *filter (string, 可选)* - 包含查询"where"过滤器的 JSON 格式字符串。这必须是（列，运算符，值）对的数组。确切 JSON 语法为 "{"column":{"operator":"value"}}"; 运算符可以是 `>`、`<`、`=`、`!=` 或自定义字符串；值可以是字符串、整数或 `null`。为简化与 `=` 运算符的使用，您可以使用 "{"column":"value"}"。如果缺失，将更新所有行。
- *db_id (int, 可选)* - 定义的 DB URL 的引用（数字 id）——请参阅 [db url](#param_db_url) 模块参数。它可以是常量，也可以是字符串/整数变量。

此函数可以从任何类型的路由使用。

```c title="sql_update 使用示例"
...
sql_update( '[{"password":"my_secret"}]', 'subscriber',
	'[{"username": "$tu"}]');
...
					
```

#### sql_insert(table,columns,[db_id])

执行结构化（非原始）SQL INSERT 操作的函数。重要提示：请参阅 [sql select](#func_sql_select) 函数的所有一般说明。

如果查询成功，函数返回 true。

参数的含义和用法：

- *table (string, 必需)* - 要查询的表名。
- *columns (string,必需)* - 包含要插入的（列，值）对的 JSON 格式字符串数组。例如："[{"col1":"val1"},{"col2":"val1"}]"。
- *db_id (int, 可选)* - 定义的 DB URL 的引用（数字 id）——请参阅 [db url](#param_db_url) 模块参数。它可以是常量，也可以是字符串/整数变量。

此函数可以从任何类型的路由使用。

```c title="sql_insert 使用示例"
...
sql_insert( 'cc_agents', '[{"agentid":"agentX"},{"skills":"info"},{"location":null},{"msrp_location":"sip:agentX@opensips.com"},{"msrp_max_sessions":2}]' );
...
					
```

#### sql_delete(table,[filter],[db_id])

执行结构化（非原始）SQL DELETE 操作的函数。重要提示：请参阅 [sql select](#func_sql_select) 函数的所有一般说明。

如果查询成功，函数返回 true。

参数的含义和用法：

- *table (string, 必需)* - 要从中删除的表。
- *filter (string, 可选)* - 包含查询"where"过滤器的 JSON 格式字符串。这必须是（列，运算符，值）对的数组。确切 JSON 语法为 "{"column":{"operator":"value"}}"; 运算符可以是 `>`、`<`、`=`、`!=` 或自定义字符串；值可以是字符串、整数或 `null`。为简化与 `=` 运算符的使用，您可以使用 "{"column":"value"}"。如果缺失，将更新所有行。
- *db_id (int, 可选)* - 定义的 DB URL 的引用（数字 id）——请参阅 [db url](#param_db_url) 模块参数。它可以是常量，也可以是字符串/整数变量。

此函数可以从任何类型的路由使用。

```c title="sql_delete 使用示例"
...
sql_delete( 'subscriber', '[{"username": "$tu"}]');
...
					
```

#### sql_replace(table,columns,[db_id])

非常类似于 [sql insert](#func_sql_insert) 函数，但执行 SQL REPLACE 操作而不是 INSERT。请注意，OpenSIPS 中并非所有 SQL 后端都支持 REPLACE 操作。

如果查询成功，函数返回 true。

#### sql_avp_load(source, name, [db_id], [prefix]])

从 DB 加载与给定 *source* 对应的 AVP 到内存中。如果给定，它会设置加载的 AVP 的脚本标志。如果在 AVP 中加载了一些值则返回 true，否则返回 false（db 错误、没有加载 avp ...）。

AVP 前面可以带有可选的 *prefix*，以避免一些冲突。

参数的含义如下：

- *source (string, 不展开)* - 用于识别 AVP 的信息。参数语法：

  *source = (pvar|str_value)
  ['/'('username'|'domain'|'uri'|'uuid')])*
  *pvar = OpenSIPS 中定义的任何伪变量。如果 pvar 是 $ru（请求 URI）、$fu（来自 URI）、$tu（到 URI）或 $ou（原始 URI），则隐式标志为 'uri'。否则，隐式标志为 'uuid'。*
- *name (string, 不展开)* - 将从 DB 加载到内存的 AVP。参数语法为：

  *name = avp_spec['/'(table_name|'$'db_scheme)]*
- *db_id (int, 可选)* - 定义的 DB URL 的引用（数字 id）——请参阅 "db_url" 模块参数。
- *prefix (string, 可选)* - 静态字符串，将在此函数填充的 AVP 名称之前。

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE 和 ONREPLY_ROUTE 使用。

```c title="sql_avp_load 使用示例"
...
sql_avp_load("$fu", "$avp(678)");
sql_avp_load("$ru/domain", "i/domain_preferences");
sql_avp_load("$avp(uuid)", "$avp(404fwd)/fwd_table");
sql_avp_load("$ru", "$avp(123)/$some_scheme");

# 使用 DB URL id 3
sql_avp_load("$ru", "$avp(1)", 3);

# 在所有加载的 AVP 前面加 "caller_" 前缀
sql_avp_load("$ru", "$avp(100)", , "caller_");
xlog("Loaded: $avp(caller_100)\n");

...
					
```

#### sql_avp_store(source, name, [db_id])

将 AVP 存储到与给定 *source* 对应的 DB 中。

参数的含义和用法与 *sql_avp_load(source, name)* 函数相同。请参阅其描述。

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE 和 ONREPLY_ROUTE 使用。

```c title="sql_avp_store 使用示例"
...
sql_avp_store("$tu", "$avp(678)");
sql_avp_store("$ru/username", "$avp(email)");
# 使用 DB URL id 3
sql_avp_store("$ru", "$avp(1)", 3);
...
					
```

#### sql_avp_delete(source, name, [db_id])

从 DB 删除与给定 *source* 对应的 AVP。

参数的含义和用法与 *sql_avp_load(source, name)* 函数相同。请参阅其描述。

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE 和 ONREPLY_ROUTE 使用。

```c title="sql_avp_delete 使用示例"
...
sql_avp_delete("$tu", "$avp(678)");
sql_avp_delete("$ru/username", "$avp(email)");
sql_avp_delete("$avp(uuid)", "$avp(404fwd)/fwd_table");
# 使用 DB URL id 3
sql_avp_delete("$ru", "$avp(1)", 3);
...
					
```

### 导出的异步函数

#### sql_query(query, [dest], [db_id])

此函数采用相同的参数并表现得与 [sql query](#func_sql_query) 完全相同，但以异步方式执行（在启动查询后，当前 SIP worker 暂停当前 SIP 消息的执行，直到结果可用并尝试处理更多 SIP 流量）。

此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE 和 ONREPLY_ROUTE 使用。

```c title="异步 sql_query 使用示例"
...
{
...
/* 慢 MySQL 查询示例 - 大约需要 5 秒 */
async(
	sql_query(
		"SELECT table_name, table_version, SLEEP(0.1) from version",
		"$avp(tb_name); $avp(tb_ver); $avp(retcode)"),
	my_resume_route);
/* 异步() 调用后脚本执行停止 */
}

/* 当数据就绪时我们将调用 - 同时 worker 是空闲的 */
route [my_resume_route]
{
	xlog("Results: \n$(avp(tb_name)[*])\n
-------------------\n$(avp(tb_ver)[*])\n
-------------------\n$(avp(retcode)[*])\n");
}
...
					
```

#### sql_query_one(query, [dest], [db_id])

此函数采用相同的参数并表现得与 [sql query one](#func_sql_query_one) 完全相同，但以异步方式执行（在启动查询后，当前 SIP worker 暂停当前 SIP 消息的执行，直到结果可用并尝试处理更多 SIP 流量）。

此函数可以从任何路由使用。

```c title="异步 sql_query_one 使用示例"
...
{
...
/* 慢 MySQL 查询示例 - 大约需要 5 秒 */
async(
	sql_query_one(
		"SELECT table_name, table_version, SLEEP(0.1) from version",
		"$var(tb_name); $var(tb_ver); $var(retcode)"),
	my_resume_route);
/* 异步() 调用后脚本执行停止 */
}

/* 当数据就绪时我们将调用 - 同时 worker 是空闲的 */
route [my_resume_route]
{
	xlog("Result: $var(tb_name) | $var(tb_ver) | $(var(retcode)\n");
}
...
					
```

<!-- 贡献者 -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
