---
title: "AAA_DIAMETER 模块"
description: "此模块提供 RFC 6733 Diameter 对等实现，能够充当 Diameter 客户端或服务器，或两者兼而有之。"
---

## 管理指南


### 概述


此模块提供 RFC 6733 Diameter 对等实现，能够
		充当 **Diameter 客户端** 或 **服务器**，或**两者**。


任何希望使用它的模块必须执行以下操作：


- *include aaa.h*
- *使用适当的 Diameter 特定 URL 进行绑定调用，例如 "diameter:freeDiameter-client.conf"*


### Diameter 客户端


该模块实现了核心 AAA OpenSIPS 接口，
		因此提供了一种替代客户端实现，
        可替代 [aaa_radius](../aaa_radius) 模块，
        这在例如对实时 SIP 通话进行计费和 accounting 时非常有用。


除了 RADIUS 客户端的认证和 accounting 功能外，
		Diameter 客户端还包括发送*任意*
		Diameter 请求的支持，
        从而进一步扩展了可以通过 OpenSIPS 脚本实现的应用程序范围。
        此类 Diameter 请求可以使用 [dm send request](#func_dm_send_request) 函数发送。


### Diameter 服务器


从 OpenSIPS **3.5** 开始，
		Diameter 模块还包括*服务器端*支持。


首先，必须加载 [event_route](../event_route) 模块，
		以便能够在 OpenSIPS 配置文件中处理
        [dm request](#event_e_dm_request) 事件。
        这些事件将包含有关传入 Diameter 请求的所有必要信息。


最后，一旦处理了请求信息并准备了回复 AVP，
		脚本编写者应使用 [dm send answer](#func_dm_send_answer)
		函数来回复 Diameter 答案消息。


*建议：* 尽可能在您的 *freeDiameter.conf* 配置文件中
		始终加载 **dict_sip.fdx** freeDiameter 扩展模块，
		因为它包含数百个众所周知的 AVP 定义，
        在与其他 Diameter 对等实现进行互操作时可能会有用。


### 依赖


#### OpenSIPS 模块


无。


#### 外部库或应用程序


所有 Diameter 消息构建和解析，
		以及对等状态机和 Diameter 相关的网络通信，
        均由 [freeDiameter 项目](http://www.freediameter.net/trac/)
        和 C 库提供支持，动态链接到 "aaa_diameter" 模块。


运行加载了此模块的 OpenSIPS 之前必须安装
		以下库：


- *libfdcore* v1.2.1 或更高版本
- *libfdproto* v1.2.1 或更高版本


### 导出的参数


#### fd_log_level (整数)


此参数衡量 freeDiameter 库日志的*安静程度*。
		可能的值：


- 0 (ANNOYING)
- 1 (DEBUG)
- 3 (NOTICE，默认)
- 5 (ERROR)
- 6 (FATAL)


注意：由于 freeDiameter 输出到标准输出，
		在获取任何库日志之前，您还必须启用新的核心参数 **log_stdout**。


```c title="设置 fd_log_level 参数"
modparam("aaa_diameter", "fd_log_level", 0)
```


#### realm (字符串)


所有参与的 Diameter 对等使用的唯一领域。


默认值为 *"diameter.test"*。


```c title="设置 realm 参数"
modparam("aaa_diameter", "realm", "opensips.org")
```


#### peer_identity (字符串)


OpenSIPS Diameter 客户端对等将连接到的 Diameter 服务器对等的身份（领域子域）。


默认值为 *"server"*
				（即 "server.diameter.test"）。


```c title="设置 peer_identity 参数"
modparam("aaa_diameter", "peer_identity", "server")
```


#### aaa_url (字符串)


Diameter 客户端的 URL：配置文件，附带可选的
			extra-avps-file，用于配置 Diameter 客户端。


默认情况下，不创建连接。


```c title="设置 aaa_url 参数"
modparam("aaa_diameter", "aaa_url", "diameter:freeDiameter-client.conf")
```


```c title="设置 aaa_url 参数"
modparam("aaa_diameter", "aaa_url", "diameter:freeDiameter-client.conf;extra-avps-file:dictionary.opensips")
```


#### answer_timeout (整数)


以毫秒为单位的时间，超过该时间后，
		[d m send request](#func_dm_send_request)
		函数调用将在未收到回复时超时并返回 **-2** 代码。


默认值为 *2000* 毫秒。


```c title="设置 answer_timeout 参数"
modparam("aaa_diameter", "answer_timeout", 5000)
```


#### max_json_log_size (整数)


当由于格式错误的 JSON 打印错误日志时，
			此参数指示应在控制台打印 JSON 的多少个字符。
            更高的值可能会使日志过于拥挤，但可能对故障排除有用。


默认值为 *512* 个字符。


```c title="设置 max_json_log_size 参数"
modparam("aaa_diameter", "max_json_log_size", 4096)
```


### 导出的函数


#### dm_send_request(app_id, cmd_code, avps_json, [rpl_avps_pv])


执行到互连对等的阻塞 Diameter 请求，
		并从回复中返回 Result-Code AVP 值。


*参数*


- *app_id* (整数) - 应用程序的 ID。
				自定义应用程序必须在 dictionary.opensips
				Diameter 配置文件中定义，然后才能被识别。
- *cmd_code* (整数) - 命令的 ID。
				自定义命令代码、名称和 AVP 要求必须
				事先在 dictionary.opensips Diameter 配置文件中定义。
				HTTP 响应的正文。
- *avps_json* (字符串) - 包含要包含在消息中的 AVP 的 JSON 数组。
- *rpl_avps_pv* (var，可选) - 输出变量，
				将包含 Diameter Answer 中所有 AVP 名称及其值，
                打包为 JSON 数组字符串。
                可以使用 "json" 模块及其 *$json* 变量来迭代此数组。


*返回码*


- **1** - 成功
- **-1** - 内部错误
- **-2** - 请求超时
			（在处理答案之前超过了 [answer timeout](#param_answer_timeout)）


此函数可用于任何路由。


```c title="dictionary.opensips 扩展语法示例"
# 在 "dictionary.opensips" 文件中定义自定义 Diameter AVP、
# 应用程序、请求和回复的示例

ATTRIBUTE out_gw            232 string
ATTRIBUTE trunk_id          233 string

ATTRIBUTE rated_duration    234 integer
ATTRIBUTE call_cost         235 integer

ATTRIBUTE Exponent          429 integer32
ATTRIBUTE Value-Digits      447 integer64

ATTRIBUTE Cost-Unit 424 grouped
{
	Value-Digits | REQUIRED | 1
	Exponent | OPTIONAL | 1
}

ATTRIBUTE Currency-Code     425 unsigned32

ATTRIBUTE Unit-Value  445 grouped
{
	Value-Digits | REQUIRED | 1
	Exponent | OPTIONAL | 1
}

ATTRIBUTE Cost-Information  423 grouped
{
	Unit-Value | REQUIRED | 1
	Currency-Code | REQUIRED | 1
	Cost-Unit | OPTIONAL | 1
}

APPLICATION 42 My Diameter Application

REQUEST 92001 My-Custom-Request
{
	Origin-Host | REQUIRED | 1
	Origin-Realm | REQUIRED | 1
	Destination-Realm | REQUIRED | 1
	Sip-From-Tag | REQUIRED | 1
	Sip-To-Tag | REQUIRED | 1
	Sip-Call-Duration | REQUIRED | 1
	Sip-Call-Setuptime | REQUIRED | 1
	Sip-Call-Created | REQUIRED | 1
	Sip-Call-MSDuration | REQUIRED | 1
	out_gw | REQUIRED | 1
	call_cost | REQUIRED | 1
	Cost-Information | OPTIONAL | 1
}

ANSWER 92001 My-Custom-Answer
{
	Origin-Host | REQUIRED | 1
	Origin-Realm | REQUIRED | 1
	Destination-Realm | REQUIRED | 1
	Result-Code | REQUIRED | 1
}
```


```c title="dm_send_request 使用"
# 为 My Diameter Application (42) 构建并发送 My-Custom-Request (92001)
$var(payload) = "[
	{ \"Origin-Host\": \"client.diameter.test\" },
	{ \"Origin-Realm\": \"diameter.test\" },
	{ \"Destination-Realm\": \"diameter.test\" },
	{ \"Sip-From-Tag\": \"dc93-4fba-91db\" },
	{ \"Sip-To-Tag\": \"ae12-47d6-816a\" },
	{ \"Session-Id\": \"a59c-dff0d9efd167\" },
	{ \"Sip-Call-Duration\": 6 },
	{ \"Sip-Call-Setuptime\": 1 },
	{ \"Sip-Call-Created\": 1652372541 },
	{ \"Sip-Call-MSDuration\": 5850 },
	{ \"out_gw\": \"GW-774\" },
	{ \"call_cost\": 10 },
	{ \"Cost-Information\": [
		{\"Unit-Value\": [{\"Value-Digits\": 1000}]},
		{\"Currency-Code\": 35}
		]}
]";

$var(rc) = dm_send_request(42, 92001, $var(payload), $var(rpl_avps));
xlog("rc: $var(rc), AVPs: $var(rpl_avps)\n");
$json(avps) := $var(rpl_avps);
```


#### dm_send_answer(avps_json, [is_error])


以*非阻塞*方式向互连对等发送 Diameter 答案消息，
		以响应其请求。


构建答案消息时，以下字段将自动从 Diameter 请求中复制：


- Application ID
- Command Code
- Session-Id AVP（如果有）
- Transaction-Id AVP（如果有）（仅在 Session-Id 不存在时适用）


*参数*


- *avps_json* (字符串) - 包含要包含在答案消息中的 AVP 的 JSON 数组（见下文示例）。
- *is_error* (布尔值，默认：*false*)
				- 设置为 *true*
				以在答案消息中设置 'E'（错误）位。


*返回码*


- **1** - 成功
- **-1** - 内部错误


此函数只能从 *EVENT_ROUTE* 使用。


```c title="dm_send_answer() 使用"
event_route [E_DM_REQUEST] {
  xlog("Req: $param(sess_id) / $param(app_id) / $param(cmd_code)\n");
  xlog("AVPs: $param(avps_json)\n");

  $json(avps) := $param(avps_json);

  /* ... 处理数据（AVPs）... */

  /* ... 并回复更多 AVP！ */
  $var(ans_avps) = "[
          { \"Vendor-Specific-Application-Id\": [{
                  \"Vendor-Id\": 0
                  }] },

          { \"Result-Code\": 2001 },
          { \"Auth-Session-State\": 0 },
          { \"Origin-Host\": \"opensips.diameter.test\" },
          { \"Origin-Realm\": \"diameter.test\" }
  ]";

  if (!dm_send_answer($var(ans_avps)))
    xlog("错误 - 发送 Diameter 答案失败\n");
}
```


### 导出的异步函数


#### dm_send_request(app_id, cmd_code, avps_json, [rpl_avps_pv])


类似于 [dm send request](#func_dm_send_request)，
        但执行异步 Diameter 请求。


使用与
            [dm send request](#func_dm_send_request) 相同的参数和返回码。


```c title="dm_send_request 异步使用"
# 为 My Diameter Application (42) 构建并发送 My-Custom-Request (92001)
$var(payload) = "[
	{ \"Origin-Host\": \"client.diameter.test\" },
	{ \"Origin-Realm\": \"diameter.test\" },
	{ \"Destination-Realm\": \"diameter.test\" },
	{ \"Sip-From-Tag\": \"dc93-4fba-91db\" },
	{ \"Sip-To-Tag\": \"ae12-47d6-816a\" },
	{ \"Session-Id\": \"a59c-dff0d9efd167\" },
	{ \"Sip-Call-Duration\": 6 },
	{ \"Sip-Call-Setuptime\": 1 },
	{ \"Sip-Call-Created\": 1652372541 },
	{ \"Sip-Call-MSDuration\": 5850 },
	{ \"out_gw\": \"GW-774\" },
	{ \"call_cost\": 10 },
	{ \"Cost-Information\": [
		{\"Unit-Value\": [{\"Value-Digits\": 1000}]},
		{\"Currency-Code\": 35}
		]}
]";

async(dm_send_request(42, 92001, $var(payload), $var(rpl_avps), dm_reply);

route[dm_reply] {
	xlog("rc: $retcode, AVPs: $var(rpl_avps)\n");
	$json(avps) := $var(rpl_avps);
}
```


### 导出的事件


#### E_DM_REQUEST


每當加載了 *aaa_diameter*
		模塊且 OpenSIPS 在配置的 Diameter 監聽接口上收到 Diameter 請求時，
        都會引發此事件。


參數：


- *app_id (整數)* - Diameter 應用程序標識符
- *cmd_code (整數)* - Diameter 命令代碼
- *sess_id (字符串)* - Session-Id AVP、
					Transaction-Id AVP 的值，
                    或者如果這些事務標識 AVP 都不存在於 Diameter 請求中，
                    則為 *NULL* 值。
- *avps_json (字符串)* - 包含請求 AVP 的 JSON 數組。
                    使用 [json](../json) 模塊的 **$json** 變量
                    可以輕鬆解析和使用它。


請注意，此事件目前設計為主要通過 *event_route* 使用，
		因為這是訪問 [dm send answer](#func_dm_send_answer)
		函數以構建自定義答案消息的唯一方法。
        另一方面，如果應用程序不介意答案始終是 3001 (DIAMETER_COMMAND_UNSUPPORTED) 錯誤，
        則可以通過任何其他 EVI 兼容的傳遞通道成功使用此事件。
<!-- CONTRIBUTORS -->

### 許可證

所有文檔文件（即 .md 擴展名）均採用知識共享署名 4.0 國際許可協議授權。
