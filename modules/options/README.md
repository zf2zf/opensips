---
title: "Options 模块"
description: "本模块提供一个函数来应答直接发送给服务器本身的 OPTIONS 请求。这意味着 OPTIONS 请求的请求 URI 中包含服务器地址,且 URI 中没有用户名。请求将以 200 OK 应答,其中包含服务器的功能。"
---

## 管理指南


### 概述


本模块提供一个函数来应答直接发送给服务器本身的 OPTIONS 请求。
这意味着 OPTIONS 请求的请求 URI 中包含服务器地址,
且 URI 中没有用户名。
请求将以 200 OK 应答,其中包含服务器的功能。


应答直接发送到您服务器的 OPTIONS 请求是进行 SIP(应用层)远程存活性测试的最简单方法
(类似于网络层的 ICMP echo 请求,也称为 "ping")。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载:


- *sl* -- 无状态回复。
- *signaling* -- 无状态回复。


#### 外部库或应用程序


运行 OpenSIPS 加载此模块之前必须安装以下库或应用程序:


- *无*。


### 导出的参数


#### accept (string)


这是 Accept 头字段的内容。如果为 "",则不会在回复中添加该头。
注意:在 RFC3261 中没有明确说明代理是否应该接受任何内容(默认 "*/*"),
因为它不在乎内容。或者它不接受任何内容,即为 ""。


*默认值为 "*/*"。*


```c title="设置 accept 参数"
...
modparam("options", "accept", "application/*")
...
```


#### accept_encoding (string)


这是 Accept-Encoding 头字段的内容。如果为 "",则不会在回复中添加该头。
请勿更改默认值,因为 OpenSIPS 目前尚不支持任何编码。


*默认值为 ""。*


```c title="设置 accept_encoding 参数"
...
modparam("options", "accept_encoding", "gzip")
...
```


#### accept_language (string)


这是 Accept-Language 头字段的内容。如果为 "",则不会在回复中添加该头。
您可以设置用于其他设备错误描述的语言代码,但大概没有多少设备支持英语以外的其他语言。


*默认值为 "en"。*


```c title="设置 accept_language 参数"
...
modparam("options", "accept_language", "de")
...
```


#### support (string)


这是 Support 头字段的内容。如果为 "",则不会在回复中添加该头。
请勿更改默认值,因为 OpenSIPS 目前不支持 IANA 注册的任何 SIP 扩展。


*默认值为 ""。*


```c title="设置 support 参数"
...
modparam("options", "support", "100rel")
...
```


### 导出的函数


#### options_reply()


此函数检查请求方法是否为 OPTIONS 且
请求 URI 是否不包含用户名。
如果两者都为真,则将以无状态方式用 "200 OK" 和
模块参数中的功能来应答请求。


对于某些错误,它发送 "500 Server Internal Error",
如果为错误请求调用则返回 false。


请求方法和缺失用户名的检查是可选的,
因为函数本身也会执行此检查。
但您不应在此函数之外调用 myself 检查,
因为在这种情况下,函数可能应答发送给您的出站代理,
但目的地与您的代理不同(此检查目前在函数中缺失)。


此函数可用于 REQUEST_ROUTE。


```c title="options_reply 用法"
...
if (is_myself("$rd")) {
	if (is_method("OPTIONS") && (! $ru=~"sip:.*[@]+.*")) {
		options_reply();
	}
}
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)均采用知识共享许可证 4.0 版授权
