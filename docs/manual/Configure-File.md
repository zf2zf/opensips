---
title: "配置文件"
description: "OpenSIPS 配置文件包含控制 OpenSIPS 核心和模块的所有参数，以及 OpenSIPS 用于路由 SIP 流量的实际路由逻辑。"
---

OpenSIPS 配置文件包含控制 OpenSIPS 核心和模块的所有参数，以及 OpenSIPS 用于路由 SIP 流量的实际路由逻辑。

  

安装后，默认配置文件路径为：

```text

[INSTALL_PATH]/etc/opensips/opensips.cfg

```

  

配置文件是基于文本的，使用 OpenSIPS 自定义语言编写，与 C 语言非常相似。您会发现不同的变量（每个变量有不同的作用域——在手册下文中有详细解释），您可以使用经典的构造如 if / while / switch 等，您还可以调用带参数的子程序，因此对于具备一些 SIP 和编程技能的人来说，阅读脚本应该相当容易。

  

> [!IMPORTANT]
> 如果您对配置文件进行了任何更改，为了使更改生效，您必须重启 OpenSIPS

  

由于每次对配置文件进行更改时都必须重启 OpenSIPS，因此确保您所做的所有更改符合 OpenSIPS 语言语法至关重要。

您可以通过运行以下命令来检查 OpenSIPS 配置文件的有效性：

  

```text

[INSTALL_PATH]/sbin/opensips -C [PATH_TO_CFG]

```

  

检查配置文件有效性时，如果 cfg 正常，OpenSIPS 将返回 0。

  

如果配置文件包含任何错误，它们将显示在控制台上，OpenSIPS 将返回 -1
