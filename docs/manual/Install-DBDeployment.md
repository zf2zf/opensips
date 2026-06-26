---
title: "数据库部署"
description: "安装 OpenSIPS 后，你很可能还需要部署一个数据库，用于各种用途（DB 用户认证、持久化注册、对话等）。"
---

安装 OpenSIPS 后，你很可能还需要部署一个数据库，用于各种用途（DB 用户认证、持久化注册、对话等）。

---

你可以使用 [opensips-cli](https://github.com/OpenSIPS/opensips-cli) 工具部署 opensips 数据库。在此之前，你应该先[安装它](https://github.com/OpenSIPS/opensips-cli#install)。

## 配置 OpenSIPS CLI

打开你的 OpenSIPS CLI 配置文件并指定以下参数：
* `database_schema_path` -（默认为 `/usr/share/opensips/`）设置为 `[Install_Path]/share/opensips/`
* `database_url` - 连接数据库的 URL（如果未指定，部署期间会提示你输入）
* `database_name` -（默认为 `opensips`）要使用的数据库
* `database_modules` -（默认为标准模块）你要部署的模块。

你可以在此处找到更多关于 OpenSIPS CLI 工具配置的信息[here](https://github.com/OpenSIPS/opensips-cli/blob/master/docs/modules/database.md#configuration)。

> [!NOTE]
> OpenSIPS CLI 在 `~/.opensips-cli.cfg`、`/etc/opensips-cli.cfg`、`/etc/opensips/opensips-cli.cfg` 中搜索配置文件，但你也可以使用 `-f` 参数指定自己的配置文件。

## 创建数据库

要创建你上面配置的 `database_name` 数据库，请运行
```bash

opensips-cli -x database create

```

之后，如果你决定添加新模块，例如 presence，只需调用：
```bash

opensips-cli -x database add presence

```

你也可以指定不同的数据库名称，例如 `opensips_test`，使用：
```bash

opensips-cli -x database create opensips_test

```
