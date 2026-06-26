---
title: "domain 模块"
description: "Domain 模块实现检查功能，基于 domain 表确定 URI 的主机部分是否是\"本地的\"。\"本地\"域名是代理服务器负责的域名。"
---

## 管理指南


### 概述


Domain 模块实现检查功能，基于 domain 表确定 URI 的主机部分是否是"本地的"。 "本地"域名是代理服务器负责的域名。


Domain 模块根据模块参数 `db_mode` 的值在缓存或非缓存模式下运行。在缓存模式下，domain 模块在加载模块时将 domain 表的内容读入缓存内存。此后，仅当模块收到 domain:reload MI 命令时才会重新读取 domain 表。因此，domain 表中的任何更改都必须随后执行"domain:reload"命令才能反映到模块行为中。在非缓存模式下，domain 模块始终查询数据库中的 domain 表。


缓存使用哈希表实现。哈希表大小由 domain_mod.h 中定义的 HASH_SIZE 常量给出。其"出厂默认值"为 128。


### 依赖


该模块依赖以下模块（换句话说，以下模块必须在此模块之前加载）：


- *database* -- 任何数据库模块


### 导出的参数


#### db_url (string)


这是要使用的数据库的 URL。


默认值为 
			"mysql://opensipsro:opensipsro@localhost/opensips"


```c title="设置 db_url 参数"
modparam("domain", "db_url", "mysql://ser:pass@db_host/ser")
```


#### db_mode (integer)


数据库模式：0 表示非缓存，1 表示缓存。


默认值为 0（非缓存）。


```c title="db_mode 示例"
modparam("domain", "db_mode", 1)   # 使用缓存
```


#### domain_table (string)


包含代理服务器负责的本地域名列表的表名。本地用户的 SIP URI 中的主机部分必须等于这些域名之一。


默认值为 "domain"。


```c title="设置 domain_table 参数"
modparam("domain", "domain_table", "new_name")
```


#### domain_col (string)


domain 表中包含域名的列名。


默认值为 "domain"。


```c title="设置 domain_col 参数"
modparam("domain", "domain_col", "domain_name")
```


#### attrs_col (string)


domain 表中包含属性的列名。


默认值为 "attrs"。


```c title="设置 attrs_col 参数"
modparam("domain", "attrs_col", "attributes")
```


#### subdomain_col (int)


domain 表中"accept_subdomain"列的名称。该列的正值表示该域名接受子域名。0 值表示不接受。


默认值为 "accept_subdomain"。


```c title="设置 subdomain_col 参数"
modparam("domain", "subdomain_col", "has_subdomain")
```


### 导出的函数


#### is_from_local([attrs_var])


基于 domain 表检查 From 头 URI 的主机部分是否是代理服务器负责的本地域名之一。参数是可选的，如果存在，应包含一个可写变量，该变量将被填充来自数据库的属性。


此函数可以从 REQUEST_ROUTE 使用。


```c title="is_from_local 使用示例"
...
if (is_from_local()) {
	...
};
...
if (is_from_local($var(attrs))) {
	xlog("Domain attributes are $var(attrs)\n");
	...
};
...

```


#### is_uri_host_local([attrs_var])


如果从 route 或 failure route 块调用，则基于 domain 表检查 Request-URI 的主机部分是否是代理服务器负责的本地域名之一。
如果从 branch route 调用，则在第一个分支的 URI 主机部分上进行测试，因此必须在调用 is_uri_host_local() 之前将其附加到事务中。
参数是可选的，如果存在，应包含一个可写变量，该变量将被填充来自数据库的属性。


此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。


```c title="is_uri_host_local 使用示例"
...
if (is_uri_host_local()) {
	...
};
...
if (is_uri_host_local($var(attrs))) {
	xlog("Domain attributes are $var(attrs)\n");
	...
};

```


#### is_domain_local(domain, [attrs_var])


此函数检查第一个参数中包含的域名是否是本地的。


此函数是 is_from_local() 和 is_uri_host_local() 函数的广义形式，能够完全替换它们，并通过允许从上述任何来源获取域名来扩展它们。
以下等价关系存在：


- is_domain_local($rd) 等同于 is_uri_host_local()
- is_domain_local($fd) 等同于 is_from_local()


参数：


- *domain* (string)
- *attrs_var* (var, 可选) - 一个可写变量，该变量将被填充来自数据库的属性。


此函数可以从 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE 使用。


```c title="is_domain_local 使用示例"
...
if (is_domain_local($rd)) {
	...
};
if (is_domain_local($fd)) {
	...
};
if (is_domain_local($avp(some_avp_alias))) {
	...
};
if (is_domain_local($avp(850))) {
	...
};
if (is_domain_local($avp(some_avp))) {
	...
};
if (is_domain_local($avp(some_avp), $avp(attrs))) {
	xlog("Domain attributes are $avp(attrs)\n");
	...
};
...

```


### 导出的 MI 函数


#### domain:reload


替换已弃用的 MI 命令：*domain_reload*。


使 domain 模块将 domain 表的内容重新读入缓存内存。


名称：*domain:reload*


参数：*无*


MI FIFO 命令格式：


```c
		opensips-cli -x mi domain:reload
		
```


#### domain:dump


替换已弃用的 MI 命令：*domain_dump*。


使 domain 模块转储其缓存内存中的哈希索引和域名。


名称：*domain:dump*


参数：*无*


MI FIFO 命令格式：


```c
		opensips-cli -x mi domain:dump
		
```


### 已知限制


在 domain 列表更新时存在一个不太可能的竞争条件。如果某个进程使用的表同时通过 FIFO 重新加载了两次，第二次重新加载将删除该进程仍在使用的原始表。


## 开发者指南


该模块为其他 OpenSIPS 模块提供 is_domain_local API 函数。


### 可用函数


#### is_domain_local(domain)


检查 str* 参数中给出的域名是否是本地的。


如果域名是本地的则返回 1，如果不是本地或发生错误则返回 -1。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用 Creative Common License 4.0 许可证。
