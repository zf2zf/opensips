---
title: "UAC 模块"
description: "UAC（User Agent Client，用户代理客户端）模块提供一些基本的 UAC 功能，如 FROM/TO 头域 manipulation（匿名化）或客户端认证。"
---

## 管理指南


### 概述


UAC（User Agent Client，用户代理客户端）模块提供一些基本的 UAC
		功能，如 FROM/TO 头域 manipulation（匿名化）或客户端认证。


如果 dialog 模块已加载且可以创建 dialog，则可以使用自动模式
		来提高效率。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *TM - Transaction Module（事务模块）*。
- *RR - Record-Route Module（记录路由模块）*，但仅在 FROM URI 的
			恢复模式设置为"auto"时需要。
- *UAC_AUTH - UAC Authentication Module（UAC 认证模块）*。
- *Dialog Module（Dialog 模块）*，如果启用了"force_dialog"
			模块参数，或在配置脚本中创建了 dialog。


#### 外部库或应用程序


以下库或应用程序必须在运行加载了此模块的 OpenSIPS 之前安装：


- *无*


### 导出的参数


#### restore_mode (string)


有三种恢复原始头域（FROM/TO）URI 的模式：


- "none" - 不存储原始 URI 的任何信息；
			无法进行恢复。
- "manual" - 所有后续回复都将被恢复，
			顺序请求除外 - 这些必须基于原始 URI 手动
			更新。
- "auto" - 所有顺序请求和回复都将
			基于存储的原始 URI 自动更新。


*此参数是可选的，默认值为
					"auto"。*


```c title="设置 restore_mode 参数"
...
modparam("uac","restore_mode","auto")
...
				
```


#### restore_passwd (string)


用于加密 RR 存储参数的字符串密码
			（在替换 TO/FROM 头域时使用）。如果为空，则不会使用
			加密。


*此参数的默认值为空。*


```c title="设置 restore_passwd 参数"
...
modparam("uac","restore_passwd","my_secret_passwd")
...
				
```


#### rr_from_store_param (string)


Record-Route 头域参数的名称，用于存储
			（编码）原始 FROM URI。


*此参数是可选的，默认值为
					"vsf"。*


```c title="设置 rr_from_store_param 参数"
...
modparam("uac","rr_from_store_param","my_Fparam")
...
				
```


#### rr_to_store_param (string)


Record-Route 头域参数的名称，用于存储
			（编码）原始 TO URI。


*此参数是可选的，默认值为
					"vst"。*


```c title="设置 rr_to_store_param 参数"
...
modparam("uac","rr_to_store_param","my_Tparam")
...
				
```


#### force_dialog (int)


如果未从配置脚本创建 dialog，则强制创建 dialog。


默认值为 no（否）。


```c title="设置 force_dialog 参数"
...
modparam("uac", "force_dialog", yes)
...
				
```


### 导出的函数


#### uac_replace_from([display],uri) uac_replace_to([display],uri)


替换 FROM/TO 头域中的 *display* 名称或/和
			*URI* 部分。


两个参数都是字符串。*display* 是可选的。
			如果缺失，则只会在消息中更改 URI。


重要提示：在每个 branch 上多次调用此函数将导致
			对请求的更改不一致。请确保每个 branch 只进行一次更改。注意，从 REQUEST
			ROUTE 调用此函数会影响所有 branch！，因此将来不可能进行其他更改。对于每个 branch 的更改，请使用 BRANCH 和
			FAILURE route。


此函数可以从 REQUEST_ROUTE、BRANCH_ROUTE 和
			FAILURE_ROUTE 使用。


```c title="uac_replace_from/uac_replace_to 使用示例"
...
# 替换 display 和 uri
uac_replace_from($avp(display),$avp(uri));
# 只替换 display，不更改 uri
uac_replace_from("batman","");
# 移除 display 并替换 uri
uac_replace_from("","sip:robin@gotham.org");
# 移除 display 且不更改 uri
uac_replace_from("","");
# 替换 URI 而不更改 display
uac_replace_from( , "sip:batman@gotham.org");
...
				
```


#### uac_restore_from() uac_restore_to()


此函数将检查 FROM/TO URI 是否已被修改，并使用
			头域参数中存储的信息来恢复
			原始 FROM/TO URI 值。


注意 - 此函数仅应在您配置了 MANUAL
			头域恢复时使用（请参阅 restore_mode 参数）。对于 AUTO
			和 NONE，无需使用此函数。


此函数可以从 REQUEST_ROUTE 使用。


```c title="uac_restore_from/uac_restore_to 使用示例"
...
uac_restore_from();
...
				
```


#### uac_auth()


此函数只能从 failure route 调用，并将
			构建认证响应头并将其插入到请求中，但不发送任何内容。
			用于构建认证响应的凭据将从 uac_auth 模块提供的凭据列表中获取（静态
			或通过 AVP）。


作为可选参数，此函数可以接收一个认证
			算法列表，在认证过程中考虑/支持这些算法：


- MD5、MD5-sess
- SHA-256、SHA-256-sess（可能缺失，取决于 lib 支持）
- SHA-512-256、SHA-512-256-sess（可能缺失，取决于 lib 支持）


请注意，CSeq 在认证期间会自动增加。


此函数可以从 FAILURE_ROUTE 使用。


*注意：* 当在没有 dialog 支持的情况下使用时，
				*uac_auth()* 函数无法用于认证
				-dialog 请求，因为没有机制来存储对话所需的 CSeq 更改。
				唯一的例外是 *BYE* 消息，它是通话中的最后一条消息，
				因此不需要进一步的调整。但是，该函数仍然可以用于
				认证初始 INVITE。


```c title="uac_auth 使用示例"
...
uac_auth();
...
failure_route[check_auth] {
    ...
    if ($T_reply_code==407) {
        if (uac_auth("MD5,MD5-sess")) {
            # 认证成功，只需转发
            t_relay();
            exit;
        }
        # 认证失败（可能没有凭据）
        # 所以继续处理 407 回复
    }
    ...
}
...
				
```


#### uac_inc_cseq()


可以调用此函数来增加正在进行的请求的 CSeq。


它接收 *cseq* 参数作为
			CSeq 应该增加的值。


此函数可以从 REQUEST_ROUTE、BRANCH_ROUTE 和 FAILURE_ROUTE 使用。


```c title="uac_inc_cseq 使用示例"
...
uac_inc_cseq(1);
...
				
```


## 常见问题


**Q: auth_username_avp、auth_realm_avp 和 auth_password_avp 参数怎么了？**


由于 UAC auth 模块的一些重构，这些参数已移至"uac_auth"模块。
		此模块现在负责处理所有凭据（静态定义或通过 AVP 动态定义）。
		UAC 模块仍然可以看到通过 AVP 定义的凭据。


**Q: 在哪里可以找到更多关于 OpenSIPS 的信息？**


请参阅 [https://opensips.org/](https://opensips.org/)。


**Q: 在哪里可以发布关于此模块的问题？**


首先检查您的问题是否已在我们
			的邮件列表中回答：

关于任何稳定 OpenSIPS 版本的电子邮件应发送至
			users@lists.opensips.org，关于开发版本的
			电子邮件应发送至 devel@lists.opensips.org。

如果您想保持邮件私密，请发送至
			users@lists.opensips.org。


**Q: 如何报告错误？**


请遵循以下指南：
			[https://github.com/OpenSIPS/opensips/issues](https://github.com/OpenSIPS/opensips/issues)。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证授权。
