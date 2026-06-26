---
title: "topology_hiding 模块"
description: "这是一个提供拓扑隐藏功能的模块。该模块可以在 dialog 模块之上工作，也可以作为独立模块工作（因此允许对所有类型的请求进行拓扑隐藏）"
---

## 管理指南


### 概述


这是一个提供拓扑隐藏功能的模块。
		该模块可以在 dialog 模块之上工作，也可以作为独立模块工作
		（因此允许对所有类型的请求进行拓扑隐藏）


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *TM - 事务模块*。
- *Dialog 模块*，如果启用了 "force_dialog"
				模块参数，或从配置脚本创建了 dialog。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- *无*


### 导出的参数


#### th_callid_passwd (string)


在使用 callid mangling 进行 topology_hiding 时，
		用于对 callid 进行编码/解码的字符串密码。


*默认值为 ""OpenSIPS""*


```c title="设置 th_callid_passwd 参数"
...
modparam("topology_hiding", "th_callid_passwd", "my_topo_hiding_secret")
...
```


#### th_callid_prefix (string)


用于检测已被 dialog 拓扑隐藏编码的 callid 的前缀。
		如果您的 SIP 路径包含多个具有拓扑隐藏的 OpenSIPS  boxes，请确保更改此值。


*默认值为 ""DLGCH_""*


```c title="设置 th_callid_prefix 参数"
...
modparam("topology_hiding", "th_callid_prefix", "MYCALLIDPREFIX_")
...
```


#### th_passed_contact_uri_params (string)


分号分隔的 Contact URI 参数列表，
		这些参数将在拓扑隐藏呼叫中从一侧传递到另一侧。
		当端到端功能使用此类 Contact URI 参数时使用。


*默认值为 "empty" - 不传递任何参数*


```c title="设置 th_passed_contact_uri_params 参数"
...
modparam("topology_hiding", "th_passed_contact_uri_params", "paramname1;myparam;custom_param")
...
```


#### th_passed_contact_params (string)


分号分隔的 Contact 头参数列表，
		这些参数将在拓扑隐藏呼叫中从一侧传递到另一侧。
		当端到端功能使用此类 Contact 头参数时使用。


*默认值为 "empty" - 不传递任何参数*


```c title="设置 th_passed_contact_params 参数"
...
modparam("topology_hiding", "th_passed_contact_params", "paramname1;myparam;custom_param")
...
```


#### force_dialog (int)


如果设置为 1，模块将内部创建 dialog（如果尚未创建）。
		这仅适用于基于 INVITE 的 dialog，并且必须加载 dialog 模块。


*默认值为 "0"*


```c title="设置 force_dialog 参数"
...
modparam("topology_hiding", "force_dialog", 1)
...
```


#### th_contact_encode_passwd (string)


当不依赖 dialog 模块时（由于脚本编写者偏好，
		或者只是为非 INVITE dialog 进行拓扑隐藏），
		模块会将所需信息存储在 Contact URI 参数中。
		此参数配置用于对该特定参数进行编码/解码的字符串密码。


*默认值为 ""ToPoCtPaSS""*


```c title="设置 th_contact_encode_passwd 参数"
...
modparam("topology_hiding", "th_contact_encode_passwd", "my_topoh_passwd")
...
```


#### th_contact_encode_param (string)


当不依赖 dialog 模块时（由于脚本编写者偏好，
		或者只是为非 INVITE dialog 进行拓扑隐藏），
		模块会将所需信息存储在 Contact URI 参数中。
		此参数配置相应参数的名称。


*默认值为 ""thinfo""*


```c title="设置 th_contact_encode_param 参数"
...
modparam("topology_hiding", "th_contact_encode_param", "customparam")
...
```


#### th_contact_encode_scheme (string)


当不依赖 dialog 模块时（由于脚本编写者偏好，
		或者只是为非 INVITE dialog 进行拓扑隐藏），
		模块会将所需信息存储在 Contact URI 参数中。
		此参数配置用于存储在 Contact URI 参数中的数据的编码方案。
		可能的值有：


- *base64*
- *base32*


*默认值为 ""base64""*


```c title="设置 th_contact_encode_scheme 参数"
...
modparam("topology_hiding", "th_contact_encode_scheme", "base32")
...
```


#### th_contact_caller_username_var (string)


用于存储向呼叫者公布的 contact 用户名的值的变量。


*默认值为 "_th_contact_caller_username_var_"*


```c title="设置 th_contact_caller_username_var 参数"
...
modparam("topology_hiding", "th_contact_caller_username_var", "__topo_hiding_username_var__")
...
```


#### th_contact_callee_username_var (string)


用于存储向被叫方公布的 contact 用户名的值的变量。


*默认值为 "_th_contact_callee_username_var_"*


```c title="设置 th_contact_callee_username_var 参数"
...
modparam("topology_hiding", "th_contact_callee_username_var", "__topo_hiding_username_var__")
...
```


#### th_callid_loop_protection (int)


在编码拓扑隐藏 Call-ID 时包含 *from_tag*，
			以确保在循环场景中正确解码
			（当具有先前编码的 Call-ID 的相同呼叫被循环回来时）。


请注意，启用此参数会增加生成的 Call-ID 值，
			因为附加的 from_tag 信息被嵌入其中。


*默认值为 "0" / 禁用。*


```c title="设置 th_callid_loop_protection 参数"
...
modparam("topology_hiding", "th_callid_loop_protection", 1)
...
```


