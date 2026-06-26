---
title: "Presence User Agent 模块"
description: "本模块为 OpenSIPS 提供内部支持，使其能够作为 Presence User Agent（呈现代理）客户端使用，通过发送 Subscribe 和 Publish 消息。"
---

## 管理指南


### 概述


本模块为 OpenSIPS 提供内部支持，使其能够作为 Presence User Agent（呈现代理）客户端使用，通过发送 Subscribe 和 Publish 消息。


请注意，该模块并不提供任何可直接从脚本中使用的功能，而是为其他特定事件模块提供 PUA 客户端支持（通过内部 API），以便这些模块执行 PUA 客户端操作。


在 PUA 模块基础上构建的一些模块包括 pua_mi、pua_usrloc、pua_dialoginfo、pua_bla 和 pua_xmpp。
pua_mi 模块提供通过 fifo 发布任何类型信息或订阅资源的功能。pua_usrloc 模块调用 pua 模块导出的函数来发布基本的呈现信息，例如不支持客户端到服务器呈现的客户端的"在线"或"离线"状态。
pua_dialoginfo 模块通过发布通话参与者的状态（如振铃、建立、终止）来提供 BLF（Busy Lamp Field，忙灯指示）支持。
通过 pua_bla 模块，可以为 OpenSIPS 添加 BRIDGED LINE APPEARANCE（桥接线外观）功能。
pua_xmpp 模块代表 SIP 和 XMPP 之间的网关，使 Jabber 和 SIP 客户端能够交换呈现信息。


该模块使用缓存存储 presentity（呈现实体）列表，并定时写入数据库，以便在重启后能够恢复。


注意：此模块不得在 no fork 模式下使用（所使用的锁机制可能在 no fork 模式下导致死锁）。


### PUA 集群


从 3.2 版本开始，该模块也扩展了集群支持。这意味着多个配置了 PUA 模块的 OpenSIPS 实例可以协同工作。例如，某个特定 presentity 的发布可以通过集群中的不同节点（PUA OpenSIPS 实例）完成。


集群支持是 DB 共享和 OpenSIPS 集群的混合实现。当某个节点修改了 presentity 时，OpenSIPS 集群层用于在集群中广播通知（以便集群中的其他节点可以通过 DB 刷新 presentity）。


共享数据库用于在节点之间共享实际的 presentity 数据。一个节点只在内存中缓存该节点创建的 presentity 或该节点处理过的 presentity。如果某个节点需要对该 presentity 执行操作，可以将 presentity 记录加载到内存中（从数据库）。


