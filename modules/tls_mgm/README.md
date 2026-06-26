---
title: "TLS_MGM 模块"
description: "TLS_MGM 模块是 TLS 证书和参数的管理模块。它为所有使用 TLS 协议的模块提供接口。它还导出带有证书和 TLS 参数的伪变量。"
---

## 管理指南

### 概述

TLS_MGM 模块是 TLS 证书和参数的管理模块。它为所有使用 TLS 协议的模块提供接口。它还导出带有证书和 TLS 参数的伪变量。

### 使用

此模块用于为所有使用 TLS 传输的模块（如 *proto_tls* 或 *proto_wss*）配置 TLS 证书和参数。该模块支持多个虚拟域，可以分配给不同的监听器（服务器）或新连接（客户端）。每个使用此管理模块的 TLS 模块应将自己分配给一个或多个域。

该模块允许通过模块参数（脚本级别）和 SQL 表两种方式定义 TLS 域。

包含此模块使用详情的脚本示例可在 [tls 示例](#opensips_with_tls_script_example) 中找到。

### TLS 库

除了 TLS 证书和参数外，此模块还充当实际 TLS 实现（由 *openSSL* 或 *wolfSSL* 库提供）与传输协议模块（如 *proto_tls* 或 *proto_wss*）之间的接口。*tls_mgm* 模块透明地向高级 OpenSIPS 传输模块暴露由 *tls_openssl* 和 *tls_wolfssl* 模块实现的 TLS 操作。

TLS 库选择可以通过 [tls library](#param_tls_library) 模块参数进行配置。

### TLS 域

"TLS 域"这个术语意味着此 TLS 连接将具有与另一个 TLS 连接（来自另一个 TLS 域）不同的参数。因此，TLS 域与不同的 SIP 域没有直接关系，尽管它们经常结合使用。根据 TLS 握手的方向，TLS 域被称为"客户端域"（= 外出 TLS 连接）或"服务器域"（= 入站 TLS 连接）。

如果您运行多个 SIP 域，您可以分别为每个域指定一些参数（无论您在配置文件中只有一个还是多个 socket=tls:ip:port 条目）。

例如，TLS 域可用于 TLS 虚拟托管场景。OpenSIPS 为多个域提供 SIP 服务，例如 atlanta.com 和 biloxi.com。虽然两个域都将托管在单个 SIP 代理上，但 SIP 代理需要 2 个证书：一个用于 atlanta.com，一个用于 biloxi.com。对于入站 TLS 连接，SIP 代理需要在 TLS 握手期间呈现相应的证书。由于 SIP 代理还没有收到 SIP 消息（这是在 TLS 握手之后完成的），SIP 代理无法从 SIP 中检索目标域（通常是从请求 URI 中的域检索的）。因此，必须通过使用多个监听套接字或让客户端在握手过程中发送 Servername TLS 扩展（SNI）来区分这些域。

对于外出 TLS 连接，TLS 域是基于底层外出 TCP 连接的目标套接字和/或通过 AVP 在脚本级别做出决策来选择的。例如，您可以检查 RURI 或 From 等头，并将 SIP 头中的域与您为 TLS 域设置的过滤器进行匹配。

注意：除 tls_handshake_timeout 和 tls_send_timeout 外，所有 TLS 参数都可以按 TLS 域设置。

### 定义 TLS 域

TLS 域可以通过两种方式定义：

- 通过设置 *server_domain* 或 *client_domain* 模块参数
- 通过数据库配置

对于在数据库中定义的域，证书、私钥、受信任 CA 列表和 Diffie-Hellman 参数配置为 BLOB 值，而对于脚本定义的域，您必须提供文件路径。

您可以同时在数据库和脚本中定义域。

对于任何 TLS 域（通过脚本或数据库定义），如果没有另行指定，默认设置为：

- method - *SSLv23*
- verify_cert - *1*
- require_cert - *1*
- certificate - *CFG_DIR/tls/cert.pem*
- private_key - *CFG_DIR/tls/ckey.pem*
- crl_check_all - *0*
- crl_dir - 无
- ca_list - 无
- ca_dir - */etc/pki/CA/*
- cipher_list - OpenSSL 默认密码
- dh_params - 无
- ec_curve - 无

### 依赖

#### OpenSIPS 模块

以下模块必须在此模块之前加载：

- *tls_openssl* 或 *tls_wolfssl*，除非 [tls library](#param_tls_library) 设置为 'none'。

#### 外部库依赖

运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：

- *无*。

### 导出的函数

#### is_peer_verified

如果消息通过 TLS 接收且对等方在 TLS 连接握手期间被验证，则返回 1，否则返回 -1。

此函数可以从 REQUEST_ROUTE 使用。

```c title="is_peer_verified 使用示例"
...
if (is_peer_verified()) {
        xlog("L_INFO","request from verified TLS peer\n");
} else {
        xlog("L_INFO","request not verified\n");
}
...
```

### 导出的 MI 函数

#### tls_mgm:list

替换已弃用的 MI 命令：*tls_list*。

列出所有域信息。

#### tls_mgm:reload

替换已弃用的 MI 命令：*tls_reload*。

从数据库重新加载 TLS 域信息。前面的数据库定义的域被丢弃，但脚本定义的域被保留。

### 导出的参数

所有这些参数都可以从 opensips.cfg 文件中使用，以配置 OpenSIPS-TLS 的行为。

#### listen=interface

不是 TLS 特有的。允许指定协议（udp、tcp、tls）、IP 地址和监听服务器所在的端口。

```c title="设置 listen 变量"
...
socket= tls:1.2.3.4:5061
...
					
```

#### tls_library (string)

选择要使用的 TLS 库。可能的值有：

- *auto* - 自动检测加载了哪个 TLS 库模块（*tls_openssl* 或 *tls_wolfssl*）。如果找不到模块或两个模块都找到，OpenSIPS 将无法启动。
- *none* - 不使用任何 TLS 库；当 *tls_mgm* 模块仅由 *db_mysql*、*rabbitmq* 等模块需要用于 TLS 证书和参数管理时（而不是由 *proto_tls* 等传输模块进行 TLS 操作），这很有用。
- *openssl* - 通过 *tls_openssl* 模块使用 *openSSL* 库。
- *wolfssl* - 通过 *tls_wolfssl* 模块使用 *wolfSSL* 库。

默认值为 *auto*。

```c title="设置 tls_library 变量"
...
modparam("tls_mgm", "tls_library", "none")
...
					
```

#### tls_method ([domain]string)

设置 TLS 协议。域部分表示 TLS 域的名称。支持的 TLS 方法有：

- *TLSv1_3* - 表示 OpenSIPS 将仅接受 TLSv1.3 连接。此版本仅在 OpenSSL 1.1.1 版本及以上可用。
- *TLSv1_2* - 表示 OpenSIPS 将仅接受 TLSv1.2 连接（符合 rfc3261）。
- *TLSv1* - 表示 OpenSIPS 将仅接受 TLSv1 连接（符合 rfc3261）。
- *SSLv23* - 表示 OpenSIPS 将接受上述任何方法，但初始 SSL hello 必须为 v2（在初始 hello 中广告所有支持的协议，以便切换到更高和更安全的版本）。初始 v2 hello 意味着它不会接受来自仅支持 SSLv3 或 TLSv1 的客户端的连接。

*如果您使用的是高于 1.1.0 的 OpenSSL 库，您还可以指定接受的 TLS 版本范围作为 [VLOW]-[VHIGH]。如果未指定 VLOW，它将使用支持的最小协议版本；如果未指定 VHIGH，它将使用最大协议版本。这意味着使用低值和高值都缺失的范围将接受所有支持的方法，但与 SSLv23 不同，不需要初始 hello 为 SSLv2。*

*默认值为 SSLv23。*

> [!WARNING]
> 为与旧系统扩展兼容，最好使用 SSLv23。

如果您需要 RFC3261 一致性且您的所有客户端都支持 TLSv1（或您计划仅在不同 OpenSIPS 代理之间使用加密"隧道"），请使用 TLSv1。如果要支持较旧的客户端，请使用 SSLv23（实际上，大多数支持 SSL 的应用程序都使用 SSLv23 方法）。

```c title="设置 tls_method 变量"
...
modparam("tls_mgm", "tls_method", "[dom]TLSv1")
...
					
```

```c title="设置 tls_method 范围变量"
...
modparam("tls_mgm", "tls_method", "[dom]TLSv1-TLSv1_3")  # v1 到 v1.3 之间
modparam("tls_mgm", "tls_method", "[dom]TLSv1-")         # v1 或更高
modparam("tls_mgm", "tls_method", "[dom]-TLSv1_2")       # 最高 v1.2
modparam("tls_mgm", "tls_method", "[dom]-")              # 所有支持
...
					
```

#### certificate ([domain](string)

OpenSIPS 的公钥证书文件。它将用作入站 TLS 连接的服务器端证书，以及外出 TLS 连接的客户端证书。域部分表示 TLS 域的名称。

*默认值为 "CFG_DIR/tls/cert.pem"。*

```c title="设置 certificate 变量"
...
modparam("tls_mgm", "certificate", "[dom]/mycerts/certs/opensips_server_cert.pem")
...
					
```

#### private_key ([domain](string)

上述证书的私钥。我必须保存在安全的地方并保持严格的权限！域部分表示 TLS 域的名称。

*默认值为 "CFG_DIR/tls/ckey.pem"。*

```c title="设置 private_key 变量"
...
modparam("tls_mgm", "private_key", "[dom]/mycerts/private/prik.pem")
...
					
```

#### ca_list ([domain](string)

受信任 CA 的列表。该文件包含接受的证书，一个接一个。它必须是文件，不是文件夹。域部分表示 TLS 域的名称。

*默认值为 ""。*

```c title="设置 ca_list 变量"
...
modparam("tls_mgm", "ca_list", "[dom]/mycerts/certs/ca_list.pem")
...
					
```

#### ca_dir ([domain](string)

存储受信任 CA 的目录。目录中的证书必须以哈希形式存储，如 [openssl 文档](https://www.openssl.org/docs/manmaster/man3/X509_LOOKUP_hash_dir.html) 中所述的"哈希目录方法"。域部分表示 TLS 域的名称。

*默认值为 "/etc/pki/CA/"。*

```c title="设置 ca_dir 变量"
...
modparam("tls_mgm", "ca_dir", "[dom]/mycerts/certs")
...
					
```

#### crl_dir ([domain](string)

存储证书吊销列表（CRL）的目录。域部分表示 TLS 域的名称。

*如果未设置此参数，则不会使用 CRL。*

```c title="设置 crl_dir 变量"
...
modparam("tls_mgm", "crl_dir", "[dom]/mycerts/crls")
...
					
```

#### crl_check_all ([domain](string)

使用非零整数值设置此参数可为整个证书链启用 CRL 检查。

*默认情况下，仅检查证书链中的叶证书。*

```c title="设置 crl_check_all 变量"
...
modparam("tls_mgm", "crl_check_all", "[dom]1")
...
					
```

#### ciphers_list ([domain](string)

您可以指定允许的认证和加密算法列表。域部分表示 TLS 域的名称。要获取密码列表然后选择，请使用 openssl 应用程序：

- openssl ciphers 'ALL:eNULL:!LOW:!EXPORT'

> [!WARNING]
> 不要使用 NULL 算法（无加密）... 仅用于测试！！！

*默认为 OpenSSL 默认密码。*

```c title="设置 ciphers_list 变量"
...
modparam("tls_mgm", "ciphers_list", "[dom]NULL")
...
					
```

#### dh_params ([domain](string)

您可以指定包含 PEM 文件格式的 Diffie-Hellman 参数的文件。如果您想指定包含 Diffie-Hellman 模式的密码，则需要此文件。域部分表示 TLS 域的名称。

*默认不设置 dh 参数文件。*

```c title="设置 dh_params 变量"
...
modparam("tls_mgm", "dh_params", "[dom]/etc/pki/CA/dh1024.pem")
...
					
```

#### ec_curve ([domain](string)

您可以指定应用于需要椭圆曲线的密码的椭圆曲线。域部分表示 TLS 域的名称。

它仅在编译了 TLS v1.1/1.2 支持时才可用。您可以获取可使用的曲线列表

```c
				openssl ecparam -list_curves
			
```

*默认不设置椭圆曲线。*

#### verify_cert ([domain](string)

在 ssl_context 中激活 SSL_VERIFY_PEER。详细解释，请查看 *openssl* 文档。

域部分表示 TLS 域的名称。

默认值为 *1*。

```c title="设置 verify_cert 变量"
...
modparam("tls_mgm", "verify_cert", "[dom]0")
...
					
```

#### require_cert ([domain](string)

在 ssl_context 中激活 SSL_VERIFY_FAIL_IF_NO_PEER_CERT。详细解释，请查看 *openssl* 文档。此参数仅对服务器域有意义，并且如果 also 设置了 [verify cert](#param_verify_cert) 参数。

域部分表示 TLS 域的名称。

默认值为 *1*。

```c title="设置 require_cert 变量"
...
modparam("tls_mgm", "require_cert", "[dom]0")
...
					
```

#### client_tls_domain_avp (string)

用于强制选择特定 TLS 客户端域的 AVP 名称。将此 AVP 设置为 TLS 客户端域的名称将导致使用该特定域，而不管标准匹配机制如何。

注意：如果已存在到远程目标的 TLS 连接，它将被重用，设置此 AVP 无效。

注意：您可以通过设置具有相同名称的 *$bavp* 变量来强制仅对特定分支使用特定域。当同时设置 *$bavp* 和 *$avp* 变量时，第一个优先。

*无默认值。*

```c title="设置 client_tls_domain_avp 变量"
...
modparam("tls_mgm", "client_tls_domain_avp", "tls_match_dom")
...
					
```

#### client_sip_domain_avp (string)

在 TLS 客户端域匹配过程中设置所用 SIP 域的 AVP 名称。

注意：如果已存在到远程目标的 TLS 连接，它将被重用，设置此 AVP 无效。

注意：您可以通过设置具有相同名称的 *$bavp* 变量来强制仅对特定分支使用特定 SIP 域。当同时设置 *$bavp* 和 *$avp* 变量时，第一个优先。

有关 AVP 使用示例，请参阅 [domains param](#param_server_domain_client_domain)。

*无默认值。*

```c title="设置 client_sip_domain_avp 变量"
...
modparam("tls_mgm", "client_sip_domain_avp", "sip_match_dom")
...
					
```

#### db_url (string)

数据库 URL。它不能为 NULL。

您不能将 "tls_domain=*dom_name*" URL 参数用于 tls_mgm 模块本身的数据库 TLS 连接。

```c title="db_url 使用示例"
modparam("tls_mgm", "db_url", "mysql://root:admin@localhost/opensips")
					
```

#### db_table (string)

设置数据库表名。

默认值为 "tls_mgm"。

```c title="db_table 使用示例"
modparam("tls_mgm", "db_table", "tls_mgm")
                                
```

#### domain_col (string)

设置 TLS 域列的名称。

默认值为 "domain"。

```c title="domain_col 使用示例"
modparam("tls_mgm", "domain_col", "tls_domain")
                                
```

#### match_ip_address_col (string)

设置 IP 地址匹配列名称。

默认值为 "match_ip_address"。

```c title="match_ip_address_col 使用示例"
modparam("tls_mgm", "match_ip_address_col", "addr")
                                
```

#### match_sip_domain_col (string)

设置 SIP 域匹配列名称。

默认值为 "match_sip_domain"。

```c title="match_sip_domain_col 使用示例"
modparam("tls_mgm", "match_sip_domain_col", "addr")
                                
```

#### tls_method_col (string)

设置方法列名称。

默认值为 "method"。

```c title="tls_method_col 使用示例"
modparam("tls_mgm", "tls_method_col", "method")
                                
```

#### verify_cert_col (string)

设置验证证书列名称。

默认值为 "verify_cert"。

```c title="vertify_cert_col 使用示例"
modparam("tls_mgm", "verify_cert_col", "verify_cert")
                                
```

#### require_cert_col (string)

设置需要证书列名称。

默认值为 "require_cert"。

```c title="require_cert_col 使用示例"
modparam("tls_mgm", "require_cert_col", "req")
                                
```

#### certificate_col (string)

设置证书列名称。

默认值为 "certificate"。

```c title="certificate_col 使用示例"
modparam("tls_mgm", "certificate_col", "certificate")
                                
```

#### private_key_col (string)

设置私钥列名称。

默认值为 "private_key"。

```c title="private_key_col 使用示例"
modparam("tls_mgm", "private_key_col", "pk")
                                
```

#### crl_check_all_col (string)

设置 crl_check_all 列名称。

默认值为 "crl_check_all"。

```c title="crl_check_all_col 使用示例"
modparam("tls_mgm", "crl_check_all_col", "crl_check")
                                
```

#### crl_dir_col (string)

设置 crl 目录列名称。

默认值为 "crl_dir"。

```c title="crl_dir_col 使用示例"
modparam("tls_mgm", "crl_dir_col", "crl_dir")
                                
```

#### ca_list_col (string)

设置 CA 列表列名称。

默认值为 "ca_list"。

```c title="ca_list_col 使用示例"
modparam("tls_mgm", "ca_list_col", "ca_list")
                                
```

#### ca_dir_col (string)

设置 CA 目录列名称。

默认值为 "ca_dir"。

```c title="ca_dir_col 使用示例"
modparam("tls_mgm", "ca_dir_col", "ca_dir")
                                
```

#### cipher_list_col (string)

设置密码列表列名称。

默认值为 "cipher_list"。

```c title="cipher_list_col 使用示例"
modparam("tls_mgm", "cipher_list_col", "cipher_list")
                                
```

#### dh_params_col (string)

设置 Diffie-Hellmann 参数列名称。

默认值为 "dh_params"。

```c title="dh_params_col 使用示例"
modparam("tls_mgm", "dh_params_col", "dh_parms")
                                
```

#### ec_curve_col (string)

设置 ec_curve 列名称。

默认值为 "ec_curve"。

```c title="ec_curve_col 使用示例"
modparam("tls_mgm", "ec_curve_col", "ec_curve")
                                
```

#### match_ip_address (string)

用于将 TLS 连接与虚拟 TLS 域匹配的 IP 地址和端口。对于 TLS 服务器域，这些值将与接收连接的套接字进行匹配。对于 TLS 客户端域，这些值将与连接的目标套接字进行比较。

该参数接受值列表，特殊值 "*" 表示：匹配任何地址。

*默认值为 "*"（匹配任何地址）。*

```c title="设置 match_ip_address 变量"
...
modparam("tls_mgm", "match_ip_address", "[dom1]10.0.0.10:5061, 10.0.0.11:5061")
...
					
```

#### match_sip_domain (string)

用于将 TLS 连接与虚拟 TLS 域匹配的 SIP 域。对于 TLS 服务器域，这些值将与 TLS Servername 扩展（SNI）中提供的主机名进行匹配。对于 TLS 客户端域，这些值将与 [client sip domain avp](#param_client_sip_domain_avp) AVP 的值进行比较。

该参数接受 FQDN 列表或特殊值：

- *** - 匹配任何 sip 域（包括未提供 SNI 的情况，用于 TLS 服务器域）；
- *none* - 当没有提供 SNI 时匹配 TLS 域（仅对 TLS 服务器域有意义）。请注意，如果提供了 SNI 但不匹配任何其他 SIP 域过滤器，连接将被拒绝。

FQDN 可以使用 Unix shell 风格通配符指定。如果有多个潜在匹配，将选择最具体的域（例如，对 "foo.bar.com" 的请求将与使用 "foo.bar.com" 指定的域匹配，而不是与使用 "*.bar.com" 的域匹配）。

*默认值为 "*"（匹配任何 sip 域）。*

```c title="设置 match_sip_domain 变量"
...
modparam("tls_mgm", "match_sip_domain", "[dom1]foo.com, bar.com, *.baz.com")
modparam("tls_mgm", "match_sip_domain", "[default_dom]*")
...
					
```

#### server_domain, client_domain (string)

您可以通过这些参数定义虚拟 TLS 域。

这些参数的值表示虚拟 tls 域的名称，仅用于标识。

```c title="tls_client_domain 和 tls_server_domain 块使用示例"
...
socket=tls:10.0.0.10:5061
...
# 设置 TLS 客户端域 AVP
modparam("tls_mgm", "client_sip_domain_avp", "tls_sip_dom")
...

# 'atlanta' 服务器域
modparam("tls_mgm", "server_domain", "dom1")
modparam("tls_mgm", "match_ip_address", "[dom1]10.0.0.10:5061")
modparam("tls_mgm", "match_sip_domain", "[dom1]atlanta.com")

modparam("tls_mgm", "certificate", "[dom1]/certs/atlanta.com/cert.pem")
modparam("tls_mgm", "private_key", "[dom1]/certs/atlanta.com/privkey.pem")
modparam("tls_mgm", "ca_list", "[dom1]/certs/wellknownCAs")
modparam("tls_mgm", "tls_method", "[dom1]tlsv1")
modparam("tls_mgm", "verify_cert", "[dom1]1")
modparam("tls_mgm", "require_cert", "[dom1]1")

#'biloxi' 服务器域
modparam("tls_mgm", "server_domain", "dom2")
modparam("tls_mgm", "match_ip_address", "[dom2]10.0.0.10:5061")
modparam("tls_mgm", "match_sip_domain", "[dom2]biloxi.com")

modparam("tls_mgm", "certificate", "[dom2]/certs/biloxi.com/cert.pem")
modparam("tls_mgm", "private_key", "[dom2]/certs/biloxi.com/privkey.pem")
modparam("tls_mgm", "ca_list", "[dom2]/certs/wellknownCAs")
modparam("tls_mgm", "tls_method", "[dom2]tlsv1")
modparam("tls_mgm", "verify_cert", "[dom2]1")
modparam("tls_mgm", "require_cert", "[dom2]1")

# 通用 TLS 服务器域，如果客户端不提供 SNI
modparam("tls_mgm", "server_domain", "dom3")
modparam("tls_mgm", "match_ip_address", "[dom3]10.0.0.10:5061")
modparam("tls_mgm", "match_sip_domain", "[dom3]none")

modparam("tls_mgm", "certificate", "[dom3]/certs/generic/cert.pem")
modparam("tls_mgm", "private_key", "[dom3]/certs/generic/privkey.pem")
modparam("tls_mgm", "ca_list", "[dom3]/certs/wellknownCAs")
modparam("tls_mgm", "tls_method", "[dom3]tlsv1")
modparam("tls_mgm", "verify_cert", "[dom3]1")
modparam("tls_mgm", "require_cert", "[dom3]1")

# 'atlanta' 客户端域
modparam("tls_mgm", "client_domain", "dom4")
modparam("tls_mgm", "match_ip_address", "[dom4]*")
modparam("tls_mgm", "match_sip_domain", "[dom4]atlanta.com")


modparam("tls_mgm", "certificate", "[dom4]/certs/atlanta.com/cert.pem")
modparam("tls_mgm", "private_key", "[dom4]/certs/atlanta.com/privkey.pem")
modparam("tls_mgm", "ca_list", "[dom4]/certs/wellknownCAs")
modparam("tls_mgm", "tls_method", "[dom4]tlsv1")
modparam("tls_mgm", "verify_cert", "[dom4]1")
modparam("tls_mgm", "require_cert", "[dom4]1")

# 'biloxi' 客户端域
modparam("tls_mgm", "client_domain", "dom5")
modparam("tls_mgm", "match_ip_address", "[dom5]*")
modparam("tls_mgm", "match_sip_domain", "[dom5]biloxi.com")

modparam("tls_mgm", "certificate", "[dom5]/certs/biloxi.com/cert.pem")
modparam("tls_mgm", "private_key", "[dom5]/certs/biloxi.com/privkey.pem")
modparam("tls_mgm", "ca_list", "[dom5]/certs/wellknownCAs")
modparam("tls_mgm", "tls_method", "[dom5]tlsv1")
modparam("tls_mgm", "verify_cert", "[dom5]1")
modparam("tls_mgm", "require_cert", "[dom5]1")

# GW 提供商的 TLS 客户端域
modparam("tls_mgm", "client_domain", "dom6")
modparam("tls_mgm", "match_ip_address", "[dom6]1.2.3.4:6677")
modparam("tls_mgm", "match_sip_domain", "[dom6]*")

modparam("tls_mgm", "certificate", "[dom6]/certs/gw/cert.pem")
modparam("tls_mgm", "private_key", "[dom6]/certs/gw/privkey.pem")
modparam("tls_mgm", "ca_list", "[dom6]/certs/wellknownCAs")
modparam("tls_mgm", "tls_method", "[dom6]tlsv1")
modparam("tls_mgm", "verify_cert", "[dom6]0")

...
route{
...
    # 我们使用 RURI 中的 SIP 域匹配 TLS 客户端域
    $avp(tls_sip_dom) = $rd;
    t_relay();
    exit;
...
    # 到 PSTN GW 的呼叫，将通过 IP 匹配正确的 TLS 域
    t_relay("tls:1.2.3.4:6677");
    exit;
...
					
```

### 变量

此模块导出以下变量：

某些变量可用于对等方的证书和本地证书。此外，某些参数可以从"Subject"字段或"Issuer"字段读取。

#### $tls_version

*$tls_version* - 用于接收消息的 TLS 连接的 TLS/SSL 版本。字符串类型。

#### $tls_description

*$tls_description* - 用于接收消息的 TLS 连接的 TLS/SSL 描述。字符串类型。

#### $tls_cipher_info

*$tls_cipher_info* - 用于接收消息的 TLS 连接的 TLS/SSL 密码。字符串类型。

#### $tls_cipher_bits

*$tls_cipher_bits* - 用于接收消息的 TLS 连接的密码位数。字符串和整数类型。

#### $tls_[peer|my]_version

*$tls_[peer|my]_version* - 证书的版本。字符串类型。

#### $tls_[peer|my]_serial

*$tls_[peer|my]_serial* - 证书的序列号。字符串和整数类型。

#### $tls_[peer|my]_[subject|issuer]

*$tls_[peer|my]_[subject|issuer]* - 证书中 issuer/subject 字段的 ASCII 转储。字符串类型。

```c title="$tls_[peer|my]_[subject|issuer] 示例"
/C=AT/ST=Vienna/L=Vienna/O=enum.at/CN=enum.at
```

#### $tls_[peer|my]_[subject|issuer]_cn

*$tls_[peer|my]_[subject|issuer]_cn* - 证书 issuer/subject 部分中的 commonName。字符串类型。

#### $tls_[peer|my]_[subject|issuer]_locality

*$tls_[peer|my]_[subject|issuer]_locality* - 证书 issuer/subject 部分中的 localityName。字符串类型。

#### $tls_[peer|my]_[subject|issuer]_country

*$tls_[peer|my]_[subject|issuer]_country* - 证书 issuer/subject 部分中的 countryName。字符串类型。

#### $tls_[peer|my]_[subject|issuer]_state

*$tls_[peer|my]_[subject|issuer]_state* - 证书 issuer/subject 部分中的 stateOrProvinceName。字符串类型。

#### $tls_[peer|my]_[subject|issuer]_organization

*$tls_[peer|my]_[subject|issuer]_organization* - 证书 issuer/subject 部分中的 organizationName。字符串类型。

#### $tls_[peer|my]_[subject|issuer]_unit

*$tls_[peer|my]_[subject|issuer]_unit* - 证书 issuer/subject 部分中的 organizationalUnitName。字符串类型。

#### $tls_[peer|my]_san_email

*$tls_[peer|my]_san_email* - 证书中"subject alternative name"扩展的电子邮件地址。字符串类型。

#### $tls_[peer|my]_san_hostname

*$tls_[peer|my]_san_hostname* - 证书中"subject alternative name"扩展的主机名（DNS）。字符串类型。

#### $tls_[peer|my]_san_uri

*$tls_[peer|my]_san_uri* - 证书中"subject alternative name"扩展的 URI。字符串类型。

#### $tls_[peer|my]_san_ip

*$tls_[peer|my]_san_ip* - 证书中"subject alternative name"扩展的 IP 地址。字符串类型。

#### $tls_peer_verified

*$tls_peer_verified* - 如果对等方证书验证成功，返回 1。否则返回 0。字符串和整数类型。

#### $tls_peer_revoked

*$tls_peer_revoked* - 如果对等方证书被吊销，返回 1。否则返回 0。字符串和整数类型。

#### $tls_peer_expired

*$tls_peer_expired* - 如果对等方证书已过期，返回 1。否则返回 0。字符串和整数类型。

#### $tls_peer_selfsigned

*$tls_peer_selfsigned* - 如果对等方证书是自签名的，返回 1。否则返回 0。字符串和整数类型。

#### $tls_peer_notBefore

*$tls_peer_notBefore* - 返回对等方证书的 notBefore 有效期。字符串类型。

#### $tls_peer_notAfter

*$tls_peer_notAfter* - 返回对等方证书的 notAfter 有效期。字符串类型。

### 带有 TLS 的 OpenSIPS - 脚本示例

重要提示：TLS 支持基于 TCP，要允许 OpenSIPS 使用 TCP，它必须以多进程模式启动。因此，必须将"fork"参数设置为"yes"：

注意：由于 TLS 引擎非常消耗内存，请通过运行时参数"-m"增加使用的内存（请参阅 OpenSIPS -h 了解更多详细信息）。

- fork = yes

```c title="带 TLS 支持的脚本"
  # ----------- 全局配置参数 ------------------------
  log_level=3
  stderror_enabled=no
  syslog_enabled=yes

  check_via=no
  dns=no
  rev_dns=no
  socket=udp:your_serv_IP:5060
  socket=tls:your_serv_IP:5061
  udp_workers=4

  # ------------------ 模块加载 ----------------------------------

  loadmodule "proto_tls.so"
  loadmodule "proto_udp.so"

  #TLS 特定设置
  loadmodule "tls_mgm.so"

  modparam("tls_mgm", "certificate", "/path/opensipsX_cert.pem")
  modparam("tls_mgm", "private_key", "/path/privkey.pem")
  modparam("tls_mgm", "ca_list", "/path/calist.pem")
  modparam("tls_mgm", "ca_list", "/path/calist.pem")
  modparam("tls_mgm", "require_cert", "1")
  modparam("tls_mgm", "verify_cert", "1")

  alias=_DNS_ALIAS_


  loadmodule "sl.so"
  loadmodule "rr.so"
  loadmodule "maxfwd.so"
  loadmodule "mysql.so"
  loadmodule "usrloc.so"
  loadmodule "registrar.so"
  loadmodule "tm.so"
  loadmodule "auth.so"
  loadmodule "auth_db.so"
  loadmodule "textops.so"
  loadmodule "sipmsgops.so"
  loadmodule "signaling.so"
  loadmodule "uri_db.so"

  # ----------------- 设置模块特定参数 ---------------

  # -- auth_db 参数 --
  modparam("auth_db", "db_url", "sql_url")
  modparam("auth_db", "password_column", "password")
  modparam("auth_db", "calculate_ha1", 1)

  # -- registrar 参数 --
  # 不允许多重注册
  modparam("registrar", "append_branches", 0)

  # ------------------------- 请求路由逻辑 -------------------

  # 主要路由逻辑

  route{

  # 初始完整性检查
  if (!mf_process_maxfwd_header("10")) {
      send_reply(483,"Too Many Hops");
      exit;
  };

  # 如果有人在 From 中声称属于我们的域，
  # 质询他（跳过 REGISTER -- 我们稍后会质询他们）
  if (is_myself("$fd")) {
      setflag(1);
      if ( is_method("INVITE|SUBSCRIBE|MESSAGE")
      && !(is_myself("$si")) ) {
          if  (!(proxy_authorize( "domA.net", "subscriber" ))) {
              proxy_challenge("domA.net","0"/*no-qop*/);
              exit;
          };
          if ($au!=$fU) {
              xlog("FROM 头 INVITE 中的欺骗尝试\n");
              send_reply(403,
                  "That is ugly -- use From=id next time (OB)");
              exit;
          };
      }; # 来自其他域的非 REGISTER
  } else if ( is_method("INVITE") && !is_myself("$rd") ) {
      send_reply(403, "No relaying");
      exit;
  };

  /* ******** 执行 record-route 和 loose-route ******* */
  if (!is_method("REGISTER"))
      record_route();

  if (loose_route()) {
      append_hf("P-hint: rr-enforced\r\n");
      t_relay();
      exit;
  };

  /* ******* 检查针对我们域外的请求 ******* */
  if ( !is_myself("$rd") ) {
      append_hf("P-hint: OUTBOUND\r\n");
      if ($rd=="domB.net") {
          t_relay("tls:domB.net:5061");
      } else if ($rd=="domC.net") {
          t_relay("tls:domC.net:5061");
      } else {
          t_relay();
      };
      exit;
  };

  /* ******* 根据前缀将请求分流到其他域 ******* */
  if (!is_method("REGISTER")) {
      if ( $ru=~"sip:201") {
          strip(3);
          $rd = "domB.net";
          t_relay("tls:domB.net:5061");
          exit;
      } else if ( $ru=~"sip:202" ) {
          strip(3);
          $rd = "domC.net";
          t_relay("tls:domC.net:5061");
          exit;
      };
  };

  /* ************ 我们域的请求 ********** */
  if (is_method("REGISTER")) {
      if (!www_authorize( "domA.net", "subscriber" )) {
          # 如果没有或凭证无效则质询
          www_challenge( "domA.net" /* realm */,
              "0" /* no qop -- 有些电话不能处理它 */);
          exit;
      };
      if ($au!=$tU) {
          xlog("TO 头欺骗尝试\n");
          send_reply(403, "That is ugly -- use To=id in REGISTERs");
          exit;
      };
      # 这是一个经过认证的请求，立即更新联系人数据库
      if (!save("location")) {
          sl_reply_error();
      };
      exit;
  };

  # 使用 USRLOC DB 处理本机 SIP 目的地
  if (!lookup("location")) {
      # 处理未找到的用户
      send_reply(404, "Not Found");
      exit;
  };

  # 删除所有现有的 Alert-info 头
  remove_hf("Alert-Info");

  if (is_method("INVITE") && ($rP=="TLS" || isflagset(1))) {
      append_hf("Alert-info: 1\r\n");                     # cisco 7960
      append_hf("Alert-info: Bellcore-dr4\r\n");          # cisco ATA
      append_hf("Alert-info: http://foo.bar/x.wav\r\n");  # snom
  };

  # 执行转发
  if (!t_relay()) {
      sl_reply_error();
  };

  # 脚本结束
  }
			
