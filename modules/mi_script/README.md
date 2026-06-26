---
title: "MI 脚本模块"
description: "此模块提供了多个钩子，用于直接从OpenSIPS脚本运行管理接口命令。它支持运行同步和异步命令。根据命令的性质（异步与否）以及从脚本运行*mi*命令的方式，返回的结果不同。"
---

## 管理指南


### 概述


此模块提供了多个钩子，用于直接从OpenSIPS脚本运行管理接口命令。它支持运行同步和异步命令。根据命令的性质（异步与否）以及从脚本运行*mi*命令的方式，返回的结果不同。


### 返回值


成功情况下，MI命令成功返回。如果提供了返回变量作为参数，JSON也存储在提供的变量中。


失败情况下，JSON-RPC错误代码存储在*$rc*变量中，作为负数。较低的值，如*-1,-2,-3*，也可能返回以表示内部错误。如果提供了返回变量，它被存储为错误描述。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- 如果使用MI跟踪，则需要*proto_hep模块*。


#### 外部库或应用程序


运行此模块加载的OpenSIPS之前必须安装以下库或应用程序：


- *无*


### 导出的参数


#### pretty_printing (int)


指示存储在返回变量中的JSON响应是否应该被美化打印。


*默认值为"0 - 不美化打印"。*


```c title="设置 pretty_printing 参数"
...
modparam("mi_script", "pretty_printing", 1)
...
```


#### trace_destination (string)


跟踪模块中定义的跟踪目标。目前唯一的跟踪模块是**proto_hep**。跟踪的MI消息将发送到此处。


**警告：**必须加载跟踪模块此参数才能工作。（例如**proto_hep**）。


*默认值为无（未定义）。*


```c title="设置 trace_destination 参数"
...
modparam("proto_hep", "trace_id", "[hep_dest]10.0.0.2;transport=tcp;version=3")

modparam("mi_script", "trace_destination", "hep_dest")
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
modparam("mi_script", "trace_bwlist", "b: ps, which")
...
## 只允许sip_trace MI命令
## 所有其他命令都不会被跟踪
modparam("mi_script", "trace_bwlist", "w: sip_trace")
...
```


### 导出的函数


#### mi(command, [ret_var [,params_avp[, vals_avp]]])


以同步模式运行MI命令，阻塞直到有响应可用。


*重要：*强烈建议不要对耗时的任务使用此函数，如重新加载，因为函数会阻塞直到命令结束。此外，如果运行的MI*command*配置为异步模式运行（如*t_uac_dlg*），命令会以忙等待方式阻塞直到收到响应。


此函数可在任何路由中使用。


函数可以接收以下参数：


- *command(string)* - 要运行的MI命令。这可以是单个token，表示要运行的MI命令（无参数），也可以后跟多个空格分隔的参数（不处理转义）。每个空格分隔的参数将作为索引参数传递给MI命令。*注意：*不能使用此参数指定命名参数，您必须使用*params_avp*和/或*vals_avp*参数来指定命名命令，在这种情况下，此参数将仅包含MI命令。
- *ret_var(var, 可选)* - 用于存储MI命令执行返回值的变量。成功时存储JSON，否则存储错误消息。
- *params_avp(avp, 可选)* - 一个AVP，包含将发送到MI命令的所有参数名称。如果此参数没有使用*vals_avp*，AVP内的所有值将作为索引参数传递给MI命令，否则作为命名参数。*注意：*如果使用此参数，*command*参数中指定的参数将被忽略。*注意：*参数传递给命令的顺序与填充AVP的顺序相同（因此与AVP在内存中存储的方式有些相反——第一个添加的AVP是第一个参数）
- *vals_avp(avp, 可选)* - 一个AVP，包含将发送到MI命令的所有参数值。此参数仅在*params_avp*设置时才有意义，并且必须包含与参数数量相同的值。要指定*数组值*，请将空格分隔的数组元素包装在*__array()*伪函数调用中。例如：*"__array(HEARTBEAT BACKGROUND_JOB)"*


```c title="无参数的mi"
...
mi("shm_check");
...
```


```c title="命令中带参数的mi"
...
# 此命令类似于上面的
mi("cache_remove local password_user1");
...
```


```c title="带返回值的mi"
...
mi("ds_list", $var(ret));
...
```


```c title="无返回但有索引参数的mi"
...
$avp(params) = "local";
$avp(params) = "password_user1";
mi("cache_remove",,$avp(params));

# 以下命令类似于上面的
mi("cache_remove local password_user1");
...
```


```c title="带返回值和命名参数的mi"
...
$avp(params) = "callid";
$avp(vals) = "SEARCH_FOR_THIS_CALLID";
$avp(params) = "from_tag";
$avp(vals) = "SEARCH_FOR_THIS_FROM_TAG";
mi("dlg_list", $var(dlg), $avp(params), $avp(vals));
...
```


```c title="无返回值，带数组参数值的mi"
...
$avp(params) = "freeswitch_url";
$avp(vals) = "fs://:ClueCon@192.168.20.8:8021";
$avp(params) = "events";
$avp(vals) = "__array(HEARTBEAT BACKGROUND_JOB)";
mi("fs_subscribe", , $avp(params), $avp(vals));
...
```


### 导出的异步函数


#### mi(command, [ret_var [,params_avp[, vals_avp]]])


函数的工作方式与其同步对应函数大致相同，只是MI命令以异步方式运行——进程不阻塞等待响应，而是继续执行，MI命令在异步上下文中运行。


*注意：*目前异步运行的MI命令无法通过hep跟踪。


```c title="异步mi调用用法"
...
xlog("重新加载开始\n");
async(mi("dr_reload"), after_reload);
...

route[after_reload] {
	xlog("重新加载完成\n");
}
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即.md扩展名）均采用知识共享署名4.0许可证。
