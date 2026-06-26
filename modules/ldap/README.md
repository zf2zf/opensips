---
title: "LDAP 模块"
description: "LDAP 模块为 OpenSIPS 实现了 LDAP 搜索接口。它导出脚本函数来执行 LDAP 搜索操作，并将搜索结果存储为 OpenSIPS AVP。这允许在 OpenSIPS SIP 消息路由脚本中使用 LDAP 目录数据。"
---

## 管理指南


### 概述


LDAP 模块为 OpenSIPS 实现了 LDAP 搜索接口。它导出脚本函数来执行 LDAP 搜索操作，
		并将搜索结果存储为 OpenSIPS AVP。这允许在 OpenSIPS SIP 消息路由脚本中使用 LDAP 目录数据。


LDAP 模块提供以下功能：


- LDAP 搜索函数，接受 LDAP URL 作为输入，支持同步和异步
- LDAP 结果解析函数，将 LDAP 数据存储为 AVP
- 支持访问多个 LDAP 服务器
- LDAP SIMPLE 认证
- LDAP 服务器故障转移和自动重连
- 可配置的 LDAP 连接和绑定超时
- 可供其他 OpenSIPS 模块使用的 LDAP 搜索操作模块 API
- StartTLS 支持


该模块实现利用了大多数 UNIX/Linux 平台上可用的开源 OpenLDAP 库。
		除了 LDAP 服务器故障转移和自动重连外，此模块可以同时处理多个 LDAP 会话，
		允许访问存储在不同 LDAP 服务器上的数据。
		每个 OpenSIPS 工作进程为每个配置的 LDAP 服务器维护一个 LDAP TCP 连接。
		这使得 LDAP 请求可以并行执行，并将 LDAP 并发控制卸载到 LDAP 服务器。


提供了 LDAP 搜索模块 API，可供其他 OpenSIPS 模块使用。
		使用此 API 的模块不必实现 LDAP 连接管理和配置，
		同时仍能访问用于搜索和结果处理的完整 OpenLDAP API。


由于 LDAP 服务器实现针对快速读取访问进行了优化，
		它们是存储 SIP 配置数据的良好选择。
		性能测试表明，与其他数据库模块（如 OpenSIPS MYSQL 模块）相比，
		此模块实现了更低的数据访问时间和更高的呼叫速率。


#### 基本用法


