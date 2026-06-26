---
title: "运营商路由模块"
description: "提供路由、负载均衡和黑名单功能的模块。"
---

## 管理指南


### 概述


提供路由、负载均衡和黑名单功能的模块。


该模块提供路由、负载均衡和黑名单功能。
		它在 OpenSIPS 启动时从数据库源或配置文件读取路由条目。它可以使用一个路由树（为一个运营商），或者在需要时为每个用户使用不同的路由树（每个运营商唯一）进行基于号码前缀的路由。
		它支持多个路由树域，例如用于故障转移路由或 VoIP 和 PSTN 目标的不同路由规则。


基于路由树，该模块决定哪些号码前缀被转发到哪些网关。它还可以通过比率参数分发流量。此外，可以通过哈希函数将请求分发到可预测的目标。哈希源是可配置的，有两种不同的哈希函数可用。


此模块可扩展到数百万用户，并且能够处理数十万条路由表条目。它应该能够处理更多，但目前尚未经过充分测试。在负载均衡场景中，建议使用配置文件模式，以避免数据库驱动路由带来的额外复杂性。


路由表可以通过 MI 接口重新加载和编辑（在配置文件模式下），配置文件将根据更改进行更新。数据库接口未实现此功能，因为直接在数据库上进行更改更容易。但重新加载和转储功能当然在这里也可以使用。


在配置文件模式下，某些模块功能不可完全使用，因为在配置文件中无法指定数据库表中可以存储的所有信息。这些限制的更多信息将在后面的章节中提供。对于基于用户的路由或 LCR，您应该使用数据库模式。


基本上，此模块可以替代 lcr 和调度器模块，如果您有这些模块无法妥善处理的特定性能、灵活性和/或集成要求。但对于小型安装，使用 lcr 和调度器模块可能更有意义。


如果您想在故障路由中使用此模块，则需要在重写请求 URI 后调用"append_branch()"以将消息中继到新目标。它还支持使用 carrierfailureroute 表进行数据库派生的故障路由决策。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *数据库模块*，当使用数据库作为配置数据源时。
				仅支持基于 SQL 的数据库，因为此模块需要能够
				发出原始查询。目前无法使用 dbtext 或 db_berkeley 模块。
- 当您想在"cr_next_domain"函数中使用 $T_reply_code 伪变量时的 *tm 模块*。


#### 外部库或应用程序


以下库或应用程序必须在运行
		加载了此模块的 OpenSIPS 之前安装：


