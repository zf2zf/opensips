---
title: "Domain Policy 模块"
description: "Domain Policy 模块实现了 draft-lendl-domain-policy-ddds-02 以及 draft-lendl-speermint-federations-02 和 draft-lendl-speermint-technical-policy-00 的组合。这些草案定义了 DNS 记录,域可以通过它公布其联盟成员身份。本地数据库可以..."
---

## 管理指南


### 概述


Domain Policy 模块实现了 draft-lendl-domain-policy-ddds-02 以及
		draft-lendl-speermint-federations-02 和
		draft-lendl-speermint-technical-policy-00 的组合。这些草案
		定义了 DNS 记录,域可以通过它公布其联盟成员身份。本地数据库可以
		用于将策略规则映射到路由策略决策。
		该数据库还可以包含与 draft-lendl-domain-policy-ddds-02 无关的
		目标域规则。


此模块需要数据库。未实现缓存。


### 依赖


该模块依赖以下模块（换句话说,以下模块必须在此模块之前加载）：


- *database* -- 任何数据库模块


### 导出的参数


#### db_url (string)


这是要使用的数据库的 URL。


默认值为
			"mysql://opensipsro:opensipsro@localhost/opensips"


```c title="设置 db_url 参数"
modparam("domainpolicy", "db_url", "postgresql://user:pass@db_host/opensips")
```


#### dp_table (string)


包含本地支持域策略设置的表名。


默认值为 "domainpolicy"。


```c title="设置 dp_table 参数"
modparam("domainpolicy", "dp_table", "supportedpolicies")
```


#### dp_col_rule (string)


包含域策略规则名称的列名,该名称等于域策略 NAPTR 中发布的 URI。


默认值为 "rule"。


```c title="设置 dp_col_rule 参数"
modparam("domainpolicy", "dp_col_rule", "rules")
```


#### dp_col_type (string)


包含域策略规则类型的列名。
		对于联盟名称,这是 "fed"。对于根据 draft-lendl-speermint-technical-policy-00
		的标准转介,这是 "std"。对于直接域查找,这是 "dom"。


默认值为 "type"。


```c title="设置 dp_col_rule 参数"
modparam("domainpolicy", "dp_col_type", "type")
```


#### dp_col_att (string)


包含 AVP 名称的列名。如果存储在该行中的规则被触发,
		则 dp_can_connect() 将添加具有该名称的 AVP。


默认值为 "att"。


```c title="设置 dp_col_att 参数"
modparam("domainpolicy", "dp_col_att", "attribute")
```


#### dp_col_val (string)


包含由 dp_can_connect() 创建的 AVP 值的列名。


默认值为 "val"。


```c title="设置 dp_col_val 参数"
modparam("domainpolicy", "dp_col_val", "values")
```


#### port_override_avp (string)


此参数定义 AVP 的名称,dp_apply_policy() 将在其中查找覆盖端口号。


默认值为 "portoverride"。


```c title="设置 port_override_avp 参数"
# 字符串类型的 AVP 名称
modparam("domainpolicy", "port_override_avp", "portoverride")
```


#### transport_override_avp (string)


包含覆盖传输设置的 AVP 名称。


默认值为 "transportoverride"。


```c title="设置 transport_override_avp 参数"
# 字符串类型的 AVP 名称
modparam("domainpolicy", "transport_override_avp", "transportoverride")
```


#### domain_replacement_avp (string)


包含域替换的 AVP 名称。


默认值为 "domainreplacement"。


```c title="设置 domain_replacement_avp 参数"
# 字符串类型的 AVP 名称
modparam("domainpolicy", "domain_replacement_avp", "domainreplacement")
```


#### domain_prefix_avp (string)


包含域前缀的 AVP 名称。


默认值为 "domainprefix"。


```c title="设置 domain_prefix_avp 参数"
# 字符串类型的 AVP 名称
modparam("domainpolicy", "domain_prefix_avp", "domainprefix")
```


