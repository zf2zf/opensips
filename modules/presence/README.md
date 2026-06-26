---
title: "Presence 模块"
description: "该模块处理 PUBLISH 和 SUBSCRIBE 消息，并以通用的、事件无关的方式生成 NOTIFY 消息。它允许从其他 OpenSIPS 模块注册事件。当前可以添加的事件有：*presence*、*presence.winfo*、*dialog;sla* 来自 presence_xml 模块 *mes..."
---

## 管理指南


### 概述


该模块处理 PUBLISH 和 SUBSCRIBE 消息，并以通用的、事件无关的方式生成
		NOTIFY 消息。它允许从其他 OpenSIPS 模块注册事件。当前可以添加的事件有：


- *presence*、*presence.winfo*、
		*dialog;sla* 来自 presence_xml 模块
- *message-summary* 来自 presence_mwi 模块
- *call-info*、*line-seize* 来自
		presence_callinfo 模块
- *dialog* 来自 presence_dialoginfo 模块
- *xcap-diff* 来自 presence_xcapdiff 模块
- *as-feature-event* 来自 presence_dfks 模块


该模块使用数据库存储。后来改进了内存缓存操作以提高性能。
		订阅对话框信息存储在内存中，并定期更新到数据库，
		而对于 Publish，仅在内存中维护是否存在针对某个资源的存储信息，
		以避免不必要的、昂贵的数据库操作。
		可以配置回退到数据库模式（通过设置模块参数 "fallback2db"）。
		在此模式下，如果缓存中找不到搜索的记录，则继续在数据库中搜索。
		这对于处理和内存负载可能分布在使用同一数据库的多台机器上的架构很有用。


该模块也可以仅作为库的功能工作，不处理消息和生成，
		仅用于导出的函数。
		如果 db_url 参数未设置为任何值，则启用此操作模式。


服务器遵循以下规范：RFC3265、RFC3856、RFC3857、RFC3858。


### Presence 集群


