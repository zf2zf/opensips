---
title: "快速拨号模块"
description: "此模块提供服务器端快速拨号功能。用户可以将由短号码（2位数字）和 SIP 地址组成的记录存储到 OpenSIPS 的表中。然后，他可以在想要呼叫关联的 SIP 地址时拨打这两位数字。"
---

## 管理指南

### 概述

此模块提供服务器端快速拨号功能。用户可以将由短号码（2位数字）和 SIP 地址组成的记录存储到 OpenSIPS 的表中。然后，他可以在想要呼叫关联的 SIP 地址时拨打这两位数字。

### 依赖

#### OpenSIPS 模块

以下模块必须在此模块之前加载：

- *数据库模块（mysql、dbtext 等）*

#### 外部库或应用程序

运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：

- *无*

### 导出的参数

#### db_url (string)

包含快速拨号记录的数据库 URL。

*默认值为 mysql://opensipsro:opensipsro@localhost/opensips*

```c title="设置 db_url 参数"
...
modparam("speeddial", "db_url", "mysql://user:xxx@localhost/db_name")
...
```

#### user_column (string)

存储快速拨号记录所有者用户名的列名。

*默认值为 "username"*

```c title="设置 user_column 参数"
...
modparam("speeddial", "user_column", "userid")
...
```

#### domain_column (string)

存储快速拨号记录所有者域名的列名。

*默认值为 "domain"*

```c title="设置 domain_column 参数"
...
modparam("speeddial", "domain_column", "userdomain")
...
```

#### sd_user_column (string)

存储短拨号地址用户部分的列名。

*默认值为 "sd_username"*

```c title="设置 sd_user_column 参数"
...
modparam("speeddial", "sd_user_column", "short_user")
...
```

#### sd_domain_column (string)

存储短拨号地址域名的列名。

*默认值为 "sd_domain"*

```c title="设置 sd_domain_column 参数"
...
modparam("speeddial", "sd_domain_column", "short_domain")
...
```

#### new_uri_column (string)

包含将用于替换短拨号 URI 的 URI 的列名。

*默认值为 "new_uri"*

```c title="设置 new_uri_column 参数"
...
modparam("speeddial", "new_uri_column", "real_uri")
...
```

#### domain_prefix (string)

如果所有者域名（From URI）以此参数的值开头，则在执行短号码查找之前会将其剥离。

*默认值为 NULL*

```c title="设置 domain_prefix 参数"
...
modparam("speeddial", "domain_prefix", "tel.")
...
```

#### use_domain (int)

该参数指定搜索快速拨号记录时是否使用域名（0 - 不使用域名，1 - 使用 From URI 中的域名，2 - 同时使用 From URI 和请求 URI 中的域名）。

*默认值为 0*

```c title="设置 use_domain 参数"
...
modparam("speeddial", "use_domain", 1)
...
```

### 导出的函数

#### sd_lookup(table [, owner])

该函数从"表"中的 R-URI 查找短拨号号码，并用关联的地址替换 R-URI。

参数的含义如下：

- *table* (string) - 存储快速拨号记录的表名。
- *owner* (string) - 短拨号代码所有者的 SIP URI。如果不存在，则使用 From 头的 URI。

此函数可以从 REQUEST_ROUTE 使用。

```c title="sd_lookup 用法"
...
# 'speed_dial' 是 opensips db 脚本创建的默认表名
if($ru=~"sip:[0-9]{2}@.*")
	sd_lookup("speed_dial");
# 使用认证用户名
if($ru=~"sip:[0-9]{2}@.*")
	sd_lookup("speed_dial", "sip:$au@$fd");
...
```

### 安装和运行

#### OpenSIPS 配置文件

下一张图片显示 speeddial 的示例用法。

[OpenSIPS 配置文件 - speeddial 用法示例](./samples.md "include")
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
