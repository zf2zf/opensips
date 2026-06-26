---
title: "编译和安装"
description: "使用 Makefile.conf 从源代码编译和安装 OpenSIPS。"
---

本页面面向从源代码编译 OpenSIPS 的用户。二进制软件包应使用操作系统提供的包管理器安装。

## 配置构建

构建设置存储在仓库根目录的 `Makefile.conf` 中。第一次调用 `make` 时，如果该文件不存在，会从 `Makefile.conf.template` 创建它。要显式准备它：

```bash
cp Makefile.conf.template Makefile.conf
```

在编译前编辑 `Makefile.conf`。保留此文件以供后续重新构建；它故意不被 Git 跟踪。

### 选择模块

`exclude_modules` 列出从常规 `modules` 和 `all` 目标中省略的模块。默认列表主要包含有外部依赖的模块。在安装其开发依赖后从列表中移除模块，或将其添加到 `include_modules` 以强制将其纳入构建而无需重写默认排除列表：

```make
include_modules += db_mysql json
```

你可以显式排除额外的模块：

```make
exclude_modules += cachedb_redis event_rabbitmq
```

对于命名模块，`include_modules` 优先。模块名称是 `modules/` 下的目录名称。

对于一次性的构建，相同的变量可以在命令行上提供：

```bash
make -j4 modules include_modules="db_mysql json"
make -j4 modules skip_modules="cachedb_redis event_rabbitmq"
```

### 调整编译器和链接器标志

使用 `CC_EXTRA_OPTS` 和 `LD_EXTRA_OPTS` 添加额外的编译器和链接器选项：

```make
CC_EXTRA_OPTS += -O2 -march=native
LD_EXTRA_OPTS += -Wl,--as-needed
```

使用 `DEFS` 设置 OpenSIPS 编译时定义。`Makefile.conf.template` 包含支持的定义及简短描述。取消注释以启用已禁用的定义，或显式添加定义：

```make
DEFS += -DEXTRA_DEBUG
DEFS += -DSHM_EXTRA_STATS
```

只启用了解其行为的标志。某些分配器和锁定定义是互斥的，或实质性影响运行时性能。更改编译器标志或编译时定义后重新构建前运行 `make proper`。

### 配置安装前缀

在 `Makefile.conf` 中设置 `PREFIX` 以更改默认安装根目录：

```make
PREFIX ?= /opt/opensips/
```

编译和安装使用相同的前缀，因为默认配置路径被编译到 OpenSIPS 二进制文件中。

## 编译

构建核心和选定的模块：

```bash
make -j4 all
```

有用的更窄目标：

```bash
make -j1                 # 仅核心二进制文件
make -j4 modules         # 仅选定的模块
make -j1 modules module=db_mysql
```

## 安装

使用 `Makefile.conf` 中的设置安装核心、选定的模块、文档和数据库模式：

```bash
make install
```

命令行变量覆盖相应配置以进行一次性操作。向构建和安装步骤传递相同的值。