要阅读和理解 presence 集群、其能力以及如何实现高可用性、负载均衡或联邦等场景，
		请参阅此文章 [https://blog.opensips.org/2018/03/27/clustering-presence-services-with-opensips-2-4/](https://blog.opensips.org/2018/03/27/clustering-presence-services-with-opensips-2-4/)。


由于在 using the *full-sharing* [集群联邦模式](#param_cluster_federation_mode) 时执行启动时的数据同步，
		在这种情况下，您应在集群中定义至少一个 "seed" 节点。


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *数据库模块*。
- *signaling*。
- *clusterer*，如果设置了 cluster_id 模块参数并激活了集群支持。


#### 外部库或应用程序


- *libxml-dev*。


### 导出的参数


#### db_url(str)


数据库 URL。


如果设置，该模块是一个功能完整的 presence 服务器。
		否则，它被用作"库"，仅用于其导出的函数。


*默认值为 "NULL"。*


```c title="设置 db_url 参数"
...
modparam("presence", "db_url", 
	"mysql://opensips:opensipsrw@192.168.2.132/opensips")
...
```


#### fallback2db (int)


设置此参数可启用回退到数据库操作模式。
		在此模式下，如果缓存中找不到搜索的记录，
		则继续在数据库中搜索。对于处理和内存负载可能分布在使用同一数据库的多台机器上的架构很有用。


```c title="设置 fallback2db 参数"
...
modparam("presence", "fallback2db", 1)
...
```


#### cluster_id (int)


此 presence 服务器所属集群的 ID。
		仅在需要集群模式时使用此参数。
		要了解集群 ID 的概念，请参见 *clusterer* 模块。


此 OpenSIPS 集群公开 **"presence"** 能力，以将节点标记为在任意同步请求期间有资格成为数据贡献者。
		因此，集群必须至少有一个节点标记为 *clusterer.flags* 列/属性中的 **"seed"** 值才能完全正常运行。
		有关更多详细信息，请参阅 [clusterer - 能力](../clusterer#capabilities) 章节。


有关 presence 集群的更多信息，请参见 [presence 集群](#presence_clustering) 章节。


*默认值为 "None"。*


```c title="设置 cluster_id 参数"
...
modparam("presence", "cluster_id", 2)
...
```


#### cluster_federation_mode (str)


启用联邦模式时，presence 集群内的节点将通过集群支持开始向其他节点广播数据。


*可能的值：*


- *disabled* - 联邦模式被禁用
- *on-demand-sharing* - 每个节点保留最少必要的信息。
				非本地订阅者的复制信息被丢弃，新订阅者的查询在集群中广播。
- *full-sharing* - 即使没有本地订阅者，也会在所有 presence 节点上保留发布的状态。


如果您不想使用共享数据库（通过 [fallback2db](#param_fallback2db)），
		但仍希望各地都有完整数据集，则可以选择 *full-sharing* 模式。
		此模式允许您切换 PUBLISH 端点，即使对于已发布的 Event States，
		从而允许您添加和删除 presence 服务器而不会丢失状态。


有关 presence 集群的更多信息，请参见 [presence 集群](#presence_clustering) 章节。


*默认值为 "disabled"。*


```c title="设置 cluster_federation_mode 参数"
...
modparam("presence", "cluster_federation_mode", "full-sharing")
...
```


#### cluster_pres_events (str)


逗号分隔值（CSV）列表，包含联邦集群要考虑的事件——只有发布这些事件之一的 presentities
		将通过集群广播。


有关 presence 集群的更多信息，请参见 [presence 集群](#presence_clustering) 章节。


*默认值为 "empty"（意味着全部）。*


```c title="设置 cluster_pres_events 参数"
...
modparam("presence", "cluster_pres_events" ,"presence, dialog;sla, message-summary")
...
```


#### cluster_be_active_shtag (str)


集群共享标签的名称，用于指示此节点（作为集群的一部分）何时应处于活动或非活动状态。
		如果共享标签关闭（或作为备份），该节点将从集群角度变为非活动状态，
		意味着不发送也不接受任何 presence 相关的集群流量。


节点的这种变为非活动状态的能力可用于创建联邦集群，
		其中两个节点作为本地活动-备份设置（用于本地高可用性目的）。


此参数仅在集群模式有意义。如果未定义，节点将始终处于活动状态。


有关 presence 集群的更多信息，请参见 [presence 集群](#presence_clustering) 章节。


*默认值为 "empty"（未定义标签）。*


```c title="设置 cluster_be_active_shtag 参数"
...
modparam("presence", "cluster_be_active_shtag" ,"local_ha")
...
```


#### expires_offset (int)


存储订阅/发布的额外时间。


*默认值为 "0"。*


```c title="设置 expires_offset 参数"
...
modparam("presence", "expires_offset", 10)
...
```


#### max_expires_subscribe (int)


SUBSCRIBE 消息的最大允许 expires 值。


*默认值为 "3600"。*


```c title="设置 max_expires_subscribe 参数"
...
modparam("presence", "max_expires_subscribe", 3600)
...
```


#### max_expires_publish (int)


PUBLISH 消息的最大允许 expires 值。


*默认值为 "3600"。*


```c title="设置 max_expires_publish 参数"
...
modparam("presence", "max_expires_publish", 3600)
...
```


#### contact_user (str)


这将是在 200 OK 回复中对 SUBSCRIBE 和后续同-dialog NOTIFY 请求的 Contact 头中使用的用户名。
		Contact 的 IP 地址、端口和传输将根据接收 SUBSCRIBE 的接口自动确定。


如果设置为空字符串，则不会向 contact 添加用户名，
		contact 将仅由 IP、端口和传输构建。


*默认值为 "presence"。*


```c title="设置 contact_user 参数"
...
modparam("presence", "contact_user", "presence")
...
			
```


#### enable_sphere_check (int)


如果权限规则包括球体检查，则应设置此参数。
		球体信息预计存在于 presentity 发布的 RPID 正文中。
		引入此标志是因为此检查需要额外的处理，如果客户端不支持此功能，则应避免。


*默认值为 "0 "。*


```c title="设置 enable_sphere_check 参数"
...
modparam("presence", "enable_sphere_check", 1)
...
		
```


#### waiting_subs_daysno (int)


如果在服务器数据库中订阅处于待定或等待状态（没有为其定义授权策略，
			或者目标用户没有注册并且没有被通知），
			则保留订阅记录的天数。


*默认值为 "3" 天。最大接受值为 30 天。*


```c title="设置 waiting_subs_daysno 参数"
...
modparam("presence", "waiting_subs_daysno", 2)
...
		
```


#### mix_dialog_presence (int)


此模块参数在 presence 服务器中启用了一个非常好的功能——从对话框状态生成 presence 信息。
		如果设置此参数，presence 服务器将告诉您好友是否正在通话，
		即使他的电话没有发送包含此信息的 presence Publish。
		您需要加载 dialoginfo 模块、presence_dialoginfo、pua_dialoginfo、dialog 和 pua。


*默认值为 "0"。*


```c title="设置 mix_dialog_presence 参数"
...
modparam("presence", "mix_dialog_presence", 1)
...
		
```


#### bla_presentity_spec (str)


默认情况下，BLA 订阅（event=dialog;sla）的 presentity URI 由 contact 用户名 + from domain 计算。
		但在某些情况下，这种计算 presentity 的方式可能不正确
		（例如，如果您有 SBC 在前面伪装 contact）。
		所以我们添加了这个参数，允许定义自定义 URI 作为 BLA 订阅的 presentity URI。
		您应该将此参数设置为一个伪变量的名称，然后在调用
		[handle subscribe](#func_handle_subscribe) 函数之前将此伪变量设置为您想要的 URI。


*默认值为 "NULL"。*


```c title="设置 bla_presentity_spec 参数"
...
modparam("presence", "bla_presentity_spec", "$var(bla_pres)")
...
		
```


#### bla_fix_remote_target (int)


Polycom 在 bla 实现中有一个错误。它在 Notify 正文中插入了远程 IP contact，
			当电话接听由同一 BLA 组中另一部电话保持的呼叫时，
			它会直接向远程 IP 发送 Invite。
			OpenSIPS BLA 服务器尝试通过用域名替换 IP contact 来防止这种情况（当可能时）。


但在某些情况（配置）下这是不可取的，
			所以引入了此参数以便在需要时禁用此行为。


*默认值为 "1"。*


```c title="设置 bla_fix_remote_target 参数"
...
modparam("presence", "bla_fix_remote_target", 0)
...
		
```


#### notify_offline_body (int)


如果设置此参数，当找不到用户的发布信息时，
			presence 服务器将生成一个带有 'closed' 状态的虚拟正文，
			并在发送 Notify 时使用它，而不是发送无正文的 Notify。


*默认值为 "0"。*


```c title="设置 notify_offline_body 参数"
...
modparam("presence", "notify_offline_body", 1)
...
		
```


#### end_sub_on_timeout (int)


当收到已发送 NOTIFY 请求的 SIP 超时（408）时，
			presence 订阅是否应自动终止（销毁）。


*默认值为 "1"（启用）。*


```c title="设置 end_sub_on_timeout 参数"
...
modparam("presence", "end_sub_on_timeout", 0)
...
		
```


#### clean_period (int)


清理过期订阅对话框的周期。


*默认值为 "100"。零或负值禁用此活动。*


```c title="设置 clean_period 参数"
...
modparam("presence", "clean_period", 100)
...
```


#### db_update_period (int)


将缓存的订阅者信息与数据库同步的周期。


*默认值为 "100"。零或负值禁用同步。*


```c title="设置 db_update_period 参数"
...
modparam("presence", "db_update_period", 100)
...
```


#### presentity_table(str)


存储 Publish 信息的数据库表名。


*默认值为 "presentity"。*


```c title="设置 presentity_table 参数"
...
modparam("presence", "presentity_table", "presentity")
...
```


#### active_watchers_table(str)


存储活动订阅信息的数据库表名。


*默认值为 "active_watchers"。*


```c title="设置 active_watchers_table 参数"
...
modparam("presence", "active_watchers_table", "active_watchers")
...
```


#### watchers_table(str)


存储订阅状态的数据库表名。


*默认值为 "watchers"。*


```c title="设置 watchers_table 参数"
...
modparam("presence", "watchers_table", "watchers")
...
```


#### subs_htable_size (int)


存储订阅对话框的哈希表大小。
		此参数在计算表大小时将用作 2 的幂。


*默认值为 "9 (512)"。*


```c title="设置 subs_htable_size 参数"
...
modparam("presence", "subs_htable_size", 11)
...
	
```


#### pres_htable_size (int)


存储发布记录的哈希表大小。
		此参数在计算表大小时将用作 2 的幂。


*默认值为 "9 (512)"。*


```c title="设置 pres_htable_size 参数"
...
modparam("presence", "pres_htable_size", 11)
...
	
```


### 导出的函数


#### handle_publish([sender_uri])


该函数处理 PUBLISH 请求。它在数据库中存储和更新发布的信息，
		并在发布的信息发生变化时调用函数发送 NOTIFY 消息。


它可以接受一个可选的字符串参数 'sender_uri' SIP URI。
		添加此参数是为了启用 BLA 实现。如果存在，
		不会将状态变化的通知发送到该 URI，即使存在订阅。
		它应该从 Sender 头中获取。管理员可以决定是否将此头的内容作为参数传递给 handle_publish，
		以防止安全问题。


此函数可用于 REQUEST_ROUTE。


*返回码：*


- *1 - 成功*。
- *-1 - 错误*。


模块在所有情况下都会发送适当的无状态回复。


```c title="handle_publish 使用示例"
...
	if(is_method("PUBLISH"))
	{
		if($hdr(Sender)!= NULL)
			handle_publish($hdr(Sender));
		else
			handle_publish();
	} 
...
```


#### handle_subscribe([force_active] [,sharing_tag])


此函数用于处理 SUBSCRIBE 请求。它在数据库中存储或更新 watcher/订阅者信息。
		此外，作为对初始 SUBSCRIBE 请求的响应（创建新的订阅会话），
		该函数还向 watcher/订阅者发送回 NOTIFY（包含 presence 信息）。


该函数可以接受以下参数：


- *force_active* (int, optional) - 可选参数，控制
				presentity 在接受新订阅（接受或拒绝）方面的默认策略——当然，
				此参数仅在使用带有隐私规则的 presence 配置时有意义
				（presence_xml 模块中的 force_active 参数未设置）。
	有些情况下，presentity（您订阅的一方）无法上传其隐私规则的 XCAP 文档
				（控制哪些 watcher 可以订阅它）。在这种情况下，
				您可以从脚本级别强制 presence 服务器认为当前订阅是允许的
				（带有 Subscription-Status:active），方法是用整数参数 "1" 调用 handle_subscribe() 函数。
- *sharing_tag* (string, optional) - 可选参数，在集群场景中告诉
				订阅数据在多个服务器之间共享时的所有者标签——请参阅
				[presence 集群](#presence_clustering) 章节了解更多详情。


```c
   示例： 
	if($ru =~ "kphone@opensips.org")
		handle_subscribe(1);
			
```


此函数可用于 REQUEST_ROUTE。


*返回码：*


- *1 - 成功*。
- *-1 - 错误*。


模块在所有情况下都会发送适当的无状态回复。


```c title="handle_subscribe 使用示例"
...
if($rm=="SUBSCRIBE")
    handle_subscribe();
...
```


### 导出的 MI 函数


#### refresh_watchers


在 watcher 授权或发布状态发生变化时触发向 watcher 发送通知消息。


名称：*refresh_watchers*


参数：


- presentity_uri：做出更改的用户 URI，其 watcher 应该被通知
- event：事件包
- refresh type：区分两种不同类型事件的刷新：
					
					
				watcher 授权的更改：refresh type= 0；
					
					
				发布状态的统计更新（无论是通过直接更新 db 表还是通过修改
				pidf 操作文档，如果设置了 pidf_manipulation 参数）：refresh type!= 0。


MI FIFO 命令格式：


```c
opensips-cli -x mi refresh_watchers sip:11@192.168.2.132 presence 1
	
```


#### cleanup


手动触发 watcher 和 presentity 表的清理函数。如果您将 `clean_period` 设置为零或更小，则很有用。


名称：*cleanup*


参数：*无*


MI FIFO 命令格式：


```c
opensips-cli -x mi cleanup
	  
```


#### presence:phtable_list


替换过时的 MI 命令：*pres_phtable_list*。


列出所有 presentity 记录。


名称：*presence:phtable_list*


参数：*无*


MI FIFO 命令格式：


```c
opensips-cli -x mi presence:phtable_list
	  
```


#### subs_phtable_list


列出所有订阅记录，或 "To" 和 "From" URI 与给定参数匹配的订阅。


名称：*subs_phtable_list*


参数


- *from*(optional) - "From" URI 的通配符
- *to*(optional) - "To" URI 的通配符


MI FIFO 命令格式：


```c
opensips-cli -x mi subs_phtable_list sip:222@domain2.com sip:user_1@example.com
	  
```


#### presence:expose


替换过时的 MI命令：*pres_expose*。


通过引发 *E_PRESENCE_EXPOSED* 事件，在脚本中公开匹配指定过滤器的特定事件的所有 presentities。


名称：*presence:expose*


参数：


- *event* - 期望的 presence 事件。
- *filter*(optional) - 用于过滤该事件 presentities 的正则表达式（REGEXP）。
				只有匹配的 presentities 会被公开。如果未指定，该事件的所有 presentities 都会被公开。


MI FIFO 命令格式：


```c
opensips-cli -x mi presence:expose presence ^sip:10\.0\.5\.[0-9]*
	  
```


### 导出的事件


#### E_PRESENCE_PUBLISH


当 presence 模块收到 PUBLISH 消息时引发此事件。


参数：


- *user* - 用户的 AOR
- *domain* - 域
- *event* - 发布的事件类型
- *expires* - 发布的过期值
- *etag* - 实体标签
- *old_etag* - 要刷新的实体标签
- *body* - PUBLISH 请求的正文


#### E_PRESENCE_EXPOSED


对于 *presence:expose* 公开的每个 presentity 引发此事件。


参数：


与 *E_PRESENCE_PUBLISH* 事件相同的参数。


### 安装


该模块需要在 OpenSIPS 数据库中有 3 个表：presentity、active_watchers 和 watchers 表。
		创建它们的 SQL 语法可以在 opensips/scripts 文件夹的数据库目录中的
		presence-create.sql 脚本中找到。
		您也可以在项目网页上找到完整的数据库文档，
		[https://opensips.org/docs/db/db-schema-devel.html](https://opensips.org/docs/db/db-schema-devel.html)。


## 开发者指南


该模块提供以下可在其他 OpenSIPS 模块中使用的函数。


### bind_presence(presence_api_t* api)


此函数绑定 presence 模块并用导出的函数填充结构，
			这些函数表示在 presence 模块中添加事件的函数，
			以及用于 Subscribe 处理的特定函数。


```c title="presence_api_t 结构"
...
typedef struct presence_api {
	add_event_t add_event;
	contains_event_t contains_event;
	search_event_t search_event;
	get_event_list_t get_event_list;
	
	update_watchers_t update_watchers_status;
	
	/* 订阅哈希表处理函数 */
	new_shtable_t new_shtable;
	destroy_shtable_t destroy_shtable;
	insert_shtable_t insert_shtable;
	search_shtable_t search_shtable;
	delete_shtable_t delete_shtable;
	update_shtable_t update_shtable;
	/* 用于复制 subs 结构的函数*/
	mem_copy_subs_t  mem_copy_subs;
	/* 用于更新数据库的函数*/
	update_db_subs_t update_db_subs;
	/* 用于从 SUBSCRIBE 消息中提取对话框信息的函数*/
	extract_sdialog_info_t extract_sdialog_info;
	/* 用于请求 presentity 的 sphere 定义的函数 */
	pres_get_sphere_t get_sphere;
	pres_contains_presence_t contains_presence;
}presence_api_t;
...
```


### add_event


字段类型：


```c
...
typedef int (*add_event_t)(pres_ev_t* event);
...
```


此函数接收一个包含事件特定信息的结构作为参数，并将其添加到 presence 事件列表中。


作为参数接收的结构：


```c
...
typedef struct pres_ev
{
	str name;
	event_t* evp;
	str content_type;
	int default_expires;
	int type;
	int etag_not_new;
	/*
	 *  0 - 标准机制（为每个 Publish 分配新 etag）
	 *  1 - 仅在初始 Publish 时分配 etag
	*/
	int req_auth;
	get_rules_doc_t* get_rules_doc;
	apply_auth_t*  apply_auth_nbody;
	is_allowed_t*  get_auth_status;
	
	/* 如果事件允许有多个发布状态并需要聚合信息，
	 * 则应注册一个 agg_body_t 函数
	 * 否则，此字段应为 NULL，在构建 Notify 消息时使用最后发布的的状态
	 */
	agg_nbody_t* agg_nbody;
	publ_handling_t  * evs_publ_handl;
	subs_handling_t  * evs_subs_handl;
	free_body_t* free_body;
	
	/* 有时模块需要为每个 active watcher 对正文进行更改
	 * （例如在 XML 文档中设置 "version" 参数）。
	 * 如果模块注册了 aux_body_processing 回调，它会为每个 watcher 调用它。
	 * 它要么获取 PUBLISH 接收到的正文，要么获取 agg_nbody 函数生成的正文。
	 * 模块可以决定是否复制原始正文，然后进行操作，
	 * 或者直接处理原始正文。如果模块复制了原始正文，
	 * 它还必须注册 aux_free_body() 来释放这个 "per watcher" 正文。
	 */
	aux_body_processing_t* aux_body_processing;
	free_body_t* aux_free_body;

	struct pres_ev* wipeer;			
	struct pres_ev* next;
	
}pres_ev_t;
...
```


### get_rules_doc


字段类型：


```c
...
typedef int (get_rules_doc_t)(str* user, str* domain, str** rules_doc);
...
				
```


此函数返回将用于获取订阅状态和处理通知正文的授权规则文档。
		应在作为参数传递给下面描述的函数的 subs_t 结构的 auth_rules_doc 字段中放置对文档的引用。


### get_auth_status


此字段是一个函数，对于订阅请求调用以根据授权规则返回该订阅的状态。
			subs_t 结构收到的 auth_rules_doc 字段应包含 presentity 的规则文档（如果存在）。


仅当 req_auth 字段不为 0 时调用。


字段类型：


```c
...
typedef int (is_allowed_t)(struct subscription* subs);
...
				
```


### apply_auth_nbody


此参数应该是一个函数，对于需要授权的事件，在构建最终正文时调用。
			授权文档从作为参数传递的 subs_t 结构的 auth_rules_doc 字段获取。
			仅当 req_auth 字段不为 0 时调用。


字段类型：


```c
...
typedef int (apply_auth_t)(str* , struct subscription*, str** );
...
				
```


### agg_nbody


如果存在，此字段标记事件需要状态聚合。
			此函数接收正文数组并应返回最终正文。
			如果不存在，则认为事件不需要聚合，在构建 Notify 时使用最近发布的信息。


字段类型：


```c
...
typedef str* (agg_nbody_t)(str* pres_user, str* pres_domain, 
str** body_array, int n, int off_index);
..
				
```


### free_body


如果需要对从数据库检索的信息进行后续处理然后插入 Notify 消息正文
			（如果 agg_nbody 或 apply_auth_nbody 字段已填写），
			则此字段必须填写。
			它应该与处理正文时使用的分配函数匹配。


字段类型：


```c
...
typedef void(free_body_t)(char* body);
..
				
```


### aux_body_processing


如果模块需要为每个 watcher 操作 NOTIFY 正文，则必须设置此字段。
			例如，如果 XML 正文中包含一个 'version' 参数，
			该参数将为每个 NOTIFY 增加，"per watcher" 的基础上。
			模块可以为新正文分配新缓冲区并返回它（也必须设置 aux_free_body 函数），
			或者直接操作原始正文缓冲区并返回 NULL。


字段类型：


```c
...
typedef str* (aux_body_processing_t)(struct subscription *subs, str* body);
..
				
```


### aux_free_body


如果模块注册了 aux_body_processing 函数并为新修改的正文分配了内存，
			则必须设置此字段。然后，此函数将用于释放 aux_body_processing 函数返回的指针。
			如果模块确实使用了 aux_body_processing，但不分配新内存，
			而是直接操作原始正文缓冲区，则 aux_body_processing 必须返回 NULL，
			且不应设置此字段。


字段类型：


```c
...
typedef void(free_body_t)(char* body);
..
				
```


### evs_publ_handl


此函数在处理 Publish 请求时调用。大多数包含正文正确性检查。


```c
...
typedef int (publ_handling_t)(struct sip_msg*);
..
				
```


### evs_subs_handl


这不是强制的。应包含订阅请求的事件特定处理。


字段类型：


```c
...
typedef int (subs_handling_t)(struct sip_msg*);
..
```


### contains_event


字段类型：


```c
..
typedef pres_ev_t* (*contains_event_t)(str* name,
event_t* parsed_event);
...
```


此函数解析作为参数接收的事件名称并在列表中搜索结果。
		如果找到则返回找到的事件，否则返回 NULL。
		如果第二个参数是已分配的 event_t* 结构，它用解析结果填充它。


### get_event_list


字段类型：


```c
...
typedef int (*get_event_list_t) (str** ev_list);
...
```


此函数返回在 presence 模块中注册的事件的字符串表示。（用于 Allowed-Events 头）。


### update_watchers_status


字段类型：


```c
...
typedef int (*update_watchers_t)(str pres_uri, pres_ev_t* ev,
str* rules_doc);
...
```


此函数是一个外部命令，可用于宣布 presentity 授权规则的更改。
		它更新存储的状态并向状态发生变化的 watcher 发送通知。
		（由 presence_xml 模块在通过 MI 命令通知 XCAP 文档更改时使用）。


### get_sphere


字段类型：


```c
...
typedef char* (*pres_get_sphere_t)(str* pres_uri);
...
```


此函数在发布的信息中搜索 sphere 定义（如果类型为 RPID）。
		如果未找到则返回 NULL。（返回值在私有内存中分配，应该被释放）


### contains_presence


字段类型：


```c
...
typedef int (*pres_contains_presence_t)(str* pres_uri);
...
```


此函数搜索 presence URI 是否发布了任何 presence 信息。
		如果找到记录则返回 1，否则返回 -1。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
