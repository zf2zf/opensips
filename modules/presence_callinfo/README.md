---
title: "Presence_CallInfo 模块"
description: "该模块为 OpenSIPS 提供共享呼叫外观（SCA）支持，如 BroadWorks SIP Access Side Extensions Interface 规范所定义。SCA 机制是各种增强电话服务的基本构建块。功能如总机控制台、线路扩展..."
---

## 管理指南


### 概述


该模块为 OpenSIPS 提供共享呼叫外观（SCA）支持，
		如 BroadWorks SIP Access Side Extensions Interface 规范所定义。
		SCA 机制是各种增强电话服务的基本构建块。
		功能如总机控制台、线路扩展和按键系统模拟，
		如果没有任何在访问设备之间共享呼叫外观的机制，则无法实现。
		虽然 SIP（RFC 3261）本身不提供支持 SCA 功能的固有语义，
		但当与"SIP 特定事件通知"框架（RFC 3265）适当结合时，
		这些服务可以相当容易地部署在分布式网络中。


共享线路是由中央控制元素（如应用服务器）管理的地址记录。
		应用服务器允许多个端点向地址记录注册位置。
		应用服务器负责控制谁可以注册和谁不能注册共享线路。


该模块支持在 presence 模块中处理 "call-info" 和 "line-seize" 事件。
		它与通用事件处理模块：presence 一起使用，
		并构造和添加 "Call-Info" 头到通知事件。


### 使用模式


该模块可以以两种方式使用（取决于谁在发布 "call-info" 数据）：


- 外部发布 - "call-info" 数据通过 SIP PUBLISH 请求从第三方接收。
				在此模式下，模块只是分发 SCA 信息，不生成任何信息——第三方应用必须向 presence 服务器发布 "call-info" 事件。
- 内部发布 - "call-info" 数据由模块根据从 dialog 模块接收的信息内部生成——
				哪些呼叫使用哪些线路/索引，呼叫的状态等。
				在此情况下没有 SIP PUBLISH，也不需要第三方——模块在功能上是自给自足和独立的。


使用的模式可以通过模块参数 "disable_dialog_support_for_sca" 控制——请参阅下面参数部分中的说明。


#### 外部发布


该模块目前不实现任何授权规则。它假设发布请求仅由第三方应用发送，
			订阅请求仅由订阅 call-info 和 line-seize 事件的订阅者发送。
			因此，授权可以很容易地在 OpenSIPS 配置文件中完成，
			然后再调用 handle_publish() 和 handle_subscribe() 函数。


为了更好地理解模块的工作原理，请看下图：


```c
   caller       proxy &   callee        watcher        publisher
alice@example  presence  bob@example  watcher@example
                 server                       
     |             |           |           |              |
     |             |<-----SUBSCRIBE bob----|              |
     |             |------200 OK---------->|              |
     |             |------NOTIFY---------->|              |
     |             |<-----200 OK-----------|              |
     |             |           |           |              |
     |--INV bob--->|           |           |              |
     |             |--INV bob->|           |              |
     |             |<-100------|           |              |
     |             |<-----PUBLISH(alerting)---------------|
     |             |------200 OK------------------------->|
     |             |------NOTIFY---------->|              |
     |             |<-----200 OK-----------|              |
     |             |           |           |              |
     |             |<-180 ring-|           |              |
     |<--180 ring--|           |           |              |
     |             |           |           |              |
     |             |           |           |              |
     |             |<-200 OK---|           |              |
     |<--200 OK----|           |           |              |
     |             |<-----PUBLISH(active)-----------------|
     |             |------200 OK------------------------->|
     |             |------NOTIFY---------->|              |
     |             |<-----200 OK-----------|              |
     |             |           |           |              |

			
```


- watcher 订阅 Bob 的 "Event: dialog"。
- Alice 呼叫 Bob。
- publisher 正在为 Bob 发布 "alerting" 状态。
- PUBLISH 被接收并由 presence 模块处理。
				Presence 模块更新 "presentity"。
				Presence 模块检查 presentity 的 active watcher。
				active watcher 通过 NOTIFY SIP 请求得到通知。
