---
title: "cpl_c 模块"
description: "cpl_c 模块实现了一个 CPL（Call Processing Language，呼叫处理语言）解释器。支持通过 SIP REGISTER 方法上传/下载/删除脚本。"
---

## 管理指南


### 概述


cpl_c 模块实现了一个 CPL（Call Processing Language，呼叫处理语言）
		解释器。支持通过 SIP REGISTER 方法上传/下载/删除脚本。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *任何 DB 模块 - 用于数据库操作的 DB 模块
				（如 mysql、postgres、dbtext 等）*
- *TM（Transaction，事务）模块 - 用于代理/分叉
				请求*
- *SL（StateLess，无状态）模块 - 用于在响应 REGISTER 请求时
				发送无状态回复，或发送错误响应*
- *USRLOC（User Location，用户位置）模块 - 用于实现
				lookup("registration") 标签（添加到用户的位置集中）*


#### 外部库或应用程序


以下库或应用程序必须在运行加载此模块的 OpenSIPS 之前安装：


- *libxml2 和 libxml2-devel - 在某些 SO 上，这两个
					包合并为 libxml2。该库包含用于 XML 解析、DTD 验证和
					DOM 操作的引擎。*


### 导出的参数


#### db_url (string)


需要为模块提供一个 SQL URL，用于指定存储 CPL 脚本的数据库
				位置。如需要，可以指定用户名和密码以允许
				模块连接到数据库服务器。


*默认值为 "mysql://opensips:opensipsrw@localhost/opensips"。*


```c title="设置 db_url 参数"
...
modparam("cpl_c","db_url","dbdriver://username:password@dbhost/dbname")
...
```


#### db_table (string)


指定存储 CPL 脚本的表名。
				该表必须位于 "db_url" 参数指定的数据库中。关于 CPL
				表的格式详情，请参阅 modules/cpl_c/init.mysql 文件。


*默认值为 "cpl"。*


```c title="设置 db_table 参数"
...
modparam("cpl_c","cpl_table","cpl")
...
```


#### username_column (string)


指定用于存储用户名的列名。


*默认值为 "username"。*


```c title="设置 username_column 参数"
...
modparam("cpl_c","username_column","username")
...
```


#### domain_column (string)


指定用于存储域名的列名。


*默认值为 "domain"。*


```c title="设置 domain_column 参数"
...
modparam("cpl_c","domain_column","domain")
...
```


#### cpl_xml_column (string)


指定用于存储
				CPL 脚本 XML 版本的列名。


*默认值为 "cpl_xml"。*


```c title="设置 cpl_xml_column 参数"
...
modparam("cpl_c","cpl_xml_column","cpl_xml")
...
```


#### cpl_bin_column (string)


指定用于存储
				CPL 脚本二进制版本（编译版本）的列名。


*默认值为 "cpl_bin"。*


```c title="设置 cpl_bin_column 参数"
...
modparam("cpl_c","cpl_bin_column","cpl_bin")
...
```


#### cpl_dtd_file (string)


指向描述 CPL 语法的 DTD 文件。文件名
				可以包含路径。该路径可以是
				绝对路径或相对路径（请注意，路径将相对于 OpenSIPS 的启动目录）。


*此参数是必需的！*


```c title="设置 cpl_dtd_file 参数"
...
modparam("cpl_c","cpl_dtd_file","/etc/opensips/cpl-06.dtd")
...
```


#### log_dir (string)


指向一个目录，用于创建由 LOG CPL 节点生成的所有日志文件。
				将为每个用户创建一个按需生成的日志文件，
				文件名为 username.log。


*如果此参数不存在，日志记录将被禁用，
					但不会在执行时产生错误。*


```c title="设置 log_dir 参数"
...
modparam("cpl_c","log_dir","/var/log/opensips/cpl")
...
```


#### proxy_recurse (int)


指定 PROXY CPL 节点允许递归的次数。
				如果值为 2，在进行代理时，代理操作只会被重试两次；
				第三次时，代理执行将通过进入重定向分支结束。
				可以通过将此参数设置为 0 来禁用递归功能。


*此参数的默认值为 0。*


```c title="设置 proxy_recurse 参数"
...
modparam("cpl_c","proxy_recurse",2)
...
```