#### domain_suffix_avp (string)


包含域后缀的 AVP 名称。


默认值为 "domainsuffix"。


```c title="设置 domain_suffix_avp 参数"
# 字符串类型的 AVP 名称
modparam("domainpolicy", "domain_suffix_avp", "domainsuffix")
```


#### send_socket_avp (string)


包含 send_socket 的 AVP 名称。此 AVP 的格式（有效载荷）必须为
		[proto:]ip_address[:port] 格式。dp_apply_policy 函数将
		查找此 AVP,如果已定义,它将强制发送套接字为其值（类似于 force_send_socket 核心函数）。


默认值为 "sendsocket"。


```c title="设置 send_socket_avp 参数"
# 字符串类型的 AVP 名称
modparam("domainpolicy", "send_socket_avp", "sendsocket")
```


### 导出的函数


#### dp_can_connect()


检查调用者的互联策略。它使用请求 URI 中的域执行 DP-DDDS 算法,
		根据 draft-lendl-domain-policy-ddds-02 检索域的策略公告。
		在此版本中,仅支持符合 draft-lendl-speermint-federations-02
		和 draft-lendl-speermint-technical-policy-00 的记录。


非终结 NAPTR 记录将递归到替换域。dp_can_connect()
		因此会在引用域中查找策略规则。此外,将为
		"domainreplacement"（包含新域）添加一个 AVP 到呼叫中。这将
		把 SRV/A 记录查找重定向到新域。


为了简化直接基于域的对等连接,所有目标域都被视为包含
		优先级为 "D2P+SIP:dom" 的规则,规则值为域本身。因此,任何
		type = 'dom' 且 rule = 'example.com' 的数据库行都将覆盖
		任何动态 DNS 发现的规则。


对于服务类型为 "D2P+SIP:fed" 的 NAPTR,联盟 ID
		（从 regexp 字段提取）用于从本地数据库检索策略记录
		（基本上是："SELECT dp_col_att, dp_col_val FROM
		dp_table WHERE dp_col_rule = '[federationID]' AND type = 'fed'）。如果找到记录（并且
		具有相同 order 值的所有其他记录都可满足）,则将从
		dp_col_att 和 dp_col_val 列创建 AVP。


对于服务类型为 "D2P+SIP:std" 的 NAPTR,执行相同的过程。但是,
		数据库查找搜索 type = 'std'。


"D2P+SIP:fed" 和 "D2P+SIP:std" 可以自由混合。如果具有相同
		"order" 的两个规则匹配并尝试设置相同的 AVP,则行为未定义。


dp_col_att 列指定 AVP 的名称。如果 AVP 以 "s:" 或 "i:" 开头,则
		将生成相应的 AVP 类型（字符串命名或整数命名）。如果省略
		精确说明符,则将猜测 AVP 类型。


dp_col_val 列将始终被解释为字符串。因此,AVP 的值
		始终基于字符串。


dp_can_connect 返回：


- *-2*：评估期间的错误。（DNS、DB、...）
- *-1*：找到 D2P+SIP 记录,但策略无法满足。
- *1*：找到 D2P+SIP 记录且可以呼叫
- *2*：未找到 D2P+SIP 记录。目标域未公布
			传入 SIP 呼叫的策略。


此函数可用于 REQUEST_ROUTE。


```c title="dp_can_connect 使用示例"
...
dp_can_connect();
switch(retcode) {
	case -2:
		xlog("L_INFO","DP 评估期间出错\n");
		sl_send_reply(404, "我们无法连接您。");
		break;
	case -1:
		xlog("L_INFO","我们无法连接到该域\n");
		sl_send_reply(404, "我们无法连接您。");
		break;
	case 1:
		xlog("L_INFO","我们找到了匹配的策略记录\n");
		avp_print();
		dp_apply_policy();
		t_relay();
		break;
	case 2:
		xlog("L_INFO","未找到 DP 记录\n");
		t_relay();
		break;
}
...
		
```


