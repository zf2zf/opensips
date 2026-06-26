---
title: "DB_HTTP 模块"
description: "该模块提供对实现为 HTTP 服务器的数据库的访问。当穿越防火墙成为问题或需要数据加密时，可使用此模块。"
---

## 管理指南


### 概述


该模块提供对实现为 HTTP 服务器的数据库的访问。
当穿越防火墙成为问题或需要数据加密时，可使用此模块。


要使用此模块，您必须有一台可以通过 HTTP 或 HTTPS
与此模块通信的服务器，该服务器完全按照规格说明部分描述的格式运行。


该模块可以提供 SSL、身份验证和 opensips 数据库的所有功能，
只要服务器支持（除了 result_fetch）。


db_http 的 URL 与其他 db 模块的 URL 有一点不同。
URL 不必包含数据库名称。相反，
地址之后的所有内容都被视为指向 db 资源的路径，
它可能缺失。


即使使用 HTTPS，URL 也必须以 "http://" 开头，
模块的 SSL 参数必须设置为 1。


```c title="为模块设置 db_url"
...
modparam("presence", "db_url","http://user:pass@localhost:13100")
or
modparam("presence", "db_url","http://user:pass@www.some.com/some/some")
...
```


### 依赖


#### OpenSIPS 模块


该模块不依赖其他模块。


#### 外部库或应用程序


- *libcurl*。


### 导出的参数


#### SSL(int)


是否使用 SSL。


如果值为 1，模块将使用 https，否则
将使用 http。


*默认值为 "0"。*


```c title="设置 SSL 参数"
...
modparam("db_http", "SSL",1)
...
```


#### cap_raw_query(int)


服务器是否支持原始查询。


*默认值为 "0"。*


```c title="设置 cap_raw_query 参数"
...
modparam("db_http", "cap_raw_query", 1)
...
```


#### cap_replace(int)


服务器是否支持替换功能。


*默认值为 "0"。*


```c title="设置 cap_replace 参数"
...
modparam("db_http", "cap_replace", 1)
...
```


#### cap_insert_update(int)


服务器是否支持 insert_update 功能。


*默认值为 "0"。*


```c title="设置 cap_insert_update 参数"
...
modparam("db_http", "cap_insert_update", 1)
...
```


#### cap_last_inserted_id(int)


服务器是否支持 last_inserted_id 功能。


*默认值为 "0"。*


```c title="设置 cap_last_inserted_id 参数"
...
modparam("db_http", "cap_last_inserted_id", 1)
...
```


#### field_delimiter (str)


用于分隔回复中字段的字符。只
可以设置一个字符。


*默认值为 ";"*


```c title="设置 field_delimiter 参数"
...
modparam("db_http", "field_delimiter",";")
...
```


#### row_delimiter (str)


用于分隔回复中行的字符。只
可以设置一个字符。


*默认值为 "\n"*


```c title="设置 row_delimiter 参数"
...
modparam("db_http", "row_delimiter","\n")
...
```


#### quote_delimiter (str)


用于引用回复中需要引用的
字段的字符。只可以设置一个字符。


*默认值为 "|"*


```c title="设置 quote_delimiter 参数"
...
modparam("db_http", "quote_delimiter","|")
...
```


#### value_delimiter (str)


