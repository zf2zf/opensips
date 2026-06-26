---
title: "QOS 模块"
description: "qos 模块提供了一种跟踪每个对话 SDP 会话的方法。"
---

## 管理指南


### 概述


qos 模块提供了一种跟踪每个对话 SDP 会话的方法。


### 工作原理


qos 模块使用 dialog 模块来接收任何新对话或更新对话的通知。然后它会从 SIP 请求和回复中查找并提取 SDP 会话（如果存在），并在对话的整个生命周期内跟踪它。


所有这些都通过正确配置的 dialog 和 qos 模块实现，并在看到任何 INVITE SIP 消息时设置 dialog 标志和 qos 标志。设置 SDP 会话跟踪机制不需要配置脚本函数调用。有关更多信息，请参阅 dialog 模块用户指南。


一个对话可以有一个或多个处于以下状态之一的 SDP 会话：


- *pending* - 仅知道 SDP 会话的一端。
- *negotiated* - SDP 会话的两端都知道。


SDP 会话可以在以下场景之一中建立：


- *INVITE/200ok* - 典型的 "INVITE" 和 "200 OK" SDP 交换。
- *200ok/ACK* - "200 OK" 和 "ACK" SDP 交换（用于以空 INVITE 开始的呼叫）。
- *183/PRACK* - 通过 "183 Session Progress" 和 "PRACK" 的早期媒体（详见 rfc3959）——尚未实现。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *dialog* - dialog 模块及其依赖（tm）。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### qos_flag (string)


与 OpenSIPS 保持一致，除非通过配置脚本指示，否则模块不会对任何消息执行任何操作。您必须在要 qos 模块处理的 INVITE 的 setflag() 调用中设置 qos_flag 值。但在此之前，您需要告诉 qos 模块您分配给 qos 的标志值是什么。


在大多数情况下，当您通过 create_dialog() 函数创建新对话时，您会想要设置 qos 标志。如果未调用 create_dialog() 且设置了 qos 标志，则不会有任何效果。


必须设置此参数，否则模块不会加载。


*默认值为 "未设置！"。*


```c title="设置 qos_flag 参数"
...
modparam("qos", "qos_flag", "QOS_FLAG")
...
route {
  ...
  if ($rm=="INVITE") {
    setflag(QOS_FLAG); # 设置 qos 标志
	create_dialog(); # 创建对话
  }
  ...
}
```


### 导出的函数


没有可从脚本使用的导出函数。


### 导出的统计信息


qos 模块没有导出的统计信息。


### 导出的 MI 函数


qos 模块没有导出的 MI 函数。
	请查看 dialog MI 函数以了解检查对话内部的方法。


### 导出的伪变量


qos 模块没有导出的伪变量。


### 安装和运行


只需加载模块并记住设置标志。


## 开发者指南


### 可用函数


#### register_qoscb (qos, type, cb, param)


向 qos 注册新回调。


参数的含义如下：


- *struct qos_ctx_st* qos* - 要注册回调的 qos。对于 QOSCB_CREATED 回调类型，它可能仅为 NULL，这不是每 qos 类型。
- *int type* - 回调类型；可以为同一回调函数注册多种类型；只有 QOSCB_CREATED 必须单独注册。可能的类型：
	
	
	*QOSCB_CREATED* - 创建新 qos 上下文时调用——它是全局类型（不与任何 qos 关联）。
	
	
	*QOSCB_ADD_SDP* - 向 qos 上下文添加新 SDP 时调用——它是每 qos 类型。
	
	
	*QOSCB_UPDATE_SDP* - 更新现有 SDP 时调用——它是每 qos 类型。
	
	
	*QOSCB_REMOVE_SDP* - 删除现有 SDP 时调用——它是每 qos 类型。
	
	
	*QOSCB_TERMINATED* - qos 终止时调用。
- *qos_cb cb* - 要调用的回调函数。原型为： "void (qos_cb) (struct qos_ctx_st *qos, int type, struct qos_cb_params *params);"
- *void *param* - 要传递给回调函数的参数。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0（Creative Common License 4.0）授权。
