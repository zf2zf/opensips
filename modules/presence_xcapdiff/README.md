---
title: "Presence_XCAPDiff 模块"
description: "presence_xcapdiff 是一个 OpenSIPS 模块，它为 presence 和 pua 添加了对 \"xcap-diff\" 事件的支持。目前，该模块只是注册事件，不进行任何特定于事件的处理。该模块将自动确定 presence 和/或 pua 模块是否存在，如果存在..."
---

## 管理指南


### 概述


presence_xcapdiff 是一个 OpenSIPS 模块，它为 presence 和 pua 添加了对
      "xcap-diff" 事件的支持。目前，该模块只是注册事件，不进行任何特定于事件的处理。
      该模块将自动确定 presence 和/或 pua 模块是否存在，
      如果存在，它将向其注册 xcap-diff 事件。
      这允许模块仅基于 OpenSIPS 配置中存在上述模块，
      自动提供 presence 或 pua 相关功能，无需任何手动配置。


向 pua 注册事件允许 XCAP 服务器在文档发生某些修改时发布 xcap-event。
      向 presence 注册事件允许客户端订阅该事件。


该模块旨在与 OpenXCAP 服务器（www.openxcap.org）一起使用，
      尽管它不包含任何 OpenXCAP 特定代码，应该可以与任何 XCAP 服务器一起使用。


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *presence* 模块 - 允许客户端订阅 xcap-diff 事件包。
- *pua* 模块 - 能够在文档发生某些修改时发布 xcap-diff 事件。
- *pua_mi* 模块 - 允许 pua 通过 MI 接口发布 xcap-diff 事件。
		如果此模块旨在与 OpenXCAP 结合使用，则需要此模块。


#### 外部库或应用程序


必须在运行加载了此模块的 OpenSIPS 之前安装以下库或应用程序：


- *无*。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
