---
title: "perl 模块"
description: "编写新的 OpenSIPS 模块所需的时间非常高，而配置文件提供的选项仅限于模块中实现的功能。"
---

## 管理指南


### 概述


编写新的 OpenSIPS 模块所需的时间非常高，而配置文件提供的选项仅限于模块中实现的功能。


通过这个 Perl 模块，您可以轻松地用 Perl 实现自己的 OpenSIPS 扩展。这允许简单访问 CPAN 模块的完整世界。可以基于正则表达式实现 SIP URI 重写；访问任意数据后端，例如 LDAP 或 Berkeley DB 文件，现在变得非常简单。


### 安装模块


这个 Perl 模块在 opensips.cfg 中加载（就像所有其他模块一样），使用
		loadmodule("/path/to/perl.so");。


为了编译 Perl 模块，您需要一个相当新版本的 perl（用 5.8.8 测试过）并动态链接。强烈建议使用线程版本。
		您喜欢的 Linux 发行版的默认二进制包应该可以正常工作。


Makefile 支持交叉编译。您需要设置环境变量
		PERLLDOPTS、PERLCCOPTS 和 TYPEMAP 为与以下输出类似的值：


```c
PERLLDOPTS: perl -MExtUtils::Embed -e ldopts
PERLCCOPTS: perl -MExtUtils::Embed -e ccopts
TYPEMAP:    echo "`perl -MConfig -e 'print $Config{installprivlib}'`/ExtUtils/typemap"
```


您的（预编译的！）perl 库的确切位置取决于您环境的具体设置。


### 使用模块


Perl 模块有两个接口：Perl 端和 OpenSIPS 端。一旦通过模块参数定义和加载了 Perl
		函数（见下文），就可以在 OpenSIPS 配置的任意位置调用它。例如，您可以在 Perl 中编写一个
		"ldap_alias" 函数，然后执行


```c
...
if (perl_exec("ldap_alias")) {
	...
}	
...
```


就像您使用 alias_db 模块一样。