重要提示：由于实际的 presentity 数据是通过数据库在节点之间共享的（集群层仅用于通知），因此必须将数据库更新间隔设置得非常低（将从内存缓存刷新到数据库的数据），以尽可能实时地更新数据库内容。请参阅下面的[更新周期](#param_update_period) 模块参数，建议值为 2-5 秒。


在 OpenSIPS 集群层上，PUA 模块使用 sharing-tags（共享标签）机制来控制集群中所有节点之间哪个节点负责对 presentity 执行过期操作（如发送 expires 为 0 的 PUBLISH）。


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *数据库模块*。
- *tm*。
- *clusterer*，如果设置了 cluster_id 模块参数并激活了集群支持。


#### 外部库或应用程序


在运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *libxml*。


### 导出的参数


#### hash_size (int)


用于存储 Subscribe 和 Publish 信息的哈希表大小。
此参数将用于计算表大小时作为 2 的幂次。


默认值为 "9"。


```c title="设置 hash_size 参数"
...
modparam("pua", "hash_size", 11)
...
```


#### db_url (str)


数据库 URL。


默认值为 "mysql://opensips:opensipsrw@localhost/opensips"。


```c title="设置 db_url 参数"
...
modparam("pua", "db_url" "dbdriver://username:password@dbhost/dbname")
...
```


#### db_table (str)


数据库表名称。


默认值为 "pua"。


```c title="设置 db_table 参数"
...
modparam("pua", "db_table", "pua")
...
```


#### min_expires (int)


Publish 和 Subscribe 的最小过期时间限制。


默认值为 "300"。


```c title="设置 min_expires 参数"
...
modparam("pua", "min_expires", 0)
...
```


#### default_expires (int)


当没有提供此信息时使用的默认过期值。


默认值为 "3600"。


```c title="设置 default_expires 参数"
...
modparam("pua", "default_expires", 3600)
...
```


#### update_period (int)


更新数据库和哈希表中信息的间隔。哈希表的更新操作是删除过期的消息。


默认值为 "30"。


重要提示 - 如果您为此模块使用集群支持，请在此处设置一个较低的值，如 2-5，请参阅上面的集群章节。


```c title="设置 update_period 参数"
...
modparam("pua", "update_period", 100)
...
```


#### cluster_id (int)


应该复制/共享 PUA 数据的集群 ID。
此参数仅在需要集群模式时使用。
要了解集群 ID 的概念，请参阅 *clusterer* 模块。


有关 PUA 集群的更多信息，请参阅 [pua 集群](#pua_clustering) 章节。


默认值为 "None"。


```c title="设置 cluster_id 参数"
...
modparam("pua", "cluster_id", 10)
...
```


#### cluster_sharing_tag (int)


创建任何新 presentity 记录时 PUA 模块使用的集群共享标签。该标签用于决定哪个 OpenSIPS 实例（拥有该标签为 active 状态）将负责此 presentity 的过期操作。
此参数仅在需要集群模式时使用。
要了解共享标签的概念，请参阅 *clusterer* 模块。


有关 PUA 集群的更多信息，请参阅 [pua 集群](#pua_clustering) 章节。


默认值为 "NULL"。


```c title="设置 cluster_sharing_tag 参数"
...
modparam("pua", "cluster_sharing_tag", "vip")
...
```


### 导出的函数


#### pua_update_contact()


远程目标可以通过后续 in-dialog 请求中的 Contact 更新。在 PUA watcher 情况下（发送 SUBSCRIBE 消息），这意味着后续 Subscribe 消息的远程目标可以随时通过 Notify 消息的 contact 更新。
如果在收到 Notify 消息时在请求路由中调用此函数，它将尝试更新存储的远程目标。


此函数可以从 REQUEST_ROUTE 使用。


*返回代码：*


- *1 - 如果成功*。
- *-1 - 如果出错*。


```c title="pua_update_contact 用法"
...
if($rm=="NOTIFY")
    pua_update_contact();
...
```


### 安装


该模块需要在 OpenSIPS 数据库中创建 1 个表：pua。创建表的 SQL 语法可以在 opensips/scripts 文件夹的数据库目录中的 presence_xml-create.sql 脚本中找到。
您还可以在项目网页上找到完整的数据库文档：[https://opensips.org/docs/db/db-schema-devel.html](https://opensips.org/docs/db/db-schema-devel.html)。


## 开发者指南


该模块提供以下可供其他 OpenSIPS 模块使用的函数。


### bind_pua(pua_api_t* api)


此函数绑定 pua 模块并用两个导出的函数填充结构。


```c title="pua_api 结构"
...
typedef struct pua_api {
	send_subscribe_t send_subscribe;
	send_publish_t send_publish;
	query_dialog_t is_dialog;
	register_puacb_t register_puacb;
	add_pua_event_t add_event;
} pua_api_t;
...
```


### send_publish


字段类型：


```c
...
typedef int (*send_publish_t)(publ_info_t* publ);
...
				
```


此函数接收一个包含 Publish 所需信息的结构作为参数，并发送 Publish 消息。


接收到的结构参数：


```c
...
typedef struct publ_info

  str id;             /*  (可选) 对于 pres_uri 和 flag 的组合是唯一的值 */
  str* pres_uri;      /*  presentity URI */	
  str* body;          /*  Publish 消息的 body；
                          在更新过期的情况下可以为 NULL */ 	
  int  expires;       /*  将用于 Publish Expires 头部的 expires 值*/
  int flag;           /*  可以是：INSERT_TYPE 或 UPDATE_TYPE
                          如果缺失，将根据哈希表中的搜索结果确定 */ 	
  int source_flag;    /*  标识资源的 flag；
                          支持的值：UL_PUBLISH, MI_PUBLISH,
                          BLA_PUBLISH, XMPP_PUBLISH*/
  int event;          /*  事件 flag；
                          支持的值：PRESENCE_EVENT, BLA_EVENT,
                          MWI_EVENT */
  str content_type;   /*  body 的 content_type（如果存在）
                          （如果与该事件的默认值相同则为可选）*/
  str* etag;          /*  (可选) 请求应匹配的 etag 值 */
  str* extra_headers  /*  (可选) 应添加到 Publish 消息的额外头部*/
  publrpl_cb_t* cbrpl;/*  在收到发送请求的回复时调用的回调函数 */
  void* cbparam;      /*  回调函数的额外参数 */

  str outbound_proxy; /*  发送 Publish 请求时使用的 outbound proxy*/

}publ_info_t;
...
			
```


回调函数类型：


```c
...
typedef int (publrpl_cb_t)(struct sip_msg* reply, void*  extra_param);
...
			
```


### send_subscribe


字段类型：


```c
...
typedef int (*send_subscribe_t)(subs_info_t* subs);
...
```


此函数接收一个包含 Subscribe 所需信息的结构作为参数，并发送 Subscribe 消息。


接收到的结构参数：


```c
...
typedef struct subs_info

  str id;              /*  对于 pres_uri 和 flag 的组合是唯一的值 */
  str* pres_uri;       /*  presentity URI */	
  str* watcher_uri;    /*  watcher URI */
  str* contact;        /*  将用于 Contact 头部的 URI*/  
  str* remote_target;  /*  将用作 Subscribe 消息的 R-URI 的 URI
                           （非强制；如果未设置，则使用 pres_uri 字段的值） */
  str* outbound_proxy; /*  发送 Subscribe 请求时使用的 outbound_proxy*/
  int event;           /*  事件 flag；支持的值： 
                           PRESENCE_EVENT, BLA_EVENT, PWINFO_EVENT*/ 
  int expires;         /*  将用于 Subscribe Expires 头部的 expires 值 */	
  int flag;            /*  可以是：INSERT_TYPE 或 UPDATE_TYPE
                           （非强制）*/	
  int source_flag;     /*  标识资源的 flag；
                           支持的值：MI_SUBSCRIBE, 
                           BLA_SUBSCRIBE, XMPP_SUBSCRIBE,
                           XMPP_INITIAL_SUBS */
}subs_info_t;
...
```


### is_dialog


字段类型：


```c
...
typedef int  (*query_dialog_t)(ua_pres_t* presentity);
...
				
```


此函数检查参数是否对应于存储的 Subscribe 发起的 dialog。


```c title="pua_is_dialog 使用示例"
...	
	if(pua_is_dialog(dialog) < 0)
	{
		LM_ERR("querying dialog\n");
		goto error;
	}
...	
```


### register_puacb


字段类型：


```c
...
typedef int (*register_puacb_t)(int types, pua_cb f, void* param );
...
				
```


此函数注册一个回调，在收到发送的 Subscribe 请求的回复消息时调用。
type 参数应设置为与该请求的 source_flag 相同。
注册为 pua 回调的函数应该是 pua_cb 类型：
typedef void (pua_cb)(ua_pres_t* hentity, struct msg_start * fl);
参数是该请求的 dialog 结构和回复消息的第一行。


```c title="register_puacb 使用示例"
...
	if(pua.register_puacb(XMPP_SUBSCRIBE, Sipreply2Xmpp, NULL) & 0)
	{
		LM_ERR("Could not register callback\n");
		return -1;
	}
...	
	
```


### add_event


字段类型：


```c
...
typedef int (*add_pua_event_t)(int ev_flag, char* name, 
   char* content_type,evs_process_body_t* process_body);

- ev_flag     : 定义为 pua 模块中宏的事件 flag		
- name        : 用于 Event 请求头部的事件名称
- content_type: 该事件 Publish body 的默认 content_type
                （如果是 winfo 事件则为 NULL）
- process_body: 在构造 PUBLISH 请求之前处理接收到的 body 的函数
                （如果是 winfo 事件则为 NULL）
...
				
```


此函数允许向 pua 模块注册新事件。目前 pua 模块支持 4 个事件：presence、presence;winfo、message-summary、dialog;sla。这些事件是从 pua 模块内部注册的。


process_body 的字段类型：


```c
...
typedef int (evs_process_body_t)(struct publ_info* publ, 
  str** final_body, int ver, str* tuple);
- publ      : 作为 send_publish 函数参数接收的结构
              （在 publ->body 中找到的初始 body）
- final_body: 应存储结果（final_body）的指针 
- ver       : 已发送 Publish 请求的计数器
              （用于 winfo 事件）
- tuple     : 资源的唯一标识符；
              如果是初始 Publish，应作为结果返回，
              并将为该记录存储它，否则它将作为参数给出；    
...
				
```


```c title="add_event 使用示例"
...
	if(pua.add_event((PRESENCE_EVENT, "presence", "application/pidf+xml", 
				pres_process_body) & 0)
	{
		LM_ERR("Could not register new event\n");
		return -1;
	}
...	
	
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享 4.0 许可证。