#### dp_apply_policy()


此函数根据从 `dp_can_connect()` 函数返回的策略设置目标 URI。
		`dp_can_connect()` 和 `dp_apply_policy()` 之间的参数
		交换通过 AVP 完成。AVP 可以在模块的参数部分配置。


注意：AVP 的名称必须与 domainpolicy 表中
		*att* 列中的名称对应。


在 `dp_can_connect()` 中设置以下 AVP
		（或其他方式）
		将在 `dp_apply_policy()` 中导致以下操作：


- *port_override_avp*：如果设置了此 AVP,则目标
			URI 中的端口将设置为该端口。设置覆盖端口会禁用
			NAPTR 和 SRV 查找（根据 RFC 3263）。
- *transport_override_avp*：如果设置了此 AVP,则目标
			URI 中的传输参数将设置为指定传输（"udp"、"tcp"、
			"tls"）。设置覆盖传输也会禁用 NAPTR 查找,但保留
			SRV 查找（根据 RFC 3263）。
- *domain_replacement_avp*：如果设置了此 AVP,则目标
			URI 中的域将被此域替换。
		非终结 NAPTR 隐式地将 *domain_replacement_avp* 设置为新域。
- *domain_prefix_avp*：如果设置了此 AVP,则目标
			URI 中的域将以此"子域"为前缀。例如,如果请求 URI 中的域是
			"example.com" 并且 domain_prefix_avp 包含 "inbound",则目标
			URI 中的域设置为 "inbound.example.com"。
- *domain_suffix_avp*：如果设置了此 AVP,则目标
			URI 中的域将追加 AVP 的内容。例如,如果请求 URI 中的域是
			"example.com" 并且 domain_suffix_avp 包含 "myroot.com",则目标
			URI 中的域设置为 "example.com.myroot.com"。
- *send_socket_avp*：如果设置了此 AVP,则发送套接字
			将被强制为 AVP 中的套接字。此 AVP 的有效载荷格式必须
			为 [proto:]ip_address[:port]。


如果同时使用前缀/后缀和域替换,则首先执行替换,
		然后将前缀/后缀应用于新域。


此函数可用于 REQUEST_ROUTE。


```c title="dp_apply_policy 使用示例"
...
if (dp_apply_policy()) {
	t_relay();
}
...
		
```


### FIFO 命令


### 使用场景


本节描述如何使用此模块实现选择性 VoIP 对等连接。


#### 基于 TLS 的联盟


此示例显示如何基于 TLS 和域策略配置安全对等结构。


假设一个名为 "TLSFED.org" 的组织作为希望相互对等但不想运行
		开放 SIP 代理的 VoIP 提供商的伞式组织。TLSFED.org 的秘书担任
		X.509 认证机构,为所有成员 SIP 代理的 TLS 密钥签名。每个成员应自动
		允许来自其他成员的传入呼叫。另一方面,此联盟的配置不得干扰
		成员参与其他 VoIP 对等结构。这一切都可以通过以下配置实现
		对于名为 example.com 的参与 VoIP 运营：


- *传入 SIP 配置*
预期来自其他成员的呼叫使用 TLS 并使用客户端证书进行
			认证。为此,我们不能与 TCP/TLS 端口共享其他传入连接。因此我们需要使用
			tls_server_domain[] 为此联盟分配一个 TCP 端口。

  ```
  tls_server_domain[1.2.3.4:5066] {
   tls_certificate   = "/path/to/tlsfed/example-com.key"
   tls_private_key   = "/path/to/tlsfed/example-com.crt"
   tls_ca_list       = "/path/to/tlsfed/ca.pem"
   tls_method        = tlsv1
   tls_verify_client = 1
   tls_require_cleint_certificate = 1
  }
  		
  ```
