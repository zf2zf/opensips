---
title: "状态/报告模块"
description: "状态/报告模块是内部状态/报告框架的包装器，允许脚本编写者动态定义和使用 SR 组。"
---

## 管理指南


### 概述


状态/报告模块是内部状态/报告框架的包装器，
		允许脚本编写者动态定义和使用 SR 组。


通过将状态/报告支持引入脚本，它开启了从脚本创建自定义报告的可能性，
		具体取决于您在那里的逻辑。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他 OpenSIPS 模块*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### script_sr_group (string)


要创建并在脚本级别稍后使用的状态/报告组的名称。


可以多次定义此参数，以定义多个组。


```c title="script_sr_group 示例"
modparam("status_report", "script_sr_group", "security")
modparam("status_report", "script_sr_group", "alarms")
```


### 导出的函数


#### sr_set_status( group, status, [details])


为状态/报告组设置新状态（及详情）。


参数的含义如下：


- *group* (string) - SR 组的名称；
			您只能更改通过此模块定义的组的状态（作为参数）。
- *status* (int) - 新状态值
			（严格正值表示 OK，严格负值表示 NOT OK，
			0 不被接受，会自动转换为 1）。
- *details* (string, 可选) - 
			描述状态值的文本


此函数可用于任何路由。


```c title="sr_set_status 使用示例"
...
sr_set_status( "script_caching", 1, "completed");
...
```


#### sr_add_report( group, report)


向状态/报告组添加新报告/日志。这同样必须通过此模块定义。


参数的含义如下：


- *group* (string) - SR 组的名称；
			您只能更改通过此模块定义的组的状态（作为参数）。
*report* (string) - 要添加的日志。


此函数可用于任何路由。


```c title="sr_add_report 使用示例"
...
sr_add_report("security","检测到攻击者 IP $si");
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
