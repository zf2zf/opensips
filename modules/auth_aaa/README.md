---
title: "Auth_aaa 模块"
description: "此模块包含用于执行摘要认证和针对 AAA 服务器进行某些 URI 检查的函数。为了执行认证，代理将把凭据传递给 AAA 服务器，然后 AAA 服务器将发送包含认证结果的回复。"
---

## 管理指南


### 概述


此模块包含用于执行摘要认证和针对 AAA 服务器进行某些 URI 检查的函数。
		为了执行认证，代理将把凭据传递给 AAA 服务器，
        然后 AAA 服务器将发送包含认证结果的回复。
        所以基本上整个认证过程都在 AAA 服务器中完成。
        在将请求发送到 AAA 服务器之前，我们会对凭据进行一些完整性检查，
        以确保只有格式正确的凭据才会到达服务器。


### 附加凭据


执行认证时，AAA 服务器可以在回复中包含附加凭据。
		这种方案非常有用，可以在不进行额外查询的情况下从 AAA 服务器获取附加的用户信息。


附加凭据以 AVP "SIP-AVP" 的形式嵌入在 AAA 回复中。
		值的语法如下：


- *value = SIP_AVP_NAME SIP_AVP_VALUE*
- *SIP_AVP_NAME = STRING_NAME | '#'ID_NUMBER*
- *SIP_AVP_VALUE = ':'STRING_VALUE | '#'NUMBER_VALUE*


所有附加凭据都将存储为 OpenSIPS AVP
		（SIP_AVP_NAME = SIP_AVP_VALUE）。


RPID 值可以通过此机制获取。


```c title="'SIP-AVP' AAA AVP 示例"
....
"email:joe@yahoo.com"
    - 字符串名称 AVP (email)，字符串值 (joe@yahoo.com)
"#14:joe@yahoo.com"
    - ID AVP (14)，字符串值 (joe@yahoo.com)
"age#28"
    - 字符串名称 AVP (age)，整数值 (28)
"#14#28"
    - ID AVP (14)，整数值 (28)
....
			
```


### 依赖


#### OpenSIPS 模块


该模块依赖以下模块（换句话说，
			列出的模块必须在此模块之前加载）：


- *auth* -- 认证框架，仅当从脚本使用 auth 函数时
- *一个实现 aaa 的模块* -- 例如 aaa_radius


#### 外部库或应用程序


此模块不依赖任何外部库。


### 导出的参数


#### aaa_url (字符串)


这是表示所使用的 AAA 协议及其配置文件位置的 URL。


URL 的语法如下：
		"name_of_the_aaa_protocol_used:path_of_the_configuration_file"


```c title="aaa_url 参数使用"
			
modparam("auth_aaa", "aaa_url", "radius:/etc/radiusclient-ng/radiusclient.conf")
			
```


#### auth_service_type (整数)


执行认证操作时使用的 Service-Type aaa 属性的值。
		默认值对大多数人都应该没问题。
        如果需要更改，请参阅您的 aaa 客户端包含文件以获取此参数应使用的数字。


默认值为 "15"。


```c title="auth_service_type 参数使用"
			
modparam("auth_aaa", "auth_service_type", 15)
			
```


#### check_service_type (整数)


`aaa_does_uri_exist` 和
		`aaa_does_uri_user_exist` 检查所使用的 AAA 服务类型。


*默认值为 10（Call-Check）。*


```c title="设置 check_service_type 参数"
...
modparam("auth_aaa", "check_service_type", 11)
...
```


#### use_ruri_flag (字符串)


当此参数设置为非 "NULL" 的值，并且被认证的请求
		具有通过 setflag() 函数设置的匹配编号标志时，
        使用 Request URI 而不是 Authorization / Proxy-Authorization 头域中
        uri 参数的值来执行 AAA 认证。
        这旨在为行为不当的 NAT/路由器/ALG 提供变通方法，
        这些设备在传输过程中更改请求，破坏认证。
        在撰写本文时，已知某些版本的 Linksys WRT54GL 会这样做。


默认值为 "NULL"（未设置）。


```c title="use_ruri_flag 参数使用"
			
modparam("auth_aaa", "use_ruri_flag", "USE_RURI_FLAG")
			
```


### 导出的函数


#### aaa_www_authorize(realm, [uri_user])


