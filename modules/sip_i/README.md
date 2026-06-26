---
title: "SIP-I 模块"
description: "该模块提供处理封装在 SIP 中的 ISDN 用户部分(ISUP)消息的功能。可用的操作包括：从 ISUP 消息中读取和修改参数、删除或添加新的可选参数、向 SIP 消息体添加 ISUP 部分。这些操作通过脚本伪变量和函数显式执行。"
---

## 管理指南


### 概述


该模块提供处理封装在 SIP 中的 ISDN 用户部分(ISUP)消息的功能。可用的操作包括：从 ISUP 消息中读取和修改参数、删除或添加新的可选参数、向 SIP 消息体添加 ISUP 部分。这些操作通过脚本伪变量和函数显式执行。


支持的 ISUP 消息类型仅限于根据 ITU-T 定义的 SIP-I(SIP with encapsulated ISUP)协议可以包含在 SIP 消息中的那些类型。


ISUP 消息和参数的格式和规范遵循 ITU-T 建议 Q.763。


### 依赖


#### OpenSIPS 模块


必须在加载此模块之前加载以下模块：


- *无*。


#### 外部库或应用程序


运行 OpenSIPS 并加载此模块之前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### param_subfield_separator (str)


用作 *$isup_param* 和 *$isup_param_str* 伪变量的子名称中 ISUP 参数名和子字段名之间的分隔符的字符。


*默认值为 "|"。*


```c title="设置 param_subfield_separator 参数"
...
modparam("sip_i", "param_subfield_separator", ":")
...
```


#### isup_mime_str (str)


创建新 ISUP 部分时用于 Content-Type 头字段的 ISUP MIME 体字符串。


*默认值为 "application/ISUP;version=itu-t92+"。*


```c title="设置 isup_mime_str 参数"
...
modparam("sip_i", "isup_mime_str", "application/ISUP;base=itu-t92+;version=itu-t")
...
```


#### default_part_headers (str)


与 *Content-Type* 头一起推送到 ISUP 部分的默认头部集（完全定义，包括头部终止）。


*默认值为 "Content-Disposition:signal;handling=optional\r\n"。*


```c title="设置 default_part_headers 参数"
...
modparam("sip_i", "default_part_headers", "Content-Disposition:signal;handling=required\r\n")
...
```


#### country_code (str)


当尝试从 SIP 默认映射 Calling Party Number ISUP 参数时，
P-Asserted-Identity 号码第一部分所针对的国家代码。如果有匹配，
地址性质指示符子字段的赋值为 *3*(国内)，否则为 *4*(国际)。


*默认值为 "+1"。*


```c title="设置 country_code 参数"
...
modparam("sip_i", "country_code", "+4")
...
```


### 导出的函数


#### add_isup_part([isup_msg_type][,extra_headers])


向 SIP 消息体添加新的 ISUP 部分。


除了某些 ISUP 消息类型(IAM、REL、ACM、CPG、ANM、CON)，新添加的部分包含一个空的 ISUP 消息（即所有必需参数置零且没有可选参数），所有必需参数应通过 $isup_param 设置。对于前面提到的消息类型，必需参数和一些可选参数会根据 ITU-T 建议 Q.1912.5 的基本 SIP-ISUP 互通规则自动设置为默认值。这仅提供了从 SIP 头部和消息类型（请求方法、回复代码等）到 ISUP 参数的通用简化映射，
您不应仅基于此来构建您的 SIP-ISUP 互通。


参数含义如下：


- *isup_msg_type (string, 可选)* - 要添加的 ISUP 消息名称，
		完全按照 ITU-T 建议 Q.763 中的显示，或使用缩写（例如：*IAM* 表示 "Initial address"）。
- *extra_headers (string, string, 可选)* - 要插入到 ISUP 部分中的一组完全定义的 SIP 头部
		（包括头部终止符），位于 *Content-Type* 头部旁边。
		它会覆盖全局模块参数 *default_part_headers*。如果未指定，将使用 *default_part_headers* 值。


如果未明确提供 *isup_msg_type*，则会自动从 SIP 消息中推导，如下所示：


- INVITE - IAM
- BYE - REL
- 180, 183 - ACM
- 4xx, 5xx - REL
- 200 OK INVITE - ANM
- 200 OK BYE - RLC


