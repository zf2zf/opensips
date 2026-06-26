---
title: "SNMPStats 模块（简单网络管理协议统计模块）"
description: "SNMPStats 模块提供到 OpenSIPS 的 SNMP 管理接口。具体来说，它提供通用的 SNMP 可查询标量统计、更复杂数据（如用户和联系人信息）的表表示，以及告警监控功能。"
---

## 管理指南


### 概述


SNMPStats 模块提供到 OpenSIPS 的 SNMP 管理接口。
具体来说，它提供通用的 SNMP 可查询标量统计、
更复杂数据（如用户和联系人信息）的表表示，
以及告警监控功能。


#### 通用标量统计


SNMPStats 模块提供许多通用标量统计。
详细信息可在 OPENSER-MIB、OPENSER-REG-MIB、
OPENSER-SIP-COMMON-MIB 和 OPENSER-SIP-SERVER-MIB 中找到。
但简要地说，这些标量如下：


openserSIPProtocolVersion, openserSIPServiceStartTime,
			openserSIPEntityType,
			openserSIPSummaryInRequests, openserSIPSummaryOutRequest,
			openserSIPSummaryInResponses, openserSIPSummaryOutResponses,
			openserSIPSummaryTotalTransactions, openserSIPCurrentTransactions,
			openserSIPNumUnsupportedUris, openserSIPNumUnsupportedMethods,
			openserSIPOtherwiseDiscardedMsgs, openserSIPProxyStatefulness
			openserSIPProxyRecordRoute, openserSIPProxyAuthMethod,
			openserSIPNumProxyRequireFailures,
			openserSIPRegMaxContactExpiryDuration,
			openserSIPRegMaxUsers, openserSIPRegCurrentUsers,
			openserSIPRegDfltRegActiveInterval,
			openserSIPRegAcceptedRegistrations,
			openserSIPRegRejectedRegistrations, openserMsgQueueDepth.
			openserCurNumDialogs, openserCurNumDialogsInProgress,
			openserCurNumDialogsInSetup, openserTotalNumFailedDialogSetups


还有一些与告警相关的标量。它们如下：


openserMsgQueueMinorThreshold, openserMsgQueueMajorThreshold,
			openserMsgQueueDepthAlarmStatus, openserMsgQueueDepthMinorAlarm,
			openserMsgQueueDepthMajorAlarm, openserDialogLimitMinorThreshold,
			openserDialogLimitMajorThreshold, openserDialogUsageState,
			openserDialogLimitAlarmStatus, openserDialogLimitMinorAlarm,
			openserDialogLimitMajorAlarm


#### SNMP 表


SNMPStats 模块提供多个表，包含更复杂的数据。
当前可用的表如下：


openserSIPPortTable, openserSIPMethodSupportedTable,
			openserSIPStatusCodesTable, openserSIPRegUserTable,
			openserSIPContactTable, openserSIPRegUserLookupTable


#### 告警监控


如果启用，SNMPStats 模块将监控告警条件。
当前定义了两类告警类型。


1. 活动对话框的数量已超过次要或主要阈值。
				其理念是网络运营中心可以意识到其 SIP 服务器可能过载，
				而无需明确检查此条件。
如果发生次要或主要条件，
				将分别生成 openserDialogLimitMinorEvent 陷阱或
				openserDialogLimitMajorEvent 陷阱。
				次要和主要阈值在下面的参数部分中描述。
2. 在所有 OpenSIPS 监听端口上等待被使用的字节数已超过次要或主要阈值。
				其理念是网络运营中心可以意识到托管 SIP 服务器的机器可能进入降级状态，
				并调查原因。
如果等待使用的字节数超过次要或主要阈值，
				将分别发送 openserMsgQueueDepthMinorEvent 或
				openserMsgQueueDepthMajorEvent 陷阱。


这些陷阱的完整详细信息可在发行版的 OPENSER-MIB 文件中找到。


### 工作原理


#### SNMPStats 模块如何获取其数据


SNMPStats 模块使用 OpenSIPS 内部统计框架来收集其大部分数据。
但有两个例外。


1. openserSIPRegUserTable 和 openserSIPContactTable 依赖于
				usrloc 模块的回调系统。
				具体来说，SNMPStats 模块将在用户/联系人添加到系统时接收回调。
