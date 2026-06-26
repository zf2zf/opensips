---
title: "UAC Registrant 模块"
description: "该模块使 OpenSIPS 能够在远程 SIP registrar 上注册自己。"
---

## 管理指南


### 概述


该模块使 OpenSIPS 能够在远程 SIP registrar 上注册自己。


在启动时，registrant 记录被加载到内存中的哈希表中，
		并启动一个计时器。
		哈希索引是根据 AOR 字段计算的。


检查哈希桶中记录的时间间隔是通过
		将 timer_interval 模块参数除以哈希桶数来计算的。
		当计时器第一次触发时，将检查第一个哈希桶，
		并将发送找到的每条记录的 REGISTER。
		在下一次超时触发时，将检查第二个哈希桶，依此类推。
		如果配置的 timer_interval 模块参数小于桶数，
		模块将无法启动。


示例：将 timer_interval 模块设置为 8，hash_size 设置为 2，
		将产生 4 个哈希桶（2^2=4），
		桶将每 2 秒检查一次（8/4=2）。


每个 registrant 都有自己的状态。
	    Registrant 的状态可以通过 "uac_registrant:list" MI 命令检查。


UAC registrant 状态：


- *0*
				- NOT_REGISTERED_STATE -
				初始状态（尚未发送 REGISTER）；
- *1*
				- REGISTERING_STATE - 发送无认证头的 REGISTER 后
				等待 registrar 的回复；
- *2*
				- AUTHENTICATING_STATE - 发送带认证头的 REGISTER 后
				等待 registrar 的回复；
- *3*
				- REGISTERED_STATE - uac 已成功注册；
- *4*
				- REGISTER_TIMEOUT_STATE :
				未收到 registrar 的回复；
- *5*
				- INTERNAL_ERROR_STATE -
				处理回复时发现/遇到一些错误；
- *6*
				- WRONG_CREDENTIALS_STATE -
				registrar 拒绝凭据；
- *7*
				- REGISTRAR_ERROR_STATE -
				收到 registrar 的错误回复；
- *8*
				- UNREGISTERING_STATE - 发送无认证头的 unREGISTER 后
				等待 registrar 的回复；
- *9*
				- AUTHENTICATING_UNREGISTER_STATE - 发送带认证头的 unREGISTER 后
				等待 registrar 的回复；


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *uac_auth - UAC 认证模块*


#### 外部库或应用程序


无。


### 导出的参数


#### hash_size (integer)


用于保存 registrants 的哈希表的大小。
		较大的表在时间上更均匀地分配注册负载，但消耗更多内存。
		哈希大小是 2 的幂次方。


*默认值为 1。*


```c title="设置 hash_size 参数"
...
modparam("uac_registrant", "hash_size", 2)
...
```


#### timer_interval (integer)


定义检查注册状态的定期计时器。


*默认值为 100。*


```c title="设置 timer_interval 参数"
...
modparam("uac_registrant", "timer_interval", 120)
...
```


#### failure_retry_interval (integer)


定义在错误/失败时重试注册的自定义间隔。
		通常，在任何类型的失败（超时、凭据、内部错误）后，
		注册将在 "expires" 秒后重新获取。
		如果设置了此参数，它将覆盖该值。


*默认值为 0（未设置）。*


```c title="设置 failure_retry_interval 参数"
...
modparam("uac_registrant", "failure_retry_interval", 3600)
...
```


#### enable_clustering (integer)


此参数启用模块中的集群支持。
		这用于在集群中的所有节点之间共享此注册。
		使用此选项时，您应该为每个 registrant 记录定义一个共享标签
		- 此共享标签将在集群级别控制哪个节点有权执行注册
		（只有将标签作为活动标签的节点才会执行注册，其他节点保持空闲）。


*默认值为 0 / 关闭。*


```c title="设置 enable_clustering 参数"
...
modparam("uac_registrant", "enable_clustering", 1)
...
```


#### db_url (string)


要从中加载 registrants 的数据库。


