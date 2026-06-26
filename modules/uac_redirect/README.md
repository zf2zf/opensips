---
title: "UAC_REDIRECT 模块"
description: "UAC REDIRECT - 用户代理客户端重定向 - 模块增强了 OpenSIPS 处理（解释、过滤、记录和跟随）重定向响应（3xx 回复类）的功能。"
---

## 管理指南


### 概述


UAC REDIRECT - 用户代理客户端重定向 - 模块增强了 OpenSIPS
		处理（解释、过滤、记录和跟随）重定向响应（3xx 回复类）的功能。


UAC REDIRECT 模块提供有状态处理，
		从呼叫的所有 3xx 分支收集联系人。


该模块提供了强大机制来选择和过滤
		用于新重定向的联系人：


- *基于数量* - 限制如
			要使用的联系人总数或
			每个分支选择的最大联系人数。
- *基于正则表达式* - 拒绝和接受
			过滤器的组合允许对用于重定向的联系人进行严格控制。


从 3xx 分支选择要使用的联系人时，
		联系人将根据 "q" 值排序和优先级排序。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *TM* - 事务模块，用于访问
				回复。
- *ACC* - 计费模块，但仅在使用
				日志功能时。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前必须安装以下库或应用程序：


- *无*


### 导出的参数


#### default_filter (string)


过滤联系人的默认行为。可以是
			"accept" 或 "deny"。


*默认值为 "accept"。*


```c title="设置 default_filter 模块参数"
...
modparam("uac_redirect","default_filter","deny")
...

```


#### deny_filter (string)


默认拒绝过滤的正则表达式。只有在
			`default_filter` 参数设置为 "accept" 时才有意义。
			所有匹配 `deny_filter` 的联系人将被拒绝；
			其余的将被接受用于重定向。


此参数只能定义一次 - 多个定义将
			覆盖之前的定义。如果需要定义更多正则表达式，
			请使用 
			`set_deny_filter()` 脚本
			函数。


*此参数是可选的，其默认值为 NULL。*


```c title="设置 deny_filter 模块参数"
...
modparam("uac_redirect","deny_filter",".*@siphub\.net")
...

```


#### accept_filter (string)


默认接受过滤的正则表达式。只有在
			`default_filter` 参数设置为 "deny" 时才有意义。
			所有匹配 `accept_filter` 的联系人将被接受；
			其余的将被拒绝用于重定向。


此参数只能定义一次 - 多个定义将
			覆盖之前的定义。如果需要定义更多正则表达式，
			请使用 
			`set_accept_filter()` 脚本
			函数。


*此参数是可选的，其默认值为 NULL。*


```c title="设置 accept_filter 模块参数"
...
modparam("uac_redirect","accept_filter",".*@siphub\.net")
...

```


### 导出的函数


#### set_deny_filter(filter,flags)


设置额外的拒绝过滤器。最多可组合 6 个。
			此附加过滤器仅适用于当前消息 -
			它不会产生全局效果。


参数：


- *filter* (string) - 正则表达式
- *flags* (string)
根据参数值，可能会重置默认或之前添加的拒绝过滤器：

  - *reset_all* - 重置默认和之前添加的所有拒绝过滤器；
  - *reset_default* - 仅重置默认拒绝过滤器；
  - *reset_added* - 仅重置之前添加的拒绝过滤器；
  - *empty* - 不重置，仅添加过滤器。


此函数可用于 FAILURE_ROUTE。


```c title="set_deny_filter 使用示例"
...
set_deny_filter(".*@domain2.net","reset_all");
set_deny_filter(".*@domain1.net","");
...

```


#### set_accept_filter(filter,flags)


设置额外的接受过滤器。最多可组合 6 个。
			此附加过滤器仅适用于当前消息 -
			它不会产生全局效果。


参数：


- *filter* (string) - 正则表达式
- *flags* (string)
根据参数值，可能会重置默认或之前添加的拒绝过滤器：

  - *reset_all* - 重置默认和之前添加的所有接受过滤器；
  - *reset_default* - 仅重置默认接受过滤器；
  - *reset_added* - 仅重置之前添加的接受过滤器；
  - *empty* - 不重置，仅添加过滤器。


此函数可用于 FAILURE_ROUTE。


```c title="set_accept_filter 使用示例"
...
set_accept_filter(".*@domain2.net","reset_added");
set_accept_filter(".*@domain1.net","");
...

```


#### get_redirects([max_total], [max_branch])


此函数只能从 failure 路由调用。
			它将从所有 3xx 分支提取联系人并将其作为新分支附加。
			请注意，函数不会转发新分支，
			这必须从脚本中明确完成。


选择多少联系人（总数和每个分支）
				取决于 *max_total* 和
				*max_branch* 参数：


- max_total (int, 可选) - 要选择的最大联系人总数
- max_branch (int, 可选) - 每个分支要选择的最大联系人数


"max_total" 和 "max_branch"
				都默认为 0（无限制）。


请注意，在选择过程中，
				每个分支的联系人集根据 "q" 值排序。


此函数可用于 FAILURE_ROUTE。


```c title="get_redirects 使用示例"
...
# 无限制
get_redirects();
...
# 每个分支无限制，但总共不超过 6 个联系人
get_redirects(6);
...
# 每个分支最多 2 个联系人，但总数无限制
get_redirects(, 2);
...

```


### 脚本示例


```c title="重定向脚本示例"
loadmodule "modules/sl/sl.so"
loadmodule "modules/usrloc/usrloc.so"
loadmodule "modules/registrar/registrar.so"
loadmodule "modules/tm/tm.so"
loadmodule "modules/acc/acc.so"
loadmodule "modules/uac_redirect/uac_redirect.so"

modparam("usrloc", "working_mode_preset", "single-instance-no-db")

route{
	if (is_myself("$rd")) {

		if ($rm=="REGISTER") {
			save("location");
			exit;
		};

		if (!lookup("location")) {
			sl_send_reply(404, "Not Found");
			exit;
		};
	}

	t_on_failure("do_redirect");

	if (!t_relay()) {
		sl_reply_error();
	};
}

failure_route[do_redirect] {
	if (get_redirects(3, 1))
		t_relay();
}

			
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可证。
