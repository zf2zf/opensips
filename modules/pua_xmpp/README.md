---
title: "XMPP 的 PUA（SIP 与 XMPP 之间的 Presence 网关）"
description: "此模块是 SIP 和 XMPP 之间的 presence 网关。"
---

## 管理指南


### 概述


此模块是 SIP 和 XMPP 之间的 presence 网关。


它将一种格式翻译成另一种格式，并使用 xmpp、pua 和 presence 模块来管理 presence 状态信息的传输。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *presence*。
- *pua*。
- *xmpp*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *libxml*。


### 导出的参数


#### server_address (str)


服务器的 IP 地址。


```c title="设置 server_address 参数"
...
modparam("pua_xmpp", "server_address", "sip:sa@opensips.org:5060")
...
```


#### presence_server (str)


Presence 服务器的地址。如果设置，发送 PUBLISH 请求时将用作 outbound proxy。


```c title="设置 presence_server 参数"
...
modparam("pua_xmpp", "presence_server", "sip:pa@opensips.org:5075")
...
	
```


### 导出的函数


导出供配置文件使用的函数。


#### pua_xmpp_notify()


处理从 xmpp 域中的用户发送的 NOTIFY 消息的函数。它需要在配置文件中按方法和域名进行过滤。如果函数成功，必须发送 2xx 回复。


此函数可用于 REQUEST_ROUTE。


```c title="Notify2Xmpp 使用示例"
...
	if( is_method("NOTIFY") && $ru=~"sip:.+@sip-xmpp.siphub.ro")
	{
		if(Notify2Xmpp())
			t_reply(200, "OK");
		exit;
	}
...
```


#### pua_xmpp_req_winfo(request_uri, expires)


当收到针对 xmpp 域中用户的 SUBSCRIBE 时调用的函数。它调用为用户发送 winfo 的 SUBSCRIBE，随后的带有 dialog-info 的 NOTIFY 被翻译为 xmpp 中的订阅。它还需要在配置文件中进行过滤——按方法、域名和事件（仅针对 presence）。


参数：


- *request_uri* (字符串)
- *expires* (整数) - 收到的 SUBSCRIBE 中 Expires header 字段的值


此函数可用于 REQUEST_ROUTE。


```c title="xmpp_send_winfo 使用示例"
...
	if( is_method("SUBSCRIBE"))
	{
		handle_subscribe();
		if($ru=~"sip:.+@sip-xmpp.siphub.ro" && $hdr(Event)== "presence")
		{
			pua_xmpp_req_winfo($ruri, $hdr(Expires));
		}
		t_release();
	}

...
		
```


### 过滤


示例中的 "sip-xmpp.siphub.ro" 应替换为为 xmpp 模块参数 'gateway_domain' 设置的值。


## 开发者指南


此模块不提供供其他 OpenSIPS 模块使用的函数。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0（Creative Common License 4.0）授权。
