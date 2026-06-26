---
title: "tls_wolfssl 模块"
description: "此模块使用 [wolfSSL](https://www.wolfssl.com/) 库实现 TLS 操作。它提供 *tls_mgm* 模块所需的原语，以暴露由 *proto_tls* 或 *proto_wss* 等基于 TLS 的协议模块使用的高级 API。"
---

## 管理指南


### 概述


此模块使用
		[wolfSSL](https://www.wolfssl.com/) 库实现 TLS 操作。
		它提供 *tls_mgm* 模块所需的原语，
		以暴露由 *proto_tls* 或 *proto_wss* 等基于 TLS 的协议模块使用的高级 API。


*wolfSSL* 库是静态链接的，
		并与此模块捆绑在一起，因此无需安装或外部依赖。


### 依赖


#### 编译


编译此模块之前必须安装以下软件包：


- *autoconf*。
- *automake*。
- *libtool*。


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *无*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- *无*。


### 导出的参数


所有这些参数都可以从 opensips.cfg 文件使用，
		用于配置 OpenSIPS-TLS 的行为。


#### try_use_ktls (integer)


尝试为 RX 和 TX 使用 KTLS（取决于内核支持和加载的模块
			https://docs.kernel.org/networking/tls-offload.htm ）
			如果未找到内核支持，或尝试使用的密码不支持
			（目前仅支持 AES-GCM），则 SSL 操作将继续在用户空间进行。
			如果 NIC 支持 SSL 卸载，也可以启用，
			无需对模块进行任何更改
			https://docs.nvidia.com/doca/sdk/ktls-offloads/index.html


默认值为 *0*。


```c title="设置 try_use_ktls 变量"
...
modparam("tls_wolfssl", "try_use_ktls", 1)
...

```


## 常见问题


**Q：编译模块时为什么会收到以下错误？**


如果您通过从 Github 克隆仓库获取 OpenSIPS 源码，
		而没有为 *git clone* 命令使用 *--recursive* 选项，
		则您没有正确获取作为 git 子模块包含的
		*wolfSSL* 库代码，该子模块指向官方 *wolfSSL* 仓库。


要获取 *wolfSSL* 库代码，您可以运行：

```c

	git submodule update --init

```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
