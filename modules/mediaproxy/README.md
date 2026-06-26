---
title: "Mediaproxy 模块"
description: "Mediaproxy是一个OpenSIPS模块，旨在为大多数现有SIP客户端提供自动NAT穿透。这意味着使用mediaproxy模块时，不需要在NAT设备上进行任何特殊配置即可让这些客户端在NAT后面正常工作。"
---

## 管理指南


### 概述


Mediaproxy是一个OpenSIPS模块，旨在为大多数现有SIP客户端提供自动NAT穿透。这意味着使用mediaproxy模块时，不需要在NAT设备上进行任何特殊配置即可让这些客户端在NAT后面正常工作。


### 工作原理


此NAT穿透解决方案通过在2个SIP用户代理之间放置一个媒体中继来运作。它为双方修改SDP消息的方式是让各方认为自己直接与对方通话，而实际上他们是与中继通话。


Mediaproxy由2个组件组成：


- OpenSIPS mediaproxy模块
- 一个名为MediaProxy的外部应用程序，它包含一个调度器和多个分布式媒体中继。这可以从http://ag-projects.com/MediaProxy.html获得（此模块需要2.0.0或更高版本）。


mediaproxy调度器与OpenSIPS运行在同一台机器上，其目的是为呼叫选择一个媒体中继。媒体中继可以与调度器运行在同一台机器上，也可以在多个远程主机上运行，其目的是在各方之间转发流。为了解更多关于MediaProxy架构的信息，请阅读其随附的文档。


为了能够充当2个用户代理之间的中继，运行模块/代理服务器的机器必须具有公共IP地址。


OpenSIPS将请求媒体中继分配与SDP offer和answer中一样多的端口。媒体中继将把它们的IP地址和端口发送回OpenSIPS。然后OpenSIPS将用媒体中继提供的IP地址和RTP端口替换SDP消息中的原始contact IP和RTP端口。通过这样做，双方用户代理将尝试联系媒体中继，而不是直接相互通信。一旦用户代理联系了媒体中继，它将记录它们来自的地址，并知道将收到的数据包转发到哪里。这是必要的，因为NAT设备为媒体流分配的地址/端口在它们实际离开NAT设备之前是不知道的。然而，媒体中继的地址总是已知的（因为是公共IP），所以2个端点知道要连接到哪里。连接后，中继学习它们的地址并可以在它们之间转发数据包。


使用mediaproxy能够透明地在NAT后面工作的SIP客户端是所谓的对称客户端。对称客户端的特点是使用相同的端口发送和接收数据。对于客户端来说，信令和媒体都必须如此才能使mediaproxy透明地工作，而无需在NAT设备上进行任何配置。


### 功能


- 使对称客户端透明地在NAT后面工作，无需在客户端的NAT设备上进行任何配置。
- 能够将RTP流量分发到运行在多个主机上的多个媒体中继。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- 如果使用engage_media_proxy，则需要*dialog*模块（见下文engage_media_proxy的描述）。


#### 外部库或应用程序


运行此模块加载的OpenSIPS之前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### disable (int)


一个布尔标志，指定是否应禁用mediaproxy。当您想在两种不同上下文中使用相同的OpenSIPS配置，一个使用mediaproxy，另一个不使用时，这很有用。如果mediaproxy被禁用，对其函数的调用将不起作用，允许您使用相同配置而无需更改。


*默认值为"0"。*


```c title="设置 disable 参数"
...
modparam("mediaproxy", "disable", 1)
...
        
```


#### mediaproxy_socket (string)


这是mediaproxy调度器监听模块命令的文件系统socket的路径。


*默认值为"/run/mediaproxy/dispatcher.sock"。*


```c title="设置 mediaproxy_socket 参数"
...
modparam("mediaproxy", "mediaproxy_socket", "/run/mediaproxy/dispatcher.sock")
...
        
```


#### mediaproxy_timeout (int)


等待mediaproxy调度器应答的时间（以毫秒为单位）。


*默认值为"500"。*


```c title="设置 mediaproxy_timeout 参数"
...
modparam("mediaproxy", "mediaproxy_timeout", 500)
...
        
```


#### signaling_ip_avp (string)


指定保存SIP信令来源IP地址的AVP的规范。如果此AVP被设置，它将用于获取信令IP地址，否则将使用接收SIP消息的源IP地址。在呼叫设置路径中有多个代理的情况下使用此AVP，并且实际启动mediaproxy的代理不直接从UA接收SIP消息，也无法确定信令来源的NAT IP地址。在这种情况下，在第一个代理附加一个SIP头，然后在启动mediaproxy的代理上将该头的值复制到signaling_ip_avp将允许它获取正确的信令来源NAT IP地址。