可以作为 *isup_msg_type* 给出的每个 ISUP 消息类型的缩写如下：


- Initial address - *IAM*
- Address complete - *ACM*
- Answer - *ANM*
- Connect - *CON*
- Release - *REL*
- Release complete - *RLC*
- Call progress - *CPG*
- Facility reject - *FRJ*
- Facility accepted - *FAA*
- Facility request - *FAR*
- Confusion - *CFN*
- Suspend - *SUS*
- Resume - *RES*
- Subsequent address - *SAM*
- Forward transfer - *FOT*
- User-to-user information - *USR*
- Network resource management - *NRM*
- Facility - *FAC*
- Identification request - *IRQ*
- Identification response - *IRS*
- Loop prevention - *LPR*
- Application transport - *APT*
- Pre-release information - *PRI*


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、LOCAL_ROUTE。


```c title="add_isup_part 用法"
...
if ($rs == "183") {
	# 封装一个 CPG
	add_isup_part("Call progress");
	# 设置所需的参数
	...
}
...

```


### 导出的伪变量


#### $(isup_param(param_name{sep}subfield_name)[byte_index])


可以通过此读写变量访问收到的或新添加的 ISUP 消息中名为 *param_name* 的 ISUP 参数。
对于可选参数，向此 ISUP 消息中不存在的 *param_name* 写入将插入它。
为此变量分配 null 将从消息中删除可选参数，或者在必需参数的情况下将其置零。


$isup_param 的子名称格式如下：


- *param_name* - ISUP 参数名称，按照 ITU-T 建议 Q.763 中的显示
- *sep* - 分隔符，允许前后有空格
- *subfield_name* - ISUP 参数的子字段名称，按照 ITU-T 建议 Q.763 中的显示


ISUP 参数可以通过不同方式访问：


- 整个参数 - 仅提供 ISUP 参数名作为变量子名称，允许访问整个参数内容为：
	十六进制字符串（类似于十六进制"转储"）用于读写，写入时为字符串别名，或用于读写的整数值；
	当分配十六进制字符串时，必须在前面加上 "0x"；
	当读取时，如果此参数支持字符串别名，则返回关联的整数值，否则返回十六进制字符串
- 子字段级别 - 提供 ISUP 参数名和子字段名作为变量子名称，允许作为整数值或字符串值
	（例如：电话号码参数如 Called Party Number）进行读写访问，或作为写入时的字符串别名
- 字节级别 - 提供 ISUP 参数名和索引作为变量子名称，允许作为整数值访问指定索引的字节


整个参数级别的十六进制字符串访问和字节级别访问支持 ITU-T 建议 Q.763 中定义的所有 ISUP 参数。
子字段级别访问仅支持某些 ISUP 参数，且不支持 ITU 建议中定义的参数的所有子字段。


并非所有参数或参数子字段都有字符串别名可用。同样，并非参数或参数子字段的所有可能值都定义了字符串别名。


