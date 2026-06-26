---
title: "Auth_AKA 模块"
description: "此模块包含用于使用 AKA（认证和密钥协商）安全协议执行摘要认证的函数。该机制在 IMS 网络中使用，用于在 UE（设备）和 3G/4G/5G 网络之间提供双向认证。"
---

## 管理指南

### 概述

此模块包含用于使用 AKA（认证和密钥协商）安全协议执行摘要认证的函数。该机制在 IMS 网络中使用，用于在 UE（设备）和 3G/4G/5G 网络之间提供双向认证。

AKA 协议建立一组称为认证向量（或 AV）的安全密钥，并使用它们来生成摘要挑战，以及计算摘要结果和对 UE 进行认证。AV 通过单独的通信通道交换。

虽然 AKA 协议还需要使用 AV 在 UE 和网络之间建立安全通道（通过 IPSec 隧道），但此模块不处理该部分——它只执行用户认证，并根据 *ETSI TS 129 229* 规范在 Authorization 头中传递加密和完整性密钥。这些密钥随后被其他组件（如 P-CSCF）获取以建立安全通道。

### 认证向量

认证向量（或 AV）由一组五个参数（RAND、AUTN、XRES、CK、IK）组成，用于双向认证。由于这些参数需要通过不同通道（即 LTE 网络中的 Diameter Cx 接口）在设备（UE）和网络之间交换，该模块不提供获取 AV 信息的方式。但是，它提供了一个通用接口（称为 AV 管理接口）来存储 AV（由其他模块/通道获取）、管理它们并在摘要认证算法中使用它们。

模块执行的基本 AV 操作：

- 请求为特定用户身份获取新的 AV
- 管理 AV 生命周期，包括重用
- 将 AV 标记为已在摘要挑战中使用
- 使 AV 无效或丢弃（由于各种原因）

实现 AV 管理接口（称为 AV 管理器）的模块应该能够获取 AV 的所有五个参数，并将它们推送到 AV 存储。

### 支持的算法

当前实现仅支持 AKAv1 算法，具有相关的哈希函数（如 MD5、SHA-256）。在挑战消息中，我们可以广告其他算法，但无法处理该模块中的响应，将返回适当的错误。

### 依赖

#### OpenSIPS 模块

该模块依赖以下模块（换句话说，列出的模块必须在此模块之前加载）：

- *auth* -- 认证框架
- *AV 管理模块* -- 至少一个模块用于获取 AV 并将它们推送到 AV 存储

#### 外部库或应用程序

该模块不依赖任何外部库。

### 导出的参数

#### default_av_mgm (string)

当函数未明确提供时使用的默认 AV 管理器。

```c title="default_av_mgm 参数用法"
	
modparam("auth_aka", "default_av_mgm", "diameter") # 通过 Cx 接口获取 AV
	
```

#### default_qop (string)

挑战期间使用的默认 qop 参数，如果函数未明确提供。

默认值为 *auth*。

```c title="default_qop 参数用法"
	
modparam("auth_aka", "default_qop", "auth,auth-int")
	
```

#### default_algorithm (string)

挑战期间广告的默认算法，如果函数未明确提供。

*请注意*，提供的算法中至少应有一种是 AKA 算法，否则使用此模块没有意义。

默认值为 *AKAv1-MD5*。

*警告：*目前仅支持 AKAv1* 算法。

```c title="default_algorithm 参数用法"
	
modparam("auth_aka", "default_algorithm", "AKAv2-MD5")
	
```

#### hash_size (integer)

存储每个用户的 AV 的哈希大小。必须是 2 的幂次方。

默认值为 *4096*。

```c title="hash_size 参数用法"
	
modparam("auth_aka", "hash_size", 1024)
	
```

#### sync_timeout (integer)

同步调用等待获取认证向量的毫秒数。

必须是正值。值为 *0* 表示无限等待。

默认值为 *100* 毫秒。

```c title="sync_timeout 参数用法"
	
modparam("auth_aka", "sync_timeout", 200)
	
```

#### async_timeout (integer)

异步调用等待获取认证向量的毫秒数。

必须是大于 0 的正值。

*注意：*当前超时机制只有秒级粒度，因此您应该将此参数配置为 1000 的倍数。

默认值为 *1000* 毫秒。

```c title="async_timeout 参数用法"
modparam("auth_aka", "async_timeout", 2000)
	
```

#### unused_timeout (integer)

未使用的认证向量可以在内存中停留的秒数。一旦达到此超时，认证向量将被移除。