此函数根据
		[RFC2617](http://www.ietf.org/rfc/rfc2617.txt) 验证凭据。
        如果凭据验证成功，则函数将成功并将凭据标记为已授权
        （标记的凭据可供其他函数稍后使用）。
        如果函数由于某种原因无法验证凭据，则它将失败，
        脚本应调用 `www_challenge` 再次向用户发起挑战。


负返回码的解释如下：


- *-5（通用错误）* - 发生某些通用错误，未发送回复；
- *-4（无凭据）* - 在请求中未找到凭据；
- *-3（过期 nonce）* - nonce 已过期。


此函数实际上将对收到的凭据执行完整性检查，
		然后将它们传递给 aaa 服务器，aaa 服务器将验证凭据并返回是否有效。


参数含义如下：


- *realm (字符串)* - Realm 是一个不透明字符串，
			用户代理应向用户展示，以便用户决定使用什么
			用户名和密码。通常这是服务器运行所在的主机域名。
如果使用空字符串 ""，则服务器将从请求中生成它。
            对于 REGISTER 请求的 To 头域，将使用该头域中的域名
            （因为此头域代表正在注册的用户），
            对于所有其他消息，将使用 From 头域中的域名。
该字符串可以包含伪变量。
- *uri_user (字符串，可选)* - 传递给 Radius 服务器作为 SIP-URI-User
			检查项的值。如果此参数不存在，
            服务器将从 To 头域 URI 的用户名部分生成 SIP-URI-User 检查项的值。


此函数可用于 REQUEST_ROUTE。


```c title="aaa_www_authorize 使用"
			
...
if (!aaa_www_authorize("siphub.net"))
	www_challenge("siphub.net", "auth");
...
```


#### aaa_proxy_authorize(realm, [uri_user])


此函数根据
		[RFC2617](http://www.ietf.org/rfc/rfc2617.txt) 验证凭据。
        如果凭据验证成功，则函数将成功并将凭据标记为已授权
        （标记的凭据可供其他函数稍后使用）。
        如果函数由于某种原因无法验证凭据，则它将失败，
        脚本应调用 `proxy_challenge` 再次向用户发起挑战。
        有关负返回码的更多信息，请参阅上面的函数。


此函数实际上将对收到的凭据执行完整性检查，
		然后将它们传递给 aaa 服务器，aaa 服务器将验证凭据并返回是否有效。


参数含义如下：


- *realm (字符串)* - Realm 是一个不透明字符串，
			用户代理应向用户展示，以便用户决定使用什么
			用户名和密码。通常这是代理负责的域名之一。
			如果使用空字符串 ""，则服务器将从 From 头域 URI 的主机部分生成 realm。
该字符串可以包含伪变量。
- *uri_user (字符串，可选)* - 传递给 Radius 服务器作为 SIP-URI-User
			检查项的值。如果此参数不存在，
            服务器将从 To 头域 URI 的用户名部分生成 SIP-URI-User 检查项的值。


此函数可用于 REQUEST_ROUTE。


```c title="proxy_authorize 使用"
			
...
if (!aaa_proxy_authorize(""))    # Realm 和 URI user 将自动生成
	proxy_challenge("", "auth");
...
if (!aaa_proxy_authorize($pd, $pU))    # Realm 和 URI user 从
	proxy_challenge($pd, "auth");  # P-Preferred-Identity 头域获取
                                       #
...
```


#### aaa_does_uri_exist([sip_uri])


从 Radius 检查存储在 "sip_uri" 参数中的 SIP URI
		（如果未给出 "sip_uri"，则使用 Request-URI 的 user@host 部分）
		是否属于本地用户。
        可用于在查找失败后决定返回 404 还是 480。
        如果是，将加载基于从 Radius 返回的 SIP-AVP 回复项的 AVP。
        每个 SIP-AVP 回复项必须具有以下形式的字符串值：


- *value = SIP_AVP_NAME SIP_AVP_VALUE*
- *SIP_AVP_NAME = STRING_NAME | '#'ID_NUMBER*
- *SIP_AVP_VALUE = ':'STRING_VALUE | '#'NUMBER_VALUE*


如果 Radius 返回 Access-Accept，则返回 1；
		如果 Radius 返回 Access-Reject，则返回 -1；
        如果发生内部错误，则返回 -2。


此函数可用于 REQUEST_ROUTE。


```c title="aaa_does_uri_exist 使用"
...
if (aaa_does_uri_exist()) {
	...
};
...
```


#### aaa_does_uri_user_exist([sip_uri])


类似于 aaa_does_uri_exist，但检查仅基于
		Request-URI 的用户部分或存储在 "sip_uri" 中的用户。
        因此，用户应该在所有用户中唯一，如 E.164 号码。


此函数可用于 REQUEST_ROUTE。


```c title="aaa_does_uri_user_exist 使用"
...
if (aaa_does_uri_user_exist()) {
	...
};
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
