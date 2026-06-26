---
title: "PUA Usrloc"
description: "pua_usrloc 是 usrloc 和 pua 模块之间的连接器。它创建环境以便在特定事件发生时为用户位置记录发送 PUBLISH 请求（例如，当新记录添加到 usrloc 时，发送状态为 open（在线）的 PUBLISH；当过期时，发送 closed（离线））。"
---

## 管理指南


### 概述


pua_usrloc 是 usrloc 和 pua 模块之间的连接器。
它创建环境以便在特定事件发生时为用户位置记录发送 PUBLISH 请求（例如，当新记录添加到 usrloc 时，发送状态为 open（在线）的 PUBLISH；当过期时，发送 closed（离线））。


使用此模块，没有呈现支持的电话可以被视为在线/离线。


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *usrloc*。
- *pua*。


#### 外部库或应用程序


在运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *libxml*。


### 导出的参数


#### default_domain (str)


在构造 presentity URI 时，如果 recorded aor 中缺少域名，则使用的默认域名。


默认值为 "NULL"。


```c title="设置 default_domain 参数"
...
modparam("pua_usrloc", "default_domain", "opensips.org")
...
```


#### entity_prefix (str)


在 xml pidf 的 presence 节点中构造 entity 属性时添加的前缀。
（例如：pres:user@domain）。


默认值为 "NULL"。


```c title="设置 presentity_prefix 参数"
...
modparam("pua_usrloc", "entity_prefix", "pres")
...
```


#### presence_server (str)


presence 服务器的地址。如果设置，发送 PUBLISH 请求时将使用它作为 outbound proxy。


```c title="设置 presence_server 参数"
...
modparam("pua_usrloc", "presence_server", "sip:pa@opensips.org:5075")
...
	
```


### 导出的函数


#### pua_set_publish()


此函数用于标记必须发出 PUBLISH 的 REGISTER 请求。当 REGISTER 保存到位置表时，将发出 PUBLISH。


```c title="pua_set_publish 用法"
...
if(is_method("REGISTER") && $fu=~"john@opensips.org") 
	pua_set_publish();
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享 4.0 许可证。
