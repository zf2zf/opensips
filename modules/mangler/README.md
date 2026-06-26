---
title: "mangler 模块"
description: "这是一个用于SDP mangling的模块。注意：此模块已弃用，将在1.5.0版本中移除。"
---

## 管理指南


### 概述


这是一个用于SDP mangling的模块。
		注意：此模块已弃用，将在1.5.0版本中移除。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他OpenSIPS模块*。


#### 外部库或应用程序


运行此模块加载的OpenSIPS之前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### contact_flds_separator (string)


此参数的第一个字符用作编码/解码Contact头部分隔符。


> [!警告]
> 此字段的第一个字符必须设置为在username、password或其他contact字段中不使用的值。否则解码步骤可能会失败/产生错误结果。


*默认值为"*"。*


```c title="设置 db_url 参数"
...
modparam("mangler", "contact_flds_separator", "-")
...
```


那么编码后的URI可能看起来像
	sip:user-password-ip-port-protocol@PublicIP


### 导出的函数


#### sdp_mangle_ip(pattern, newip)


修改SDP包中描述连接的IP地址，如c=IN IP4。当前只修改IP4地址，因为IP6可能不需要穿越NAT :)


函数在错误时返回负数，或返回替换次数+1。


参数的含义如下：


- *pattern* (string) - 用于匹配的IP/掩码对
		用于匹配SDP包中c=IN IP4 ip行中的IP。只有位于此模式描述的网络中的IP对应的行才会被修改。有效模式的例子包括"10.0.0.0/255.0.0.0"或
		"10.0.0.0/8"等。
- *newip* (string) - 新的
		IP，用于替换SDP包中匹配pattern的旧IP地址。


此函数可用于REQUEST_ROUTE、ONREPLY_ROUTE。


```c title="sdp_mangle_ip 使用示例"
...
sdp_mangle_ip("10.0.0.0/8","193.175.135.38");
...
```


#### sdp_mangle_port(offset)


修改SDP包中描述媒体的端口，如m=audio 13451。


函数在错误时返回负数，或返回替换次数+1。


参数的含义如下：


- *offset* (int) - 一个整数，
		将与找到的端口相加/相减。


此函数可用于REQUEST_ROUTE、ONREPLY_ROUTE。


```c title="sdp_mangle_port 使用示例"
...
sdp_mangle_port(-12000);
...
```


#### encode_contact(encoding_prefix, public_ip)


此函数将按以下方式编码Contact头中的URI
	sip:username:password@ip:port;transport=protocol 变为
	sip:enc_pref*username*ip*port*protocol@public_ip *是默认分隔符。


函数错误时返回负数，成功时返回1。


参数的含义如下：


- *encoding_prefix* (string) - 用于确定contact是否已编码的标识符，publicip--一个可路由的IP，很可能应该是您NAT设备的外网IP。
*public_ip* (string) - 将用于编码contact的公共IP，如上例所述。


此函数可用于REQUEST_ROUTE、ONREPLY_ROUTE。


```c title="encode_contact 使用示例"
...
if ($si == 10.0.0.0/8) encode_contact("enc_prefix","193.175.135.38"); 
...
```


#### decode_contact()


此函数将解码数据包第一行中的URI，该数据包以以下方式编码：
	sip:enc_pref*username*ip*port*protocol@public_ip 变为
	sip:username:password@ip:port;transport=protocol 它使用contact编码分隔符的默认设置参数。


函数错误时返回负数，成功时返回1。


参数的含义如下：


此函数可用于REQUEST_ROUTE。


```c title="decode_contact 使用示例"
...
if ($ru =~ "^enc*") { decode_contact(); }
...
```


#### decode_contact_header()


此函数将按以下方式解码Contact头中的URI：
	sip:enc_pref*username*ip*port*protocol@public_ip 变为
	sip:username:password@ip:port;transport=protocol。它使用contact编码分隔符的默认设置参数。


函数错误时返回负数，成功时返回1。


参数的含义如下：


此函数可用于REQUEST_ROUTE、ONREPLY_ROUTE。


```c title="decode_contact_header 使用示例"
...
if ($ru =~ "^enc*") { decode_contact_header(); }
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即.md扩展名）均采用知识共享署名4.0许可证。
