---
title: "配置模块"
description: "*config* 模块通过在启动时从持久存储加载配置参数并在脚本级别通过 [config](#pv_config) 伪变量公开，从而实现 OpenSIPS 参数的动态运行时配置。"
---

## 管理指南

### 概述

*config* 模块通过在启动时从持久存储加载配置参数并在脚本级别通过 [config](#pv_config) 伪变量公开，从而实现 OpenSIPS 参数的动态运行时配置。

所有配置变量都存储在 OpenSIPS 内部缓存中，允许在 SIP 处理期间快速访问以保持高性能。缓存可以通过三种方式更新：

- *脚本* – 给 [config](#pv_config) 伪变量赋值会更新内存缓存，但此更改不会持久化到数据库。
- *MI 命令* – 使用 [mi push](#mi_push) 或 [mi push bulk](#mi_push_bulk) 可以在运行时缓存中更新一个或多个变量。这些更新也不会保存到数据库。
- *数据库* – 手动修改数据库中的值，然后触发 [mi reload](#mi_reload) 命令，将使用数据库中的更新值刷新内存缓存。

#### 重启持久内存

默认情况下，配置缓存在启动时通过从数据库读取来初始化，仅在运行时保持。任何通过脚本或 MI 命令进行的临时更改（未使用 [mi flush](#mi_flush) 命令明确刷新到数据库）在重启后将丢失。

在这种情况下，重启持久内存变得有用。通过 [enable rpm](#param_enable_restart_persistency) 参数启用后，OpenSIPS 不再在启动时从数据库加载配置值。相反，它会恢复先前保存的内存缓存，保留跨重启的运行时更改。

如果需要，您仍可以通过运行 [mi reload](#mi_reload) MI 命令从数据库手动重新初始化缓存。

### 依赖

#### OpenSIPS 模块

以下模块必须在此模块之前加载：

- *需要数据库模块来读取初始缓存。*

#### 外部库或应用程序

运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：

- *无*。

### 导出的参数

#### db_url (string)

用于加载初始配置值并在运行时使用 [mi flush](#mi_flush) MI 命令刷新它们的数据库 URL。

*默认值为 "mysql://opensips:opensipsrw@localhost/opensips"。*

```c title="设置 'db_url' 参数"
...
modparam("config", "db_url", "dbdriver://username:password@dbhost/dbname")
...
```

#### table_name (string)

存储配置项的表名。

*默认值为 "config"。*

```c title="设置 'table_name' 参数"
...
modparam("config", "table_name", "configuration")
...
```

#### name_column (string)

存储配置变量名的列名。

*默认值为 "name"。*

```c title="设置 'name_column' 参数"
...
modparam("config", "name_column", "key")
...
```

#### value_column (string)

存储配置变量值的列名。

*默认值为 "value"。*

```c title="设置 'value_column' 参数"
...
modparam("config", "value_column", "val")
...
```

#### description_column (string)

存储变量描述的列名。

*默认值为 "description"。*

```c title="设置 'desctiption_column' 参数"
...
modparam("config", "description_column", "desc")
...
```

#### enable_restart_persistency (integer)

启用重启持久性。有关详细信息，请参阅[重启持久内存](#restart_persistent_memory)。

*默认值为 "0 / 禁用"。*

```c title="设置 'restart-persistent-memory' 参数"
...
modparam("config", "restart-persistent_memory", yes)
...
```

#### hash_size (integer)

用于存储配置变量的内部哈希表的大小。必须是 2 的幂次方，否则其值将四舍五入到小于所提供值的最接近的 2 的幂次方。

*默认值为 "16"。*

```c title="设置 'hash_size' 参数"
...
modparam("config", "hash_size", 32)
...
```

### 导出的伪变量

#### $config(name)

按名称返回给定配置变量的值。也可用于临时更改值。

```c title="$config(...) 用法"
			...
			xlog("配置值: $config(debug_mode)\n"); # 读取值
			$config(debug_mode) = 1; # 临时更改值
			...
			
```

#### $config.description(name)

如果可用，返回配置变量的描述。

此变量是只读的。

```c title="$config.description(name) 用法"
			...
			xlog("描述: $config.description(debug_mode)\n");
			...
			
```

### 导出的 MI 函数

#### config:reload

替换已弃用的 MI 命令：*config_reload*。

从数据库重新加载所有配置变量。

MI FIFO 命令格式：

```c
		## 从数据库重新加载配置缓存
		opensips-mi config:reload
		opensips-cli -x mi config:reload
		
```

#### config:list

替换已弃用的 MI 命令：*config_list*。

列出当前缓存中加载的所有配置变量，也打印临时值。如果提供了可选的 *description* 参数且不同于 *0*，则返回一个数组，也包含值的描述。

MI FIFO 命令格式：

```c
		## 列出所有配置缓存
		opensips-mi config:list
		opensips-cli -x mi config:list 1
		
```

#### config:push

替换已弃用的 MI 命令：*config_push*。

临时推送单个配置变量。

预期参数：

- *name* – (string) 变量名
- *value* – (string) 变量值
- *description* – (string，可选) 变量描述；如果缺失则继承描述，或者如果变量是新变量则使用空值。

MI FIFO 命令格式：

```c
		## 临时推送 debug_mode 配置值
		opensips-mi config:push debug_mode 1 "启用调试模式"
		opensips-cli -x mi config:list 1
		
```

#### config:push_bulk

替换已弃用的 MI 命令：*config_push_bulk*。

将多个临时配置变量推送到内存中。

预期参数：

- *configs* – (json) 一个 JSON 数组，包含要推送的一组变量。每个变量应描述为一个 JSON 对象，包含以下键：
	
	*name* – (string) 要更改的变量名。
	
	*value* – (string 或 null) 变量的新值。
	
	*description* – (string，可选) 变量描述。

MI FIFO 命令格式：

```c
		## 临时批量推送配置缓存值
		opensips-mi config:push_bulk -j '[[{"name":"debug_mode","value":"1"},{"name":"debug_level","value":"5"}]]'
		
```

该命令返回成功推送的值数量。

#### config:flush

替换已弃用的 MI 命令：*config_flush*。

将变量从内存刷新到数据库。

预期参数：

- *name* – (string，可选) 如果存在，仅刷新数据库中的特定配置变量，否则刷新整个缓存。

MI FIFO 命令格式：

```c
		## 将配置变量刷新到数据库
		opensips-mi config:flush
		opensips-cli -x mi config:flush debug_mode
		
```

该命令返回成功刷新的值数量。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
