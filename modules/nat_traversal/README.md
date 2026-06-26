---
title: "NAT 穿越模块"
description: "nat_traversal 模块提供处理 SIP 信令远端 NAT 穿越的支持。该模块包括检测 NAT 后面的用户代理、修改 SIP 头以使用户代理透明地在 NAT 后面工作以及向 NAT 后面的用户代理发送保活消息以保持其在网络中的可见性等功能。"
---

## 管理指南


### 概述


nat_traversal 模块提供处理 SIP 信令远端 NAT
穿越的支持。该模块包括检测 NAT 后面的用户代理、
修改 SIP 头以使用户代理透明地在 NAT 后面工作,
以及向 NAT 后面的用户代理发送保活消息
以保持其在网络中的可见性等功能。该模块可以处理多个级联
NAT 盒子后面的用户代理,就像处理单层 NAT 后面的用户代理一样简单。


该模块设计用于在复杂环境中工作,其中可能涉及多个
SIP 代理处理注册和路由,且入站和出站路径不一定相同,
或者路由路径可能在连续对话之间甚至会改变。


### 保活功能


#### 概述


nat_traversal 模块实现了一个非常复杂的保活机制,
能够处理最复杂的环境和用例,包括具有多个代理的分布式环境。
与现有的仅向已注册用户代理发送保活消息的保活解决方案不同,
nat_traversal 模块可以基于多个条件保持用户代理的存活,
使其不仅更加灵活和高效,
而且能够在我持活注册 alone 无法工作的环境和用例中工作。


保活机制通过向 NAT 后面的用户代理发送 SIP 请求来工作,
以使该用户代理发送回复。目的是从 NAT 内部经常向代理发送数据包,
以防止 NAT 盒子超时连接。许多 NAT 盒子不认为从外部到内部的数据包
会重置连接到期计时器,因此，为了保持用户代理的存活,
我们需要从它触发一个回复。


#### 背景


仅向已注册用户代理发送保活消息的实现的一个主要限制是,
它在与网络可见性概念和用户注册概念之间创建了一个人为的关联。
注册过程仅为入站 INVITE 请求(即入站呼叫)创建网络可见性。
但是,在其他情况下,用户代理需要在 NAT 后面保持其网络可见性,
这些与接收入站呼叫无关。其中之一是用户代理能够继续接收其存在的订阅的 NOTIFY 请求。
另一种情况是用户代理应该能够接收对话中它所发起的所有消息,即使它没有注册。
在第一种情况下,存在代理需要注册才能接收其订阅的通知,
并且在整个订阅期间必须保持注册活动。
在第二种情况下,想要发起出站呼叫的用户代理需要注册,
并在呼叫期间保持注册活动,否则可能无法接收未来的对话内消息,
包括关闭对话的 BYE。


不仅我们有上面显示的强制关联,要求用户代理注册才能做任何事情,
而且基于仅向已注册用户代理发送保活消息的简单保活实现,
由于这种人为关联,在常见情况下也会失败。
例如,假设我们有一个已注册的用户代理。
如果该用户代理在发起的出站呼叫期间停止注册,
则在 NAT 绑定到期后,它将无法接收进一步的对话内消息。
对于接收其订阅通知的存在代理也是如此。


在多个代理处理相同域的环境中,问题变得更加严峻。
在这种情况下,呼叫的入站和出站路径可能完全不同:
用户代理可能使用一个代理作为网络入口点进行注册,
但可能使用不同的代理作为网络入口点发起出站呼叫。
甚至注册可能每次续订时使用不同的代理作为网络入口点,
使其变得不稳定和不可靠,除了入站呼叫。
仅向已注册用户代理发送保活消息的保活实现,
将无法保证为出站呼叫提供对话内消息的传递,
即使它要求用户代理在发起呼叫之前注册。
在这种情况下,即使我们假设用户代理会为其最后一次注册选择相同的代理,
但在下次注册时,它可能会选择另一个(由 DNS 返回),
并将分离入站和出站路径,使出站路径不可用
(假设呼叫持续时间超过注册期限)。


