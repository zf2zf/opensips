---
title: "pua_reginfo 模块"
description: "本模块根据 RFC 3680 发布关于\"reg\"事件的信息。这可用于将注册信息状态分发给订阅的 watchers。"
---

## 管理指南


### 概述


本模块根据 RFC 3680 发布关于"reg"事件的信息。这可用于将注册信息状态分发给订阅的 watchers。


当新用户在服务器上注册时（例如调用"save()"时），此模块会向订阅了该用户 reg-info 的用户"PUBLISH"信息。


此模块可以在另一个服务器上"SUBSCRIBE"信息，这样当用户信息发生变化时，它将收到"NOTIFY"请求。


最后，它可以处理接收到的"NOTIFY"请求，并相应地更新本地注册表。


此模块的用例包括：


- 保持不同服务器之间位置数据库的同步
- 获取用户注册通知：当用户上线时，处理该账户离线消息存储的 presence 服务器会收到通知。
- 客户端可以订阅自己的注册状态，以便在其账户被管理注销时立即收到通知。
- ...


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *pua*。
- *usrloc*。


#### 外部库或应用程序


无。


### 导出的参数


#### default_domain(str)


用于注册用户在构造 registrar 回调 URI 时使用的默认域名。


默认值为 "NULL"。


```c title="设置 default_domain 参数"
...
modparam("pua_reginfo", "default_domain", "kamailio.org")
...
```


#### publish_reginfo(int)


是否生成 PUBLISH 请求。


默认值为 "1"（启用）。


```c title="设置 publish_reginfo 参数"
...
modparam("pua_reginfo", "publish_reginfo", 0)
...
```


#### outbound_proxy(str)


发送 Subscribe 和 Publish 请求时使用的 outbound_proxy URI。


默认值为 "NULL"。


```c title="设置 outbound_proxy 参数"
...
modparam("pua_reginfo", "outbound_proxy", "sip:proxy@kamailio.org")
...
```


#### server_address(str)


服务器的 IP 地址。


```c title="设置 server_address 参数"
...
modparam("pua_reginfo", "server_address", "sip:reginfo@160.34.23.12")
...
```


#### ul_domain(str)


用于查询 usrloc 数据库的域名。


默认值为 "NULL"（未设置）。


```c title="设置 ul_domain 参数"
...
modparam("pua_reginfo", "ul_domain", "location")
...
```


#### ul_identities_key(str)


可用于检索用户多个公有身份的 Key。


默认值为 "NULL"（未设置）。


```c title="设置 ul_identities_key 参数"
...
modparam("pua_reginfo", "ul_identities_key", "identities")
...
onreply_route[register_reply] {
	if (t_check_status("200") && $hdr(P-Associated-URI)) {
        ul_add_key("location", "$tU@$td", "identities", "$hdr(P-Associated-URI)");
        reginfo_update("$tU@$td");
	}
}

...
			
```


### 导出的函数


#### reginfo_handle_notify(uldomain)


此函数处理接收到的"NOTIFY"请求并相应地更新本地注册表。


此方法不创建任何 SIP 响应，这必须由脚本编写者完成。


参数必须对应于要存储记录的用户位置表（域）。


返回代码：


- *2* - 联系人更新成功，但目前没有更多联系人在线。
- *1* - 联系人更新成功且至少有一个联系人仍在注册。
- *-1* - 无效的 NOTIFY 或其他错误（请参阅日志文件）。


```c title="reginfo_handle_notify 用法"
...
if(is_method("NOTIFY")) 
	if (reginfo_handle_notify("location"))
		send_reply("202", "Accepted");
...
					
```


#### reginfo_subscribe(uri[, expires])


此函数将在给定的服务器 URI 处订阅 reginfo 信息。


参数含义如下：


- *uri* - 要订阅的服务器 SIP-URI，可以包含伪变量。
- *expires* - 此订阅的过期时间，以秒为单位（默认 3600）。


```c title="reginfo_subscribe 用法"
...
route {
	t_on_reply("1");
	t_relay();
}

reply_route[1] {
	if (t_check_status("200")) 
		reginfo_subscribe("$ru");		
}
...
					
```


#### reginfo_update(aor)


在学到新信息时显式更新呈现状态。这可能会向订阅的实体触发新的 NOTIFY；至少会更新内部信息以供后续订阅和通知使用。


当注册更新时，这是隐式完成的。但是，当使用额外信息（如身份）更新注册时，不会自动触发此操作。


参数含义如下：


- *aor* - 要更新的 AOR。


```c title="reginfo_subscribe 用法"
...
modparam("pua_reginfo", "ul_domain", "location")
modparam("pua_reginfo", "ul_identities_key", "identities")
...
onreply_route[register_reply] {
	if (t_check_status("200") && $hdr(P-Associated-URI)) {
        ul_add_key("location", "$tU@$td", "identities", "$hdr(P-Associated-URI)");
        reginfo_update("$tU@$td");
	}
}

...
					
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享 4.0 许可证。