#### proxy_route (string)


在进行代理（转发）之前，可以执行一个脚本路由。
				该路由所做的所有修改只会在当前分支上生效。


*此参数的默认值为 NULL（无）。*


```c title="设置 proxy_route 参数"
...
modparam("cpl_c","proxy_route", "1")
...
```


#### case_sensitive (int)


指定用户名匹配是否应该区分大小写。
				设置为非零值以强制执行区分大小写的用户名处理。


*此参数的默认值为 0。*


```c title="设置 case_sensitive 参数"
...
modparam("cpl_c","case_sensitive",1)
...
```


#### realm_prefix (string)


定义一个域名前缀，在处理用户和脚本时应忽略该前缀。


*此参数的默认值为空字符串。*


```c title="设置 realm_prefix 参数"
...
modparam("cpl_c","realm_prefix","sip.")
...
```


#### lookup_domain (string)


由 lookup 标签使用，用于指定执行用户位置查询的位置。
				这实际上是 usrloc 域（表）的名称，用于
				存储用户注册信息。


如果设置为空字符串，lookup 节点将被禁用 -
				不会执行用户位置查询。


*此参数的默认值为 NULL。*


```c title="设置 lookup_domain 参数"
...
modparam("cpl_c","lookup_domain","location")
...
```


#### lookup_append_branches (int)


指定 lookup 标签是否应该追加分支（进行并行
				分叉），如果 user_location 查询返回多个联系人。
				设置为非零值以启用位置查询标签的并行分叉。


*此参数的默认值为 0。*


```c title="设置 lookup_append_branches 参数"
...
modparam("cpl_c","lookup_append_branches",1)
...
```


#### use_domain (boolean)


指定是否应在用户标识中使用 URI 的域名部分
				（否则只使用用户名部分）。


*默认值为 *true*（启用）。*


```c title="设置 use_domain 参数"
...
modparam("cpl_c", "use_domain", true)
...
```


### 导出的函数


#### cpl_run_script(type,mode)


开始执行 CPL 脚本。用户名的获取顺序是：
				new_uri 或请求 URI 或 To 头 - 按此顺序
				（对于传入执行），或 FROM 头（对于
				传出执行）。
				关于有状态/无状态消息处理，该
				函数非常灵活，能够以不同模式运行（见下文 "mode" 参数）。
				通常此函数将结束脚本执行。不能保证当 OpenSIPS
				脚本结束时 CPL 脚本解释也结束（对于同一个 INVITE；-）
				- 这可能发生在 CPL 脚本执行 PROXY 且脚本在代理后暂停，
				并将在收到某些回复时恢复（这可能发生在 OpenSIPS 的不同进程中）。


如果函数返回 true 到脚本，如果返回值 "1"，
				SIP 服务器应继续正常行为，就像没有脚本存在一样；
				如果返回值为 (2)，表示未找到脚本，因此未执行任何操作。


当报告某些错误（返回 false）时，
				函数本身不会发送任何 SIP 错误回复（这可以从脚本中完成）。


参数的含义如下：


- *type (string)* - 指定应运行脚本的哪一部分；
				设置为 "incoming" 以执行脚本的传入部分（当收到 INVITE 时），
				或设置为 "outgoing" 以运行脚本的传出部分（当用户生成 INVITE 时 - 呼叫）。
- *mode (string)* - 设置解释器的无状态/有状态行为模式。接受的模式如下：

  - *IS_STATELESS* - 当前 INVITE 尚未
					创建事务。所有回复（重定向或拒绝）都将以无状态方式进行。
					只有在执行代理时才会切换到有状态模式。因此，
					如果函数返回，将处于无状态模式。
  - *IS_STATEFUL* - 当前 INVITE 已
					关联了一个事务。所有信令操作（回复或代理）
					都将以有状态方式进行。因此，如果
					函数返回，将处于有状态模式。
  - *FORCE_STATEFUL* - 当前 INVITE
					尚未创建事务。所有信令操作
					都将以有状态方式进行（在信令上，
					事务将从解释器内部创建）。因此，
					如果函数返回，将处于无状态模式。
