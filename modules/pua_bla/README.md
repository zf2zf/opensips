---
title: "PUA 桥接线外观"
description: "pua_bla 模块根据 draft-anil-sipping-bla-03.txt 规范提供桥接线外观（Bridged Line Appearances）支持。"
---

## 管理指南


### 概述


pua_bla 模块根据 draft-anil-sipping-bla-03.txt 规范提供桥接线外观（Bridged Line Appearances）支持。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *usrloc*。
- *pua*。
- *presence*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *libxml*。


### 导出的参数


#### default_domain (str)


注册用户的默认域名，用于构造注册回调的 URI。


*默认值为 "NULL"。*


```c title="设置 default_domain 参数"
...
modparam("pua_bla", "default_domain", "opensips.org")
...
```


#### header_name (str)


要添加到 PUBLISH 请求的 header 名称。它包含发送 Notify 的用户代理的 URI，该 Notify 被转换为 Publish。它停止向发送者发送包含相同信息的通知。


*默认值为 "NULL"。*


```c title="设置 header_name 参数"
...
modparam("pua_bla", "header_name", "Sender")
...
```


#### outbound_proxy (str)


发送 SUBSCRIBE 请求时使用的 outbound_proxy URI。


*默认值为 "NULL"。*


```c title="设置 outbound_proxy 参数"
...
modparam("pua_bla", "outbound_proxy", "sip:proxy@opensips.org")
...
```


#### server_address (str)


服务器的 IP 地址。


```c title="设置 server_address 参数"
...
modparam("pua_bla", "server_address", "sip:bla@160.34.23.12")
...
```


#### presence_server (str)


Presence 服务器的地址——发送 PUBLISH 请求时将用作 outbound proxy。可选。


*默认值为 "NULL"。*


```c title="设置 presence_server 参数"
...
modparam("pua_bla", "presence_server", "sip:pa@opensips.org")
...
```


### 导出的函数


#### bla_set_flag()


此函数用于标记发送到 BLA AOR 的 REGISTER 请求。模块订阅已注册的联系人的 dialog;sla 事件。


```c title="bla_set_flag 使用示例"
...
if(is_method("REGISTER") && $tu=~"bla_aor@opensips.org") 
	bla_set_flag();		
...
```


#### bla_handle_notify()


此函数处理从同一 BLA 上的电话发送到服务器的 NOTIFY 请求。消息被转换为 PUBLISH 请求并传递给 presence 模块进行进一步处理。成功处理后应发送 2xx 回复。


```c title="bla_handle_notify 使用示例"
...
if(is_method("NOTIFY") && $tu=~"bla_aor@opensips.org") 
{
		if( bla_handle_notify() ) 
			t_reply(200, "OK");
}	
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0（Creative Common License 4.0）授权。
