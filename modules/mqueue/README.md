---
title: "mqueue 模块"
description: "mqueue模块在共享内存中提供了一个通用的消息队列系统，用于使用配置文件进行进程间通信。一个使用示例是将耗时的操作发送给一个或多个消费队列中的计时器进程，而不影响套接字监听进程中的SIP消息处理。"
---

## 管理指南


### 概述


mqueue模块在共享内存中提供了一个通用的消息队列系统，用于使用配置文件进行进程间通信。一个使用示例是将耗时的操作发送给一个或多个消费队列中的计时器进程，而不影响套接字监听进程中的SIP消息处理。


可以定义多个队列。通过伪变量访问队列中的值。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *无*。


#### 外部库或应用程序


运行此模块加载的OpenSIPS之前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### db_url (str)


数据库URL，用于在启动时加载值和/或在关闭时保存值到mqueue表。


*默认值为NULL（不连接）。*


```c title="设置 db_url 参数"
...
modparam("mqueue", "db_url", "mysql://opensips:opensipsrw@localhost/opensips")

# sqlite中的表示例，
# 您需要设置字段以根据mqueue中存在的数据支持适当的长度
CREATE TABLE mqueue_name (
id INTEGER PRIMARY KEY AUTOINCREMENT,
key character varying(64) DEFAULT "" NOT NULL,
val character varying(4096) DEFAULT "" NOT NULL
);
...
```


#### mqueue (string)


内存队列的定义。


*默认值为"none"。*


值必须是参数列表：attr=value;...


- 必选属性：

  - *name*：队列名称。
- 可选属性：

  - *size*：队列大小。
				指定队列中的最大项目数。
				如果超出，最早的将被移除。
				如果未设置，队列将是无限的。
  - *dbmode*：如果设置为1，当SIP服务器停止时，队列内容将写入数据库表（即确保重启后的持久性）。
				如果设置为2，它在关闭时写入但在启动时不读取。
				如果设置为3，它在启动时读取但在关闭时不写入。
				默认值为0（无数据库表交互）。
  - *addmode*：如何添加新的(key,value)对。
					
					
					*0*：
					将所有新的(key,value)对推到队列末尾。（默认）
					
					
					*1*：
					基于键保留队列中最旧的(key,value)对。
					
					
					*2*：
					基于键保留队列中最新的(key,value)对。


可以多次设置此参数，每个参数持有一个队列的定义。


```c title="设置 mqueue 参数"
...
modparam("mqueue", "mqueue", "name=myq;size=20;")
modparam("mqueue", "mqueue", "name=myq;size=10000;addmode=2")
modparam("mqueue", "mqueue", "name=qaz")
modparam("mqueue", "mqueue", "name=qaz;addmode=1")
...
```


### 导出的函数


#### mq_add(queue, key, value)


在队列中添加一个新项目(key, value)。如果队列超出最大大小，最早的被移除。


```c title="mq_add 使用示例"
...
mq_add("myq", "$rU", "来自 $fU 的呼叫");
...
```


#### mq_fetch(queue)


从队列中取出最旧的项目，并填充$mqk(queue)和$mqv(queue)伪变量。


返回：成功时为真(1)；失败时为假(-1)或未取到项目(-2)。


```c title="mq_fetch 使用示例"
...
while(mq_fetch("myq"))
{
	xlog("$mqk(myq) - $mqv(myq)\n");
}
...
```


#### mq_pv_free(queue)


释放伪变量中取出的项目。这是可选的，新的fetch会释放之前的值。


```c title="mq_pv_free 使用示例"
...
mq_pv_free("myq");
...
```


#### mq_size(queue)


返回mqueue中当前元素的数量。


如果mqueue为空，函数返回-1。如果未找到mqueue，函数返回-2。


```c title="mq_size 使用示例"
...
$var(q_size) = mq_size("queue");
xlog("L_INFO", "队列大小为: $var(q_size)\n");
...
```


### 导出的MI函数


#### mqueue:get_size


替换已废弃的MI命令：*mq_get_size*。


获取内存队列的大小。


参数：


- name


```c title="mqueue:get_size 使用示例"
...
opensips-cli -x mqueue:get_size xyz
...
```


#### mqueue:fetch


替换已废弃的MI命令：*mq_fetch*。


从内存队列中取出一个（或最多limit个）键值对。


参数：


- name
- limit


```c title="mqueue:fetch 使用示例"
...
opensips-cli -x mqueue:fetch xyz
...
```


#### mqueue:get_sizes


替换已废弃的MI命令：*mq_get_sizes*。


获取所有内存队列的大小。


参数：无


```c title="mqueue:get_sizes 使用示例"
...
opensips-cli -x mqueue:get_sizes
...
```


### 导出的伪变量


#### $mqk(mqueue)


该变量是只读的，返回从指定mqueue取出的最新项目键。


#### $mqv(mqueue)


该变量是只读的，返回从指定mqueue取出的最新项目值。


#### $mq_size(mqueue)


该变量是只读的，返回指定mqueue的大小。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即.md扩展名）均采用知识共享署名4.0许可证。
