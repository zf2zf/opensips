---
title: "用于安全多边对等的 OSP 模块"
description: "OSP 模块使 OpenSIPS 能够支持使用 ETSI(TS 101 321 V4.1.1)定义的 OSP 标准进行安全的多边对等。本模块将使您的 OpenSIPS 能够:"
---

## 管理指南


### 概述


OSP 模块使 OpenSIPS 能够支持使用 ETSI(TS 101 321 V4.1.1)定义的 OSP 标准进行安全的多边对等。本模块将使您的 OpenSIPS 能够:


- 向对等服务器发送对等授权请求。
- 验证 SIP INVITE 消息中收到的数字签名对等授权令牌。
- 向对等服务器报告使用信息。


### 依赖


OSP 模块依赖以下模块,必须在此模块之前加载。


- *auth* -- 认证框架模块
- *sqlops* -- SQL 操作模块
- *maxfwd* -- Max-Forward 处理模块
- *mi_fifo* -- 管理接口的 FIFO 支持
- *options* -- OPTIONS 服务器回复模块
- *proto_udp* -- UDP 协议模块 - 实现 SIP 的 UDP-plain 传输
- *registrar* -- SIP Registrar 实现模块
- *rr* -- Record-Route 和 Route 模块
- *signaling* -- SIP 信令模块
- *sipmsgops* -- SIP 操作模块
- *sl* -- 无状态回复模块
- *tm* -- 事务(有状态)模块
- *uac* -- UAC 功能(FROM 修改和 UAC 认证)
- *uac_auth* -- UAC 认证功能
- *usrloc* -- 用户位置实现模块
- *OSP Toolkit* -- OSP Toolkit,可从 https://github.com/TransNexus/osptoolkit 获取,
必须在使用 OSP 模块构建 OpenSIPS 之前构建。
有关使用 OSP Toolkit 构建 OpenSIPS 的说明,请参阅 http://www.http://transnexus.com/wp-content/uploads/OSP-Routing-and-CDR-Collection-Server-with-OpenSIPS-1.7.2.pdf。
对于 OpenSIPS 2.4.0,应使用 OSP Toolkit 4.16.0 或更高版本。


### 导出的参数


#### work_mode


work_mode(integer) 参数指示 OSP 模块应工作在什么模式。
如果设置为 0,OSP 模块工作在直接模式。如果设置为 1,OSP 模块工作在间接模式。默认值为 0。


```c title="指示模块工作在直接模式"
modparam("osp","work_mode",0)
        
```


#### service_type


service_type(integer) 参数指示 OSP 模块应提供什么服务。
如果设置为 0,OSP 模块提供正常的语音服务。
如果设置为 1,OSP 模块提供号码携带查询服务。
如果设置为 2,OSP 模块提供 CNAM 查询服务。默认值为 0。


```c title="指示模块提供正常的语音服务"
modparam("osp","service_type",0)
        
```


#### sp1_uri, sp2_uri, ..., sp16_uri


这些 sp_uri(string) 参数定义用于请求对等授权和路由信息的对等服务器。
必须至少配置一个对等服务器。仅当有多个对等服务器时才需要其他。
每个对等服务器地址采用标准 URL 的形式,由最多四个组件组成:


- 可选的协议指示,用于与对等服务器通信。支持 HTTP 和使用 SSL/TLS 保护的 HTTP,
分别由 "http://" 和 "https://" 表示。
如果未明确指示协议,OpenSIPS 默认为 HTTP,使用 SSL 保护。
- 对等服务器的互联网域名。也可以使用 IP 地址,
但必须用方括号括起来,如 [172.16.1.1]。
- 可选的 TCP 端口号,用于与对等服务器通信。
如果省略端口号,OpenSIPS 默认为端口 5045(对于 HTTP)或端口 1443(对于使用 SSL 保护的 HTTP)。
对等服务器请求的统一资源标识符。此组件不是可选的,必须包含。


