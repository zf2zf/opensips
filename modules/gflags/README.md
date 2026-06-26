---
title: "gflags 模块"
description: "gflags 模块（全局标志）在共享内存中维护一个位图,可用于根据标志的值更改服务器行为。示例：```c if (is_gflag(1)) { t_relay(\"udp:10.0.0.1:5060\"); } else { t_relay(\"udp:10.0.0.2:5060\"); } ```"
---

## 管理指南


### 概述


gflags 模块（全局标志）在共享内存中维护一个位图,
		可用于根据标志的值更改服务器行为。
		示例：


```c
	if (is_gflag(1)) {
		t_relay("udp:10.0.0.1:5060");
	} else {
		t_relay("udp:10.0.0.2:5060");
	}
	
```


此模块的好处是开关标志的值可以通过 Web 界面或命令行工具等外部应用程序进行操作。
		位图大小为 32。


该模块导出外部命令,可用于通过管理接口更改全局标志。这些 MI 命令为：
	"set_gflag"、"reset_gflag" 和
	"is_gflag"。


### 依赖


该模块依赖以下模块（换句话说,
		以下模块必须在此模块之前加载）：


- *无*


### 导出的参数


#### initial (integer)


全局标志位图的初始值。


默认值为 "0"。


```c title="initial 参数使用"
modparam("gflags", "initial", 15)
		
```


### 导出的函数


#### set_gflag(flag)


设置全局标志中位置 "flag" 处的位。


"flag"（int）参数的值范围为 0..31。


此函数可用于任何路由。


```c title="set_gflag() 使用示例"
...
set_gflag(4);
...
```


#### reset_gflag(flag)


重置全局标志中位置 "flag" 处的位。


"flag"（int）参数的值范围为 0..31。


此函数可用于任何路由。


```c title="reset_gflag() 使用示例"
...
reset_gflag(4);
...
```


#### is_gflag(flag)


检查全局标志中位置 "flag" 处的位是否已设置。


"flag"（int）参数的值范围为 0..31。


此函数可用于任何路由。


```c title="is_gflag() 使用示例"
...
if(is_gflag(4))
{
	log("全局标志 4 已设置\n");
} else {
	log("全局标志 4 未设置\n");
};
...
```


### 导出的 MI 函数


检查或更改某些标志的函数接受一个参数,
			该参数是指定相应标志的位图/掩码。
			不能像路由脚本中可用的函数那样直接指定要更改的标志位置。


#### set_gflag


将某些标志的值（由位掩码指定）设置为 1。


参数值必须是十进制或十六进制格式的位掩码。
			位掩码大小为 32 位。


```c title="set_gflag 使用示例"
...
$ opensips-cli -x mi set_gflag 1
$ opensips-cli -x mi set_gflag 0x3
...
```


#### reset_gflag


将某些标志的值重置为 0。


参数值必须是十进制或十六进制格式的位掩码。
			位掩码大小为 32 位。


```c title="reset_gflag 使用示例"
...
$ opensips-cli -x mi reset_gflag 1
$ opensips-cli -x mi reset_gflag 0x3
...
```


#### is_gflag


如果位掩码中的所有标志都已设置,则返回 true。


参数值必须是十进制或十六进制格式的位掩码。
			位掩码大小为 32 位。


如果集合中的所有标志都已设置,函数返回 TRUE；
			如果至少有一个未设置,则返回 FALSE。


```c title="is_gflag 使用示例"
...
$ opensips-cli -x mi set_gflag 1024
$ opensips-cli -x mi is_gflag 1024
TRUE
$ opensips-cli -x mi is_gflag 1025
TRUE
$ opensips-cli -x mi is_gflag 1023
FALSE
$ opensips-cli -x mi set_gflag 0x10
$ opensips-cli -x mi is_gflag 1023
TRUE
$ opensips-cli -x mi is_gflag 1007
FALSE
$ opensips-cli -x mi is_gflag 16
TRUE
...
```


#### get_gflags


返回包含所有标志的位图。函数不接受参数,
			以十六进制和十进制格式返回位图。


```c title="get_gflags 使用示例"
...
$ opensips-cli -x mi get_gflags
0x3039
12345
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权
