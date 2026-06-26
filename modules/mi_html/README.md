---
title: "mi_html 模块"
description: "此模块为OpenSIPS的管理接口提供了一个极简的Web用户界面。"
---

## 管理指南


### 概述


此模块为OpenSIPS的管理接口提供了一个极简的Web用户界面。


MI命令的参数必须以json数组格式给出。例如，要获取所有统计信息，参数应给出为[["all"]]。要仅获取dialog和tm统计信息，参数应给出为[["dialog:","tm:"]]。


### 待办事项


未来要添加的功能：


- 连接身份验证的可能性。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *httpd* 模块。


### 导出的参数


#### root(string)


指定HTTP请求的根路径。MI Web界面的链接必须使用以下模式构建：
	http://[opensips_IP]:[opensips_mi_port]/[root]


*默认值为"mi"。*


```c title="设置 root 参数"
...
modparam("mi_html", "root", "opensips_mi")
...
```


#### http_method(integer)


指定要使用的HTTP请求方法：


- 0 - 使用GET HTTP请求
- 1 - 使用POST HTTP请求


*默认值为0。*


```c title="设置 http_method 参数"
...
modparam("mi_html", "http_method", 1)
...
```


#### trace_destination (string)


跟踪模块中定义的跟踪目标。目前唯一的跟踪模块是**proto_hep**。跟踪的MI消息将发送到此处。


**警告：**必须加载跟踪模块此参数才能工作。（例如**proto_hep**）。


*默认值为无（未定义）。*


```c title="设置 trace_destination 参数"
...
modparam("proto_hep", "trace_destination", "[hep_dest]10.0.0.2;transport=tcp;version=3")

modparam("mi_html", "trace_destination", "hep_dest")
...
```


#### trace_bwlist (string)


根据黑名单或白名单过滤跟踪的MI命令。必须定义**trace_destination**此参数才有意义。白名单可以使用'w'或'W'定义，黑名单使用'b'或'B'。类型与实际黑名单之间用':'分隔。列表中的MI命令必须用','分隔。


定义黑名单意味着所有未被列入黑名单的命令都将被跟踪。定义白名单意味着所有未被列入白名单的命令都不会被跟踪。
**警告：**不能同时定义白名单和黑名单。只允许其中一种。第二次定义参数将覆盖第一个。


**警告：**必须加载跟踪模块此参数才能工作。（例如**proto_hep**）。


*默认值为无（未定义）。*


```c title="设置 trace_destination 参数"
...
## 黑名单ps和which MI命令
## 所有其他命令将被跟踪
modparam("mi_html", "trace_bwlist", "b: ps, which")
...
## 只允许sip_trace MI命令
## 所有其他命令都不会被跟踪
modparam("mi_html", "trace_bwlist", "w: sip_trace")
...
```


### 导出的函数


没有导出到配置文件使用的函数。


### 已知问题


响应较大的命令（如ul_dump）如果配置的httpd缓冲区太小（或没有配置足够的pkg内存）将会失败。


httpd模块的未来版本将解决此问题。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即.md扩展名）均采用知识共享署名4.0许可证。