```c title="设置 OSP 服务器"
modparam("osp","sp1_uri","http://osptestserver.transnexus.com:5045/osp")
modparam("osp","sp2_uri","https://[1.2.3.4]:1443/osp")
        
```


#### sp1_weight, sp2_weight, ..., sp16_weight


这些 sp_weight(integer) 参数用于对等服务器之间的负载均衡对等请求。
这些参数在配置为 1000 的因数时最有效。
例如,如果 sp1_uri 应管理 sp2_uri 两倍的流量负载,
则将 sp1_weight 设置为 2000,sp2_weight 设置为 1000。
建议在对等服务器之间进行共享负载均衡。
但是,可以将对等服务器配置为主服务器和备份服务器,
方法是将主服务器的 sp_weight 设置为 0,将备份服务器的 sp_weight 设置为非零。
sp1_weight 和 sp2_weight 的默认值均为 1000。


```c title="设置 OSP 服务器权重"
modparam("osp","sp1_weight",1000)
        
```


#### device_ip


device_ip(string) 是一个推荐参数,明确定义对等请求消息中 OpenSIPS 的 IP 地址(作为 SourceAlternate type=transport)。
点分十进制 IP 地址必须用括号括起来,如示例所示。


```c title="设置设备 IP 地址"
modparam("osp","device_ip","[127.0.0.1]:5060")
        
```


#### use_security_features


use_security_features(integer) 参数指示 OSP 模块如何使用 OSP 安全功能。
如果设置为 1,OSP 模块使用 OSP 安全功能。
如果设置为 0,OSP 模块将不使用 OSP 安全功能。默认值为 0。


```c title="指示模块不使用 OSP 安全功能"
modparam("osp","use_security_features",0)
        
```


#### token_format


当 OpenSIPS 收到带有对等令牌的 SIP INVITE 时,
OSP 模块将验证令牌以确定呼叫是否已通过对等服务器授权。
对等令牌可能已签名或未签名。
token_format(integer) 参数定义 OpenSIPS 是验证签名令牌、未签名令牌还是两者都验证。
令牌格式值定义如下。默认值为 2。


如果 use_security_features 参数设置为 0,则无法验证签名令牌。


0 - 仅验证签名令牌。带有有效签名令牌的呼叫被允许。


1 - 仅验证未签名令牌。带有有效未签名令牌的呼叫被允许。


2 - 允许验证签名和未签名令牌。带有有效令牌的呼叫被允许。


```c title="设置令牌格式"
modparam("osp","token_format",2)
        
```


#### private_key, local_certificate, ca_certificates


这些参数标识用于验证对等授权令牌以及使用 SSL 在 OpenSIPS 和对等服务器之间建立安全通道的文件。
这些文件是使用 OSP Toolkit 的 'Enroll' 实用程序生成的。
默认情况下,代理将在默认配置目录中查找 pkey.pem、localcert.pem 和 cacart_0.pem。
默认配置目录在编译时使用 CFG_DIR 设置,默认为 /usr/local/etc/opensips/。
文件可以复制到预期的文件位置,或更改以下参数。


如果 use_security_features 参数设置为 0,这些参数将被忽略。


如果编译时使用了默认 CFG_DIR 值,则文件将从以下位置加载:


```c title="设置授权文件"
modparam("osp","private_key","/usr/local/etc/opensips/pkey.pem")
modparam("osp","local_certificate","/usr/local/etc/opensips/localcert.pem")
modparam("osp","ca_certificates","/usr/local/etc/opensips/cacert.pem")
        
```


#### enable_crypto_hardware_support


enable_crypto_hardware_support(integer) 参数用于在 openssl 库中设置加密硬件加速引擎。
默认值为 0(没有加密硬件)。
如果使用加密硬件,应将该值设置为 1。


```c title="设置硬件支持"
modparam("osp","enable_crypto_hardware_support",0)
        
```


#### ssl_lifetime


ssl_lifetime(integer) 参数定义单个 SSL 会话密钥的生存期(秒)。
一旦超过此时间限制,OSP 模块将协商新的会话密钥。
正在进行中的通信交换不会在此时间限制到期时中断。这是一个可选字段,默认值为 200 秒。