*默认值为 "NULL"（使用核心中的默认 DB URL）。*


```c title="设置 'db_url' 参数"
...
modparam("uac_registrant", "db_url", "mysql://user:passw@localhost/database")
...
```


#### table_name (string)


保存 registrant 记录的数据库表。


*默认值为 "registrant"。*


```c title="设置 'table_name' 参数"
...
modparam("uac_registrant", "table_name", "my_registrant")
...
```


#### registrar_column (string)


数据库中存储指向远程 registrar 的 URI 的列名（必填字段）。
		OpenSIPS 期望一个有效的 URI。


*默认值为 "registrar"。*


```c title="设置 'registrar_column' 参数"
...
modparam("uac_registrant", "registrar_column", "registrant_uri")
...
```


#### proxy_column (string)


数据库中存储指向出站代理的 URI 的列名（非必填字段）。
		空值或 NULL 值表示无出站代理，
		否则 OpenSIPS 期望一个有效的 URI。


*默认值为 "proxy"。*


```c title="设置 'proxy_column' 参数"
...
modparam("uac_registrant", "proxy_column", "proxy_uri")
...
```


#### aor_column (string)


数据库中存储定义地址记录的 URI 的列名（必填字段）。
		存储在这里的 URI 将用于 REGISTER 的 To URI。
		OpenSIPS 期望一个有效的 URI。


*默认值为 "aor"。*


```c title="设置 'aor_column' 参数"
...
modparam("uac_registrant", "aor_column", "to_uri")
...
```


#### third_party_registrant_column (string)


数据库中存储定义第三方 registrant 的 URI 的列名（非必填字段）。
		存储在这里的 URI 将用于 REGISTER 的 From URI。
		空值或 NULL 值表示无第三方注册
		（From URI 将与 To URI 相同），
		否则 OpenSIPS 期望一个有效的 URI。


*默认值为 "third_party_registrant"。*


```c title="设置 'third_party_registrant_column' 参数"
...
modparam("uac_registrant", "third_party_registrant_column", "from_uri")
...
```


#### username_column (string)


数据库中存储认证用户名的列名
		（如果 registrar 需要认证，则为必填）。


*默认值为 "username"。*


```c title="设置 'username_column' 参数"
...
modparam("uac_registrant", "username_column", "auth_username")
...
```


#### password_column (string)


数据库中存储认证密码的列名
		（如果 registrar 需要认证，则为必填）。


*默认值为 "password"。*


```c title="设置 'password_column' 参数"
...
modparam("uac_registrant", "password_column", "auth_passowrd")
...
```


#### binding_URI_column (string)


数据库中存储 REGISTER 中 binding URI 的列名（必填字段）。
		存储在这里的 URI 将用于 REGISTER 的 Contact URI。
		OpenSIPS 期望一个有效的 URI。


*默认值为 "binding_URI"。*


```c title="设置 'binding_URI_column' 参数"
...
modparam("uac_registrant", "binding_URI_column", "contact_uri")
...
```


#### binding_params_column (string)


数据库中存储 REGISTER 中 binding params 的列名（非必填字段）。
		如果不为 NULL 或不为空，存储在这里的字符串将作为参数添加到
		REGISTER 的 Contact URI 中（必须以 ";" 开头）。


如果存在以下两个参数，则强制绑定为唯一的
		（如果在 200ok 中收到两个绑定，在重新注册之前将执行完整绑定移除）：


- *reg-id*
- *+sip.instance*


强制唯一绑定的参数示例：


```c
;reg-id=1;+sip.instance="<urn:uuid:11111111-AABBCCDDEEFF>"
			
```


*默认值为 "binding_params"。*


```c title="设置 'binding_params_column' 参数"
...
modparam("uac_registrant", "binding_params_column", "contact_params")
...
```


#### expiry_column (string)


数据库中存储过期时间的列名（非必填）。


*默认值为 "expiry"。*


```c title="设置 'expiry_column' 参数"
...
modparam("uac_registrant", "expiry_column", "registration_timeout")
...
```


