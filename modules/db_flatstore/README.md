---
title: "Flatstore 模块"
description: "Flatstore 是所谓的 OpenSIPS 数据库模块之一。它不导出任何可从配置脚本执行的函数，但它导出了数据库 API 的一个子集，因此其他模块可以使用它来替代，例如 mysql 模块。"
---

## 管理指南


### 概述


Flatstore 是所谓的 OpenSIPS 数据库模块之一。它不导出
任何可从配置脚本执行的函数，但
它导出了数据库 API 的一个子集，因此
其他模块可以使用它来替代，例如 mysql 模块。


该模块不导出数据库 API 的所有功能，它
只支持一个函数，即 insert。该模块功能有限但非常
快速。它特别适用于存储极高流量的站点的计费信息。
如果 MySQL 太慢或者您收到大量计费数据，那么您可以考虑
使用此模块。请注意，acc 模块是唯一经过测试的
使用 flastore 的模块。


该模块生成的文件的格式是纯文本。每一
行由多个字段组成，字段默认由
| 字符分隔。新信息总是附加在文件
末尾，该模块不支持搜索、删除和更新现有数据。


acc 模块可以配置为使用 flatstore 模块作为
数据库后端，使用 db_url_parameter：


```c
modparam("acc", "db_url", "flatstore:/var/log/acc")
```


此配置选项告诉 acc 模块它应该使用
flatstore 模块，flatstore 模块应在
/var/log/acc 目录中创建所有文件。该目录必须存在，OpenSIPS
进程必须有权限在该目录中创建文件。


该目录中文件的名称遵循以下模式：


```c
<prefix><table_name>[_<process_name>]<suffix>
```


例如，在不设置任何模块参数的情况下，
OpenSIPS 进程 8 写入 acc 表的条目将
被写入文件 acc_8.log。每个表会有多个
文件，每个 OpenSIPS 进程写入该表的一些数据
就有一个文件。每个表有多个文件的主要原因是
每个进程一个文件会更快，因为它不需要任何锁定，
因此 OpenSIPS 进程不会相互阻塞。要获取表的完整数据，
您可以简单地将具有相同表名但不同进程 ID 的文件内容连接起来。
或者，您可以使用 single_file 参数，所有进程会将数据写入同一文件。请注意，
这会带来一些延迟。


#### 轮转日志文件


有一个新的 OpenSIPS MI（管理接口）命令称为
db_flatstore:rotate。
当 OpenSIPS 接收到命令时，它将关闭并重新打开 flatstore 模块使用的所有
文件。轮转本身必须由另一个应用程序（如 logrotate）完成。遵循
以下步骤来轮转 flatstore 模块生成的文件：


- 重命名要轮转的文件：
			
```c

cd /var/log/acc
mv acc_1.log acc_1.log.20050605
mv acc_2.log acc_2.log.20050605
mv acc_4.log acc_3.log.20050605
...
```
请注意，此时 OpenSIPS 仍将所有数据写入
重命名的文件。
- 向 OpenSIPS 发送 MI 命令以关闭并重新打开
重命名的文件。例如，使用 FIFO：
			
```c

opensips-cli -x mi flat_rotate
```

这将强制 OpenSIPS 关闭重命名的文件并打开
具有原始名称的新文件，如
`acc_1.log`。新文件将在 OpenSIPS 有一些数据要写入时打开。
如果代理服务器上没有流量，文件不会立即创建，这是
正常的。请注意，每次执行 flat_rotate 命令时会重新评估后缀和前缀参数。因此，
轮转命令之后，可能会打开与之前不同的文件。
- 将重命名的文件移动到其他地方并处理它们。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他 OpenSIPS 模块*。


#### 外部库或应用程序


以下库或应用程序必须在运行
加载了此模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### flush (integer)


启用或禁用每次写入后刷新。


*默认值为 1。*


```c title="设置 'flush' 参数"
...
modparam("db_flatstore", "flush", 0)
...
```


#### delimiter (char)


用于分隔值的分隔符。


*默认值为 '|'。*


```c title="设置 'delimiter' 参数"
...
modparam("db_flatstore", "delimiter", ";")
...
```


#### suffix (string)


追加到表名的后缀。可以是伪
变量。


*默认值为 ".log"。*


```c title="设置 'suffix' 参数"
...
modparam("db_flatstore", "suffix", "$time(%H)")
...
```


#### prefix (string)


表名前缀。可以是伪变量。


*默认值为无。*


```c title="设置 'prefix' 参数"
...
modparam("db_flatstore", "prefix", "$time(%H)")
...
```


#### single_file (integer)


指定所有进程是否应将数据
写入单个文件。


*默认值为 0。*


```c title="设置 'single_file' 参数"
...
modparam("db_flatstore", "single_file", 1)
...
```


### 导出的函数


路由脚本中没有导出函数。


### 导出的 MI 函数


#### db_flatstore:rotate


替换过时的 MI 命令：*flat_rotate*。


它更改写入文件的名称。


名称：*db_flatstore:rotate*


参数：*无*


MI FIFO 命令格式：


```c
		opensips-cli -x mi db_flatstore:rotate
		
```


## 开发者指南


该模块实现了 DB API。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0
