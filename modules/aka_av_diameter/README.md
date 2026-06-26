---
title: "AKA 认证向量 Diameter 模块"
description: "此模块是 *AKA_AUTH* 模块的扩展，提供 Diameter AKA AV Manager，实现了 *Cx* 接口的 *ETSI TS 129 229* 规范中定义的多媒体认证请求和多媒体认证答案 Diameter 命令，以获取一组认证向量并将其馈送到 AKA 认证过程。"
---

## 管理指南


### 概述


此模块是 *AKA_AUTH* 模块的扩展，
		提供 Diameter AKA AV Manager，实现了
		*Cx* 接口的 *ETSI TS 129 229*
		规范中定义的多媒体认证请求和多媒体认证答案 Diameter 命令，
        以获取一组认证向量并将其馈送到 AKA 认证过程。


当 *AKA_AUTH* 模块需要新的认证向量来执行 *aka_challenge()* 时，
		它可能需要此模块获取一组认证向量。
        该模块将查询打包成 *MAR*（多媒体认证请求）命令，
        并将其发送到 *HSS* Diameter 服务器。
        当收到响应中的 *MAA*（多媒体认证答案）命令时，
        相应的认证向量被收集并反馈给 *AUTH_AKA* 引擎。


它使用 *AAA_Diameter* 模块执行 Diameter 请求。
		根据 *AUTH_AKA* 模块执行查询的方式，
        它可以同步和异步模式运行。


### 设置


该模块需要到 *HSS* Diameter 服务器的 *aaa_diameter* 连接，
		该服务器实现 *Cx* 接口，
        并能够通过多媒体认证请求和多媒体认证答案命令提供认证向量。


命令的格式以及必需字段可以在模块源代码目录中的
		*example/aka_av_diameter.dictionary* 文件中找到，
        也可以在 [示例 diameter 命令](#diameter_commands_file) 部分中找到。


*注意：* 模块内部使用提供的字典中找到的 AVP 名称
		——更改文件可能会破坏模块的行为。


### 依赖


#### OpenSIPS 模块


该模块依赖以下模块（换句话说，
			列出的模块必须在此模块之前加载）：


- *auth_aka* -- 触发 AKA 认证过程的
				AKA 认证模块
- *aaa_diameter* -- 实现到 *HSS* 服务器的
				Diameter 通信的 AAA Diameter 模块。


#### 外部库或应用程序


此模块不依赖任何外部库。


### 导出的参数


#### aaa_url (字符串)


这是表示到 AAA 服务器连接的 URL。
		*注意：* 目前该模块仅支持到 Diameter 服务器的连接。
        还需要 AVPs 配置文件路径，否则模块将无法启动或无法正常工作。


```c title="aaa_url 参数使用"
modparam("auth_aaa", "aaa_url", "diameter:freeDiameter.conf;extra-avps-file:/etc/freeDiameter/aka_av_diameter.dictionary")
			
```


#### realm (字符串)


在 Origin Diameter 命令中使用的 Realm。


默认值为 "diameter.test"。


```c title="realm 参数使用"
			
modparam("aka_av_diameter", "realm", "scscf.ims.mnc001.mcc001.3gppnetwork.org")
			
```


#### server_uri (字符串)


在 Diameter 命令中使用的 Server-URI。


如果留空，Server-Name 将通过在 realm 参数值前面添加 "sip:" 来创建
		（例如 "sip:scscf.ims.mnc001.mcc001.3gppnetwork.org"）。


```c title="server_uri 参数使用"
			
modparam("aka_av_diameter", "server_uri", "sip:scscf.ims.mnc001.mcc001.3gppnetwork.org")
			
```


### Diameter 命令文件


应提供给 *aaa_diameter* 连接的文件。


```c title="Diameter 命令文件示例"
VENDOR 10415 TGPP

ATTRIBUTE Public-Identity                     601 string     10415
ATTRIBUTE Server-Name                         602 string     10415
ATTRIBUTE 3GPP-SIP-Number-Auth-Items          607 unsigned32 10415
ATTRIBUTE 3GPP-SIP-Authentication-Scheme      608 utf8string 10415
ATTRIBUTE 3GPP-SIP-Authenticate               609 hexstring  10415
ATTRIBUTE 3GPP-SIP-Authorization              610 hexstring  10415
ATTRIBUTE 3GPP-SIP-Authentication-Context     611 string     10415
ATTRIBUTE 3GPP-SIP-Item-Number                613 unsigned32 10415
ATTRIBUTE Confidentiality-Key                 625 hexstring  10415
ATTRIBUTE Integrity-Key                       626 hexstring  10415


ATTRIBUTE 3GPP-SIP-Auth-Data-Item             612 grouped    10415
{
	3GPP-SIP-Item-Number | OPTIONAL | 1
	3GPP-SIP-Authentication-Scheme | OPTIONAL | 1
	3GPP-SIP-Authenticate | OPTIONAL | 1
	3GPP-SIP-Authorization | OPTIONAL | 1
	3GPP-SIP-Authentication-Context | OPTIONAL | 1
	Confidentiality-Key | OPTIONAL | 1
	Integrity-Key | OPTIONAL | 1
}

APPLICATION-AUTH 16777216/10415 3GPP Cx

REQUEST 303 Multimedia-Auth Request
{
	Session-Id | REQUIRED | 1
	Origin-Host | REQUIRED | 1
	Origin-Realm | REQUIRED | 1
	Destination-Realm | REQUIRED | 1
	Vendor-Specific-Application-Id | REQUIRED | 1
	Auth-Session-State | REQUIRED | 1
	User-Name | REQUIRED | 1
	Public-Identity | REQUIRED | 1
	3GPP-SIP-Number-Auth-Items | REQUIRED | 1
	3GPP-SIP-Auth-Data-Item | REQUIRED | 1
	Server-Name | REQUIRED | 1
}

ANSWER 303 Multimedia-Auth Answer
{
	Session-Id | REQUIRED | 1
	Origin-Host | REQUIRED | 1
	Origin-Realm | REQUIRED | 1
	Destination-Host | OPTIONAL | 1
	Destination-Realm | OPTIONAL | 1
	Vendor-Specific-Application-Id | REQUIRED | 1
	Auth-Session-State | REQUIRED | 1
	User-Name | REQUIRED | 1
	Public-Identity | REQUIRED | 1
	3GPP-SIP-Number-Auth-Items | REQUIRED | 1
	3GPP-SIP-Auth-Data-Item | REQUIRED | 1
	Result-Code | REQUIRED | 1
}
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
