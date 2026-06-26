---
title: "Lua 模块"
description: "编写新的 OpenSIPS 模块所需的时间不幸地相当高，而配置文件提供的选项仅限于模块中实现的功能。"
---

## 管理指南


### 概述


编写新的 OpenSIPS 模块所需的时间不幸地相当高，
   而配置文件提供的选项仅限于模块中实现的功能。


通过此 Lua 模块，您可以轻松地用 Lua 实现自己的 OpenSIPS 扩展。


### 安装模块


此 Lua 模块在 opensips.cfg 中加载（就像所有其他模块一样），
    使用 `loadmodule("/path/to/lua.so");`。


为了编译 Lua 模块，您需要链接动态库的较新版本的 Lua（使用 5.1 测试）。
    您最喜欢的 Linux 发行版的默认版本应该可以正常工作。


### 使用模块


通过 Lua 模块，您可以访问 OpenSIPS 端的 Lua 函数。
    您需要定义要加载的文件并从中调用函数。
    编写一个函数 "mongo_alias"，然后在您的 opensips.cfg 中编写


```c
...
if (lua_exec("mongo_alias")) {
	...
}
...
```


在 Lua 端，您可以访问 OpenSIPS 函数和变量（AVP、pseudoVar 等）。
    请阅读下面的文档以获取更多信息。


### 依赖


#### OpenSIPS 模块


无 ;-)


#### 外部库或应用程序


运行加载此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- Lua 5.1.x 或更高版本
- memcached


此模块使用 Lua 5.1.? 开发并测试，
      但应该适用于任何 5.1.x 版本。早期版本不工作。


在当前的 Debian 系统上，至少应安装以下软件包：


- lua5.1
- liblua5.1-0-dev
- libmemcached-dev
- libmysqlclient-dev


据报告，其他 Debian 风格的发行版（如 Ubuntu）需要相同的软件包。


在 OpenBSD 系统上，至少应安装以下软件包：


- Lua


### 导出的参数


#### luafilename (字符串)


这是脚本的文件名。这只能设置一次，
      但它可以包含任意数量的函数，
      并根据需要使用尽可能多的 Lua 模块。


默认值为 "/etc/opensips/opensips.lua"


```c title="设置 luafilename 参数"
...
modparam("lua", "luafilename", "/etc/opensips/opensips.lua")
...
        
```


#### lua_auto_reload (整数)


如果您想自动重新加载 Lua 脚本，请将此值定义为 1。
      默认禁用。


#### warn_missing_free_fixup (整数)


当您通过 moduleFunc() 调用函数时，可能会出现内存泄漏。
      启用此选项会在您这样做时发出警告。
      默认启用。


#### lua_allocator (字符串)


更改 Lua 模块的默认内存分配器。
      可能值为：


- opensips（默认）
- malloc


### 导出的函数


#### lua_exec(func, [param])


调用 Lua 函数，并将当前 SIP 消息传递给它。
      此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、
      ONREPLY_ROUTE 和 BRANCH_ROUTE。


参数：


- *func* (字符串) - Lua 函数名
- *param* (字符串，可选) - 要传递给 Lua 函数的参数。


```c title="lua_exec() 用法"
...
if (lua_exec("mongo_alias")) {
	...
}
...
```


#### lua_meminfo()


记录有关内存的信息。


### 导出的 MI 函数


#### watch


名称：*watch*


参数：*无*


- *action* (可选) - 'add' 或 'delete'
- *extension* (可选) - 如果提供了 *action* 则需要


MI FIFO 命令格式：


```c
  opensips-cli -x mi watch
  
```


## OpenSIPS Lua API


### 可用函数


此模块提供对有限数量的 OpenSIPS 核心函数的访问。


#### xdbg(message)


xlog(DBG, message) 的别名


#### xlog([level],message)


使用 OpenSIPS 的日志工具记录消息。日志级别为以下之一：


- ALERT
- CRIT
- ERR
- WARN
- NOTICE
- INFO
- DBG


#### WarnMissingFreeFixup


动态更改变量 warn_missing_free_fixup。


#### getpid


返回当前进程 ID。


#### getmem


返回一个包含已分配内存大小和碎片化程度的表。


#### getmeminfo


返回一个包含内存信息的表。


#### gethostname


返回当前主机名的值。


#### getType(msg)


返回 "SIP_REQUEST" 或 "SIP_REPLY"。


#### isMyself(host, port)


测试主机和可选端口是否代表 OpenSIPS 监听的地址之一。


#### grepSockInfo(host, port)


类似于 isMyself()，但不查看别名。


#### getURI_User(msg)


返回 To URI 的用户部分。


#### getExpires(msg)


返回当前消息的过期头。


#### getHeader(msg, header)


返回指定头部的值。


#### getContact(msg)


返回一个包含联系头部的表。


#### getRoute(msg)


返回一个包含 Route 头的表。


#### moduleFunc(msg, function, args1, args2, ...)


您可以将参数传递到此函数。


#### getStatus(msg)


如果 SIP 消息是 SIP_REPLY，则返回当前状态。


#### getMethod(msg)


返回当前方法。


#### getSrcIp(msg)


返回源 IP 地址。


#### getDstIp(msg)


返回目标 IP 地址。


#### AVP_get(name)


返回一个 AVP 变量。


#### AVP_set(name, value)


定义一个 AVP 变量。


#### AVP_destroy(name)


销毁一个 AVP 变量。


#### pseudoVar(msg, variable)


返回一个伪变量。


#### pseudoVarSet(msg, variable, value)


设置伪变量的值。


#### scriptVarGet(variable)


返回一个脚本变量。


#### scriptVarSet(variable, value)


设置脚本变量的值。


#### add_lump_rpl(msg, header)


向回复添加头部。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议。
