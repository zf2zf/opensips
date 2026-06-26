---
title: "Auth_db 模块"
description: "此模块包含所有需要访问数据库的认证相关函数。此模块应与 auth 模块一起使用，不能独立使用，因为它依赖于该模块。如果要使用数据库存储认证信息（如订户用户名和密码），请选择此模块。"
---

## 管理指南


### 概述


此模块包含所有需要访问数据库的认证相关函数。
		此模块应与 auth 模块一起使用，不能独立使用，因为它依赖于该模块。
        如果要使用数据库存储认证信息（如订户用户名和密码），请选择此模块。
        如果要使用 radius 认证，请改用 auth_radius。


#### RFC 8760 支持（增强型认证）


从 OpenSIPS 3.2 开始，[auth](../auth)、
			[auth_db](../auth_db) 和
			[uac_auth](../uac_auth)
			模块支持两种新的摘要认证算法
			（"SHA-256" 和 "SHA-512-256"），符合
	        [RFC 8760](https://datatracker.ietf.org/doc/html/rfc8760)
	        规范。


### 依赖


#### OpenSIPS 模块


该模块依赖以下模块（换句话说，
			列出的模块必须在此模块之前加载）：


- *auth* -- 通用认证函数
- *database* -- 任何数据库模块
				（当前为 mysql、postgres、dbtext）


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前必须安装
			以下库或应用程序：


- *无*


### 导出的参数


#### db_url (字符串)


这是要使用的数据库的 URL。参数的值取决于所使用的数据库模块。
		例如，对于 mysql 和 postgres 模块，这类似于 mysql://username:password@host:port/database。
		对于 dbtext 模块（以纯文本文件存储数据），这是数据库所在的目录。


*默认值为 "mysql://opensipsro:opensipsro@localhost/opensips"。*


```c title="db_url 参数使用"
modparam("auth_db", "db_url", "dbdriver://username:password@dbhost/dbname")
```


#### calculate_ha1 (整数)


此参数告诉服务器应将加载的密码（用于认证）视为明文密码还是
		预计算的 HA1 字符串。


此参数的可能含义如下：


- *1（计算 HA1）* - 加载的密码是明文密码，
			因此 OpenSIPS 将在内部计算 HA1。
            由于密码将从 [password column](#param_password_column) 参数指定的列加载，
            请确保此参数指向包含明文密码的列
           （默认情况下，此参数指向 "ha1" 列）；
- *0（不计算 HA1）* - 加载的密码是预计算的
			HA1 哈希（无需计算）。
            模块将加载存储在 [password column](#param_password_column)、
            [hash column sha256](#param_hash_column_sha256) 和
            [hash column sha512t256](#param_hash_column_sha512t256) 列中的所有哈希，
            然后使用与给定摘要认证挑战所选哈希算法对应的哈希。
哈希列的内容可按如下方式生成：
				
			password_column: MD5(username:realm:password)
			hash_column_sha256: SHA-256(username:realm:password)
			hash_column_sha512t256: SHA-512-256(username:realm:password)


此参数的默认值为
			*0（使用哈希密码）*。


```c title="calculate_ha1 参数使用"
modparam("auth_db", "calculate_ha1", 1)
```


#### use_domain (布尔值)


如果为 true（非 0），则在查找订户表时也将使用域名。
		如果有多个域设置，强烈建议保持此参数启用，以避免域之间的用户名重叠。


默认值为 *true*（已启用）。


```c title="use_domain 参数使用"
modparam("auth_db", "use_domain", true)
			
```


#### load_credentials (字符串)


此参数指定执行认证时要从数据库获取的凭据。
		加载的凭据将存储在 AVP 中。
        如果未特别给出 AVP 名称，将使用与列名相同的名称 AVP。


参数语法：


- *load_credentials = credential (';' credential)**
- *credential = (avp_specification '=' column_name) |
							(column_name)*
- *avp_specification = '$avp(' + NAME + ')'*


此参数的默认值为空 / """" 列表。


```c title="load_credentials 参数使用"
# 将 rpid 列加载到 $avp(13)，将 email_address 列加载到
# $avp(email_address)
modparam("auth_db", "load_credentials", "$avp(13)=rpid;email_address")
```


#### skip_version_check (整数)


此参数指定不检查 auth 表版本。
		当使用自定义认证表时应设置此参数。


默认值为 "0（false）"。


```c title="skip_version_check 参数使用"
modparam("auth_db", "skip_version_check", 1)
			
```


#### user_column (字符串)


这是 "SUBSCRIBER" 类表中保存用户名的列名。
		默认值对大多数人都应该没问题。
		只有在真正需要更改时才使用此参数。


默认值为 "username"。


```c title="user_column 参数使用"
modparam("auth_db", "user_column", "user")
```


#### domain_column (字符串)


这是 "SUBSCRIBER" 类表中保存用户域的列名。
		默认值对大多数人都应该没问题。
		只有在真正需要时才使用此参数。


默认值为 "domain"。


```c title="domain_column 参数使用"
modparam("auth_db", "domain_column", "domain")
```


#### password_column (字符串)


这是 "subscriber" 类表中保存 MD5 HA1 哈希字符串或明文密码的列名。
        MD5 HA1 哈希是用户名、密码和 realm 的 MD5 哈希。
        在 DB 中存储哈希（而不是直接存储密码）更加安全，
        因为服务器不需要知道明文密码，而且攻击者从 HA1 字符串
        反向获取密码在计算上是不可行的。


默认值为 "ha1"。


```c title="password_column 参数使用"
modparam("auth_db", "password_column", "password")
```


#### hash_column_sha256 (字符串)


保存 SHA-256 HA1 哈希的列名
		（[RFC 8760](https://datatracker.ietf.org/doc/html/rfc8760) 支持）。


默认值为 "ha1_sha256"。


```c title="password_column 参数使用"
modparam("auth_db", "hash_column_sha256", "ha1_sha256")
```


#### hash_column_sha512t256 (字符串)


保存 SHA-512/256 HA1 哈希的列名。
		（[RFC 8760](https://datatracker.ietf.org/doc/html/rfc8760) 支持）。


默认值为 "ha1_sha512t256"。


```c title="password_column 参数使用"
modparam("auth_db", "hash_column_sha512t256", "ha1_sha512t256")
```


#### uri_user_column (字符串)


保存 "URI" 类表中用户名的列。


*默认值为 "username"。*


```c title="设置 uri_user_column 参数"
...
modparam("auth_db", "uri_user_column", "username")
...
```


#### uri_domain_column (字符串)


保存 "URI" 类表中域的列。


*默认值为 "domain"。*


```c title="设置 uri_domain_column 参数"
...
modparam("auth_db", "uri_domain_column", "domain")
...
```


#### uri_uriuser_column (字符串)


保存 "URI" 类表中 URI 用户名的列。


*默认值为 "uri_user"。*


```c title="设置 uriuser_column 参数"
...
modparam("auth_db", "uri_uriuser_column", "uri_user")
...
```


### 导出的函数


#### www_authorize(realm, table)


此函数根据 RFC2617
		（[RFC2617](http://www.ietf.org/rfc/rfc2617.txt)）中的摘要认证，
        针对 "SUBSCRIBER" 类表验证收到的凭据。
        如果凭据验证成功，则函数将成功并将凭据标记为已授权
        （标记的凭据可供其他函数稍后使用）。
        如果函数由于某种原因无法验证凭据，则它将失败，
        脚本应调用 `www_challenge` 再次向用户发起挑战。


负返回码的解释如下：


- *-5（通用错误）* - 发生某些通用错误，未发送回复；
- *-4（无凭据）* - 在请求中未找到凭据；
- *-3（过期 nonce）* - nonce 已过期；
- *-2（密码无效）* - 用户有效，但密码错误；
- *-1（用户无效）* - 认证用户不存在。


参数的含义如下：


- *realm (字符串)* - Realm 是一个不透明字符串，
			用户代理应向用户展示，以便用户决定使用什么
			用户名和密码。通常这是服务器运行所在的主机域名。
如果使用空字符串 ""，则服务器将从请求中生成它。
            对于 REGISTER 请求的 To 头域，将使用该头域中的域名
            （因为此头域代表正在注册的用户），
            对于所有其他消息，将使用 From 头域中的域名。
该字符串可以包含伪变量。
- *table (字符串)* - 用于查找用户名和密码的表（通常为 subscribers 表）。


此函数可用于 REQUEST_ROUTE。


```c title="www_authorize 使用"
...
if (!www_authorize("siphub.net", "subscriber"))
	www_challenge("siphub.net", "auth");
...
```


#### proxy_authorize(realm, table)


此函数根据 RFC2617
		（[RFC2617](http://www.ietf.org/rfc/rfc2617.txt)）中的摘要认证，
        针对 "SUBSCRIBER" 类表验证收到的凭据。
        如果凭据验证成功，则函数将成功并将凭据标记为已授权
        （标记的凭据可供其他函数稍后使用）。
        如果函数由于某种原因无法验证凭据，则它将失败，
        脚本应调用 `proxy_challenge` 再次向用户发起挑战。


负返回码的解释如下：


- *-5（通用错误）* - 发生某些通用错误，未发送回复；
- *-4（无凭据）* - 在请求中未找到凭据；
- *-3（过期 nonce）* - nonce 已过期；
- *-2（密码无效）* - 用户有效，但密码错误；
- *-1（用户无效）* - 认证用户不存在。


参数的含义如下：


- *realm (字符串)* - Realm 是一个不透明字符串，
			用户代理应向用户展示，以便用户决定使用什么
			用户名和密码。通常这是服务器运行所在的主机域名。
如果使用空字符串 ""，则服务器将从请求中生成它。
            From 头域的域名将被用作 realm。
该字符串可以包含伪变量。
- *table (字符串)* - 用于查找用户名和密码的表（通常为 subscribers 表）。


此函数可用于 REQUEST_ROUTE。


```c title="proxy_authorize 使用"
...
if (!proxy_authorize("", "subscriber"))
	proxy_challenge("", "auth");  # Realm 将自动生成
...
```


#### db_is_to_authorized(table)


此函数针对 "URI" 类表进行检查，
        以查看从 To 头域 URI 中提取的用户名是否允许/授权使用
        通过 [www authorize](#func_www_authorize) 验证的凭据（认证用户名）。


此函数是允许创建 SIP 用户（来自 FROM/TO 头域）
        与他们使用的认证用户（来自 SUBSCRIBER 类表）之间映射的机制的一部分。
        映射存储在 URI 类表中。


参数的含义如下：


- *table (字符串)* - 用于查找 URI/AUTH 映射的表（通常为 URI 表）。


此函数可用于 REQUEST_ROUTE。


```c title="db_is_to_authorized 使用"
...
if (!db_is_to_authorized("uri")) {
	xlog("用户 $tu 未被授权使用 $au 凭据进行认证\n");
}
...
```


#### db_is_from_authorized(table)


类似于 [db is to authorized](#func_db_is_to_authorized)，
        但不是检查 TO 头域 URI，而是检查 FROM 头域 URI。


#### db_does_uri_exist(uri, table)


检查给定 URI 的 username@domain 是否是 "SUBSCRIBER" 类表中的现有用户。


参数的含义如下：


- *uri (字符串)* - 要测试的 SIP URI。
            它必须包含用户名部分才能进行有效检查。允许使用变量。
- *table (字符串)* - 用于搜索 URI 的表（通常为 SUBSCRIBER 表）。


此函数可用于 REQUEST_ROUTE。


```c title="db_does_uri_exist 使用"
...
if (db_does_uri_exist($ru, "subscriber")) {
	...
}
...
```


#### db_get_auth_id(table, uri, auth, realm)


针对 "URI" 类表检查给定 uri 字符串的用户名。
        如果用户存在于数据库中则返回 true，
        并将给定变量设置为与给定 uri 对应的认证 id 和 realm。


参数的含义如下：


- *table (字符串)* - 用于搜索 URI 的表（通常为 URI 表）。
- *uri (字符串)* - 要测试的输入 SIP URI。
            它必须包含用户名部分才能进行有效检查。允许使用变量。
- *auth (var)* - 用于存储与给定 SIP URI 匹配的
			找到的认证 id 的输出变量。
- *realm (var)* - 用于存储与给定 SIP URI 匹配的
			找到的认证 realm 的输出变量。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE 和
		LOCAL_ROUTE。


```c title="db_get_auth_id 使用"
...
if (db_get_auth_id("uri", $ru, $avp(auth_id), $avp(auth_realm))) {
	...
}
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