#### forced_socket_column (string)


数据库中存储用于发送 REGISTER 的套接字的列名（非必填）。
		如果提供了强制套接字，该套接字必须
		在配置中明确设置为全局监听套接字
		（见 "socket" 核心参数）。


*默认值为 "forced_socket"。*


```c title="设置 'forced_socket_column' 参数"
...
modparam("uac_registrant", "forced_socket_column", "fs")
...
```


#### cluster_shtag_column (string)


数据库中存储集群共享标签的列名，
		格式为 [tag_name/cluster_id]（非必填）。
		如果提供了集群共享标签，
		则仅当标签处于活动状态时才会发出 REGISTER 请求。


*默认值为 "cluster_shtag"。*


```c title="设置 'cluster_shtag_column' 参数"
...
modparam("uac_registrant", "cluster_shtag_column", "sh")
...
```


#### state_column (string)


数据库中存储 registrant 当前状态的列名。
		当 registrant 被禁用时，OpenSIPS 将不再为其发送 REGISTER。
		此列的值为 *0* 表示启用，*1* 表示禁用。


*默认值为 "state"。*


```c title="设置 'state_column' 参数"
...
modparam("uac_registrant", "state_column", "status")
...
```


#### reregister_expiry_percentage (integer)


描述基于 Expiry 需要多早发送 RE-REGISTER 的百分比。
		100 表示 RE-REGISTER 将在过期边缘发送（旧行为），
		这可能导致注册丢失。
		90 表示 RE-REGISTER 将更早发送，在 Expiry 的 90% 时，依此类推。


*默认值为 "100"。*


```c title="设置 'reregister_expiry_percentage' 参数"
...
modparam("uac_registrant", "reregister_expiry_percentage", 90)
...
```


### 导出的函数


配置文件中没有要使用的函数。


### 导出的 MI 函数


#### uac_registrant:list


替换已弃用的 MI 命令：*reg_list*。


列出 registrant 记录及其状态。


名称：*uac_registrant:list*


参数：


- *aor* (可选) - 定义地址记录的 URI。
				如果提供，则还需要 *contact* 和
				*registrar* 参数，
				并且仅列出特定记录。
- *contact* (可选) - Contact URI。如果
				提供，
				*aor* 和 *registrar*
				参数也必须提供，
				并且仅列出特定记录。
- *registrar* (可选) - 指向远程 registrar 的 URI。
				如果提供，则还需要 *aor* 和
				*contact* 参数，
				并且仅列出特定记录。


MI FIFO 命令格式：


```c
opensips-cli -x mi uac_registrant:list
...
opensips-cli -x mi uac_registrant:list sip:alice@opensips.org  sip:alice@127.0.0.1:5060 sip:opensips.org
			
```


#### uac_registrant:reload


替换已弃用的 MI 命令：*reg_reload*。


从数据库重新加载 registrant 记录。


名称：*uac_registrant:reload*


参数：*无*


- *aor* (可选) - 定义地址记录的 URI。
				如果提供，则还需要 *contact* 和
				*registrar* 参数，
				并且仅重新加载特定记录。
- *contact* (可选) - Contact URI。如果
				提供，
				*aor* 和 *registrar*
				参数也必须提供，
				并且仅重新加载特定记录。
- *registrar* (可选) - 指向远程 registrar 的 URI。
				如果提供，则还需要 *aor* 和
				*contact* 参数，
				并且仅重新加载特定记录。


MI FIFO 命令格式：


```c
opensips-cli -x mi uac_registrant:reload
...
opensips-cli -x mi reg_leload sip:alice@opensips.org  sip:alice@127.0.0.1:5060 sip:opensips.org
			
```


#### uac_registrant:enable


替换已弃用的 MI 命令：*reg_enable*。


启用特定 registrant。
		如果 registrant 之前被禁用，OpenSIPS 将立即发送 REGISTER，
		并更新数据库中的状态。


名称：*uac_registrant:enable*


