---
title: "cachedb_redis 模块"
description: "本模块是缓存系统的实现，旨在与 Redis 服务器配合工作。它使用 hiredis 客户端库连接到单个 Redis 服务器实例或 Redis 集群中的 Redis 服务器。它使用了 OpenSIPS 核心导出的 Key-Value 接口。"
---

## 管理指南


### 概述


本模块是缓存系统的实现，旨在与 Redis 服务器配合工作。它使用 hiredis 客户端库连接到单个 Redis 服务器实例或 Redis 集群中的 Redis 服务器。
它使用了 OpenSIPS 核心导出的 Key-Value 接口。


### 优势


- *内存成本不再由服务器承担*
- *可以在集群内使用多台服务器，因此内存实际上是无限的*
- *缓存是 100% 持久化的。OpenSIPS 服务器的重启不会影响 DB。Redis DB 也是持久化的，因此也可以在不失数据的情况下重启。*
- *Redis 是开源项目，因此可用于与各种其他应用程序交换数据*
- *通过创建 Redis 集群，多个 OpenSIPS 实例可以轻松共享键值信息*


### Redis Stack 支持


从 OpenSIPS **3.6** 开始，*cachedb_redis* 模块实现了面向列的 CacheDB API 函数。
这使其成为需要此 API 的场景（如用户位置*联合*和*完全共享*）中合适的 CacheDB 存储。


该实现利用了 *RedisJSON* 和 *RediSearch* -- 这些相对较新的功能在 Redis Stack Server 中可用，
而不是通常的 Redis Server（Redis OSS 项目）。更多文档可在 Redis 网站上找到。


OpenSIPS 将在必要时自动检测 RedisJSON 支持的可用性并记录相应的消息。


### Redis 集群支持（拓扑）


