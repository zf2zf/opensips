---
title: "紧急呼叫模块"
description: "紧急呼叫模块为 OpenSIPS 提供紧急呼叫处理功能，遵循美国 NENA（National Emergency Number Association，国家紧急号码协会）的 i2 架构规范。NENA 解决方案将紧急呼叫路由到最近的网关（ESGW），然后将呼叫转发到为呼叫者所在地区服务的 PSAP（负责接听紧急呼叫的呼叫中心）..."
---

## 管理指南


### 概述


紧急呼叫模块为 OpenSIPS 提供紧急呼叫处理功能，遵循美国 NENA（National Emergency Number Association，国家紧急号码协会）的 i2 架构规范。NENA 解决方案将紧急呼叫路由到最近的网关（ESGW），然后将呼叫转发到为呼叫者所在地区服务的 PSAP（负责接听紧急呼叫的呼叫中心），因此必须考虑在 SIP 协议中处理和传输呼叫者位置信息。

为满足这一新需求，NENA 解决方案由多个服务器组成：用于确定位置的位置信息服务器（LIS）、根据位置确定紧急处理区域的 VPC（Voice Protocol Controller，语音协议控制器）、验证存储位置的 VDB（Voice Database，语音数据库）等。除了这些元素，还有与这些服务器接口以路由呼叫的 SIP Proxy。OpenSIPS 可以通过此紧急呼叫模块实现这些 SIP Proxy 的功能，可以根据所提出的场景执行呼叫服务器、重定向服务器和路由代理的功能：


- 场景 I：VSP（VoIP 服务提供商）保留对紧急呼叫处理的控制。VSP 的呼叫服务器实现 v2 接口以查询 VPC 获取路由信息，使用此信息选择合适的 ESGW，如果正常路由失败则通过 PSTN 使用应急号码（LRO）路由呼叫。
- 场景 II：VSP 使用 v6 SIP 接口将所有紧急呼叫转移到路由代理提供商。转移完成后，VSP 不再参与呼叫。路由代理提供商实现 v2 接口，查询 VPC 获取路由信息，并转发呼叫。
- 场景 III：VSP 向重定向服务器操作员请求路由信息，但仍然参与呼叫。重定向服务器从 VPC 获取路由信息。它将呼叫连同 SIP Contact Header 中的路由信息返回给 VSP 的呼叫服务器。呼叫服务器根据此信息选择合适的 ESGW。


紧急呼叫模块允许 OpenSIPS 在所呈现的场景中扮演呼叫服务器、代理或重定向路由服务器的角色，具体取决于其配置。


1.2. 场景 I：发起呼叫的 VSP 与处理呼叫的 VSP 相同，并向 VPC 发送路由信息请求。 
	
		紧急呼叫模块通过 emergency_call() 命令检查收到的 INVITE 是否为紧急呼叫。如果是，OpenSIPS 将从 INVITE 中的特定头和正文获取呼叫者位置信息。结合为此模块定义的配置参数，opensips 实现 v2 接口以查询 VPC 获取路由信息（即 ESQK、LRO 以及 ERT 或 ESGWRI），基于 ESGWRI 选择合适的 ESGW。当呼叫结束时，OpenSIPS 收到 BYE 请求时，会通知 VPC 清理基于该呼叫的数据。	
		OpenSIPS 通过 failure() 命令，如果正常路由失败，将尝试使用应急号码（LRO）通过 PSTN 路由呼叫。


1.3. 场景 II：VSP 将呼叫转移到路由服务器提供商

		紧急呼叫模块通过 emergency_call() 命令检查收到的 INVITE 是否为紧急呼叫。如果是，它将呼叫转发到将与 VPC 接口并路由呼叫的路由代理。		
		OpenSIPS 将离开呼叫，此对话框收到的所有请求都将被转发到路由服务器。


1.4. 场景 III：VSP 向重定向服务器请求路由信息

		紧急呼叫模块通过 emergency_call() 命令检查收到的 INVITE 是否为紧急呼叫。如果是，它向重定向服务器请求路由信息。重定向服务器与 VPC 有接口，并在 Contact header 中返回带有路由信息给 VSP 的呼叫服务器。		
		呼叫服务器使用此信息处理呼叫。当紧急呼叫结束时，必须通知重定向服务器，再由其通知 VPC 释放资源。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *Dialog - 对话模块*。
- *TM - 事务模块*。
- *RR - 记录路由模块*。


#### 外部库或应用程序


运行加载此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *libcurl*。


### 导出的参数


#### db_url (string)


必须指定数据库 URL。


*默认值为 "NULL"。*


```c title="设置 db_url 参数"
...
modparam("emergency", "db_url", "mysql://opensips:opensipsrw@localhost/opensips")
...
		
```


#### db_table_routing (string)


存储紧急呼叫路由信息的数据库表名称。


*默认值为 "emergency_routing"。*


```c title="设置 db_table_routing 参数"
...
modparam("emergency", "db_table_routing", "emergency_routing")
...
		
```


#### db_table_report (string)