参数：*无*


- *aor* - 地址记录的 URI。
- *contact* - Contact URI。
- *registrar* - 指向远程 registrar 的 URI。


MI FIFO 命令格式：


```c
opensips-cli -x mi uac_registrant:enable sip:alice@opensips.org  sip:alice@127.0.0.1:5060 sip:opensips.org
			
```


#### uac_registrant:disable


替换已弃用的 MI 命令：*reg_disable*。


禁用特定 registrant。
		如果 registrant 之前被启用，OpenSIPS 将立即发送 unREGISTER，
		并更新数据库中的状态。


名称：*uac_registrant:disable*


参数：*无*


- *aor* - 地址记录的 URI。
				如果提供，则还需要 *contact* 和
				*registrar* 参数，
				并且仅禁用特定记录。
- *contact* - Contact URI。如果提供，
				*aor* 和 *registrar*
				参数也必须提供，
				并且仅禁用特定记录。
- *registrar* - 指向远程
				registrar 的 URI。如果提供，
				则还需要 *aor* 和
				*contact* 参数，
				并且仅禁用特定记录。


MI FIFO 命令格式：


```c
opensips-cli -x mi uac_registrant:disable sip:alice@opensips.org  sip:alice@127.0.0.1:5060 sip:opensips.org
			
```


#### uac_registrant:force_register


替换已弃用的 MI 命令：*reg_force_register*。


强制重新注册（或注册）特定 registrant
		（取决于其状态）。请注意，registrant 必须已启用。


名称：*uac_registrant:force_register*


参数：


- *aor* - 地址记录的 URI。
				如果提供，则还需要 *contact* 和
				*registrar* 参数，
				并且仅强制重新加载特定记录。
- *contact* - Contact URI。如果提供，
				*aor* 和 *registrar*
				参数也必须提供，
				并且仅强制重新加载特定记录。
- *registrar* - 指向远程
				registrar 的 URI。如果提供，
				则还需要 *aor* 和
				*contact* 参数，
				并且仅强制重新加载特定记录。


MI FIFO 命令格式：


```c
opensips-cli -x mi uac_registrant:force_register sip:alice@opensips.org  sip:alice@127.0.0.1:5060 sip:opensips.org
			
```


#### uac_registrant:upsert


替换已弃用的 MI 命令：*reg_upsert*。


插入或更新 AOR/Contact/Registrar 的内存内容。
		调用此 MI 命令时不执行数据库查询，
		所有参数都通过 MI 传递。


名称：*uac_registrant:upsert*


参数：


- *aor* - 地址的 URI
- *contact* - Contact URI
- *registrar* - 指向远程 registrar 的 URI
- *proxy* - 注册代理的 URI
- *third_party_registrant* - 第三方 registrant
- *username* - 用于认证的用户名
- *password* - 用于认证的密码
- *binding_params* - 要添加到注册的参数
- *expiry* - 注册有效的秒数
- *forced_socket* - opensips 套接字用于发送注册
- *cluster_shtag* - 此注册的共享标签
- *state* - 0 表示启用，1 表示禁用


MI FIFO 命令格式：


```c
opensips-cli -x mi uac_registrant:upsert aor=sip:vlad@test.com contact=sip:test@localhost registrar=sip:127.0.0.1:5061 proxy="" third_party_registrant="" username="vlad" password="1234" binding_params="" expiry=60 forced_socket="" cluster_shtag="" state=0
			
```


#### uac_registrant:delete


替换已弃用的 MI 命令：*reg_delete*。


删除 AOR/Contact/Registrar 的内存内容。
		调用此 MI 命令时不执行数据库查询，
		所有参数都通过 MI 传递。


名称：*uac_registrant:delete*


参数：


- *aor* - 地址的 URI
- *contact* - Contact URI
- *registrar* - 指向远程 registrar 的 URI


MI FIFO 命令格式：


```c
opensips-cli -x mi uac_registrant:delete aor=sip:vlad@test.com contact=sip:test@localhost registrar=sip:127.0.0.1:5061 
			
```


