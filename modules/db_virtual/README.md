---
title: "db_virtual 模块"
---

## 管理指南


### 概述


#### 思路


虚拟 DB 将公开相同的前端 DB API，但是，
它由许多真实的 DB 支持。这意味着一个虚拟 DB URL 
会转换为许多真实的 DB URL。这个虚拟层还使我们能够以多种方式使用真实的 DB：
并行、故障转移（热切换）和轮询。

因此：
每个虚拟 DB URL 必须与关联的真实 DB 和
使用其真实 DB 的方式（模式）一起指定。


#### 模式


实现的模式有：


- FAILOVER
使用第一个 URL；如果失败，使用下一个
URL 并重做操作。
- PARALLEL
使用虚拟 DB URL 集合中的所有 URL。
如果所有 URL 都失败，则失败。
- ROUND（轮询）
每次使用下一个 URL；如果失败，
使用下一个，重做操作。


选择 db virtual 模式时，请确保您想要执行的 DB 操作（插入、
更新、删除，...）与集合中真实 DB URL 之间的关系（如果有）完全兼容 - 它们可以完全独立，可以是同一集群的节点，或任何其他组合。


#### 功能


对于每个集合（或新的虚拟 DB URL），功能是
根据集合中真实 DB URL 提供的能力自动计算的。
对每个功能进行逻辑 AND。
简而言之，为了使虚拟 URL 提供某种能力，
其所有真实 URL 必须都提供该能力。


请注意，从版本 2.2 开始，db_virtual 支持
目前仅由 mysql 数据库引擎实现的 async_raw_query 和 async_raw_resume 函数。


#### 故障


```c
	当某个进程在真实 DB 上的操作失败时：
		它被标记（全局和本地 CAN 标志关闭）
		其连接关闭

	稍后，定时器进程（探测器）：
		对于每个虚拟 db_url
			对于每个真实 db_url
				如果全局 CAN 关闭
					尝试连接
				如果成功
					全局 CAN 开启
					关闭连接

	稍后每个进程：
		如果本地 CAN 关闭且全局 CAN 开启
			如果 db_max_consec_retrys *
				尝试连接
		如果成功
			本地 CAN 开启

				
```


注意 *：探测器和每个进程之间可能存在不一致，因此需要重试限制。
它通过 MI 命令重置和忽略。


#### 定时器进程


定时器进程（探测器）是一个定期尝试重新连接到失败 DB 的进程。
它是一个单独的进程，这样当它阻塞（连接超时）时，不会影响其他操作。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *至少一个真实 DB 模块*。


#### 外部库或应用程序


以下库或应用程序必须在运行
加载了此模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### db_urls (str)


用于虚拟 DB URL 声明的多值参数。


```c title="设置 db_urls 参数"
...

modparam("group","db_url","virtual://set1")
modparam("presence|presence_xml", "db_url","virtual://set2")

modparam("db_virtual", "db_urls", "define set1 PARALLEL")
modparam("db_virtual", "db_urls", "mysql://opensips:opensipsrw@localhost/testa")
modparam("db_virtual", "db_urls", "postgres://opensips:opensipsrw@localhost/opensips")

modparam("db_virtual", "db_urls", "define set2 FAILOVER")
modparam("db_virtual", "db_urls", "mysql://opensips:opensipsrw@localhost/testa")
...
				
```


#### db_probe_time (integer)


定时器进程在注册后尝试检查失败 DB 连接的时间间隔（由其他进程报告）。
探测器将连接到失败的真实 DB 并断开连接，然后向其他进程宣布。


*默认值为 10（10 秒）。*


```c title="设置 db_probe_time 参数"
...
modparam("db_virtual", "db_probe_time", 20)
...
				
```


#### db_max_consec_retrys (integer)


在定时器进程报告可以连接到真实 DB 后，
其他进程将尝试重新连接到它。
在某些情况下，虽然探测器可以连接，但某些进程可能会失败。
此参数表示进程放弃之前将执行的连续失败重试次数。
此值通过 MI 函数（db_virtual:set）重置和取消。


*默认值为 10（连续 10 次）。*


```c title="设置 db_max_consec_retrys 参数"
...
modparam("db_virtual", "db_max_consec_retrys", 20)
...

				
```


### 导出的 MI 函数


#### db_virtual:get


替换过时的 MI 命令：*db_get*。


返回有关真实 DB 全局状态的信息。


名称：
*db_virtual:get*


参数：


- 无。


MI FIFO 命令格式：


```c
				opensips-cli -x mi db_virtual:get
			
```


#### db_virtual:set


替换过时的 MI 命令：*db_set*。


设置每个集合每个 DB 的真实 DB 访问权限。


设置重新连接重置标志。


名称：
*db_virtual:set*


参数：


- set_index [int]
- db_url_index [int]
- may_use_db_flag [boolean]
- ignore_retries[boolean]（可选）


db_virtual:set 3 2 0 1 表示：


- 3 - 第四个集合（必须存在）
- 2 - 第四个集合中的第三个 URL（必须存在）
- 0 - 不允许进程使用该 URL
- 1 - 重置并取消 db_max_consec_retrys


MI FIFO 命令格式：


```c
				opensips-cli -x mi db_virtual:set 3 2 0 1
			
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0