```c title="设置 ssl 生存期"
modparam("osp","ssl_lifetime",200)
        
```


#### persistence


persistence(integer) 参数定义在通信交换完成后 HTTP 连接应保持的时间(秒)。
OSP 模块将为此时间段保持连接,以便将来与同一对等服务器的通信交换。


```c title="设置 persistence"
modparam("osp","persistence",1000)
        
```


#### retry_delay


retry_delay(integer) 参数定义重试连接到 OSP 对等服务器的时间间隔(秒)。
在耗尽所有对等服务器后,OSP 模块将在恢复连接尝试之前延迟此时间量。这是一个可选字段,默认值为 1 秒。


```c title="设置重试延迟"
modparam("osp","retry_delay",1)
        
```


#### retry_limit


retry_limit(integer) 参数定义连接到对等服务器的最大重试次数。
如果经过多次重试后仍无法与所有对等服务器建立连接,OSP 模块将停止连接尝试并返回适当的错误代码。
此数字不计初始连接尝试,因此 retry_limit 为 1 将导致对每个对等服务器进行总共两次连接尝试。默认值为 2。


```c title="设置重试限制"
modparam("osp","retry_limit",2)
        
```


#### timeout


timeout(integer) 参数定义等待对等服务器响应的最长时间(毫秒)。
如果在此时间内未收到响应,当前连接将中止,OSP 模块尝试联系下一个对等服务器。默认值为 10 秒。


```c title="设置超时"
modparam("osp","timeout",10)
        
```


#### support_nonsip_protocol


support_nonsip_protocol(integer) 参数用于告诉 OSP 模块是否支持非 SIP 信令协议目标设备。默认值为 0。


```c title="设置支持非 SIP 目标设备"
modparam("osp","support_nonsip_protocol",0)
        
```


#### max_destinations


max_destinations(integer) 参数定义 OpenSIPS 请求对等服务器在对等响应中返回的最大目标数量。
OSP 模块最多支持 12 个目标。默认值为 12。


```c title="设置目标数量"
modparam("osp","max_destinations",12)
        
```


#### report_networkid


report_networkid(integer) 参数用于告诉 OSP 模块是否在已结束呼叫 CDR 中报告网络 ID。
如果设置为 0,OSP 模块不报告任何网络 ID。
如果设置为 1,OSP 模块报告源网络 ID。
如果设置为 2,OSP 模块报告目标网络 ID。
如果设置为 3,OSP 模块报告源和目标网络 ID。默认值为 3。


```c title="设置报告网络 ID 标志"
modparam("osp","report_networkid",3)
        
```


#### validate_call_id


validate_call_id(integer) 参数指示 OSP 模块验证对等令牌中的呼叫 ID。
如果设置为 1,OSP 模块验证 SIP INVITE 消息中的呼叫 ID 与对等令牌中的呼叫 ID 是否匹配。
如果不匹配,INVITE 将被拒绝。
如果设置为 0,OSP 模块将不验证对等令牌中的呼叫 ID。默认值为 1。


```c title="指示模块验证呼叫 ID"
modparam("osp","validate_call_id",1)
        
```


#### use_number_portability


use_number_portability(integer) 参数指示 OSP 模块如何使用 SIP INVITE 消息 Request URI 中的号码携带参数。
如果设置为 1,OSP 模块在存在这些参数时使用 Request URI 中的号码携带参数。
如果设置为 0,OSP 模块将不使用号码携带参数。默认值为 1。


```c title="指示模块在 Request URI 中使用号码携带参数"
modparam("osp","use_number_portablity",1)
        
```


#### append_userphone


append_userphone(integer) 参数指示 OSP 模块是否在 URI 中附加 "user=phone" 参数。
如果设置为 0,OSP 模块不附加 "user=phone" 参数。
如果设置为 1,OSP 模块将附加 "user=phone" 参数。默认值为 0


