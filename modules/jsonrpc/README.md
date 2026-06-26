---
title: "JSON-RPC 模块"
description: "此模块是 JSON-RPC v2.0 客户端 [http://www.jsonrpc.org/specification](http://www.jsonrpc.org/specification) 的实现，可以通过 TCP 连接向 JSON-RPC 服务器发送调用。"
---

## 管理指南


### 概述


此模块是 JSON-RPC v2.0 客户端
		[http://www.jsonrpc.org/specification](http://www.jsonrpc.org/specification)
		的实现，可以通过 TCP 连接向 JSON-RPC 服务器发送调用。


请注意，此模块的当前版本不支持 TCP 连接重用，也不支持异步命令。


### 依赖


#### OpenSIPS 模块


加载此模块之前必须加载以下模块：


- *无*。


#### 外部库或应用程序


运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- *无*


### 导出的参数


#### connect_timeout (整数)


OpenSIPS 连接到 JSON-RPC 服务器所能等待的毫秒数。


*默认值为 "500 毫秒"。*


```c title="设置 connect_timeout 参数"
...
modparam("jsonrpc", "connect_timeout", 200)
...
```


#### write_timeout (整数)


OpenSIPS 发送 RPC 命令到 JSON-RPC 服务器所能等待的毫秒数。


*默认值为 "500 毫秒"。*


```c title="设置 write_timeout 参数"
...
modparam("jsonrpc", "write_timeout", 300)
...
```


#### read_timeout (整数)


OpenSIPS 等待 JSON-RPC 服务器响应 JSON-RPC 请求所能等待的毫秒数。
		请注意，这些参数仅影响 *jsonrpc_request* 命令。


*默认值为 "500 毫秒"。*


```c title="设置 read_timeout 参数"
...
modparam("jsonrpc", "read_timeout", 300)
...
```


### 导出的函数


#### jsonrpc_request(destination, method, params, ret_var)


向 *destination* 参数中指定的 JSON-RPC 服务器
				发出 JSON-RPC 请求，并等待其回复。


此函数可用于任何路由。


函数具有以下参数：


- *destination* (字符串) - JSON-RPC 服务器的地址。格式需要是
						*IP:port*。
- *method* (字符串) - RPC 请求中使用的方法。
- *params* (字符串) - 发送到 RPC 方法的参数。
						此参数需要是一个格式正确的 JSON 数组或 JSON 对象，
						根据 JSON-RPC 规范。
- *ret_var* 一个可写变量，
						用于存储 JSON-RPC 命令的结果。如果命令返回错误，
						该变量将被填充错误 JSON；否则，
						填充 JSON-RPC 结果的主体。


函数具有以下返回码：


- *1* - JSON-RPC 命令成功执行，
						服务器返回成功。您可以检查 *ret_pvar* 变量获取结果。
- *-1* - 处理过程中发生内部错误。
- *-2* - 与目标的连接（超时或连接）错误。
- *-3* - JSON-RPC 成功运行，但服务器返回错误。
						检查 *ret_pvar* 值以获取更多信息。


```c title="jsonrpc_request() 函数用法"
	...
	if (!jsonrpc_request("127.0.0.1", "add", "[1,2]", $var(ret))) {
		xlog("JSON-RPC command failed with $var(ret)\n");
		exit;
	}
	xlog(JSON-RPC command returned $var(ret)\n");
	# 解析 $var(ret) 为 JSON，或函数返回的任何内容
	...
	
```


#### jsonrpc_notification(destination, method, params)


向 *destination* 参数中指定的 JSON-RPC 服务器
				发出 JSON-RPC 通知，但与 [jsonrpc request](#func_jsonrpc_request) 不同，
				它不等待 JSON-RPC 服务器的回复。


此函数可用于任何路由。


函数接收与 [jsonrpc request](#func_jsonrpc_request) 相同的参数，
				除了 *ret_pvar*。返回值也相同。


```c title="jsonrpc_notification() 函数用法"
	...
	if (!jsonrpc_notification("127.0.0.1", "block_ip", "{ \"ip": \"$si\" }")) {
		xlog("JSON-RPC notification failed with $rc!\n");
		exit;
	}
	...
	
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议。
