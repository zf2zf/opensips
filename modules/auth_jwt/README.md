---
title: "AUTH_JWT 模块"
description: "该模块实现基于 JSON Web Tokens 的认证。在某些情况下（即 WebRTC），用户在另一层（而不是 SIP）进行认证，因此在 SIP 层重复认证没有意义。"
---

## 管理指南


### 概述


该模块实现基于 JSON Web Tokens 的认证。
		在某些情况下（即 WebRTC），用户在另一层（而不是 SIP）进行认证，
        因此在 SIP 层重复认证没有意义。
        因此，SIP 客户端将简单地向 OpenSIPS 呈现其从服务器收到的 JWT 认证令牌，
        OpenSIPS 将使用它进行认证目的。

		它依赖于两个数据库表：一个包含 JWT 配置文件（配置文件名及其关联的 SIP 用户名），
        另一个包含 JWT 密钥。每个密钥都有对应的配置文件，
        用于签名 JWT 的密钥以及两个描述验证间隔的时间戳。
        多个 JWT 密钥可以指向同一个 JWT 配置文件。


### 依赖


#### OpenSIPS 模块


该模块依赖以下模块（换句话说，
			列出的模块必须在此模块之前加载）：


- *database* -- 任何数据库模块
				（当前为 mysql、postgres、dbtext），如果设置了 db_url 参数


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前必须安装
			以下库或应用程序：


- *libjwt-dev*
- *openssl-dev* 或
					*libssl-dev*


### 导出的参数


#### db_mode (整数)


如果设置为 0，模块将不会连接到数据库来读取用于解码 JWT 的密钥——
		此时只有 jwt_script_authorize 可从脚本使用。


*默认值为 "0"。*


```c title="db_mode 参数使用"
modparam("auth_jwt", "db_mode", 0)
```


#### db_url (字符串)


这是要使用的数据库的 URL。参数的值取决于所使用的数据库模块。
		例如，对于 mysql 和 postgres 模块，这类似于 mysql://username:password@host:port/database。
		对于 dbtext 模块（以纯文本文件存储数据），这是数据库所在的目录。


*默认值为 "mysql://opensipsro:opensipsro@localhost/opensips"。*


```c title="db_url 参数使用"
modparam("auth_jwt", "db_url", "dbdriver://username:password@dbhost/dbname")
```


#### profiles_table (字符串)


包含 jwt 配置文件的数据库表名


此参数的默认值为 jwt_profiles。


```c title="profiles_table 参数使用"
modparam("auth_jwt", "profiles_table", "my_profiles")
```


#### secrets_table (字符串)


包含 jwt 密钥的数据库表名


此参数的默认值为 jwt_secrets。


```c title="secrets_table 参数使用"
modparam("auth_jwt", "secrets_table", "my_secrets")
```


#### tag_column (字符串)


保存 JWT 配置文件标签的列。


*默认值为 "tag"。*


```c title="设置 tag_column 参数"
...
modparam("auth_jwt", "tag_column", "my_tag_column")
...
```


#### username_column (字符串)


保存 JWT 配置文件关联的 SIP 用户名的列。


*默认值为 "sip_username"。*


```c title="设置 username_column 参数"
...
modparam("auth_jwt", "username_column", "my_username_column")
...
```


#### secret_tag_column (字符串)


保存 JWT 密钥关联标签的列。


*默认值为 "corresponding_tag"。*


```c title="设置 secret_tag_column 参数"
...
modparam("auth_jwt", "secret_tag_column", "my_secret_tag_column")
...
```


#### secret_column (字符串)


保存实际 jwt 签名密钥的列。


*默认值为 "secret"。*


```c title="设置 secret_column 参数"
...
modparam("auth_jwt", "secret_column", "my_secret_column")
...
```


#### start_ts_column (字符串)


保存 JWT 密钥开始 UNIX 时间戳的列。


*默认值为 "start_ts"。*


```c title="设置 start_ts 参数"
...
modparam("auth_jwt", "start_ts", "my_start_ts_column")
...
```


#### end_ts_column (字符串)


保存 jwt 密钥结束 unix 时间戳的列。


*默认值为 "end_ts"。*


```c title="设置 end_ts 参数"
...
modparam("auth_jwt", "end_ts", "my_end_ts_column")
...
```


#### tag_claim (字符串)


用于识别 JWT 配置文件的 JWT 声明


*默认值为 "tag"。*


```c title="设置 tag_claim 参数"
...
modparam("auth_jwt", "tag_claim", "my_tag_claim")
...
```


#### load_credentials (字符串)


此参数指定执行认证时要从 JWT 配置文件表获取的凭据。
		加载的凭据将存储在 AVP 中。
        如果未特别给出 AVP 名称，将使用与列名相同的名称 AVP。


参数语法：


- *load_credentials = credential (';' credential)**
- *credential = (avp_specification '=' column_name) |
							(column_name)*