```c title="附加 user=phone 参数"
modparam("osp","append_userphone",0)
        
```


#### networkid_location


networkid_location(integer) 参数指示 OSP 模块应在何处附加目标网络 ID。默认值为 2


0 - 不附加网络 ID。


1 - 作为 userinfo 参数附加网络 ID。


2 - 作为 URI 参数附加网络 ID。


```c title="附加 networkid 位置"
modparam("osp","networkid_location",2)
        
```


#### networkid_parameter


networkid_parameter(string) 参数指示 OSP 模块在出站目标 URI 中使用哪个参数名附加目标网络 ID。默认值为 "networkid"


```c title="Networkid 参数名"
modparam("osp","networkid_param","networkid")
        
```


#### switchid_location


switchid_location(integer) 参数指示 OSP 模块应在何处附加目标交换机 ID。默认值为 2


0 - 不附加交换机 ID。


1 - 作为 userinfo 参数附加交换机 ID。


2 - 作为 URI 参数附加交换机 ID。


```c title="附加 switchid 位置"
modparam("osp","switchid_location",2)
        
```


#### switchid_parameter


switchid_parameter(string) 参数指示 OSP 模块在出站目标 URI 中使用哪个参数名附加目标交换机 ID。默认值为 "switchid"


```c title="Networkid 参数名"
modparam("osp","switchid_param","switchid")
        
```


#### parameterstring_location


parameterstring_location(integer) 参数指示 OSP 模块应在何处附加参数字符串。默认值为 0


0 - 不附加参数字符串。


1 - 作为 userinfo 参数附加参数字符串。


2 - 作为 URI 参数附加参数字符串。


```c title="附加参数字符串位置"
modparam("osp","parameterstring_location",0)
        
```


#### parameterstring_value


parameterstring_value(string) 参数指示 OSP 模块在出站 URI 中附加的参数字符串。默认值为 ""


```c title="参数字符串值"
modparam("osp","parameterstring_value","")
        
```


#### source_device_avp


source_device_avp(string) 参数指示 OSP 模块使用定义的 AVP 传递源设备 IP 值(在间接工作模式下)。默认值为 "$avp(_osp_source_device_)"。
然后可以使用 "$avp(_osp_source_device_) = 伪变量" 设置源设备 IP。
所有伪变量均在 https://opensips.org/Resources/DocsCoreVar 中描述。


```c title="设置源设备 IP AVP"
modparam("osp","source_device_avp","$avp(srcdev)")
        
```


#### source_networkid_avp


source_networkid_avp(string) 参数指示 OSP 模块使用定义的 AVP 传递源网络 ID 值。默认值为 "$avp(_osp_source_networkid_)"。
然后可以使用 "$avp(_osp_source_networkid_) = 伪变量" 设置源网络 ID。
所有伪变量均在 https://opensips.org/Resources/DocsCoreVar 中描述。


```c title="设置源网络 ID AVP"
modparam("osp","source_networkid_avp","$avp(snid)")
        
```


#### source_switchid_avp


source_switchid_avp(string) 参数指示 OSP 模块使用定义的 AVP 传递源交换机 ID 值。默认值为 "$avp(_osp_source_switchid_)"。
然后可以使用 "$avp(_osp_source_switchid_) = 伪变量" 设置源交换机 ID。
所有伪变量均在 https://opensips.org/Resources/DocsCoreVar 中描述。


```c title="设置源交换机 ID AVP"
modparam("osp","source_switchid_avp","$avp(swid)")
        
```


#### custom_info_avp


custom_info_avp(string) 参数指示 OSP 模块使用定义的 AVP 传递自定义信息值。默认值为 "$avp(_osp_custom_info_)"。
然后可以使用 "$avp(_osp_custom_info_) = 伪变量" 设置自定义信息。
所有伪变量均在 https://opensips.org/Resources/DocsCoreVar 中描述。


```c title="设置自定义信息 AVP"
modparam("osp","custom_info_avp","$avp(cinfo)")
        
```