- *传出 SIP 配置*
到其他成员的呼叫也必须使用正确的客户端证书。
			因此,需要配置 TLS 客户端域。我们使用联盟名称作为 TLS 客户端域标识符。因此,
			"tls_client_domain_avp" 的内容必须设置为此标识符
			（例如, 通过将其作为规则放入 domainpolicy 表）。

  ```
  tls_client_domain["tlsfed"] {
   tls_certificate   = "/path/to/tlsfed/example-com.key"
   tls_private_key   = "/path/to/tlsfed/example-com.crt"
   tls_ca_list       = "/path/to/tlsfed/ca.pem"
   tls_method        = tlsv1
   tls_verify_server = 1
  }
  		
  ```


#### 基于 SIP Hub 的联盟


此示例显示如何配置基于中央 SIP hub 的对等结构。


假设一个名为 "HUBFED.org" 的组织作为希望相互对等但不想运行
		开放 SIP 代理的 VoIP 提供商的伞式组织。相反,HUBFED.org 操作一个中央 SIP 代理,
		它将在所有参与成员之间转发呼叫。因此,每个成员只需要
		允许来自该中央 hub 的传入呼叫（可以通过防火墙实现）。
		这一切都可以通过以下配置实现
		对于名为 example.com 的参与 VoIP 运营：


- *DNS 配置*
目标网络宣布其在此联盟中的成员身份。

  ```
  $ORIGIN destination.example.org
  @ IN NAPTR 10 50   "U"  "D2P+SIP:fed" (
                   "!^.*$!http://HUBFED.org/!" . )
  		
  ```
- *传出 SIP 配置*
到其他成员的呼叫需要重定向到中央代理。
			domainpolicy 表只需要列出联盟并将其链接到
			中央代理的域名：

  ```
  mysql> select * from domainpolicy;
  +----+--------------------+------+-------------------+----------------+
  | id | rule               | type | att               | val            |
  +----+--------------------+------+-------------------+----------------+
  | 1  | http://HUBFED.org/ | fed  | domainreplacement | sip.HUBFED.org |
  +----+--------------------+------+-------------------+----------------+
  		
  ```


#### 隔离花园联盟


此示例假设一组 SIP 提供商在其代理之间建立了
		安全的三层网络。此网络是通过 IPsec、私有
		二层网络还是通过简单防火墙构建并不重要。我们将使用 10.x
		网络（用于隔离花园网络）和 "http://l3fed.org/"
		（作为联盟标识符）在此示例中。


此联盟的成员（例如 example.com）不能在其域的标准 SRV / A 记录中公布其
		SIP 代理的 10.x 地址,因为该地址仅对该联盟的其他成员有意义。
		为了在联盟内外启用不同的 IP 地址解析路径,"http://l3fed.org/"
		的所有成员同意在 SRV（或 A）查找之前,
		用 "l3fed" 作为目标域的前缀。


以下是 example.com 的配置：


- *DNS 配置*
目标网络宣布其在此联盟中的成员身份。

  ```
  $ORIGIN example.com
  @ IN NAPTR 10 50   "U"  "D2P+SIP:fed" (
                   "!^.*$!http://l3fed.org/!" . )
  _sip._udp      IN SRV 10 10 5060 publicsip.example.com.
  _sip._udp.l3fe IN SRV 10 10 5060 l3fedsip.example.com.
  
  publicsip      IN A   193.XXX.YYY.ZZZ 
  l3fedsip       IN A   10.0.0.42
  		
  ```
- *传出 SIP 配置*
domainpolicy 表只需要将联盟标识符链接到约定的
			前缀：

  ```
  mysql> select * from domainpolicy;
  +----+-------------------+------+--------------+-------+
  | id | rule              | type | att          | val   |
  +----+-------------------+------+--------------+-------+
  | 1  | http://l3fed.org/ | fed  | domainprefix | l3fed |
  +----+-------------------+------+--------------+-------+
  		
  ```


### 已知限制
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权