### 导出的函数


#### topology_hiding()


通过对初始请求调用此函数，模块将隐藏拓扑，
			这意味着它将剥离并恢复所有 Via、Record-Route 和 Route 头，
			并用接收请求的接口 IP 地址替换 contact。


但是您必须注意，对应用拓扑隐藏的这些 dialog 的未来
			-dialog 内请求（BYE、reInvite 等）的检测不是自动完成的。
			在没有拓扑隐藏且只有正常 dialog 的情况下，
			检测是在调用 loose_route 时完成的。
			但是现在，对于应用了拓扑隐藏的 dialog，
			到达 OpenSIPS 的 dialog 内请求不会有任何 Route 头，
			且 RURI 将指向 OpenSIPS 机器。
			因此，为了能够将 dialog 内请求匹配到相应的 dialog，
			必须调用一个脚本函数。
			它的名称是 *topology_hiding_match*，您可以在上面阅读它的描述。
			dialog 内拓扑请求是带有 to tag、
			RURI 指向 opensips 且方法特定于 Invite dialog 的请求。
			对于这类请求，您应该调用 topology_hiding_match() 函数。
			如果请求成功匹配并根据拓扑隐藏逻辑修复，函数返回成功。


可选地，该函数还接收一个字符串参数，其中包含字符串标志。
			字符串标志的当前选项有：


- *U* - 在 Contact 头 URI 中传播用户名
- *D* - Dialog ID (DID) 被推入 Contact 用户名，而不是 URI 参数。
			此选项仅在使用带 dialog 支持的拓扑隐藏时才有意义。
- *a* - 在整个 dialog 期间保留向呼叫者公布的 Contact 头。
- *A* - 在整个 dialog 期间保留向被叫方公布的 Contact 头。
- *D* - Dialog ID (DID) 被推入 Contact 用户名，而不是 URI 参数。
			此选项仅在使用带 dialog 支持的拓扑隐藏时才有意义。
- *C* - 对 callid 头进行编码
在很多情况下，将 callid 传播到被叫方并不是一个好主意，
			因为有时 callid 包含实际呼叫方侧的 IP，
			从而暴露部分网络拓扑。
当使用 "C" 标志时，callid 将被自动编码/解码，
			对脚本编写者透明 - 在 OpenSIPS 内部（脚本、MI 函数等），
			所有与 callid 相关的变量都将表示呼叫方侧的 callid 值。
			如果需要被叫方侧的 callid，请参阅 $TH_callee_callid pvar。
*注：*使用 "C" 标志更改呼叫的 callid 仅在
						使用 *dialog 支持*进行 topology_hiding 时可用。
						在没有 dialog 支持的情况下使用此标志根本不会更改 callid！


第二个参数可用于在 Contact 头 URI 中公布特定的
			*username*，可以在 *呼叫方*、*被叫方*
			或两侧，通过 */* 分隔。
			参数的格式为 
			*caller_username|/[caller_contact_username][/callee_contact_username]*。
			如果缺少分隔符，则在两侧公布相同的 contact 用户名。
			如果使用了分隔符，您可以控制每个分支中放入的 username。


```c title="topology_hiding 使用示例"
...
if(!has_totag() && is_method("INVITE")) {
	topology_hiding();
}
...
...
if(!has_totot() && is_method("INVITE")) {
	topology_hiding("U");
}
...
# 为呼叫方和被叫方的 Contact 用户名都设置 "opensips"
if(!has_totag() && is_method("INVITE")) {
	topology_hiding("U", "opensips");
}
...
# 在呼叫方的 Contact 用户名中设置 "caller"
if(!has_totag() && is_method("INVITE")) {
	topology_hiding("U", "/caller");
}
...
# 在被叫方的 Contact 用户名中设置 "callee"
if(!has_totag() && is_method("INVITE")) {
	topology_hiding("U", "//callee");
}
...
# 在呼叫方的 Contact 用户名中设置 "caller"，
# 在被叫方的 Contact 用户名中设置 "callee"
if(!has_totag() && is_method("INVITE")) {
	topology_hiding("U", "/caller/callee");
}
...
```


```c title="为拓扑隐藏顺序请求调用 topology_hiding_match() 函数"
...
if (has_totag())
        if(topology_hiding_match())
        {
                xlog("找到一个属于现有拓扑隐藏 dialog 的请求 $rm\n");
                route(relay);
                exit;
        }
}
...
```


#### topology_hiding_match([dlg_match_mode])


此函数用于匹配和修复属于现有拓扑隐藏 dialog 的顺序请求。


关于 dialog 匹配（包括可选参数），
		此函数的行为与 match_dialog() 完全相同。
		有关 dialog 匹配选项的更多详细信息，请参阅 dialog 模块文档。


如果请求存在拓扑隐藏 dialog 且请求已成功修复，函数返回 true。


此函数可用于 REQUEST_ROUTE。


```c title="topology_hiding_match_dialog() 使用示例"
...
    if (has_totag()) {
        if (!topology_hiding_match() ) {
            xlog(" 无法将请求匹配到 dialog \n");
	    send_reply(404,"Not found");
        } else
		route(RELAY);
    }
...
```


### 导出的伪变量


#### $TH_callee_callid


只读变量，如果调用了 topology_hiding("C")，
		它将包含传播到被叫方侧的 callid。


如果没有请求的拓扑隐藏 dialog，
		或者当前 dialog 未使用 callid 编码的 topology_hiding，
		则返回 NULL。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