首先，需要在外部配置文件中指定所谓的 LDAP 会话（如 [ldap 配置](#ldap_configuration_file) 中所述）。
		每个 LDAP 会话包含 LDAP 服务器访问参数，如服务器主机名或连接超时。
		通常只使用一个 LDAP 会话，除非需要访问多个 LDAP 服务器。
		LDAP 会话名称将用于 OpenSIPS 配置脚本中以引用特定的 LDAP 会话。


`ldap_search` 函数（[ldap 搜索函数](#func_ldap_search)）执行 LDAP 搜索操作。
		它接受 LDAP URL 作为输入，其中包括 LDAP 会话名称和搜索参数。
		[ldap url](#ldap_urls) 提供了 LDAP URL 的快速概述。


LDAP 搜索的结果存储在内部，可以通过 `ldap_result*` 函数之一访问。
		`ldap_result`（[ldap 结果函数](#func_ldap_result)）将结果 LDAP 属性值存储为 AVP。
		`ldap_result_check`（[ldap 结果检查函数](#func_ldap_result_check)）
		是一个便捷函数，用于使用正则表达式匹配将字符串与 LDAP 属性值进行比较。
		最后，`ldap_result_next`（[ldap 结果下一个函数](#func_ldap_result_next)）
		允许处理返回多个 LDAP 条目的 LDAP 搜索查询。


所有 `ldap_result*` 函数始终访问最后一次 `ldap_search` 调用的 LDAP 结果集。
		在 OpenSIPS 配置脚本中多次调用 `ldap_search` 时应牢记这一点。


#### LDAP URL


`ldap_search` 期望 LDAP URL 作为参数。本节描述 LDAP URL 的格式和语义。


RFC 4516 [RFC4516](#RFC4516) 描述了 LDAP 统一资源定位符（URL）的格式。
		LDAP URL 以紧凑格式表示 LDAP 搜索操作。
		LDAP URL 格式定义如下（略有修改，
		有关 ABNF 表示法请参阅 [RFC4516](#RFC4516) 第 2 节）：


`ldap://[ldap_session_name][/dn?attrs[?scope[?filter]]]]`


**`ldap_session_name`**


LDAP 配置文件中定义的 LDAP 会话名称。


（RFC 4516 将其定义为 LDAP hostport 参数）


**`dn`**


LDAP 搜索或非搜索操作目标的基 Distinguished Name (DN)，
              如 RFC 4514 [RFC4514](#RFC4514) 中定义


**`attrs`**


返回的 LDAP 属性的逗号分隔列表


**`scope`**


LDAP 搜索范围，有效值为
              "base"、"one" 或 "sub"


**`filter`**


遵循 RFC 4515 [RFC4515](#RFC4515) 规则的 LDAP 搜索过滤器定义


> [!NOTE]
> 下表列出了必须在 LDAP 搜索过滤器中转义的字符：


> [!NOTE]
> LDAP URL 中的非 URL 字符必须使用百分号编码进行转义
          （请参阅 RFC 4516 第 2.1 节）。
	  这意味着 LDAP URL 组件中的任何 "?" 字符必须写为 "%3F"，
	  因为 "?" 用作 URL 分隔符。
	  导出的函数 `ldap_filter_url_encode`（[ldap 过滤器 URL 编码函数](#func_ldap_filter_url_encode)）
	  实现了 RFC 4515/4516 LDAP 搜索过滤器和 URL 转义规则。


### 依赖


#### OpenSIPS 模块


该模块依赖以下模块（列出的模块必须在此模块之前加载）：


- *不依赖其他 OpenSIPS 模块。*


#### 外部库或应用程序


运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- OpenLDAP 库 (libldap) v2.1 或更高版本，编译需要 libldap 头文件 (libldap-dev)


### LDAP 配置文件


该模块在模块初始化时读取外部配置文件，
      其中包含 LDAP 会话定义。


#### 配置文件语法


配置文件遵循 Windows INI 文件语法，节名称用方括号括起来：


```c
[Section_Name]
```


任何节可以包含零个或多个形式为的配置键赋值


```c
key = value ; comment
```


可以给值加引号。如果没有引号，则该值被理解为包含第一个和最后一个非空白字符之间的所有字符。
        以井号开头和空白的行被视为注释。


每个节描述一个 LDAP 会话，可以在 OpenSIPS 配置脚本中引用。
        使用节名作为 LDAP URL 的主机部分告诉模块使用相应节中指定的 LDAP 会话。
        LDAP 会话规范的示例如下：


```c
[example_ldap]
ldap_server_url            = "ldap://ldap1.example.com, ldap://ldap2.example.com"
ldap_bind_dn               = "cn=sip_proxy,ou=accounts,dc=example,dc=com"
ldap_bind_password         = "pwd"
ldap_network_timeout       = 500
ldap_client_bind_timeout   = 500
ldap_ca_cert_file		   = "/usr/share/ca-certificates/mycert.pem"
ldap_cert_file			   = "/var/my-certificate/certificate.pem"
ldap_key_file			   = "/var/my-certificate/key.pem"
ldap_require_certificate   = "ALLOW"
```


配置键在以下部分中说明。此 LDAP 会话可以通过使用 LDAP URL
        在路由脚本中引用，例如


```c
ldap://example_ldap/cn=admin,dc=example,dc=com
```


#### LDAP 会话设置


**ldap_server_url（必需）**


LDAP URL，包括 LDAP 服务器的完全限定域名或 IP 地址，
		可选择后跟冒号和 TCP 端口：`ldap://<FQDN/IP>[:<port>]`。
		可以添加故障转移 LDAP 服务器，每个用逗号分隔。
		连接错误时，模块按出现顺序尝试连接到服务器。


默认值：无，这是一个必需设置


```c title="ldap_server_url 示例"
ldap_server_url = "ldap://localhost"
ldap_server_url = "ldap://ldap.example.com:7777"
ldap_server_url = "ldap://ldap1.example.com,
                   ldap://ldap2.example.com:80389"
				
```


**ldap_version（可选）**


支持的 LDAP 版本为 2 和 3。


默认值：`3`（LDAPv3）


```c title="ldap_version 示例"
ldap_version = 2
```


**ldap_bind_dn（可选）**


用于绑定到 LDAP 服务器的认证用户 DN（模块当前仅支持 SIMPLE_AUTH）。
              空字符串启用匿名 LDAP 绑定。


默认值：""（空字符串 -->
              匿名绑定）


```c title="ldap_bind_dn 示例"
ldap_bind_dn = "cn=root,dc=example,dc=com";
```


**ldap_bind_password（可选）**


用于绑定到 LDAP 服务器的认证密码（SIMPLE_AUTH）。
              空字符串启用匿名绑定。


默认值：""（空字符串 -->
              匿名绑定）


```c title="ldap_bind_password 示例"
ldap_bind_password = "secret";
```


**ldap_network_timeout（可选）**


LDAP TCP 连接超时（毫秒）。
              如果 `ldap_server_url` 包含多个 LDAP 服务器地址，
              将此参数设置为较低的值可以启用快速故障转移。


默认值：1000（1 秒）


```c title="ldap_network_timeout 示例"
ldap_network_timeout = 500 ; 设置 TCP 超时为 500 ms
```


**ldap_client_bind_timeout（可选）**


LDAP 绑定操作超时（毫秒）。


默认值：1000（1 秒）


```c title="ldap_client_bind_timeout 示例"
ldap_client_bind_timeout = 1000
```


**ldap_ca_cert_file（可选）**


CA 证书文件的完整路径。


无默认值。如果您希望使用 StartTLS，这是必需的。


```c title="ldap_ca_cert_file 示例"
ldap_ca_cert_file = "/usr/local/CAcert.pem"
```


**ldap_cert_file（可选）**


证书文件的完整路径。


无默认值。如果您希望使用 StartTLS，这是必需的。


```c title="ldap_cert_file 示例"
ldap_cert_file = "/usr/local/mycert.pem"
```


**ldap_key_file（可选）**


密钥文件的完整路径。


无默认值。如果您希望使用 StartTLS，这是必需的。


```c title="ldap_key_file 示例"
ldap_key_file = "/usr/local/mykey.pem"
```


**ldap_require_certificate（可选）**


LDAP 对等证书检查策略，"NEVER"、"HARD"、"DEMAND"、"ALLOW"、"TRY" 之一。
					也接受小写字母。


默认值 "NEVER"。


```c title="ldap_require_certificate 示例"
ldap_require_certificate = "NEVER"
```


#### 配置文件示例


以下配置文件示例包含两个 LDAP 会话定义，
        例如可分别用于访问 H.350 数据和电话号码到名称映射。


```c title="LDAP 配置文件示例"
# LDAP 会话 "sipaccounts"：
#
# - 使用 LDAPv3（默认）
# - 两个冗余 LDAP 服务器
#
[sipaccounts]
ldap_server_url = "ldap://h350-1.example.com, ldap://h350-2.example.com"
ldap_bind_dn = "cn=sip_proxy,ou=accounts,dc=example,dc=com"
ldap_bind_password = "pwd"
ldap_network_timeout = 500
ldap_client_bind_timeout = 500
#使用 StartTLS
ldap_ca_cert_file = "/ldap/path/to/ca/certificate.pem"
ldap_cert_file = "/ldap/path/to/certificate.pem"
ldap_key_file = "/ldap/path/to/key/file.pem"
ldap_require_certificate = "NEVER"


# LDAP 会话 "campus"：
#
# - 使用 LDAPv2
# - 匿名绑定
#
[campus]
ldap_version = 2
ldap_server_url = "ldap://ldap.example.com"
ldap_network_timeout = 500
ldap_client_bind_timeout = 500
			
```


### 导出的参数


#### config_file (字符串)


LDAP 配置文件的完整路径。


默认值：
        `/usr/local/etc/opensips/ldap.cfg`


```c title="config_file 参数用法"
modparam("ldap", "config_file", "/etc/opensips/ldap.ini")
		  
```


#### max_async_connections (整数)


将启动以执行异步 ldap_search 调用的
			  LDAP 服务器的最大异步连接数。
			  连接数是按进程计算的，
			  因此如果有 8 个工作进程，每个进程有 20 个 max_async_connections，
			  则到 LDAP 服务器的最大连接数将为 160。


默认值：`20`


```c title="max_async_connections 参数用法"
modparam("ldap", "max_async_connections", 50)
		  
```


### 导出的函数


#### ldap_search(ldap_url)


使用给定的 LDAP URL 执行 LDAP 搜索操作，
        并在内部存储结果以供以后通过 `ldap_result*` 函数检索。
        如果找到一个或多个 LDAP 条目，函数返回找到的条目数，
        在 OpenSIPS 配置脚本中计算为 TRUE。
        如果未找到 LDAP 条目，返回 `-1`（`FALSE`）；
        如果发生内部错误（如 LDAP 服务器不可用），返回 `-2`（`FALSE`）。


**`ldap_url (字符串)`**


定义 LDAP 搜索操作的 LDAP URL
			  （有关 LDAP URL 格式的说明请参阅 [ldap url](#ldap_urls)）。
              hostport 部分必须是 LDAP 配置脚本中声明的 LDAP 会话名称之一。


使用 LDAP 会话 `sipaccounts`、
                基础 `ou=sip,dc=example,dc=com`、
                搜索过滤器 `(cn=schlatter)` 返回所有属性的搜索：


```c title="ldap_url 用法示例"
ldap://sipaccounts/ou=sip,dc=example,dc=com??one?(cn=schlatter)
```


使用 LDAP 会话 `ldap1`、基础 `dc=example,dc=com`、
                搜索过滤器 `(cn=$(avp(name)))` 返回
                `SIPIdentityUserName` 和 `SIPIdentityServiceLevel` 属性的子树搜索：


```c title="ldap_url 用法示例"
ldap://ldap_1/dc=example,dc=com?
       SIPIdentityUserName,SIPIdentityServiceLevel?sub?(cn=$(avp(name)))
	        
```


**`n` > 0 (TRUE)：**


- 找到 `n` 个匹配的 LDAP 条目


**`-1` (FALSE)：**


- 未找到匹配的 LDAP 条目


**`-2` (FALSE)：**


- LDAP 错误（如 LDAP 服务器不可用），或内部错误


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 ONREPLY_ROUTE。


```c title="用法示例"
...
# ldap 搜索
if (!ldap_search("ldap://sipaccounts/ou=sip,dc=example,dc=com??one?(cn=$rU)"))
{
    switch ($retcode)
    {
    case -1:
        # 未找到 LDAP 条目
        sl_send_reply(404, "User Not Found");
        exit;
    case -2:
        # 内部错误
        sl_send_reply(500, "Internal server error");
        exit;
    default:
        exit;
    }
}
xlog("L_INFO", "ldap_search: found [$retcode] entries for (cn=$rU)");

# 将电话号码保存到 $avp(tel_number)
ldap_result("telephoneNumber/$avp(tel_number)");
...
			
```


#### ldap_result(ldap_attr_name, avp_spec, [avp_type], [regex_subst])


此函数将 LDAP 属性值转换为 AVP，
        以便在消息路由脚本中稍后使用。
        它访问由最后一次 `ldap_search` 调用获取的 LDAP 结果集。
        `ldap_attr_name` 指定要存储其值的 LDAP 属性名称。
        多值 LDAP 属性生成索引 AVP。
        可选的 `regex_subst` 参数允许进一步定义应将属性值的哪一部分存储为 AVP。


AVP 可以是字符串类型或整数类型。默认情况下，`ldap_result` 将 LDAP 属性值存储为字符串类型的 AVP。
        可选的 `avp_type` 参数可用于明确指定 AVP 的类型。
        可以是 `str`（字符串）或 `int`（整数）。
        如果 `avp_type` 指定为 `int`，则 `ldap_result` 尝试将 LDAP 属性值转换为整数。
        在这种情况下，只有在整数转换成功时才会将值存储为 AVP。


**ldap_attr_name (字符串)**


要存储其值的 LDAP 属性名称，例如
              `SIPIdentityServiceLevel` 或 `telephonenumber`


**avp_spec (变量)**


目标 AVP 的规范，例如
              `$avp(service_level)` 或 `$avp(12)`


**avp_type (字符串，可选)**


目标 AVP 类型的规范，`str` 或 `int`。
              如果未指定此参数，则 LDAP 属性值存储为字符串类型的 AVP。


**regex_subst (字符串)**


在将 LDAP 属性值存储为 AVP 之前要应用的正则表达式替换，
              例如 `"/^sip:(.+)$/\1/"` 以去除 LDAP 属性值开头的 "sip:"。


**`n` > 0 (TRUE)**


在 LDAP 结果集中找到 LDAP 属性 `ldap_attr_name`，
        并将 `n` 个 LDAP 属性值存储在 `avp_spec` 中


**-1 (FALSE)**


在 LDAP 结果集中未找到 LDAP 属性 `ldap_attr_name`


**-2 (FALSE)**


发生内部错误


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 ONREPLY_ROUTE。


```c title="用法示例"
...

# ldap_search 调用
...

# 将 SIPIdentityServiceLevel 保存到 $avp(service_level)
if (!ldap_result("SIPIdentityServiceLevel", $avp(service_level)))
{
    switch ($retcode)
    {
    case -1:
        # 未找到 SIPIdentityServiceLevel
        sl_send_reply(403, "Forbidden");
        exit;
    case -2:
        # 内部错误
        sl_send_reply(500, "Internal server error");
        exit;
    default:
        exit;
    }
}

# 将 SIP URI 域保存到 $avp(10)
ldap_result("SIPIdentitySIPURI", $avp(10), "/^[^@]+@(.+)$/\1/");
...
			
```


#### ldap_result_check(ldap_attr_name, string_to_match, [, regex_subst])


此函数将 `ldap_attr_name` 的值与 `string_to_match` 进行比较。
        它访问由最后一次 `ldap_search` 调用获取的 LDAP 结果集。
        可选的 `regex_subst` 参数允许进一步定义属性值的哪一部分应用
        于相等性匹配。如果 `ldap_attr_name` 是多值的，
        则检查每个值是否与 `string_to_match` 匹配。
        如果有一个或多个值匹配，函数返回 `1`（TRUE）。


**ldap_attr_name (字符串)**


要匹配其值的 LDAP 属性名称，例如 `SIPIdentitySIPURI`


**string_to_match (字符串)**


要匹配的字符串。包含的 AVP 和伪变量会被展开。


**regex_subst (字符串，可选)**


在将 LDAP 属性值与 string_to_match 进行比较之前应用的正则表达式替换，
              例如 `"/^[^@]@+(.+)$/\1/"` 以提取 SIP URI 的域部分


**1 (TRUE)**


一个或多个 `ldap_attr_name` 属性值与
              `string_to_match` 匹配（应用 `regex_subst` 后）


**-1 (FALSE)**


未找到 `ldap_attr_name` 属性或
              属性值与 `string_to_match` 不匹配
              （应用 `regex_subst` 后）


**-2 (FALSE)**


发生内部错误


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 ONREPLY_ROUTE。


```c title="用法示例"
...
# ldap_search 调用
...

# 检查 'sn' ldap 属性值是否等于 R-URI 的用户名部分，
# 可以通过 ldap_result_check("sn/$rU") 实现相同效果
if (!ldap_result_check("sn", $ru, "/^sip:([^@]).*$/\1/"))
{
    switch ($retcode)
    {
    case -1:
        # R-URI 用户名与 sn 不匹配
        sl_send_reply(401, "Unauthorized");
        exit;
    case -2:
        # 内部错误
        sl_send_reply(500, "Internal server error");
        exit;
    default:
        exit;
    }
}
...
			
```


#### ldap_result_next()


LDAP 搜索操作可以返回多个 LDAP 条目。
        此函数可用于遍历所有返回的 LDAP 条目。
        如果 LDAP 结果集中存在另一个 LDAP 条目，它返回 1 (TRUE)，
        并使 `ldap_result*` 函数在下一个 LDAP 条目上工作。
        如果 LDAP 结果集中没有更多 LDAP 条目，函数返回 -1 (FALSE)。


**1 (TRUE)**


LDAP 结果集中存在另一个 LDAP 条目，
              结果指针增加一


**-1 (FALSE)**


没有更多 LDAP 条目可用


**`-2` (FALSE)**


内部错误


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 ONREPLY_ROUTE。


```c title="用法示例"
...
# ldap_search 调用
...

ldap_result("telephonenumber/$avp(tel1)");
if (ldap_result_next())
{
	ldap_result("telephonenumber/$avp(tel2)");
}
if (ldap_result_next())
{
	ldap_result("telephonenumber/$avp(tel3)");
}
if (ldap_result_next())
{
	ldap_result("telephonenumber/$avp(tel4)");
}
...
			
```


#### ldap_filter_url_encode(string, avp_spec)


此函数将以下转义规则应用于 `string`，
        并将结果存储在 AVP `avp_spec` 中：


**ldap_filter_url_encode() 转义规则**


| `string` 中的字符 | 替换为 | 定义于 |
| --- | --- | --- |
| * | \2a | RFC 4515 |
| ( | \28 | RFC 4515 |
| ) | \29 | RFC 4515 |
| \ | \5c | RFC 4515 |
| ? | %3F | RFC 4516 |


存储在 AVP `avp_spec` 中的字符串可以在 LDAP URL 过滤器字符串中安全使用。


**`string`**


要应用 RFC 4515 和 URL 转义规则的字符串。
	      AVP 和伪变量会被展开。例如："cn=$avp(name)"


**`avp_spec (变量)`**


存储结果的 AVP，
	      RFC 4515 和 URL 编码字符串，例如 `$avp(ldap_search)` 或 `$avp(10)`


**`1` (TRUE)**


RFC 4515 和 URL 编码的 `filter_component` 存储为 AVP `avp_name`


**`-1` (FALSE)**


内部错误


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 ONREPLY_ROUTE。


```c title="用法示例"
...
if (!ldap_filter_url_encode("cn=$avp(name)", $avp(name_esc)))
{
    # RFC 4515/URL 编码失败 --> 静默丢弃请求
    exit;
}

xlog("L_INFO", "encoded LDAP filter component: [$avp(name_esc)]\n");

if (ldap_search(
     "ldap://h350/ou=commObjects,dc=example,dc=com??sub?($avp(name_esc))"))
    { ... }
...
			
```


### 导出的异步函数


#### ldap_search(ldap_url)


使用给定的 LDAP URL 执行 LDAP 搜索操作，
        并在内部存储结果以供以后通过 `ldap_result*` 函数检索。
        如果找到一个或多个 LDAP 条目，函数返回找到的条目数，
        在 OpenSIPS 配置脚本中计算为 TRUE。
        如果未找到 LDAP 条目，返回 `-1`（`FALSE`）；
        如果发生内部错误（如 LDAP 服务器不可用），返回 `-2`（`FALSE`）。


**`ldap_url (字符串)`**


定义 LDAP 搜索操作的 LDAP URL
			  （有关 LDAP URL 格式的说明请参阅 [ldap url](#ldap_urls)）。
              hostport 部分必须是 LDAP 配置脚本中声明的 LDAP 会话名称之一。


使用 LDAP 会话 `sipaccounts`、
                基础 `ou=sip,dc=example,dc=com`、
                搜索过滤器 `(cn=schlatter)` 返回所有属性的搜索：


```c title="ldap_url 用法示例"
ldap://sipaccounts/ou=sip,dc=example,dc=com??one?(cn=schlatter)
```


使用 LDAP 会话 `ldap1`、基础 `dc=example,dc=com`、
                搜索过滤器 `(cn=$(avp(name)))` 返回
                `SIPIdentityUserName` 和 `SIPIdentityServiceLevel` 属性的子树搜索：


```c title="ldap_url 用法示例"
ldap://ldap_1/dc=example,dc=com?
       SIPIdentityUserName,SIPIdentityServiceLevel?sub?(cn=$(avp(name)))
	        
```


**`n` > 0 (TRUE)：**


- 找到 `n` 个匹配的 LDAP 条目


**`-1` (FALSE)：**


- 未找到匹配的 LDAP 条目


**`-2` (FALSE)：**


- LDAP 错误（如 LDAP 服务器不可用），或内部错误


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 ONREPLY_ROUTE。


```c title="用法示例"
...
# ldap 搜索

route {
	async( ldap_search("ldap://sipaccounts/ou=sip,dc=example,dc=com??one?(cn=$rU)"), resume);
}
....
route[resume] {
{
    switch ($rc)
    {
    case -1:
        # 未找到 LDAP 条目
        sl_send_reply(404, "User Not Found");
        exit;
    case -2:
        # 内部错误
        sl_send_reply(500, "Internal server error");
        exit;
    default:
        exit;
    }
    xlog("L_INFO", "ldap_search: found [$retcode] entries for (cn=$rU)");

    # 将电话号码保存到 $avp(tel_number)
    ldap_result("telephoneNumber", $avp(tel_number)");
...
}
			
```


### 安装与运行


#### 编译模块


编译 LDAP 模块需要 OpenLDAP 库 (libldap) 和头文件 (libldap-dev) v2.1 或更高版本
        （此模块已在 v2.1.3 和 v2.3.32 上测试）。
        OpenLDAP 源代码可从 [http://www.openldap.org/](http://www.openldap.org/) 获取。


OpenLDAP 库已为大多数 UNIX/Linux 发行版预编译。
        在 Debian/Ubuntu 上，必须安装以下软件包：


```c
# apt-get install libldap2 libldap2-dev
```


.


## 开发者指南


### 概述


LDAP 模块 API 可供其他 OpenSIPS 模块用于实现 LDAP 搜索功能。
		这使模块实现者无需关心 LDAP 连接管理和配置。


要使用此 API，模块需要使用 `load_ldap_api` 函数加载 API，
		该函数返回指向 `ldap_api` 结构的指针。
		该结构包括下面描述的 API 函数指针。
		LDAP 模块源文件 `api.h` 包含加载 API 所需的所有声明，
		必须将其包含在加载 API 的文件中。
		API 加载通常在模块的 `mod_init` 调用内完成，如下例所示：


```c title="加载 LDAP 模块 API 的示例代码片段"
#include "../../sr_module.h"
#include "../ldap/api.h"

/*
 * ldap api 的全局指针
 */
extern ldap_api_t ldap_api;

...

static int mod_init(void)
{
    /*
     * 加载 LDAP API
     */
    if (load_ldap_api(&ldap_api) != 0)
    {
        LM_ERR("Unable to load LDAP API - this module requires ldap module\n");
        return -1;
    }

    ...
}

...
			
				
```


然后可以像以下示例一样使用 API 函数：


```c title="LDAP 模块 API 函数调用示例"
...
	
    rc = ldap_api.ldap_rfc4515_escape(str1, str2, 0);	
					
...		
			
				
```


### API 函数


#### ldap_params_search


使用作为函数参数给出的参数执行 LDAP 搜索。


```c
typedef int (*ldap_params_search_t)(int* _ld_result_count,
                                    char* _lds_name,
                                    char* _dn,
                                    int _scope,
                                    char** _attrs,
                                    char* _filter,
                                    ...);

			
```


**int* _ld_result_count**


函数将返回的 LDAP 条目数存储在 `_ld_result_count` 中。


**char* _lds_name**


LDAP 模块配置文件中配置的 LDAP 会话名称。


**char* _dn**


LDAP 搜索 DN。


**int _scope**


LDAP 搜索范围，`LDAP_SCOPE_ONELEVEL`、`LDAP_SCOPE_BASE`
			或 `LDAP_SCOPE_SUBTREE` 之一，
			如 OpenLDAP 的 `ldap.h` 中所定义。


**char** _attrs**


要从条目返回的属性类型的空终止数组。如果为空（`NULL`），则返回所有属性类型。


**char* _filter**


按照 RFC 4515 的 LDAP 搜索过滤器字符串。
		此字符串中的 printf 模式将替换为 `_filter` 参数之后的函数参数值。


**-1**


内部错误。


**0**


成功，`_ld_result_count` 包含找到的 LDAP 条目数。


#### ldap_url_search


使用 LDAP URL 执行 LDAP 搜索。


```c
typedef int (*ldap_url_search_t)(char* _ldap_url,
                                 int* _result_count);

			
```


**char* _ldap_url**


如 [ldap url](#ldap_urls) 中描述的 LDAP URL。


**int* _result_count**


函数将返回的 LDAP 条目数存储在 `_ld_result_count` 中。


**-1**


内部错误。


**0**


成功，`_ld_result_count` 包含找到的 LDAP 条目数。


#### ldap_result_attr_vals


检索返回的 LDAP 属性的值。
		函数访问由最后一次 `ldap_params_search` 或 `ldap_url_search` 调用返回的 LDAP 结果。
		`berval` 结构在 OpenLDAP 的 `ldap.h` 中定义，必须包含该头文件。


此函数分配内存来存储 LDAP 属性值。
		必须使用 `ldap_value_free_len` 函数释放此内存（见下一节）。


```c
typedef int (*ldap_result_attr_vals_t)(str* _attr_name,
                                       struct berval ***_vals);
									   
typedef struct berval {
        ber_len_t       bv_len;
        char            *bv_val;
} BerValue;

			
```


**str* _attr_name**


保存 LDAP 属性名称的 `str` 结构。


**struct berval ***_vals**


属性值的空终止数组。


**-1**


内部错误。


**0**


成功，`_vals` 包含属性的值。


**1**


未找到属性值。


#### ldap_value_free_len


用于释放由 `ldap_result_attr_vals` 分配的内存的函数。
		`berval` 结构在 OpenLDAP 的 `ldap.h` 中定义，必须包含该头文件。


```c
typedef void (*ldap_value_free_len_t)(struct berval **_vals);

typedef struct berval {
        ber_len_t       bv_len;
        char            *bv_val;
} BerValue;

			
```


**struct berval **_vals**


由 `ldap_result_attr_vals` 返回的 `berval` 数组。


#### ldap_result_next


递增 LDAP 结果指针。


```c
typedef int (*ldap_result_next_t)();

			
```


**-1**


未找到 LDAP 结果，可能是因为未调用 `ldap_params_search` 或 `ldap_url_search`。


**0**


成功，LDAP 结果指针现在指向下一个结果。


**1**


没有更多结果可用。


#### ldap_str2scope


将 LDAP 搜索范围字符串转换为整数值，例如用于 `ldap_params_search`。


```c
typedef int (*ldap_str2scope_t)(char* scope_str);

			
```


**char* scope_str**


LDAP 搜索范围字符串。"one"、"onelevel"、"base"、"sub" 或 "subtree" 之一。


**-1**


无法识别 `scope_str`。


**n >= 0**


LDAP 搜索范围整数。


#### ldap_rfc4515_escape


应用 [ldap 过滤器 URL 编码函数](#func_ldap_filter_url_encode) 中描述的转义规则。


```c
typedef int (*ldap_rfc4515_escape_t)(str *sin, str *sout, int url_encode);

			
```


**str *sin**


保存要应用转义规则的字符串的 `str` 结构。


**str *sout**


保存转义字符串的 `str` 结构。
		此字符串的长度必须至少是 `sin` 长度的三倍加一。


**int url_encode**


标志，指定是否使用 '%3F' 转义 '?' 字符。
		如果 `url_encode` 等于 0，则 '?' 不会被转义。


**-1**


内部错误。


**0**


成功，`sout` 包含转义字符串。


#### get_ldap_handle


返回特定 LDAP 会话的 OpenLDAP LDAP 句柄。
		这允许模块实现者直接使用 OpenLDAP API 函数，
		而不是使用 OpenSIPS LDAP 模块导出的 API 函数。
		`LDAP` 结构在 OpenLDAP 的 `ldap.h` 中定义，必须包含该头文件。


```c
typedef int (*get_ldap_handle_t)(char* _lds_name, LDAP** _ldap_handle);

			
```


**char* _lds_name**


LDAP 模块配置文件中指定的 LDAP 会话名称。


**LDAP** _ldap_handle**


此函数返回的 OpenLDAP LDAP 句柄。


**-1**


内部错误。


**0**


成功，`_ldap_handle` 包含 OpenLDAP LDAP 句柄。


#### get_last_ldap_result


返回最后一次 LDAP 搜索操作的 OpenLDAP LDAP 句柄和 OpenLDAP 结果句柄。
		这些句柄可用作 OpenLDAP LDAP 结果 API 函数的输入。
		`LDAP` 和 `LDAPMessage` 结构在 OpenLDAP 的 `ldap.h` 中定义，必须包含该头文件。


```c
typedef void (*get_last_ldap_result_t)
	     (LDAP** _last_ldap_handle, LDAPMessage** _last_ldap_result);

			
```


**LDAP** _last_ldap_handle**


此函数返回的 OpenLDAP LDAP 句柄。


**LDAPMessage** _last_ldap_result**


此函数返回的 OpenLDAP 结果句柄。


### 用法示例


以下示例显示如何使用此 API 执行 LDAP 搜索操作。
		假设 API 已通过 `ldap_api` 指针加载并可用。


```c
...
	
	int rc, ld_result_count, scope = 0;
	char* sip_username = "test";

	/*
	 * 获取 LDAP 搜索范围整数
	 */
	scope = ldap_api.ldap_str2scope("sub");
	if (scope == -1)
	{
	    LM_ERR("ldap_str2scope failed\n");
	    return -1;
	}

	/*
	 * 执行 LDAP 搜索
	 */

	if (ldap_api.ldap_params_search(
	       &ld_result_count,
	       "campus",
	       "dc=example,dc=com",
	       scope,
	       NULL,
	       "(&(objectClass=SIPIdentity)(SIPIdentityUserName=%s))",
	       sip_username)
	     != 0)
	{
	    LM_ERR("LDAP search failed\n");
	    return -1;
	}

	/*
	 * 检查结果计数
	 */
	if (ld_result_count < 1)
	{
	    LM_ERR("LDAP search returned no entry\n");
	    return 1;
	}

	/*
	 * 获取密码属性值 
	 */
	 
	struct berval **attr_vals = NULL;
	str ldap_pwd_attr_name = str_init("SIPIdentityPassword");
	str res_password;

	rc = ldap_api.ldap_result_attr_vals(&ldap_pwd_attr_name, &attr_vals);
	if (rc < 0)
	{
	    LM_ERR("ldap_result_attr_vals failed\n");
	    ldap_api.ldap_value_free_len(attr_vals);
	    return -1;
	}
	if (rc == 1)
	{
	    LM_INFO("No password attribute value found for [%s]\n", sip_username);
	    ldap_api.ldap_value_free_len(attr_vals);
	    return 2;
	}

	res_password.s = attr_vals[0]->bv_val;
	res_password.len = attr_vals[0]->bv_len;

	ldap_api.ldap_value_free_len(attr_vals);

	LM_INFO("Password for user [%s]: [%s]\n", sip_username, res_password.s);

	...

	return 0;		

		
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议。