*默认值为"$avp(signaling_ip)"。*


```c title="设置 signaling_ip_avp 参数"
...
modparam("mediaproxy", "signaling_ip_avp", "$avp(nat_ip)")
...
        
```


#### media_relay_avp (string)


指定保存可选应用程序定义的媒体中继IP地址的AVP的规范，该特定媒体中继被首选用于当前呼叫。如果在调用use_media_proxy()之前将IP地址写入此AVP，它将被调度器优先于正常选择算法。


*默认值为"$avp(media_relay)"。*


```c title="设置 media_relay_avp 参数"
...
modparam("mediaproxy", "media_relay_avp", "$avp(media_relay)")
...
        
```


#### ice_candidate (string)


指示将添加到SDP的ICE候选类型。它可以取3个值：'none'、'low-priority'或'high-priority'。如果选择'none'，则不会将任何候选添加到SDP。如果选择'low-priority'，则添加低优先级候选；如果选择'high-priority'，则添加高优先级候选。


*默认值为"none"。*


```c title="设置 ice_candidate 参数"
...
modparam("mediaproxy", "ice_candidate", "low-priority")
...
        
```


#### ice_candidate_avp (string)


指定保存将插入SDP的ICE候选的AVP的规范。此AVP中指定的值将覆盖ice_candidate模块参数中的值。


请注意，如果正在使用use_media_proxy()和end_media_session()函数，AVP在reply route中不可用，除非您将tm模块的onreply_avp_mode设置为'1'。如果AVP未设置，将使用默认值。


*默认值为"$avp(ice_candidate)"。*


```c title="设置 ice_candidate_avp 参数"
...
modparam("mediaproxy", "ice_candidate_avp", "$avp(ice_candidate)")
...
        
```


### 导出的函数


#### engage_media_proxy()


触发对所有具有SDP body的对话请求和回复使用MediaProxy。这只需要为对话中的第一个INVITE调用一次。之后，它将使用dialog模块跟踪对话，并自动为属于该对话且带有SDP body的每个请求和回复调用use_media_proxy()。当对话结束时，它也会自动调用end_media_session()。所有这些都在dialog回调中内部调用，因此要使此函数工作，必须加载并配置dialog模块。


此函数是一种高级机制，无需在属于对话的每个消息上手动调用函数即可使用媒体中继。但是，此方法不太灵活，因为一旦通过在第一个INVITE上调用此函数启动事情，就无法停止，即使调用end_media_session()也无法停止。它只在对话结束时停止。在此之前，它会修改每个indialog消息的SDP内容以使其使用媒体中继。如果需要更多地控制过程，例如仅在failure route中开始使用mediaproxy，或在failure route中停止使用mediaproxy，则应使用use_media_proxy和end_media_session函数，并根据需要手动调用。不应将此函数与use_media_proxy()或end_media_session()混合使用。


此函数可用于REQUEST_ROUTE。


```c title="使用 engage_media_proxy 函数"
...
if (is_method("INVITE") && !has_totag()) {
    # 如果需要，我们也可以使用特定的媒体中继
    #$avp(media_relay) = "1.2.3.4";
    engage_media_proxy();
}
...
        
```


#### use_media_proxy()


将调用调度器，并用媒体中继返回的IP和端口替换SDP body中的IP和端口。这将强制媒体流通过媒体中继路由。如果SDP中存在支持和不支持的媒体流混合，只有支持的流会被修改，而不支持的流会保持不变。


此函数不应与engage_media_proxy()混合使用。


此函数有以下返回码：


- +1 - 成功修改消息（真值）
- -1 - 处理消息时出错（假值）
- -2 - 缺少SDP body，无可处理（假值）


此函数可用于REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE。


```c title="使用 use_media_proxy 函数"
...
if (is_method("INVITE")) {
    # 如果需要，我们也可以使用特定的媒体中继
    #$avp(media_relay) = "1.2.3.4";
    use_media_proxy();
}
...
        
```


#### end_media_session()


将调用调度器以通知媒体中继结束媒体会话。这是在呼叫结束时执行的，以指示媒体中继释放为该呼叫分配的资源，以及保存有关媒体会话的日志信息。在BYE、CANCEL或失败时调用。


此函数不应与engage_media_proxy()混合使用。


此函数可用于REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE。


```c title="使用 end_media_session 函数"
...
if (is_method("BYE")) {
    end_media_session();
}
...
        
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即.md扩展名）均采用知识共享署名4.0许可证。
