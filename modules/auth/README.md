---
title: "Auth 模块"
description: "这是一个提供其他认证相关模块所需通用函数的模块。此外，它还可以从伪变量中获取用户名和密码进行认证。"
---

## 管理指南


### 概述


这是一个提供其他认证相关模块所需通用函数的模块。此外，它还可以从伪变量中获取用户名和密码进行认证。


#### RFC 8760 支持（增强型认证）


从 OpenSIPS 3.2 开始，[auth](../auth)、
			[auth_db](../auth_db) 和
			[uac_auth](../uac_auth)
			模块支持两种新的摘要认证算法
			（"SHA-256" 和 "SHA-512-256"），符合
	        [RFC 8760](https://datatracker.ietf.org/doc/html/rfc8760)
	        规范。


### Nonce 安全机制


认证机制提供防止嗅探入侵的保护。
        模块生成并验证 nonce，使其只能使用一次（在一次认证响应中）。
        这是通过为每个 nonce 设置生命周期值和索引来实现的。
        仅使用过期时间是不够的，因为该值必须只有几十秒，
        攻击者有可能在网络上嗅探到凭据，然后在另一个数据包中重用它们，
        用它来注册不同的联系人或使用他人的账户进行呼叫。
        索引确保这永远不会发生，因为它在整个 nonce 生命周期内是唯一生成的。


默认限制是 30 秒内可认证 100000 个请求。
		如果需要调整，可以减少 nonce 的生命周期（等待回复的时间）。
        但要注意不要设置得太小。


但是，对于使用服务器集群通过相同的 DNS 名称进行负载均衡的架构，
		此机制不起作用。在这种情况下，
		可以通过设置模块参数 'disable_nonce_check' 来禁用 nonce 可重用性检查。


### 依赖


#### OpenSIPS 模块


该模块依赖以下模块（换句话说，
			列出的模块必须在此模块之前加载）：


- *signaling* -- 信令模块


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前必须安装
			以下库或应用程序：


- *无*


### 导出的参数


#### secret (字符串)


用于计算 nonce 值的密钥短语。
		必须恰好是 32 个字符长。


默认使用核心中随机源生成的随机值。


如果在安装中使用多台服务器，并且希望使用第一台服务器生成的 nonce
		在第二台服务器上进行认证，则必须明确设置所有服务器上的密钥为相同的值。
		但是，使用共享（和固定）的密钥作为 nonce 是不安全的，
        更好的做法是保持默认值。任何客户端都应将回复发送到发出请求的服务器。


```c title="secret 参数示例"
modparam("auth", "secret", "johndoessecretphrase")
```


#### nonce_expire (整数)


Nonce 有有限的生命周期。超过指定时间后
		nonce 将被视为无效。这是为了防止重放攻击。
		包含过期 nonce 的凭据将不会被授权，但用户代理将再次收到挑战。
        这次挑战将包含 `stale` 参数，向客户端表明
		不必打扰用户询问用户名和密码，
        它可以使用现有的用户名和密码重新计算凭据。


该值以秒为单位，默认值为 30 秒。


```c title="nonce_expire 参数示例"
modparam("auth", "nonce_expire", 15)   # 将 nonce_expire 设置为 15 秒
```


#### rpid_prefix (字符串)


在 Remote-Party-ID 头域之前添加的前缀，
		该头域中的 URI 是从 radius 或数据库返回的。


默认值为 ""。


```c title="rpid_prefix 参数示例"
modparam("auth", "rpid_prefix", "Whatever <")
```


#### rpid_suffix (字符串)


在 Remote-Party-ID 头域之后添加的后缀，
		该头域中的 URI 是从 radius 或数据库返回的。


默认值为 
			";party=calling;id-type=subscriber;screen=yes"。


```c title="rpid_suffix 参数示例"
modparam("auth", "rpid_suffix", "@1.2.3.4>")
```


#### realm_prefix (字符串)


自动从 realm 中剥离的前缀。作为
			SRV 记录的替代方案（并非所有 SIP 客户端都支持 SRV 查询），
			可以为 SIP 用途定义主域的子域
			（如 sip.mydomain.net 指向与 mydomain.net 的 SRV 记录相同的 IP 地址）。
        通过在认证时忽略 realm_prefix
			"sip."，sip.mydomain.net 将等同于 mydomain.net。


默认值为空字符串。


```c title="realm_prefix 参数示例"
modparam("auth", "realm_prefix", "sip.")
```


#### rpid_avp (字符串)


用于存储 RPID 值的 AVP 的完整规范。
        它用于将 RPID 值从认证后端模块（auth_db 或 auth_radius）
        或从脚本传递到 auth 函数 append_rpid_hf 和 is_rpid_user_e164。


如果设置为 NULL 字符串，所有 RPID 函数将在
			运行时失败。


默认值为 "$avp(rpid)"。


```c title="rpid_avp 参数示例"
modparam("auth", "rpid_avp", "$avp(caller_rpid)")
			
```


#### username_spec (字符串)


用于保存用户名的伪变量名称。


默认值为 "NULL"。


```c title="username_spec 参数使用"
modparam("auth", "username_spec", "$var(username)")
```


#### password_spec (字符串)


用于保存密码的伪变量名称。


默认值为 "NULL"。


```c title="password_spec 参数使用"
modparam("auth", "password_spec", "$var(password)")
```


#### calculate_ha1 (整数)


此参数告诉服务器是否应期望伪变量中的明文
		密码或预计算的 HA1 字符串。


如果参数设置为 1，则服务器将假定
		"password_spec" 伪变量包含明文密码，
        并将动态计算 HA1 字符串。如果参数设置为 0，
        则服务器假定伪变量直接包含 HA1 字符串，不会计算它们。


此参数的默认值为 0。


```c title="calculate_ha1 参数使用"
modparam("auth", "calculate_ha1", 1)
```


#### disable_nonce_check (整数)


通过设置此参数，可以禁用保护免受入侵嗅探的安全机制，
		不允许 nonce 被重用。但是，由于当前实现，
		启用此功能会破坏使用相同 DNS 名称进行负载均衡的架构的认证。
        在这种情况下必须设置此参数。


默认值为 "0"（已启用）。


```c title="disable_nonce_check 参数使用"
modparam("auth", "disable_nonce_check", 1)
```


### 导出的函数


#### www_challenge(realm[, qop[, algorithms]])


向用户代理发起挑战。它将生成一个或
		多个包含摘要挑战的 WWW-Authorize 头域，
        它将把头域放入从服务器正在处理的请求生成的响应中并发送回复。
        收到此类回复后，用户代理应计算凭据并重试请求。
        有关摘要认证的更多信息，请参阅 RFC2617、RFC3261 和 RFC8760。


参数的含义如下：


- *realm* (字符串) - Realm 是一个不透明字符串，
			用户代理应向用户展示，以便用户决定使用什么
			用户名和密码。通常这是服务器运行所在的主机域名。
如果使用空字符串 ""，则服务器将
			从请求中生成它。对于 REGISTER 请求的 To
			头域，将使用该头域中的域名（因为此头域
			代表正在注册的用户），对于所有其他消息，
			将使用 From 头域中的域名。
- *qop* (字符串，可选) - 此参数的值可以是 "auth"、"auth-int"
			或两者的组合（用 *,* 分隔）。设置此参数后，
            服务器将在挑战中放入 qop 参数。建议使用 qop 参数，
            但仍有一些用户代理不能正确处理 qop，所以设为可选。
            另一方面，仍有一些用户代理不能处理没有 qop 参数的请求。
启用此参数目前不会提高安全性，
			因为序列号未被存储，因此无法检查。
            实际上，模块在挑战和响应请求期间不保留任何信息。
- *algorithms* (字符串，可选) - 此参数的值是一个逗号分隔的摘要算法列表，
			可供 UAC 选择用于认证。可能的值有：

  - MD5
  - MD5-sess
  - SHA-256
  - SHA-256-sess
  - SHA-512-256
  - SHA-512-256-sess
当值为空或未设置时，唯一提供的摘要
			算法是 *MD5*，以提供与 RFC8760 之前 UAC 实现的兼容性。
值的顺序可以任意排列。SIP 响应中各个挑战的实际顺序由 RFC8760 定义：
            从更强的算法到更弱的算法。


此函数可用于 REQUEST_ROUTE。


```c title="www_challenge 使用"
...
if (!www_authorize("siphub.net", "subscriber")) {
	www_challenge("siphub.net", "auth,auth-int", "MD5,SHA-512-256");
}
...
```


#### proxy_challenge(realm[, qop[, algorithms]])


此函数向用户代理发起挑战。它将生成一个包含摘要挑战的
		Proxy-Authorize 头域，
        它将把头域放入从服务器正在处理的请求生成的响应中并发送回复。
        收到此类回复后，用户代理应计算凭据并重试请求。
        有关摘要认证的更多信息，请参阅 RFC2617、RFC3261 和 RFC8760。


有关参数的说明，请参阅
		    [www challenge 参数](#www_challenge_params)。


此函数可用于 REQUEST_ROUTE。


```c title="proxy_challenge 使用"
...
$var(secure_algorithms) = "sha-256,sha-512-256";
...
if (!proxy_authorize("", "subscriber")) {
...
	proxy_challenge("", "auth", $var(secure_algorithms));  # Realm 将自动生成
							       # MD5 将不被允许
}
...
```


#### consume_credentials()


此函数从服务器正在处理的消息中删除先前授权的凭据。
		这意味着下游消息将不包含这些被此服务器使用的凭据。
        这确保代理不会向下游元素透露有关
        凭据的信息，并且消息也会稍微短一些。
        此函数必须在 `www_authorize` 或
		`proxy_authorize` 之后调用。


此函数可用于 REQUEST_ROUTE。


```c title="consume_credentials 示例"
...
if (www_authorize("", "subscriber")) {
    consume_credentials();
}
...
```


#### is_rpid_user_e164()


此函数检查从数据库或 radius 服务器收到的 SIP URI
		（将用于 Remote-Party-ID 头域）的用户部分是否包含 E164 号码
        （+ 后跟最多 15 位十进制数字）。
        如果不存在这样的 SIP URI（即 radius 服务器或数据库未提供此信息），
        检查失败。


此函数可用于 REQUEST_ROUTE。


```c title="is_rpid_user_e164 使用"
...
if (is_rpid_user_e164()) {
    # 在此进行相应处理
}
...
```


#### append_rpid_hf()


向消息追加一个 Remote-Party-ID 头域，
		该头域包含 'Remote-Party-ID: '，后跟从数据库或 radius 服务器收到的 SIP URI 的保存值，
        再后跟模块参数 radius_rpid_suffix 的值。
        如果不存在保存的 SIP URI，此函数不执行任何操作。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、
		BRANCH_ROUTE。


```c title="append_rpid_hf 使用"
...
append_rpid_hf();  # 追加 Remote-Party-ID 头域
...
```


#### append_rpid_hf(prefix, suffix)


此函数与
		[append rpid hf no params](#func_append_rpid_hf) 相同。
        唯一的区别是它接受两个参数——前缀和后缀，
        将被添加到 Remote-Party-ID 头域。
        此函数忽略 rpid_prefix 和 rpid_suffix 参数，
        相反，允许在每次调用时设置它们。


参数的含义如下：


- *prefix* (字符串) - Remote-Party-ID URI 的前缀。
			该字符串将被添加到头域主体的开头，正好在 URI 之前。
- *suffix* (字符串) - Remote-Party-ID 头域的后缀。
			该字符串将被追加到头域的末尾。
            例如，它可以用于设置各种 URI 参数。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、
		BRANCH_ROUTE。


```c title="append_rpid_hf(prefix, suffix) 使用"
...
# 追加 Remote-Party-ID 头域
append_rpid_hf("", ";party=calling;id-type=subscriber;screen=yes");
...
```


#### pv_www_authorize(realm)


此函数根据
		[RFC2617](http://www.ietf.org/rfc/rfc2617.txt) 验证凭据。
        如果凭据验证成功，则函数将成功并
        将凭据标记为已授权（标记的凭据可供其他函数稍后使用）。
        如果函数由于某种原因无法验证凭据，则它将失败，
        脚本应调用 `www_challenge` 再次向用户发起挑战。


负返回码的解释如下：


- *-5（通用错误）* - 发生某些通用错误，未发送回复；
- *-4（无凭据）* - 在请求中未找到凭据；
- *-3（过期 nonce）* - nonce 已过期；
- *-2（密码无效）* - 用户有效，但密码错误；
- *-1（用户无效）* - 认证用户不存在。


参数的含义如下：


- *realm* (字符串) - Realm 是一个不透明字符串，
			用户代理应向用户展示，以便用户决定使用什么
			用户名和密码。通常这是服务器运行所在的主机域名。
如果使用空字符串 ""，则服务器将从请求中生成它。
            对于 REGISTER 请求的 To 头域，将使用该头域中的域名
            （因为此头域代表正在注册的用户），
            对于所有其他消息，将使用 From 头域中的域名。


此函数可用于 REQUEST_ROUTE。


```c title="pv_www_authorize 使用"
...
$var(username)="abc";
$var(password)="xyz";
if (!pv_www_authorize("opensips.org")) {
	www_challenge("opensips.org", "auth");
}
...
```


#### pv_proxy_authorize(realm)


此函数根据
		[RFC2617](http://www.ietf.org/rfc/rfc2617.txt) 验证凭据。
        如果凭据验证成功，则函数将成功并将凭据标记为已授权
        （标记的凭据可供其他函数稍后使用）。
        如果函数由于某种原因无法验证凭据，则它将失败，
        脚本应调用 `proxy_challenge` 再次向用户发起挑战。
        有关负返回码的更多信息，请参阅上面的函数。


参数的含义如下：


- *realm* (字符串) - Realm 是一个不透明字符串，
			用户代理应向用户展示，以便用户决定使用什么
			用户名和密码。通常这是服务器运行所在的主机域名。
如果使用空字符串 ""，则服务器将从请求中生成它。
            From 头域的域名将被用作 realm。


此函数可用于 REQUEST_ROUTE。


```c title="pv_proxy_authorize 使用"
...
$var(username)="abc";
$var(password)="xyz";
if (!pv_proxy_authorize("")) {
	proxy_challenge("", "auth");  # Realm 将自动生成
}
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
