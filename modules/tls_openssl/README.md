---
title: "tls_openssl 模块"
description: "此模块使用 [openSSL](https://www.openssl.org/) 库实现 TLS 操作。它提供 *tls_mgm* 模块所需的原语，以暴露由 *proto_tls* 或 *proto_wss* 等基于 TLS 的协议模块使用的高级 API。"
---

## 管理指南


### 概述


此模块使用
		[openSSL](https://www.openssl.org/) 库实现 TLS 操作。
		它提供 *tls_mgm* 模块所需的原语，
		以暴露由 *proto_tls* 或 *proto_wss* 等基于 TLS 的协议模块使用的高级 API。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *无*。


#### 外部库或应用程序


OpenSIPS TLS v1.0 支持需要以下软件包：


- *openssl* 或
				*libssl* >= 0.9.6
- *openssl-dev* 或
				*libssl-dev*


OpenSIPS TLS v1.1/1.2 支持需要以下软件包：


- *openssl* 或
				*libssl* >= 1.0.1e
- *openssl-dev* 或
				*libssl-dev*
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