所有这些导致这样的结论:基于仅向已注册用户代理发送保活消息的保活实现,
只能在中单代理环境中工作,并且只有在与要求用户代理在任何其他操作之前注册的情况下才能可靠地工作,
即使某些操作不需要用户代理注册。


#### 实现


为避免上述问题,此实现引入了给定条件的网络可见性概念。
这样,我们可以为多个独立条件保持用户代理的存活,
从而避免上述所有问题。


模块将发送保活消息的条件如下:


- *注册* - 对于已注册以保持入站呼叫可见性的用户代理。
这是为 REGISTER 请求触发保活的结果。
- *订阅* - 对于已订阅某些事件以保持接收通知可见性的存在代理。
这是为 SUBSCRIBE 请求触发保活的结果。
- *对话* - 对于已发起出站呼叫以保持接收进一步对话内消息可见性的用户代理。
这是为出站 INVITE 请求触发保活的结果。


用户代理的 NAT 入口点可能为上述一个或多个条件保持存活。
即使为 NAT 入口点保持多个条件,
也只向该 NAT 入口点发送一条保活消息。
NAT 入口点的多个条件的存在,
仅保证基于某个条件的用户代理网络可见性在该条件为真时可用,
而与其他条件无关。当保持 NAT 入口点存活的所有条件消失时,
该入口点将从需要保持存活的 NAT 入口点列表中删除。


保活功能的用户界面非常简单。它由一个名为 nat_keepalive() 的函数组成,
只需要为触发网络可见性需求的请求调用一次。
这些请求是:REGISTER、SUBSCRIBE 和出站 INVITE。
请求到达后,它使用户代理可见用于接收其他消息。
因此,REGISTER 后,用户代理可以接收入站呼叫;
SUBSCRIBE 后,可以接收通知;
出站 INVITE 后,可以接收进一步的对话内消息,包括结束对话的 BYE。
nat_keepalive() 函数需要在直接接收用户代理请求的代理上调用,
如果它确定发出请求的用户代理在 NAT 后面。
该函数需要在请求得到无状态回复或通过 t_relay() 转发之前调用。
如果请求没有得到无状态回复或未被转发,则调用 nat_keepalive() 函数无效。


对于具有多个代理的环境,其中充当给定请求网络入口点的代理
不是实际处理请求的代理,
则需要在入口点代理上调用 nat_keepalive() 函数,
然后使用 t_relay() 将请求发送到实际处理请求的代理。
这是必需的,因为保活功能从无状态回复或 TM 转发的回复中检测
NAT 入口点是否需要为触发请求的条件保持存活。
例如,假设网络中有代理 P1 接收来自 NAT 后面用户代理的 REGISTER。
P1 将确定用户代理在 NAT 后面,需要保活功能,
但另一个名为 P2 的代理实际处理订户注册。
在这种情况下,P1 必须调用 nat_keepalive(),即使它还不知道 P2 将对 REGISTER 请求
给出的答案(甚至可能是否定回复),或者 P2 将如何以任何方式限制建议的到期时间。
因此,P1 调用 nat_keepalive(),然后调用 t_relay()。
当来自 P2 的回复到达时,触发一个回调,该回调将确定请求是否得到肯定回复,
如果是,将提取注册到期时间,并为该入口点启用注册条件的保活功能,
时间为注册到期时间。
对于单代理环境,或者如果 P1 与 P2 相同,
则不调用 t_relay(),而是调用 save_location()(如果注册被接受)。
然后发生上述相同的过程,只是这次由无状态回复回调触发。
在这两种情况下,在收到 REGISTER 时调用 nat_keepalive()
没有其他作用,只是触发一些回调,这些回调将从回复中确定
呼叫端点是否应该保持存活。


下面描述了如何为需要保活功能的每个请求调用 nat_keepalive() 及其作用
(仅当生成请求的用户代理在 NAT 后面时才应调用):