连接到 Redis 集群时，模块会自动检测集群模式并在运行时管理完整的 slot-to-node 拓扑。
除了标准的 [cachedb url](#param_cachedb_url) 参数外，无需额外配置。


#### 拓扑发现


在启动时，模块使用 *CLUSTER SHARDS* 命令探测 Redis 服务器（Redis 7.0+ 中可用）。
如果服务器不支持此命令，它会回退到 *CLUSTER SLOTS*（Redis 3.0+ 中可用）。
如果两个命令都不成功，则连接被视为单实例（非集群）连接。


发现的拓扑存储在内部的 O(1) slot 查找表（16384 个 slot）中，将每个 slot 直接映射到其所属的主节点。


#### 自动拓扑刷新


当以下任何事件发生时，模块会自动刷新集群拓扑：


- 从集群节点收到 *MOVED* 重定向（表示永久 slot 迁移）。
- 发生*连接失败*（NULL 回复）且无法重新连接节点。
- *查询针对没有已知所有者的 slot*，
			表明拓扑已过时。
- 操作员通过 [mi redis cluster refresh](#mi_redis_cluster_refresh) MI 命令触发手动刷新。


自动刷新限制为最多每秒一次，以避免对集群造成过多负载。
MI 触发的刷新绕过此速率限制。


#### MOVED 重定向


模块透明处理 Redis 集群 MOVED 重定向：


- *MOVED* — 表示永久 slot 迁移。模块更新其 slot 映射，
			将查询重定向到新节点，并触发拓扑刷新，
			使所有未来查询直接转到正确的节点。


如果重定向指向尚未知道的节点，模块会动态创建新的节点条目、
建立连接并重试查询。


#### 哈希标签


模块支持 Redis 集群*哈希标签*，
它允许将相关键共存放在同一集群节点上。
如果键包含 *{...}* 子字符串，
则仅使用第一个 *{* 和下一个 *}* 之间的内容进行哈希 slot 计算。
例如，键 *{user1000}.profile* 和 *{user1000}.settings*
将始终位于同一节点上，从而实现多键操作。


如果大括号为空 (*{}*) 或没有右大括号，
则整个键按常规进行哈希。


### 限制


- *键（键值对中的键）不能包含空格或控制字符*


### 依赖


#### OpenSIPS 模块


以下模块必须在本模块之前加载：


- *如果定义了 [use tls](#param_use_tls)，则还需要加载 **tls_mgm** 和 **tls_openssl** 模块。*


#### 外部库或应用程序


运行 OpenSIPS 并加载本模块之前，必须安装以下库或应用程序：


- *hiredis:*
在最新的基于 Debian 的发行版上，可以通过运行 'apt-get install libhiredis-dev' 来安装 hiredis

			另外，如果 hiredis 在您的操作系统仓库中不可用，
			hiredis 可从以下地址下载：https://github.com/antirez/hiredis 。
			下载压缩包，解压源码，运行 make，sudo make install。
如果通过 [use tls](#param_use_tls) modparam 启用了 TLS 连接，
			*hiredis* 需要使用 TLS 支持编译。


### 导出的参数


#### cachedb_url (字符串)


OpenSIPS 将连接到的服务器组 URL，以便在脚本中使用 cache_store()、cache_fetch() 等操作。
可以多次设置。URL 的前缀部分将是脚本中使用的标识符。


```c title="设置 cachedb_url 参数"
...
# 单实例 URL（Redis Server 或 Redis Cluster）
modparam("cachedb_redis", "cachedb_url", "redis:group1://localhost:6379/")
modparam("cachedb_redis", "cachedb_url", "redis:cluster1://random_url:8888/")

# 多实例 URL（将执行循环）
```


```c title="使用 Redis 服务器"
...
cache_store("redis:group1", "key", "$ru value");
cache_fetch("redis:cluster1", "key", $avp(10));
cache_remove("redis:cluster1", "key");
...

##### 认证

该模块支持三种基于 URL 格式的认证模式：

**URL 认证格式**

| URL 格式 | AUTH 命令 | 使用场景 |
| --- | --- | --- |
| `redis:group://:password@host:port/` | `AUTH password` | 经典 Redis (< 6.0) 使用 `requirepass` |
| `redis:group://username:password@host:port/` | `AUTH username password` | Redis 6+ ACL 使用每用户凭据 |
| `redis:group://host:port/` | （无） | 非认证 Redis |

**重要**：对于经典仅密码认证，
			URL 必须在密码前包含冒号 (`:password@host`)。
			如果写成 `password@host`（没有冒号），
			凭据将进入 URL 解析器的用户名字段，
			认证将被跳过。

连接到带认证的 Redis 集群时，所有发现的集群节点使用 URL 中的相同凭据。

##### Unix 套接字

从该版本开始，该模块支持通过 Unix 域套接字而非 TCP 连接到本地 Redis 实例。
这可以为共置的 Redis 实例提供更低的延迟并避免网络开销。

要使用 Unix 套接字，请在 URL 查询字符串中添加 `socket=` 参数：

```c
# 基础 Unix 套接字（无认证）
modparam("cachedb_redis", "cachedb_url",
    "redis:local://localhost/?socket=/var/run/redis/redis.sock")

# 带密码认证的 Unix 套接字
modparam("cachedb_redis", "cachedb_url",
    "redis:local://:password@localhost/?socket=/var/run/redis/redis.sock")

# 带 ACL 认证（Redis 6+）和数据库选择的 Unix 套接字
modparam("cachedb_redis", "cachedb_url",
    "redis:local://user:pass@localhost/2?socket=/var/run/redis/redis.sock")
		
```

**限制：**

- Unix 套接字连接始终被视为*单实例*模式（Unix 套接字不支持 Redis 集群）。
- Unix 套接字不能与多个主机组合（故障转移）。
			如果同时指定两者，将导致启动错误。
- TLS 不适用于 Unix 套接字连接，如果启用了 `use_tls`，将被忽略并发出警告。
- TCP keepalive 不适用于 Unix 套接字，会自动跳过。

[mi redis cluster info](#mi_redis_cluster_info) MI 命令将使用 `transport=unix` 和套接字路径显示 Unix 套接字连接。
[mi redis ping nodes](#mi_redis_ping_nodes) 命令可与 Unix 套接字连接正常工作。


#### connect_timeout (整数)

指定 OpenSIPS 等待连接到 Redis 节点的时间（毫秒）。

*默认值为 "5000 ms"。*

```c title="设置 connect_timeout 参数"
...
# 等待 Redis 连接 1 秒
modparam("cachedb_redis", "connect_timeout",1000)
...

#### query_timeout (整数)

指定 OpenSIPS 等待 Redis 节点查询响应的时间（毫秒）。

*默认值为 "5000 ms"。*

```c title="设置 query_timeout 参数"
...
# 等待 Redis 查询 1 秒
modparam("cachedb_redis", "query_timeout",1000)
...

#### shutdown_on_error (整数)

将此参数设置为 1，如果无法连接到 Redis，则 OpenSIPS 将中止启动。
运行时重新连接行为不受此参数影响，始终启用。

*默认值为 "0"（禁用）。*

```c title="设置 shutdown_on_error 参数"
...
# 如果 Redis 宕机则中止 OpenSIPS 启动
modparam("cachedb_redis", "shutdown_on_error", 1)
...

#### lazy_connect (整数)

将此参数设置为 1，OpenSIPS 将延迟建立 Redis 连接，
直到每个 worker 进程实际执行第一个缓存操作。
这可以防止空闲的 worker 进程（从不使用 Redis 的那些）保持打开的套接字，
从而避免 Redis 重启时套接字卡在 CLOSE_WAIT 状态。

启用此参数后，
[shutdown on error](#param_shutdown_on_error) 参数无效，
因为启动时不会尝试连接。

*默认值为 "0"（禁用 — 启动时连接，保持现有行为）。*

```c title="设置 lazy_connect 参数"
...
# 延迟 Redis 连接直到首次使用
modparam("cachedb_redis", "lazy_connect", 1)
...

#### use_tls (整数)

设置此参数将允许您对 Redis 连接使用 TLS。
要为特定连接启用 TLS，您可以在本模块的 cachedb_url 中使用
"tls_domain=*dom_name*" URL 参数（或其他使用 CacheDB 接口的模块）。
这应该放在 URL 末尾 '?' 字符之后。

使用此参数时，还必须确保已加载 *tls_mgm* 并正确配置。
有关 TLS 客户端域的附加信息，请参阅 tls_mgm 模块。

请注意，Redis 从版本 6.0 开始支持 TLS。此外，这是一个可选功能，
在编译时启用，可能不包含在您的操作系统的标准 Redis 包中。

*默认值为 **0**（未启用）*

```c title="设置 use_tls 参数"
...
modparam("tls_mgm", "client_domain", "redis")
modparam("tls_mgm", "certificate", "[redis]/etc/pki/tls/certs/redis.pem")
modparam("tls_mgm", "private_key", "[redis]/etc/pki/tls/private/redis.key")
modparam("tls_mgm", "ca_list",     "[redis]/etc/pki/tls/certs/ca.pem")
...
modparam("cachedb_redis", "use_tls", 1)
modparam("cachedb_redis", "cachedb_url","redis:tls_group://localhost:6379/?tls_domain=redis")
...

#### ftsearch_index_name (字符串)

仅与 *RedisJSON* 和 *RediSearch* 服务器端支持相关。

所有内部 JSON 全文搜索操作使用的全局索引名称。
未来扩展可能会添加例如连接级索引名称设置。

默认值为 **"idx:usrloc"**。

```c title="设置 ftsearch_index_name 参数"
modparam("cachedb_redis", "ftsearch_index_name", "ix::usrloc")
```

#### ftsearch_json_prefix (字符串)

仅与 *RedisJSON* 和 *RediSearch* 服务器端支持相关。

所有内部创建的 Redis JSON 对象（例如使用 JSON.SET 或 JSON.MSET 创建的）的键命名前缀。

默认值为 **"usrloc:"**。

```c title="设置 ftsearch_json_prefix 参数"
modparam("cachedb_redis", "ftsearch_json_prefix", "userlocation:")
```

#### ftsearch_max_results (整数)

仅与 *RedisJSON* 和 *RediSearch* 服务器端支持相关。

每次内部触发的 FT.SEARCH JSON 查找查询返回的最大结果数。

默认值为 **10000** 最大结果。

```c title="设置 ftsearch_max_results 参数"
modparam("cachedb_redis", "ftsearch_max_results", 100)
```

#### redis_keepalive (整数)

Redis 连接的 TCP keepalive 间隔（秒）。设置为正值时，
内核在空闲连接上发送 TCP 探测以检测死对等点（例如由于 NAT/防火墙空闲超时或网络分区）。
这允许下一个查询立即失败而不是等待完整的查询超时，
从而通过现有重试循环实现更快的恢复。

设置为 0 以禁用 TCP keepalive。
建议在生产部署中保持启用，以防止静默连接死亡。

*默认值为 "10"（秒）。*

```c title="设置 redis_keepalive 参数"
...
# 将 TCP keepalive 间隔设置为 15 秒
modparam("cachedb_redis", "redis_keepalive", 15)

# 禁用 TCP keepalive
modparam("cachedb_redis", "redis_keepalive", 0)
...

#### ftsearch_json_mset_expire (整数)

仅与 *RedisJSON* 和 *RediSearch* 服务器端支持相关。

每次 JSON.MSET 操作后（创建 JSON 或添加/删除子键）在 JSON 键上设置/刷新的 Redis EXPIRE 计时器（秒）。
值为 **0** 完全禁用 EXPIRE 查询。

默认值为 **3600** 秒。

```c title="设置 ftsearch_json_mset_expire 参数"
modparam("cachedb_redis", "ftsearch_json_mset_expire", 7200)
```

### 导出的函数

本模块不导出在配置脚本中使用的函数。

### 导出的 MI 函数

#### redis_cluster_info

显示模块管理的所有 Redis 连接的详细信息，
包括集群拓扑、每节点连接状态、slot 分配和每节点查询计数器。

参数：

- *group*（可选）- 如果指定，
			则仅列出属于此组的连接（例如
			来自 *"redis:local://..."* URL 的 *"local"*"）。
			如果省略，
			将列出所有 Redis 连接。

响应是一个 JSON 数组，每个连接对象包括：

- *group* - 连接组名称
- *url* - 原始 cachedb_url
- *mode* - *"cluster"* 或 *"single"*
- *cluster_command*（仅集群模式）-
			*"SHARDS"* 或 *"SLOTS"*，
			取决于用于拓扑发现的 Redis 命令
- *topology_refreshes* - 此连接执行的拓扑刷新次数
- *last_topology_refresh* - 上次拓扑刷新的 UNIX 时间戳
- *nodes* - 集群节点对象数组，
			每个包含：
			*ip*、*port*、
			*status*
			(*"connected"* / *"disconnected"*)、
			*slots_assigned*（仅集群模式）、
			*queries*、*errors*、
			*moved*、
			*last_activity*（自上次成功查询以来的秒数，如果从未查询则为 -1）
- *total_slots_mapped*（仅集群模式）-
			分配了节点的 slot 总数（健康集群应为 16384）

MI FIFO 命令格式：

```c
## 列出所有 Redis 连接
opensips-cli -x mi redis_cluster_info

## 仅列出 "local" 组
opensips-cli -x mi redis_cluster_info group=local
			
```

#### redis_cluster_refresh

强制立即刷新 Redis 集群连接的拓扑。
这绕改了正常的每秒一次速率限制，
并查询集群当前的 slot-to-node 映射。
在手动重新平衡集群或节点添加/删除后很有用。

对于非集群（单实例）连接，
命令返回 *"skipped (not cluster mode)"* 状态。

参数：

- *group*（可选）- 如果指定，
			则仅刷新属于此组的连接。
			如果省略，
			所有集群连接都会被刷新。

响应是一个 JSON 对象数组，每个连接包含 *group* 和 *status*
(*"ok"*、*"error"* 或 *"skipped (not cluster mode)"*)。

MI FIFO 命令格式：

```c
## 刷新所有集群连接
opensips-cli -x mi redis_cluster_refresh

## 仅刷新 "local" 组
opensips-cli -x mi redis_cluster_refresh group=local
			
```

#### redis_ping_nodes

向每个 Redis 节点发送 PING 命令，并报告每个节点的可访问性状态和往返延迟。
用于按需健康检查，而无需等待下一个查询。

参数：

- *group*（可选）- 如果指定，
			则仅 ping 属于此组的节点。
			如果省略，
			所有 Redis 连接都会被 ping。

响应是一个 JSON 数组，每个连接对象包括：

- *group* - 连接组名称
- *nodes* - 节点对象数组，每个
			包含：
			*ip*、*port*、
			*status*
			(*"reachable"*、
			*"unreachable"* 或 *"disconnected"*)、
			*latency_us*（往返时间（微秒），
			如果不可达则为 -1）

MI FIFO 命令格式：

```c
## ping 所有 Redis 节点
opensips-cli -x mi redis_ping_nodes

## 仅 ping "local" 组
opensips-cli -x mi redis_ping_nodes group=local
			
```

### 导出的统计信息

#### redis_queries

跨所有连接和进程执行的 Redis 查询成功总数。


#### redis_queries_failed

失败的 Redis 查询总数（来自 hiredis 的 NULL 回复或 Redis 错误响应，MOVED 除外）。


#### redis_moved

从 Redis 集群节点收到的 MOVED 重定向总数。
MOVED 响应表示永久 slot 迁移 - 模块更新其 slot 映射并重试正确节点上的查询。


#### redis_topology_refreshes

执行的集群拓扑刷新总数（通过 CLUSTER SHARDS 或 CLUSTER SLOTS）。
此计数器对于自动刷新（由 MOVED 响应或不可达节点触发）和手动刷新
（通过 [mi redis cluster refresh](#mi_redis_cluster_refresh) MI 命令触发）都会递增。

### 原始查询语法

cachedb_redis 模块允许运行原始查询，从而充分利用后端的功能。

查询语法是典型的 REDIS 语法。

以下是运行一些 Redis 查询的示例：

```c title="Redis 原始查询示例"
...
	$var(my_hash) = "my_hash_name";
	$var(my_key) = "my_key_name";
	$var(my_value) = "my_key_value";
	cache_raw_query("redis","HSET $var(my_hash) $var(my_key) $var(my_value)");
	cache_raw_query("redis","HGET $var(my_hash) $var(my_key)","$avp(result)");
	xlog("We have fetched $avp(result) \n");
...
	$var(my_hash) = "my_hash_name";
	$var(my_key1) = "my_key1_name";
	$var(my_key2) = "my_key2_name";
	$var(my_value1) = "my_key1_value";
	$var(my_value2) = "my_key2_value";
	cache_raw_query("redis","HSET $var(my_hash) $var(my_key1) $var(my_value1)");
	cache_raw_query("redis","HSET $var(my_hash) $var(my_key2) $var(my_value2)");
	cache_raw_query("redis","HGETALL $var(my_hash)","$avp(result)");

	$var(it) = 0;
	while ($(avp(result)[$var(it)]) != NULL) {
		xlog("Multiple key reply: - we have fetched $(avp(result)[$var(it)]) \n");
		$var(it) = $var(it) + 1;
	}
...

## 常见问题

**Q: 我的 OpenSIPS 偶尔在 libhiredis 中崩溃，怎么办？**

请确保您已将 Redis "libhiredis" 客户端库升级到至少 0.14.1 版本。
	在该版本之前，库中至少报告了一个严重漏洞（[CVE-2020-7105](https://bugzilla.redhat.com/show_bug.cgi?id=CVE-2020-7105)），
	因此升级到最新的稳定版本很可能可以修复崩溃！
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享许可证 4.0 版授权
