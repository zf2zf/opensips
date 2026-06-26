---
title: "UUID 模块"
description: "此模块提供了一种生成通用唯一标识符（UUID）的方法，如 RFC 4122 中所指定。UUID 作为字符串表示形式提供，通过读取 [uuid](#pv_uuid) 伪变量或调用 [uuid](#func_uuid) 脚本函数。"
---

## 管理指南


### 概述


此模块提供了一种生成通用唯一标识符
		（UUID）的方法，如 RFC 4122 中所指定。
		UUID 作为字符串表示形式提供，
		通过读取 [uuid](#pv_uuid)
		伪变量或调用 [uuid](#func_uuid)
		脚本函数。


### 依赖


#### OpenSIPS 模块


此模块不依赖其他模块。


#### 外部库或应用程序


- *libuuid* - util-linux 包的一部分，
					可从以下地址下载：
					ftp://ftp.kernel.org/pub/linux/utils/util-linux/


### 导出的参数


该模块不导出任何参数。


### 导出的伪变量


#### $uuid(version)


*$uuid* 变量返回一个新生成的 UUID。
			默认情况下（或 version 为 0），它返回基于
			/dev/urandom（如果可用）的高质量随机数的版本 4 UUID。
			否则，将生成基于当前时间和本地以太网 MAC 地址的版本 1 UUID。


可以提供可选的 *version* 参数来生成特定 UUID 版本。
			支持的版本有 0、1、4 和 7。
			版本 3 和 5 不支持，因为它们需要额外参数。


```c title="$uuid 使用示例"
xlog("生成的 uuid：$uuid\n");
xlog("生成的 uuid v7：$uuid(7)\n");

```


### 导出的函数


#### uuid(out_var, [version], [namespace], [name])


生成一个新 UUID。


- *out_var* (var) - 用于返回生成 UUID 的输出变量。
- *version* (string, 可选) - UUID 版本号。
					支持的值有：
						
							
						*0* - 将生成 RFC 版本 4 或
							版本 1 UUID，取决于
							/dev/urandom 的高质量随机数可用性。
							如果 *version* 参数缺失，这是默认行为。
						
							
						*1* - 基于当前时间和本地以太网 MAC
							地址的版本 1 UUID
						
							
						*3* - 通过 MD5 哈希命名空间标识符和名称
							生成的版本 3 UUID
						
							
						*4* - 基于高质量随机数生成器的版本 4 UUID。
							如果不可用，将使用伪随机数生成器替代。
						
							
						*5* - 通过 SHA-1 哈希命名空间标识符和名称
							生成的版本 5 UUID
						
							
						*7* - 基于时间戳和随机数的版本 7 UUID
- *namespace* (string, 可选) - 与 UUID 版本 3 和 5 一起使用的命名空间标识符。
					这必须是一个有效的 UUID，
					有关一些预定义值请参阅 RFC 4122 附录 C。
- *name* (string, 可选) - 与 UUID 版本 3 和 5 一起使用的名称。


如果使用了 UUID 版本 1，
				如果 UUID 以不安全的方式生成，函数将返回值 *2*。
				这指的是两个并发运行进程在同步机制不可用的情况下
				生成相同 UUID 的可能性
				（更多详细信息可在 *libuuid* 的 *uuid_generate* 手册页中找到）。


此函数可用于任何路由。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