- *REGISTER* - 在 save_location() 或
t_relay()(取决于接收 REGISTER 的代理是否也处理该订户的注册)之前调用。
它将从 save_location() 生成的无状态回复或 TM 转发的回复中确定注册是否成功及其到期时间。
如果注册成功,它将使用检测到的到期时间将给定 NAT 入口点标记为注册条件的保活。
如果 nat_keepalive() 被调用后 REGISTER 请求被丢弃,
或者如果它截获了否定回复,则它将不起作用,并且该入口点将不会激活注册条件。
- *SUBSCRIBE* - 在 handle_subscribe()
或 t_relay()(取决于接收 SUBSCRIBE 的代理是否也处理该订户的订阅)之前调用。
它将从 handle_subscribe() 生成的无状态回复或 TM 转发的回复中确定订阅是否成功及其到期时间。
如果订阅成功,它将使用检测到的到期时间将给定 NAT 入口点标记为订阅条件的保活。
如果 nat_keepalive() 被调用后 SUBSCRIBE 请求被丢弃,
或者如果它截获了否定回复,则它将不起作用,并且该入口点将不会激活订阅条件。
应该为收到的每个 SUBSCRIBE 调用,而不仅仅是启动订阅的 SUBSCRIBE(没有 to tag),
因为它需要更新(扩展)订阅的到期时间。
- *INVITE* - 在对话框第一次 INVITE 的 t_relay() 之前调用。
它将自动触发该对话框的对话框跟踪,
并使用对话框回调来检测对话框状态的变化。
它将在对话框创建时(调用 t_relay() 时发生)为呼叫者 NAT 入口点添加一个带有对话框条件的保活条目。
然后它将为该入口点保持该条件,直到对话框被销毁(终止、失败或过期)。
如果 nat_keepalive() 被调用后无法转发 INVITE 请求,
则它将不起作用,并且该入口点将不会激活对话框条件。
此外,启动对话框的 INVITE 将自动为目的地入口点触发保活功能,
如果它们在 NAT 后面。这是通过检测任何目的地入口点是否已有注册条件的保活条目来完成的。
如果是,则将对话框条件添加到该条目,从而在注册期间或被移动到另一个代理时保持该入口点的可见性。
在呼叫建立阶段,如果使用并行分叉,可以为被叫者添加多个带有对话框条件的条目,
但只有在 NAT 后面的目的地入口点才会设置额外的对话框条件。
稍后,当对话框被确认时,只有应答呼叫的入口点将保持对话框条件激活(如果存在),
而所有未应答分支的入口点将移除该条件。这是自动完成的,无需调用任何函数。


考虑到本节中呈现的元素,我们可以说 nat_traversal 模块提供了一种灵活高效的保活功能,
非常易于使用。因为只有边界代理发送保活消息,所以网络流量被最小化。
同样,代理中的消息处理也被最小化,因为边界代理自己生成保活消息并以无状态方式发送,
而不是必须中继由注册中心生成的消息。
通过仅为一个入口点发送一条保活消息(无论该入口点出于多少原因保持存活)也可以最小化网络流量。
保活消息也会在保活间隔上分布,以避免一次生成太多消息而使代理过载。
nat_traversal 模块保持关于需要保活的入口点的内部状态,
这些状态是在代理处理消息时构建的,
因此它不需要从 usrloc 模块传输任何信息,这也应该提高其效率。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载:


- *sl* 模块 - 如果启用保活。
- *tm* 模块 - 如果启用保活。
- *dialog* 模块 - 如果启用保活且需要保持 INVITE 对话存活。
- *clusterer* - 仅当启用 "cluster_id" 选项时。


#### 外部库或应用程序


运行 OpenSIPS 加载此模块之前必须安装以下库或应用程序:


- *无*。


### 导出的参数


#### keepalive_interval (integer)


向所有需要保持存活的端点发送保活消息的时间间隔(秒)。
在此间隔内,每个端点将正好收到一条保活消息。
负值或零将禁用保活功能。


*默认值为 "60"。*


```c title="设置 keepalive_interval 参数"
...
modparam("nat_traversal", "keepalive_interval", 90)
...
        
```


#### keepalive_method (string)