存储紧急呼叫报告的数据库表名称。


*默认值为 "emergency_report"。*


```c title="设置 db_table_report 参数"
...
modparam("emergency", "db_table_report", "emergency_report")
...
		
```


#### db_table_provider (string)


存储参与紧急呼叫的组织节点信息的数据库表名称。


*默认值为 "emergency_service_provider"。*


```c title="设置 db_table_provider 参数"
...
modparam("emergency", "db_table_provider", "emergency_service_provider")
...
		
```


#### proxy_role (integer)


此参数定义 opensips 处理紧急呼叫将扮演的角色：
			0 – opensips 在场景 I 中是呼叫服务器。在此角色中，opensips 实现 V2 接口，直接查询 VPC 获取 ESGWRI/ESQK，基于 ESGWRI 选择合适的 ESGW，如果路由失败则通过 PSTN 使用 LRO 路由呼叫。
			1 – opensips 在场景 II 中是发送紧急呼叫 INVITE 到路由代理提供商的呼叫服务器。路由代理提供商实现 V2 接口。
			2 - opensips 在场景 II 中是路由代理。在此角色中，opensips 实现 V2 接口，直接查询 VPC 获取 ESGWRI/ESQK，基于 ESGWRI 选择合适的 ESGW，如果路由失败则通过 PSTN 使用 LRO 路由呼叫。
			3 - opensips 在场景 III 中是接收来自呼叫服务器的紧急呼叫 INVITE 的重定向代理。重定向服务器从 VPC 获取 ESGWRI/ESQK，并在 SIP 3xx 响应中发送给呼叫服务器。	        
			4 - opensips 在场景 III 中是发送紧急呼叫 INVITE 到重定向服务器的呼叫服务器。重定向服务器从 VPC 获取 ESGWRI/ESQK。它将呼叫连同 SIP 响应中 header contact 中的 ESGWRI/ESQK 返回给 opensips。opensips 基于 ESGWRI 选择合适的 ESGW。


*默认值为 "0"。*


```c title="设置 proxy_role 参数"
...
modparam("emergency", "proxy_role", 0))
...
		
```


#### url_vpc (string)


VPC URL，opensips 向其请求紧急呼叫的路由信息。此 VPC URL 格式为 IP:Port。


*默认值为空字符串"。*


```c title="设置 url_vpc 参数"
...
modparam("emergency", "url_vpc", "192.168.0.103:5060")
...
		
```


#### emergency_codes (string)


本地紧急号码。Opensips 使用此号码识别紧急呼叫，除了 RFC-5031（urn:service.sos.）定义的默认用户名外的紧急呼叫。        
		除了号码外，还应提供关于此代码的简要描述。格式为 code_number-description。可以注册多个紧急号码。


*默认值为 "NULLg"。*


```c title="设置 emergency_codes 参数"
...
modparam("emergency", "emergency_codes", "911-us emegency code")
...
		
```


#### timer_interval (integer)


设置轮询的时间间隔，以将 db_table_routing 复制到内存中。


*默认值为 "10"。*


```c title="设置 timer_interval 参数"
...
modparam("emergency","timer_interval",20)
...
		
```


#### contingency_hostname (string)


contingency_hostname 是服务器的 URL，该服务器将使用应急号码将呼叫路由到 PSTN。


*默认值为 "NULL"。*


```c title="设置 contingency_hostname 参数"
...
modparam("emergency","contingency_hostname","176.34,29.102:5060")
...
		
```


#### emergency_call_server (string)


emergency_call_server 是将处理场景 II 中紧急呼叫的路由代理/重定向服务器的 URL。如果 Opensips 在场景 II 中担任呼叫服务器（proxy_role = 1 且 flag_third_enterprise = 0）或在场景 III 中担任呼叫服务器（proxy_role = 2），则此参数是必需的。


*默认值为 "NULL"。*


```c title="设置 emergency_call_server 参数"
...
modparam("emergency","emergency_call_server","124.78.29.123:5060")
...
		
```


### 导出的函数


#### emergency_call()


检查传入呼叫是否为紧急呼叫，如果是，则处理呼叫，并将呼叫路由到 VPC 指定的目的地。

		如果这是一个紧急呼叫且处理成功，函数返回 true。


此函数可用于 *REQUEST* 路由。


```c title="emergency_call() 使用示例"
...
# 紧急呼叫处理示例

    if (emergency_call()){

        xlog("紧急呼叫\n");
        t_on_failure("emergency_call");
        t_relay();
        exit;

  	}
...
		
```


#### failure()


当尝试将紧急呼叫路由到 VPC 指定的目的地失败时，使用此函数通过应急号码进行最后一次尝试。

		如果应急处理成功，函数返回 true。


此函数可用于 *FAILURE* 路由。


```c title="failure() 使用示例"
...
# 紧急呼叫中应急处理示例

    if (failure()) {
        if (!t_relay()) {
            send_reply(500,"内部错误");
        };
        exit;
    }
...
		
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用 Creative Common License 4.0 许可证