```

### 调试 TLS 连接

如果要调试 TLS 连接，请将以下日志语句放入您的 OpenSIPS.cfg 中。这将转储所有可用的 TLS 伪变量。

```c title="TLS 日志记录示例"
xlog("L_INFO","================= start TLS pseudo variables ===============\n");
xlog("L_INFO","$$tls_version                   = '$tls_version'\n");
xlog("L_INFO","$$tls_description               = '$tls_description'\n");
xlog("L_INFO","$$tls_cipher_info               = '$tls_cipher_info'\n");
xlog("L_INFO","$$tls_cipher_bits               = '$tls_cipher_bits'\n");
xlog("L_INFO","$$tls_peer_subject              = '$tls_peer_subject'\n");
xlog("L_INFO","$$tls_peer_issuer               = '$tls_peer_issuer'\n");
xlog("L_INFO","$$tls_my_subject                = '$tls_my_subject'\n");
xlog("L_INFO","$$tls_my_issuer                 = '$tls_my_issuer'\n");
xlog("L_INFO","$$tls_peer_version              = '$tls_peer_version'\n");
xlog("L_INFO","$$tls_my_version                = '$tls_my_version'\n");
xlog("L_INFO","$$tls_peer_serial               = '$tls_peer_serial'\n");
xlog("L_INFO","$$tls_my_serial                 = '$tls_my_serial'\n");
xlog("L_INFO","$$tls_peer_subject_cn           = '$tls_peer_subject_cn'\n");
xlog("L_INFO","$$tls_peer_issuer_cn            = '$tls_peer_issuer_cn'\n");
xlog("L_INFO","$$tls_my_subject_cn             = '$tls_my_subject_cn'\n");
xlog("L_INFO","$$tls_my_issuer_cn              = '$tls_my_issuer_cn'\n");
xlog("L_INFO","$$tls_peer_subject_locality     = '$tls_peer_subject_locality'\n");
xlog("L_INFO","$$tls_peer_issuer_locality      = '$tls_peer_issuer_locality'\n");
xlog("L_INFO","$$tls_my_subject_locality       = '$tls_my_subject_locality'\n");
xlog("L_INFO","$$tls_my_issuer_locality        = '$tls_my_issuer_locality'\n");
xlog("L_INFO","$$tls_peer_subject_country      = '$tls_peer_subject_country'\n");
xlog("L_INFO","$$tls_peer_issuer_country       = '$tls_peer_issuer_country'\n");
xlog("L_INFO","$$tls_my_subject_country        = '$tls_my_subject_country'\n");
xlog("L_INFO","$$tls_my_issuer_country         = '$tls_my_issuer_country'\n");
xlog("L_INFO","$$tls_peer_subject_state        = '$tls_peer_subject_state'\n");
xlog("L_INFO","$$tls_peer_issuer_state         = '$tls_peer_issuer_state'\n");
xlog("L_INFO","$$tls_my_subject_state          = '$tls_my_subject_state'\n");
xlog("L_INFO","$$tls_my_issuer_state           = '$tls_my_issuer_state'\n");
xlog("L_INFO","$$tls_peer_subject_organization = '$tls_peer_subject_organization'\n");
xlog("L_INFO","$$tls_peer_issuer_organization  = '$tls_peer_issuer_organization'\n");
xlog("L_INFO","$$tls_my_subject_organization   = '$tls_my_subject_organization'\n");
xlog("L_INFO","$$tls_my_issuer_organization    = '$tls_my_issuer_organization'\n");
xlog("L_INFO","$$tls_peer_subject_unit         = '$tls_peer_subject_unit'\n");
xlog("L_INFO","$$tls_peer_issuer_unit          = '$tls_peer_issuer_unit'\n");
xlog("L_INFO","$$tls_my_subject_unit           = '$tls_my_subject_unit'\n");
xlog("L_INFO","$$tls_my_issuer_unit            = '$tls_my_issuer_unit'\n");
xlog("L_INFO","$$tls_peer_san_email            = '$tls_peer_san_email'\n");
xlog("L_INFO","$$tls_my_san_email              = '$tls_my_san_email'\n");
xlog("L_INFO","$$tls_peer_san_hostname         = '$tls_peer_san_hostname'\n");
xlog("L_INFO","$$tls_my_san_hostname           = '$tls_my_san_hostname'\n");
xlog("L_INFO","$$tls_peer_san_uri              = '$tls_peer_san_uri'\n");
xlog("L_INFO","$$tls_my_san_uri                = '$tls_my_san_uri'\n");
xlog("L_INFO","$$tls_peer_san_ip               = '$tls_peer_san_ip'\n");
xlog("L_INFO","$$tls_my_san_ip                 = '$tls_my_san_ip'\n");
xlog("L_INFO","$$tls_peer_verified             = '$tls_peer_verified'\n");
xlog("L_INFO","$$tls_peer_revoked              = '$tls_peer_revoked'\n");
xlog("L_INFO","$$tls_peer_expired              = '$tls_peer_expired'\n");
xlog("L_INFO","$$tls_peer_selfsigned           = '$tls_peer_selfsigned'\n");
xlog("L_INFO","$$tls_peer_notBefore            = '$tls_peer_notBefore'\n");
xlog("L_INFO","$$tls_peer_notAfter             = '$tls_peer_notAfter'\n");
xlog("L_INFO","================= end TLS pseudo variables ===============\n");
```

## 开发者指南

### API 函数

#### find_server_domain

struct tls_domain *find_server_domain(struct ip_addr *ip,
                    unsigned short port);

查找具有给定 ip 和端口的 TLS 服务器域（本地监听套接字）。

#### find_client_domain

struct tls_domain *find_client_domain(struct ip_addr *ip,
                     unsigned short port);

查找 TLS 客户端域。

#### get_handshake_timeout

int get_handshake_timeout(void);

返回握手超时。

#### get_send_timeout

int get_send_timeout(void);

返回发送超时。

### TLS_CONFIG

它包含 OpenSIPS 的 TLS 配置变量（超时、文件路径等）。

### TLS_INIT

初始化相关的函数和参数。

#### ssl context

extern SSL_CTX *default_client_ctx;

ssl context 是 TLS 域结构的成员。因此，每个 TLS 域、默认和虚拟 - 服务器和客户端，都有其自己的 SSL 上下文。

#### pre_init_tls

int init_tls(void);

从 main() 调用一次以预初始化 tls 子系统。在解析配置文件之前调用。

#### init_tls

int init_tls(void);

从 main() 调用一次以初始化 tls 子系统。在解析配置文件之后调用。

#### destroy_tls

void destroy_tls(void);

调用一次，就在清理之前。

#### tls_init

int tls_init(struct socket_info *c);

从 main.c 为每个创建的 tls 套接字调用一次。

### TLS_DOMAIN

#### tls_domains

extern struct tls_domain *tls_default_server_domain;

默认 TLS 服务器域。

extern struct tls_domain *tls_default_client_domain;

默认 TLS 客户端域。

extern struct tls_domain *tls_server_domains;

已定义服务器域的列表。

extern struct tls_domain *tls_client_domains;

已定义客户端域的列表。

#### tls_find_server_domain

struct tls_domain *tls_find_server_domain(struct ip_addr *ip,
			unsigned short port);

查找具有给定 ip 和端口的 TLS 服务器域（本地监听套接字）。

#### tls_find_client_domain

struct tls_domain *tls_find_client_domain(struct ip_addr *ip,
			unsigned short port);

查找 TLS 客户端域。

#### tls_find_client_domain_addr

struct tls_domain *tls_find_client_domain_addr(struct ip_addr *ip,
			unsigned short port);

查找具有给定 ip 和端口的 TLS 客户端域（远程目标套接字）。

#### tls_find_client_domain_name

struct tls_domain *tls_find_client_name(str name);

按名称查找 TLS 客户端域。

#### tls_new__domain

struct tls_domain *tls_new_domain(int type);

创建新 TLS：分配内存、设置类型并初始化成员

#### tls_new_server_domain

int tls_new_server_domain(struct ip_addr *ip, unsigned short port);

创建并添加到 TLS 服务器域列表的新域。

#### tls_new_client_domain

int tls_new_client_domain(struct ip_addr *ip, unsigned short port);

创建并添加到 TLS 客户端域列表的基于套接字的新域。

#### tls_new_client_domain_name

int tls_new_client_domain_name(char *s, int len);

创建并添加到 TLS 客户端域列表的基于名称的新域。

#### tls_free_domains

void tls_free_domains(void);

清理整个域列表。

<!-- 贡献者 -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