有关支持的子字段和别名的更多信息，请查看 [子字段别名](#isup_parameter_subfields_and_string_aliases)。


```c title="isup_param 用法"
...
	$isup_param(Called Party Number | Nature of address indicator) = 3;
	...
	# 使用字符串别名
	$isup_param(Called Party Number | Numbering plan indicator) = "ISDN";
	...
	$isup_param(Called Party Number | Address signal) = "99991234";
	$isup_param(Nature of connection indicators) = "0x01"
	$isup_param(Calling party's category) = 10;
	...
	# 使用字符串别名
	$isup_param(Transmission Medium Requirement) = "speech";
	...
	# 字节级别访问
	$(isup_param(Forward Call Indicators)[0]) = 96;
	$(isup_param(Forward Call Indicators)[1]) = 1;
...

```


#### $isup_param_str(param_name{sep}subfield_name)


收到的或新添加的 ISUP 消息中名为 *param_name* 的 ISUP 参数也可以通过此只读变量访问。
此变量的用法与 *$isup_param* 类似，不同之处在于它在可能时返回值的字符串别名。


$isup_param_str 的子名称格式如下：


- *param_name* - ISUP 参数名称，按照 ITU-T 建议 Q.763 中的显示
- *sep* - 分隔符，允许前后有空格
- *subfield_name* - ISUP 参数的子字段名称，按照 ITU-T 建议 Q.763 中的显示


```c title="isup_param_str 用法"
...
	# 可能输出: "NOA is: national"  
	xlog("NOA is: $isup_param_str(Called Party Number|Nature of address indicator)");
	# 可能输出: "CpN is: 99991234"
	xlog("CpN is: $isup_param_str(Called Party Number|Address signal)");
	# 可能输出: "nature of conn: 0x01"
	xlog("nature of conn: $isup_param_str(Nature of connection indicators)");
	# 可能输出: "Cg cat is: ordinary"
	xlog("$isup_param_str(Calling party's category)");
...

```


#### $isup_msg_type


只读变量，返回 ISUP 消息类型作为字符串。


```c title="isup_msg_type 用法"
...
	# 可能输出: "ISUP msg is: IAM"
	xlog("ISUP msg is: $isup_msg_type");
...

```


### 导出的脚本转换


该模块还提供了一种从包含在任意脚本变量中的 ISUP 消息访问 ISUP 参数及其子字段值的方法，
而不是直接从处理的 SIP（封装 ISUP）消息中访问。
这是通过对包含 ISUP 消息体的脚本变量应用转换来完成的。
原始变量的值不会改变，返回对应的整数或字符串值（表示 ISUP 参数或子字段作为确切值或字符串别名）。


#### {isup.param,param_name,[subfield_name]}


此转换的结果类似于对 *$isup_param* 伪变量的读取访问，
不同之处在于不提供字节级别访问。


转换的参数如下：


- *param_name* - ISUP 参数名称，按照 ITU-T 建议 Q.763 中的显示
- *subfield_name* - 可选，ISUP 参数的子字段名称，按照 ITU-T 建议 Q.763 中的显示


```c title="isup.param 用法"
...
	# 在此示例中，我们从收到的 SIP-I 消息中获取 ISUP 体
	$var(isup_body) = $(rb[1]);

	# 可能输出: "NOA is: 3"  
	xlog("NOA is: $(var(isup_body){isup.param, Called Party Number, Nature of address indicator})\n");

	# 可能输出: "CpN is: 99991234"  
	xlog("CpN is: $(var(isup_body){isup.param, Called Party Number, Address signal})\n");

	# 可能输出: "Cg cat is: 10"
	xlog("Cg cat is: $(var(isup_body){isup.param, Calling party's category})\n");

	# 可能输出: "nature of conn: 0x01"
	xlog("nature of conn: $(var(isup_body){isup.param, Nature of connection indicators})\n");
...

```


#### {isup.param.str,param_name,[subfield_name]}


此转换的结果类似于对 *$isup_param_str* 伪变量的读取访问，
不同之处在于不提供字节级别访问。


转换的参数如下：


- *param_name* - ISUP 参数名称，按照 ITU-T 建议 Q.763 中的显示
- *subfield_name* - 可选，ISUP 参数的子字段名称，按照 ITU-T 建议 Q.763 中的显示


```c title="isup.param.str 用法"
...
	# 在此示例中，我们从收到的 SIP-I 消息中获取 ISUP 体
	$var(isup_body) = $(rb[1]);

	# 可能输出: "NOA is: national"  
	xlog("NOA is: $(var(isup_body){isup.param.str, Called Party Number, Nature of address indicator})\n");

	# 可能输出: "CpN is: 99991234"  
	xlog("CpN is: $(var(isup_body){isup.param.str, Called Party Number, Address signal})\n");

	# 可能输出: "Cg cat is: ordinary"
	xlog("Cg cat is: $(var(isup_body){isup.param.str, Calling party's category})\n");

	# 可能输出: "nature of conn: 0x01"
	xlog("nature of conn: $(var(isup_body){isup.param.str, Nature of connection indicators})\n");
...

```


### ISUP 参数子字段和字符串别名


每个 ISUP 参数支持的子字段及其值的字符串别名如下：


- Nature of Connection Indicators

  - Satellite indicator

  - *no satellite* - 0
  - *one satellite* - 1
  - *two satellite* - 2
  - Continuity check indicator

  - *not required* - 0
  - *required* - 1
  - *performed* - 2
  - Echo control device indicator

  - *not included* - 0
  - *included* - 1
- Forward Call Indicators

  - National/international call indicator

  - *national* - 0
  - *international* - 1
  - End-to-end method indicator

  - *no method* - 0
  - *pass-along* - 1
  - *SCCP* - 2
  - *pass-along and SCCP* - 3
  - Interworking indicator

  - *no interworking* - 0
  - *interworking* - 1
  - End-to-end information indicator

  - *no end-to-end* - 0
  - *end-to-end* - 1
  - ISDN user part indicator

  - *not all the way* - 0
  - *all the way* - 1
  - ISDN user part preference indicator

  - *preferred* - 0
  - *not required* - 1
  - *required* - 2
  - ISDN access indicator

  - *non-ISDN* - 0
  - *ISDN* - 1
  - SCCP method indicator

  - *no indication* - 0
  - *connectionless* - 1
  - *connection* - 2
  - *connectionless and connection* - 3
- Optional forward call indicators

  - Closed user group call indicator

  - *non-CUG* - 0
  - *outgoing allowed* - 2
  - *outgoing not allowed* - 3
  - Simple segmentation indicator

  - *no additional information* - 0
  - *additional information* - 1
  - Connected line identity request indicator

  - *not requested* - 0
  - *requested* - 1
- Called Party Number

  - Odd/even indicator

  - *even* - 0
  - *odd* - 1
  - Nature of address indicator

  - *subscriber* - 1
  - *unknown* - 2
  - *national* - 3
  - *international* - 4
  - *network-specific* - 5
  - *network routing national* - 6
  - *network routing network-specific* - 7
  - *network routing with CDN* - 8
  - Internal Network Number indicator

  - *allowed* - 0
  - *not allowed* - 1
  - Numbering plan indicator

  - *ISDN* - 1
  - *Data* - 3
  - *Telex* - 4
  - Address signal
- Calling Party Number

  - Odd/even indicator

  - *even* - 0
  - *odd* - 1
  - Nature of address indicator

  - *subscriber* - 1
  - *unknown* - 2
  - *national* - 3
  - *international* - 4
  - Number Incomplete indicator

  - *complete* - 0
  - *incomplete* - 1
  - Numbering plan indicator

  - *ISDN* - 1
  - *Data* - 3
  - *Telex* - 4
  - Address presentation restricted indicator

  - *allowed* - 0
  - *restricted* - 1
  - *not available* - 2
  - *reserved* - 3
  - Screening indicator

  - *user* - 0
  - *network* - 1
  - Address signal
- Backward Call Indicators

  - Charge indicator

  - *no indication* - 0
  - *no charge* - 1
  - Called party's status indicator

  - *no indication* - 0
  - *subscriber free* - 1
  - *connect* - 2
  - Called party's category indicator

  - *no indication* - 0
  - *ordinary subscriber* - 1
  - *payphone* - 2
  - End to End method indicator

  - *no end-to-end* - 0
  - *pass-along* - 1
  - *SCCP* - 2
  - *pass-along and SCCP* - 3
  - Interworking indicator

  - *no interworking* - 0
  - *interworking* - 1
  - End to End information indicator

  - *no end-to-end* - 0
  - *end-to-end* - 1
  - ISDN user part indicator

  - *not all the way* - 0
  - *all the way* - 1
  - Holding indicator

  - *not requested* - 0
  - *requested* - 1
  - ISDN access indicator

  - *non-ISDN* - 0
  - *ISDN* - 1
  - Echo control device indicator

  - *not included* - 0
  - *included* - 1
  - SCCP method indicator

  - *no indication* - 0
  - *connectionless* - 1
  - *connection* - 2
  - *connectionless and connection* - 3
- Optional Backward Call Indicators

  - In-band information indicator

  - *no indication*- 0
  - *available* - 1
  - Call diversion may occur indicator

  - *no indication* - 0
  - *call diversion* - 1
  - Simple segmentation indicator

  - *no additional information* - 0
  - *additional information* - 1
  - MLPP user indicator

  - *no indication* - 0
  - *MLPP user* - 1
- Connected Number

  - Odd/even indicator

  - *even* - 0
  - *odd* - 1
  - Nature of address indicator

  - *subscriber* - 1
  - *unknown* - 2
  - *national* - 3
  - *international* - 4
  - Numbering plan indicator

  - *ISDN* - 1
  - *Data* - 3
  - *Telex* - 4
  - Address presentation restricted indicator

  - *allowed* - 0
  - *restricted* - 1
  - *not available* - 2
  - Screening indicator

  - *user* - 0
  - *network* - 1
  - Address signal
- Original Called Number

  - Odd/even indicator

  - *even* - 0
  - *odd* - 1
  - Nature of address indicator

  - *subscriber* - 1
  - *unknown* - 2
  - *national* - 3
  - *international* - 4
  - Numbering plan indicator

  - *ISDN* - 1
  - *Data* - 3
  - *Telex* - 4
  - Address presentation restricted indicator

  - *allowed* - 0
  - *restricted* - 1
  - *not available* - 2
  - *reserved* - 3
- Redirecting Number - 与 *Original Called Number* 相同
- Redirection Number - 与 *Called Party Number* 相同
- Redirection information

  - Redirecting indicator

  - *no redirection* - 0
  - *call rerouted* - 1
  - *call rerouted, all information restricted* - 2
  - *call diverted* - 3
  - *Call diverted, all information restricted* - 4
  - *call rerouted, redirection number restricted* - 5
  - *call diversion, redirection number restricted* - 6
  - Original redirection reason

  - *unknown/not available* - 0
  - *user busy* - 1
  - *no reply* - 2
  - *unconditional* - 3
  - Redirection counter

  - 1
  - 2
  - 3
  - 4
  - 5
  - Redirecting reason

  - *unknown/not available* - 0
  - *user busy* - 1
  - *no reply* - 2
  - *unconditional* - 3
  - *deflection alerting* - 4
  - *deflection response* - 5
  - *mobile not reachable* - 6
- Cause Indicators

  - Location

  - *user* - 0
  - *LPN* - 1
  - *LN* - 2
  - *TN* - 3
  - *RLN* - 4
  - *RPN* - 5
  - *INTL* - 7
  - *BI* - 10
  - Coding standard

  - *ITU-T* - 0
  - *ISO/IEC* - 1
  - *national* - 2
  - *location* - 3
  - Cause value
- Subsequent Number

  - Odd/even indicator

  - *even* - 0
  - *odd* - 1
  - Address signal
- Event Information

  - Event indicator

  - *alerting* - 1
  - *progress* - 2
  - *in-band or pattern* - 3
  - *busy* - 4
  - *no reply* - 5
  - *unconditional* - 6
  - Event presentation restricted indicator

  - *no indication* - 0
  - *restricted* - 1
- Calling Party's Category

  - *unknown* - 0
  - *french* - 1
  - *english* - 2
  - *german* - 3
  - *russian* - 4
  - *spanish* - 5
  - *ordinary* - 10
  - *priority* - 11
  - *data* - 12
  - *test* - 13
  - *payphone* - 15
- Transmission Medium Requirement

  - *speech* - 0
  - *64 kbit/s unrestricted* - 2
  - *3.1 kHz audio* - 3
  - *64 kbit/s preferred* - 6
  - *2 x 64 kbit/s* - 7
  - *384 kbit/s* - 8
  - *1536 kbit/s* - 9
  - *1920 kbit/s* - 10


### 必需的 ISUP 参数


每个需要此参数的受支持 ISUP 消息的必需参数（根据 ITU-T 建议 Q.763）如下：


- Initial address

  - Nature of connection indicators
  - Forward call indicators
  - Calling party's category
  - Transmission medium requirement
  - Called party number
- Address complete

  - Backward call indicators
- Connect

  - Backward call indicators
- Release

  - Cause indicators
- Call progress

  - Event information
- Facility reject

  - Facility indicator

  - Cause indicators
- Facility accepted

  - Facility indicator
- Facility request

  - Facility indicator
- Confusion

  - Cause indicators
- Suspend

  - Suspend/resume indicators
- Resume

  - Suspend/resume indicators
- Subsequent address

  - Subsequent number
- User-to-user information

  - User-to-user information
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可证 4.0 版授权
