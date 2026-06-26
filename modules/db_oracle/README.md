---
title: "Oracle 模块"
description: "这是一个为 OpenSIPS 提供 Oracle 连接功能的模块。它实现了 OpenSIPS 中定义的 DB API。如果您想使用 nathelper 模块，或任何其他调用 usrloc 中 get_all_ucontacts API 的模块，则需要在编译前在 Makefile.defs 文件中设置 *DORACLE_USRLOC* 定义。"
---

## 管理指南

### 概述

这是一个为 OpenSIPS 提供 Oracle 连接功能的模块。它实现了 OpenSIPS 中定义的 DB API。如果您想使用 nathelper 模块，或任何其他调用 usrloc 中 get_all_ucontacts API 的模块，则需要在编译前在 Makefile.defs 文件中设置 *DORACLE_USRLOC* 定义。

### 依赖

#### OpenSIPS 模块

以下模块需要在此模块之前加载：

- *不依赖其他 OpenSIPS 模块*。

#### 外部库或应用程序

运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：

- *instantclient-sdk-10.2.0.3* - OCI 的开发头文件和库。

### 导出的参数

#### timeout (fixedpoint)

任何数据库操作的超时值。

可能的值范围为 0.1 到 10.0 秒。

*默认值为 3.0（3 秒）。*

如果 timeout 参数设置为 0，模块使用同步模式（无超时）。

```c title="设置 timeout 参数"
...
modparam("db_oracle", "timeout", 1.5)
...
```

```c title="禁用异步模式"
...
modparam("db_oracle", "timeout", 0)
...
```

#### reconnect (fixedpoint)

连接（创建会话）操作的超时值。

可能的值范围为 0.1 到 10.0 秒。

*默认值为 0.2（200 毫秒）。*

```c title="设置 reconnect 参数"
...
modparam("db_oracle", "reconnect", 0.5)
...
```

### 导出的函数

配置文件中没有导出可使用的函数。

### 安装

由于依赖外部库，oracle 模块默认不会被编译和安装。您可以使用以下选项之一：

- 编辑 "Makefile" 并从 "excluded_modules" 列表中删除 "db_oracle"。然后按照标准程序安装 OpenSIPS："make all; make install"。
- 从命令行使用：'make all include_modules="db_oracle"; make install include_modules="db_oracle"'。

### 工具 opensips_orasel

为了让 opensips-cli 工具能够以用户可读的形式将 'query' 结果打印到终端。标准的命令行 Oracle 客户端（sqlplus）不太适合此用途，因为它无法将列宽与实际（接收到的）数据对齐（它总是按照数据库方案中描述的列宽打印）。这个问题通过包含工具 opensips_orasel 得到了解决，它格式化输出的方式与 'mysql' 客户端工具大致相同。此外，此工具了解 OpenSIPS 中用于 Oracle 工作的数据库"协议和类型"，并在格式化输出时考虑这些因素。

<!-- 贡献者 -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0 版授权。
