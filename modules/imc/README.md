---
title: "IMC 模块"
description: "此模块提供即时消息会议支持。它遵循 IRC 频道的架构，您可以发送嵌入在 MESSAGE 主体中的命令，因为没有用于 IM 会议的 SIP UA 客户端 GUI。"
---

## 管理指南


### 概述


此模块提供即时消息会议支持。它
		遵循 IRC 频道的架构，您可以发送嵌入在
		MESSAGE 主体中的命令，因为没有用于 IM 会议的 SIP UA 客户端。


您需要定义一个与 IM 会议管理器对应的 URI，用户可以在其中发送命令来创建新的会议室。一旦会议室创建，用户可以直接向会议室的 URI 发送命令。


为了便于集成到配置文件中，IMC 命令的解释器嵌入在模块中，
		从配置的角度来看，对于消息和命令都只需要执行一个函数。


### 依赖


#### OpenSIPS 模块


加载此模块之前必须加载以下模块：


- *mysql*。
- *tm*。


#### 外部库或应用程序


运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### db_url (字符串)


数据库 URL。


*默认值为 "mysql://opensips:opensipsrw@localhost/opensips"*。


```c title="设置 db_url 参数"
...
modparam("imc", "db_url", "dbdriver://username:password@dbhost/dbname")
...
```


#### rooms_table (字符串)


存储 IMC 会议室的表名。


*默认值为 "imc_rooms"*。


```c title="设置 rooms_table 参数"
...
modparam("imc", "rooms_table", "rooms")
...
```


#### members_table (字符串)


存储 IMC 成员的表名。


*默认值为 "imc_members"*。


```c title="设置 members_table 参数"
...
modparam("imc", "rooms_table", "members")
...
```


#### hash_size (整数)


用于存储成员和会议室的哈希表大小，以 2 的幂次计算。


*默认值为 4（结果哈希大小为 16）*。


```c title="设置 hash_size 参数"
...
modparam("imc", "hash_size", 8)
...
```


#### imc_cmd_start_char (字符串)


指示消息主体是命令的字符。


*默认值为 "#"*。


```c title="设置 imc_cmd_start_char 参数"
...
modparam("imc", "imc_cmd_start_char", "#")
...
```


#### outbound_proxy (字符串)


发送消息时用作下一跳的 SIP 地址。当使用不在 DNS 中的域名的 OpenSIPS，或使用单独的 OpenSIPS 实例进行 imc 处理时非常有用。如果未设置，消息将发送到目标 URI 中的地址。


*默认值为 NULL。*


```c title="设置 outbound_proxy 参数"
...
modparam("imc", "outbound_proxy", "sip:opensips.org;transport=tcp")
...
```


### 导出的函数


#### imc_manager()


处理 Message 方法。它检测消息主体是否为会议命令。
		如果是，则执行它；否则，将消息发送到房间中的所有成员。


此函数可用于 REQUEST_ROUTE。


```c title="imc_manager() 函数用法"
...
# 会议室将命名为 chat-xyz 以避免与用户名重叠
if(is_method("MESSAGE)
        && ($ru=~ "sip:chat-[0-9]+@" || ($ru=~ "sip:chat-manager@")
    imc_manager();
...
```


### 导出的 MI 函数


#### imc:list_rooms


替换已弃用的 MI 命令：*imc_list_rooms*。


列出 IM 会议室。


名称：*imc:list_rooms*


参数：无


MI FIFO 命令格式：


```c
		opensips-cli -x mi imc:list_rooms
		
```


#### imc:list_members


替换已弃用的 MI 命令：*imc_list_members*。


列出 IM 会议室中的成员。


名称：*imc:list_members*


参数：


- *room*：您要列出成员的会议室


MI FIFO 命令格式：


```c
		opensips-cli -x mi imc:list_members sip:chat-000@opensips.org
		
```


### 导出的统计


#### active_rooms


活跃的 IM 会议室数量。


### IMC 命令


命令由起始字符标识。命令必须写在一行中。默认情况下，起始字符是 '#'。
		您可以通过 "imc_cmd_start_char" 参数更改它。


下图展示了命令及其参数列表。


```c title="命令列表"
...

1.create
  -创建一个会议室
  -需要 2 个参数：
     1) 会议室名称
     2)可选-"private" -如果存在，创建的会议室是私有的
	   新成员只能通过邀请添加
  -用户作为第一个成员和房间所有者添加
  -例如：#create chat-000 private

2.join
  -使用户成为房间的成员
  -需要一个可选参数 - 房间地址 -如果不存在
    将被视为消息 To 头中的地址
  -如果房间不存在，命令被视为 create
  -例如：join sip:chat-000@opensips.org,
      或仅发送 #join 到 sip:chat-000@opensips.org

3.invite
  -邀请用户成为房间成员
  -需要 2 个参数：
     1)用户的完整地址
     2)房间地址 -如果不存在，将被视为
	   消息 To 头中的地址
  -只有某些用户有权邀请其他用户：所有者和管理员
  -例如：#invite sip:john@opensips.org sip:chat-000@opensips.org
    或 #invite john@opensips.org 发送到 sip:chat-000@opensips.org

4.accept
  -接受邀请
  -需要一个可选参数 - 房间地址 - 如果不存在，
    将被视为消息 To 头中的地址
  -例如：#accept sip:john@opensips.org

5.deny
  -拒绝邀请
  -参数与 accept 相同

6.remove
  -从房间中删除成员
  -需要 2 个参数：
    1)成员的完整地址
    2)房间地址 -如果不存在，将被视为
	  消息 To 头中的地址
  -只有某些成员有权删除其他成员
  -例如：#remove sip:john@opensips.org，发送到 sip:chat-000@opensips.org

7.exit
  -离开房间
  -需要一个可选参数 - 房间地址 - 如果不存在，
    将被视为消息 To 头中的地址
  -如果用户是房间所有者，房间将被销毁

8.destroy
  -删除房间
  -参数与 exit 相同
  -只有房间所有者有权销毁它

9.list
  -列出房间中的成员

...
```


### 安装


在运行带有 IMC 的 OpenSIPS 之前，您必须设置模块将存储数据的数据库表。
		如果表不是由安装脚本创建的，或者您选择自己安装一切，
		可以使用 opensips/scripts 文件夹中数据库目录下的 imc-create.sql
		SQL 脚本作为模板。
		您还可以在项目网页上找到完整的数据库文档，
		[https://opensips.org/docs/db/db-schema-devel.html](https://opensips.org/docs/db/db-schema-devel.html)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议。
