---
title: "Python 模块"
description: "此模块可用于直接从 OpenSIPS 脚本高效运行 Python 代码，而无需执行 *python* 解释器。"
---

## 管理指南


### 概述


此模块可用于直接从 OpenSIPS 脚本高效运行 Python 代码，而无需执行 *python* 解释器。


该模块提供了加载 Python 模块并运行其函数的方法。每个函数必须接收 SIP 消息作为参数，以及可选的一些从脚本传递的额外参数。


要运行 Python 函数，必须通过使用 *script_name* 参数指定脚本名称来加载包含这些函数的模块。该模块必须包含以下组件：


- 一个包含所有可从脚本调用方法的类。
- 类中有一个方法，在创建 SIP 子进程时调用。该方法应接收一个整数参数，表示子进程的 rank，并在成功执行时返回 0 或正数，否则返回负数。此方法的名称由 *child_init_method* 参数指定。
- 一个初始化 Python 模块并返回将从中调用函数的类对象的全局函数。全局函数的名称由 *mod_init_method* 参数指定。


满足这些要求的 Python 脚本最小示例如下：


```c
	def mod_init():
		return SIPMsg()

	class SIPMsg:
        def child_init(self, rank):
		return 0
		
```


可从上述对象执行的函数使用 *python_exec()* 脚本函数。Python 方法必须接收以下参数：


- SIP 消息，具有如下详述的结构
- 可选的，从脚本传递的字符串


作为参数接收的 SIP 消息具有以下字段和方法：


- *Type* - 消息的类型，为 *SIP_REQUEST* 或 *SIP_REPLY* 之一
- *Method* - 消息的方法
- *Status* - 消息的状态，仅适用于回复
- *RURI* - 消息的 R-URI，仅适用于请求
- *src_address* - 表示消息源地址的 (IP, port) 元组
- *dst_address* - 表示消息目标地址（OpenSIPS 地址）的 (IP, port) 元组
- *copy()* - 将当前 SIP 消息复制到新对象中
- *rewrite_ruri()* - 更改消息的 R-URI；仅适用于请求
- *set_dst_uri()* - 设置消息的目标 URI；仅适用于请求
- *getHeader()* - 返回消息的 header
- *call_function()* - 调用内置脚本函数或其他模块导出的函数
- *get_pseudoVar(name)* - 返回由 *name* 指定的伪变量值作为 Unicode 字符串。
- *set_pseudoVar(name, value)* - 使用 Unicode 字符串 *value* 设置伪变量。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *无*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *python-dev* - 提供 Python 绑定。


### 导出的参数


#### script_name (string)


包含 Python 模块的脚本。


*默认值为 "/usr/local/etc/opensips/handler.py"。*


```c title="设置 script_name 参数"
...
modparam("python", "script_name", "/usr/local/bin/opensips_handler.py")
...
```


#### mod_init_function (string)


用于初始化 Python 模块并返回对象的方法。


*默认值为 "mod_init"。*


```c title="设置 mod_init_function 参数"
...
modparam("python", "mod_init_function", "module_initializer")
...
```


#### child_init_method (string)


为每个子进程调用的方法。


*默认值为 "child_init"。*


```c title="设置 child_init_method 参数"
...
modparam("python", "child_init_method", "child_initializer")
...
```


### 导出的函数


#### python_exec(method_name [, extra_args])


此函数用于执行加载的 Python 模块中的方法。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE 和 BRANCH_ROUTE。


参数的含义如下：


- *method_name* (字符串) - 被调用方法的名称
- *extra_args* (字符串，可选) - 可从脚本传递给 python 函数的额外参数。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0（Creative Common License 4.0）授权。