用于发送保活消息的 SIP 方法。用于此目的的典型方法是 NOTIFY 和 OPTIONS。
NOTIFY 从用户代理生成较小的回复,但它们几乎都是否定回复。
显然,几乎没有任何用户代理理解带有 "keep-alive" 事件的 NOTIFY 的目的是保持 NAT 开放,
尽管许多用户代理自己发送这样的 NOTIFY 请求。
然而,这完全不影响结果,因为目的是从 NAT 后面的用户代理触发响应,
肯定或否定回复几乎没有区别,因为它们无论如何都会被丢弃。
另一方面,OPTIONS 方法具有高得多的肯定回复率,
但同时那些肯定回复也大得多,主要是因为 OPTIONS 方法用于通知用户代理能力,
因此包含大量额外的头来指示这些能力。
许多用户代理还包括带有虚假媒体会话的 SDP 体,
可能是为了指示媒体能力。
所有这些使得对 OPTIONS 请求的肯定回复比对 NOTIFY 请求的回复大 2 到 3 倍。
因此,所用方法的默认值为 NOTIFY。


*默认值为 "NOTIFY"。*


```c title="设置 keepalive_method 参数"
...
modparam("nat_traversal", "keepalive_method", "OPTIONS")
...
        
```


#### keepalive_from (string)


指示在保活请求的 From 头中使用的 SIP URI。
如果未指定,它将使用 sip:keepalive@proxy_ip,其中
proxy_ip 是用于发送保活消息的传出接口的 IP 地址,
这是请求到达的传入接口的 IP 地址。


*默认值为 "sip:keepalive@proxy_ip",其中 proxy_ip 是实际传出接口的 IP。*


```c title="设置 keepalive_from 参数"
...
modparam("nat_traversal", "keepalive_from", "sip:keepalive@my-domain.com")
...
        
```


#### keepalive_extra_headers (string)


指定应添加到代理发送的保活消息的额外头。
头规范还必须包括 CRLF(\r\n) 行分隔符。
可以通过连接指定多个头,每个都必须包含 \r\n 分隔符。


*默认值为未定义(不发送额外头)。*


```c title="设置 keepalive_extra_headers 参数"
...
modparam("nat_traversal", "keepalive_extra_headers", "User-Agent: OpenSIPS\r\nX-MyHeader: some_value\r\n")
...
        
```


#### keepalive_state_file (string)


指定一个文件名,在 OpenSIPS 退出时保存有关 NAT 端点及其保持存活条件的信息。
此文件中的信息在 OpenSIPS 启动时使用,以恢复其内部状态,
并继续向在此期间未过期的 NAT 端点发送保活消息。
这在重启 OpenSIPS 时很有用,可避免丢失有关 NAT 端点的保活状态信息。
保证在退出时将此文件中的内部保活状态保存,
即使 OpenSIPS 崩溃也是如此。


此参数的值可以是相对路径,在这种情况下,
它将存储在 OpenSIPS 工作目录中,或者是绝对路径。


*默认值为未定义 "keepalive_state"。*


```c title="设置 keepalive_state_file 参数"
...
modparam("nat_traversal", "keepalive_state_file", "/run/opensips/keepalive_state")
...
        
```


#### cluster_id (integer)


模块所属集群的 ID。集群支持由 nat_traversal 模块用于控制 ping 过程。
当作为多个节点的集群的一部分时,节点可以商定哪个节点是负责 ping 的节点。


