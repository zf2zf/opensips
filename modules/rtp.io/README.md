---
title: "RTP.io 模块"
description: "RTP.io 模块提供了在 OpenSIPS 内部处理 RTP 流量的集成解决方案，支持直接在 OpenSIPS 进程中进行 RTP 中继和处理。这消除了对 RTPProxy 等外部进程的需求，从而为某些用例提供了更简化、高效和可管理的系统。"
---

## 管理指南


### 概述


RTP.io 模块提供了在 OpenSIPS 内部处理 RTP 流量的集成解决方案，
            能够在 OpenSIPS 进程内直接进行 RTP 中继和处理。这消除了
            对 RTPProxy 等外部进程的需求，从而为某些用例提供了
            更简化、高效和可管理的系统。


*rtp.io* 模块在主 OpenSIPS 进程中启动 RTP 处理线程，
            并允许 *rtpproxy* 模块通过一对一套接字对访问这些
            线程。这种紧密集成促进了高效的 RTP 流量管理，
            而不依赖外部 RTP 处理服务。


该模块需要 RTPProxy 3.1 或更高版本，
            使用 `--enable-librtpproxy` 选项编译以进行构建。
            它利用 `librtpproxy` 库管理 RTP 流量，
            并与现有的 *rtpproxy* 模块接口以生成命令、解析响应，
            并处理 SIP 消息。


当 *rtpproxy* 模块加载时没有参数，并且 *rtp.io* 模块也被加载，
            *rtp.io* 导出的套接字将自动用于集合 `0`。
            或者，可以使用 `"rtp.io:auto"` 名称将这些套接字合并到其他集合中。


### 依赖


### 导出的参数


#### rtpproxy_args(string)


初始化时传递给嵌入式 RTPProxy 模块的命令行参数。
                有关完整列表，请参阅 RTPProxy 文档。


*参数没有默认值。*


```c title="设置 rtpproxy_args 参数"
...
modparam("rtp.io", "rtpproxy_args", "-m 12000 -M 15000 -l 0.0.0.0 -6 /::")
...
```


### 导出的函数
<!-- CONTRIBUTORS -->

### 许可

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0 版授权