您可以使用的函数列在下面的
		[导出的函数](#exported_functions) 部分。


在 Perl 端，有许多函数可以让您读取和修改当前 SIP 消息，例如 RURI 或消息标志。
		下面可以找到 Perl 接口的介绍和完整的参考文档。


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- 需要 "sl" 模块来发送关于致命错误的回复。所有其他模块都可以从
				Perl 模块访问。


#### 外部库或应用程序


必须在运行加载了此模块的 OpenSIPS 之前安装以下库或应用程序：


- *Perl 5.8.x 或更高版本*


此外，应该安装一些 perl 模块。OpenSIPS::LDAPUtils 包依赖 Net::LDAP 的安装。其中一个示例脚本需要 IPC::Shareable


此模块使用 Perl 5.8.8 开发和测试，但应该适用于任何
		5.8.x 版本。可以用 5.6.x 编译，但不支持其行为。
		早期版本不工作。


在当前的 Debian 系统上，至少应安装以下包：


- perl
- perl-base
- perl-modules
- libperl5.8
- libperl-dev
- libnet-ldap-perl
- libipc-shareable-perl


据报道，其他 Debian 风格的发行版（如 Ubuntu）需要相同的包。


在 SuSE 系统上，至少应安装以下包：


- perl
- perl-ldap
- 来自 CPAN 的 IPC::Shareable perl 模块


虽然 SuSE 提供大量 perl 模块，但其他可能需要从
		CPAN 获取。考虑使用 "cpan2rpm" 程序——它反过来可以在 CPAN 上找到。它从 CPAN 创建 RPM 文件。


### 导出的参数


#### filename (string)


这是脚本的文件名。这只能设置一次，但可以包含任意数量的函数和 "use" 尽可能多的 Perl 模块。


*不能为空！*


```c title="设置 filename 参数"
...
modparam("perl", "filename", "/home/john/opensips/myperl.pl")
...
```


#### modpath (string)


Perl 模块（OpenSIPS.pm 等）的路径。设置此路径不是绝对必需的，因为您*可以*
			将模块安装到 Perl 的标准路径中，或者从脚本中更新
			"%INC" 变量。不过，使用此模块参数是标准行为。


```c title="设置 modpath 参数"
...
modparam("perl", "modpath", "/usr/local/lib/opensips/perl/")
...
```


### 导出的函数


#### perl_exec_simple(func, [param])


调用 perl 函数，*不*传递当前 SIP 消息。
			可用于处理非常简单的请求，这些请求不需要自己处理消息，而是返回有关环境的信息值。


第一个参数是要调用的函数。
			可以选择传递一个任意字符串作为参数。


如果成功调用了 perl 函数，函数返回 *1*；
			如果发生内部错误则返回 *-1*。请注意，它不会传播
			perl 函数的返回值。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE 和 BRANCH_ROUTE。


```c title="perl_exec_simple() 使用示例"
...
if ($rm=="INVITE") {
	perl_exec_simple("dosomething", "on invite messages");
};
...
```


#### perl_exec(func, [param])


调用 perl 函数，*传递*当前 SIP 消息。
			SIP 消息由一个 Perl 模块反映，该模块让您访问当前 SIP 消息中的信息
			（OpenSIPS::Message）。


第一个参数是要调用的函数。
			可以传递一个任意字符串作为参数。


函数将 perl 函数返回的值返回给 OpenSIPS 脚本。
			请注意，如果此值为 *0*，脚本执行将
			停止，类似于调用 *exit*。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE 和 BRANCH_ROUTE。


```c title="perl_exec() 使用示例"
...
if (perl_exec("ldapalias")) {
	...
};
...
```


## OpenSIPS Perl API


### OpenSIPS


此模块提供对有限数量的 OpenSIPS 核心函数的访问。
      由于最有趣的函数处理 SIP 消息，它们位于下面的
      OpenSIPS::Message 类中。


#### log(level,message)


使用 OpenSIPS 的日志设施记录消息。日志级别
	是以下之一：


```c
* L_ALERT
* L_CRIT
* L_ERR
* L_WARN
* L_NOTICE
* L_INFO
* L_DBG
```


请注意，此方法*不会*自动导出，因为它与 perl 函数 log（计算对数）冲突。
	要么显式导入函数（通过 `use OpenSIPS qw ( log );`），要么使用其全名调用：


```c
OpenSIPS::log(L_INFO, "foobar");
```


### OpenSIPS::Message


此包提供对 OpenSIPS `sip_msg` 结构及其子组件的访问函数。通过其方法，
      可以完全配置替代路由决策。


#### getType()


返回以下常量之一：SIP_REQUEST、SIP_REPLY、SIP_INVALID，
      表示当前消息的类型。


#### getStatus()


返回当前回复消息的状态码。此函数在请求上下文中无效！


#### getReason()


返回当前回复消息的原因。此函数在请求上下文中无效！


#### getVersion()


返回当前 SIP 消息的版本字符串。


#### getRURI()


此函数返回当前 SIP 消息的接收方 URI：


`my $ruri =
	$m->getRURI();`


getRURI 返回一个字符串。关于如何接收解析后的结构，请参见下面的 ["getParsedRURI()"](#getparsedruri)。


此函数仅在请求消息中有效。


#### getMethod()


返回当前方法，例如 `INVITE`、`REGISTER`、`ACK` 等。


`my $method =
	$m->getMethod();`


此函数仅在请求消息中有效。


#### getFullHeader()


返回当前消息中存在的完整消息头。
	您可以使用此头使用您喜欢的 MIME 包进一步处理它。


`my $hdr =
	$m->getFullHeader();`


#### getBody()


返回消息体。


#### getMessage()


返回包含头和体的完整消息。


#### getHeader(name)


返回具有此名称的第一个消息头的内容。


`print
	$m->getHeader("To");`


**`"John"
	<sip:john@doe.example>`**


#### getHeaderNames()


返回所有头名称的数组。可能存在重复！


#### moduleFunction(func,string1,string2)


在模块导出中搜索任意函数并使用参数 self、string1、string2 调用它。


`string1` 和/或 `string2` 可以省略。


由于此函数提供对导出到 OpenSIPS 配置文件的函数的访问，因此对于未知
		函数它是自动加载的。不必写


```c
$m->moduleFunction("sl_send_reply", "500", "Internal Error");
$m->moduleFunction("xlog", "L_INFO", "foo");
```


您也可以这样写


```c
$m->sl_send_reply("500", "Internal Error");
$m->xlog("L_INFO", "foo");
```


警告


在 OpenSIPS 1.2 中，只有有限的一组模块函数可用。
		此限制将在更高版本中移除。


以下是预期可用的函数列表（不声称完整）：


```c
* alias_db_lookup
* consume_credentials
* is_rpid_user_e164
* append_rpid_hf
* bind_auth
* avp_print
* cpl_process_register
* cpl_process_register_norpl
* load_dlg
* ds_next_dst
* ds_next_domain
* ds_mark_dst
* ds_mark_dst
* is_from_local
* is_uri_host_local
* dp_can_connect
* dp_apply_policy
* enum_query (无参数)
* enum_fquery (无参数)
* is_from_user_enum (无参数)
* i_enum_query (无参数)
* imc_manager
* jab_* (jabber 模块的所有函数)
* sdp_mangle_ip
* sdp_mangle_port
* encode_contact
* decode_contact
* decode_contact_header
* fix_contact
* use_media_proxy
* end_media_session
* m_store
* m_dump
* fix_nated_contact
* unforce_rtp_proxy
* force_rtp_proxy
* fix_nated_register
* add_rcv_param
* options_reply
* checkospheader
* validateospheader
* requestosprouting
* checkosproute
* prepareosproute
* prepareallosproutes
* checkcallingtranslation
* reportospusage
* mangle_pidf
* mangle_message_cpim
* add_path (无参数)
* add_path_received (无参数)
* prefix2domain
* allow_routing (无参数)
* allow_trusted
* pike_check_req
* handle_publish
* handle_subscribe
* stored_pres_info
* bind_pua
* send_publish
* send_subscribe
* pua_set_publish
* loose_route
* record_route
* load_rr
* sip_trace
* sl_reply_error
* sd_lookup
* sstCheckMin
* append_time
* has_body (无参数)
* is_peer_verified
* t_newtran
* t_release
* t_relay (无参数)
* t_flush_flags
* t_check_trans
* t_was_cancelled
* uac_restore_from
* uac_auth
* has_totag
* tel2sip
* check_to
* check_from
* radius_does_uri_exist
* ul_* (usrloc 模块导出的用于用户访问的所有函数)
* xmpp_send_message
```


#### log(level,message)（已弃用的类型）


使用 OpenSIPS 的日志设施记录消息。日志级别是以下之一：


```c
* L_ALERT
* L_CRIT
* L_ERR
* L_WARN
* L_NOTICE
* L_INFO
* L_DBG
```


日志函数应通过 OpenSIPS 模块变体访问。
		位于 OpenSIPS::Message 中的这个是已弃用的。


#### rewrite_ruri(newruri)


设置新的目标（接收方）URI。用于重新路由当前消息/呼叫。


```c
if ($m->getRURI() =~ m/\@somedomain.net/) {
  $m->rewrite_ruri("sip:dispatcher\@organization.net");
}
```


#### setFlag(flag)


设置消息标志。包含 Constants.pm 时可以使用 C API 中已知的常量。


#### resetFlag(flag)


重置消息标志。


#### isFlagSet(flag)


返回消息标志是否已设置。


#### pseudoVar(string)


返回一个所有伪变量都被其值替换的新字符串。
		也可用于接收单个变量的值。


**请记住，您需要在 perl 字符串中转义
		'$' 符号！**


#### append_branch(branch,qval)


向当前消息追加一个分支。


#### serialize_branches(clean_before, keep_order)


序列化分支。


#### next_branches()


下一个分支。


#### getParsedRURI()


将当前目标 URI 作为 OpenSIPS::URI 对象返回。


### OpenSIPS::URI


此包提供对 sip_uri 结构访问的函数。


#### user()


返回此 URI 的 user 部分。


#### host()


返回此 URI 的 host 部分。


#### passwd()


返回此 URI 的 passwd 部分。


#### port()


返回此 URI 的 port 部分。


#### params()


返回此 URI 的 params 部分。


#### headers()


返回此 URI 的 headers 部分。


#### transport()


返回此 URI 的 transport 部分。


#### ttl()


返回此 URI 的 ttl 部分。


#### user_param()


返回此 URI 的 user_param 部分。


#### maddr()


返回此 URI 的 maddr 部分。


#### method()


返回此 URI 的 method 部分。


#### lr()


返回此 URI 的 lr 部分。


#### r2()


返回此 URI 的 r2 部分。


#### transport_val()


返回此 URI 的 transport_val 部分。


#### ttl_val()


返回此 URI 的 ttl_val 部分。


#### user_param_val()


返回此 URI 的 user_param_val 部分。


#### maddr_val()


返回此 URI 的 maddr_val 部分。


#### method_val()


返回此 URI 的 method_val 部分。


#### lr_val()


返回此 URI 的 lr_val 部分。


#### r2_val()


返回此 URI 的 r2_val 部分。


### OpenSIPS::AVP


此包提供对 OpenSIPS AVP 的访问函数。这些变量可以通过此包创建、评估、修改和删除。


请注意，这些函数*不*支持配置文件使用的表示法，而是直接处理字符串或数字。
      有关详细信息，请参见下面的 add 方法文档。


#### add(name,val)


添加一个 AVP。


向其环境添加一个 OpenSIPS AVP。name 和 val 可以都是整数或字符串；
		此函数将尝试猜测正确的是什么。请注意


```c
OpenSIPS::AVP::add("10", "10")
```


与


```c
OpenSIPS::AVP::add(10, 10)
```


不同，因为此求值：第一个将创建名称为 10 的 _string_ AVP，而第二个将创建一个数值 AVP。


您可以使用此函数修改/覆盖 AVP。


#### get(name)


获取一个 OpenSIPS AVP：


```c
my $numavp = OpenSIPS::AVP::get(5);
my $stravp = OpenSIPS::AVP::get("foo");
```


#### destroy(name)


销毁一个 AVP。


```c
OpenSIPS::AVP::destroy(5);
OpenSIPS::AVP::destroy("foo");
```


### OpenSIPS::Utils::PhoneNumbers


OpenSIPS::Utils::PhoneNumbers - 电话号码规范形式的函数。


```c
use OpenSIPS::Utils::PhoneNumbers;

my $phonenumbers = new OpenSIPS::Utils::PhoneNumbers(
     publicAccessPrefix => "0",
     internationalPrefix => "+",
     longDistancePrefix => "0",
     areaCode => "761",
     pbxCode => "456842",
     countryCode => "49"
   );

$canonical = $phonenumbers->canonicalForm("07612034567");
$number    = $phonenumbers->dialNumber("+497612034567");
```


以加号开头并包含所有拨号前缀的电话号码处于规范形式。
      这通常不是在任何位置拨打的号码，因此拨号号码取决于用户/系统的上下文。


规范号码的想法来自 hylafax。


示例：+497614514829 是我的电话号码的规范形式，829 是 Pyramid 拨打的号码，
      4514829 是从弗赖堡地区拨打的号码，以此类推。


为了规范任何号码，我们剥离我们找到的任何拨号前缀，然后添加该位置的 prefixes。
      因此，当用户在 pyramid 上下文中输入号码 04514829 时，我们删除 publicAccessPrefix
      （在 Pyramid 这是 0）和 pbxPrefix（这里为 4514）。结果是 829。
      然后我们添加所有通用拨号前缀 - 49（国家）、761（地区）、4514（pbx）和 829，号码本身 => +497614514829


要从规范电话号码获取拨号号码，我们减去所有通用前缀，直到得到某个数字


如前所述，电话号码的解释取决于位置上下文。
      对于此包中的函数，上下文是通过 `new` 运算符创建的。


应设置以下字段：


```c
'longDistancePrefix' 
'areaCode'
'pbxCode' 
'internationalPrefix'
'publicAccessPrefix'
'countryCode'
```


当 `use` 此模块时，它导出以下函数：


#### new(publicAccessPrefix,internationalPrefix,longDistancePrefix,countryCode,areaCode,pbxCode)


new 运算符返回此类型的对象，并根据传递的参数设置其位置上下文。参见上方的
		OpenSIPS::Utils::PhoneNumbers。


#### canonicalForm( number [, context] )


将电话号码（作为第一个参数）转换为其规范形式。
		当没有上下文作为第二个参数传递时，使用系统配置文件中的默认上下文。


#### dialNumber( number [, context] )


将规范电话号码（作为第一个参数）转换为一个要拨打的号码。
		当没有上下文作为第二个参数传递时，使用系统配置文件中的默认上下文。


### OpenSIPS::LDAPUtils::LDAPConf


OpenSIPS::LDAPUtils::LDAPConf - 从标准配置文件读取 openldap 配置。


```c
use OpenSIPS::LDAPUtils::LDAPConf;
my $conf = new OpenSIPS::LDAPUtils::LDAPConf();
```


此模块可用于检索其他 LDAP 软件使用的全局 LDAP 配置，例如 `nsswitch.ldap` 和 `pam-ldap`。
      配置通常存储在 `/etc/openldap/ldap.conf` 中。


当从具有足够权限的账户使用时（例如 root），
      也会检索 ldap manager 密码。


#### 构造函数 new()


返回一个新的、初始化的 `OpenSIPS::LDAPUtils::LDAPConf` 对象。


#### 方法 base()


返回执行查询时要使用的服务器 base-dn。


#### 方法 host()


返回要联系的 ldap 主机。


#### 方法 port()


返回 ldap 服务器的端口。


#### 方法 uri()


返回要联系的 ldap 服务器的 uri。
		当配置文件中没有 ldap_uri 时，从 host 和 port 构造一个 `ldap:` uri。


#### 方法 rootbindpw()


返回 ldap "root" 密码。


请注意，`rootbindpw`
		仅在当前账户有足够权限访问 `/etc/openldap/ldap.secret` 时可用。


#### 方法 rootbinddn()


返回用于 "root" 访问 ldap 服务器的 DN。


#### 方法 binddn()


返回用于向 ldap 服务器进行身份验证的 DN。
		当配置文件中没有指定 bind dn 时，返回 `rootbinddn`。


#### 方法 bindpw()


返回用于向 ldap 服务器进行身份验证的密码。
		当没有指定 bind 密码时，如果存在则返回 `rootbindpw`。


### OpenSIPS::LDAPUtils::LDAPConnection


OpenSIPS::LDAPUtils::LDAPConnection - 执行简单 LDAP 查询的 Perl 模块。


OO 风格接口：


```c
use OpenSIPS::LDAPUtils::LDAPConnection;
my $ldap = new OpenSIPS::LDAPUtils::LDAPConnection;
my @rows = $ldap-search("uid=andi","ou=people,ou=coreworks,ou=de");
```


过程式接口：


```c
use OpenSIPS::LDAPUtils::LDAPConnection;
my @rows = $ldap->search(
      new OpenSIPS::LDAPUtils::LDAPConfig(), "uid=andi","ou=people,ou=coreworks,ou=de");
```


此 perl 模块提供了 `Net::LDAP` 功能的简化接口。
      它适用于只应检索少量属性而不需要完整 `Net::LDAP` 开销的情况。


#### 构造函数 new( [config, [authenticated]] )


设置一个新的 LDAP 连接。


第一个参数（如果给定）应该是一个哈希引用，指向连接参数，
		可能是一个 `OpenSIPS::LDAPUtils::LDAPConfig` 对象。
		此参数可能是 `undef`，在这种情况下，使用新的（默认的）
		`OpenSIPS::LDAPUtils::LDAPConfig` 对象。


当可选的第二个参数为真值时，连接将被认证。
		否则执行匿名绑定。


成功时，返回一个新的 `LDAPConnection` 对象，
		否则结果为 `undef`。


#### 函数/方法 search( conf, filter, base, [requested_attributes ...])


执行 ldap 搜索，返回第一个匹配目录条目的 dn，
		除非请求了特定属性，在这种情况下返回该属性的值。


当第一个参数（conf）是一个 `OpenSIPS::LDAPUtils::LDAPConnection` 时，
		它将用于执行查询。您可以使用 "方法" 语法隐式传递第一个参数。


否则 `conf` 参数应该是一个哈希引用的引用，
		包含连接设置参数，如 `OpenSIPS::LDAPUtils::LDAPConf` 对象中所包含的。
		在这种模式下，将重用先前查询的 `OpenSIPS::LDAPUtils::LDAPConnection`。


##### 参数：


**conf**


配置对象，用于查找 host、port、suffix 和 use_ldap_checks


**filter**


ldap 搜索过滤器，例如 '(mail=some@domain)'


**base**


此查询的搜索基础。如果为 undef 使用默认后缀，
		如果最后一个字符是 ','，则将 base 与默认后缀连接


**requested_attributes**


从 ldap 目录检索给定属性而不是 dn


##### 结果：


没有任何特定的 `requested_attributes`，返回 LDAP 目录中所有匹配条目的 dn。


当给出一些 `requested_attributes` 时，
		返回一个包含这些属性的数组。当多个条目匹配查询时，属性列表会被连接起来。


### OpenSIPS::VDB


此包是所有虚拟数据库的（抽象）基类。派生包可以配置为由 OpenSIPS 用作数据库。


基类本身不应在此上下文中使用，因为它不提供任何功能。


### OpenSIPS::Constants


此包提供从 OpenSIPS 头文件的枚举和定义中获取的大量常量。
      不幸的是，没有自动更新常量的机制，所以如有疑问请检查值。


### OpenSIPS::VDB::Adapter::Speeddial


此适配器可用于 speeddial 模块。


### OpenSIPS::VDB::Adapter::Alias


此包旨在与 alias_db 模块一起使用。
		查询 VTab 需要两个参数并返回两个参数（用户名/域名）的数组。


#### query(conds,retkeys,order)


使用给定的参数查询 vtab 以获取请求条件、返回键和排序列名。


### OpenSIPS::VDB::Adapter::AccountingSIPtrace


此包是 acc 和 tracer 模块的适配器，只提供插入操作。


### OpenSIPS::VDB::Adapter::Describe


此包用于调试目的。它将打印有关客户端模块请求的函数和操作的信息。


在创建新适配器时使用此模块请求模式信息。


### OpenSIPS::VDB::Adapter::Auth


此适配器旨在与 auth_db 模块一起使用。
		VTab 应该接受一个用户名作为参数并返回一个（纯文本！）密码。


### OpenSIPS::VDB::ReqCond


此包表示数据库访问的请求条件，由列名、运算符（=、<、>、...）、
		数据类型和值组成。


此包继承自 OpenSIPS::VDB::Pair，因此包含其方法。


#### new(key,op,type,name)


构造一个新的列对象。


#### op()


返回或设置当前运算符。


### OpenSIPS::VDB::Pair


此包表示数据库键/值对，由键、值类型和值组成。


此包继承自 OpenSIPS::VDB::Value，因此具有相同的方法。


#### new(key,type,name)


构造一个新的列对象。


#### key()


返回或设置当前键。


### OpenSIPS::VDB::VTab


此包处理虚拟表，由 OpenSIPS::VDB 类用来存储有关有效表的信息。
		此包不适用于最终用户访问。


#### new()


```c
构造一个新的 VTab 对象
```


#### call(op,[args])


使用给定参数调用表上的操作（插入、更新、...）。


### OpenSIPS::VDB::Value


此包表示数据库值。除数据本身外，还存储有关其类型的信息。


#### 字符串化


当将 OpenSIPS::VDB::Value 对象作为字符串访问时，它只返回其数据而不管其类型。=cut


use strict;


package OpenSIPS::VDB::Value;


use overload '""' => \&stringify;


sub stringify { shift->{data} }


use OpenSIPS; use OpenSIPS::Constants;


our @ISA = qw ( OpenSIPS::Utils::Debug );


#### new(type,data)


构造一个新的值对象。其数据类型和数据作为参数传递。


#### type()


返回或设置当前数据类型。请考虑使用 OpenSIPS::Constants 中的常量


#### data()


返回或设置当前数据。


### OpenSIPS::VDB::Column


此包表示数据库列定义，由列名及其数据类型组成。


#### 字符串化


当将 OpenSIPS::VDB::Column 对象作为字符串访问时，它只返回其列名而不管其类型。=cut


package OpenSIPS::VDB::Column;


use overload '""' => \&stringify;


sub stringify { shift->{name} }


use OpenSIPS; use OpenSIPS::Constants;


our @ISA = qw ( OpenSIPS::Utils::Debug );


#### new(type,name)


构造一个新的列对象。其类型和名称作为参数传递。


#### type( )


返回或设置当前类型。请考虑使用 OpenSIPS::Constants 中的常量


#### name()


返回或设置当前列名。


#### OpenSIPS::VDB::Result


此类表示 VDB 结果集。它包含列定义，加上一系列行。
		行本身就是对标量数组的引用。


#### new(coldefs,[row, row, ...])


构造函数创建一个新的 Result 对象。它的第一个参数是对 OpenSIPS::VDB::Column 对象数组的引用。
		可以传递其他参数以提供初始行，这些行是对标量数组的引用。


#### coldefs()


```c
返回或设置对象的列定义。
```


#### rows()


```c
返回或设置对象的行。
```


## Perl 示例


### 示例目录


"samples/" 中有许多示例脚本。它们有很好的文档。
		阅读它们，它会向您解释很多：)


如果您想在自己的实现中直接使用这些脚本中的任何一个，
		您可以使用 Perl 的 "require" 机制导入它们（请记住，
		require .pl 文件时需要使用引号）。


#### 脚本描述


下面描述了包含的示例脚本：


##### branches.pl


branches.pl 中的最小函数演示了您可以从 perl 中访问 "append_branch" 函数，
				就像您从正常配置文件中执行操作一样。您可以在 OpenSIPS 文档中找到有关分支概念的文档。


##### firstline.pl


可以评估消息的 first_line 结构。消息可以是 SIP_REQUEST 或 SIP_REPLY。
				根据不同，可以接收不同的信息。此脚本演示了这些函数。


##### flags.pl


perl 模块提供对 OpenSIPS 标志机制的访问。OpenSIPS 模块可用的标志名称通过 OpenSIPS::Constants 包提供，
				因此您可以将消息标记为 "green"、"magenta" 等。


第一个函数 setflag 演示了如何设置 "green" 标志。在第二个函数 readflag 中，
				评估 "green" 和 "magenta" 标志。


##### functions.pl


此示例脚本演示了从 perl 内部调用函数以及您可以为 OpenSIPS 访问提供的不同类型函数的相关内容。


"exportedfuncs" 简单地演示了您可以使用 moduleFunction 方法调用其他模块提供的函数。
				结果等同于从配置文件中调用这些函数。在演示的例子中，
				以 555... 开头的目标号码的电话被内部服务器错误拒绝。
				其他目标地址被传递给 alias_db 模块。


请注意，moduleFunction 方法在 OpenSIPS 1.2 中不完全可用。
				有关详细信息，请参见该方法的文档。


"paramfunc" 显示您可以将任意字符串传递给 perl 函数。
				用它们做你想做的：)


