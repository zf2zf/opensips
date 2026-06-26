---
title: "httpd 模块"
description: "本模块为 OpenSIPS 提供 HTTP 传输层。"
---

## 管理指南


### 概述


本模块为 OpenSIPS 提供 HTTP 传输层。


httpd 模块的 HTTP 服务器实现基于 libmicrohttpd 库。


### 概述


HTTP 服务器的 TLS 通过设置 `tls_cert_file` 和 `tls_key_file` 参数来启用。
如果启用了 TLS，则会禁用普通 HTTP 支持。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *无其他 OpenSIPS 模块依赖*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *libmicrohttpd*，需要 EPOLL 支持。
这通常意味着版本高于 **0.9.50**。


**警告！** 请注意 libmicrohttpd 库及其打包中的一个 EPOLL 支持回归问题，
它会影响 OpenSIPS httpd 模块，已按照以下时间线修复。
回归的影响是 HTTP 响应体有时 *有时* 不会被库写入，
导致客户端（如 opensips-cli）无限期挂起等待：


- **0.9.51** - **0.9.52** 版本经过测试，可以正常工作
- 回归问题在 **0.9.53**（2017年4月）引入，持续到 **0.9.71**（2020年5月）
- 回归问题在 **0.9.72**（2020年12月）已修复


### 导出的参数


#### ip (string)


HTTP 服务器监听传入请求的 IP 地址。


*默认值为 "127.0.0.1"*（仅绑定到回环接口）。
使用 "*" 可绑定到所有 IPv6 和 IPv4 接口。


```c title="设置 ip 参数"
...
modparam("httpd", "ip", "127.0.0.1")
...
```


#### port (integer)


HTTP 服务器监听传入请求的端口号。


*默认值为 8888。*
不接受低于 1024 的端口。


```c title="设置 port 参数"
...
modparam("httpd", "port", 8000)
...
```


#### conn_timeout (integer)


自动关闭空闲超过指定超时时间（秒）的 TCP 连接。
设置为零则永不关闭任何连接。


注意：连接自动关闭程序似乎仅在"按需"模式下执行，
在 HTTPD 网络事件期间（例如在新连接时），
虽然不理想，但在实际使用中应该足够了。


*默认超时为 30 秒。*


```c title="设置 conn_timeout 参数"
...
modparam("httpd", "conn_timeout", 10)
...
```


#### buf_size (integer)


它指定写入 HTML 响应时使用的缓冲区的最大长度（以字节为单位）。


如果缓冲区大小设置为零，它将自动设置为 pkg 内存大小的四分之一。


*默认值为 0。*


```c title="设置 buf_size 参数"
...
modparam("httpd", "buf_size", 524288)
...
```


#### post_buf_size (integer)


它指定处理 POST HTTP 请求的缓冲区长度（以字节为单位）。
对于大型 POST 请求，可能需要增加默认值。


*默认值为 1024。最小值为 256。*


```c title="设置 post_buf_size 参数"
...
modparam("httpd", "post_buf_size", 4096)
...
```


#### receive_buf_size (integer)


它指定接收的 HTTP 请求的最大长度（以字节为单位）。
对于接收大型 POST 请求，可能需要增加默认值。


*默认值为 1024。*


```c title="设置 receive_buf_size 参数"
...
modparam("httpd", "receive_buf_size", 4096)
...
```


#### tls_cert_file (string)


httpd 的公钥证书文件。它将用作传入 TLS 连接的服务器端证书。


*默认值为 ""*


```c title="设置 tls_cert_file 参数"
...
modparam("httpd", "tls_cert_file", "/etc/opensips/tls/server.pem")
...
```


#### tls_key_file (string)


上述证书的私钥。必须保存在安全的地方并设置严格的权限！


*默认值为 ""*


```c title="设置 tls_key_file 参数"
...
modparam("httpd", "tls_key_file", "/etc/opensips/tls/server.key")
...
```


#### tls_ciphers (string)


您可以指定允许的身份验证和加密算法列表。
要获取密码列表并选择，请使用 gnutls-cli 应用程序：


- gnutls-cli -l


> [!警告]
> 不要使用 NULL 算法（无加密）... 永远不要！！！


*默认值为 "SECURE256:+SECURE192:-VERS-ALL:+VERS-TLS1.2"*


```c title="设置 tls_key_file 参数"
...
modparam("httpd", "tls_ciphers", "SECURE256:+SECURE192:-VERS-ALL:+VERS-TLS1.2")
...
```


#### auth_realm (string)


用于 HTTP 基本认证挑战的 realm 字符串。
仅在同时设置了 `auth_username` 和 `auth_password` 时生效。


*默认值为 "OpenSIPS MI"。*


```c title="设置 auth_realm 参数"
...
modparam("httpd", "auth_realm", "OpenSIPS Management")
...
```


#### auth_username (string)


HTTP 基本认证的用户名。当与 `auth_password` 一起设置时，
所有 HTTP 请求都必须提供有效凭证。
没有凭证或凭证不正确的请求将收到 401 Unauthorized 响应。


*默认值为 ""（认证已禁用）。*


```c title="设置 auth_username 参数"
...
modparam("httpd", "auth_username", "admin")
...
```


#### auth_password (string)


HTTP 基本认证的密码。必须与 `auth_username` 一起设置。


> [!警告]
> 使用 HTTP 基本认证时，强烈建议同时通过
`tls_cert_file` 和 `tls_key_file` 启用 TLS，
以防止凭证以明文形式传输。


*默认值为 ""（认证已禁用）。*


```c title="设置 auth_password 参数"
...
modparam("httpd", "auth_password", "secretpass")
...
```


### 导出的 MI 函数


#### httpd:list_root_path


替换已废弃的 MI 命令：*httpd_list_root_path*。


列出 httpd 模块中所有已注册的 HTTP 根路径。
当请求到达时，如果根路径在列表中，
请求将被发送到注册它的模块。


名称：*httpd:list_root_path*


参数：无


MI FIFO 命令格式：


```c
opensips-cli -x mi httpd:list_root_path
		
```


### 导出的函数


配置文件中没有导出可供使用的函数。


### 已知问题


由于 OpenSIPS 是一个多进程应用程序，
microhttpd 库以"外部 select"模式使用。
这确保库不在多线程模式下运行，
并且库完全由 OpenSIPS 控制。
由于这种特殊的操作模式，
目前整个 HTTP 响应是在预分配的缓冲区中构建的（参见 buf_size 参数）。


此模块的未来版本将解决此问题。


在 Linux 上，默认禁止以非 root 用户在低于 1024 的端口上运行 httpd 守护进程（kernel>=2.6.24）。
要允许端口绑定，可以使用 *setcap* 为 opensips 二进制文件赋予额外权限：


```c
setcap 'cap_net_bind_service=+ep' /usr/local/sbin/opensips
		
```


## 开发者指南


### 可用函数


#### register_httpdcb (module, root_path, httpd_acces_handler_cb, httpd_flush_data_cb, httpd_init_proc_cb)


将新的 HTTP 根及其关联的回调注册到 httpd 模块中。


参数的含义如下：


- *const char *mod*
- 注册要处理的 HTTP 根路径的模块名称
- *str *root_path*
- 已注册的根路径
- *httpd_acces_handler_cb f1*
- 根路径匹配时调用的回调方法处理程序
- *httpd_flush_data_cb f2*
- 用于发送额外数据（在稍后时间）的回调方法处理程序
- *httpd_init_proc_cb f3*
- 在 httpd 进程初始化期间调用的回调方法处理程序
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议。
