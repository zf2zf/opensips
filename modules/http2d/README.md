---
title: "HTTP2D 模块"
description: "此模块提供了一个基于 **nghttp2** 库 ([https://nghttp2.org/](https://nghttp2.org/)) 的 RFC 7540/9113 HTTP/2 服务器实现，支持 \"h2\" ALPN。"
---

## 管理指南


### 概述


此模块提供了一个基于 **nghttp2** 库 ([https://nghttp2.org/](https://nghttp2.org/)) 的 RFC 7540/9113 HTTP/2 服务器实现，支持 "h2" ALPN。


HTTP/2 于 2015 年推出，是一种二进制协议，包含额外的传输层（SESSION、FRAME），
		它允许在同一个 TCP/TLS 连接上识别和管理多个并发传输。
		因此，修订后的协议主要旨在减少客户端和服务器的資源使用，
		通过减少加载给定网页时执行的 TCP 和/或 TLS 握手次数。


OpenSIPS **http2d** 服务器同时支持 "h2"（TLS 加密）
		和 "h2c"（明文）HTTP/2 连接。请求到达
		*opensips.cfg* 级别时使用 [http2 请求](#event_e_http2_request) 事件，
		脚本编写者可以在此处处理数据并做出相应响应。


### 依赖


#### OpenSIPS 模块


无。


#### 外部库或应用程序


HTTP/2 服务器由 **nghttp2** 库提供，
		该库运行在 **libevent** 服务器框架之上。


在运行加载此模块的 OpenSIPS 之前，必须安装以下库：


- *libnghttp2*
- *libevent*, *libevent_openssl*
- *libssl*, *libcrypto*


### 导出的参数


#### ip (字符串)


监听的 IPv4 地址。


默认值为 *"127.0.0.1"*。


```c title="设置 ip 参数"
modparam("http2d", "ip", "127.0.0.2")
```


#### port (整数)


监听端口。


默认值为 *443*。


```c title="设置 port 参数"
modparam("http2d", "port", 5000)
```


#### tls_cert_path (字符串)


TLS 证书文件的路径，格式为 PEM。


默认值为 *NULL*（未设置）。


```c title="设置 tls_cert_path 参数"
modparam("http2d", "tls_cert_path", "/etc/pki/http2/cert.pem")
```


#### tls_cert_key (字符串)


TLS 私钥文件的路径，格式为 PEM。


默认值为 *NULL*（未设置）。


```c title="设置 tls_cert_key 参数"
modparam("http2d", "tls_cert_key", "/etc/pki/http2/private/key.pem")
```


#### max_headers_size (整数)


服务器处理的单个 HTTP/2 请求中所有头部字段名称和值的最大字节数。
		一旦达到此阈值，额外头部将不再提供给脚本级别，而是报告为错误。


默认值为 *8192* 字节。


```c title="设置 max_headers_size 参数"
modparam("http2d", "max_headers_size", 16384)
```


#### response_timeout (整数)


库允许 opensips.cfg 处理给定 HTTP/2 请求的最大时间（毫秒）。


一旦达到此超时，模块将自动生成 408（请求超时）回复。


默认值为 *2000* 毫秒。


```c title="设置 response_timeout 参数"
modparam("http2d", "response_timeout", 5000)
```


### 导出的函数


#### http2_send_response(code, [headers_json], [data])


发送正在处理的 HTTP/2 请求的响应。*":status"*
		头部字段将由模块自动作为第一个头部包含，因此不必包含在 *headers_json* 数组中。


*参数*


- *code* (整数) - HTTP/2 回复码
- *headers_json* (字符串, 默认值: *NULL*)
				- 可选的 JSON 数组，包含 {"header": "value"} 元素，表示要包含在响应消息中的 HTTP/2
				头部及其值。
- *data* (字符串, 默认值: *NULL*)
				- 要包含在响应消息中的可选 DATA 负载。


*返回码*


- **1** - 成功
- **-1** - 内部错误


此函数只能用于 *EVENT_ROUTE*。


```c title="http2_send_response() 用法"
event_route [E_HTTP2_REQUEST] {
  xlog(":: Method:  $param(method)\n");
  xlog(":: Path:    $param(path)\n");
  xlog(":: Headers: $param(headers)\n");
  xlog(":: Data:    $param(data)\n");

  $json(hdrs) := $param(headers);
  xlog("content-type: $json(hdrs/content-type)\n");

  $var(rpl_headers) = "[
	{ \"content-type\": \"application/json\" },
	{ \"server\": \"OpenSIPS 3.5\" },
	{ \"x-current-time\": \"1711457142\" },
	{ \"x-call-cost\": \"0.355\" }
  ]";

  $var(data) = "{\"status\": \"success\"}";

  if (!http2_send_response(200, $var(rpl_headers), $var(data)))
    xlog("ERROR - failed to send HTTP/2 response\n");
}
```


### 导出的事件


#### E_HTTP2_REQUEST


当加载 *http2d* 模块且 OpenSIPS 在配置
		的监听接口上收到 HTTP/2 请求时触发此事件。


参数：


- *method (字符串)* - ":method" HTTP/2 头的值
- *path (字符串)* - ":path" HTTP/2 头的值
- *headers (字符串)* - 包含请求所有头部的 JSON 数组，
						包括伪头部
- *data (字符串, 默认值: NULL)* - 如果请求包含负载，
						此参数将保存其内容


请注意，此事件当前设计为主要通过 *event_route* 使用，
		因为这是访问 [http2 发送响应](#func_http2_send_response)
		函数的唯一方式，以便构建自定义响应消息。另一方面，
		如果应用程序不介意答案始终是 200 且没有负载，
		则可以通过任何其他 EVI 兼容的传递通道成功使用此事件 :-)
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议。
