---
title: "MSILO 模块"
description: "此模块为Open SIP Server提供离线消息存储。它为离线用户存储接收到的消息，并在用户上线时发送。"
---

## 管理指南


### 概述


此模块为Open SIP Server提供离线消息存储。它为离线用户存储接收到的消息，并在用户上线时发送。


对于每条消息，模块存储"Request-URI"（"R-URI"），仅当它是完整的地址记录（"username@hostname"）时，以及"To"头中的URI、"From"头中的URI、接收时间、过期时间、内容类型和消息体。如果"R-URI"不是地址记录（它可能是当前SIP会话的contact地址），则使用"To"头中的URI作为R-URI。


当过期时间过去时，消息将从数据库中丢弃。过期时间基于接收时间和模块参数之一计算。


每次用户向OpenSIPS注册时，模块会在数据库中查找该用户的离线消息。所有这些消息都将发送到REGISTER请求中提供的contact地址。


有时SIP用户可能已注册但其SIP用户代理不支持MESSAGE请求。这种情况下应使用"failure_route"来存储未传递的请求。


模块提供的另一个功能是在特定时间发送消息——提醒功能。使用配置逻辑，接收到的消息可以存储并在存储时指定的时间使用'snd_time_avp'发送。


### 依赖


#### OpenSIPS模块


以下模块必须在此模块之前加载：


- *数据库模块* - mysql、dbtext或其他实现"db"接口并提供对数据库系统存储/接收数据支持的模块。
- *TM*--事务模块--用于发送SIP请求。


#### 外部库或应用程序


运行此模块之前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### db_url (string)


数据库URL。


*默认值为"mysql://opensips:opensipsrw@localhost/opensips"。*


```c title="设置 'db_url' 参数"
...
modparam("msilo", "db_url", "mysql://user:passwd@host.com/dbname")
...
```


#### db_table (string)


存储消息的表名。


*默认值为"silo"。*


```c title="设置 'db_table' 参数"
...
modparam("msilo", "db_table", "silo")
...
```


#### from_address (string)


用于通知用户其消息目标不在线且该消息将在该用户下次上线时传递的SIP地址。如果未设置此参数，模块将不发送任何通知。它可以包含伪变量。


*默认值为"NULL"。*


```c title="设置 'from_address' 参数"
...
modparam("msilo", "from_address", "sip:registrar@example.org")
modparam("msilo", "from_address", "sip:$rU@example.org")
...
```


#### contact_hdr (string)


通知消息中要添加的Contact头的值（包括头名称和结束符\r\n）。它可以包含伪变量。


*默认值为"NULL"。*


```c title="设置 'contact_hdr' 参数"
...
modparam("msilo", "contact_hdr", "Contact: <sip:null@example.com>\r\n")
...
```


#### offline_message (string)


通知消息的正文。它可以包含伪变量。


*默认值为"NULL"。*


```c title="设置 'offline_message' 参数"
...
modparam("msilo", "offline_message", "*** 用户 $rU 已离线！")
modparam("msilo", "offline_message", "<em>我已离线！</em>")
...
```


#### content_type_hdr (string)


通知消息中要添加的Content-Type头的值（包括头名称和结束符\r\n）。它必须反映'offline_message'包含的内容。它可以包含伪变量。


*默认值为"NULL"。*


```c title="设置 'content_type_hdr' 参数"
...
modparam("msilo", "content_type_hdr", "Content-Type: text/plain\r\n")
modparam("msilo", "content_type_hdr", "Content-Type: text/html\r\n")
...
```


#### reminder (string)


用于发送提醒消息的SIP地址。如果未设置此值，提醒功能将被禁用。


*默认值为"NULL"。*


```c title="设置 'reminder' 参数"
...
modparam("msilo", "reminder", "sip:registrar@example.org")
...
```


#### outbound_proxy (string)


发送消息时用作下一跳的SIP地址。当使用OpenSIPS且域名不在DNS中，或使用单独的OpenSIPS实例进行msilo处理时非常有用。如果未设置，消息将发送到目标URI中的地址。


*默认值为"NULL"。*


```c title="设置 'outbound_proxy' 参数"
...
modparam("msilo", "outbound_proxy", "sip:opensips.org;transport=tcp")
...
```


#### expire_time (int)


存储消息的过期时间（秒）。超过此时间后，消息将被静默丢弃。


*默认值为"259200（72小时=3天）"。*


```c title="设置 'expire_time' 参数"
...
modparam("msilo", "expire_time", 36000)
...
```


#### check_time (int)


检查转储消息是否发送成功的计时器间隔（秒）。模块为每个向新上线用户发送的请求保留，如果回复是2xx，则从数据库中删除消息。


*默认值为"30"。*


```c title="设置 'check_time' 参数"
...
modparam("msilo", "check_time", 10)
...
```


#### send_time (int)


检查是否有提醒消息的计时器间隔（秒）。模块获取所有此刻或之前必须发送的提醒消息。


如果值为0，提醒功能将被禁用。


*默认值为"0"。*


```c title="设置 'send_time' 参数"
...
modparam("msilo", "send_time", 60)
...
```


#### clean_period (int)


检查数据库中是否有过期消息的"check_time"周期数。


*默认值为"5"。*