2. SNMPStats 模块的 openserSIPMsgQueueDepthMinorEvent 和
				openserSIPMsgQueueDepthMajorEvent 告警依赖于 OpenSIPS
				核心来了解 OpenSIPS 正在监听哪些接口、端口和传输。
				但是，该模块实际上会查询 proc 文件系统来了解等待使用的字节数。
				（目前，这仅适用于提供 proc 文件系统的系统）。


#### 数据如何从 SNMPStats 模块移动到 NOC


我们已经解释了 SNMPStats 模块如何收集其数据。
我们仍然没有解释它如何将此数据导出到 NOC（网络运营中心）或管理员。


SNMPStats 模块希望连接到 *Master Agent*。
这将是一个 SNMP 守护进程，运行在与 OpenSIPS 实例相同的系统上，或在另一个系统上。
（通信可以通过 TCP 进行，因此此守护进程不必与 OpenSIPS 在同一系统上，没有限制）。


如果主代理在 OpenSIPS 首次启动时不可用，SNMPStats 模块将继续运行。
但是，您将无法查询它。
值得庆幸的是，SNMPStats 模块会持续查找其主代理。
因此，即使主代理启动较晚，或者到 SNMPStats 模块的链接因临时硬件故障或主代理崩溃和重启而中断，
链接最终也会重新建立。
不应丢失任何数据，可以再次开始查询。


要请求此数据，您需要查询主代理。
主代理将重定向请求到 SNMPStats 模块，
SNMPStats 模块将响应主代理，
主代理将依次响应您的请求。


### 依赖


#### OpenSIPS 模块


SNMPStats 模块提供了大量统计信息，其中一些由其他模块收集。
如果依赖模块未加载，那些特定统计信息仍会返回，但值为零。
所有其他统计信息将正常运行。
这意味着 SNMPStats 模块对其他模块没有*硬/强制*依赖。
但是，存在*软*依赖，如下：


- *usrloc* - 所有与用户和联系人相关的标量和表都依赖于 usrloc 模块。
		如果该模块未加载，相应的表将为空。
- *dialog* - 所有与对话框数量相关的标量都依赖于 dialog 模块的存在。
		此外，如果该模块未加载，
		openserDialogLimitMinorEvent 和 openserDialogLimitMajorEvent 告警将被禁用。


openserSIPMethodSupportedTable 的内容取决于加载的模块。


#### 外部库或应用程序


运行 OpenSIPS 并加载此模块之前必须安装以下库或应用程序：


- *Net SNMP DEV (Debian 上的 libsnmp-dev)* - SNMP
			库（开发文件）必须在编译时安装。
			此外，在加载 SNMPStats 时必须加载多个共享对象。
			这意味着 SNMP lib 必须安装在加载 SNMPStats 模块的系统上（但不一定运行）。
			（详细信息可在下面的编译部分找到）。
- *SNMP 工具 (Debian 上的 snmp)* - SNMP
			工具包，用于提供 snmpget 命令（SNMPStats 模块内部使用）。


### 导出的参数


#### sipEntityType (String)


此参数描述此 OpenSIPS 实例的实体类型，
		将用于确定返回给 openserSIPEntityType 标量的内容。
		有效参数如下：


*registrarServer, redirectServer, proxyServer, userAgent, other*


```c title="设置 sipEntityType 参数"
...
modparam("snmpstats", "sipEntityType", "registrarServer")
modparam("snmpstats", "sipEntityType", "proxyServer")
...

```


请注意，如上面的示例所示，您可以多次定义此参数。
当然，这是因为给定的 OpenSIPS 实例可以承担多个角色。


#### MsgQueueMinorThreshold (Integer)


SNMPStats 模块监控等待 OpenSIPS 使用的字节数。
如果等待使用的字节数超过次要阈值，
SNMPStats 模块将发出 openserMsgQueueDepthMinorEvent 陷阱以发出告警条件已发生的信号。
次要阈值通过 MsgQueueMinorThreshold 参数设置。


```c title="设置 MsgQueueMinorThreshold 参数"
...
modparam("snmpstats", "MsgQueueMinorThreshold", 2000)
...

```


如果未设置此参数，则不会有次要告警监控。


#### MsgQueueMajorThreshold (Integer)


