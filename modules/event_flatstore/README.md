---
title: "event_flatstore 模块"
description: "*event_flatstore* 模块提供了一种日志记录功能，用于记录通过 OpenSIPS Event Interface 从 OpenSIPS 脚本触发的不同事件。该模块将事件及其参数以纯文本文件形式记录。"
---

## 管理指南


### 概述


*event_flatstore* 模块提供了一种日志记录功能，用于记录通过 OpenSIPS Event Interface 从 OpenSIPS 脚本触发的不同事件。该模块将事件及其参数以纯文本文件形式记录。


### Flatstore 套接字语法


*flatstore:path_to_file*


含义：


- *flatstore:* - 通知 Event Interface，发送到此订阅者的事件应由 *event_flatstore* 模块处理。
- *path_to_file* - 将记录事件追加到的文件路径。如果文件不存在，将创建该文件。它必须是有效路径，不能是目录。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他 OpenSIPS 模块*。


### 外部库或应用程序


运行加载此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *无*


### 导出的参数


#### max_open_sockets (integer)


定义模块同时打开的最大文件数。如果达到最大限制，将抛出错误消息，只有当前订阅中至少一个过期后才能进行进一步订阅。


*默认值为 "100"。*


```c title="设置 max_open_sockets 参数"
...
modparam("event_flatstore", "max_open_sockets", 200)
...
```


#### delimiter (string)


设置日志文件中事件参数之间的分隔符。


*默认值为 ","。*


```c title="设置 delimiter 参数"
...
modparam("event_flatstore", "delimiter", ";")
...
```


#### escape_delimiter (string)


可选的替换序列，当字符串参数中包含 [`delimiter`](#param_delimiter) 字符（或序列）时，将写入*替代* [`delimiter`](#param_delimiter)。
			这允许您在用户数据本身可能包含分隔符符号时保持日志文件可解析。


如果设置，其长度*必须恰好等于* `delimiter` 的长度。


*默认值为 """"（转义禁用）。*


```c title="启用 ',' 用 '|' 转义"
...
modparam("event_flatstore", "delimiter", ",")
modparam("event_flatstore", "escape_delimiter", "|")
...
	
```


#### file_permissions (string)


设置新创建的日志文件的权限。它期望八进制值的字符串表示。


*默认值为 "644"。*


```c title="设置 file_permissions 参数"
...
modparam("event_flatstore", "file_permissions", "664")
...
```


#### suppress_event_name (int)


禁止在日志文件中显示事件名称。


*默认值为 "0/关闭"（打印事件名称）。*


```c title="设置 suppress_event_name 参数"
...
modparam("event_flatstore", "suppress_event_name", 1)
...
```


#### rotate_period (int)


使用时，会触发文件自动轮换。该周期与机器的绝对时间匹配，可用于触发每分钟或每小时自动轮换。


*默认值为 "0/关闭"（文件从不自动轮换）*


```c title="设置 rotate_period 参数"
...
modparam("event_flatstore", "rotate_period", 60) # 每分钟轮换
modparam("event_flatstore", "rotate_period", 3660) # 每小时轮换
...
```


#### rotate_count (int|string)


定义日志文件轮换前的写入行数。该值可能超过 32 位整数限制；如果是这种情况，请*作为字符串*传递，例如 "5000000000"。


*默认值为 "0/关闭"。*


```c title="五十亿行后轮换"
...
modparam("event_flatstore", "rotate_count", "5000000000")
...
		
```


#### rotate_size (int|string)


设置文件轮换前的最大大小。可以提供 "k"、"m" 或 "g" 的文件大小后缀（1024 的倍数）。
		可以用字符串提供非常大的值，例如 "8589934592" 表示 8 GiB。


*默认值为 "0/关闭"。*


```c title="2 GiB 时轮换"
...
modparam("event_flatstore", "rotate_size", "2g")
...
```


#### suffix (string)


通过在 flatstore *socket* 中指定的文件追加后缀来修改 OpenSIPS 写入事件的文件。


后缀可以包含字符串格式（即与字符串混合的变量）。生成文件的路径在重新加载后第一次引发/写入文件的事件时进行评估，或者当 *rotate_period*（如果指定）触发轮换时进行评估。


此参数不影响事件套接字的匹配——匹配将仅使用注册的 flatstore *socket* 进行。


*默认值为 """"（不添加后缀）*


```c title="设置 suffix 参数"
...
modparam("event_flatstore", "suffix", "$time(%Y)")
...
```


### 导出的函数


没有可从配置文件使用的导出函数。


### 导出的 MI 函数


#### event_flatstore:rotate


替换已弃用的 MI 命令：*evi_flat_rotate*。


它使进程重新打开文件作为参数指定的命令以与 logrotate 命令兼容。如果在执行 mv 命令后未调用该函数，模块将继续写入重命名的文件。


名称：*event_flatstore:rotate*


参数：*path_to_file*


MI FIFO 命令格式：


```c
opensips-cli -x mi event_flatstore:rotate _path_to_log_file_
	
```


### 导出的事件


#### E_FLATSTORE_ROTATION


每次 *event_flatstore* 打开新日志文件时都会引发此事件（手动 `event_flatstore:rotate`、由 `rotate_period` 自动轮换，或由 `rotate_count`/`rotate_size` 阈值触发）。
		外部应用程序可以订阅以监控日志轮换活动。


参数：


- *timestamp* – 执行轮换的 Unix 时间戳（秒）。
- *reason* – 以下字符串之一：*count*、*size*、*period* 或 *mi*。
- *filename* – 新日志文件的完整路径。
- *old_filename* – 之前日志文件的完整路径，如果没有则为空字符串。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用 Creative Common License 4.0 许可证
