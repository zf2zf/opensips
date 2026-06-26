---
title: "H350 模块"
description: "OpenSIPS H350 模块使 OpenSIPS SIP 代理服务器能够访问存储在包含 H.350 commObjects 的 LDAP [RFC4510](#RFC4510) 目录中的 SIP 账户数据。ITU-T 建议 H.350 标准定义了 LDAP 对象类来存储实时通信（RTC）账户数据..."
---

## 管理指南


### 概述


OpenSIPS H350 模块使 OpenSIPS SIP 代理服务器能够访问存储在包含 H.350 [H350](#H350) *commObjects* 的 LDAP [RFC4510](#RFC4510) 目录中的 SIP 账户数据。
		ITU-T 建议 H.350 将 LDAP 对象类标准化以存储实时通信（RTC）账户数据。
		特别是*H.350.4* [H350 4](#H350-4) 定义了一个名为 *sipIdentity* 的对象类,
		其中包含 SIP 账户数据的属性规范,如 SIP URI、SIP 摘要用户名/密码或服务级别。
		这允许以供应商中立的方式存储 SIP 账户数据,
		并允许不同的实体（如 SIP 代理、配置或计费应用程序）以标准化格式访问数据。


*ViDe H.350 Cookbook* [vide H350 cookbook](#vide-H350-cookbook) 是部署 H.350 目录的良好参考。
		除了关于 H.350、LDAP 和相关标准的一般信息外,
		本文档还解释了如何设置 H.350/LDAP 目录并讨论了不同的部署场景。


H350 模块使用 OpenSIPS LDAP 模块将 H.350 属性值导入 OpenSIPS 路由脚本变量空间。
		该模块导出函数用于从 OpenSIPS 路由脚本解析和存储 H.350 属性值。
		它允许脚本编写者实现基于 H.350 的 SIP 摘要认证、呼叫转发、
		SIP URI 别名到 AOR 重写以及服务级别解析。


#### H.350 commObject LDAP 条目示例


以下示例显示了一个典型的 H.350 commObject LDAP 条目,
		其中存储了 SIP 账户数据。


```c title="存储 SIP 账户数据的 H.350 commObject 示例"
Attribute Name                Attribute Value(s)
--------------                -----------------

# LDAP URI identifying the owner of this commObject, typically 
# points to an entry in the enterprise directory
commOwner	ldap://dir.example.com/dc=example,dc=com??one?(uid=bob)	

# Unique identifier for this commObject, used for referencing 
# this object e.g. from the enterprise directory 
commUniqueId                  298217asdjgj213


# Determines if this commObject should be listed on white pages
commPrivate                   false

# Valid SIP URIs for this account (can be used to store alias SIP URIs 
# like DIDs as well)
SIPIdentitySIPURI             sip:bob@example.com                 
                              sip:bob@alias.example.com
                              sip:+1919123456@alias.example.com
# SIP digest username	
SIPIdentityUserName           bob

# SIP digest password
SIPIdentityPassword           pwd

# SIP proxy address
SIPIdentityProxyAddress       sip.example.com

# SIP registrar address
SIPIdentityRegistrarAddress   sip.example.com

# Call preferences: Forward to voicemail on no response 
# after 20 seconds and on busy
callPreferenceURI             sip:bob@voicemail.example.com n:20000
                              sip:bob@voicemail.example.com b
	
# Account service level(s)
SIPIdentityServiceLevel	      long_distance
                              conferencing
                              
# H.350 object classes
objectClass                   top
                              commObject
                              SIPIdentity
                              callPreferenceURIObject
            
```


### 依赖


#### OpenSIPS 模块


该模块依赖以下模块（以下模块必须在此模块之前加载）：


- LDAP


#### 外部库或应用程序


以下库或应用程序必须在运行
		加载本模块的 OpenSIPS 之前安装：


- OpenLDAP 库（libldap）,编译需要 libldap 头文件（libldap-dev）


### 导出的参数


#### ldap_session (string)


用于 H.350 查询的 LDAP 会话名称,
		如 LDAP 模块配置文件中定义的那样。


默认值: ""


```c title="ldap_session 参数使用"
modparam("h350", "ldap_session", "h350");
            
```


#### base_dn (string)


开始 H.350 条目 LDAP 搜索的基础 LDAP DN。
		为获得最佳性能,这应该设置为 H.350 对象的直接祖先。


默认值: ""


```c title="base_dn 参数使用"
modparam("h350", "base_dn", "ou=h350,dc=example,dc=com");
            
```


#### search_scope (string)


H.350 查询的 LDAP 搜索范围,
		为 "one"、"base" 或 "sub" 之一。


默认值: "one"


```c title="search_scope 参数使用"
modparam("h350", "search_scope", "sub");
            
```


### 导出的函数


#### h350_sipuri_lookup(sip_uri)


此函数对具有 SIPIdentitySIPURI 为 `sip_uri` 的 H.350 commObject 执行 LDAP 搜索查询。
		`sip_uri` 参数首先根据 LDAP 过滤器字符串的规则进行转义。
		LDAP 搜索的结果存储在内部,
		可以由 OpenSIPS LDAP 模块的 *h350_result** 或 *ldap_result** 函数访问。


函数在内部错误时返回 `-1`（FALSE）,
		如果未找到具有匹配 `sip_uri` 的 H.350 commObject,则返回 `-2`（FALSE）。
		如果找到 `n` 个 H.350 commObject,则返回 `n` > 0（TRUE）。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE 和 BRANCH_ROUTE。


**sip_uri (string)**


要在目录中搜索的 H.350 SIPIdentitySIPURI。


**`n` > 0（TRUE）：**


- 找到 `n` 个 H.350 commObject。


**`-1`（FALSE）：**


- 发生内部错误。


**`-2`（FALSE）：**


- 未找到 H.350 commObject。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 ONREPLY_ROUTE。


```c title="使用示例"
#
# H.350 被叫方查找
#

if (!h350_sipuri_lookup("sip:$rU@$rd"))
{
    switch ($retcode)
    {
    case -2:
        xlog("L_INFO", 
             "h350 被叫方查找: 在 H.350 目录中未找到条目");
        exit;
    case -1:
        sl_send_reply(500, "内部服务器错误");
        exit;
    }
}

# 现在可以使用 h350_result* 或 ldap_result* 函数
            
```


#### h350_auth_lookup(auth_username, "username_avp_spec/pwd_avp_spec")


此函数对 H.350 目录中的 SIP 摘要认证凭据执行 LDAP 搜索查询。
		搜索 H.350 目录中具有 SIPIdentityUserName 为 `auth_username` 的 commObject。
		如果找到这样的 commObject,
		SIP 摘要认证用户名和密码分别存储在 AVP `username_avp_spec` 和 `pwd_avp_spec` 中。
		然后可以使用 AUTH 模块的 *pv_*_authorize* 函数执行 SIP 摘要认证。


如果找到 H.350 commObject,函数返回 `1`（TRUE）；
		发生内部错误时返回 `-1`（FALSE）；
		如果未找到匹配的 commObject,则返回 `-2`（FALSE）。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE 和 BRANCH_ROUTE。


**auth_username (string)**


要在目录中搜索的 H.350 SIPIdentityUserName。


**username_avp_spec (var)**


认证用户名 AVP 的规范,例如 `$avp(username)`。


**pwd_avp_spec (var)**


认证密码 AVP 的规范,例如 `$avp(pwd)`。


**`1`（TRUE）：**


- 找到 H.350 commObject,
		SIP 摘要认证凭据已存储在 `username_avp_spec` 和 `pwd_avp_spec` 中。


**`-1`（FALSE）：**


- 发生内部错误。


**`-2`（FALSE）：**


- 未找到 H.350 commObject。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 ONREPLY_ROUTE。


```c title="使用示例"
# -- 认证参数 --
modparam("auth", "username_spec", "$avp(auth_user)")
modparam("auth", "password_spec", "$avp(auth_pwd)")
modparam("auth", "calculate_ha1", 1)

# -- h350 参数 --
modparam("h350", "ldap_session", "h350")
modparam("h350", "base_dn", "ou=h350,dc=example,dc=com")
modparam("h350", "search_scope", "one")


route[1]
{
    #
    # 基于 H.350 的 SIP 摘要认证 
    #
     
    # 对所有不包含 Auth 头部的请求进行挑战
    if (!(is_present_hf("Authorization") || 
          is_present_hf("Proxy-Authorization")))
    {
        if (is_method("REGISTER"))
        {
            www_challenge("example.com", 0);
            exit;
        }
        proxy_challenge("example.com", 0);
        exit;
    }

    # 使用 auth 用户名（$au）从 H.350 获取摘要密码
    if (!h350_auth_lookup($au, 
                          "$avp(auth_user)/$avp(auth_pwd)"))
    {
        switch ($retcode)
        {
        case -2:
            sl_send_reply(401, "Unauthorized");
            exit;
        case -1:
            sl_send_reply(500, "内部服务器错误");
            exit;
        }
    }

    # REGISTER 请求
    if (is_method("REGISTER"))
    {
        if (!pv_www_authorize("example.com"))
        {
            if ($retcode == -5)
            {
                sl_send_reply(500, "内部服务器错误");
                exit;    
            }
            else {
                www_challenge("example.com", 0);
                exit;
            }
        }

        consume_credentials();
        xlog("L_INFO", 
             "REGISTER 请求成功认证");
        return(1);
    }

    # 非 REGISTER 请求
    if (!pv_proxy_authorize("example.com"))
    {
        if ($retcode == -5)
        {
            sl_send_reply(500, "内部服务器错误");
            exit;    
        }
        else {
            proxy_challenge("example.com", 0);
            exit;
        }
    }

    consume_credentials();
    xlog("L_INFO", "$rm 请求成功认证");
    return(1);
}
            
```


#### h350_result_call_preferences(avp_name_prefix)


此函数解析 H.350 commObject 的 callPreferenceURI 属性,
		该 commObject 必须已经通过 *h350_*_lookup* 或 *ldap_search* 获取。
		callPreferenceURI 是一个多值属性,
		存储呼叫偏好规则,如呼叫前转（忙时、无应答等）。
		*呼叫转发的目录服务架构和偏好* [H350 6](#H350-6)
		定义了简单呼叫转发规则的格式：


`target_uri type[:argument]`


在 SIP 环境中,`target_uri` 通常是呼叫转发规则的目标 SIP URI,
		尽管它可以是任何类型的 URI,例如指向 CPL 脚本的 HTTP 指针。
		为 `type` 指定了四个不同的值：
		`b` 表示"忙时前转",`n` 表示"无应答前转",
		`u` 表示"无条件前转",`f` 表示"目标未找到前转"。
		可选的 `argument` 是一个字符串,指示呼叫转发发生前的毫秒数。


```c title="H.350 callPreferenceURI 简单呼叫前转规则示例"
# 示例 1:
# 15 秒无应答后转接到 sip:voicemail@example.com:

callPreferenceURI: sip:voicemail@example.com n:15000

# 示例 2:
# 无条件前转到 sip:alice@example.com:

callPreferenceURI: sip:alice@example.com u

# 示例 3:
# 目标未找到时前转到 sip:bob@example.com 和 sip:alice@example.com
#（分叉）:

callPreferenceURI: sip:bob@example.com f
callPreferenceURI: sip:alice@example.com f
            
```


*h350_result_call_preferences* 根据以下规则将这些呼叫前转规则存储为 AVP：


```c
#
# 存储前转规则目标 URI 的 AVP
#
            
AVP name  = avp_name_prefix + '_' + type
AVP value = target_uri

#
# 存储前转规则参数的 AVP
#

AVP name  = avp_name_prefix + '_' + type + '_t'
AVP value = argument / 1000
            
```


上面的示例 1 将产生两个 AVP：
	`$avp("prefix_n") = "sip:voicemail@example.com"` 和 `$avp("prefix_n_t") = 15`。


示例 2：`$avp("prefix_u") = "sip:alice@example.com"`。


示例 3：`$avp("prefix_f[1]") = "sip:bob@example.com"` 和 `$avp("prefix_f[2]]") = "sip:alice@example.com"`。


然后可以在 OpenSIPS 路由脚本中使用这些 AVP 来实现所需的行为。


如果 H.350 callPreferenceURI 属性包含一个或多个匹配上述简单呼叫前转规则的多个值,
		此函数返回成功解析的简单呼叫前转规则的数量（TRUE）。
		对于内部错误返回 `-1`（FALSE）,
		如果没有规则匹配或未找到 callPreferenceURI 属性,则返回 `-2`（FALSE）。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE 和 BRANCH_ROUTE。


**avp_name_prefix (string)**


呼叫前转规则 AVP 的名称前缀,如上所述。


**`n` > 0（TRUE）：**


- 找到 `n` 个简单呼叫前转规则。


**`-1`（FALSE）：**


- 发生内部错误。


**`-2`（FALSE）：**


- 未找到简单呼叫前转规则,或 callPreferenceURI 不存在。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 ONREPLY_ROUTE。


```c title="使用示例"
#
# H.350 被叫方查找
#

... h350_sipuri_lookup("sip:$rU@$rd") ...

#
# 将 H.350 呼叫偏好存储在 AVP 中
#

if (!h350_result_call_preferences("callee_pref_") && ($retcode == -1))
{
    sl_send_reply(500, "内部服务器错误");
    exit;
}

# $avp(callee_pref_u)   = CFU URI(s)
# $avp(callee_pref_n)   = CFNR URI(s)
# $avp(callee_pref_n_t) = CFNR 超时秒数
# $avp(callee_pref_b)   = CFB URI(s)
# $avp(callee_pref_f)   = CFOFFLINE URI(s)

#
# 无条件前转（CFU）示例
#

if ($avp(callee_pref_u) != NULL)
{
    # 将 CFU URI 推入 R-URI 和额外分支
    # --> 请求可以分叉
    $ru = $avp(callee_pref_u);
    $avp(callee_pref_u) = NULL;
    while ($avp(callee_pref_u)!=NULL) {
        $branch = $avp(callee_pref_u);
        $avp(callee_pref_u) = NULL;
    }
    sl_send_reply(181, "呼叫正在前转");
    t_relay();
    exit;
}
            
```


#### h350_result_service_level(avp_name_prefix)


*SIP 目录服务架构* [H350 4](#H350-4)
		定义了一个名为 SIPIdentityServiceLevel 的多值 LDAP 属性,
		可用于在 LDAP 目录中存储 SIP 账户服务级别值。
		此函数解析 SIPIdentityServiceLevel 属性并将所有服务级别值存储为 AVP,
		以供 OpenSIPS 路由脚本后续检索。
		该函数访问由 *h350_*_lookup* 或 *ldap_search* 调用获取的 H.350 commObject。


结果 AVP 的名称形式为 `avp_name_prefix + SIPIdentityServiceLevel 属性值`,
		整数值为 `1`。


```c title="SIPIdentityServiceLevel 值及结果 AVP 示例"
SIPIdentityServiceLevel: longdistance
SIPIdentityServiceLevel: international
SIPIdentityServiceLevel: 900

调用 h350_result_service_level("sl_") 后,
路由脚本中将有以下 AVP 可用：

$avp("sl_longdistance") = 1
$avp("sl_international") = 1
$avp("sl_900") = 1
            
```


此函数返回添加的 AVP 数量（TRUE）；
		发生内部错误时返回 `-1`（FALSE）；
		未找到 SIPIdentityServiceLevel 属性时返回 `-2`（FALSE）。


函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE 和 BRANCH_ROUTE。


**avp_name_prefix (string)**


服务级别 AVP 的名称前缀,如上所述。


**`n` > 0（TRUE）：**


- 添加了 `n` 个 AVP。


**`-1`（FALSE）：**


- 发生内部错误。


**`-2`（FALSE）：**


- 未找到 SIPIdentityServiceLevel 属性。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 和 ONREPLY_ROUTE。


```c title="使用示例"
#
# H.350 SIP 摘要认证（主叫方）
#

... h350_auth_lookup("$au", ...) ...

#
# 将主叫方的服务级别存储为 AVP
#

if (!h350_result_service_level("caller_sl_") && ($retcode == -1))
{
    sl_send_reply(500, "内部服务器错误");
    exit;
}

#
# 根据服务级别 AVP 做出路由决策
#

if ($avp(caller_sl_international) != NULL)
{
    t_relay();
} 
else {
    sl_send_reply(403, "Forbidden");    
}
exit;
            
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权
