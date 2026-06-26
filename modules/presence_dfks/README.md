---
title: "presence_dfks 模块"
description: "该模块支持通过 presence 模块处理 \"as-feature-event\" 事件包（如 Broadsoft 的 [Device Feature Key Synchronization](https://h30434.www3.hp.com/psg/attachments/psg/Desk_IP_Conference_Phones/1740/1/DeviceFeatureKeySynchronizationFD.pdf) 协议所定义）。这可用于在 SIP..."
---

## 管理指南


### 概述


该模块支持通过 presence 模块处理 "as-feature-event" 事件包（如
	    Broadsoft 的
	    [Device Feature Key Synchronization](https://h30434.www3.hp.com/psg/attachments/psg/Desk_IP_Conference_Phones/1740/1/DeviceFeatureKeySynchronizationFD.pdf)
	    协议所定义）。这可用于在 SIP 电话和 SIP 服务器之间同步"请勿打扰"和各种转发类型等功能的状态。


该模块支持同步以下功能："请勿打扰"、"呼叫转移始终"、"呼叫转移占线"和"呼叫转移无应答"。
	    功能状态可以从 SIP 电话或 OpenSIPS 服务器更改（通过运行 MI 命令）。


当处理没有正文的 SUBSCRIBE 消息时，模块将为每个功能运行一个脚本路由，
	    用于检索该功能的当前状态。相反，带有正文的 SUBSCRIBE 将触发一个脚本路由，
	    其中包含特定功能的更新状态。如果功能更新是从 OpenSIPS 通过 MI 触发的，
	    此路由也可能运行。


请注意，模块不会自动缓存或持久化任何功能信息，
	    因为这是留给脚本编写者在模块触发的路由中实现的。


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *presence*。


#### 外部库或应用程序


- *libxml2-dev*。


### 导出的参数


#### get_route (string)


脚本路由的名称，用于检索功能的状态。


*默认值为 "dfks_get"。*


```c title="设置参数"
...
modparam("presence_dfks", "get_route", "dfks_get")
...
```


#### set_route (string)


从 SIP 电话收到功能状态更新时运行的脚本路由名称。


*默认值为 "dfks_get"。*


```c title="设置参数"
...
modparam("presence_dfks", "set_route", "dfks_set")
...
```


### 导出的函数


无。


### 导出的 MI 函数


#### presence_dfks:set_feature


替换过时的 MI 命令：*dfks_set_feature*。


触发发送包含功能状态更新的 NOTIFY 消息给所有 watcher。


*注意：* 调用此 MI 函数也会触发 *set_route* 运行。
		可以通过检查 *$dfks(param)* 变量是否存在来确定路由是否由 MI 函数触发。


名称：*presence_dfks:set_feature*


参数：


- *presentity*：应更新其功能状态的用户 URI
- *feature*：要更新的功能名称。取以下值之一：

  - *DoNotDisturb*
  - *CallForwardingAlways*
  - *CallForwardingBusy*
  - *CallForwardingNoAnswer*
- *status*：功能的新状态：*0* - 禁用，*1* - 启用
- *route_param*：可选字符串参数，传递给 *set_route* 中的 *$dfks(param)* 变量。
- *values*：可以为功能更新的额外值数组。数组元素格式为：*field*/*value*。支持的字段有：
					
					
				*forwardTo* - 适用于所有转发类型
					
					
				*ringCount* - 适用于 *CallForwardingNoAnswer*


MI FIFO 命令格式：


```c
opensips-cli -x mi presence_dfks:set_feature sip:alice@10.0.0.11 CallForwardingNoAnswer 1 1 \
ringCount/4 forwardTo/sip:bob@10.0.0.11
```


### 导出的伪变量


#### $dfks(field)


此伪变量可用于模块触发的路由中，通过以下子名称处理功能信息：


- *assigned* - 通过将此设置为 *0* 来通知 SIP 电话功能未分配
		（NOTIFY 响应将不包含相应功能的 XML 数据）。默认情况下，功能是分配的。
- *notify* - 通过将此设置为 *0* 来禁止发送 NOTIFY 消息。默认情况下，NOTIFY 被发送。
- *presentity* - 只读，返回当前 presentity URI。
- *feature* - 只读，返回当前功能名称。可能的值有：

  - *DoNotDisturb*
  - *CallForwardingAlways*
  - *CallForwardingBusy*
  - *CallForwardingNoAnswer*
- *status* - 读取或写入功能状态。值 *1* 表示启用，*0* 表示禁用。
- *param* - 返回由 *mi_dfks_set_feature* MI 函数传递的参数。
		如果未指定参数，或者 *set_route* 不是由 MI 命令而是由 SIP 信令触发，则此字段为 *NULL*。
- *value/field* - 读取或写入额外的功能值。
		*field* 可以是：
			
			
			*forwardTo* - 适用于所有转发类型
			
			
			*ringCount* - 适用于 *CallForwardingNoAnswer*


```c title="dfks 使用示例"
...
route[dfks_set] {
    # 不允许 CallForwardingAlways
    if ($dfks(feature) == "CallForwardingAlways")
        $dfks(status) = 0;

    xlog("新状态：$dfks(status)，功能 '$dfks(feature)'，用户 '$dfks(presentity)'\n");
}
route[dfks_get] {
    if ($dfks(feature) == "CallForwardingNoAnswer") {
        $dfks(status) = 1;
        $dfks(value/forwardTo) = "sip:bob@10.0.0.11";
        $dfks(value/ringCount) = "3";
    } else if ($dfks(feature) == "CallForwardingAlways")
        $dfks(assigned) = 0;
    } else {
        ...
    }
}
...
	
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
