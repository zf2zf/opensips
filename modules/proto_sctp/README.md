---
title: "proto_sctp 模块"
description: "**proto_sctp** 模块是一个可选的传输模块(共享库),导出处理基于 SCTP 通信所需的逻辑。(套接字初始化和 send/recv 原语,供更高级别的网络层使用)"
---

## 管理指南


### 概述


**proto_sctp** 模块是一个可选的传输模块(共享库),导出处理基于 SCTP 通信所需的逻辑。(套接字初始化和 send/recv 原语,供更高级别的网络层使用)


加载后,你将能够在脚本中定义 *"sctp:"* 监听器。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载:


- *无*。


#### 外部库或应用程序


运行 OpenSIPS 加载此模块之前,必须安装以下库或应用程序:


- *无*。


### 导出的参数


#### sctp_port (integer)


用于所有 SCTP 相关操作的默认端口。请小心,因为默认端口会影响 SIP 监听部分(如果在 SCTP 监听器中未定义端口)和 SIP 发送部分(如果目标 SCTP URI 没有显式端口)。


如果你只想更改 STP 的监听端口,请使用 SIP 监听器定义中的端口选项。


*默认值为 5060。*


```c title="设置 sctp_port 参数"
...
modparam("proto_sctp", "sctp_port", 5070)
...
```


## 常见问题


**Q: 切换到 OpenSIPS 2.1 后,我收到此错误:
				"listeners found for protocol sctp, but no module can handle it"**


你需要加载 "proto_sctp" 模块。在脚本中,确保在设置 **[mpath](https://docs.opensips.org/manual/2-1/script-coreparameters#mpath)** 之后执行 **loadmodule "proto_sctp.so"**。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)采用 Creative Common License 4.0 授权