#### cnam_avp


cnam_avp(string) 参数指示 OSP 模块使用定义的 AVP 传递 CNAM 值。默认值为 "$avp(_osp_cnam_)"。
然后可以使用 "$avp(_osp_cnam_)" 使用 CNAM。
所有伪变量均在 https://opensips.org/Resources/DocsCoreVar 中描述。


```c title="设置 CNAM AVP"
modparam("osp","cnam_avp","$avp(cnam)")
        
```


#### extraheaders_value


extraheaders_value(string) 参数指示 OSP 模块在出站 SIP NOTIFY 消息中附加定义的 SIP 头。默认值为空。


```c title="设置 NOTIFY 额外头"
modparam("osp", "extraheaders_value", "Source: N")
        
```


#### source_media_avp, destination_media_avp


这些参数用于告诉 OSP 模块哪些 AVP 用于存储媒体地址。默认值分别为 "$avp(_osp_source_media_address_)" 和 "$avp(_osp_destination_media_address_)"。
所有伪变量均在 https://opensips.org/Resources/DocsCoreVar 中描述。


```c title="设置媒体地址 AVP"
modparam("osp", "source_media_avp", "$avp(srcmedia)")
modparam("osp", "destination_media_avp", "$avp(destmedia)")
        
```


#### request_date_avp


request_date_avp(string) 参数指示 OSP 模块使用定义的 AVP 传递 SIP 请求 Date 头值。默认值为 "$avp(_osp_request_date_)"。
然后可以使用 "$avp(_osp_request_date_)" 使用请求日期。
所有伪变量均在 https://opensips.org/Resources/DocsCoreVar 中描述。


```c title="设置请求日期 AVP"
modparam("osp","request_date_avp","$avp(reqdate)")
        
```


#### sdp_fingerprint_avp


sdp_fingerprint_avp(string) 参数指示 OSP 模块使用定义的 AVP 传递 SDP 指纹属性值。默认值为 "$avp(_osp_sdp_fingerprint_)"。
然后可以使用 "$avp(_osp_sdp_fingerprint_)" 使用 SDP 指纹属性。
所有伪变量均在 https://opensips.org/Resources/DocsCoreVar 中描述。


```c title="设置 SDP 指纹 AVP"
modparam("osp","sdp_fingerprint_avp","$avp(sdpfp)")
        
```


#### identity_signature_avp, identity_algorithm_avp, identity_information_avp, identity_type_avp, identity_canon_avp


这些参数指示 OSP 模块使用定义的 AVP 传递 Identity 相关值。
默认值分别为 "$avp(_osp_identity_signature_)"、"$avp(_osp_identity_algorithm_)"、
"$avp(_osp_identity_information_)"、"$avp(_osp_identity_type_)"、"$avp(_osp_identity_canon_)"。
然后可以通过这些 AVP 使用身份相关值。
所有伪变量均在 https://opensips.org/Resources/DocsCoreVar 中描述。


```c title="设置 Identity 相关 AVP"
modparam("osp","identity_signature_avp","$avp(idsign)")
modparam("osp","identity_algorithm_avp","$avp(idalg)")
modparam("osp","identity_information_avp","$avp(idinfo)")
modparam("osp","identity_type_avp","$avp(idtype)")
modparam("osp","identity_canon_avp","$avp(idcanon)")
        
```


#### service_provider_avp


此参数用于告诉 OSP 模块哪个 AVP 用于存储源服务提供商信息。默认值为 "$avp(_osp_service_provider_)"。
所有伪变量均在 https://opensips.org/Resources/DocsCoreVar 中描述。


```c title="设置源服务提供商 AVP"
modparam("osp", "service_provider_avp", "$avp(sp)")
        
```


#### user_group_avp


此参数用于告诉 OSP 模块哪个 AVP 用于存储源用户组信息。默认值为 "$avp(_osp_user_group_)"。
所有伪变量均在 https://opensips.org/Resources/DocsCoreVar 中描述。


