---
title: "SipCapture 模块"
description: "提供将传入/传出的 SIP 消息存储到数据库的功能。"
---

## 管理指南


### 概述


提供将传入/传出的 SIP 消息存储到数据库的功能。


OpenSIPS 可以通过三种模式捕获 SIP 消息：


- IPIP 封装。(ETHHDR+IPHDR+IPHDR+UDPHDR)。
- 监控/镜像端口。
- Homer 封装协议模式 (HEP v1/2/3)。从版本 2.2 开始支持新的 HEPv3，使用 proto _hep 模块。同时还添加了 HEPv3 的头部操作支持。详见 [hep set](#func_hep_set)。如需更多关于 hep 协议的信息，请查看此 [链接](https://github.com/sipcapture/HEP/blob/master/docs/HEP3_rev11.pdf)。


可以使用 MI 命令 "sipcapture:capture" 来开启/关闭捕获功能：


opensips-cli -x mi sipcapture:capture on


opensips-cli -x mi sipcapture:capture off


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *数据库模块* - mysql、postrgress、dbtext、unixodbc 等
- *proto_hep 模块* - 如果使用 hep 捕获


#### 外部库或应用程序


运行 OpenSIPS 并加载此模块之前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### db_url (str)


数据库 URL。


*默认值为 ""。*


```c title="设置 db_url 参数"
...
modparam("sipcapture", "db_url", "mysql://user:passwd@host/dbname")
...
```


#### table_name (str)


存储 SIP 消息的表名。从版本 2.2 开始支持 strftime 格式的后缀，用于创建带时间格式的表名。


*默认值为 "sip_capture"。*


```c title="设置 table_name 参数"
...
modparam("sipcapture", "table_name", "homer_capture")

/* 每天更换表名 */
modparam("sipcapture", "table_name", "homer_%m_%d")
/* 如果今天是 2014-04-13，将扩展为 homer_04_13 */
...
```


#### rtcp_table_name (str)


使用 report_capture 函数捕获的数据包所存储的表名。从版本 2.2 开始支持 strftime 格式的后缀，用于创建带时间格式的表名。


*默认值为 "rtcp_capture"。*


```c title="设置 rtcp_capture 参数"
...
modparam("sipcapture", "rtcp_table_name", "homer_capture")

/* 每小时更换表名 */
modparam("sipcapture", "rtcp_table_name", "homer_%m_%d_%H")
/* 如果今天是 2014-04-13 13:05，将扩展为 homer_04_13_13 */
...
```


#### capture_on (integer)


全局启用/禁用捕获的参数 (on(1)/off(0))


*默认值为 "0"。*


```c title="设置 capture_on 参数"
...
modparam("sipcapture", "capture_on", 1)
...
```


#### hep_capture_on (integer)


启用/禁用 HEP 捕获的参数 (on(1)/off(0))


*默认值为 "0"。*


```c title="设置 hep_capture_on 参数"
...
modparam("sipcapture", "hep_capture_on", 1)
...
```


#### max_async_queries (integer)


设置同时执行的捕获数据包"INSERT"查询的最大数量，仅在 DB 支持异步操作时有效。如果 OpenSIPS 关闭，剩余的查询仍将被执行。查询缓冲区限制为 65535 字符，因此可能同时执行不超过 30-40 个查询，具体取决于插入的 sip 消息大小，因为它是查询中最大的部分。


*默认值为 "5"。*


```c title="设置 max_async_queries 参数"
...
modparam("sipcapture", "max_async_queries", 3)
...
```


#### raw_ipip_capture_on (integer)


启用/禁用 IPIP 捕获的参数 (on(1)/off(0))


*默认值为 "0"。*


```c title="设置 raw_ipip_capture_on 参数"
...
modparam("sipcapture", "raw_ipip_capture_on", 1)
...
```


#### raw_moni_capture_on (integer)


启用/禁用监控/镜像端口捕获的参数 (on(1)/off(0))
同时只能启用一种原始套接字模式！监控端口捕获目前仅在 Linux 上支持。


*默认值为 "0"。*


```c title="设置 raw_moni_capture_on 参数"
...
modparam("sipcapture", "raw_moni_capture_on", 1)
...


```


#### raw_socket_listen (string)


RAW 套接字用于 IPIP 捕获的监听 IP 地址参数。您还可以为 IPIP/镜像模式定义端口/端口范围，以捕获特定端口上的 SIP 消息：
"10.0.0.1:5060" - SIP 消息的源/目标端口必须等于 5060
"10.0.0.1:5060-5090" - SIP 消息的源/目标端口必须等于或介于 5060 和 5090 之间。
如果使用镜像捕获，则必须定义端口/端口范围！此时 IP 地址部分将被忽略，但为了让解析器正常工作，请使用如 10.0.0.0。


*默认值为 ""。*


```c title="设置 raw_socket_listen 参数"
...
modparam("sipcapture", "raw_socket_listen", "10.0.0.1:5060-5090")
...
modparam("sipcapture", "raw_socket_listen", "10.0.0.1:5060")
...
```


#### raw_interface (string)


绑定原始套接字的接口名称。


*默认值为 ""。*


```c title="设置 raw_socket_listen 参数"
...
modparam("sipcapture", "raw_interface", "eth0")
...
```


#### raw_sock_children (integer)


定义必须创建多少个子进程来监听原始套接字。


*默认值为 "1"。*


```c title="设置 raw_socket_listen 参数"
...
modparam("sipcapture", "raw_sock_children", 6)
...
```


#### promiscuous_on (integer)


在原始套接字上启用/禁用混杂模式的参数。
仅限 Linux。


*默认值为 "0"。*


```c title="设置 promiscuous_on 参数"
...
modparam("sipcapture", "promiscuous_on", 1)
...
```


#### raw_moni_bpf_on (integer)


在镜像接口上激活 Linux Socket Filter (基于 BPF 的 LSF)。
该结构在 linux/filter.h 中定义。默认 LSF 接受 raw_socket_listen 参数中的端口/端口范围。目前 LSF 仅在 Linux 上支持。


*默认值为 "0"。*


```c title="设置 raw_moni_bpf_on 参数"
...
modparam("sipcapture", "raw_moni_bpf_on", 1)
...
```


#### capture_node (str)


捕获节点的名称。


*默认值为 "homer01"。*


```c title="设置 capture_node 参数"
...
modparam("sipcapture", "capture_node", "homer03")
...
```


#### hep_route (string)


指定 hep 消息应采用的路径。可能的值如下：


- *none* - 不经过脚本；
					直接执行 sip_capture()；
- *sip(默认)* - 经过主
					请求路由；此时消息会被解析，您可以对其执行任何操作；
- *任何其他字符串值* - 定义一个路由名称，
					hep 消息应通过该路由；由于效率原因，消息不会被解析；您可以修改 hep 块（如果使用 hep 版本 3）并将 hep 消息转发到其他 hep 捕获节点；


*默认值为 sip（经过主请求路由）。*


```c title="设置 hep_route 参数"
...
modparam("sipcapture", "hep_route", "my_hep_route")
...

route[my_hep_route] {
	/* 在此处执行 hep 相关操作 */
	...
}
...
```


### 导出的函数


#### sip_capture([table_name], [custom_field1], [custom_field2], [custom_field3])


将消息保存到数据库。


参数含义如下：


- *table_name (string, 可选)* - 存储数据包的表名；
				可以使用 strftime 格式的后缀以根据时间更改表名；如果未设置，将使用 modparam 定义的表；
*custom_field1 (string, 可选)* - 要存储在 "custom_field1" 列中的自定义数据
*custom_field2 (string, 可选)* - 要存储在 "custom_field2" 列中的自定义数据
*custom_field3 (string, 可选)* - 要存储在 "custom_field3" 列中的自定义数据


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE。


```c title="sip_capture 用法"
...
if (is_method("REGISTER"))
	sip_capture();
	...
	/* 表名每天都会更改 */
	sip_capture("homer_%m_%d");
	sip_capture("homer_%m_%d", , $hdr(P-Asserted-Identity));
...

```


#### report_capture(correlation_id, [table_name], [proto_type])


将消息保存到数据库。如果要设置协议类型，必须定义表名，即使传递 null 也是如此 (report_capture($var(cor_id),,$var(proto_type)))。


参数含义如下：


- *correlation_id (string)*
- *table_name (string, 可选)* - 存储数据包的表名；
				可以使用 strftime 格式的后缀以根据时间更改表名；
- *proto_type (int, 可选)* - hep 协议规范中定义的协议类型编号。


**非常重要：** 从版本 2.3 开始，report_capture 函数的行为将根据 [proto_hep](../proto_hep) 中的 [homer5_on](../proto_hep#idp154080) 参数而改变。
请查看模块中的 [sql](https://github.com/OpenSIPS/opensips/tree/master/modules/sipcapture/sql) 文件夹以检查每个版本的表字段。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE。


```c title="sip_capture 用法"
...
	hep_get("0x0011", "utf8-string", , $var(correlation_id));
	if ($var(correlation_id) == null) {
		xlog("NO CORRELATION ID! SET SOMETHING OR DROP");
		$var(correlation_id) = "absdcef";
	}

	$var(proto_type) = "3"; /* 0x03 - SDP 协议 */

	report_capture($var(correlation_id), "rtcp_log");
	/* 设置第二个参数，即使设置为 null，也是设置 proto type 所必需的 */
	report_capture($var(correlation_id), , $var(proto_type));
	report_capture($var(correlation_id), "rtcp_log", $var(proto_type));
...

```


#### hep_set(chunk_id, chunk_data, [data_type], [vendor_id])


设置一个 hep 块。如果不存在，则添加。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE。


参数含义如下：


- *chunk_id(十六进制/整数或字符串标识符)* - 要添加的块的 ID；
				大多数通用块都在内部 hep 结构中。对于这些块，您可以跳过 data_type 和 vendor_id，因为它们已经已知。不支持内置的通用块如下：0x000d(keep alive timer)、0x000e(authenticate key)、
			0x0011(internal correltion id)、0x0012(vlan ID)。您可以设置这些块，但只能使用 vendor id 0x0000，其他值将导致错误。Timestamp(0x0009)
			和 timestamp_us(0x000A) 块无法设置。对于有内置支持的块，您也可以使用字符串代替块 ID，如下所示：

				0x0001 - proto_family(无法设置；它会在您将源/目标地址类型从 IPv4 更改为 IPv6 时自动更新
				或反之)

				0x0002 - proto_id；由于很难知道协议的整数值，您可以使用以下字符串值更改此值：

				UDP

				TCP

				TLS

				SCTP

				WS

				WSS

				BIN

				HEP

			0x0003 - src_ip

			0x0004 - dst_ip

			0x0005 - src_ip

			0x0006 - dst_ip

			0x0007 - src_port

			0x0008 - dst_port

			0x0009 - timestamp(无法设置)

			0x000A - timestamp_us(无法设置)

			0x000B - proto_type；对于此变量，有预定义的字符串可以设置：

				SIP

				XMPP

				SDP

				RTP

				RTCP

				MGCP

				MEGACO

				M2UA

				M3UA

				IAX

				H322

				H321

			0x000C - captagent_id

			0x000f - payload

			0x0010 - payload
- *chunk_data(string)* - 块应包含的数据；
			内部将转换为请求的数据类型
- *data_type (string, 可选, 默认值: "utf8-string")* - 块中数据的类型。可以是以下值：

  - uint8  - 字节无符号整数
  - uint16 - 字无符号整数
  - uint32 - 4 字节无符号整数
  - inet4-addr - IPv4 地址（人类可读格式）
  - inet6-addr - IPv6 地址（人类可读格式）
  - utf8-string - UTF8 编码的字符序列
  - octet-string - 字节数组
- *vendor id(十六进制或整数的字符串值, 可选, 默认值: "3")* - 已经定义了一些 vendor id；
				更多详情请查看 [hep proto docs](http://hep.sipcapture.org/hepfiles/HEP3_rev11.pdf)。


```c title="hep_set 用法"
...
/* 修改/添加通用块 */
hep_set("proto_type", "H321");

/* 添加自定义块 - int */
hep_set("31", "132", "uint32", "3")

/* 添加自定义块 - IPv4 地址 */
hep_set("32", "192.168.5.14", "inet4-addr", "3")
...

```


#### hep_get(chunk_id, data_type, [chunk_data_pv], [vendor_id_pv])


设置一个 hep 块。如果不存在，则添加。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE。


参数含义如下：


- *chunk_id (string)* - 与 [hep set](#func_hep_set) 中的含义相同
- *data_type (string)* - 与 [hep set](#func_hep_set) 中的含义相同；如果是通用块可以省略
- *chunk_data_pv (可写变量, 可选)* - 将保存块内的数据；
			某些通用块数据以特定格式返回，如下所示：

  - 0x0001 - proto_family(string) - AF_INET/AF_INET6
  - 0x0002  proto_id(string) - 参见 [hep set](#func_hep_set) 的可能值
  - 0x0003/0x0004/0x0005/0x0006  src/dst_ip(string) - 人类可读格式的 IP 地址
  - 0x0009  timestamp(string) - 人类可读格式的日期和时间
  - 0x000B  proto_type(string) - 参见 [hep set](#func_hep_set) 的可能值
- *vendor_id_pv (可写变量, 可选)* - 将保存块的 vendor id(整数值)


```c title="hep_set 用法"
...
/* 获取通用块 */
hep_get("proto_type", , $var(data), $var(vid));

/* 获取自定义块 - 您必须知道其中存储的数据类型 */
hep_set("31", "uint32", $var(data), $var(vid))
...

```


#### hep_del(chunk_id)


删除一个 hep 块。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE。


参数含义如下：


- *chunk_id (string)* - 与 [hep set](#func_hep_set) 中的 *chunk_id* 含义相同。


```c title="hep_set 用法"
...
/* 获取通用块 */
hep_del("25"); /* 删除 ID 为 25 的块 */
...

```


#### hep_relay()


将有状态地将消息转发到当前 URI 指示的目标。
（如果原始 URI 被 UsrLoc、RR、strip/prefix 等重写，
则使用新 URI）。消息必须是 HEP 消息，版本 1、2 或 3。对于版本 1 和 2，只能使用 UDP 转发，
对于版本 3，可以使用 TCP 和 UDP。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE。


```c title="hep_relay 用法"
...
$du="sip:192.168.153.157";
if (!hep_relay()) {
	xlog("Hep 代理失败！\n");
	exit;
}

...

```


#### hep_resume_sip()


中断 hep 路由执行并恢复到主请求路由。


警告：仅从使用 *hep_route* 参数定义的路由中调用此函数。


```c title="hep_resume_sip 用法"
...
modparam("sipcapture", "hep_route", "my_hep_route")

route[my_hep_route] {
	...

	/* 在主请求路由中恢复执行 */
	hep_resume_sip();
}


...

```


### 导出的异步函数


#### sip_capture()


将消息保存到数据库。查询仅在数据库支持异步操作时异步执行。
查询可能不会立即执行，取决于 *max_async_queries* 参数。


```c title="sip_capture 用法"
...
{
	async(sip_capture(), capture_resume);
}

route[capture_resume] {
	xlog("插入执行\n");
	/* 后续逻辑 */
}
...

```


### 导出的伪变量


#### $hep_net


保存有关收到 hep 消息的节点的第 3 层和第 4 层信息（IP 地址和端口）。该变量是只读的，
只能通过其名称引用。


可能的名称值如下：


- *proto_family* - 可以是 AF_INET/AF_INET6
- *proto_id* - 是 PROTO_HEP，因为您收到的是 hep 格式的消息。
- *src_ip* - 发送节点的 IPv4/IPv6 地址，
		取决于 proto_family。
- *dst_ip* - 接收节点的 IPv4/IPv6 地址，
			取决于 proto_family（OpenSIPS hep 接口 IP，消息在该接口上接收）。
- *src_port* - 发送节点端口。
- *dst_port* - 接收端口（OpenSIPS hep 接口
			端口，消息在该端口上接收）。


```c title="hep_net 用法"
...
	/* 在接口 192.168.2.5 上收到此 hep 数据包 */
	if ($hep_net(dst_ip) == "192.168.2.5") {
		/* 在 192.168.2.5:6060 接口上收到 */
		if ($hep_net(dst_port) == 6060) {
			...
		/* 在 192.168.2.5:6061 接口上收到 */
		} else if ($hep_net(dst_port) == 6061) {
			...
		}
	}
...

```


#### HEPVERSION (string, int)


保存接口上收到的 hep 数据包的版本。


```c title="HEPVERSION 用法"
...
	if ($HEPVERSION == 3) {
		/* 这是一个 HEPv3 数据包 */
		...
	} else if ($HEPVERSION == 2) {
		/* 这是一个 HEPv2 数据包 */
		...
	} else if ($HEPVERSION == 1) {
		/* 这是一个 HEPv1 数据包 */
		...
	}
...

```


### 导出的 MI 函数


#### sipcapture:capture


替换已弃用的 MI 命令：*sip_capture*。


名称：*sipcapture:capture*


参数：


- *capture_mode (可选)* - 
			开启/关闭 SIP 消息捕获。可能的值是：

  - on
  - off
如果参数缺失，命令将返回 SIP 消息捕获的状态（作为字符串 "on" 或 "off"）而不进行任何更改。


MI FIFO 命令格式：


```c
		opensips-cli -x mi sipcapture:capture off

```


### 数据库设置


在运行带有 sipcapture 的 OpenSIPS 之前，您必须设置模块将存储数据的数据库表。
如果表不是由安装脚本创建的，或者您选择自己安装所有内容，
可以使用 sipcapture-create.sql 和
reportcapture-create.sql 或
sipcapture-st-create.sql SQL 脚本（位于 opensips/scripts 文件夹中的数据库目录中）作为模板。
您还可以在项目网页上找到完整的数据库文档，
[https://opensips.org/docs/db/db-schema-devel.html](https://opensips.org/docs/db/db-schema-devel.html)。


### 限制


1. 仅支持一种原始套接字捕获模式：IPIP 或监控/镜像端口。
			不要同时激活两者。
		2. 默认情况下，MySQL 不支持分区表的 INSERT DELAYED。您可以修补 MySQL
			(http://bugs.mysql.com/bug.php?id=50393) 或使用单独的表（伪分区）
		3. 镜像端口捕获仅在 Linux 上工作。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可证 4.0 版授权
