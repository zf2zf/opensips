---
title: "Launch Darkly 模块"
description: "此模块实现对 [Launch Darkly](https://launchdarkly.com/) 功能管理云的支持。该模块提供到云端的连接以及查询功能标志的能力。"
---

## 管理指南


### 概述


此模块实现对 [Launch Darkly](https://launchdarkly.com/)
		功能管理云的支持。该模块提供到云端的连接以及查询功能标志的能力。


OpenSIPS 使用 Launch Darkly 提供的 [服务器端 C/C++ SDK](https://launchdarkly.com/features/sdk/)。


### 依赖


#### OpenSIPS 模块


加载此模块之前必须加载以下模块：


- *无*。


#### 外部库或应用程序


运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- *ldserverapi*


*ldserverapi* 必须从官方
			[GITHUB 仓库](https://github.com/launchdarkly/c-server-sdk) 编译和安装。


库快速安装说明（注意必须编译为共享库才能与 OpenSIPS 模块兼容）：


```c
...
	$ git clone https://github.com/launchdarkly/c-server-sdk.git
	$ cd c-server-sdk
	$ cmake -DBUILD_SHARED_LIBS=On -DBUILD_TESTING=OFF .
	$ sudo make install
...
```


### 导出的参数


#### sdk_key (字符串)


用于连接到服务的 LaunchDarkly SDK 密钥。这是一个必需参数。


```c title="设置 sdk_key 参数"
...
modparam("launch_darkly", "sdk_key", "sdk-12345678-abcd-12ab-1234-0123456789abc")
...
```


#### ld_log_level (字符串)


由 LD SDK/库用于记录其内部消息的 LaunchDarkly 特定日志级别。
		请注意，这些由 LD 库产生的日志（根据此 ld_log_level）
		将根据整体 OpenSIPS log_level 进一步过滤。


可接受的值有
		*LD_LOG_FATAL*、
		*LD_LOG_CRITICAL*、
		*LD_LOG_ERROR*、
		*LD_LOG_WARNING*、
		*LD_LOG_INFO*、
		*LD_LOG_DEBUG*、
		*LD_LOG_TRACE*。


如果未设置或设置为不支持的值，
		默认使用 *LD_LOG_WARNING* 级别。


```c title="设置 log_level 参数"
...
modparam("launch_darkly", "ld_log_level", "LD_LOG_CRITICAL")
...
```


#### connect_wait (整数)


连接到 LD 服务时等待的时间（毫秒）。
		初次连接 LD 服务失败可以通过增加此等待值来解决。


默认值为 500 毫秒。


```c title="设置 connect_wait 参数"
...
modparam("launch_darkly", "connect_wait", 100)
...
```


#### re_init_interval (整数)


当模块在启动时无法初始化 LC 连接时，
		再次尝试初始化 LD 客户端的最小时间间隔（秒）。
		如果初始化失败，模块将在从脚本检查功能标志时自动重试，
		但不会早于 `re_init_interval`。
		请注意：如果没有要执行的功能标志检查，重试可能会晚于 `re_init_interval`。


默认值为 10 秒。


```c title="设置 re_init_interval 参数"
...
modparam("launch_darkly", "re_init_interval", 30)
...
```


### 导出的函数


#### ld_feature_enabled( flag, user, [user_extra], [fallback])


用于评估 LaunchDarkly 布尔功能标志的函数。


如果标志被确定为 TRUE 则返回 *1*，否则返回 *-1*。


发生错误时，将返回回退（TRUE 或 FALSE）值。
		在这种情况下，回退 TRUE 返回为 2，回退 FALSE 返回 -2，
		因此您可以区分真正的 TRUE（由 LD 服务返回）和因错误而返回的回退 TRUE。


此函数可用于任何路由。


函数具有以下参数：


- *flag* (字符串) - 要评估的标志的键。
					不能为 NULL 或空。
- *user* (字符串) - 要评估标志的用户。
					不能为 NULL 或空。
- *user_extra* (AVP，可选) - 一个 AVP，
					包含要附加到用户的一个或多个键值属性。
					AVP 值的格式为 "key=value"。
- *fallback* (整数，可选) - 错误时返回的值。
					默认返回 FALSE。


```c title="ld_feature_enabled() 函数用法"
	...
	$avp(extra) = "domainId=123456";
	if (ld_feature_enabled("my-flag","opensips", $avp(extra), false))
		xlog("-------TRUE\n");
	else
		xlog("-------FALSE\n");
	...
	
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议。