用于分隔单个
变量的多个字段的分隔符（请参阅[http 变量](#variables)）。
只可以设置一个字符。


*默认值为 ","*


```c title="设置 value_delimiter 参数"
...
modparam("db_http", "value_delimiter",";")
...
```


#### timeout (int)


HTTP 操作允许的最大毫秒数


*默认值为 "30000（30 秒）"*


```c title="设置 timeout 参数"
...
modparam("db_http", "timeout",5000)
...
```


#### disable_expect (int)


对超过 1024 字节的请求禁用 libcurl 中的自动 'Expect: 100-continue' 行为。
这可以通过为大记录节省一次网络往返来帮助减少延迟。
有关此行为的更多信息，请参阅 rfc2616 第 8.2.3 节。


*默认值为 "0（关闭）"*


```c title="设置 disable_expect 参数"
...
modparam("db_http", "disable_expect",1)
...
```


### 导出的函数


### 服务器规格


#### 查询


服务器必须接受 HTTP 查询格式的查询。


查询有两种类型：GET 和 POST。两者
都设置必须由服务器解释的变量。
所有值都是 URL 编码的。


有几种类型的查询，服务器可以通过 query_type 变量来区分它们。
每种类型的查询使用与 opensips db_api 中类似的特定变量。


```c title="查询示例"
...
GET /presentity/?c=username,domain,event,expires HTTP/1.1
...
```


#### 变量


所有变量的描述。每个变量可以
有单个值或逗号分隔的列表。每个
变量都有特殊含义，只能与某些
查询一起使用。


将在其上执行操作的表将编码在
url 的末尾（www.some.com/users 将指向
users 表）。


- k=
描述将用于比较的键（列）。可以有多个值。
- op=
描述将用于比较的运算符。可以有多个值。
- v=
描述列将被比较的值。可以有多个值。
- c=
描述将从结果中选择的列。可以有多个值。
- o=
结果将按其排序的列。只有一个值。
- uk=
将更新的键（列）。可以有多个值。
- uv=
将放入列中的新值。可以有多个值。
- q=
描述原始查询。仅在服务器支持原始查询时使用。只有一个值。
- query_type=
描述当前查询的类型。可以有单个值，如查询部分所述。
除 "SELECT"（正常查询）外，所有查询中都存在。


```c title="带变量的查询示例"
...
GET /presentity/?c=username,domain,event,expires HTTP/1.1
GET /version/?k=table_name&v=xcap&c=table_version HTTP/1.1 
...
...
POST /active_watchers HTTP/1.1

k=id&v=100&query_type=insert
...
```


#### 查询类型


查询的类型由 query_type 变量描述。
变量的值将设置为查询的确切名称。


"SELECT" 的查询使用 GET，其余使用 POST
（insert、update、delete、replace、insert_update）。


- normal query
使用 k、op、v、c 和 o 变量。这不会设置 query_type 变量，
将使用 GET。
- delete
使用 k、op 和 v 变量。
- insert
使用 k 和 v 变量。
- update
使用 k、op、v、uk 和 uv 变量。
- replace
使用 k 和 v 变量。这是一种可选的查询类型。
如果模块未配置为使用它，则不会使用。
- insert_update
使用 k 和 v 变量。这是一种可选的查询类型。
如果模块未配置为使用它，则不会使用。
- custom
使用 q 变量。这是一种可选的查询类型。
如果模块未配置为使用它，则不会使用。


```c title="更多查询示例"
...
POST /active_watchers HTTP/1.1

k=id&op=%3D&v=100&query_type=delete
...

...
POST /active_watchers HTTP/1.1

k=id&op=%3D&v=100&uk=id&uv=101&query_type=update
...
```


#### 查询中的 NULL 值


查询中的 NULL 值表示为长度为 1 的字符串，
其中包含一个值为 '\0' 的字符。


```c title="NULL 查询示例"
...
POST /active_watchers HTTP/1.1

k=id&op=%3D&v=%00&query_type=delete
...
```


#### 服务器回复


如果查询正常（即使答案为空），
服务器必须回复 200 OK HTTP 回复，
其主体包含列的类型和值。


服务器必须回复由分隔符分隔的值和列的列表。


列表中的每个元素必须与前一个元素用
字段分隔符分隔，该分隔符必须与脚本为模块设置的参数相同。
每一行的最后一个元素后面不能跟字段分隔符，
而是要跟行分隔符。


回复的第一行必须包含每个列的值类型列表。类型可以是以下任意一种：
integer、string、str、blob、date。


接下来的每一行都包含结果中每一行的值。


如果查询产生错误，服务器必须回复
HTTP 500 回复，或相应的错误代码（404、401）。


```c title="回复示例"
...
int;string;blob
6;something=something;1000
100;mine;10002030
...
```


#### 回复引用


由于值内部可能包含分隔符，
服务器必须在必要时执行引用（必要时执行引用是没有问题的）。


必须定义引用分隔符，并且必须与
脚本设置的相同（默认为 "|"）。


如果值包含字段、行或引用分隔符，
则必须将其放在引号内。值内部的引用分隔符
必须在前面加上另一个引用分隔符。


```c title="引用示例"
...
int;string;blob
6;|ana;maria|;1000
100;mine;10002030
3;mine;|some||more;|
...
```


#### 最后插入的 ID


这是一个可选功能，如果您想使用它，可以启用它。


为了使用此功能，服务器必须在每个插入查询的 200 回复中放置最后插入的 ID。


#### 身份验证和 SSL


如果服务器支持身份验证和 SSL，可以
启用模块使用 SSL。身份验证将在需要时始终使用。


模块将尝试使用服务器提供的最安全身份验证类型：
Basic、Digest、GSSNEGOTIATE 和 NTLM。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0