"autotest" 演示了 OpenSIPS::Message 对象中的未知函数会自动转换为对模块函数的调用。


"diefuncs" 显示 perl 脚本的消亡——通过 "手动" 消亡，或因为脚本错误——由 OpenSIPS 包处理。
				错误消息通过 OpenSIPS 的日志机制记录。
				请注意，这仅在您不覆盖默认 die 处理程序时才能正常工作。
				哦，是的，警告也一样。


##### headers.pl


在处理 SIP 消息时，头提取是最关键的功能之一。
				此示例脚本演示了在两个示例函数中访问头名称和值。


"headernames" 提取所有头名称并记录它们的名称。


"someheaders" 记录两个头 "To" 和 "WWW-Contact" 的内容。
				如您所见，出现多次的头作为数组检索，
				可以通过 Perl 的数组访问方法访问。


##### logging.pl


为了调试目的，您可能希望将消息写入 syslog。
				"logdemo" 展示了三种访问 OpenSIPS 日志函数的方式：
				它可以通过 OpenSIPS 类以及 OpenSIPS::Message 类访问。


请记住，您可以使用其他模块导出的函数。
				因此您也可以使用 "xlog" 模块及其 xlog 函数。


L_INFO、L_DBG、L_ERR、L_CRIT... 常量可通过 OpenSIPS::Constants 包获得。


