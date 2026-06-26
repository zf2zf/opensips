---
title: "maxfwd 模块"
description: "该模块实现了与 MaX-Forward 头字段相关的所有操作，如添加（如果不存在）或递减和检查现有值。"
---

## 管理指南


### 概述


该模块实现了与 MaX-Forward 头字段相关的所有操作，如添加（如果不存在）或递减和检查现有值。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他 OpenSIPS 模块*。


#### 外部库或应用程序


运行 OpenSIPS 加载此模块前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### max_limit (integer)


设置传出请求中 max-forward 值的上限。如果头存在，递减后的值不允许超过此最大值 - 如果超过，头值将减少到"max_limit"。


注意：此检查在调用 mf_process_maxfwd_header() 头时执行。


值范围从 1 到 256，这是 RFC 3261 允许的最大 MAX-FORWARDS 值。


*默认值为 "256"。*


```c title="设置 max_limit 参数"
...
modparam("maxfwd", "max_limit", 32)
...
```


### 导出的函数


#### mf_process_maxfwd_header(max_value)


如果接收到的请求中没有 Max-Forward 头，将添加一个原始值等于"max_value"的新头。如果已存在 Max-Forward 头，其值将被递减（如果不为 0）。


返回值代码：


- *2 (true)* - 未找到头，
			新头已成功添加。
- *1 (true)* - 找到头且其 
			值已成功递减（值非 0）。
- *-1 (false)* - 找到头且其
			值为 0（无法递减）。
- *-2 (false)* - 处理过程中出错。


返回值代码可以通过脚本变量"retcode"（或"$?"）进行广泛测试。


参数含义如下：


- *max_value* (int) - 如果消息中没有 Max-Forwards 头字段，要添加的值。


此函数可以从 REQUEST_ROUTE 使用。


```c title="mx_process_maxfwd_header 使用示例"
...
# 初始完整性检查 -- 消息 with
# max_forwards==0，或过长的请求
if (!mf_process_maxfwd_header(10) && $retcode==-1) {
	sl_send_reply(483,"Too Many Hops");
	exit;
};
...
```


#### is_maxfwd_lt(max_value)


检查 Max-Forward 头值是否小于"max_value"参数值。它也会考虑新插入的头（如果本地添加）的值。


返回值代码：


- *1 (true)* - 找到或设置了头且
			其值严格小于"max_value"。
- *-1 (false)* - 找到或设置了头且
			其值大于或等于"max_value"。
- *-2 (false)* - 未找到或未设置头。
- *-3 (false)* - 处理过程中出错。


返回值代码可以通过脚本变量"retcode"（或"$?"）进行广泛测试。


参数含义如下：


- *max_value* (int) - 要与 Max-Forward.value 进行比较（作为小于）的值。


```c title="is_maxfwd_lt 使用示例"
...
# 下一跳是网关，所以如果 MF 为 0（递减后）就没有意义
# 继续转发
if ( is_maxfwd_lt(1) ) {
	sl_send_reply(483,"Too Many Hops");
	exit;
};
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用 Creative Common License 4.0 许可证。
