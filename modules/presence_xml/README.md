---
title: "Presence_XML 模块"
description: "该模块对使用 xml body 的 notify-subscribe 事件进行特定处理。它与通用事件处理模块 presence 一起使用。它向其中构造并添加 3 个事件：presence、presence.winfo、dialog;sla。"
---

## 管理指南


### 概述


该模块对使用 xml body 的 notify-subscribe 事件进行特定处理。
它与通用事件处理模块 presence 一起使用。它向其中构造并添加
3 个事件：presence、presence.winfo、dialog;sla。


该模块从 xcap_table 中获取 xcap 权限规则文档。

presence 权限规则根据 RFC 4745 和 RFC 5025 中的规范进行解释。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *数据库模块*。
- *presence*。
- *signaling*。
- *xcap*。
- *xcap_client*。
仅在未使用集成 xcap 服务器时必需
（如果未设置 'integrated_xcap_server' 参数）。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *libxml-dev*。


### 导出的参数


#### force_active (int)


此参数用于处理 Subscribe 消息时的权限。
如果设置为 1，订阅状态被视为活跃，且不会查询
presentity 的权限（如果不使用 xcap 服务器，应设置为 1）。
否则，将查询 xcap 服务器，订阅状态根据
用户定义的权限规则确定。如果为某个 watcher
定义了规则，则订阅保持待处理状态，发送的
Notify 将不包含 body。


注意：在切换值时，必须清空 watchers 表。


*默认值为 "0"。*


```c title="设置 force_active 参数"
...
modparam("presence_xml", "force_active", 1)
...
```


#### pidf_manipulation (int)


将此参数设置为 1 可启用 RFC 4827 中描述的功能。
它使用户可以即使在手机不在线的情况下也能获得永久状态通知。
presence document 从 xcap 服务器获取，并与
每次发送给 watchers 的 Notify 的其他 presence 信息（如果存在）聚合在一起。
即使不发布任何 Publish 也可以通知信息（适用于
电子邮件、短信、彩信等服务）。


*默认值为 "0"。*


```c title="设置 pidf_manipulation 参数"
...
modparam("presence_xml", "pidf_manipulation", 1)
...
```


#### xcap_server (str)


用于存储的 xcap 服务器地址。
如果未设置 integrated_xcap_server 参数，则此参数是必需的。
可以多次设置，以构建可信 XCAP 服务器的地址列表。


```c title="设置 xcap_server 参数"
...
modparam("presence_xml", "xcap_server", "xcap_server.example.org")
modparam("presence_xml", "xcap_server", "xcap_server.ag.org")
...
```


#### pres_rules_auid (str)


如果使用非集成 xcap 模式且需要使用默认的 'pres-rules'
以外的 pres-rules auid，则应配置此参数。


```c title="设置 pres_rules_auid 参数"
...
modparam("presence_xml", "pres_rules_auid", "org.openmobilealliance.pres-rules")
...
```


#### pres_rules_filename (str)


如果使用非集成 xcap 模式且需要配置默认的 'index'
以外的文件名，则应配置此参数。


```c title="设置 pres_rules_filename 参数"
...
modparam("presence_xml", "pres_rules_filename", "pres-rules")
...
```


#### generate_offline_body (str)


如果需要阻止 OpenSIPS 在 publication 过期或被明确终止时
自动生成 PIDF body（收到 Expires: 0 的 PUBLISH 请求时），
则应将此参数设置为 0。


```c title="设置 generate_offline_body 参数"
...
modparam("presence_xml", "generate_offline_body", 0)
...
```


### 导出的函数


配置文件中无需使用的函数。


### 安装


该模块需要在 OpenSIPS 数据库中创建 1 个表：xcap。SQL
语法可以在 opensips/scripts 文件夹的数据库目录中的
presence-create.sql 脚本中找到。
您还可以在项目网页上找到完整的数据库文档，
https://opensips.org/docs/db/db-schema-devel.html。


## 开发者指南


该模块不导出供其他 OpenSIPS 模块使用的函数。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可证 4.0
