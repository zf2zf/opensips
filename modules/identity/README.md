---
title: "身份验证模块"
description: "此模块添加对 SIP Identity（参见 RFC 4474）的支持。"
---

## 管理指南

### 概述

此模块添加对 SIP Identity（参见 RFC 4474）的支持。

### 依赖

#### OpenSIPS 模块

以下模块必须在此模块之前加载：

- *无依赖*

#### 外部库或应用程序

运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：

- *openssl (libssl)*

### 导出的参数

#### privKey (string)

认证服务的私钥文件名。此文件必须是 PEM 格式。

```c title="设置 privKey 参数"
...
modparam("identity", "privKey", "/etc/openser/privkey.pem")
...
```

#### authCert (string)

属于 `privKey` 的证书文件名。此文件必须是 PEM 格式。

#### certUri (string)

可以获取认证服务证书的 URI。此字符串将放在 Identity-Info 头中。

#### verCert (string)

包含验证器证书的路径。证书必须是 PEM 格式。

#### caList (string)

包含验证器所有受信任（根）证书的文件。证书必须是 PEM 格式。

#### useCrls (integer)

决定是否使用吊销列表（"1"）或不使用（"0"）。

*默认值为 "0"*

### 导出的函数

#### authservice()

执行认证服务的步骤。

返回码：
- -3: Date 头与证书有效期不匹配
- -2: 消息超时
- -1: 发生错误
- 1: 一切正常，Identity 头已添加

#### verifier()

执行验证器的步骤。

返回码：
- -438: 签名与消息不符
- -437: 无法验证证书
- -436: 证书不可用
- -428: 消息没有 Identity 头
- -3: 验证 Date 头时出错
- -2: 认证服务不权威
- -1: 发生未知错误
- 1: 验证通过

### 已知限制

- 证书不会被下载，必须本地存储
- 不提供完整的重放保护
- 认证服务和验证器使用原始请求
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
