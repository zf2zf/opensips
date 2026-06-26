---
title: "PUA MI"
description: "pua_mi 提供通过 MI 传输发布和订阅 presence 信息的功能。"
---

## 管理指南


### 概述


pua_mi 提供通过 MI 传输发布和订阅 presence 信息的功能。


使用此模块，您可以创建独立的应用程序/脚本来发布与 SIP 无关的信息（例如，系统资源如 CPU 使用率、内存、活动订阅者数量等）。此外，此模块允许非 SIP 应用程序订阅 SIP presence 服务器中保存的 presence 信息。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *pua*


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *无*


### 导出的参数


#### presence_server (str)


Presence 服务器的地址。如果设置，发送 PUBLISH 请求时将用作 outbound proxy。


```c title="设置 presence_server 参数"
...
modparam("pua_mi", "presence_server", "sip:pa@opensips.org:5075")
...
	
```


### 导出的函数


此模块不导出供配置脚本使用的函数。


### 导出的 MI 函数


#### pua_mi:publish


替代已废弃的 MI 命令：*pua_publish*。


命令参数：


- *presentity_uri* - 例如 sip:system@opensips.org
- *expires* - 相对过期时间，以秒为单位（例如 3600）。
- *event_package* - 发布信息的目标事件包（例如 presence）。
- *content_type* (可选) - 发布信息的 content type（例如 application/pidf+xml）。如果提供此参数，则还需要 *body* 参数。
- *etag* (可选) - publish 应该匹配的 ETag。
- *extra_headers* (可选) - 添加到 PUBLISH 请求的额外 header。
- *body* (可选) - 包含发布信息的 publish 请求正文，如果没有发布信息则可省略。
			对于 FIFO 传输，它必须是单行的。如果提供此参数，则还需要 *content_type* 参数。


```c title="pua_mi:publish FIFO 示例"
...

opensips-cli -x mi pua_mi:publish sip:system@opensips.org 3600 presence application/pidf+xml <?xml version='1.0'?><presence xmlns='urn:ietf:params:xml:ns:pidf' xmlns:dm='urn:ietf:params:xml:ns:pidf:data-model' xmlns:rpid='urn:ietf:params:xml:ns:pidf:rpid' xmlns:c='urn:ietf:params:xml:ns:pidf:cipid' entity='system@opensips.org'><tuple id='0x81475a0'><status><basic>open</basic></status></tuple><dm:person id='pdd748945'><rpid:activities><rpid:away/>away</rpid:activities><dm:note>CPU:16 MEM:476</dm:note></dm:person></presence>
```


#### pua_mi:subscribe


替代已废弃的 MI 命令：*pua_subscribe*。


命令参数：


- *presentity_uri* - 例如 sip:presentity@opensips.org
- *watcher_uri* - 例如 sip:watcher@opensips.org
- *event_package*
- *expires* - 订阅有效期的相对时间，以秒为单位。


```c title="pua_mi:subscribe FIFO 示例"
...

opensips-cli -x mi pua_mi:subscribe sip:system@opensips.org sip:400@opensips.org presence 3600
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0（Creative Common License 4.0）授权。
