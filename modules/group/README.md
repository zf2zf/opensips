---
title: "group 模块"
description: "本模块提供多种用户组成员资格检查功能。"
---

## 管理指南


### 概述


本模块提供多种用户组成员资格检查功能。


#### 严格成员资格检查


数据库表中包含用户及其所属组的列表。该模块提供检查特定用户是否属于特定组的功能。


不支持数据库缓存，每次检查都需要执行数据库查询。


#### 基于正则表达式的检查


另一个数据库表包含正则表达式和组ID的列表。当用户URI匹配正则表达式时进行匹配。这种匹配类型可用于获取用户所属的组ID（通过正则表达式匹配）。


由于性能原因（正则表达式评估），支持数据库缓存：表内容在启动时加载到内存中，所有正则表达式都会被编译。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- 数据库模块，如 mysql、postgres 或 dbtext。
- AAA 模块，如 radius 或 diameter。


#### 外部库或应用程序


运行 OpenSIPS 加载此模块前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### db_url (string)


要使用的数据库表的 URL。


```c title="设置 db_url 参数"
...
modparam("group", "db_url", "mysql://username:password@dbhost/opensips")
...
```


#### table (string)


保存组成员严格定义的表名。


*默认值为 "grp"。*


```c title="设置 table 参数"
...
modparam("group", "table", "grp_table")
...
```


#### user_column (string)


保存用户名的"表"列名。


*默认值为 "username"。*


```c title="设置 user_column 参数"
...
modparam("group", "user_column", "user")
...
```


#### domain_column (string)


保存域名的"表"列名。


*默认值为 "domain"。*


```c title="设置 domain_column 参数"
...
modparam("group", "domain_column", "realm")
...
```


#### group_column (string)


保存组的"表"列名。


*默认值为 "grp"。*


```c title="设置 group_column 参数"
...
modparam("group", "group_column", "grp")
...
```


#### use_domain (boolean)


如果启用，URI 的域名部分也将用于查找，以进行更严格的组匹配。否则，仅使用用户名部分。


*默认值为 *true*（启用）。*


```c title="设置 use_domain 参数"
...
modparam("group", "use_domain", 1)
...
```


#### re_table (string)


保存基于正则表达式的组定义的表名。如果未定义表，则正则表达式支持被禁用。


*默认值为 "NULL"。*


```c title="设置 re_table 参数"
...
modparam("group", "re_table", "re_grp")
...
```


#### re_exp_column (string)


"re_table" 中保存用于用户匹配的正则表达式的列名。


*默认值为 "reg_exp"。*


```c title="设置 re_exp_column 参数"
...
modparam("group", "re_exp_column", "re")
...
```


#### re_gid_column (string)


"re_table" 中保存组ID的列名。


*默认值为 "group_id"。*


```c title="设置 re_gid_column 参数"
...
modparam("group", "re_gid_column", "grp_id")
...
```


#### multiple_gid (integer)


如果启用（非零值），正则表达式匹配将返回所有匹配的用户组ID；否则仅返回第一个。


*默认值为 "1"。*


```c title="设置 multiple_gid 参数"
...
modparam("group", "multiple_gid", 0)
...
```


#### aaa_url (string)


这是表示所使用的 AAA 协议及其配置文件位置的 URL。


```c title="设置 aaa_url 参数"
...
modparam("group", "aaa_url", "radius:/etc/radiusclient-ng/radiusclient.conf")
...
```


### 导出的函数


#### db_is_user_in(uri, group)


此函数用于脚本中的组成员资格检查。如果给定 URI 中的用户名是给定组的成员则返回 true，否则返回 false。


参数含义如下：


- *uri (string)* - SIP URI，其
				用户名和可选域名用于检查。可选值：
			
					
				"Request-URI" - 使用 Request-URI 的用户名和
				（可选）域名。
					
					
				"To" - 使用 To 用户名和（可选）域名。
					
					
				"From" - 使用 From 用户名和（可选）域名。
					
					
				"Credentials" - 使用 digest 凭证用户名。
					
					
				（默认）- 将给定输入解析为 SIP URI
- *group (string)* - 要检查的组


此函数可以从 REQUEST_ROUTE 和 FAILURE_ROUTE 使用。


```c title="db_is_user_in 使用示例"
...
if (db_is_user_in("Request-URI", "ld")) {
	...
}
...
$avp(grouptocheck)="offline";

if (db_is_user_in("Credentials", $avp(grouptocheck))) {
	...
}
...
```


#### db_get_user_group(uri, output_avp)


此函数用于基于正则表达式的组成员资格检查，使用数据库支持。如果给定"uri"中的用户名属于至少一个组，则返回 true。


所有匹配的组ID
		将在"output_avp"中返回（如果启用了 [multiple gid](#param_multiple_gid)），
		否则仅返回第一个匹配的（记录按 RDBMS 返回结果的逆序尝试）。


参数含义如下：


- *uri (string)* - 要与正则表达式匹配的 SIP URI
				
				
				"Request-URI" - 使用 Request-URI
				
				
				"To" - 使用 To URI。
				
				
				"From" - 使用 From URI
				
				
				"Credentials" - 使用 digest 凭证用户名和域。
				
				
				（默认）- 将给定输入解析为 SIP URI
- *output_avp (var)* - 匹配的组 ID 列表


此函数可以从 REQUEST_ROUTE 和 FAILURE_ROUTE 使用。


```c title="db_get_user_group 使用示例"
...
if (db_get_user_group("Request-URI", $avp(10))) {
    xdbg("User $ru belongs to the following groups: $(avp(10)[*])\n");
    ....
};
...
```


#### aaa_is_user_in(uri, group)


此函数使用 AAA 支持检查组成员资格。如果给定"uri"中的用户名是给定组的成员则返回 true，否则返回 false。


参数含义如下：


- *uri (string)* - SIP URI，其
				用户名和可选域名用于检查，可选值包括：
			
					
				"Request-URI" - 使用 Request-URI 的用户名和
				（可选）域名。
					
					
				"To" - 使用 To 用户名和（可选）域名。
					
					
				"From" - 使用 From 用户名和（可选）域名。
					
					
				"Credentials" - 使用 digest 凭证用户名。
- *group (string)* - 要检查的组名称。


此函数可以从 REQUEST_ROUTE 使用。


```c title="aaa_is_user_in 使用示例"
...
if (aaa_is_user_in("Request-URI", "ld")) {
	...
};
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用 Creative Common License 4.0 许可证。