### 导出的事件


#### E_REGISTRANT_REGISTERING


当模块发送初始 REGISTER 并开始注册过程时触发此事件。


参数：


- *aor* - AOR
- *contact* - Contact
- *registrar* - Registrar


#### E_REGISTRANT_AUTHENTICATING


当初始 REGISTER 被质询并发送了带凭据的新 REGISTER 时触发此事件。


参数：


- *aor* - AOR
- *contact* - Contact
- *registrar* - Registrar


#### E_REGISTRANT_REGISTERED


当 REGISTER 收到 200 OK 时触发此事件。


参数：


- *aor* - AOR
- *contact* - Contact
- *registrar* - Registrar


#### E_REGISTRANT_REGISTER_TIMEOUT


当 REGISTER 未收到 registrar 的回复时触发此事件。


参数：


- *aor* - AOR
- *contact* - Contact
- *registrar* - Registrar


#### E_REGISTRANT_INTERNAL_ERROR


当 REGISTER 处理因内部 OpenSIPS 错误而停止时触发此事件。


参数：


- *aor* - AOR
- *contact* - Contact
- *registrar* - Registrar


#### E_REGISTRANT_WRONG_CREDENTIALS


当初始 REGISTER 仍被 registrar 拒绝时触发此事件


参数：


- *aor* - AOR
- *contact* - Contact
- *registrar* - Registrar


#### E_REGISTRANT_REGISTRAR_ERROR


当 REGISTER 被 registrar 以非标准 sip 码拒绝时触发此事件。


参数：


- *aor* - AOR
- *contact* - Contact
- *registrar* - Registrar


#### E_REGISTRANT_UNREGISTERING


当 OpenSIPS 发送 de-REGISTER 时触发此事件。


参数：


- *aor* - AOR
- *contact* - Contact
- *registrar* - Registrar


#### E_REGISTRANT_AUTHENTICATING_UNREGISTER


当 de-REGISTER 被质询且 OpenSIPS 发送认证时触发此事件。


参数：


- *aor* - AOR
- *contact* - Contact
- *registrar* - Registrar


### 导出的状态/报告标识符


该模块提供 "uac_registrant" 状态/报告组，
		其中每个 UAC registrant 被定义为单独的 SR 标识符。


每个单独标识符的名称构建如下：


```c
   "aor=_AOR_;contact=_SIP_CONTACT_URI_;registrar=_SIP_REGISTAR_URI_"
   例如：
   "aor=sip:vlad@test.com;contact=sip:test@mycontact.com;registrar=sip:127.0.0.1:5061"
	
```


就状态而言，将报告以下值：


- STATUS_READY（如果已注册）
- STATUS_LOADING_DATA（如果正在注册、注销、认证中）
- STATUS_NOT_READY（registrant 的任何其他状态）


作为报告，每个标识符可以提供以下信息：


```c
# opensips-cli -x mi  sr_list_reports uac_registrant
[
   {
       "Name": "aor=sip:vlad@test.com;contact=sip:test@mycontact.com;registrar=sip:127.0.0.1:5061",
       "Reports": [
           {
               "Timestamp": 1769604697,
               "Date": "Wed Jan 28 14:51:37 2026",
               "Log": "创建于 NOT_REGISTERED_STATE\n"
           },
           {
               "Timestamp": 1769604707,
               "Date": "Wed Jan 28 14:51:47 2026",
               "Log": "状态更改为 REGISTERING_STATE\n"
           },
           {
               "Timestamp": 1769604712,
               "Date": "Wed Jan 28 14:51:52 2026",
               "Log": "状态更改为 REGISTER_TIMEOUT_STATE\n"
           }
       ]
   }
]

	
```


有关如何访问和使用状态/报告信息，
		请参阅 [https://www.opensips.org/Documentation/Interface-StatusReport-3-6](>https://www.opensips.org/Documentation/Interface-StatusReport-3-6)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