##### messagedump.pl


此脚本演示了如何访问当前消息的整个消息头。
				请注意，早期函数调用在配置脚本中对消息所做的修改可能不会反映在此转储中。


##### persistence.pl


在处理 SIP 消息时，您可能希望在多次调用 Perl 函数时使用持久数据。
				您的第一个选择是在脚本中使用全局变量。
				不幸的是，这些全局变量在 OpenSIPS 的多个实例中不可见。
				您可能希望使用 IPC::Shareable 共享内存访问包来纠正这一点。


##### phonenumbers.pl


OpenSIPS::Utils::PhoneNumbers 包提供了将本地电话号码转换为规范形式的方法，反之亦然。
				此脚本演示了它的用法。


##### pseudovars.pl


此脚本演示了 Perl 模块的 "pseudoVar" 方法。
				它可用于检索当前伪变量的值。


您可能注意到没有设置伪变量的特定函数；
				不过您可以使用 sqlops 模块导出的函数。


## 常见问题


**Q：Perl 模块是否有已知错误？**


Perl 模块确实有一些可以被视为错误的缺点。


**Q：在哪里可以找到更多关于 OpenSIPS 的信息？**


请查看 [https://opensips.org/](https://opensips.org/)。


**Q：在哪里可以发布关于此模块的问题？**


首先检查您的问题是否已在我们某个邮件列表上得到解答：


关于任何稳定 OpenSIPS 版本的电子邮件应发送到 
			users@lists.opensips.org，关于开发版本的电子邮件应发送到 devel@lists.opensips.org。


如果您想保密邮件，请发送至 
			users@lists.opensips.org。


**Q：如何报告错误？**


请遵循以下指南：
			[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