可以使用带共享标签的集群来控制集群中的哪个节点将对联系人执行 ping/探测。
请参阅 [cluster sharing tag](#param_cluster_sharing_tag) 选项。


有关如何定义和填充集群(使用 OpenSIPS 节点)的更多信息,请参阅 "clusterer" 模块。


*默认值为 "0(无)。"*


```c title="设置 cluster_id 参数"
...
# 成为集群 ID 9 的一部分
modparam("nat_traversal", "cluster_id", 9)
...
```


#### cluster_sharing_tag (string)


共享标签的名称(按 clusterer 模块定义)用于控制哪个节点负责对联系人执行 ping。
如果定义,则只有具有此标签活动状态的节点将执行 ping。


此选项必须定义 [cluster id](#param_cluster_id) 才能工作。


这是一个可选参数。如果未设置,集群中的所有节点将单独执行 ping。


*默认值为 "空(无)。"*


```c title="设置 cluster_sharing_tag 参数"
...
# 只有具有活动 "vip" 共享标签的节点将执行 ping
modparam("nat_traversal", "cluster_id", 9)
modparam("nat_traversal", "cluster_sharing_tag", "vip")
...
```


### 导出的函数


#### client_nat_test(type)


检查客户端是否在 NAT 后面。执行的测试由 type 参数指定,
该参数是一个整数,由希望执行的测试对应数字的总和组成。
各个测试对应的数字如下所示:


- 1 - 测试客户端是否在 SIP 消息的 Contact 字段中有私有 IP 地址(如 RFC1918 所定义)
- 2 - 测试客户端是否从与 Via 字段中不同的地址联系 OpenSIPS。
此测试比较 IP 和端口。
- 4 - 测试客户端是否在 SIP 消息的顶层 Via 字段中有私有 IP 地址(如 RFC1918 所定义)
- 8 - 测试客户端是否从与 Contact 字段中不同的地址联系 OpenSIPS。
仅比较 IP。

例如,调用 client_nat_test(3) 将执行测试 1 和测试 2,
如果至少一个成功则返回 true,否则返回 false。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE。


```c title="使用 client_nat_test 函数"
...
if (client_nat_test(3)) {
    .....
}
...
        
```


#### fix_contact()


将 Contact 头中的 IP 和端口替换为接收 SIP 消息的 IP 和端口。
通常在成功调用 client_nat_test(type) 后调用。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE。


```c title="使用 fix_contact 函数"
...
if (client_nat_test(3)) {
    fix_contact();
}
...
        
```


#### nat_keepalive()


为请求的源地址触发保活功能。调用时,它仅设置一些内部标志,
这些标志将在稍后(对于 REGISTER 和 SUBSCRIBE)在生成/收到肯定回复时,
或(对于 INVITE)在对话框开始/回复时触发将端点添加到保活列表。
因此,可以早或晚在脚本中调用它。
唯一条件是在回复请求之前或将其发送到另一个代理之前调用它。
如果需要将请求发送到另一个代理,必须使用 t_relay() 才能通过 TM 或对话框回调截获回复。
如果使用无状态转发,保活功能将不起作用。
同样,对于出站 INVITE,还应使用 record_route() 以确保保持呼叫者端点存活的代理留在路径中。
对于多代理设置,此函数应始终在边界代理(直接接收用户代理请求的代理)上调用。
有关此函数的更多详细信息,请参阅 *保活功能* 部分的 *实现* 小节。


此函数可用于 REQUEST_ROUTE。


```c title="使用 nat_keepalive 函数"
...
if (($rm=="REGISTER" || $rm=="SUBSCRIBE" ||
    ($rm=="INVITE" && !has_totag())) && client_nat_test(3))
{
    nat_keepalive();
}
...
        
```


### 导出的统计


#### keepalive_endpoints


指示正在保持存活的 NAT 端点的总数。


#### registered_endpoints


指示有多少 NAT 端点为注册而保持存活。


#### subscribed_endpoints


指示有多少 NAT 端点为订阅而保持存活。


#### dialog_endpoints


指示有多少 NAT 端点为参与 INVITE 对话而保持存活。


### 导出的伪变量


#### $keepalive.socket(nat_endpoint)


返回用于向给定 NAT 端点 URI 发送消息的本地套接字。
套接字格式为 proto:ip:port。NAT 端点 URI 格式为 sip:ip:port[;transport=xxx],
如果使用 UDP 则 transport 缺失。
如果请求的 NAT 端点 URI 在任何条件的内部保活表中存在,
它将返回其关联的本地套接字,否则返回 null。
nat_endpoint 可以是字符串或其他伪变量。


这可用于在多代理环境中中继消息到给定用户代理时恢复发送套接字。
考虑一个涉及 2 个代理 P1 和 P2 的示例。
用户代理通过向 P1 发送 REGISTER 请求进行注册。
P1 将调用 nat_keepalive(),但因为它确定 P2 实际上应该处理用户注册,
会将请求转发给 P2。
现在假设 P2 收到该用户的入站 INVITE。
它将确定注册是通过 P1 进行的,
并将请求转发给 P1。
P2 还应包含此请求要转发到的 NAT 端点 URI。
此信息应在 P1 将 REGISTER 请求转发给 P2 时由 P1 提供。
做到这一点的手段超出了此示例的范围,
但可以使用路径扩展或自定义头来做到这一点。
当 P1 收到 INVITE 时,它将使用随请求一起收到的 NAT 端点 URI 来确定发送请求的套接字,
这应该与最初接收注册请求的套接字相同。
在下面的示例中,我们假设 P2 在名为 X-NAT-URI 的自定义头中提供了原始 NAT 端点地址,
并且还提供了一个名为 X-Scope 的自定义头来指示消息被发送到 P1,
以由 P1 中继回用户代理,因为 P1 与它保持着 NAT 开放。


```c title="在多代理环境中使用 $keepalive.socket"
...
# 此代码在 P1 上运行,P1 已收到来自 P2 的 INVITE 以转发到 NAT 后面的用户代理(因为 P1 与它保持着 NAT 开放)。
if ($rm=="INVITE" && $hdr(X-Scope)=="nat-relay") {
    $du = $hdr(X-NAT-URI);
    $fs = $keepalive.socket($du);
    t_relay();
    exit;
}
...
        
```


#### $source_uri


返回请求接收位置的 URI,格式为 sip:ip:port[;transport=xxx],
如果使用 UDP 则 transport 缺失。


此伪变量可用于设置 registrar 模块的 received AVP,
以指示用户代理在 NAT 后面。
这是作为 fix_nated_register() 函数的更灵活的替代方案,
因为它允许在保存到 received AVP 之前通过附加一些额外参数来修改源 URI。


此伪变量的另一个用途是在多代理环境中向下一个代理指示 NAT 端点 URI(如果需要)。
考虑前面带有两个代理 P1 和 P2 的示例。
P1 接收用户代理的 REGISTER 请求并将其转发给实际执行注册的 P2。
P1 需要向 P2 指示 NAT 端点 URI,以便 P2 稍后可以在入站 INVITE 请求中包含它。


```c title="使用 $source_uri 设置 registrar 的 received AVP"
...
modparam("registrar", "received_avp", "$avp(received_uri)")
modparam("registrar", "tcp_persistent_flag", 10)
...
# 此代码在 registrar 上运行,假设它已直接从用户代理接收 REGISTER 请求。
if ($rm=="REGISTER") {
    if (client_nat_test(3)) {
        if ($socket_in(proto)==UDP) {
            nat_keepalive();
        } else {
            # 保持 TCP/TLS 连接打开直到注册到期,通过设置 tcp_persistent_flag
            setflag(10);
        }
        force_rport();
        $avp(received_uri) = $source_uri;
        # 或者如果需要我们可以向它添加一些额外参数
        # $avp(received_uri) = $source_uri + ";relayed=false" 
    }
    if (!www_authorize("", "subscriber")) {
        www_challenge("", "0");
        return;
    } else if ($au!=$tU) {
        sl_send_reply("403", "Username!=To not allowed ($au!=$tU)");
        return;
    }

    if (!save("location")) {
        sl_reply_error();
    }
    exit;
}
...
        
```


```c title="在多代理环境中使用 $source_uri"
...
# 此代码在 P1 上运行,P1 接收 REGISTER 请求并必须将其转发给 registrar P2。
if ($rm=="REGISTER") {
    if (client_nat_test(3)) {
        force_rport();
        nat_keepalive();
        append_hf("X-NAT-URI: $source_uri\r\n");
    }
    $du = "sip:P2_ip:P2_port";
    t_relay();
    exit;
}
...
        
```


#### $nat_traversal.track_dialog


返回一个布尔值(0 或 1),指示 nat_traversal 模块是否将启用对话框跟踪。
nat_traversal 模块将始终跟踪对话框(通过内部调用 create_dialog),
除非被告知不要这样做。


这是一个高级设置,仅适用于多代理环境,
在这种情况下,代理不想跟踪对话框,即如果它不会保持在信令路径中。


通过将此 pv 设置为 0,nat_traversal 模块将不会尝试创建对话框。


### 保活用例


#### 单代理环境


在这种情况下,用法很简单。
nat_keepalive() 函数需要在 REGISTER 请求的 save_location() 之前、
SUBSCRIBE 请求的 handle_subscribe() 之前,
以及对话框第一次 INVITE 的 t_relay() 之前调用。


#### 多代理环境中的注册


如果接收 REGISTER 请求的代理与处理它的代理相同,
则情况归结为单代理情况。
对于此示例,我们假设它们不同。
我们有一个用户代理 UA1,其注册由代理 P1 处理。
然而 UA1 将 REGISTER 发送到 P0,P0 再将其转发给 P1,如下所示:
UA1 --> P0 --> P1。在这种情况下,P0 调用 nat_keepalive(),
将 NAT 端点 URI 添加到请求(例如使用自定义头),
并将请求转发给 P1。
P1 将把用户连同 NAT 端点 URI 保存到用户位置。


当入站 INVITE 请求到达 P1 时,P1 将查找位置,
并确定它必须转发给 P0,因为 P0 与 UA1 保持着 NAT 开放。
P1 将包括原始 NAT 端点 URI 和一个指示,
表明 P0 在此事务中的唯一角色是将其转发给 UA1。
P0 将收到此请求并确定它必须充当其中继。
它将提取 NAT 端点 URI,然后基于它使用 $keepalive.socket(endpoint_uri) 找到相应的本地套接字。
然后它将设置 $du 和 $fs 为找到的值,
调用 record_route() 以保持在路径中,
然后调用 t_relay() 将其发送给 UA1。


处理其他类型的请求(如 SUBSCRIBE 或 MESSAGE)的方式与 P1 和 P0 上第一次 INVITE 的处理方式相同。


#### 多代理环境中的订阅


如果接收 SUBSCRIBE 请求的代理与处理它的代理相同,
则情况归结为单代理情况。
对于此示例,我们假设它们不同。
我们有一个用户代理 UA1,其订阅由代理 P1 处理。
然而 UA1 将 SUBSCRIBE 发送到 P0,P0 再将其转发给 P1,如下所示:
UA1 --> P0 --> P1。在这种情况下,P0 调用 nat_keepalive(),
然后调用 record_route() 以保持在路径中,
然后使用 t_relay() 将请求转发给 P1。
后续的 SUBSCRIBE 和 NOTIFY 请求将遵循记录路由,
并使用 P0 作为 NAT 入口点来访问 UA1。
后续的对话内 SUBSCRIBE 请求也应该调用 record_route()。


#### 多代理环境中的出站 INVITE


如果接收 INVITE 请求的代理与处理它的代理相同,
则情况归结为单代理情况。
对于此示例,我们假设它们不同。
我们有一个由代理 P1 处理的 UA1 和一个由 P2 处理的 UA2。
UA2 已通过 P3 注册到 P2,而 UA1 通过发送第一次 INVITE 到 P0 来调用 UA2。
第一次 INVITE 的呼叫流程如下:
UA1 --> P0 --> P1 --> P2 --> P3 --> UA2。
在这种情况下,P0 调用 nat_keepalive(),
然后调用 record_route() 以保持在路径中,
并将请求转发给 P1。
P1 对 UA1 进行身份验证,然后将请求转发给 P2,P2 是 UA2 的主代理。
P1 不必使用 record_route 保持在路径中,但如果需要可以这样做。
P2 将查找 UA2,并发现它可以通过 P3 访问。
它将采用在 UA2 注册时保存在用户位置中的原始 NAT 端点 URI,
并将其包含在消息中,以及一个指示,表明 P3 只需要将消息中继给 UA2。
如果 P2 进行记帐或启动媒体中继,它也应该调用 record_route() 以保持在路径中。
然后使用 t_relay() 将请求转发给 P3。
P3 将检测到它只需要将请求中继给 UA2,因为它与 UA2 保持着 NAT 开放。
它将从消息中提取 NAT 端点 URI,
并使用 $keepalive.socket(endpoint_uri) 找到本地发送套接字,
然后设置 $du 和 $fs。
之后,它将调用 record_route() 以保持在路径中,
然后使用 t_relay() 将请求转发给 UA2。
后续的对话内请求将遵循记录的路由,
并分别使用 P0 和 P3 作为 UA1 和 UA2 的接入点。
所有在第一次 INVITE 期间使用 record_route() 的代理也应在后续的对话内请求中调用 record_route(),
以继续保持在该路径中。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)均采用知识共享许可证 4.0 版授权