```c title="设置源用户组 AVP"
modparam("osp", "user_group_avp", "$avp(groupid)")
        
```


#### user_id_avp


此参数用于告诉 OSP 模块哪个 AVP 用于存储源用户 ID 信息。默认值为 "$avp(_osp_user_id_)"。
所有伪变量均在 https://opensips.org/Resources/DocsCoreVar 中描述。


```c title="设置源用户 ID AVP"
modparam("osp", "user_id_avp", "$avp(userid)")
        
```


### 导出的函数


#### checkospheader()


此函数检查 OSP-Auth-Token 头字段是否存在。


此函数可用于 REQUEST_ROUTE。


```c title="checkospheader 用法"
...
if (checkospheader()) {
  log(1,"找到 OSP 头字段。\n");
} else {
  log(1,"不存在 OSP 头字段\n");
};
...
        
```


#### validateospheader()


此函数验证 SIP 消息的 OSP-Auth-Token 头字段中指定的 OSP-Token。
如果存在对等令牌,将在本地验证。
如果未找到 OSP 头或头令牌无效或过期,返回 -1;
验证成功返回 1。


此函数可用于 REQUEST_ROUTE。


```c title="validateospheader 用法"
...
if (validateospheader()) {
  log(1,"找到有效 OSP 头\n");
} else {
  log(1,"未找到 OSP 头、无效或过期\n");
};
...
        
```


#### getlocaladdress()


此函数获取 SIP 响应的接收 IP 地址并将其存储为代理出口地址。


此函数可用于 ONREPLY_ROUTE。


```c title="getlocaladress 用法"
...
if (getlocaladdress()) {
  log(1,"获取代理本地出口地址\n");
} else {
  log(1,"获取代理本地出口地址失败\n");
};
...
        
```


#### setrequestdate()


此函数获取 SIP 响应的接收 IP 地址并将其存储为代理出口地址。


此函数可用于 REQUEST_ROUTE。


```c title="setrequestdate 用法"
...
if (setrequest()) {
  log(1,"设置请求日期\n");
} else {
  log(1,"设置请求日期失败\n");
};
...
        
```


#### requestosprouting()


此函数向对等服务器发起查询,请求提供服务于被叫方的目标对等方的 IP 地址。
如果目标对等方可用,对等服务器将返回每个目标对等的 IP 地址和对等授权令牌。
OSP-Auth-Token 头字段被插入到 SIP 消息中,
SIP uri 被重写为对等服务器提供的结果。


被叫方的地址必须是有效的 E164 号码,否则此函数返回 -1。
如果事务被对等服务器接受,uri 被重写并返回 1;
出错时(对等服务器不可用、认证失败、没有到目的地的路由或路由被阻止)返回 -1。


此函数可用于 REQUEST_ROUTE。


```c title="requestosprouting 用法"
...
if (requestosprouting()) {
  log(1,"成功查询 OSP 服务器,现在转发呼叫\n");
} else {
  log(1,"OSP 服务器拒绝授权请求\n");
};
...
        
```


#### checkosproute()


此函数用于检查呼叫是否有任何路由。


此函数可用于 REQUEST_ROUTE。


```c title="checkosproute 用法"
...
if (checkosproute()) {
  log(1,"呼叫至少有一条路由\n");
} else {
  log(1,"呼叫没有任何路由\n");
};
...
        
```


#### prepareosproute()


此函数尝试使用对等服务器返回的列表中的目标准备转发 INVITE。
如果呼叫号码被翻译,将设置 RPID AVP 的 RPID 值。
如果无法准备路由,函数返回 'FALSE',脚本可以决定如何处理失败。
注意,如果 checkosproute 已被调用并在 prepareosproute 之前返回 'TRUE',
prepareosproute 不应返回 'FALSE',因为 checkosproute 已确认至少有一条路由。


此函数可用于 BRANCH_ROUTE。


```c title="prepareosproute 用法"
...
if (prepareosproute()) {
  log(1,"成功准备路由,现在转发呼叫\n");
} else {
  log(1,"无法准备路由,没有路由\n");
};
...
        
```