- *avp_specification = '$avp(' + NAME + ')'*


此参数的默认值为 "none（空）"。


```c title="load_credentials 参数使用"
# 将 my_extra_column 加载到 $avp(extra_jwt_info)
modparam("auth_jwt", "load_credentials", "$avp(extra_jwt_info)=my_extra_column")
```


### 导出的函数


#### jwt_db_authorize(jwt_token,out_decoded_token,out_sip_username)


此函数将读取第一个参数（jwt_token），
		提取标签声明，然后尝试针对相应配置文件标签的数据库密钥对其进行认证。
        成功时，它会用解码后的 JWT（纯文本格式 header_json.payload_json）
        填充 out_decoded_token pvar，
        并用与该 JWT 配置文件对应的 SIP 用户名填充 out_sip_username。


负返回码的解释如下：


- *-1（错误）* - JWT 认证失败


参数的含义如下：


- *jwt_token (字符串)* - 要进行认证的 JWT 令牌
该字符串可以包含伪变量。
- *out_decoded_token (pvar)* - 用于在成功认证后存储解码 JWT 的 PVAR
- *out_sip_username (pvar)* - 用于在成功认证后存储与 JWT 配置文件对应的 SIP 用户名的 PVAR


此函数可用于 REQUEST_ROUTE。


```c title="jwt_db_authorize 使用"
...
if (!jwt_db_authorize("$avp(my_jwt_token)", $avp(decoded_token), $avp(sip_username) )) {
	send_reply(401,"Unauthorized");
	exit;
} else {
	xlog("JWT 认证成功 - $avp(decoded_token) \n");
	if ($fU != $avp(sip_username)) {
		send_reply(403,"Forbidden AUTH ID");
		exit;
	}	
}
...
```


#### jwt_script_authorize(jwt_token,key, out_decoded_token)


此函数将读取第一个参数（jwt_token），解码它，
		然后尝试使用提供的密钥对其进行验证。
        如果 JWT 解码成功，out_decoded_token pvar 将被填充。
			返回码如下：


- -2：解码 JWT 失败（out_decoded_token 将不会被填充）
- -1：验证 JWT 失败（out_decoded_token 将被填充）
- 1：使用密钥成功验证 JWT（out_decoded_token 将被填充）


参数的含义如下：


- *jwt_token (字符串)* - 要进行认证的 JWT 令牌
该字符串可以包含伪变量。
- *key (字符串)* - 用于验证 JWT 的密钥。
- *out_decoded_token (pvar)* - 用于存储解码 JWT 的 PVAR


此函数可用于 REQUEST_ROUTE。


```c title="jwt_script_authorize 使用"
...
if (!jwt_script_authorize("$avp(my_jwt_token)",$avp(pub_key), $avp(decoded_token))) {
	send_reply(401,"Unauthorized");
	exit;
} else {
	xlog("JWT 认证成功 - $avp(decoded_token) \n");
}
...
```


#### extract_pub_key_from_cert(certificate,out_public_key)


此函数将读取第一个参数（certificate），解码它，
		然后尝试从证书中提取公钥。
        如果提取成功，out_public_key 将被填充。
        可与 jwt_script_authorize 函数结合使用，
        因为大多数提供商公开他们的证书，但 JWT 使用嵌入在证书中的实际公钥进行签名。
			返回码如下：


- -1：提取公钥失败
- 1：out_public_key 成功填充


参数的含义如下：


- *certificate (字符串)* - 要读取并从中提取公钥的证书
该字符串可以包含伪变量。
- *out_public_key (pvar)* - 用于存储提取的公钥的 PVAR


此函数可用于 REQUEST_ROUTE。


```c title="extract_pub_key_from_cert 使用"
...
if (extract_pub_key_from_cert("$avp(my_certificate)",$avp(my_pub_key))) {
    xlog("成功提取公钥 - $avp(my_pub_key) \n");
}
...
```


#### extract_pub_key_from_exp_mod(e,n,out_public_key)


此函数读取 base64url 编码的 RSA 指数（*e*）和模数（*n*），
		然后构建 PEM 公钥并将其存储到 *out_public_key*。
			返回码如下：


- -1：提取公钥失败
- 1：out_public_key 成功填充


参数的含义如下：


- *e (字符串)* - Base64url 编码的 RSA 指数
该字符串可以包含伪变量。
- *n (字符串)* - Base64url 编码的 RSA 模数
该字符串可以包含伪变量。
- *out_public_key (pvar)* - 用于存储提取的公钥的 PVAR


此函数可用于 REQUEST_ROUTE。


```c title="extract_pub_key_from_exp_mod 使用"
...
if (extract_pub_key_from_exp_mod("$avp(my_exp)", "$avp(my_mod)", $avp(my_pub_key))) {
    xlog("成功提取公钥 - $avp(my_pub_key) \n");
}
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
