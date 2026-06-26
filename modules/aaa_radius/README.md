---
title: "AAA RADIUS 模块"
description: "此模块为核心中的 AAA API 提供 Radius 实现。"
---

## 管理指南


### 概述


此模块为核心中的 AAA API 提供 Radius 实现。


它还提供两个函数，可从脚本用于生成自定义 Radius acct 和 auth 请求。
		Radius 回复中的 SIP-AVP 检测和处理由模块自动透明地完成。


自版本 2.2 起，aaa_radius 模块支持异步操作。
		但要使用它们，必须应用位于 modules/aaa_radius 文件夹中的
		名为 *radius_async_support.patch* 的补丁。
        为此，您必须拥有 freeradius-client 源代码。
        为此，您可以按照文档末尾的教程进行操作。


任何希望使用它的模块必须执行以下操作：


- *include aaa.h*
- *使用适当的 radius 特定 URL 进行绑定调用*


### 依赖


#### OpenSIPS 模块


无。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前必须安装
		以下库之一：


- *radiusclient-ng* 0.5.0 或更高版本
				参见 [http://developer.berlios.de/projects/radiusclient-ng/](http://developer.berlios.de/projects/radiusclient-ng/)。
- *freeradius-client*
				参见 [http://freeradius.org/](http://freeradius.org/)。


可以通过在编译模块之前设置 RADIUSCLIENT 环境来强制使用某个 radius 库：


- *RADCLI **** 应使用 libradcli-dev 库；
- *FREERADIUS **** 应使用 libfreeradius-client-dev 库；
- *RADIUSCLIENT **** 应使用 libradiusclient-ng 库；


重要提示：如果未安装选定的库，模块将无法编译。
				注意：如果未设置 RADIUSCLIENT 环境，模块将按以下顺序尝试查找三个 radius 库：
                radcli、freeradius、radiusclient-ng。
                也就是说，如果安装了 radcli 库，则使用它，
                否则查找 freeradius，依此类推。


### 导出的参数


#### sets (字符串)


构建自定义 RADIUS 请求（输入 RADIUS AVP 集）
			或从 RADIUS 回复获取数据（输出 RADIUS AVP 集）时要使用的 RADIUS AVP 集。


集合定义的格式如下：


- " set_name = ( attribute_name1 = var1 [, attribute_name2 = var2 ]* ) "


赋值的左侧必须是 RADIUS 字典知道的属性名称。


赋值的右侧必须是脚本伪变量或脚本 AVP。
			有关它们的更多信息，请参阅 [CookBooks - Scripting Variables](https://opensips.org/Resources/DocsCoreVar15)。


```c title="设置 sets 参数"
...
modparam("aaa_radius","sets","set4  =  (  Sip-User-ID  =   $avp(10)
			,   Sip-From-Tag=$si,Sip-To-Tag=$tt      )      ")
...

...
modparam("aaa_radius","sets","set1 = (User-Name=$var(usr), Sip-Group = $var(grp),
			Service-Type = $var(type)) ")
...

...
modparam("aaa_radius","sets","set2 = (Sip-Group = $var(sipgrup)) ")
...
```


#### radius_config (字符串)


Radiusclient 配置文件。


此参数是可选的。
			仅当使用 radius_send_acct 和 radius_send_auth 函数时才需要设置。


```c title="设置 radius_config 参数"
...
modparam("aaa_radius", "radius_config", "/etc/radiusclient-ng/radiusclient.conf")
...
```


#### syslog_name (字符串)


启用将客户端库记录到 syslog，使用给定的日志名称。


此参数是可选的。Radius 客户端库会尝试使用 syslog
		报告错误（如字典问题），并使用给定的身份字符串。
        如果设置此参数，这些错误将在 syslog 中可见。
        否则，错误将被隐藏。


默认情况下此参数未设置（无日志记录）。


```c title="设置 syslog_name 参数"
...
modparam("aaa_radius", "syslog_name", "aaa-radius")
...
```


#### fetch_all_values (整数)


对于输出集，此参数控制是否应返回所有值（对于相同的
		RADIUS AVP）（否则只返回第一个值）。
        启用此选项时，请确保您使用的 RADIUS 输出变量
        可以存储多个值（如 AVP 变量）。


出于向后兼容的原因，此参数默认禁用（设置为 0）。


```c title="设置 fetch_all_values 参数"
...
modparam("aaa_radius", "fetch_all_values", 1)
...
```


### 导出的函数


#### radius_send_auth(input_set_name, output_set_name)


此函数可用于从脚本发起自定义
			radius 认证请求。该函数接受两个参数。


参数：


- *input_set_name* (字符串) - 包含将
				构成认证请求的属性和 pvar 列表的集合的名称
                （请参阅 "sets" 模块参数）。
- *output_set_name* (字符串) - 包含将
				从认证回复中提取的属性和 pvar 列表的集合的名称
                （请参阅 "sets" 模块参数）。


这些集合必须使用 "sets" 导出参数定义。


函数在认证成功时返回 TRUE（返回码 1），
			在认证过程中发生任何种类的错误时返回 FALSE（返回码 -1），
            或者在 RADIUS 服务器拒绝或否认认证时返回 FALSE（返回码 -2）。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、ERROR_ROUTE 和 LOCAL_ROUTE。


```c title="radius_send_auth 使用"
...
radius_send_auth("set1","set2");
switch ($rc) {
	case 1:
		xlog("认证成功 \n");
		break;
	case -1:
		xlog("认证过程中出错\n");
		break;
	case -2:
		xlog("认证被拒绝 \n");
		break;
}
...


			
```


#### radius_send_acct(input_set_name)


此函数可用于从脚本发起自定义
			radius 认证请求。该函数只接受一个字符串参数，
            该参数表示包含将构成 accounting 请求的属性和 pvar 列表的集合的名称。


只需要一个集合作为参数，因为无法从 accounting 回复中提取 AVP。


该集合必须使用 "sets" 导出参数定义。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、ERROR_ROUTE 和 LOCAL_ROUTE。


```c title="radius_send_acct 使用"
...
radius_send_acct("set1");
...

			
```


### 导出的异步函数


#### radius_send_auth(input_set_name, output_set_name)


此函数可用于从脚本发起自定义
			radius 认证请求。


参数：


- *input_set_name* (字符串) - 包含将
				构成认证请求的属性和 pvar 列表的集合的名称
                （请参阅 "sets" 模块参数）。
- *output_set_name* (字符串) - 包含将
				从认证回复中提取的属性和 pvar 列表的集合的名称
                （请参阅 "sets" 模块参数）。


这些集合必须使用 "sets" 导出参数定义。


函数在认证成功时返回 TRUE（返回码 1），
			在认证过程中发生任何种类的错误时返回 FALSE（返回码 -1），
            或者在 RADIUS 服务器拒绝或否认认证时返回 FALSE（返回码 -2）。


```c title="radius_send_auth 使用"
...
{
async( radius_send_auth("set1","set2"), resume);
}

route[resume] {
switch ($rc) {
	case 1:
		xlog("认证成功 \n");
		break;
	case -1:
		xlog("认证过程中出错\n");
		break;
	case -2:
		xlog("认证被拒绝 \n");
		break;
}
...

			
```


#### radius_send_acct(input_set_name)


此函数可用于从脚本发起自定义
			radius 认证请求。该函数只接受一个字符串参数，
            该参数表示包含将构成 accounting 请求的属性和 pvar 列表的集合的名称。


只需要一个集合作为参数，因为无法从 accounting 回复中提取 AVP。


该集合必须使用 "sets" 导出参数定义。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、ERROR_ROUTE 和 LOCAL_ROUTE。


```c title="radius_send_acct 使用"
...
{
async( radius_send_acct("set1","set2"), resume);
}

route[resume] {
xlog(" accounting 完成\n");
}

...

			
```


## 使用 radius 异步


### 下载 radius-client 库


您可以从
			[这里](ftp://ftp.freeradius.org/pub/freeradius/freeradius-client-1.1.7.tar.gz)
			下载最新的 freeRADIUS Client Library 源代码。
			所以第一步是将其下载到您想要的任何文件夹中。
			在这个例子中，我们将把这个文件夹一般地称为
			*freeRADIUS-client*。下载源代码后，
			解压存档的内容。


```c title="下载库"
........
mkdir freeRADIUS-client; cd freeRADIUS-client
wget ftp://ftp.freeradius.org/pub/freeradius/freeradius-client-1.1.7.tar.gz
tar -xzvf freeradius-client-1.1.7.tar.gz
........
			
```


### 应用补丁


解压存档内容后，
			您可以应用位于 OpenSIPS 源文件夹中
			*modules/aaa_radius/* 内的名为 *radius_async_support.patch* 的补丁。
			您必须将此补丁应用到 freeRADIUS-client 库，
            然后按照通常的方式使用 configure 和 make 命令安装 radius 库，
            然后可以自由使用该库。


```c title="如何应用补丁"
........
cd freeRADIUS-client/freeradius-client-1.1.7.tar.gz
patch -p1 < /path/to/opensips/modules/aaa_radius/radius_async_support.patch
./configure --any-options-you-want
make
sudo make install
........
			
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
