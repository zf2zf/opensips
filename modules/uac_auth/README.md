---
title: "UAC AUTH 模块"
description: "UAC AUTH（用户代理客户端认证）模块提供构建认证头的通用 API。"
---

## 管理指南


### 概述


UAC AUTH（用户代理客户端认证）模块提供
		构建认证头的通用 API。


它还提供供其他模块使用的通用认证凭据集。


请注意，此模块提供的认证支持 qop "auth" 和 qop "auth-int" 两种，
		但如果服务器同时提供两个值，则优先选择 "auth"。


#### RFC 8760 支持（强化认证）


从 OpenSIPS 3.2 开始，
			[auth](../auth)、
			[auth_db](../auth_db) 和
			[uac_auth](../uac_auth)
			模块包含对两种新摘要认证算法（"SHA-256" 和 "SHA-512-256"）的支持，
			根据
	        [RFC 8760](https://datatracker.ietf.org/doc/html/rfc8760)
	        规范。


### 依赖


#### OpenSIPS 模块


- *无*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- *无*


### 导出的参数


#### credential (string)


包含用于执行认证的凭据的多个定义。


请注意，密码可以作为明文密码或
			以十六进制（小写）字符串（32 个字符）
			提供，前面带有 "0x"（因此总共 34 个字符）。


*如果使用 UAC 认证，则需要此参数。*


```c title="设置 credential 参数"
...
modparam("uac_auth","credential","username:domain:password")
modparam("uac_auth","credential","username:domain:0xc17ba8157756f263d07e158504204629")
...

```


#### auth_realm_avp (string)


可能包含用于执行认证的 realm 的 AVP 定义。


*如果您定义它，还需要定义
				"auth_username_avp" 
				（[auth username avp](#param_auth_username_avp)）和 
				"auth_password_avp" 
				（[auth password avp](#param_auth_password_avp)）。*


```c title="设置 auth_realm_avp 参数"
...
modparam("uac_auth","auth_realm_avp","$avp(10)")
...

```


#### auth_username_avp (string)


可能包含用于认证的用户名的 AVP 定义。


*如果您定义它，还需要定义
				"auth_realm_avp" 
				（[auth realm avp](#param_auth_realm_avp)）和 
				"auth_password_avp" 
				（[auth password avp](#param_auth_password_avp)）。*


```c title="设置 auth_username_avp 参数"
...
modparam("uac_auth","auth_username_avp","$avp(11)")
...

```


#### auth_password_avp (string)


可能包含用于认证的密码的 AVP 定义。
		密码可以作为明文密码或
			以十六进制（小写）字符串（32 个字符）
			提供，前面带有 "0x"（因此总共 34 个字符）
			（例如 "0xc17ba8157756f263d07e158504204629"）


*如果您定义它，还需要定义
				"auth_realm_avp" 
				（[auth realm avp](#param_auth_realm_avp)）和 
				"auth_username_avp" 
				（[auth username avp](#param_auth_username_avp)）。*


```c title="设置 auth_password_avp 参数"
...
modparam("uac_auth","auth_password_avp","$avp(12)")
...

```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