- Bob 接听电话。
- publisher 正在为 Bob 发布 "active" 状态。
- PUBLISH 被接收并由 presence 模块处理。
				Presence 模块更新 "presentity"。
				Presence 模块检查 presentity 的 active watcher。
				active watcher 通过 NOTIFY SIP 请求得到通知。


#### 内部发布


在此模式下，模块需要将 "dialog" 模块加载到 OpenSIPS 中。
			所有发布将自动完成（模块将通过 C API 直接交换数据）。


从 presence 的角度来看，OpenSIPS 脚本必须配置为仅处理 SUBSCRIBE 请求
			（在此模式下没有 SIP 发布，因此不需要 PUBLISH 处理）。
			因此，请确保在脚本中使用 presence 模块的 "handle_subscribe()" 函数。


要触发（从 dialog 模块）某个呼叫的内部发布，
			在处理新呼叫时使用脚本中的 "sca_set_calling_line()" 或
			"sca_set_called_line()" 函数。
			这些函数将完成所有工作（创建 dialog、设置内部发布等）——
			您只需要使用它们，最终指定线路的名称（如果不是来自 SIP INVITE 的线路）——
			请参阅下面的文档。


限制：在此模式下，模块不会真正检查线路是否存在（如已定义）——
			它盲目地信任流量；
			也没有检查每个线路有多少索引。
			此类信息（线路和索引）未配置到模块中，
			但模块将根据 SIP 流量动态接受和处理任何线路和索引。


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *presence*。
- *dialog*。


#### 外部库或应用程序


无。


### 导出的参数


#### call_info_timeout_notification (int)


启用或禁用 call_info 事件超时通知。


*默认值为 "1"*（启用）。


```c title="设置 call_info_timeout_notification 参数"
...
modparam("presence_callinfo", "call_info_timeout_notification", 0)
...
			
```


#### line_seize_timeout_notification (int)


启用或禁用 line_seize 事件超时通知。


*默认值为 "0"*（禁用）。


```c title="设置 line_seize_timeout_notification 参数"
...
modparam("presence_callinfo", "line_seize_timeout_notification", 1)
...
			
```


#### disable_dialog_support_for_sca (int)


禁用 "call-info" 事件的内部发布（由 dialog 模块生成）。
			发布预计通过第三方的 SIP PUBLISH 完成。
			请参阅本文档开头描述的工作模式。


*默认值为 "0"*（不禁用）。


```c title="设置 disable_dialog_support_for_sca 参数"
...
modparam("presence_callinfo", "disable_dialog_support_for_sca", 1)
...
			
```


#### line_hash_size (int)


允许您控制内部哈希表的大小，用于存储有关线路和索引的信息（内部发布模式）。


该值必须是 2 的幂。
		如果使用大量线路（>1000），您可以考虑增加该值。


*默认值为 "64"*。


```c title="设置 line_hash_size 参数"
...
modparam("presence_callinfo", "line_hash_size", 128)
...
			
```


### 导出的函数


#### sca_set_calling_line([line])


该函数（仅用于内部发布模式）为当前新呼叫（初始 INVITE）设置 outbound 线路——用于外呼的线路。


如果未提供参数，则从 INVITE 的 SIP FROM 头获取线路名称。
		您可以通过提供线路名称作为字符串参数来覆盖它——请注意，该值必须是 SIP URI！


此函数可用于 REQUEST_ROUTE。


```c title="sca_set_calling_line() 使用示例"
...
	if (is_method("INVITE") and !has_totag()) {
		sca_set_calling_line();
	}
...
```


#### sca_set_called_line([line])


该函数（仅用于内部发布模式）为当前新呼叫（初始 INVITE）设置 inbound 线路——接收呼叫的线路。


如果未提供参数，则从 INVITE 的 SIP RURI 获取线路名称。
		您可以通过提供线路名称作为字符串参数来覆盖它——请注意，该值必须是 SIP URI！接受变量。


此函数可用于 REQUEST_ROUTE。


```c title="sca_set_called_line() 使用示例"
...
	if (is_method("INVITE") and !has_totag()) {
		sca_set_called_line();
	}
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