SNMPStats 模块监控等待 OpenSIPS 使用的字节数。
如果等待使用的字节数超过主要阈值，
SNMPStats 模块将发出 openserMsgQueueDepthMajorEvent 陷阱以发出告警条件已发生的信号。
主要阈值通过 MsgQueueMajorThreshold 参数设置。


```c title="设置 MsgQueueMajorThreshold 参数"
...
modparam("snmpstats", "MsgQueueMajorThreshold", 5000)
...

```


如果未设置此参数，则不会有主要告警监控。


#### dlg_minor_threshold (Integer)


SNMPStats 模块监控活动对话框的数量。
如果活动对话框的数量超过次要阈值，
SNMPStats 模块将发出 openserDialogLimitMinorEvent 陷阱以发出告警条件已发生的信号。
次要阈值通过 dlg_minor_threshold 参数设置。


```c title="设置 dlg_minor_threshold 参数"
...
  modparam("snmpstats", "dlg_minor_threshold", 500)
...

```


如果未设置此参数，则不会有次要告警监控。


#### dlg_major_threshold (Integer)


SNMPStats 模块监控活动对话框的数量。
如果活动对话框的数量超过主要阈值，
SNMPStats 模块将发出 openserDialogLimitMajorEvent 陷阱以发出告警条件已发生的信号。
主要阈值通过 dlg_major_threshold 参数设置。


```c title="设置 dlg_major_threshold 参数"
...
  modparam("snmpstats", "dlg_major_threshold", 750)
...

```


如果未设置此参数，则不会有主要告警监控。


#### snmpgetPath (String)


SNMPStats 模块提供 openserSIPServiceStartTime 标量。
此标量需要 SNMPStats 模块对主代理执行 snmpget 查询。
您可以使用此参数设置 SNMP 的 snmpget 程序的路径。


*默认值为 "/usr/local/bin/"。*


```c title="设置 snmpgetPath 参数"
...
modparam("snmpstats", "snmpgetPath",     "/my/custom/path/")
...

```


#### snmpCommunity (String)


SNMPStats 模块提供 openserSIPServiceStartTime 标量。
此标量需要 SNMPStats 模块对主代理执行 snmpget 查询。
如果您为 snmp 守护进程定义了自定义社区字符串，您需要使用此参数指定它。


*默认值为 "public"。*


```c title="设置 snmpCommunity 参数"
...
modparam("snmpstats", "snmpCommunity", "customCommunityString")
...

```


### 导出的函数


目前没有导出的函数。


### 安装和运行


需要做几件事来让 SNMPStats 模块编译和运行。


#### 编译 SNMPStats 模块


为了编译 SNMPStats 模块，您需要安装提供 SNMP（简单网络管理协议）库和开发文件的包。


SNMPStats 模块的 makefile 要求 SNMP 脚本
"net-snmp-config" 可以运行。


