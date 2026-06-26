---
title: "对等模块"
description: "对等模块允许 SIP 提供商(运营商或组织)从代理验证 SIP 请求的源或目标是否为可信对等方。"
---

## 管理指南


### 概述


对等模块允许 SIP
提供商(运营商或组织)从代理验证 SIP 请求的源或目标是否为可信对等方。


为了参与代理提供的信任社区,
每个 SIP 提供商向代理注册它们所服务的域(SIP URI 的主机部分)。
当提供商的 SIP 代理需要向非本地域发送 SIP 请求时,
它可以使用 verify_destination() 函数从代理查明非本地域是否由可信对等方服务。
如果是,提供商会从代理收到 SIP 请求的哈希和时间戳,
并将其包含在到非本地域的请求中。
当非本地域的 SIP 代理收到 SIP 请求时,
它可以依次使用 verify_source() 函数从代理验证请求是否来自可信对等方。


验证函数使用 AAA 协议与代理通信。


欢迎提出改进意见和建议。


### 依赖


#### OpenSIPS 模块


该模块依赖以下模块
(换句话说,
列出的模块必须在此模块之前加载):


- *实现 AAA 的模块*


### 导出的参数


#### aaa_url (string)


这是表示所使用的 AAA 协议及其配置文件位置的 URL。


如果参数设置为空字符串,
将禁用 AAA 计费支持(即使已编译)。


默认值为 "NULL"。


```c title="设置 aaa_url 参数"
...
modparam("peering", "aaa_url", "radius:/etc/radiusclient-ng/radiusclient.conf")
...
```


#### verify_destination_service_type (integer)


这是 Service-Type AAA 属性的值,
当 SIP 请求的发送者使用 verify_destination() 函数验证请求目标时使用。


默认值为 "Sip-Verify-Destination"
Service-Type 的字典值。


```c title="verify_destination_service_type 参数用法"
...
modparam("peering", "verify_destination_service_type", 21)
...
```


#### verify_source_service_type (integer)


这是 Service-Type AAA 属性的值,
当 SIP 请求的接收者使用 verify_source() 函数验证请求源时使用。


默认值为 "Sip-Verify-Source"
Service-Type 的字典值。


```c title="verify_source_service_type 参数用法"
...
modparam("peering", "verify_source_service_type", 22)
...
```


### 导出的函数


#### verify_destination()


verify_destination() 函数从
代理的 AAA 服务器查询 Request URI 的域(主机部分)是否由可信对等方服务。
AAA 请求包含以下属性/值:


- User-Name - Request-URI 主机
- SIP-URI-User - Request-URI 用户
- SIP-From-Tag - From 标签
- SIP-Call-Id - Call ID
- Service-Type - verify_destination_service_type


如果 Request URI 的域由可信对等方服务,函数返回 1,否则返回 -1。
如果是肯定结果,AAA 服务器返回一组 SIP-AVP 回复属性。
每个 SIP-AVP 的值格式如下:


[#]name(:|#)value


每个 SIP-AVP 回复属性的值映射到
OpenSIPS AVP。名称或值前面的 # 前缀分别表示字符串名称或字符串值。


其中一个 SIP-AVP 回复属性包含一个字符串,
源对等方必须"按原样"包含在向目标对等方发送 SIP 请求时的 P-Request-Hash 头中。
字符串值例如可以是 hash@timestamp 形式,
其中 hash 包含代理基于查询的属性和一些本地信息计算的哈希,
timestamp 是进行计算的时间。


回复属性中使用的 AVP 名称由代理分配。


此函数可用于 REQUEST_ROUTE 和 FAILURE_ROUTE。


```c title="verify_destination() 用法"
...
if (verify_destination()) {
   append_hf("P-Request-Hash: $avp(prh)\r\n");
}
...
```


#### verify_source()


verify_source() 函数从
代理的 AAA 服务器查询 SIP 请求是否来自可信对等方。
AAA 请求包含以下属性/值:


- User-Name - Request-URI 主机
- SIP-URI-User - Request-URI 用户
- SIP-From-Tag - From 标签
- SIP-Call-Id - Call ID
- SIP-Request-Hash - P-Request-Hash 头的内容
- Service-Type - verify_source_service_type


如果 SIP 请求来自可信对等方,函数返回 1,否则返回 -1。
如果是肯定结果,AAA 服务器可以返回一组 SIP-AVP 回复属性。
每个 SIP-AVP 的值格式如下:


[#]name(:|#)value


每个 SIP-AVP 回复属性的值映射到
OpenSIPS AVP。名称或值前面的 # 前缀分别表示字符串名称或字符串值。


回复属性中使用的 AVP 名称由代理分配。


此函数可用于 REQUEST_ROUTE 和 FAILURE_ROUTE。


```c title="verify_source() 用法"
...
if (is_present_hf("P-Request-Hash")) {
   if (verify_source()) {
      xlog("L_INFO", "请求来自可信对等方\n")
   }
}
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)均采用知识共享许可证 4.0 版授权