必须是大于 0 的正值。

默认值为 *60* 秒。

```c title="unused_timeout 参数用法"
modparam("auth_aka", "unused_timeout", 120)
	
```

#### pending_timeout (integer)

在认证过程中使用的认证向量应留在内存中的秒数。一旦达到此超时，认证向量将被移除，使用它的认证将失败。

必须是大于 0 的正值。

默认值为 *30* 秒。

```c title="pending_timeout 参数用法"
modparam("auth_aka", "pending_timeout", 10)
	
```

### 导出的函数

#### aka_www_authorize([realm])

该函数根据 [RFC3310](http://www.ietf.org/rfc/rfc3310.txt) 使用先前由 `aka_www_challenge()` 调用分配的认证向量来验证凭证。如果凭证验证成功，函数将成功，否则将返回适当的错误代码：

- *-6（同步请求）* - 存在 *auts* 参数，因此请求了同步；
- *-5（通用错误）* - 发生某些通用错误，未发送回复；
- *-4（无凭证）* - 在请求中未找到凭证；
- *-3（未知 nonce）* - 未找到具有相应 nonce 的认证向量；
- *-2（密码无效）* - 密码与认证向量不匹配；
- *-1（用户名无效）* - 在 Authorize 头中未找到用户名；

如果函数成功，则 *WWW-Authenticate* 头将添加到回复中，包含挑战信息以及与所使用的 AV 关联的 *Integrity-Key* 和 *Confidentiality-Key* 值。

参数的含义如下：

- *realm (string)* - Realm 是一个不透明字符串，用户代理应将其呈现给用户，以便决定使用什么用户名和密码。这通常是代理负责的域之一。如果使用空字符串 ""，则服务器将从 From 头字段 URI 的主机部分生成 realm。

如果凭证验证成功，则函数将成功并标记凭证为已授权（标记的凭证稍后可被其他函数使用）。

此函数可以从 REQUEST_ROUTE 使用。

```c title="aka_www_authorize 用法"
	
...
if (!aka_www_authorize("diameter", "siphub.com"))
	aka_www_challenge("diameter", "siphub.com", "auth");
...
```

#### aka_proxy_authorize([realm])

该函数的行为与 [aka www authorize](#func_aka_www_authorize) 相同，但从代理角度对用户进行认证。它接收相同的参数，具有相同的含义，并返回相同的值。

此函数可以从 REQUEST_ROUTE 使用。

```c title="aka_proxy_authorize 用法"
	
...
if (!aka_proxy_authorize("siphub.com"))
	aka_proxy_challenge("diameter", "siphub.com", "auth");
...
```

#### aka_www_challenge([av_mgm[, realm[ ,qop[, alg]]]])

该函数对用户代理发起挑战。它通过 *av_mgm* 管理器获取每个算法使用的认证向量，并生成一个或多个包含摘要挑战的 WWW-Authenticate 头字段。它将把头字段放入服务器正在处理的请求生成的响应中并发送回复。收到此类回复后，用户代理应使用所使用的认证向量计算凭证并重试请求。有关摘要认证的更多信息，请参阅 RFC2617、RFC3261、RFC3310 和 RFC8760。

参数的含义如下：

- *av_mgm* (string，可选) - 用于此挑战的 AV 管理器，以防挑战用户身份的 AV 尚不可用。如果缺失，则使用[默认 av mgm](#param_default_av_mgm) 的值。
- *realm* (string) - Realm 是一个不透明字符串，用户代理应将其呈现给用户，以便决定使用什么用户名和密码。通常这是服务器运行所在主机的主机域。如果缺失，则使用 *From domain* 的值。
- *qop* (string，可选) - 此参数的值可以是 "auth"、"auth-int" 或两者（用 *,* 分隔）。设置此参数时，服务器将在挑战中放置 qop 参数。建议使用 qop 参数，但仍有一些用户代理无法正确处理 qop，因此我们将其设为可选。另一方面，仍有一些用户代理无法处理没有 qop 参数的请求。如果缺失，则使用[默认 qop](#param_default_qop) 的值。
- *algorithms* (string，可选) - 此参数的值是以逗号分隔的摘要算法列表，供 UAC 用于认证。可能的值为：
  - AKAv1-MD5
  - AKAv1-MD5-sess
  - AKAv1-SHA-256
  - AKAv1-SHA-256-sess
  - AKAv1-SHA-512-256
  - AKAv1-SHA-512-256-sess
  - AKAv2-MD5
  - AKAv2-MD5-sess
  - AKAv2-SHA-256
  - AKAv2-SHA-256-sess
  - AKAv2-SHA-512-256
  - AKAv2-SHA-512-256-sess

如果值为空或未设置，则使用[默认算法](#param_default_algorithm) 的值。

可能的返回码：

- *-1* - 通用解析错误，当没有足够数据构建挑战时生成
- *-2* - 无法获取 AV 向量
- *-3* - 无法构建认证头
- *-5* - 无法发送回复
- *正值* - 回复中发送的成功挑战数量；当等待某些 AV 超时时，此值可能低于请求的算法数量。

此函数可以从 REQUEST_ROUTE 使用。

```c title="aka_www_challenge 用法"
...
if (!aka_www_authorize("siphub.com")) {
	aka_www_challenge(,"siphub.com", "auth-int", "AKAv1-MD5");
}
...
```

#### aka_proxy_challenge([realm])

该函数的行为与 [aka www challenge](#func_aka_www_challenge) 相同，但从代理角度对用户发起挑战。它接收相同的参数，具有相同的含义，唯一的区别是当 *realm* 缺失时，从 *To domain* 获取，而不是从 *From domain*。添加的头是 *Proxy-Authenticate*，而不是 *WWW-Authenticate*。其余参数、行为以及返回值相同。

此函数可以从 REQUEST_ROUTE 使用。

```c title="aka_proxy_challenge 用法"
	
...
if (!aka_proxy_authorize("siphub.com"))
	aka_proxy_challenge(,"siphub.com", "auth");
...
```

#### aka_av_add(public_identity, private_identity, authenticate, authorize, confidentiality_key, integrity_key[, algorithms])

为由 *public_identity* 和 *private_identity* 标识的用户添加认证向量。

参数的含义如下：

- *public_identity* (string) - 要添加认证向量的用户的公共身份（IMPU）。
- *private_identity* (string) - 要添加认证向量的用户的私有身份（IMPI）。
- *authenticate* (string) - 认证挑战 RAND 和令牌 AUTN 的连接，以十六进制格式编码。
- *authorize* (string) - 用于授权用户的授权字符串（XRES），以十六进制格式编码。
- *confidentiality_key* (string) - AKA IPSec 过程中使用的 Confidentiality-Key，以十六进制格式编码。
- *integrity_key* (string) - AKA IPSec 过程中使用的 Integrity-Key，以十六进制格式编码。
- *algorithms* (string，可选) - 此 AV 应使用的 AKA 算法。如果缺失，AV 可用于任何 AKA 算法。

此函数可以从任何路由使用。

```c title="aka_av_add 用法"
	
...
aka_av_add("sip:test@siphub.com", "test@siphub.com",
		"KFQ/MpR3cE3V9PxucEQS5KED8uUNYIAALFyk59sIJI4=", /* authenticate */
			"00000262c0000014000028af2d6398cbe26eea69", /* authorize */
			"db7f8c4a58e17083974bba3b936d34c4", /* ck */
			"6151667b9ef815c1dcb87473685f062a"  /* ik */);
...
```

#### aka_av_drop(public_identity, private_identity, authenticate)

丢弃由 *authenticate/nonce* 值对应的认证向量，用于由 *public_identity* 和 *private_identity* 标识的用户。

参数的含义如下：

- *public_identity* (string) - 要丢弃认证向量的用户的公共身份（IMPU）。
- *private_identity* (string) - 要丢弃认证向量的用户的私有身份（IMPI）。
- *authenticate* (string) - 用于标识要丢弃的认证向量的 authenticate/nonce。

此函数可以从任何路由使用。

```c title="aka_av_drop 用法"
	
...
aka_av_drop("sip:test@siphub.com", "test@siphub.com",
		"KFQ/MpR3cE3V9PxucEQS5KED8uUNYIAALFyk59sIJI4=");
...
```

#### aka_av_drop_all(public_identity, private_identity[, count])

丢弃由 *public_identity* 和 *private_identity* 标识的用户的所有认证向量。当必须执行同步时，此函数很有用。

参数的含义如下：

- *public_identity* (string) - 要丢弃认证向量的用户的公共身份（IMPU）。
- *private_identity* (string) - 要丢弃认证向量的用户的私有身份（IMPI）。
- *count* (variable，可选) - 返回丢弃的认证向量数量的变量。

此函数可以从任何路由使用。

```c title="aka_av_drop_all 用法"
	
...
aka_av_drop_all("sip:test@siphub.com", "test@siphub.com", $var(count));
...
```

#### aka_av_fail(public_identity, private_identity[, count])

标记引擎获取用户的认证向量失败，解除消息处理的锁定。

*注意：*当您知道由于各种原因无法获取新的认证向量时，此函数很有用——调用它将恢复消息处理，仅使用到目前为止获取的可用 AV。

参数的含义如下：

- *public_identity* (string) - 要丢弃认证向量的用户的公共身份（IMPU）。
- *private_identity* (string) - 要丢弃认证向量的用户的私有身份（IMPI）。
- *count* (integer，可选) - 失败的认证向量数量。如果缺失，则视为 *1*。

此函数可以从任何路由使用。

```c title="aka_av_fail 用法"
...
aka_av_fail("sip:test@siphub.com", "test@siphub.com", 3);
...
```

### 导出的 MI 函数

#### auth_aka:av_add

替换已弃用的 MI 命令：*aka_av_add*。

通过 MI 接口添加认证向量。

参数：

- *public_identity* (string) - 要添加认证向量的用户的公共身份（IMPU）。
- *private_identity* (string) - 要添加认证向量的用户的私有身份（IMPI）。
- *authenticate* (string) - 认证挑战 RAND 和令牌 AUTN 的连接，以十六进制格式编码。
- *authorize* (string) - 用于授权用户的授权字符串（XRES），以十六进制格式编码。
- *confidentiality_key* (string) - AKA IPSec 过程中使用的 Confidentiality-Key，以十六进制格式编码。
- *integrity_key* (string) - AKA IPSec 过程中使用的 Integrity-Key，以十六进制格式编码。
- *algorithms* (string，可选) - 此 AV 应使用的 AKA 算法。如果缺失，AV 可用于任何 AKA 算法。

```c title="auth_aka:av_add 用法"
...
## 添加一个 AKA AV
$ opensips-cli -x mi auth_aka:av_add \
			sip:test@siphub.com
			test@siphub.com
			KFQ/MpR3cE3V9PxucEQS5KED8uUNYIAALFyk59sIJI4=
			00000262c0000014000028af2d6398cbe26eea69
			db7f8c4a58e17083974bba3b936d34c4
			6151667b9ef815c1dcb87473685f062a
...
			
```

#### auth_aka:av_drop

替换已弃用的 MI 命令：*aka_av_drop*。

使由其 authenticate 值标识的用户的认证向量无效。

参数：

- *public_identity* (string) - 要添加认证向量的用户的公共身份（IMPU）。
- *private_identity* (string) - 要添加认证向量的用户的私有身份（IMPI）。
- *authenticate* (string) - 用于标识认证向量的 authenticate/nonce。

```c title="auth_aka:av_drop 用法"
...
## 添加一个 AKA AV
$ opensips-cli -x mi auth_aka:av_drop \
			sip:test@siphub.com
			test@siphub.com
			KFQ/MpR3cE3V9PxucEQS5KED8uUNYIAALFyk59sIJI4=
...
			
```

#### auth_aka:av_drop_all

替换已弃用的 MI 命令：*aka_av_drop_all*。

通过 MI 接口使认证向量全部无效。

参数：

- *public_identity* (string) - 要丢弃认证向量的用户的公共身份（IMPU）。
- *private_identity* (string) - 要丢弃认证向量的用户的私有身份（IMPI）。

```c title="auth_aka:av_drop_all 用法"
...
## 添加一个 AKA AV
$ opensips-cli -x mi auth_aka:av_drop_all \
			sip:test@siphub.com
			test@siphub.com
...
			
```

#### auth_aka:av_fail

替换已弃用的 MI 命令：*aka_av_fail*。

表示获取认证向量失败，解除消息处理的锁定。

*注意：*当您知道由于各种原因无法获取新的认证向量时，此函数很有用——调用它将恢复消息处理，仅使用到目前为止获取的可用 AV。

参数：

- *public_identity* (string) - 要添加认证向量的用户的公共身份（IMPU）。
- *private_identity* (string) - 要添加认证向量的用户的私有身份（IMPI）。
- *count* (integer，可选) - 认证向量失败的数量。

```c title="aka_av_drop 用法"
...
## 添加一个 AKA AV
$ opensips-cli -x mi aka_av_drop \
			sip:test@siphub.com
			test@siphub.com
			KFQ/MpR3cE3V9PxucEQS5KED8uUNYIAALFyk59sIJI4=
...
			
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