重要提示：默认情况下，SNMP 从 */var/lib/mibs/ietf/* 加载 *mibs*。
请记住将 OpenSIPS *mibs* 复制到您的 mibs 文件夹。


#### 配置 SNMP 守护进程以允许来自 SNMPStats 模块的连接。


SNMPStats 模块将通过称为 AgentX 的协议与 SNMP Master Agent 通信。
这意味着您需要运行一个 SMP 守护进程（充当 Master Agent）——它可以在同一台机器上，也可以在另一台机器上。


首先您需要开启 AgentX 支持。
配置文件 (snmpd.conf) 的确切位置可能因系统而异。
默认情况下，通过包安装，它位于：


```c
    /etc/snmp/snmpd.conf.

```


在文件末尾添加以下行：


```c
    master agentx

```


该行告诉 SNMP 守护进程充当 AgentX 主代理，
以便它可以接受来自 SNMPStats 模块等子代理的连接。


还有最后一步。
即使我们已经配置了 SNMP 具有 AgentX 支持，
我们仍然需要告诉守护进程监听 AgentX 连接的接口和端口。
这也通过配置文件 (snmpd.conf) 完成：


```c
    agentXSocket    tcp:localhost:705

```


这告诉 SNMP 守护进程充当主代理，
在 localhost UDP 接口的端口 705 上监听。


#### 配置 SNMPStats 模块与 Master Agent 通信


上一节说明了如何设置 SNMP 主代理以接受 AgentX 连接。
我们现在需要告诉 SNMPStats 模块如何与此主代理通信。
这是通过给 SNMPStats 模块自己的 SNMP 配置文件来完成的。
该文件必须命名为 "snmpstats.conf"，并且必须位于上面配置的 "snmpd.conf" 文件的同一文件夹中。
默认情况下，这将是：


```c
    /etc/snmp/snmpstats.conf

```


发行版中包含的默认配置文件可以使用，内容如下：


```c
    agentXSocket tcp:localhost:705

```


上述行告诉 SNMPStats 模块在 localhost 的端口 705 上向主代理注册。
参数应与 snmpd 进程匹配。
请注意，主代理 (snmpd) 不必与 OpenSIPS 在同一台机器上。
localhost 可以替换为任何其他机器。


#### 测试配置是否正确


作为快速测试以确保 SNMPStats 模块子代理可以成功连接到 SNMP Master Agent，
请确保 snmpd 服务已停止 (/etc/init.d/snmpd stop)，
并使用以下命令手动启动 snmpd：


```c
    snmpd -f -Dagentx -x tcp:localhost:705 2>&1 | less

```


您应该看到类似以下内容：


```c
    No log handling enabled - turning on stderr logging
    registered debug token agentx, 1
    ...
    Turning on AgentX master support.
    agentx/master: initializing...
    agentx/master: initializing...   DONE
    NET-SNMP version 5.3.1

```


现在，在另一个窗口中启动 OpenSIPS。
在 snmpd 窗口中，您应该会看到一堆：


```c
    agentx/master: handle pdu (req=0x2c58ebd4,trans=0x0,sess=0x0)
    agentx/master: open 0x81137c0
    agentx/master: opened 0x814bbe0 = 6 with flags = a0
    agentx/master: send response, stat 0 (req=0x2c58ebd4,trans=0x0,sess=0x0)
    agentx_build: packet built okay

```


以 "agentx" 开头的消息是调试消息，表明子代理发生了某些事情，
由于 -Dagentx snmpd 开关而出现。
大量调试消息在启动时出现，因为 SNMPStats 模块向 Master Agent 注册其所有标量和表。
如果您收到这些消息，则 SNMPStats 模块和 SNMP 守护进程都已正确配置。


## 常见问题


**问：在哪里可以找到更多关于 SNMP 的信息？**


有许多网站以各种详细程度解释 SNMP。
			可以在 http://en.wikipedia.org/wiki/SNMP 找到一个很好的通用介绍。

			如果您对协议的细节感兴趣，
			请查看 RFC 3410。
			RFC 3410 概述了定义 SNMP 的许多其他 RFC，
			可以在 http://www.rfc-archive.org/getrfc.php?rfc=3410 找到。

			另外，如果您想要一个很好的关于在 OpenSIPS 中设置 snmpstats 的教程，请尝试
			[这个](http://saevolgo.blogspot.ro/2012/09/opensips-monitoring-using-snmp-part-i.html)。


**问：在哪里可以找到更多关于 NetSNMP 的信息？**


NetSNMP 源代码、文档、FAQ 和教程都可以在
			http://net-snmp.sourceforge.net/ 找到。


**问：在哪里可以找到更多关于 AgentX 的信息？**


AgentX 协议的完整详细信息在 RFC 2741 中解释，
			可在此处获取：http://www.rfc-archive.org/getrfc.php?rfc=2741


**问：为什么我没有收到任何 SNMP 陷阱？**


假设您已使用类似以下内容在 opensips.cfg 中配置了陷阱阈值：

那么要么 OpenSIPS 没有达到这些阈值（这是好事），
		要么您没有正确设置陷阱监控。
		为了向自己证明这一点，您可以使用以下命令启动 NetSNMP：

-f 告诉 NetSNMP 进程不要守护化，-Dtrap 启用陷阱调试日志。
		您应该看到类似以下内容：

如果上述两行没有出现，那么您可能没有在 snmpd.conf 文件中包含以下内容。

当 snmpd 收到陷阱时，上述输出中将出现以下内容：

您还需要一个程序来收集陷阱并对其进行处理（如将它们发送到 syslog）。
NetSNMP 为此提供 snmptrapd。
也存在其他解决方案。
Google 是您的朋友。


**问：OpenSIPS 拒绝加载 SNMPStats 模块。为什么显示 "load_module: could not open module snmpstats.so"？**


在某些系统上，您可能会在 stdout 或日志文件中收到以下错误（取决于配置）。

这意味着两种情况之一：

在第二种情况下，修复如下：

或者，您可以在启动命令前加上：

例如，在我的系统上，我运行了：


**问：如何了解所有标量和表？**


所有标量和表的名称都在 SNMPStats 模块概述中给出。
		OPENSER-MIB、OPENSER-REG-MIB、OPENSER-SIP-COMMON-MIB 和 OPENSER-SIP-SERVER-MIB 文件
		包含完整的定义和描述。
		但请注意，MIB 实际上可能包含 SNMPStats 模块当前未提供的标量和表。
		因此，最好使用 NetSNMP 的 snmptranslate 作为替代。
		以 openserSIPEntityType 标量为例。
		您可以如下调用 snmptranslate：

		
```c

    snmptranslate -TBd openserSIPEntityType
```


		结果将类似于以下内容：

		
```c

    -- FROM       OPENSER-SIP-COMMON-MIB
    -- TEXTUAL CONVENTION OpenSIPSSIPEntityRole
    SYNTAX        BITS {other(0), userAgent(1), proxyServer(2), redirectServer(3), registrarServer(4)}
    MAX-ACCESS    read-only
    STATUS        current
    DESCRIPTION   " This object identifies the list of SIP entities this
                   row is related to. It is defined as a bit map.  Each
                   bit represents a type of SIP entity.
                   If a bit has value 1, the SIP entity represented by
                   this row plays the role of this entity type.

                   If a bit has value 0, the SIP entity represented by
                   this row does not act as this entity type
                   Combinations of bits can be set when the SIP entity
                   plays multiple SIP roles."
```


**问：为什么 snmpget、snmpwalk 和 snmptable 总是超时？**


如果您的 snmp 操作总是返回："Timeout: No Response from localhost"，
		那么很可能您使用了错误的社区字符串进行查询。
		默认安装最可能使用 "public" 作为其默认社区字符串。
		请在 snmpd.conf 文件中搜索字符串 "rocommunity"，
		并将结果作为查询中的社区字符串使用。


**问：如何使用 snmpget？**


NetSNMP 的 snmpget 使用如下：

		
```c

    snmpget -v 2c -c theCommunityString machineToSendTheMachineTo scalarElement.0
```


		例如，考虑在 openserSIPEntityType 标量上执行 snmpget，
		在与 OpenSIPS 实例相同的机器上运行，使用默认的 "public" 社区字符串。
		命令将是：

		
```c

    snmpget -v2c -c public localhost openserSIPEntityType.0
```


		结果将类似于：

		
```c

    OPENSER-SIP-COMMON-MIB::openserSIPEntityType.0 = BITS: F8 \
		other(0) userAgent(1) proxyServer(2)          \
		redirectServer(3) registrarServer(4)
```


**问：如何使用 snmptable？**


NetSNMP 的 snmptable 使用如下：

		
```c

    snmptable -Ci -v 2c -c theCommunityString machineToSendTheMachineTo theTableName
```


		例如，考虑 openserSIPRegUserTable。
		如果在与运行 OpenSIPS 实例相同的机器上运行 snmptable 命令，
		配置了默认的 "public" 社区字符串。
		命令将是：

		
```c

    snmptable -Ci -v 2c -c public localhost openserSIPRegUserTable
```


		结果将类似于：

		
```c

    index openserSIPUserUri openserSIPUserAuthenticationFailures
        1       DefaultUser                                    0
        2            bogdan                                    0
        3    jeffrey.magder                                    0
```


**问：在哪里可以找到更多关于 OpenSIPS 的信息？**


请查看 [https://opensips.org/](https://opensips.org/)。


**问：在哪里可以发布关于此模块的问题？**


首先检查您的问题是否已在我们的邮件列表中回答：

与任何稳定 OpenSIPS 版本相关的电子邮件应发送至
			users@lists.opensips.org，开发版本相关的电子邮件应发送至 devel@lists.opensips.org。

如果您想保持邮件私密，请发送至 users@lists.opensips.org。


**问：如何报告错误？**


请按照以下指南操作：
			[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可证 4.0 版授权
