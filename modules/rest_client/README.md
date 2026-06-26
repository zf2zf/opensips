---
title: "rest_client 模块"
description: "*rest_client* 模块提供了与 HTTP 服务器交互的方式，通过执行 RESTful 查询（如 GET、POST 和 PUT）来与 HTTP 服务器进行交互。"
---

## 管理指南

### 概述

*rest_client* 模块提供了与 HTTP 服务器交互的方式，通过执行 RESTful 查询（如 GET、POST 和 PUT）来与 HTTP 服务器进行交互。

### TCP 连接复用

除非服务器通过 "Connection: close" 明确指示，否则模块将尽可能保持和复用其创建的 TCP 连接，无论脚本编写者执行的是阻塞还是异步 HTTP 请求。这些连接不在 OpenSIPS 工作进程之间共享——每个工作进程维护自己的连接集。

### 依赖

#### OpenSIPS 模块

以下模块必须在此模块之前加载：

- *无其他 OpenSIPS 模块依赖。*

#### 外部库或应用程序

运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：

- *libcurl*。

### 导出的参数

#### curl_timeout (integer)

任何 HTTP(S) 传输完成所允许的最长时间。此时间间隔包括初始连接时间窗口，因此此参数的值必须大于或等于[连接超时](#param_connection_timeout)。

*默认值为 "20" 秒。*

```c title="设置 curl_timeout 参数"
...
modparam("rest_client", "curl_timeout", 10)
...
```

#### connection_timeout (integer)

与服务器建立连接所允许的最长时间。

*默认值为 "20" 秒。*

```c title="设置 connection_timeout 参数"
...
modparam("rest_client", "connection_timeout", 4)
...
```

#### connect_poll_interval (integer)

仅与异步请求相关。允许完全控制我们希望多快地检测 libcurl 完成的阻塞 TCP/TLS 握手，从而使异步传输可以在后台运行。较低的[连接轮询间隔](#param_connect_poll_interval)可能会加快所有异步 HTTP 传输，但也会增加 CPU 使用率。

*默认值为 "20" 毫秒。*

```c title="设置 connect_poll_interval 参数"
...
modparam("rest_client", "connect_poll_interval", 2)
...
```

#### max_async_transfers (integer)

单个 OpenSIPS 工作进程允许同时运行的最大异步 HTTP 传输数。只要某个工作进程的此阈值已达到，该工作进程尝试执行的所有新异步传输都将以阻塞方式进行，并附带适当的日志警告。

*默认值为 "100"。*

```c title="设置 max_async_transfers 参数"
...
modparam("rest_client", "max_async_transfers", 300)
...
```

#### max_transfer_size (integer)

单次传输（下载）所允许的最大大小。在传输过程中达到此限制将导致传输立即停止，在脚本级别返回错误 -10。值为 **0** 将禁用此检查。

*默认值为 "10240" (KB)。*

```c title="设置 max_transfer_size 参数"
...
modparam("rest_client", "max_transfer_size", 64)
...
```

#### ssl_verifypeer (integer)

设置为 0 以禁用对远程对等方证书的验证。验证使用随 libcurl 提供的默认 CA 证书包进行。

*默认值为 "1"（启用）。*

```c title="设置 ssl_verifypeer 参数"
...
modparam("rest_client", "ssl_verifypeer", 0)
...
```

#### ssl_verifyhost (integer)

设置为 0 以禁用对远程对等方实际对应于证书中列出的服务器的验证。

*默认值为 "1"（启用）。*

```c title="设置 ssl_verifyhost 参数"
...
modparam("rest_client", "ssl_verifyhost", 0)
...
```

#### ssl_capath (integer)

用于主机验证的 CA 证书的可选路径。

```c title="设置 ssl_capath 参数"
...
modparam("rest_client", "ssl_capath", "/home/opensips/ca_certificates")
...
```

#### curl_http_version (integer)

对所有请求使用特定的 HTTP 版本。可能的值：

- 0（默认）- 使用 libcurl 认为合适的版本
- 1 - 强制使用 HTTP 1.0 请求
- 2 - 强制使用 HTTP 1.1 请求
- 3 - 尝试 HTTP 2 请求。如果 HTTP 2 无法与服务器协商，则回退到 HTTP 1.1。需要 libcurl 7.33.0+。
- 4 - 仅通过 TLS（HTTPS）尝试 HTTP 2。如果 HTTP 2 无法与 HTTPS 服务器协商，则回退到 HTTP 1.1。对于明文 HTTP 服务器，请使用 HTTP 1.1。需要 libcurl 7.47.0+。
- 5 - 使用 HTTP 2 发送非 TLS HTTP 请求，无需 HTTP 1.1 升级。它需要预先知道服务器支持 HTTP 2。HTTPS 请求仍将以标准方式通过 TLS 握手中的协商协议版本进行 HTTP/2。需要 libcurl 7.49.0+。

*更多详情请参阅[此处](https://curl.haxx.se/libcurl/c/CURLOPT_HTTP_VERSION.html)，此设置的文档灵感来自此处*

```c title="设置 curl_http_version 参数"
...
modparam("rest_client", "curl_http_version", 3)
...
```

#### enable_expect_100 (boolean)

当 POST 或 PUT 请求的正文大小超过 1024 字节时，包含 "Expect: 100-continue" HTTP 头字段。启用后，等待服务器 "100 Continue" 回复的超时时间为 1 秒，之后开始上传正文。

*默认值为 "false"（禁用）。*

```c title="设置 enable_expect_100 参数"
...
modparam("rest_client", "enable_expect_100", true)
...
```

#### no_concurrent_connects (boolean)

设置为 *true* 以仅允许一个 OpenSIPS 工作进程一次连接到给定 URL 主机名。当一个工作进程正在连接时，所有其他工作进程在尝试对同一主机名执行任何 rest_client 操作时都将收到错误代码 **-4（正在连接）**，无论操作是同步还是异步。

对于同步传输，工作进程序列化的范围扩展到整个 cURL 传输（TCP 连接 + 上传 + 下载），因为所有三个阶段都在单个 cURL 库调用中进行。

此参数可用于防止因失败的（挂起的）HTTP 服务导致所有 OpenSIPS 工作进程并发阻塞而引起的系统中断，而没有更多空闲工作进程来处理传入的 SIP 数据包。

*默认值为 "false"（禁用）。*

```c title="设置 no_concurrent_connects 参数"
...
modparam("rest_client", "no_concurrent_connects", true)
...
```

#### curl_conn_lifetime (integer)

仅当[禁用并发连接](#param_no_concurrent_connects)启用时相关。通过设置此参数，脚本开发人员可以利用 libcURL 的连接复用功能，如果该工作进程已知已具有到目标 URL 主机名的 TCP 连接（通过之前的 rest_xxx() 函数调用建立），则可以完全跳过"无并发传输"逻辑。

该参数表示 TCP 连接在 libcURL 中保持复用的生命周期（以秒为单位），此设置通常取决于操作系统，也可能受启用/禁用 keepalives 的影响。有关 cURL TCP 连接最大生命周期的更多信息，请参阅您的操作系统和/或 libcurl 文档。

*默认值为 *0*（禁用）。*

```c title="设置 curl_conn_lifetime 参数"
...
modparam("rest_client", "curl_conn_lifetime", 1800)
...
```

### 导出的函数

#### rest_get(url, body_pv, [ctype_pv], [retcode_pv])

对给定的 *url* 执行阻塞 HTTP GET 并返回资源的表示。

参数：

- *url* (string)
- *body_pv* (var) - 输出变量，将包含 HTTP 响应的正文。
- *ctype_pv* (var，可选) - 输出变量，将包含响应 "Content-Type:" 头字段的值。
- *retcode_pv* (var，可选) - 输出变量，将保留 HTTP 响应的状态码。**0** 状态码值表示根本没有收到 HTTP 回复。

**返回码**

- **1** - 成功
- **-1** - 连接被拒绝。
- **-2** - 连接超时（TCP 连接建立之前超过了[连接超时](#param_connection_timeout)）
- **-3** - 传输超时（收到最后一个字节之前超过了[curl 超时](#param_curl_timeout)）。*retcode_pv* 可能被设置为 200 或 0，取决于是否收到 200 OK。如果是，*body_pv* 将包含部分下载的数据，风险自负！（我们建议您仅将此数据用于日志/调试目的）
- **-4** - 正在连接（另一个 OpenSIPS 工作进程正在连接此 URL 主机名。请参阅[无并发连接](#param_no_concurrent_connects)了解更多信息）。
- **-10** - 内部错误（内存不足、意外的 libcurl 错误等）

此函数可以从任何路由使用。

```c title="rest_get 用法"
...
# 查询 REST 服务获取账户信用的示例
$var(rc) = rest_get("https://getcredit.org/?account=$fU",
                    $var(credit),
                    $var(ct),
                    $var(rcode));
if ($var(rc) < 0) {
	xlog("rest_get() 失败，错误码 $var(rc)，账户=$fU\n");
	send_reply(500, "服务器内部错误");
	exit;
}

if ($var(rcode) != 200) {
	xlog("L_INFO", "rest_get() 响应码=$var(rcode)，账户=$fU\n");
	send_reply(403, "禁止访问");
	exit;
}
...
```

#### rest_post(url, send_body, [send_ctype], recv_body_pv, [recv_ctype_pv], [retcode_pv])

对给定的 *url* 执行阻塞 HTTP POST。

请注意，*send_body* 参数也可以接受格式字符串，但不能大于 1024 字节。对于较大的消息，您必须在伪变量中构建它们并传递给函数。

参数：

- *url* (string)
- *send_body* (string) - 请求正文。
- *send_ctype* (string，可选) - 请求的 MIME Content-Type 头。默认值为 *"application/x-www-form-urlencoded"*
- *recv_body_pv* (var) - 输出变量，将包含 HTTP 响应的正文。
- *recv_ctype_pv* (var，可选) - 输出变量，将包含响应 "Content-Type" 头的值
- *retcode_pv* (var，可选) - 输出变量，将保留 HTTP 响应的状态码。**0** 状态码值表示根本没有收到 HTTP 回复。

**返回码**

- **1** - 成功
- **-1** - 连接被拒绝。
- **-2** - 连接超时（TCP 连接建立之前超过了[连接超时](#param_connection_timeout)）
- **-3** - 传输超时（收到最后一个字节之前超过了[curl 超时](#param_curl_timeout)）。*retcode_pv* 可能被设置为 200 或 0，取决于是否收到 200 OK。如果是，*body_pv* 将包含部分下载的数据，风险自负！（我们建议您仅将此数据用于日志/调试目的）
- **-4** - 正在连接（另一个 OpenSIPS 工作进程正在连接此 URL 主机名。请参阅[无并发连接](#param_no_concurrent_connects)了解更多信息）。
- **-10** - 内部错误（内存不足、意外的 libcurl 错误等）

此函数可以从任何路由使用。

```c title="rest_post 用法"
...
# 使用 HTTP POST 请求通过 RESTful 服务创建资源
$var(rc) = rest_post("https://myserver.org/register_user",
                     $fU, , $var(body), $var(ct), $var(rcode));
if ($var(rc) < 0) {
	xlog("rest_post() 失败，错误码 $var(rc)，用户=$fU\n");
	send_reply(500, "服务器内部错误 1");
	exit;
}

if ($var(rcode) != 200) {
	xlog("rest_post() 响应码=$var(rcode)，用户=$fU\n");
	send_reply(500, "服务器内部错误 2");
	exit;
}
...
```

#### rest_put(url, send_body, [send_ctype], recv_body_pv[, [recv_ctype_pv][, [retcode_pv]]])

对给定的 *url* 执行阻塞 HTTP PUT。

与[rest post](#func_rest_post)类似，*send_body_pv* 参数也可以接受格式字符串，但不能大于 1024 字节。对于较大的消息，您必须在伪变量中构建它们并传递给函数。

参数：

- *url* (string)
- *send_body* (string) - 请求正文。
- *send_ctype* (string，可选) - 请求的 MIME Content-Type 头。默认值为 *"application/x-www-form-urlencoded"*
- *recv_body_pv* (var) - 输出变量，将包含 HTTP 响应的正文。
- *recv_ctype_pv* (var，可选) - 输出变量，将包含响应 "Content-Type" 头的值
- *retcode_pv* (var，可选) - 输出变量，将保留 HTTP 响应的状态码。**0** 状态码值表示根本没有收到 HTTP 回复。

**返回码**

- **1** - 成功
- **-1** - 连接被拒绝。
- **-2** - 连接超时（TCP 连接建立之前超过了[连接超时](#param_connection_timeout)）
- **-3** - 传输超时（收到最后一个字节之前超过了[curl 超时](#param_curl_timeout)）。*retcode_pv* 可能被设置为 200 或 0，取决于是否收到 200 OK。如果是，*body_pv* 将包含部分下载的数据，风险自负！（我们建议您仅将此数据用于日志/调试目的）
- **-4** - 正在连接（另一个 OpenSIPS 工作进程正在连接此 URL 主机名。请参阅[无并发连接](#param_no_concurrent_connects)了解更多信息）。
- **-10** - 内部错误（内存不足、意外的 libcurl 错误等）

此函数可以从任何路由使用。

```c title="rest_put 用法"
...
# 使用 HTTP PUT 请求通过 RESTful 服务创建/更新资源
$var(rc) = rest_put("https://myserver.org/users/$fU",
                    $var(userinfo), , $var(body), $var(ct), $var(rcode));
if ($var(rc) < 0) {
	xlog("rest_put() 失败，错误码 $var(rc)，用户=$fU\n");
	send_reply(500, "服务器内部错误 3");
	exit;
}

if ($var(rcode) != 200) {
	xlog("rest_put() 响应码=$var(rcode)，用户=$fU\n");
	send_reply(500, "服务器内部错误 4");
	exit;
}
...
```

#### rest_append_hf(txt)

将 *txt* 追加到后续请求的 HTTP 头。通过在执行请求之前多次调用可以追加多个头。

*txt* 的内容应符合 HTTP 头的规范（例如，Field: Value）

参数

- *txt* (string)

此函数可以从任何路由使用。

```c title="rest_append_hf 用法"
...
# 查询需要额外头的 REST 服务的示例

rest_append_hf("Authorization: Bearer mF_9.B5f-4.1JqM");
$var(rc) = rest_get("http://getcredit.org/?account=$fU", $var(credit));
...

```

#### rest_init_client_tls(tls_client_domain)

强制在下次 GET/POST/PUT 请求期间最多使用一次特定的 TLS 域。有关 TLS 客户端域的更多信息，请参阅 tls_mgm 模块。

如果使用此函数，您还必须确保 tls_mgm 已加载并正确配置。

参数

- *tls_client_domain* (string)

此函数可以从任何路由使用。

```c title="rest_init_client_tls 用法"
...
rest_init_client_tls("dom1");
if (!rest_get("https://example.com"))
    xlog("查询失败\n");
...

```

### 导出的异步函数

#### rest_get(url, body_pv[, [ctype_pv][, [retcode_pv]]])

执行异步 HTTP GET。此函数的行为与**[rest get](#func_rest_get)**完全相同（在输入、输出和处理方面），但以非阻塞方式进行。脚本执行被挂起，直到整个 HTTP 响应内容可用。

```c title="异步 rest_get 用法"
route {
	...
	async(rest_get("http://getcredit.org/?account=$fU",
	               $var(credit), , $var(rcode)), resume);
}

route [resume] {
	$var(rc) = $rc;
	if ($var(rc) < 0) {
		xlog("异步 rest_get() 失败，错误码 $var(rc)，账户=$fU\n");
		send_reply(500, "服务器内部错误");
		exit;
	}

	if ($var(rcode) != 200) {
		xlog("L_INFO", "异步 rest_get() 响应码=$var(rcode)，账户=$fU\n");
		send_reply(403, "禁止访问");
		exit;
	}

	...
}
```

#### rest_post(url, send_body_pv, [send_ctype_pv], recv_body_pv[, [recv_ctype_pv][, [retcode_pv]]])

执行异步 HTTP POST。此函数的行为与**[rest post](#func_rest_post)**完全相同（在输入、输出和处理方面），但以非阻塞方式进行。脚本执行被挂起，直到整个 HTTP 响应内容可用。

```c title="异步 rest_post 用法"
route {
	...
	async(rest_post("http://myserver.org/register_user",
	                $fU, , $var(body), $var(ct), $var(rcode)), resume);
}

route [resume] {
	$var(rc) = $rc;
	if ($var(rc) < 0) {
		xlog("异步 rest_post() 失败，错误码 $var(rc)，用户=$fU\n");
		send_reply(500, "服务器内部错误 1");
		exit;
	}
	if ($var(rcode) != 200) {
		xlog("异步 rest_post() 响应码=$var(rcode)，用户=$fU\n");
		send_reply(500, "服务器内部错误 2");
		exit;
	}

	...
}
```

#### rest_put(url, send_body_pv, [send_ctype_pv], recv_body_pv[, [recv_ctype_pv][, [retcode_pv]]])

执行异步 HTTP PUT。此函数的行为与**[rest put](#func_rest_put)**完全相同（在输入、输出和处理方面），但以非阻塞方式进行。脚本执行被挂起，直到整个 HTTP 响应内容可用。

```c title="异步 rest_put 用法"
route {
	...
	async(rest_put("http://myserver.org/users/$fU", $var(userinfo), ,
	               $var(body), $var(ct), $var(rcode)), resume);
}

route [resume] {
	$var(rc) = $rc;
	if ($var(rc) < 0) {
		xlog("异步 rest_put() 失败，错误码 $var(rc)，用户=$fU\n");
		send_reply(500, "服务器内部错误 3");
		exit;
	}
	if ($var(rcode) != 200) {
		xlog("异步 rest_put() 响应码=$var(rcode)，用户=$fU\n");
		send_reply(500, "服务器内部错误 4");
		exit;
	}

	...
}
```

### 导出的脚本转换

该模块还提供了一种对包含在任意脚本变量中的参数进行编码和解码的方法，符合 RFC3986。这是通过对包含要编码的数据的脚本变量应用转换来完成的。原始变量的值不会改变，并返回一个相应的字符串值。转换通过 libcurl API 方法 curl_easy_escape 执行（或用于 libcurl < 7.15.4 的 curl_escape）。

#### {rest.escape}

此转换的结果是生成可安全用于 URI 构建的百分号编码字符串值。

此转换没有参数。

```c title="rest.escape 用法"
...
# 此示例将生成日志条目："Output: call%40example.com%26safe%3Dfalse"
$var(tmp) = "call@example.com&safe=false";
xlog("Output: $(var(tmp){rest.escape})\n");

# 传输前编码呼叫 ID：
$var(rc) = rest_get("https://call-info.org/?id=$(ci{rest.escape})", $var(body_pv));
...

```

#### {rest.unescape}

此转换的结果是解码百分号编码的字符串值。

此转换没有参数。

```c title="rest.unescape 用法"
...
# 此示例将生成日志条目："Output: 1+1=2!"
$var(tmp) = "1%2B1%3D2%21";
xlog("Output: $(var(tmp){rest.unescape})\n");

# 此示例将生成日志条目："OpenSIPs, tastes better with every SIP!"
$var(tmp) = "OpenSIPs%2C%20tastes%20better%20with%20every%20SIP%21";
xlog("$(var(tmp){rest.unescape})\n");
...

```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
