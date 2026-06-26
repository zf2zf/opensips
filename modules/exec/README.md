---
title: "exec 模块"
description: "Exec 模块支持从 OpenSIPS 脚本执行外部命令。接受任何有效的 shell 命令。最终输入字符串通过 \"/bin/sh\" 符号链接/二进制进行评估和执行。OpenSIPS 还可以通过环境变量传递更多关于请求的信息..."
---

## 管理指南


### 概述


Exec 模块支持从 OpenSIPS 脚本执行外部命令。
		接受任何有效的 shell 命令。最终输入字符串通过
		"/bin/sh" 符号链接/二进制进行评估和执行。
		OpenSIPS 还可以通过环境变量传递更多关于请求的信息：


- SIP_HF_<hf_name> 包含每个头域的值。
			如果某个头域出现多次,值将用逗号连接。
			<hf_name> 为大写。如果头域名称以紧凑形式出现,
			<hf_name> 为规范形式。
- SIP_TID 是事务标识符。所有与先前 INVITE 相关的请求重传或
			CANCEL/ACK 会产生相同的值。
- SIP_DID 是对话标识符,与 to-tag 相同。
			最初为空。
- SIP_SRCIP 是请求来源的 IP 地址。
- SIP_ORURI 是原始请求 URI。
- SIP_RURI 是*当前*请求 URI（如果
			未更改,则等于原始 URI）。
- SIP_USER 是*当前*请求 URI 的 userpart。
- SIP_OUSER 是原始请求 URI 的 userpart。


注意：传递给 exec 模块函数的任何环境变量必须使用 '$$' 分隔符指定
		（例如 $$SIP_OUSER）,否则它们将被评估为 OpenSIPS 伪变量,
		从而引发脚本错误。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他 OpenSIPS 模块*。


#### 外部库或应用程序


以下库或应用程序必须在运行
		加载本模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### setvars (integer)


设置为 1 以启用为所有执行的命令设置上述所有环境变量。


**警告：在启用此参数之前,请确保您的 "/bin/sh" 不受 Shellshock bash 漏洞影响！！！**


*默认值为 0（禁用）。*


```c title="设置 'setvars' 参数"
...
modparam("exec", "setvars", 1)
...
```


#### time_to_kill (integer)


如果设置,此参数指定程序允许执行的最长时间（秒）。
		一旦超过此持续时间,程序将被终止（SIGTERM）。


注意：由于内部限制,一旦 "time_to_kill"
		过期超时命中,实际上会向**所有**作业 pid 发送 SIGTERM。
		在标准系统上,这应该没有副作用,因为 pid 以缓慢的方式单调递增,
		OpenSICS 应在 "opensips" 用户下运行,因此无法终止非子进程。
		如果您的系统不是这种情况,请不要使用 OpenSIPS "time_to_kill" 功能——而是在您的外部应用程序中实现它！


*默认值为 0（禁用）。*


```c title="设置 'time_to_kill' 参数"
...
modparam("exec", "time_to_kill", 20)
...
```


### 导出的函数


#### exec(command, [stdin], [stdout], [stderr], [envavp])


执行外部命令。输入被传递给新进程的标准输入（如果指定）,
		输出保存在输出变量中。


该函数等待外部脚本提供其所有输出后才继续（不必
		实际完成）。如果函数不需要任何输出（标准输出或标准错误）,
		它根本不会阻塞——只是启动外部脚本并继续执行脚本。


参数含义如下：


- *command (string)* - 要执行的命令
- *stdin (string, 可选)* - 要传递给命令
				标准输入的字符串
- *stdout (var, 可选)* - 可选输出变量,
				将保存进程的标准输出
- *stderr (var, 可选)* - 可选输出变量,
				将保存进程的标准错误
- *envavp (var, 可选)* - 可选 AVP,
				保存要传递给命令的环境变量值。
				环境变量的名称将为 "OSIPS_EXEC_#",其中 "#" 从 0 开始。
				例如,如果您将两个值（例如 "b" 和 "a"）压入一个 AVP 变量,
				它像堆栈一样工作,OSIPS_EXEC_0 将保存 "a",
				而 OSIPS_EXEC_1 将保存 "b"。


注意：如果期望多行格式的输出,您应该使用 $avp 变量作为 "stdout" 和 "stderr" 参数,
		以避免只接收每个流的最后一行。


警告：任何可能包含特殊 bourne shell（sh/bash）字符的 OpenSIPS 伪变量应放在引号内,
		例如
		exec("update-stats.sh '$(ct{re.subst,/'//g})'");


警告："stdin"/"stdout"/"stderr" 参数不是为大量数据设计的,
		因此使用时应小心。由于基本实现,充满的管道可能导致读取死锁。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、
		LOCAL_ROUTE、STARTUP_ROUTE、TIMER_ROUTE、EVENT_ROUTE、ONREPLY_ROUTE。


```c title="exec 使用示例"
...
$avp(env) = "a";
$avp(env) = "b";
exec("ls -l", , $var(out), $var(err), $avp(env));
xlog("输出是 $var(out)\n");
xlog("收到以下错误\n$var(err)");
...
$var(input) = "input";
exec("/home/../myscript.sh", "这是我的 $var(input) 用于 exec\n", , , $avp(env));
...
```


### 导出的异步函数


#### exec(command, [stdin], [stdout], [stderr], [envavp])


执行外部命令。此函数在输入、输出和处理方面与
		[exec](#func_exec) 完全相同,
		但以异步方式工作。脚本执行被挂起,直到外部脚本提供其所有输出。
		OpenSIPS 等待外部脚本关闭其输出流,
		而不必等待其终止（因此当 OpenSIPS 在输出流上"看到"EOF 时恢复脚本执行,
		脚本可能仍在运行）


注意：此函数目前忽略 "stderr" 参数——异步等待仅在输出流上进行！！
		这可能在后续版本中修复。


要阅读和理解异步函数、如何使用它们及其优势,
		请参阅 OpenSIPS 在线手册。


```c title="异步 exec 使用示例"
{
...
async(exec("ruri-changer.sh", $ru, $ru), resume);
}

route [resume] {
...
}
```


### 已知问题


使用 [time to kill](#param_time_to_kill) 设置执行超时时,
		请确保您的 "/bin/sh" 是一个执行时不会 fork 的 shell,
		在这种情况下,作业本身不会被杀死,而是其父 shell,
		作业将被 init 静默继承并继续运行。
		"/bin/dash" 就是这种麻烦的 shell 环境之一。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权
