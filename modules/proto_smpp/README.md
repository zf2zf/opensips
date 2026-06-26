---
title: "proto_smpp 模块"
description: "该模块提供 SIP 和 SMPP(Short Message Peer-to-Peer)协议之间的互操作性。它提供了在这两个协议之间构建消息网关/桥接的方法,能够双向转换消息。"
---

## 管理指南


### 概述


该模块提供 SIP 和 SMPP
			(Short Message Peer-to-Peer)协议之间的互操作性。它提供了在这两个协议之间构建消息网关/桥接的方法,能够双向转换消息。


- SIP 到 SMPP - 来自 SIP 的消息可以转换为
			SMPP PDU(Protocol Data Unit)消息并进一步发送到
			SMSC(Short Message Service Center)。
- SMPP 到 SIP - 该模块可以充当 ESME(External Short
			Messaging Entity),从 SMSC 接收消息并将其转换为 SIP 消息,进一步发送到 SIP 代理。


该模块兼容 [SMPP v3.4](http://opensmpp.org/specs/SMPP_v3_4_Issue1_2.pdf) 规范。


### SIP 到 SMPP 桥接


为了将 SIP 消息转换为 SMPP,你需要做的只是调用 [send smpp message](#func_send_smpp_message) 函数,
			指明你要向哪个 SMSc 发送消息。该模块将根据数据库中提供的参数构建 PDU。


### SMPP 到 SIP 桥接


当桥接通过 SMPP 接口收到的消息时,
			OpenSIPS 构建一个 SIP 消息并将其发送到由 [smpp outbound uri](#param_outbound_uri)
			模块参数标识的出站代理。


### SMSC 绑定


为了能够向 SMSc 传递消息,ESME 首先需要绑定到 SMSc。这在 OpenSIPS 启动时完成,发送 SMPP *bind_transciever* 命令连接到 SMSc,或发送 *outbind* 命令通知 SMSc 我们的网关现在可以绑定了。


所有 SMSc 服务器的描述在数据库中提供。对于每个服务器,可以配置以下信息:


- *名称* - 给予 SMSc 的唯一名称,
			用于在 OpenSIPS 脚本中引用此 SMSc。
- *IP* - SMSc 监听
			新绑定/连接的 IP。
- *端口* - SMSc
			监听新绑定/连接的 TCP 端口。
- *系统 ID* - 也称为
			用于向 SMSc 认证的用户名。
- *密码* - 用于
			向 SMSc 认证的密码。
- *系统类型* - 通常
			是"SMPP",某些 SMPP 提供商需要此字段。
- *源号码类型(TON)* - 指定
			发送消息所用号码的格式。常见值为:
				
				*0* - 未知
				*1* - 国际
				*2* - 国内
				*3* - 网络特定
				*4* - 用户号码
				*5* - 字母数字
				*6* - 缩写
				
			默认值为 *0 - 未知*。
- *源号码计划指示符(NPI)* - 指定
			发送消息所用号码的编号方案。常见值为:
				
				*0* - 未知
				*1* - ISDN/电话编号计划(E163/E164)
				*3* - 数据编号计划(X.121)
				*4* - 电传编号计划(F.69)
				*6* - 陆地移动(E.212)
				*8* - 国内编号计划
				*9* - 专用编号计划
				*10* - ERMES 编号计划(ETSI DE/PS 3 01-3)
				*13* - 互联网(IP)
				*18* - WAP 客户端 ID(由 WAP 论坛定义)
				
			默认值为 *0 - 未知*。
- *目标号码类型(TON)* - 指定
			发送消息到哪个号码的格式。具有与
			*源号码类型(TON)* 相同的值,默认值为 *0 -
			未知*。
- *目标号码计划指示符(NPI)* -
			指定发送消息到哪个号码的编号方案。具有与 *源号码计划指示符(NPI)* 相同的值,
			默认值为 *0 - 未知*。
- *会话类型* - 指定应使用什么类型的会话
			连接到 SMSc。可能的值为:
				
				*1* - 收发器
				*2* - 发射器
				*3* - 接收器
				*4* - 出站绑定
				
			默认值为 *1 - 收发器*。


当 OpenSIPS 启动时,它从数据库读取所有 SMSc 规范并触发与它们的绑定。*注意:*
			重新加载 SMSc 数据库尚不支持,但正在开发中。


每个 SMPP 连接定期(目前每 5 秒)使用 *enquire_link* SMPP 命令进行 ping,
			以保持连接活跃。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载:


- *database* -- 任何数据库模块


#### 外部库的依赖


- *无*。


### 导出的参数


所有这些参数都可以从 opensips.cfg 文件使用,
		来配置 OpenSIPS-SMPP 网关的行为。


#### db_url (string)


存储 SMPP 连接的数据库处理程序。此参数是必需的。


*默认值为 *未设置*。*


```c title="设置 db_url 参数"
...
modparam("proto_smpp", "db_url", "dbdriver://username:password@dbhost/dbname")
...
```


#### smpp_port (integer)


用于更改监听新连接的 SMPP 端口的默认值。


*默认值为 2775。*


```c title="设置 smpp_port 变量"
...
modparam("proto_smpp", "smpp_port", 27775)
...
			
```


#### smpp_max_msg_chunks (integer)


SMPP 消息通过 TCP 传输时预期的最大分片数。如果收到的数据包分片程度超过此值,则连接将被断开(要么连接严重过载导致高分片,要么我们正受到攻击,攻击者发送非常碎片化的流量以降低服务器性能)。


*默认值为 8。*


```c title="设置 smpp_max_msg_chunks 参数"
...
modparam("proto_smpp", "smpp_max_msg_chunks", 32)
...
```


#### smpp_send_timeout (integer)


TCP 连接在此时间后将被关闭(如果在此间隔内无法进行阻塞写入,并且 OpenSIPS 想在其上发送数据)。


*默认值为 100 ms。*


```c title="设置 smpp_send_timeout 参数"
...
modparam("proto_smpp", "smpp_send_timeout", 200)
...
```


#### outbound_uri (string)


此参数表示用于发送从 SMPP 转换而来的 SIP 消息的出站代理的 URI。


*默认值为 *无*。*


```c title="设置 outbound_uri 参数"
...
modparam("proto_smpp", "outbound_uri", "sip:127.0.0.1:5060")
...
```


#### smpp_table (string)


包含要连接到的 SMSc 服务器定义的数据库表名。


*默认值为 "smpp"。*


```c title="设置 smpp_table 参数"
...
modparam("proto_smpp", "smpp_table", "smsc")
...
```


#### name_col (string)


保存 SMSc 标识符的列名,供 *send_smpp_message()* 函数引用。


*默认值为 "name"。*


```c title="设置 name_col 参数"
...
modparam("proto_smpp", "name_col", "smsc_name")
...
```


#### ip_col (string)


保存 SMSc IP 的列名。


*默认值为 "ip"。*


```c title="设置 ip_col 参数"
...
modparam("proto_smpp", "ip_col", "smsc_ip")
...
```


#### port_col (string)


保存 SMSc 端口的列名。


*默认值为 "port"。*


```c title="设置 port_col 参数"
...
modparam("proto_smpp", "port_col", "smsc_port")
...
```


#### system_id_col (string)


保存 SMSc 系统 ID 的列名。


*默认值为 "system_id"。*


```c title="设置 system_id_col 参数"
...
modparam("proto_smpp", "system_id_col", "smsc_system_id")
...
```


#### password_col (string)


保存用于认证 SMSc 的密码列名。


*默认值为 "password"。*


```c title="设置 password_col 参数"
...
modparam("proto_smpp", "password_col", "smsc_password")
...
```


#### system_type_col (string)


用于绑定 SMSc 的系统类型列名。


*默认值为 "system_type"。*


```c title="设置 system_type_col 参数"
...
modparam("proto_smpp", "system_type_col", "smsc_system_type")
...
```


#### src_ton_col (string)


保存源 TON 值的列名。


*默认值为 "src_ton"。*


```c title="设置 src_ton_col 参数"
...
modparam("proto_smpp", "src_ton_col", "smsc_src_ton")
...
```


#### src_npi_col (string)


保存源 NPI 值的列名。


*默认值为 "src_npi"。*


```c title="设置 src_npi_col 参数"
...
modparam("proto_smpp", "src_npi_col", "smsc_src_npi")
...
```


#### dst_ton_col (string)


保存目标 TON 值的列名。


*默认值为 "dst_ton"。*


```c title="设置 dst_ton_col 参数"
...
modparam("proto_smpp", "dst_ton_col", "smsc_dst_ton")
...
```


#### dst_npi_col (string)


保存目标 NPI 值的列名。


*默认值为 "dst_npi"。*


```c title="设置 dst_npi_col 参数"
...
modparam("proto_smpp", "dst_npi_col", "smsc_dst_npi")
...
```


#### session_type_col (string)


保存 SMSc 会话类型的列名。


*默认值为 "session_type"。*


```c title="设置 session_type_col 参数"
...
modparam("proto_smpp", "session_type_col", "smsc_session_type")
...
```


### 导出的函数


#### send_smpp_message(smsc_name, [from],[to],[body],[utf-16],[delivery_receipt])


此函数用于将在 OpenSIPS 脚本中收到的 SIP 消息转换为 SMPP PDU 并发送到作为参数收到的 *smsc_name (string)*。
			用于构建 PDU 的 SMPP 参数在数据库中提供,发送的命令是
			*submit_sm* 或 *deliver_sm*,
			取决于 SMSc 的类型。


如果数据库中不存在应发送消息的 SMSc,函数返回 *-2*,
			如果存在内部错误返回 *-1*,
			成功时返回正值。


参数含义如下:


- *sms_name (string)* - SMS 的名称,
					用于发送 SMPP 流量。
- *from (string, 可选)* - 源号码。
				如果缺失,使用 SIP 消息的 from 用户名。
- *to (string, 可选)* - 目标号码。
				如果缺失,使用 SIP 请求 URI 用户名。
- *body (string, 可选)* - SMS 的正文。
				如果缺失,使用 SIP 消息正文。
- *UTF-16 (int, 可选)* - 设置为
				*1* 如果消息正文是 UTF-16 格式。如果缺失或 *0*,则使用 UTF-8。
- *delivery_receipt (int, 可选)* - SMSC 是否应确认此 SMS 的送达


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE
			或 BRANCH_ROUTE。


```c title="send_smpp_message() 使用示例"
...
    if (is_method("MESSAGE"))
			send_smpp_message("MY_SMSC");
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)采用 Creative Common License 4.0 授权