*提示*：is_stateful 很难从路由脚本管理（脚本处理
				可以继续以有状态模式进行）；is_stateless 是最快的且资源消耗最少
				（事务仅在执行代理时创建），但对重传的保护最少
				（因为回复以无状态方式发送）；
				force_stateful 是一个很好的折衷方案 - 所有信令都以有状态方式进行
				（重传保护），同时，如果返回到脚本，
				将以无状态模式进行（便于继续路由脚本执行）。


此函数可用于 REQUEST_ROUTE。


```c title="cpl_run_script 用法"
...
cpl_run_script("incoming","force_stateful");
...
```


#### cpl_process_register()


此函数必须仅对 REGISTER 请求调用。它
				检查当前 REGISTER 请求是否与 CPL 脚本上传/下载/删除相关。
				如果是，将执行所有需要的操作。
				为了检查 REGISTER 是否与 CPL 相关，函数首先查看 "Content-Type" 头。
				如果存在且 mime 类型设置为 "application/cpl+xml"，
				则表示这是 CPL 脚本上传/删除操作。
				通过查看 "Content-Disposition" 头来区分这两种情况：
				如果其值为 "script;action=store"，表示上传；
				如果为 "script;action=remove"，表示删除操作；
				其他值被视为错误。
				如果没有 "Content-Type" 头，函数会查看 "Accept" 头，
				如果包含 "*" 或 "application/cpl-xml"，
				该请求将被视为下载 CPL 脚本的请求。
				只有当 REGISTER 与 CPL 无关时，函数才会返回到脚本。
				否则，函数将自行发送必要的回复（无状态 - 使用 sl），
				包括错误回复。


此函数可用于 REQUEST_ROUTE。


```c title="cpl_process_register 用法"
...
if ($rm=="REGISTER") {
    cpl_process_register();
}
...
```


#### cpl_process_register_norpl()


与 "cpl_process_register" 相同，但不
				内部生成回复。所有信息（脚本）都附加到回复中，
				但不会发送出去。


此函数的主要目的是允许通过相同的 REGISTER
				消息在 CPL 和 UserLocation 服务之间进行集成。


此函数可用于 REQUEST_ROUTE。


```c title="cpl_process_register_norpl 用法"
...
if ($rm=="REGISTER") {
    cpl_process_register();
    # 继续 usrloc 部分
    save("location");
}
...
```


### 导出的 MI 函数


#### cpl_c:load


替换过时的 MI 命令：*LOAD_CPL*。


对于给定用户，加载 XML cpl 文件，将其编译为
			二进制格式，并将两种格式都存储到数据库中。


名称：*cpl_c:load*


参数：


- username：用户名
- cpl_filename：文件名


MI FIFO 命令格式：


```c
                 opensips-cli -x mi cpl_c:load sip:bob@domain.com cpl_script.xml
```


#### cpl_c:remove


替换过时的 MI 命令：*REMOVE_CPL*。


对于给定用户，删除整个数据库记录
			（XML cpl 和二进制 cpl）；
			不允许空 CPL 脚本的用户存在。


名称：*cpl_c:remove*


参数：


- username：用户名


MI FIFO 命令格式：


```c
                 opensips-cli -x mi cpl_c:remove sip:bob@domain.com
```


#### cpl_c:get


替换过时的 MI 命令：*GET_CPL*。


对于给定用户，返回 XML 格式的 CPL 脚本。


名称：*cpl_c:get*


参数：


- username：用户名


MI FIFO 命令格式：


```c
                 opensips-cli -x mi cpl_c:get sip:bob@domain.com
```


### 安装和运行


#### 数据库设置


在运行带有 cpl_c 的 OpenSIPS 之前，
			必须设置模块将存储 CPL 脚本的数据库表。
			如果表未由安装脚本创建，或者您选择自己安装所有内容，
			可以使用 opensips/scripts 文件夹中数据库目录下的
			cpc-create.sql SQL 脚本作为模板。
			数据库和表名可以通过模块参数设置，因此可以更改，
			但列名必须与 SQL 脚本中的名称相同。
			您还可以在项目网页上找到完整的数据库文档：
			[https://opensips.org/docs/db/db-schema-devel.html](https://opensips.org/docs/db/db-schema-devel.html)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享署名 4.0 国际许可协议。
