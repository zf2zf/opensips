---
title: "STIR/SHAKEN 模块"
description: "此模块为 OpenSIPS 添加了实现 STIR/SHAKEN（RFC 8224、RFC 8588）认证和验证服务的支持。"
---

## 管理指南


### 概述


此模块为 OpenSIPS 添加了实现 STIR/SHAKEN（RFC 8224、RFC 8588）
		认证和验证服务的支持。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他 OpenSIPS 模块*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- *wolfssl (libwolfssl)*。


### 导出的参数


#### auth_date_freshness (integer)


Date 头字段中的值可以比当前时间更旧的最大秒数。


此参数仅与 [stir shaken auth](#func_stir_shaken_auth) 函数相关。


默认值为 *60*。


```c title="设置 auth_date_freshness 参数"
...
modparam("stir_shaken", "auth_date_freshness", 300)
...
```


#### verify_date_freshness (integer)


Date 头字段中的值可以比当前时间更旧的最大秒数。
		此外，如果 PASSporT 中的 *iat* 值与 Date 值不同，
		但在允许的间隔内，它将在验证过程中使用（用于重建的 PASSporT），
		而不是 Date 值。


如果 [require date hdr](#param_require_date_hdr) 参数设置为非必需，
		且 Date 头缺失，则 *iat* 值将用于此检查。


此参数仅与 [stir shaken verify](#func_stir_shaken_verify) 函数相关。


默认值为 *60*。


```c title="设置 verify_date_freshness 参数"
...
modparam("stir_shaken", "verify_date_freshness", 300)
...
```


#### ca_list (string)


包含验证者可信 CA 证书的文件路径。
		证书必须为 PEM 格式，依次排列。


```c title="设置 ca_list 参数"
...
modparam("stir_shaken", "ca_list", "/stir_certs/ca_list.pem")
...
```


#### ca_dir (string)


包含验证者可信 CA 证书的目录路径。
		目录中的证书必须采用哈希形式，
		如 [openssl 文档](https://www.openssl.org/docs/manmaster/man3/X509_LOOKUP_hash_dir.html) 中
		*哈希目录方法* 所述。


```c title="设置 ca_dir 参数"
...
modparam("stir_shaken", "ca_dir", "/stir_certs/cas")
...
```


#### crl_list (string)


包含验证者证书吊销列表（CRL）的文件路径。


```c title="设置 crl_list 参数"
...
modparam("stir_shaken", "crl_list", "/stir_certs/crl_list.pem")
...
```


#### crl_dir (string)


包含验证者证书吊销列表（CRL）的目录路径。
		目录中的 CRL 必须采用哈希形式，
		如 [openssl 文档](https://www.openssl.org/docs/manmaster/man3/X509_LOOKUP_hash_dir.html) 中
		*哈希目录方法* 所述。


```c title="设置 crl_dir 参数"
...
modparam("stir_shaken", "crl_dir", "/stir_certs/crls")
...
```


#### e164_strict_mode (integer)


要求在发起/目标 SHAKEN 身份中存在前导 *"+"*，
		此外还要求默认使用 E.164 电话号码。
		另外，要求 URI 必须是 *tel* URI 或带有 *user=phone*
		参数的 *sip*/*sips* URI。


默认值为 *0*（禁用）。


```c title="设置 e164_strict_mode 参数"
...
modparam("stir_shaken", "e164_strict_mode", 1)
...
```


#### e164_max_length (integer)


此参数允许绕过 E.164 格式的 15 位数字长度限制。
		在某些电话号码前缀正在使用导致一些数字超过标准最大长度的情况下特别有用。


默认值为 *15*。


```c title="设置 e164_max_length 参数"
...
modparam("stir_shaken", "e164_max_length", 16)
...
```


#### require_date_hdr (integer)


指定在使用 [stir shaken verify](#func_stir_shaken_verify) 函数进行验证时，
		    Date 头是否是强制的。


值为 *1* 表示必需，*0*
		    表示非必需。


如果参数设置为"非必需"但消息中存在 Date 头，
		    该头值将照常用于检查新鲜度（如
		    [verify date freshness](#param_verify_date_freshness)
		    参数中所配置）。
		如果 Date 头确实缺失，则使用 PASSporT 中 *iat* 声明的值。


默认值为 *1*（必需）。


```c title="设置 require_date_hdr 参数"
...
modparam("stir_shaken", "require_date_hdr", 0)
...
```


### 导出的函数


#### stir_shaken_auth(attest, origid, cert, pkey, x5u, [orig], [dest], [out])


此函数执行认证服务的步骤。但是在调用此函数之前，
		您必须确保：


- authority - 服务器对相关身份具有权威性；
- authentication - 发起者被授权声明给定身份。


参数的含义如下：


- *attest (string)* - 要包含在 PASSporT 中的 'attest' 声明的值。
			可以使用以下值：
				
					
				*A* 或 *full*
					
					
				*B* 或 *partial*
					
					
				*C* 或 *gateway*
- *origid (string)* - 要包含在 PASSporT 中的 'origid' 声明的值。
			模块将其视为不透明字符串。
- *cert (string)* - 用于计算签名的 X.509 证书，
			PEM 格式。
- *pkey (string)* - 用于计算签名的私钥，
			PEM 格式。
- *x5u (string)* - 要包含在 PASSporT 中的 'x5u' 声明的值。
			模块将其视为不透明字符串。
- *orig (string, 可选)* - 要在 PASSporT 中用作发起身份的的电话号码。
			如果缺失，此值将从 SIP 消息派生。
- *dest (string, 可选)* - 要在 PASSporT 中用作目标身份的 电话号码。
			如果缺失，此值将从 SIP 消息派生。
- *out (string, 不展开, 可选)* - 输出变量的名称，
			用于存储 Identity 头或以下标志：
				
				
				*req* - Identity 头将附加到当前请求消息；
				
				
				*rpl* - Identity 头将附加到 OpenSIPS 将为此请求生成的所有回复。
如果缺少此参数，Identity 头将附加到当前请求消息。
如果提供了输出变量，应将其作为带引号的字符串给出，
			例如 *"$var(identity_hdr)"*。


函数返回以下值：


- 1: 成功
- -1: 内部错误
- -3: 无法从 SIP 消息派生身份，因为 URI 不是电话号码
- -4: Date 头值比本地策略更新鲜度要求更旧
- -5: 当前时间或 Date 头值不在证书有效期内


此函数可用于 REQUEST_ROUTE。


```c title="stir_shaken_auth() 使用示例"
...
stir_shaken_auth("A", "4437c7eb-8f7a-4f0e-a863-f53a0e60251a",
	$var(cert), $var(privKey), "https://certs.example.org/cert.pem");
...
```


#### stir_shaken_verify(cert, err_code, err_reason, [orig], [dest])


此函数执行验证服务的步骤。


参数的含义如下：


- *cert (string)* - 用于验证签名的 X.509 证书，
			PEM 格式。
- *err_code (var)* - 输出变量，用于存储与验证过程最终错误关联的 SIP 响应码。
- *err_reason (var)* - 输出变量，用于存储与验证过程最终错误关联的 SIP 响应原因短语。
- *orig (string, 可选)* - 要在验证过程中用作发起身份的电话号码。
			如果缺失，此值将从 SIP 消息派生。
- *dest (string, 可选)* - 要在验证过程中用作目标身份的电话号码。
			如果缺失，此值将从 SIP 消息派生。


函数返回以下值：


- 1: 成功
- -1: 内部错误
- -2: 未找到 Identity 或 Date 头
- -3: 无法从 SIP 消息派生身份，因为 URI 不是电话号码
- -4: 无效的 identity 头
- -5: 不支持的 'ppt' 或 'alg' Identity 头参数
- -6: Date 头值比本地策略更新鲜度要求更旧
- -7: Date 头值不在证书有效期内
- -8: 无效证书
- -9: 签名验证不成功


此函数可用于 REQUEST_ROUTE。


```c title="stir_shaken_verify() 使用示例"
...
$var(rc) = stir_shaken_verify($var(cert), $var(err_code), $var(err_reason));
if ($var(rc) < -1) {
	send_reply($var(err_sip_code), $var(err_sip_reason));
	exit;
}
...
```


#### stir_shaken_check()


此函数检查 Identity 头以验证 STIR/SHAKEN 信息的格式正确性。
		它检测诸如缺失或格式错误的 PASSporT 声明、不支持的扩展等问题。


函数返回以下值：


- 1: 成功
- -1: 内部错误
- -2: 未找到 Identity 头
- -3: 无效的 identity 头
- -4: 不支持的 'ppt' 或 'alg' Identity 头参数


此函数可用于 REQUEST_ROUTE。


```c title="stir_shaken_check() 使用示例"
...
if (stir_shaken_check()) {
	xlog("将呼叫转发到 stir/shaken 验证服务\n");
	...
}
...
```


#### stir_shaken_check_cert()


此函数检查当前时间是否在给定证书的有效期内。


函数返回以下值：


- 1: 成功
- -1: 内部错误
- -2: 证书无效


此函数可用于 REQUEST_ROUTE。


```c title="stir_shaken_check_cert() 使用示例"
...
# 更新过期的缓存证书
cache_fetch("local", $identity(x5u), $var(cert));
if (!stir_shaken_check_cert($var(cert))) {
	rest_get($identity(x5u), $var(cert));
	cache_store("local", $identity(x5u), $var(cert));
}
...
```


#### stir_shaken_disengagement(token)


此函数在 SIP 头末尾添加带有令牌值的 P-Identity-Bypass 头。


参数的含义如下：


- *token (string)* - 宕机期间由授权机构提供的令牌。


函数返回以下值：


- 1: 成功
- 0: 添加 P-Identity-Bypass 头失败


此函数可用于 REQUEST_ROUTE。


```c title="stir_shaken_disengagement() 使用示例"
...
if ( is_method("INVITE") && !has_totag()) {
	# 等同于 sipmsgops 模块：append_hf("P-Identity-Bypass: OSIP99-1234567890ABCDEF\r\n");
	stir_shaken_disengagement("OSIP99-1234567890ABCDEF");
}
...
```


### 导出的伪变量


#### $identity(field)


这是一个只读伪变量，通过以下子名称提供对
		Identity 头解析信息的访问：


- *header* - 整个 PASSporT 头；
- *x5u* - 'x5u' PASSporT 声明的值；
- *payload* - 整个 PASSporT 载荷；
- *attest* - 'attest' PASSporT 声明的值；
- *dest* - 'dest' PASSporT 声明的 'tn' 成员的值；
- *iat* - 'iat' PASSporT 声明的值；
- *orig* - 'orig' PASSporT 声明的 'tn' 成员的值；
- *origid* - 'origid' PASSporT 声明的值。


```c title="identity 使用示例"
...
	# 获取用于验证过程的证书
	$var(rc) = rest_get($identity(x5u), $var(cert));
	if ($var(rc) < 0) {
		send_reply(436, "Bad Identity Info");
		exit;
	}
	...
	xlog("已验证呼叫者：$identity(orig)，认证级别：$identity(attest)\n");
...

```


### 导出的 MI 函数


#### stir_shaken:ca_reload


替换已弃用的 MI 命令：*stir_shaken_ca_reload*。


重新加载包含验证者可信 CA 证书的文件
			以及包含验证者可信 CA 证书的目录。


名称：*stir_shaken:ca_reload*


参数：*无*


MI FIFO 命令格式：


```c
...
opensips-cli -x mi stir_shaken:ca_reload
"OK"
...
```


#### stir_shaken:crl_reload


替换已弃用的 MI 命令：*stir_shaken_crl_reload*。


重新加载包含验证者证书吊销列表（CRL）的文件
			以及包含验证者证书吊销列表的目录。


名称：*stir_shaken:crl_reload*


参数：*无*


MI FIFO 命令格式：


```c
...
opensips-cli -x mi stir_shaken:crl_reload
"OK"
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