#### prepareospresponse()


此函数尝试将对等服务器返回的列表中的所有路由准备为 SIP 300 Redirect 或 SIP 380 Alternative Service 消息。
然后将消息回复给源。如果准备路由失败,则发送 SIP 500 并记录跟踪消息。


此函数可用于 REQUEST_ROUTE。


```c title="prepareospresponse 用法"
...
if (prepareospresponse()) {
  log(1,"响应已准备。\n");
} else {
  log(1,"无法准备响应。\n");
};
...
        
```


#### prepareallosproutes()


此函数尝试将对等服务器返回的列表中的所有路由准备就绪。
然后将消息分叉到目的地。如果准备路由失败,则发送 SIP 500 并记录跟踪消息。


此函数可用于 REQUEST_ROUTE。


```c title="prepareallosproutes 用法"
...
if (prepareallosproutes()) {
  log(1,"路由已准备,现在分叉呼叫\n");
} else {
  log(1,"无法准备路由。没有目的地可用\n");
};
...
        
```


#### checkcallingtranslation()


此函数用于检查呼叫号码是否被翻译。
在调用 checkcallingtranslation 之前应调用 prepareosproute。
如果呼叫号码已被翻译,应从 INVITE 消息中删除原始 Remote-Party-ID(如果存在)。
并应添加新的 Remote-Party-ID 头(RPID AVP 已由 prepareosproute 设置了 RPID 值)。
如果呼叫号码未被翻译,则不应执行任何操作。


此函数可用于 BRANCH_ROUTE。


```c title="checkcallingtranslation 用法"
...
if (checkcallingtranslation()) {
  # 从收到的消息中删除 Remote_Party-ID
  # 否则它将被转发到下一跳
  remove_hf("Remote-Party-ID");

  # 附加新的 Remote-Party
  append_rpid_hf();
}
...
        
```


#### reportospusage()


此函数应在收到 BYE 消息后调用。
如果消息包含 OSP cookie,函数将向前向和/或终端持续时间使用信息转发给对等服务器。
如果 BYE 包含 OSP cookie,函数返回 TRUE。
实际使用消息将在不同的线程上发送,不会延迟 BYE 处理。
函数应在转发消息之前调用。


参数含义如下:


- 0 - 源设备释放呼叫。
- 1 - 目标设备释放呼叫。


此函数可用于 REQUEST_ROUTE。


```c title="reportospusage 用法"
...
if (is_direction("downstream")) {
  log(1,"此 BYE 消息来自 SOURCE\n");
  if (!reportospusage(0)) {
    log(1,"此 BYE 消息不包含 OSP 使用信息\n");
  }
} else {
  log(1,"此 BYE 消息来自 DESTINATION\n");
  if (!reportospusage(1)) {
    log(1,"此 BYE 消息不包含 OSP 使用信息\n");
  }
}
...
        
```


#### processsubscribe([cachedcnamrecord])


此函数应在收到带有缓存 CNAM 记录的 SUBSCRIBE for CNAM 消息后调用。
此函数生成包含缓存 CNAM 记录的 NOTIFY 消息,
然后将 NOTIFY 消息发送到发送 SUBSCRIBE 消息的设备。


参数含义如下:


- *cachedcnamrecord* (string) - 缓存的 CNAM 记录。


此函数可用于 REQUEST_ROUTE。


```c title="processsubscribe 用法"
...
if (is_method("SUBSCRIBE")) {
    if (($var(sevent) == "calling-name") && (is_myself("$rd"))) {
        if ($var(cnamrecord) != NULL) {
            processsubscribe($(var(cnamrecord){s.b64decode}));
        } else {
            t_relay("1.2.3.4", 0x02);
        }
    } else {
        t_relay();
    }
}
...
        
```


## 开发者指南


OSP 模块的功能不被其他 OpenSIPS 模块使用。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件(即 .md 扩展名)均采用知识共享许可证 4.0 版授权
