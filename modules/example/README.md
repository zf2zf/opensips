---
title: "示例模块"
description: "本模块作为如何在 OpenSIPS 中编写模块的示例。其主要目的是简化新模块的开发,为新手提供清晰易懂的起点。"
---

## 管理指南


### 概述


本模块作为如何在 OpenSIPS 中编写模块的示例。
		其主要目的是简化新模块的开发,
		为新手提供清晰易懂的起点。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他 OpenSIPS 模块*。


#### 外部库或应用程序


以下库或应用程序必须在运行
		加载本模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### default_str (string)


当 [example str](#func_example_str) 函数被调用时
		未带任何参数时使用的默认参数。


*默认值为 ""（空字符串）。*


```c title="设置 'default_str' 参数"
...
modparam("example", "default_str", "TEST")
...
```


#### default_int (integer)


当 [example int](#func_example_int) 函数被调用时
		未带任何参数时使用的默认参数。


*默认值为 "0"。*


```c title="设置 'default_int' 参数"
...
modparam("example", "default_int", -1)
...
```


### 导出的函数


#### example()


该函数只是向日志打印一条消息,表明它已被调用。


此函数可用于任何路由。


```c title="example 使用示例"
...
example();
...
```


#### example_str([string])


该函数只是向日志打印一条消息,表明它已被调用。
		如果传入了参数,则将其打印到日志中,否则使用
		[default str](#param_default_str) 参数的值。


参数含义如下：


- *string (string, 可选)* - 要记录的参数


此函数可用于任何路由。


```c title="example_str() 使用示例"
...
example_str("test");
...
```


#### example_int([int])


该函数只是向日志打印一条消息,表明它已被调用。
		如果传入了参数,则将其打印到日志中,否则使用
		[default int](#param_default_int) 参数的值。


参数含义如下：


- *int (integer, 可选)* - 要记录的参数


此函数可用于任何路由。


```c title="example_int() 使用示例"
...
example_int(10);
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权