- *libconfuse*，一个配置文件解析器库。
				(http://www.nongnu.org/confuse/)


### 导出的参数


#### db_url (string)


包含路由数据的数据库的 URL。


*默认值为 "mysql://opensipsro:opensipsro@localhost/opensips"。*


```c title="设置 db_url 参数"
...
modparam("carrierroute", "db_url", "dbdriver://username:password@dbhost/dbname")
...
			
```


#### db_table (string)


存储路由数据的表名。


*默认值为 "carrierroute"。*


```c title="设置 db_table 参数"
...
modparam("carrierroute", "db_table", "carrierroute")
...
		    
```


#### id_column (string)


包含 ID 标识符的列名。


*默认值为 "id"。*


```c title="设置 id_column 参数"
...
modparam("carrierroute", "id_column", "id")
...
		    
```


#### carrier_column (string)


包含运营商 ID 的列名。


*默认值为 "carrier"。*


```c title="设置 carrier_column 参数"
...
modparam("carrierroute", "carrier_column", "carrier")
...
		    
```


#### scan_prefix_column (string)


包含扫描前缀的列名。扫描前缀定义
		    电话号码的匹配部分，例如当扫描前缀为 49721 和 49，被叫号码为 49721913740 时，它匹配
		    49721，因为采用最长匹配。如果没有前缀匹配，
			则不对该号码进行路由。为防止这种情况，可以添加空前缀值""。


*默认值为 "scan_prefix"。*


```c title="设置 scan_prefix_column 参数"
...
modparam("carrierroute", "scan_prefix_column", "scan_prefix")
...
		    
```


#### domain_column (string)


包含规则域的列名。您可以定义多个路由
		    域以使用不同的路由规则。也许您将域 0 用于正常路由，域 1 用于域 0 失败时。


*默认值为 "domain"。*


```c title="设置 domain_column 参数"
...
modparam("carrierroute", "domain_column", "domain")
...
		    
```


#### flags_column (string)


包含标志的列名。


*默认值为 "flags"。*


```c title="设置 flags_column 参数"
...
modparam("carrierroute", "flags_column", "flags")
...
		    
```


#### mask_column (string)


包含标志掩码的列名。


*默认值为 "mask"。*


```c title="设置 mask_column 参数"
...
modparam("carrierroute", "mask_column", "mask")
...
		    
```


#### prob_column (string)


包含概率的列名。概率值用于在多个网关之间分配流量。假设 70% 的流量将被路由到网关 A，其余 30% 将被路由到网关 B，我们为网关 A 定义 prob 值为 0.7 的规则，网关 B 定义 prob 值为 0.3 的规则。


如果给定前缀、树和域的所有概率加起来不到 100%，
			则前缀值将根据给定的 prob 值进行调整。例如，如果定义了三个 prob 值为 0.5、0.5 和 0.4 的主机，结果概率为 35.714、35.714 和 28.571%。但最好从一开始就选择有意义的值以保持清晰。


*默认值为 "prob"。*


```c title="设置 prob_column 参数"
...
modparam("carrierroute", "prob_column", "prob")
...
		    
```


#### rewrite_host_column (string)


包含重写主机值的列名。空字段表示黑名单条目，其他任何内容都作为 SIP 消息请求 URI 的域部分放入。


*默认值为 "rewrite_host"。*


```c title="设置 rewrite_host_column 参数"
...
modparam("carrierroute", "rewrite_host_column", "rewrite_host")
...
		    
```


#### strip_column (string)


包含在 URI 的用户部分 prepend rewrite_prefix 之前要剥离的位数的列名。


*默认值为 "strip"。*


```c title="设置 strip_column 参数"
...
modparam("carrierroute", "strip_column", "strip")
...
		    
```


#### comment_column (string)


包含可选注释的列名（在大型路由表中很有用）。
		    注释也由 MI 命令"carrierroute:dump_routes"显示。


*默认值为 "description"。*


```c title="设置 comment_column 参数"
...
modparam("carrierroute", "comment_column", "description")
...
		    
```


#### carrier_table (string)


包含现有运营商的表名，由 ID 和相应名称组成。


*默认值为 "route_tree"。*


```c title="设置 carrier_table 参数"
...
modparam("carrierroute", "carrier_table", "route_tree")
...
		    
```


#### rewrite_prefix_column (string)


包含重写前缀的列名。这里您可以为 SIP URI 的本地部分定义重写前缀。


*默认值为 "rewrite_prefix"。*


```c title="设置 rewrite_prefix_column 参数"
...
modparam("carrierroute", "rewrite_prefix_column", "rewrite_prefix")
...
		    
```


#### rewrite_suffix_column (string)


包含重写后缀的列名。这里您可以为 SIP URI 的本地部分定义重写后缀。


*默认值为 "rewrite_suffix"。*


```c title="设置 rewrite_suffix_column 参数"
			    ...
modparam("carrierroute", "rewrite_suffix_column", "rewrite_suffix")
			    ...
		    
```


#### carrier_id_col (string)


运营商表中包含运营商 ID 的列名。


*默认值为 "id"。*


```c title="设置 id_col 参数"
...
modparam("carrierroute", "carrier_id_col", "id")
...
		    
```


#### carrier_name_col (string)


运营商表中包含运营商名称的列名。


*默认值为 "carrier"。*


```c title="设置 carrier_name_col 参数"
...
modparam("carrierroute", "carrier_name_col", "carrier")
...
		    
```


#### subscriber_table (string)


包含订户的表名。


*默认值为 "subscriber"。*


```c title="设置 subscriber_table 参数"
...
modparam("carrierroute", "subscriber_table", "subscriber")
...
		    
```


#### subscriber_user_col (string)


订户表中包含用户名的列名。


*默认值为 "username"。*


```c title="设置 subscriber_user_col 参数"
...
modparam("carrierroute", "subscriber_user_col", "username")
...
		    
```


#### subscriber_domain_col (string)


订户表中包含订户域的列名。
		    
*默认值为 "domain"。*


```c title="设置 subscriber_domain_col 参数"
...
modparam("carrierroute", "subscriber_domain_col", "domain")
...
		    
```


#### subscriber_carrier_col (string)


订户表中包含订户首选运营商 ID 的列名。


*默认值为 "cr_preferred_carrier"。*


```c title="设置 subscriber_carrier_col 参数"
...
modparam("carrierroute", "subscriber_carrier_col", "cr_preferred_carrier")
...
		    
```


#### config_source (string)


指定模块是从文件还是从数据库加载其配置数据。可能的值是 file 或 db。


*默认值为 "file"。*


```c title="设置 config_source 参数"
...
modparam("carrierroute", "config_source", "file")
...
		    
```


#### config_file (string)


指定配置文件的路径。


*默认值为 "/etc/opensips/carrierroute.conf"。*


```c title="设置 config_file 参数"
...
modparam("carrierroute", "config_file", "/etc/opensips/carrierroute.conf")
...
		    
```


#### default_tree (string)


默认使用的运营商树名称（如果当前订户没有首选树）。


*默认值为 "default"。*


```c title="设置 default_tree 参数"
...
modparam("carrierroute", "default_tree", "default")
...
		    
```


#### use_domain (boolean)


当使用按用户的树查找时，此参数指定是否使用域部分进行用户匹配。


*默认值为 *true*。*


```c title="设置 use_domain 参数"
...
modparam("carrierroute", "use_domain", true)
...
		    
```


#### fallback_default (int)


此参数定义使用基于用户的树查找时的行为。如果用户设置了不存在的树且 fallback_default 设置为 1，则使用默认树。否则，cr_user_rewrite_uri 返回错误。


*默认值为 "1"。*


```c title="设置 fallback_default 参数"
...
modparam("carrierroute", "fallback_default", 1)
...
		    
```


#### db_failure_table (string)


存储故障路由数据的表名。


*默认值为 "carrierfailureroute"。*


```c title="设置 db_failure_table 参数"
...
modparam("carrierroute", "db_failure_table", "carrierfailureroute")
...
		    
```


#### failure_id_column (string)


包含 ID 标识符的列名。


*默认值为 "id"。*


```c title="设置 failure_id_column 参数"
...
modparam("carrierroute", "failure_id_column", "id")
...
		    
```


#### failure_carrier_column (string)


包含运营商 ID 的列名。


*默认值为 "carrier"。*


```c title="设置 failure_carrier_column 参数"
...
modparam("carrierroute", "failure_carrier_column", "carrier")
...
		    
```


#### failure_scan_prefix_column (string)


包含扫描前缀的列名。扫描前缀定义
        电话号码的匹配部分，例如当扫描前缀为 49721 和 49，被叫号码为 49721913740 时，它匹配
        49721，因为采用最长匹配。如果没有前缀匹配，则不对该号码进行故障路由。为防止这种情况，可以添加空前缀值""。


*默认值为 "scan_prefix"。*


```c title="设置 failure_scan_prefix_column 参数"
...
modparam("carrierroute", "failure_scan_prefix_column", "scan_prefix")
...
		    
```


#### failure_domain_column (string)


包含规则域的列名。您可以定义
        多个路由域以使用不同的路由规则。也许您将域 0 用于正常路由，域 1 用于域 0 失败时。


*默认值为 "domain"。*


```c title="设置 failure_domain_column 参数"
...
modparam("carrierroute", "failure_domain_column", "domain")
...
		    
```


#### failure_host_name_column (string)


包含上次路由目标主机名的列名。


*默认值为 "host_name"。*


```c title="设置 failure_host_name_column 参数"
...
modparam("carrierroute", "failure_host_name_column", "host_name")
...
		    
```


#### failure_reply_code_column (string)


包含回复代码的列名。


*默认值为 "reply_code"。*


```c title="设置 failure_reply_code_column 参数"
...
modparam("carrierroute", "failure_reply_code_column", "reply_code")
...
		    
```


#### failure_flags_column (string)


包含标志的列名。


*默认值为 "flags"。*


```c title="设置 failure_flags_column 参数"
...
modparam("carrierroute", "failure_flags_column", "flags")
...
		    
```


#### failure_mask_column (string)


包含标志掩码的列名。


*默认值为 "mask"。*


```c title="设置 failure_mask_column 参数"
...
modparam("carrierroute", "failure_mask_column", "mask")
...
		    
```


#### failure_next_domain_column (string)


包含下一个路由域的列名。


*默认值为 "next_domain"。*


```c title="设置 failure_next_domain_column 参数"
...
modparam("carrierroute", "failure_next_domain_column", "next_domain")
...
		    
```


#### failure_comment_column (string)


包含可选注释的列名。


*默认值为 "description"。*


```c title="设置 failure_comment_column 参数"
...
modparam("carrierroute", "failure_comment_column", "description")
...
		    
```


### 导出的函数


carrierroute 的先前版本有一些更多的函数。所有旧语义都可以通过使用几个新函数来实现，如下所示：


```c
cr_rewrite_uri(domain, hash_source)
-> cr_route("default", domain, $rU, $rU, hash_source)

cr_prime_balance_uri(domain, hash_source)
-> cr_prime_route("default", domain, $rU, $rU, hash_source)

cr_rewrite_by_to(domain, hash_source)
-> cr_route("default", domain, $tU, $rU, hash_source)

cr_prime_balance_by_to(domain, hash_source)
-> cr_prime_route("default", domain, $tU, $rU, hash_source)

cr_rewrite_by_from(domain, hash_source)
-> cr_route("default", domain, $fU, $rU, hash_source)

cr_prime_balance_by_from(domain, hash_source)
-> cr_prime_route("default", domain, $fU, $rU, hash_source)

cr_user_rewrite_uri(uri, domain)
-> cr_user_carrier(user, domain, $avp(tree_avp))
-> cr_route($avp(tree_avp), domain, $rU, $rU, "call_id")

cr_tree_rewrite_uri(tree, domain)
-> cr_route(tree, domain, $rU, $rU, "call_id")
  
```


#### cr_user_carrier(user, domain, dst_avp)


此函数加载运营商并将其存储在 AVP 中。它不能用于配置文件模式，因为需要一个从给定用户到特定运营商的映射。这是从属于用户参数的数据库条目派生的。此映射必须存在于"subscriber_table"变量指定的表中。此数据不会缓存在内存中，这意味着每次执行此函数都会进行数据库查询。


参数：


- *user (string)* - 用于
			运营商树查找的用户名
- *domain (string)* - 要使用的路由域名称
- *dst_avp (var)* - 用于存储运营商 ID 的 AVP 名称


#### cr_route(carrier, domain, prefix_matching, rewrite_user, hash_source, [dst_avp])


此函数在给定运营商树的给定域中搜索 prefix_matching 中给定用户的最长匹配。使用 rewrite_user 和给定的哈希源和算法重写请求 URI。如果未找到数据或找到最长匹配中的空重写主机，则返回 -1。否则，重写的主机存储在给定的 AVP 中（如果省略，则不存储在 AVP 中）。此函数仅适用于包含仅数字字符串的 rewrite_user 和 prefix_matching。它使用标准 crc32 算法计算哈希值。


参数：


- *carrier (string)* - 要使用的路由树
- *domain (string)* - 要使用的路由域名称
- *prefix_matching (string)* - 在路由树中用于前缀匹配的用户名
- *rewrite_user (string)* - 要用于应用重写规则的用户名。通常，这是请求 URI 的用户部分
- *hash_source (string)* - 目标集的哈希值必须是连续范围，从 1 开始，由配置参数 max_targets 限制。hash_source 的可能值为：call_id、from_uri、from_user、to_uri 和 to_user。
- *dst_avp (var, optional)* - 可选的 AVP，用于存储重写的主机


#### cr_prime_route(carrier, domain, prefix_matching, rewrite_user, hash_source, [dst_avp])


此函数在给定运营商树的给定域中搜索 prefix_matching 中给定用户的最长匹配。使用 rewrite_user 和给定的哈希源和算法重写请求 URI。如果未找到数据或找到最长匹配中的空重写主机，则返回 -1。否则，重写的主机存储在给定的 AVP 中（如果省略，则不存储在 AVP 中）。此函数仅适用于包含仅数字字符串的 rewrite_user 和 prefix_matching。它使用素数哈希算法计算哈希值。


参数含义如下：


- *carrier (string)* - 要使用的路由树
- *domain (string)* - 要使用的路由域名称
- *prefix_matching (string)* - 在路由树中用于前缀匹配的用户名
- *rewrite_user (string)* - 要用于应用重写规则的用户名。通常，这是请求 URI 的用户部分
- *hash_source (string)* - 目标集的哈希值必须
            是连续范围，从 1 开始，由
            配置参数 max_targets 限制。hash_source 的可能值为：call_id、from_uri、from_user、to_uri
            和 to_user。
- *dst_avp (var, optional)* - 可选的 AVP，用于存储重写的主机


#### cr_next_domain(carrier, domain, prefix_matching, host, reply_code, dst_avp)


此函数在给定运营商故障树的给定域中搜索 prefix_matching 中给定用户的最长匹配。它尝试找到与给定主机、reply_code 和消息标志匹配的下一个域。匹配按以下顺序进行：主机、reply_code，然后是标志。reply_code 中通配符越多，标志中使用的位数越多，优先级越低。如果未找到数据或找到最长匹配中的空 next_domain，则返回 -1。否则，下一个域存储在给定的 AVP 中。此函数仅适用于包含仅数字字符串的 prefix_matching。


参数含义如下：


- *carrier (string)* - 要使用的路由树，任何伪变量都可以用作输入。
- *domain (string)* - 要使用的路由域名称
- *prefix_matching (string)* - 在路由树中用于前缀匹配的用户名
- *host (string)* - 用于故障路由规则匹配的主机名。通常，这是存储在由 cr_route 填充的 avp 中的上次尝试的路由目标
- *reply_code (string)* - 用于故障路由规则匹配的回复代码
- *dst_avp (var)* - 用于存储下一个路由域的 AVP。


### 导出的 MI 函数


所有命令都理解"-?"参数以打印简短的帮助消息。
		选项必须作为字符串引用才能传递到 MI 接口。
		除主机和新主机外的每个选项都可以用 * 进行通配符（但只能是 * 而不是类似"-d prox*"的内容）。


#### carrierroute:reload_routes


替换过时的 MI 命令：*cr_reload_routes*。


此命令从数据源重新加载路由数据。


重要提示：当添加新域时，必须重启服务器，因为配置脚本中使用的 ID 映射目前无法在运行时更新。因此，重新加载可能导致错误的路由行为，因为脚本中使用的 ID 可能与服务器内部使用的 ID 不同。修改已存在的域没有问题。


#### carrierroute:dump_routes


替换过时的 MI 命令：*cr_dump_routes*。


此命令在命令行上打印路由规则。


#### carrierroute:replace_host


替换过时的 MI 命令：*cr_replace_host*。


此命令可以替换路由规则的重写主机，仅适用于文件模式。可能的选项如下：


- *-d* - 包含主机的域
- *-p* - 包含主机的前缀
- *-h* - 要替换的主机
- *-t* - 新主机


使用"null"前缀指定空前缀。


```c title="carrierroute:replace_host 使用示例"
...
opensips-cli -x mi carrierroute:replace_host "-d proxy -p 49 -h proxy1 -t proxy2"
...
			
```


#### carrierroute:deactivate_host


替换过时的 MI 命令：*cr_deactivate_host*。


此命令停用指定的主机，即将其状态设置为 0。仅适用于文件模式。可能的选项如下：


- *-d* - 包含主机的域
- *-p* - 包含主机的前缀
- *-h* - 要停用的主机
- *-t* - 用作备份的新主机


当指定 -t (new_host) 时，停用主机的流量部分将路由到 -t 指定的主机。这在 dump_routes 的输出中指示。当主机再次激活时，备份路由被停用。


使用"null"前缀指定空前缀。


```c title="carrierroute:deactivate_host 使用示例"
...
opensips-cli -x mi carrierroute:deactivate_host "-d proxy -p 49 -h proxy1"
...
			
```


#### carrierroute:activate_host


替换过时的 MI 命令：*cr_activate_host*。


此命令激活指定的主机，即将其状态设置为 1。仅适用于文件模式。可能的选项如下：


- *-d* - 包含主机的域
- *-p* - 包含主机的前缀
- *-h* - 要激活的主机


使用"null"前缀指定空前缀。


```c title="carrierroute:activate_host 使用示例"
...
opensips-cli -x mi carrierroute:activate_host "-d proxy -p 49 -h proxy1"
...
			
```


#### carrierroute:add_host


替换过时的 MI 命令：*cr_add_host*。


此命令添加路由规则，仅适用于文件模式。可能的选项如下：


- *-d* - 包含主机的域
- *-p* - 包含主机的前缀
- *-h* - 要添加的主机
- *-w* - 规则的权重
- *-P* - 可选的重写前缀
- *-S* - 可选的重写后缀
- *-i* - 可选的哈希索引
- *-s* - 可选的剥离值


使用"null"前缀指定空前缀。


```c title="carrierroute:add_host 使用示例"
...
opensips-cli -x mi carrierroute:add_host "-d proxy -p 49 -h proxy1 -w 0.25"
...
			
```


#### carrierroute:delete_host


替换过时的 MI 命令：*cr_delete_host*。


此命令删除指定的主机或规则，即从路由树中删除它们。仅适用于文件模式。可能的选项如下：


- *-d* - 包含主机的域
- *-p* - 包含主机的前缀
- *-h* - 要添加的主机
- *-w* - 规则的权重
- *-P* - 可选的重写前缀
- *-S* - 可选的重写后缀
- *-i* - 可选的哈希索引
- *-s* - 可选的剥离值


使用"null"前缀指定空前缀。


```c title="carrierroute:delete_host 使用示例"
...
opensips-cli -x mi carrierroute:delete_host "-d proxy -p 49 -h proxy1 -w 0.25"
...
			
```


### 示例


```c title="配置示例 - 路由到默认树"
...
route {
	# 基于 callid 哈希进行路由呼叫
	# 选择默认运营商的域 0
	
	if(!cr_route("default", "0", "$rU", "$rU", "call_id", "crc32")){
		sl_send_reply(403, "不允许");
	} else {
		# 如果失败，重新路由请求
		t_on_failure("1");
		# 将请求中继到网关
		t_relay();
	}
}

failure_route[1] {
	# 如果失败，发送到备用路由：
	if (t_check_status("408|5[0-9][0-9]")) {
		#选择默认运营商的域 1
	if(!cr_route("default", "1", "$rU", "$rU", "call_id", "crc32")){
			t_reply(403, "不允许");
		} else {
			t_on_failure("2");
			t_relay();
		}
	}
}

failure_route[2] {
	# 进一步处理
}

		
```


```c title="配置示例 - 路由到用户树"
...
route[1] {
	cr_user_carrier("$fU", "$fd", "$avp(carrier)");

	# 只是一个示例域
	$avp(domain)="start";
	if (!cr_route("$avp(carrier)", "$avp(domain)", "$rU", "$rU",
			"call_id", "$avp(host)")) {
		xlog("L_ERR", "cr_route 失败\n");
		exit;
	}
	t_on_failure("1");
		if (!t_relay()) {
			sl_reply_error();
		};
}

failure_route[1] {
	revert_uri();
	if (!cr_next_domain("$avp(carrier)", "$avp(domain)", "$rU",
		"$avp(host)", "$T_reply_code", "$avp(domain)")) {
		xlog("L_ERR", "cr_next_domain 失败\n");
		exit;
	}
	if (!cr_route("$avp(carrier)", "$avp(domain)", "$rU", "$rU",
		"call_id", "$avp(host)")) {
		xlog("L_ERR", "cr_route 失败\n");
		exit;
	}
	t_on_failure("1");
	append_branch();
	if (!t_relay()) {
		xlog("L_ERR", "t_relay 失败\n");
		exit;
	};
}
...
		
```


以下配置文件在默认运营商中指定了两个域，每个域包含两个主机的前缀。它不可能在使用配置文件作为数据源时指定另一个运营商。


所有流量将在主机之间均匀分配，两个都处于活动状态。哈希算法将覆盖 [1,2] 集合，散列到 1 的消息将转到第一个主机，另一个转到第二个主机。不要使用零的哈希索引值。如果完全省略哈希，模块会为它们生成一个从一开始的自增值。


使用"NULL"前缀指定配置文件中的空前缀。请注意，前缀与请求 URI（或 to URI）匹配，如果它们不包含有效的数字 URI，则无法匹配。因此，为了负载均衡目的（例如您的注册服务器），您应该使用空前缀。


```c title="配置示例 - 模块配置"
...
domain proxy {
   prefix 49 {
     max_targets = 2
      target proxy1.localdomain {
         prob = 0.500000
         hash_index = 1
         status = 1
         comment = "test target 1"
      }
      target proxy2.localdomain {
         prob = 0.500000
         hash_index = 2
         status = 1
         comment = "test target 2"
      }
   }
}

domain register {
   prefix NULL {
     max_targets = 2
      target register1.localdomain {
         prob = 0.500000
         hash_index = 1
         status = 1
         comment = "test target 1"
      }
      target register2.localdomain {
         prob = 0.500000
         hash_index = 2
         status = 1
         comment = "test target 2"
      }
   }
}
...
			
```


### 安装和运行


#### 数据库设置


在运行带有 carrierroute 的 OpenSIPS 之前，您必须设置模块将存储路由数据的数据库表。如果表不是由安装脚本创建的，或者您选择自己安装所有内容，您可以使用
			opensips/scripts 文件夹中的数据库目录中的 carrierroute-create.sql
			SQL 脚本作为模板。
			数据库和表名可以通过模块参数设置，因此可以更改，但列名必须与 SQL 脚本中的列名相同。
			您还可以在项目网页上找到完整的数据库文档，https://opensips.org/docs/db/db-schema-devel.html。
			flags 和 mask 列的功能与 carrierfailureroute 表中的相同。flags 和 mask 列中的零值意味着任何消息标志都将匹配此规则。


对于最小配置，您可以使用的配置文件如上，或者将一些数据插入模块的表中。


```c title="示例数据库内容 - carrierroute 表"
...
+----+---------+--------+-------------+-------+------+---------------+
| id | carrier | domain | scan_prefix | flags | prob | rewrite_host  |
+----+---------+--------+-------------+-------+------+---------------+
| 1  |       1 |      0 | 49          |     0 |  0.5 | de-1.carrier1 |
| 2  |       1 |      0 | 49          |     0 |  0.5 | de-2.carrier1 |
| 3  |       1 |      0 | 49          |    16 |    1 | de-3.carrier1 |
| 4  |       1 |      0 |             |     0 |    1 | gw.carrier1-1 |
| 5  |       1 |      1 | 49          |     0 |    1 | gw.carrier1-1 |
| 6  |       1 |      2 |             |     0 |    1 | gw.carrier1-2 |
| 7  |       1 |      3 |             |     0 |    1 | gw.carrier1-3 |
| 8  |       2 |      0 | 49          |     0 |  0.5 | de-1.carrier2 |
| 9  |       2 |      0 | 49          |     0 |  0.5 | de-2.carrier2 |
| 10 |       2 |      0 |             |     0 |    1 | gw.carrier2   |
| 11 |       2 |      1 | 49          |     0 |    1 | gw.carrier2   |
| 12 |       3 |  start | 49          |     0 |    1 | de-gw.default |
| 13 |       3 |  start |             |     0 |    1 | gw.default    |
+----+---------+--------+-------------+-------+------+---------------+
...
			
```


此表包含两个网关的"49"前缀的三条路由，以及运营商 2 和运营商 1 的默认路由。默认运营商的网关将用于不支持用户特定运营商查找的函数。运营商 1 和运营商 2"49"前缀的路由规则包含一个额外的域 1 规则，可用作域 0 中的网关无法到达时的备用路由。还为运营商 1 提供了另外两个备用路由（域 2 和 3）以支持下一节中提供的 carrierfailureroute 表功能示例。字符串也可用于域，例如运营商 3。


此表还为"49"前缀提供"carrier1"路由规则，仅在设置某些消息标志时选择。如果未设置这些标志，则使用其他两条规则。为简洁起见，省略了"strip"、"mask"和"comment"列。


```c title="示例数据库内容 - 简单 carrierfailureroute 表"
...
+----+---------+--------+---------------+------------+-------------+
| id | carrier | domain | host_name     | reply_code | next_domain |
+----+---------+--------+---------------+------------+-------------+
|  1 |       1 | 0      | gw.carrier1-2 | ...        | 3           |
|  2 |       1 | 0      | gw.carrier1-3 | ...        | 2           |
+----+---------+--------+---------------+------------+-------------+
...
```


此表包含"gw.carrier1-1"和"-2"网关的两个故障路由。对于任何（故障）回复代码，选择各自的下一个域。之后没有更多的故障路由可用，cr_next_domain 函数将返回错误。为简洁起见，此处未显示所有表列。


对于添加到 carrierfailureroute 表的每个故障路由域和运营商，该表中必须至少有一个对应的 carrierroute 表条目，否则模块将不会加载路由数据。


```c title="示例数据库内容 - 更复杂的 carrierfailureroute 表"
...
+----+---------+-----------+------------+--------+-----+-------------+
| id | domain  | host_name | reply_code | flags | mask | next_domain |
+----+---------+-----------+------------+-------+------+-------------+
|  1 |      99 |           | 408        |    16 |   16 |             |
|  2 |      99 | gw1       | 404        |     0 |    0 | 100         |
|  3 |      99 | gw2       | 50.        |     0 |    0 | 100         |
|  4 |      99 |           | 404        |  2048 | 2112 | asterisk-1  |
+----+---------+-----------+------------+-------+------+-------------+
...
```


此表包含四个故障路由，展示了更高级功能的使用。第一个路由匹配 408 和某些标志，例如表示已发生振铃的标志。如果设置了此标志，将不会进一步转发，因为 next_domain 为空。第二和第三个路由匹配某些网关错误，如果发生这些错误，则会选择下一个域。最后一个路由根据某些标志进行转发，例如客户来自某个运营商并取消了呼叫转移。为使用上述路由，必须提供匹配 carrierroute 表，其中包含此路由规则的域条目。为简洁起见，此处未显示所有表列。


```c title="示例数据库内容 - route_tree 表"
...
+----+----------+
| id | carrier  |
+----+----------+
|  1 | carrier1 |
|  2 | carrier2 |
|  3 | default  |
+----+----------+
...
			
```


此表包含运营商 ID 到实际名称的映射。


对于功能性路由，必须将"cr_preferred_carrier"列添加到订户表（或您指定为模块参数的表和列）中，以选择用户的实际运营商。


建议的更改：


```c title="用户表的必要扩展"
...
ALTER TABLE subscriber ADD cr_preferred_carrier int(10) default NULL; 
...
			
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证授权。
