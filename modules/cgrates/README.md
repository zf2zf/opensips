---
title: "CGRateS 模块"
description: "[*CGRateS*](http://www.cgrates.org/) 是一个开源的计费引擎，用于运营商级的多租户实时计费。它能够对具有不同余额单位（如货币、短信、网络流量）的多个并发会话进行后付费和预付费计费。CGRateS 还可以..."
---

## 管理指南


### 概述


[*CGRateS*](http://www.cgrates.org/)
		是一个开源的计费引擎，用于运营商级的多租户实时计费。
		它能够对具有不同余额单位（如货币、短信、网络流量）的
		多个并发会话进行后付费和预付费计费。
		CGRateS 还能以多种格式导出精确的 CDR。


此模块可用于与 CGRateS 引擎通信，
		以进行呼叫授权和计费。OpenSIPS 模块本身不进行任何计费，
		而是提供与 CGRateS 引擎通信的接口，
		使用高效的 [JSON-RPC](http://json-rpc.org/)
		API，支持同步和异步方式。
		对于每个命令，用户可以提供一组参数，
		这些参数将通过 *$cgr()* 伪变量转发到 CGRateS 引擎。
		您可以在以下部分找到使用示例。


该模块还支持多个并行计费会话到 CGRateS。
		这在涉及复杂计费逻辑的场景中很有用，
		例如双重计费（客户和运营商计费）
		或多段呼叫（串行/并行分叉）。
		每个计费会话都是独立的，
		具有一个特定的 *tag*，
		可在整个呼叫生命周期内使用。


该模块可用于实现以下功能：


### 授权


授权用于检查账户是否允许开始新的呼叫，
		以及是否有足够的信用呼叫该目的地。
		这是使用 *cgrates_auth()* 命令完成的，
		它返回呼叫允许运行的秒数，
		存储在 *$cgr_ret* 伪变量中。


使用示例：


```c
		...
		if (cgrates_auth("$fU", "$rU"))
			xlog("呼叫允许运行 $cgr_ret 秒\n");
		}
		...
			
```


### 计费


计费模式用于启动和停止 CGRateS 会话。
		可用于预付费和后付费计费。
		*cgrates_acc()* 函数在呼叫被应答时
		（收到 200 OK 消息时）启动 CGRateS 会话，
		并在呼叫结束时（收到 BYE 消息时）结束会话。
		这是使用 *dialog* 模块自动完成的。


请注意，在开始计费之前，首先授权呼叫是很重要的
		（使用 *cgrates_auth()* 命令）。
		如果不这样做且用户未被授权呼叫，
		对话将立即关闭，导致持续时间为 0 的呼叫。
		如果呼叫被允许继续，对话生命周期将被设置为
		CGRateS 引擎指示的持续时间。
		因此，如果呼叫本应更长，对话将自动结束。


呼叫结束后（通过 BYE 消息），
		CGRateS 会话也会结束。
		此时，您可以生成 CDR。
		为此，您需要将 *cdr* 标志设置为
		*cgrates_acc()* 命令。
		通过使用 *missed* 标志，
		也可以为未接呼叫生成 CDR。


使用示例：


```c
		...
		if (!cgrates_auth("$fU", "$rU")) {
			sl_send_reply(403, "Forbidden");
			exit;
		}
		xlog("呼叫允许运行 $cgr_ret 秒\n");
		# 为此呼叫进行计费
		cgrates_acc("cdr", "$fU", "$rU");
		...
			
```


请注意，当使用 *cdr* 标志时，
		CDR 由 CGRateS 引擎以各种格式导出，
		不是由 OpenSIPS 导出。
		有关更多信息，请查阅 CGRateS 文档。


### 其他命令


您可以使用 *cgrates_cmd()* 向
		CGRateS 引擎发送任意命令，
		并使用 *$cgr_ret* 伪变量检索响应。


以下示例模拟了 *cgrates_auth()* CGRateS 调用：


```c
		...
		$cgr_opt(Tenant) = $fd; # 或在兼容模式下 $cgr(Tenant) = $fd;
		$cgr(Account) = $fU;
		$cgr(OriginID) = $ci;
		$cgr(SetupTime) = "" + $Ts;
		$cgr(RequestType) = "*prepaid";
		$cgr(Destination) = $rU;
		cgrates_cmd("SessionSv1.AuthorizeEvent");
		xlog("呼叫允许运行 $cgr_ret(MaxUsage) 秒\n");
		...
			
```


### CGRateS 故障转移


可以配置多个 CGRateS 引擎以故障转移方式使用：
		如果一个引擎宕机，则使用下一个引擎。
		目前服务器之间没有负载均衡逻辑，
		但这是 CGRateS 组件从新版本开始提供的功能。


每个 CGRateS 引擎最多分配
		*max_async_connections* 个连接，
		加一个用于同步命令的连接。
		如果连接失败（由于网络问题或服务器问题），
		它将被标记为关闭，并尝试新的连接。
		如果到该引擎的所有连接都宕机，
		则整个引擎被标记为禁用，并查询另一个引擎。
		如果引擎宕机超过 *retry_timeout*
		秒，OpenSIPS 会再次尝试连接到该服务器。
		如果成功，该服务器将被启用。
		否则，将使用其他引擎，直到没有可用的引擎，命令失败。


### CGRateS 兼容性


该模块支持两个不同版本的 CGRateS：
		*compat_mode* 版本（适用于 rc8 之前的版本），
		和新版本（适用于 rc8 之后的版本）。
		两个版本之间的区别在于
		向/从 CGRateS 构建请求和响应的方式。
		在非 *compat_mode*/新版本中，
		提供了一个新变量 *$cgr_opt()*，
		可用于调整请求选项。
		在 *compat_mode* 模式下不应使用此变量以避免歧义，
		但如果使用，它的行为与 *$cgr()* 完全相同。
		默认情况下，*compat_mode* 是禁用的。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *dialog* -- 如果使用 CGRateS
				计费。


#### 外部库或应用程序


以下库或应用程序必须在运行加载此模块的 OpenSIPS 之前安装：


- *libjson*


### 导出的参数


#### cgrates_engine (string)


此参数用于指定 CGRateS 引擎连接。
			格式为 *IP[:port]*。端口是可选的，
			如果缺失，则使用 *2014*。


此参数可以有多个值，
			用于故障转移的每个服务器。
			应至少配置一个服务器。


*默认值为 "None"。*


```c title="设置 cgrates_engine 参数"
...
modparam("cgrates", "cgrates_engine", "127.0.0.1")
modparam("cgrates", "cgrates_engine", "127.0.0.1:2013")
...
```


#### bind_ip (string)


IP 用于绑定与 CGRateS 引擎通信的套接字。
			当引擎在本地、安全的 LAN 中运行时，
			使用此设置很有用，
			您希望使用该网络与服务器通信。
			此参数是可选的。


*默认值为 "未设置 - 使用任何 IP"。*


```c title="设置 bind_ip 参数"
...
modparam("cgrates", "bind_ip", "10.0.0.100")
...
```


#### max_async_connections (integer)


到 CGRateS 引擎的最大异步并发连接数。


*默认值为 "10"。*


```c title="设置 max_async_connections 参数"
...
modparam("cgrates", "max_async_connections", 20)
...
```


#### retry_timeout (integer)


禁用连接/引擎重试的秒数。


*默认值为 "60"。*


```c title="设置 retry_timeout 参数"
...
modparam("cgrates", "retry_timeout", 120)
...
```


#### compat_mode (integer)


指示 OpenSIPS 是否应使用旧版本（compat_mode）
			CGRateS API（pre-rc8）。


*默认值为 "false (0)"。*


```c title="设置 compat_mode 参数"
...
modparam("cgrates", "compat_mode", 1)
...
```


### 导出的函数


#### cgrates_acc([flags[, account[, destination[, session]]]])


`cgrates_acc()` 为当前对话启动
			CGRateS 引擎上的计费会话。
			当对话结束时，它也会结束会话。
			此函数需要一个对话，
			因此如果之前未使用 create_dialog()，
			它将在内部调用该函数。


请注意，`cgrates_acc()` 函数
			在调用时不会向 CGRateS 引擎发送任何消息，
			而只是在呼叫被应答且应启动 CGRateS 会话时
			（收到 200 OK 消息时）发送。


当在 *REQUEST_ROUTE* 或
			*FAILURE_ROUTE* 中调用时，
			会计费所有创建的分支。
			当在 *BRANCH_ROUTE*
			或 *ONREPLY_ROUTE* 中调用时，
			仅当该分支成功（以 2xx 响应码终止）时才会进行计费。


`cgrates_acc()` 函数应
			仅在初始 INVITE 上调用。
			更多信息请查看[计费](#accounting)。


参数的含义如下：


- *flags*（string，可选）- 指示 OpenSIPS
				是否应在呼叫结束时生成 CDR。
				如果参数缺失，不会生成 CDR - 会话仅通过 CGRateS。
				可以使用以下值，用 '|' 分隔：

  - *cdr* - 还要生成 CDR；
  - *missed* - 即使对于未接呼叫也生成 CDR；
					此标志仅在使用了 *cdr* 标志时有意义；
- *account*（string，可选）- 将在 CGRateS 中被计费的账户。
				如果未指定，则使用 From 头中的用户。
- *destination*（string，可选）- 被拨打的号码。
			如果不存在，则使用请求 URI 用户。
- *session*（string，可选）- 如果分支/呼叫成功完成，
				将启动的会话的标签。
				此参数指示应考虑来自 *$cgr()* 变量的哪组数据。
				如果缺失，则使用默认集。


函数可以返回以下值：


- *1* - 成功呼叫 - CGRateS 计费
				已成功为呼叫设置。
- *-1* - OpenSIPS 返回内部错误
				（即无法创建对话，或服务器内存不足）。
- *-2* - SIP 消息无效：
				要么缺少头部，要么不是初始 INVITE。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、
			BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="cgrates_acc() 用法"
		...
		if (!has_totag()) {
			...
			if (cgrates_auth($fU, $rU))
				cgrates_acc("cdr|missed", $fU, $rU);
			...
		}
		...
		
```


#### cgrates_auth([account[, destination[, session]]])


`cgrates_auth()` 通过使用
			CGRateS 引擎进行呼叫授权。


参数的含义如下：


- *account*（string，可选）- 将在 CGRateS 中被检查的账户。
				如果未指定，则使用 From 头中的用户。
- *destination*（string，可选）- 被拨打的号码。
			如果不存在，则使用请求 URI 用户。
- *session*（string，可选）- 如果分支/呼叫成功完成，
				将启动的会话的标签。
				此参数指示应考虑来自 *$cgr()* 变量的哪组数据。
				如果缺失，则使用默认集。


函数可以返回以下值：


- *1* - 成功呼叫 - CGRateS 账户
				被允许进行呼叫。
- *-1* - OpenSIPS 返回内部错误
				（即服务器内存不足）。
- *-2* - CGRateS 引擎返回错误。
- *-3* - 未找到合适的 CGRateS 服务器。
				消息类型（不是初始 INVITE）。
- *-4* - SIP 消息无效：
				要么缺少头部，要么不是初始 INVITE。
- *-5* - CGRateS 返回无效消息。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、
			BRANCH_ROUTE 和 LOCAL_ROUTE。


```c title="cgrates_auth() 用法"
		...
		if (!has_totag()) {
			...
			if (!cgrates_auth($fU, $rU)) {
				sl_send_reply(403, "Forbidden");
				exit;
			}
			...
		}
		...
		
```


```c title="带属性解析的 cgrates_auth() 用法"
		...
		if (!has_totag()) {
			...
			$cgr_opt(GetAttributes) = 1;
			if (!cgrates_auth($fU, $rU)) {
				sl_send_reply(403, "Forbidden");
				exit;
			}
			# 将属性从 AttributesDigest 变量移动到普通 AVP
			$var(idx) = 0;
			while ($(cgr_ret(AttributesDigest){s.select,$var(idx),,}) != NULL) {
				$avp($(cgr_ret(AttributesDigest){s.select,$var(idx),,}{s.select,0,:}))
					= $(cgr_ret(AttributesDigest){s.select,$var(idx),,}{s.select,1,:});
				$var(idx) = $var(idx) + 1;
			}
			...
		}
		...
		
```


#### cgrates_cmd(command[, session])


`cgrates_cmd()` 可以向
			CGRateS 引擎发送任意命令。


参数的含义如下：


- *command*（string）- 发送到
				CGRateS 引擎的命令。
- *session*（string，可选）- 如果分支/呼叫成功完成，
				将启动的会话的标签。
				此参数指示应考虑来自 *$cgr()* 变量的哪组数据。
				如果缺失，则使用默认集。


函数可以返回以下值：


- *1* - 成功呼叫 - CGRateS 账户
				被允许进行呼叫。
- *-1* - OpenSIPS 返回内部错误
				（即服务器内存不足）。
- *-2* - CGRateS 引擎返回错误。
- *-3* - 未找到合适的 CGRateS 服务器。
				消息类型（不是初始 INVITE）。


此函数可用于任何路由。


```c title="cgrates_cmd() 用法"
		...
		# cgrates_auth($fU, $rU); 模拟
		$cgr_opt(Tenant) = $fd;
		$cgr(Account) = $fU;
		$cgr(OriginID) = $ci;
		$cgr(SetupTime) = "" + $Ts;
		$cgr(RequestType) = "*prepaid";
		$cgr(Destination) = $rU;
		cgrates_cmd("SessionSv1.AuthorizeEvent");
		xlog("呼叫允许运行 $cgr_ret 秒\n");
		...
		
```


### 导出的伪变量


#### $cgr(name) / $(cgr(name)[session])


伪变量，用于设置 CGRateS
				命令的不同参数。
				每个名称-值对将被编码为
				发送到 CGRateS 的 JSON 消息中的
				*string - value* 属性。


名称-值对存储在事务中（如果
				tm 模块已加载）。
				因此，值可以在回复中访问。


当调用 *cgrates_acc()* 函数时，
				所有名称-值对都被移动到对话中。
				因此，这些值可以在对话的整个生命周期内访问。


此变量由多组名称-值对组成。
				每组对应一个会话。
				变量可以用 *会话标签* 索引。
				各组之间完全独立。
				如果 *会话标签* 不存在，
				则使用默认的（无名称）组。


当使用 *:=* 运算符赋值时，
				值被视为 JSON，而不是字符串/整数。
				但是，JSON 的求值是延迟的，
				因此在构建 CGRateS 请求时，
				如果模块无法解析 JSON，
				则该值将作为字符串发送。


```c title="$cgr(name) 简单用法"
		...
		if (!has_totag()) {
			...
			$cgr_opt(Tenant) = $fd; # 将 From 域设置为租户
			$cgr(RequestType) = "*prepaid"; # 执行预付费计费
			$cgr(AttributeIDs) := '["+5551234"]'; # 作为数组处理
			if (!cgrates_auth("$fU", "$rU")) {
				sl_send_reply(403, "Forbidden");
				exit;
			}
		}
		...
		
```


```c title="$cgr(name) 多会话用法"
		...
		if (!has_totag()) {
			...
			# 第一个会话 - 授权用户
			$cgr_opt(Tenant) = $fd; # 将 From 域设置为租户
			$cgr(RequestType) = "*prepaid"; # 执行预付费计费
			if (!cgrates_auth("$fU", "$rU")) {
				sl_send_reply(403, "Forbidden");
				exit;
			}

			# 第二个会话 - 授权运营商
			$(cgr_opt(Tenant)[carrier]) = $td;
			$(cgr(RequestType)[carrier]) = "*postpaid";
			if (!cgrates_auth("$tU", "$fU", "carrier")) {
				# 使用不同的运营商
				return;
			}

			# 如果一切成功，在两者上开始计费
			cgrates_acc("cdr", "$fU", "rU");
			cgrates_acc("cdr", "$tU", "$fU", "carrier");
		}
		...
		
```


#### $cgr_opt(name) / $(cgr_opt(name)[session])


用于在非 *compat_mode* 模式下
				调整 CGRateS 请求的参数。


*注意：* 对于所有请求选项，
				整数值作为布尔值：
				*0* 禁用功能，
				*1*（或非零值）启用功能。
				字符串变量按原样传递。


撰写本文档时的可能值：


- *Tenant* - 调整 CGRateS 租户。
- *GetAttributes* - 从
						CGRateS 数据库请求账户属性。
- *GetMaxUsage* - 请求呼叫允许运行的最长时间。
- *GetSuppliers* - 请求可以终止该呼叫的所有供应商的数组。


```c title="$cgr_opt(name) 用法"
		...
		$cgr_opt(Tenant) = "cgrates.org";
		$cgr_opt(GetMaxUsage) = 1; # 同时检索最大使用量
		if (!cgrates_auth("$fU", "$rU")) {
			# 呼叫被拒绝
		}
		...
		
```


#### $cgr_ret(name)


在脚本中返回 CGRateS 命令的回复消息，
				或在非兼容模式下返回回复中的某个对象。


```c title="$cgr_ret(name) 用法"
		...
		cgrates_auth("$fU", "$rU");

		# 在兼容模式下
		xlog("呼叫允许运行 $cgr_ret 秒\n");

		# 在非兼容模式下
		xlog("呼叫允许运行 $cgr_ret(MaxUsage) 秒\n");
		...
		
```


### 导出的异步函数


#### cgrates_auth([account[, destination[, session]]])


以异步方式执行 CGRateS 授权调用。
			脚本执行将暂停，直到 CGRateS 引擎发送回复。


参数的含义如下：


- *account* - 将在 CGRateS 中被检查的账户。
				此参数是可选的，
				如果未指定，则使用 From 头中的用户。
- *destination* - 被拨打的号码。
				可选参数，如果不存在则使用请求 URI 用户。
- *session* - 如果分支/呼叫成功完成，
				将启动的会话的标签。
				此参数指示应考虑来自 *$cgr()* 变量的哪组数据。
				如果缺失，则使用默认集。


函数可以返回以下值：


- *1* - 成功呼叫 - CGRateS 账户
				被允许进行呼叫。
- *-1* - OpenSIPS 返回内部错误
				（即服务器内存不足）。
- *-2* - CGRateS 引擎返回错误。
- *-3* - 未找到合适的 CGRateS 服务器。
				消息类型（不是初始 INVITE）。
- *-4* - SIP 消息无效：
				要么缺少头部，要么不是初始 INVITE。
- *-5* - CGRateS 返回无效消息。


```c title="异步 cgrates_auth 用法"
route {
	...
	async(cgrates_auth("$fU", "$rU"), auth_reply);
}

route [auth_reply]
{
	if ($rc < 0) {
		xlog("呼叫未授权：代码=$cgr_ret!\n");
		send_reply(403, "Forbidden");
		exit;
	}
	...
}
```


#### cgrates_cmd(command[, session])


可以异步方式运行任意 CGRateS 命令。
			执行将暂停，直到 CGRateS 引擎发送回复。


参数的含义如下：


- *command* - 发送到
				CGRateS 引擎的命令。
				这是强制参数。
- *session* - 如果分支/呼叫成功完成，
				将启动的会话的标签。
				此参数指示应考虑来自 *$cgr()* 变量的哪组数据。
				如果缺失，则使用默认集。


函数可以返回以下值：


- *1* - 成功呼叫 - CGRateS 账户
				被允许进行呼叫。
- *-1* - OpenSIPS 返回内部错误
				（即服务器内存不足）。
- *-2* - CGRateS 引擎返回错误。
- *-3* - 未找到合适的 CGRateS 服务器。
				消息类型（不是初始 INVITE）。


```c title="异步 cgrates_cmd compat_mode 用法"
route {
	...
	$cgr(Tenant) = $fd;
	$cgr(Account) = $fU;
	$cgr(OriginID) = $ci;
	$cgr(SetupTime) = "" + $Ts;
	$cgr(RequestType) = "*prepaid";
	$cgr(Destination) = $rU;
	async(cgrates_cmd("SMGenericV1.GetMaxUsage"), auth_reply);
}

route [auth_reply]
{
	if ($rc < 0) {
		xlog("呼叫未授权：代码=$cgr_ret!\n");
		send_reply(403, "Forbidden");
		exit;
	}
	...
}
```


```c title="异步 cgrates_cmd 新用法"
route {
	...
	$cgr_opt(Tenant) = $fd;
	$cgr(Account) = $fU;
	$cgr(OriginID) = $ci;
	$cgr(SetupTime) = "" + $Ts;
	$cgr(RequestType) = "*prepaid";
	$cgr(Destination) = $rU;
	async(cgrates_cmd("SessionSv1.AuthorizeEventWithDigest"), auth_reply);
}

route [auth_reply]
{
	if ($rc < 0) {
		xlog("呼叫未授权：MaxUsage=$cgr_ret(MaxUsage)!\n");
		send_reply(403, "Forbidden");
		exit;
	}
	...
}
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享署名 4.0 国际许可协议。