```c title="设置 'clean_period' 参数"
...
modparam("msilo", "clean_period", 3)
...
```


#### use_contact (int)


开启/关闭使用Contact地址发送通知回发送者（其消息由MSILO存储）的功能。


*默认值为"1（0=关闭，1=开启）"。*


```c title="设置 'use_contact' 参数"
...
modparam("msilo", "use_contact", 0)
...
```


#### sc_mid (string)


silo表中存储消息ID的列名。


默认值为"mid"。


```c title="设置 'sc_mid' 参数"
...
modparam("msilo", "sc_mid", "other_mid")
...
```


#### sc_from (string)


silo表中存储源地址的列名。


默认值为"src_addr"。


```c title="设置 'sc_from' 参数"
...
modparam("msilo", "sc_from", "source_address")
...
```


#### sc_to (string)


silo表中存储目标地址的列名。


默认值为"dst_addr"。


```c title="设置 'sc_to' 参数"
...
modparam("msilo", "sc_to", "destination_address")
...
```


#### sc_uri_user (string)


silo表中存储用户名的列名。


默认值为"username"。


```c title="设置 'sc_uri_user' 参数"
...
modparam("msilo", "sc_uri_user", "user")
...
```


#### sc_uri_host (string)


silo表中存储域名的列名。


默认值为"domain"。


```c title="设置 'sc_uri_host' 参数"
...
modparam("msilo", "sc_uri_host", "domain")
...
```


#### sc_body (string)


silo表中存储消息体的列名。


默认值为"body"。


```c title="设置 'sc_body' 参数"
...
modparam("msilo", "sc_body", "message_body")
...
```


#### sc_ctype (string)


silo表中存储内容类型的列名。


默认值为"ctype"。


```c title="设置 'sc_ctype' 参数"
...
modparam("msilo", "sc_ctype", "content_type")
...
```


#### sc_exp_time (string)


silo表中存储消息过期时间的列名。


默认值为"exp_time"。


```c title="设置 'sc_exp_time' 参数"
...
modparam("msilo", "sc_exp_time", "expire_time")
...
```


#### sc_inc_time (string)


silo表中存储消息接收时间的列名。


默认值为"inc_time"。


```c title="设置 'sc_inc_time' 参数"
...
modparam("msilo", "sc_inc_time", "incoming_time")
...
```


#### sc_snd_time (string)


silo表中存储提醒发送时间的列名。


默认值为"snd_time"。


```c title="设置 'sc_snd_time' 参数"
...
modparam("msilo", "sc_snd_time", "send_reminder_time")
...
```


#### snd_time_avp (str)


可能包含接收消息作为提醒发送时间的AVP名称。此AVP仅由m_store()使用。


如果未设置参数，模块不会查找此AVP。如果值设置为有效的AVP名称，则模块期望AVP中的时间格式为YYYYMMDDHHMMSS（例如20060101201500）。


*默认值为"null"。*


```c title="设置 'snd_time_avp' 参数"
...
modparam("msilo", "snd_time_avp", "$avp(snd_time)")
...
```


#### add_date (int)


是否将消息存储时的日期作为前缀。


*默认值为"1"（1=开启/0=关闭）。*


```c title="设置 'add_date' 参数"
...
modparam("msilo", "add_date", 0)
...
```


#### max_messages (int)


AoR存储消息的最大数量。值0等于无限制。


*默认值为0。*


```c title="设置 'max_messages' 参数"
...
modparam("msilo", "max_messages", 0)
...
```


### 导出的函数


#### m_store([owner])


此方法存储当前SIP请求的某些部分（应在请求类型为MESSAGE且目标用户离线或其UA不支持MESSAGE请求时调用）。如果用户注册的UA不支持MESSAGE请求，如果已用用户UA的contact地址更改了请求uri，则不应使用mode="0"。


参数的含义如下：


- *owner* (string, 可选) - 消息将存储在其收件箱中的SIP URI。如果"owner"缺失，则从R-URI获取SIP地址。


此函数可用于REQUEST_ROUTE、FAILURE_ROUTE。


```c title="m_store 使用示例"
...
m_store();
m_store($tu);
...
```


#### m_dump([owner], [maxmsg])


此方法向将注册的SIP用户发送存储的消息到其实际contact地址。此方法应在收到REGISTER请求且"Expire"头值大于零时调用。


参数的含义如下：


- *owner* (string, 可选) - 将被转储其收件箱的SIP URI。如果"owner"缺失，则从To URI获取SIP地址。
- *maxmsg* (int, 可选) - 要转储的最大消息数。


此函数可用于REQUEST_ROUTE、STARTUP_ROUTE、TIMER_ROUTE、EVENT_ROUTE


```c title="m_dump 使用示例"
...
m_dump();
m_dump($fu);
m_dump($fu, 10);
...
```


### 导出的统计信息


#### stored_messages


msilo存储的消息数。


#### dumped_messages


转储的消息数。


#### failed_messages


转储失败的消息数。


#### dumped_reminders


转储的提醒消息数。


#### failed_reminders


提醒消息发送失败数。


### 安装和运行


#### OpenSIPS配置文件


下图显示了msilo的示例用法。


[OpenSIPS配置文件 - msilo使用示例](./samples.md "include")
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即.md扩展名）均采用知识共享署名4.0许可证。
