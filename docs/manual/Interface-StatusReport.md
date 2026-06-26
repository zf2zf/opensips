---
title: "状态/报告接口"
description: "状态/报告（SR）是 OpenSIPS 的一个框架，允许 OpenSIPS 的不同组件（如模块、核心部分）发布其状态（就绪状态）和与其活动相关的报告（日志）。"
---

**状态/报告**（**SR**）是 OpenSIPS 的一个框架，允许 OpenSIPS 的不同组件（如模块、核心部分）发布其状态（就绪状态）和与其活动相关的报告（日志）。

该框架旨在用于运维活动，在 OpenSIPS 启动时检查其就绪状态、在运行时监控其状态，以及通过日志/报告追溯其操作。

## 概述

**状态/报告**框架中的基本元素是*标识符*——状态和报告可以附加到标识符上。所有标识符都存在于**状态/报告**组中。因此，一个组是一组标识符——模块或核心可以是这样的组。例如，*drouting* 模块发布 *drouting* 组，其中每个路由分区是一个*标识符*。

由于某些情况下组（模块）不需要多个标识符，因此存在一个默认的*主*标识符——这样的标识符只能通过组名来引用。

附加到标识符的信息包括：
* **状态**——整数值，表示标识符是否就绪可操作；严格的负值表示未就绪，严格的正值表示就绪；零值不被接受。
* **状态详情**——状态的可选文本，提供当前状态的一些人性化（或详细）信息。
* **报告**——固定大小的数组（更像是一个丢弃最旧记录的队列），包含标识符生成的日志。每个报告/日志都带有时间戳。

在大多数情况下，标识符的状态和报告由 OpenSIPS 代码内部生成——**状态/报告**接口只是让你从代码外部访问状态/报告信息，用于监控目的。

---

## 脚本函数

SR 接口提供了一个脚本函数来检查标识符（或整个组）的就绪状态，参见 [sr_check_status( group, \[identifier\])](https://docs.opensips.org/manual/devel/script-corefunctions#sr_check_status) 函数。

---

## MI 函数

SR 接口提供了多个函数来检查/列出单个或多个标识符的状态，并列出其报告：
* [sr_get_status](https://docs.opensips.org/manual/devel/interface-coremi#sr_get_status)
* [sr_list_status](https://docs.opensips.org/manual/devel/interface-coremi#sr_list_status)
* [sr_list_reports](https://docs.opensips.org/manual/devel/interface-coremi#sr_list_reports)
* [sr_list_identifiers](https://docs.opensips.org/manual/devel/interface-coremi#sr_list_identifiers)

---

## 事件

每当状态/报告标识符的状态发生变化时，SR 框架会引发一个事件。参见 [E_CORE_SR_STATUS_CHANGED 事件](https://docs.opensips.org/manual/devel/interface-coreevents#E_CORE_SR_STATUS_CHANGED) 了解更多详情。

---

## 核心标识符

OpenSIPS 核心提供 **core** 组，带有一个"主"（默认）标识符。可用的状态包括：
* STATE_NONE (-100) - OpenSIPS 刚刚启动
* STATE_TERMINATING (-2) - OpenSIPS 正在关闭
* STATE_INITIALIZING (-1) - OpenSIPS 正在启动
* STATE_RUNNING (1) - OpenSIPS 完全启动并运行

此外，**auto-scaling** 组也会被暴露（如果启用了自动扩展功能），其中每个自动扩展组是一个状态/报告标识符。每个标识符都会收到该自动扩展组中进程分叉或剥离的报告。

---

## 模块标识符

OpenSIPS 模块可能提供或不提供自己的组和标识符。为此，你需要查看模块的文档。

---

## 脚本标识符

[status_report](../../modules/status_report/README.md) 允许在脚本层面创建自定义 SR 标识符。更进一步，还可以为这些自定义标识符设置状态或发布报告。
