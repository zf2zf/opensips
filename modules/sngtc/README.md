---
title: "sngtc 模块"
description: "**Sangoma 转码模块** 提供了使用 [Sangoma 制造的 D 系列转码卡](https://wiki.sangoma.com/display/MTC/Media+Transcoding) 执行语音转码的可能性。该模块利用 Sangoma 转码 API 来管理专用设备上的转码会话。"
---

## 管理指南


### 概述


**Sangoma 转码模块** 提供了使用
[Sangoma D 系列
		转码卡](https://wiki.sangoma.com/display/MTC/Media+Transcoding) 执行语音转码的可能性。
该模块利用 Sangoma 转码 API 来管理
专用设备上的转码会话。
为了检测网络中的卡，Sangoma SOAP 服务器必须启动并运行
（*sngtc_server* 守护进程）。


### 工作原理


该模块对 SIP INVITE、200 OK 和 ACK 消息的 SDP 内容执行多项修改。
在所有转码场景中，UAC 执行早期 SDP 协商，而 UAS 执行后期协商。
这样，OpenSIPS 负责交叉编解码器提供的报价和回答，
以及 Sangoma 卡上转码会话的管理。


这种情况带来了几个**限制**：


- UAC 必须仅执行早期 SDP 协商
- UAS 必须支持后期 SDP 协商（RFC 3261 要求）


由于 *sngtc_node* 库在每个新创建的转码会话时执行多次内存分配，
该模块使用专用进程来管理上述会话。
*sangoma_worker* 进程通过一系列管道与 OpenSIPS UDP 接收器通信。


### 依赖


#### OpenSIPS 模块


必须在此模块之前加载以下模块：


- *dialog*。


#### 外部库或应用程序


运行 OpenSIPS 并加载此模块之前必须安装以下库或应用程序：


- *sngtc_node 库 - [从 Sangoma 下载](https://wiki.freepbx.org/display/MTC/Media+Transcoding+Download)，
					解压，make，make install（编译此模块需要）*。
- *sngtc_server 启动并运行（此模块才能正常工作所需）*。


### 导出的函数


#### sngtc_offer()


该函数剥离 SIP INVITE 中的 SDP 报价，从而向对方端点请求另一个 SDP 报价（后期协商）。
		
可能返回以下**错误代码**：


- *-1* - SDP 解析错误
- *-3* - 内部错误 / 内存不足


该函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE。


```c title="sngtc_offer 用法"
...
	if (is_method("INVITE")) {
		t_newtran();
		create_dialog();
		sngtc_offer();
	}
...
```


#### sngtc_callee_answer([listen_if_A], [listen_if_B])


处理 200 OK 响应中的 SDP 报价，
用转码卡的功能交叉两个报价，
并在新转码会话（仅在必要时）上创建转码会话。
然后重写 200 OK SDP，使其包含编解码器交叉的结果信息。


**参数**说明：


由于 D 系列转码卡通过 PCI 插槽或以太网连接器连接，
它们无法被分配全局 IP。
因此，模块将在发送到每个端点的 SDP 回答中写入卡的本地私有 IP。
由于这不适用于非本地 UA，可选参数强制为每个 UA 监听 RTP 接口。
这样，脚本编写者可以为传入的 RTP（可以转发到转码卡）强制使用全局 IP。


- *listen_if_A* (string) - UAC（主叫方）在通话建立后发送 RTP 的接口（SDP 'c=' 行中的 IP）
- *listen_if_B* (string) - UAS（被叫方）在通话建立后发送 RTP 的接口（SDP 'c=' 行中的 IP）


可能返回以下**错误代码**：


- *-1* - SDP 解析错误
- *-2* - 创建转码会话失败
- *-3* - 内部错误 / 内存不足


该函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE。


```c title="sngtc_callee_answer 用法"
...
onreply_route[1] {
	if ($rs == 200)
		sngtc_callee_answer("11.12.13.14", "11.12.13.14");
}
...
```


#### sngtc_caller_answer()


将 SDP 内容附加到主叫方的 ACK 请求中，以匹配 UAS 执行的后期 SDP 协商。


可能返回以下**错误代码**：


- *-3* - 内部错误 / 内存不足


该函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE。


```c title="sngtc_caller_answer 用法"
...
	if (has_totag()) {
		if (loose_route()) {
			...
			if (is_method("ACK"))
				sngtc_caller_answer();
		}
		...
	}
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可证 4.0 版授权
