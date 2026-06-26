---
title: "脚本助手模块"
description: "**脚本助手模块**的目的是简化在 OpenSIPS 中进行基本场景时的脚本编写过程。同时，它对脚本编写者很有用，因为它包含基本的 SIP 路由逻辑，使他们能够更多地关注其 OpenSIPS 路由代码的特定方面。"
---

## 管理指南


### 概述


**脚本助手模块**的目的是简化在 OpenSIPS 中进行基本场景时的脚本编写过程。
	同时，它对脚本编写者很有用，因为它包含基本的 SIP
	路由逻辑，使他们能够更多地关注其 OpenSIPS 路由代码的特定方面。


### 工作原理


只需加载模块，以下**默认逻辑**将被嵌入：


- 对于初始 SIP 请求，模块将在运行主*请求*路由之前执行*记录路由*
- 顺序 SIP 请求将被透明处理 - 模块将执行*松散路由*，请求路由根本不会运行


目前，可以进一步配置模块以嵌入以下**可选逻辑**：


- *dialog* 支持（dialog 模块依赖 - 必须在加载此模块之前加载）
- 在转发顺序请求之前运行的额外路由


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *dialog*（仅在启用 **[使用 dialog](#param_use_dialog)** 时）。


#### 外部库或应用程序


以下库或应用程序必须在运行加载了此模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### use_dialog (integer)


启用 dialog 支持。请注意，在设置此参数时，dialog 模块必须在此模块之前加载。


默认值为 0（禁用）


```c title="设置 use_dialog"
...
modparam("script_helper", "use_dialog", 1)
...
```


#### create_dialog_flags (string)


创建对话时使用的标志。有关这些标志的详细信息，请参阅 dialog 模块的 *create_dialog()* 函数。


默认值为 ""（未设置标志）


```c title="设置 create_dialog_flags"
...
modparam("script_helper", "create_dialog_flags", "options-ping-caller,options-ping-callee,bye-on-timeout")
...
```


#### sequential_route (string)


在转发顺序请求之前运行的路由。
		如果在路由内使用了 *exit* 脚本语句，
		模块假定转发逻辑已被处理。


默认情况下，未设置此参数


```c title="设置 sequential_route"
...
modparam("script_helper", "sequential_route", "sequential_handling")
...
route [sequential_handling]
{
...
}
...
```


### 已知问题


Max-Forwards 头目前完全未被处理。
<!-- CONTRIBUTORS -->

### 许可

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0 版授权
