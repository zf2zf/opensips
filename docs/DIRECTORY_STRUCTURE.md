# OpenSIPS 项目目录结构

## 概述

OpenSIPS 是一个开源的 SIP（Session Initiation Protocol）服务器实现，最初从 Fokus Fraunhofer SIP Express Router（SER）项目分叉而来。本文档详细介绍 OpenSIPS 代码库的目录结构及其功能。

---

## 根目录重要文件

| 文件/目录 | 描述 |
|-----------|------|
| `INSTALL` | 安装指南，包含编译、安装和快速入门说明 |
| `README.md` | 项目概述 |
| `NEWS` | 版本更新日志 |
| `AUTHORS` | 核心开发者列表 |
| `COPYING` | GPL 许可证文本 |
| `Makefile` | 主 Makefile |
| `Makefile.defs` | 编译配置定义 |
| `Makefile.conf.template` | 配置文件模板 |
| `CLAUDE.md` | Claude AI 助手指南 |
| `SECURITY.md` | 安全策略 |

---

## 核心目录

### `modules/` — 核心模块目录

包含 **193 个模块**，实现各种 SIP 功能。按功能分类：

#### 认证与授权
| 模块 | 描述 |
|------|------|
| `auth` | 基础认证框架 |
| `auth_db` | 基于数据库的认证 |
| `auth_aaa` | AAA 协议认证 |
| `auth_aka` | AKA 认证 |
| `auth_jwt` | JWT 认证 |
| `auth_web3` | Web3/区块链认证 |

#### 用户位置与注册
| 模块 | 描述 |
|------|------|
| `usrloc` | 用户位置管理（核心模块） |
| `registrar` | SIP 注册处理器 |
| `alias_db` | 数据库别名查找 |
| `speeddial` | 快速拨号 |
| `mid_registrar` | 中间注册服务器 |

#### 事务与路由
| 模块 | 描述 |
|------|------|
| `tm` | 事务管理（核心模块） |
| `rr` | 记录路由 |
| `drouting` | 动态路由 |
| `dispatcher` | 呼叫分发 |
| `freeswitch` | FreeSWITCH 集成 |
| `freeswitch_scripting` | FreeSWITCH 脚本 |

#### 数据库支持
| 模块 | 描述 |
|------|------|
| `db_mysql` | MySQL 数据库 |
| `db_postgres` | PostgreSQL 数据库 |
| `db_sqlite` | SQLite 数据库 |
| `db_oracle` | Oracle 数据库 |
| `db_berkeley` | Berkeley DB |
| `db_cachedb` | Cache DB 后端 |
| `db_virtual` | 虚拟数据库 |

#### 缓存与性能
| 模块 | 描述 |
|------|------|
| `cachedb_redis` | Redis 缓存 |
| `cachedb_memcached` | Memcached 缓存 |
| `cachedb_mongodb` | MongoDB 缓存 |
| `cachedb_sql` | SQL 缓存 |
| `cachedb_local` | 本地缓存 |
| `sql_cacher` | SQL 查询缓存 |

#### 协议传输
| 模块 | 描述 |
|------|------|
| `proto_tls` | TLS 传输 |
| `proto_ws` | WebSocket 传输 |
| `proto_wss` | WSS 传输 |
| `proto_sctp` | SCTP 传输 |
| `proto_msrp` | MSRP 传输 |
| `proto_hep` | HEP 协议 |
| `proto_bin` | 二进制协议 |
| `proto_ipsec` | IPsec 传输 |

#### 计费与通话控制
| 模块 | 描述 |
|------|------|
| `acc` | 计费/通话记录（核心模块） |
| `dialog` | 对话管理 |
| `call_control` | 呼叫控制 |
| `call_center` | 呼叫中心 |
| `b2b_entities` | B2B UA 实体 |
| `b2b_logic` | B2B 逻辑 |
| `cgrates` | CGRates 计费集成 |

#### 事件与统计
| 模块 | 描述 |
|------|------|
| `event_kafka` | Kafka 事件 |
| `event_rabbitmq` | RabbitMQ 事件 |
| `event_routing` | 事件路由 |
| `statistics` | 统计接口 |
| `prometheus` | Prometheus 监控 |

#### SIP 功能扩展
| 模块 | 描述 |
|------|------|
| `nathelper` | NAT 穿越辅助 |
| `nat_traversal` | NAT 遍历 |
| `stir_shaken` | STIR/SHAKEN 来电显示验证 |
| `sipcapture` | SIP 抓包/录制 |
| `siprec` | SIP 录制 |
| `media_exchange` | 媒体交换 |

#### 呈现与即时消息
| 模块 | 描述 |
|------|------|
| `presence` | 呈现服务 |
| `presence_xml` | XML 呈现 |
| `presence_dialoginfo` | 对话信息呈现 |
| `presence_mwi` | 消息等待指示 |
| `pua` | 呈现用户代理 |
| `xcap` | XCAP 客户端 |
| `imc` | 即时会议 |

#### B2B 与电信业务
| 模块 | 描述 |
|------|------|
| `b2b_sca` | 共享呼叫外观 |
| `sst` | SIP 发起会话 |
| `enum` | ENUM 查询 |
| `peering` | 对等互联 |
| `domainpolicy` | 域策略 |

#### 协议转换与互操作
| 模块 | 描述 |
|------|------|
| `tls_mgm` | TLS 连接管理 |
| `tls_openssl` | OpenSSL TLS |
| `tls_wolfssl` | WolfSSL TLS |
| `ldap` | LDAP 集成 |
| `osp` | OSP 协议 |
| `xml` | XML 处理 |
| `json` | JSON 处理 |

#### 负载均衡与集群
| 模块 | 描述 |
|------|------|
| `load_balancer` | 负载均衡 |
| `clusterer` | 集群管理 |
| `tcp_mgm` | TCP 连接管理 |
| `ratelimit` | 速率限制 |
| `qos` | QoS 控制 |

#### 管理接口
| 模块 | 描述 |
|------|------|
| `mi_http` | HTTP MI 接口 |
| `mi_xmlrpc` | XMLRPC MI 接口 |
| `mi_datagram` | Datagram MI 接口 |
| `mi_fifo` | FIFO MI 接口 |
| `mi_html` | HTML MI 接口 |
| `mi_script` | 脚本 MI 接口 |

#### 其他模块
| 模块 | 描述 |
|------|------|
| `httpd` | HTTP 服务器 |
| `rest_client` | REST 客户端 |
| `exec` | 外部命令执行 |
| `Benchmark` | 性能基准测试 |
| `gflags` | 全局标志 |
| `regex` | 正则表达式 |
| `textops` | 文本操作 |
| `sipmsgops` | SIP 消息操作 |
| `path` | Path 头域处理 |
| `diversion` | 呼叫转移 |
| `options` | OPTIONS 请求处理 |
| `maxfwd` | Max-Forwards 处理 |
| `pike` | 防洪水印 |
| `uac` | UAC 功能 |
| `uac_auth` | UAC 认证 |
| `uac_redirect` | UAC 重定向 |
| `uac_registrant` | UAC 注册 |
| `userblacklist` | 用户黑名单 |
| `carrierroute` | 运营商路由 |
| `cfgutils` | 配置工具 |
| `trie` | 前缀树数据结构 |
| `mathops` | 数学运算 |
| `uuid` | UUID 生成 |
| `compression` | SIP 压缩 |
| `sockets_mgm` | 套接字管理 |
| `tracer` | SIP 追踪 |
| `topology_hopping` | 拓扑隐藏 |
| `sngtc` | SNGTC 集成 |
| `janus` | Janus WebRTC 网关 |
| `msrp_ua` | MSRP 用户代理 |
| `msrp_relay` | MSRP 中继 |
| `msrp_gateway` | MSRP 网关 |
| `jabber` | Jabber/XMPP 网关 |
| `xmpp` | XMPP 集成 |
| `perl` | Perl 脚本 |
| `python` | Python 脚本 |
| `lua` | Lua 脚本 |
| `callops` | 呼叫操作 |
| ` Emergency` | 紧急呼叫 |
| `qrouting` | 查询路由 |
| `rabbitmq_consumer` | RabbitMQ 消费者 |
| `rate_cacher` | 速率缓存 |
| `launch_darkly` | LaunchDarkly 集成 |
| `opentelemetry` | OpenTelemetry 追踪 |
| `http2d` | HTTP/2 服务端 |
| `cachedb_couchbase` | Couchbase 缓存 |
| `cachedb_cassandra` | Cassandra 缓存 |
| `cachedb_dynamodb` | DynamoDB 缓存 |
| `h350` | H.350 协议 |
| `osp` | OSP 协议 |
| `snmpstats` | SNMP 统计 |
| `mmgeoip` | MaxMind GeoIP |
| `mqueue` | 消息队列 |
| `msilo` | MSILO 离线消息 |
| `db_http` | HTTP 数据库 |
| `db_flatstore` | 平面文件存储 |
| `db_text` | 文本数据库 |
| `db_perlvdb` | Perl Virtual DB |
| `db_unixodbc` | UnixODBC |
| `pi_http` | HTTP Provisioning Interface |
| `cpl_c` | CPL 呼叫脚本 |
| `signal` | 信号处理 |
| `rtpproxy` | RTP 代理 |
| `rtpengine` | RTP 引擎 |
| `rtp_relay` | RTP 中继 |
| `rtp.io` | RTP.io 集成 |
| `mediaproxy` | 媒体代理 |
| `t38` | T.38 传真 |
| `sdp_demux` | SDP 解复用 |

---

### `lib/` — 共享库

| 目录/文件 | 描述 |
|-----------|------|
| `cJSON.c/h` | JSON 解析库 |
| `digest_auth/` | 摘要认证库 |
| `hash.c/h` | 哈希函数库 |
| `url.c/h` | URL 解析库 |
| `path.c/h` | 路径处理库 |
| `csv.c/h` | CSV 解析库 |
| `sliblist.c/h` | 简单链表库 |
| `list.h` | 链表宏定义 |
| `json/` | JSON 工具 |
| `reg/` | 注册相关库 |
| `dbg/` | 调试工具 |
| `test/` | 测试工具 |
| `modules.mk` | 模块构建定义 |

---

### `core/` — 核心文件（根目录分散）

核心功能实现分布在根目录的 `.c/.h` 文件中：

| 文件 | 描述 |
|------|------|
| `main.c` | 程序入口 |
| `cfg.y` | 配置文件语法分析器 |
| `cfg.lex` | 配置文件词法分析器 |
| `receive.c` | 消息接收 |
| `forward.c` | 消息转发 |
| `route.c` | 路由处理 |
| `transaction.c` | 事务处理 |
| `parser/` | SIP 消息解析器 |
| `mem/` | 内存管理 |
| `net/` | 网络通信（TCP/UDP） |
| `db/` | 数据库抽象层 |
| `mi/` | 管理接口核心 |
| `evi/` | 事件接口核心 |
| `cachedb/` | CacheDB 抽象层 |

---

### `parser/` — SIP 消息解析器

SIP 消息解析的完整实现：

| 文件/目录 | 描述 |
|-----------|------|
| `msg_parser.c/h` | 消息解析主入口 |
| `parse_uri.c/h` | SIP URI 解析（44KB） |
| `parse_via.c/h` | Via 头域解析 |
| `parse_to.c/h` | To/From 头域解析 |
| `parse_header.c/h` | 通用头域解析 |
| `parse_body.c/h` | 消息体解析（SDP等） |
| `parse_param.c/h` | 参数解析 |
| `case_*.h` | SIP 头域大小写处理 |
| `sdp/` | SDP 解析器 |
| `contact/` | Contact 头域解析 |
| `digest/` | Digest 认证解析 |

---

### `mem/` — 内存管理

多种内存分配器实现：

| 文件 | 描述 |
|------|------|
| `shm_mem.c/h` | 共享内存管理 |
| `f_malloc.c/h` | 快速内存分配器 |
| `q_malloc.c/h` | 快速内存分配器（队列） |
| `hp_malloc.c/h` | 高性能内存分配器 |
| `rpm_mem.c/h` | 实时内存池 |
| `f_parallel_malloc.c/h` | 并行内存分配器 |

---

### `net/` — 网络通信

| 文件 | 描述 |
|------|------|
| `net_udp.c/h` | UDP 传输 |
| `net_tcp.c/h` | TCP 传输（74KB） |
| `tcp_conn.h` | TCP 连接管理 |
| `tcp_common.c/h` | TCP 公共函数 |
| `proxy_protocol.c/h` | Proxy Protocol |
| `trans_trace.c/h` | 传输追踪 |
| `proto_tcp/` | TCP 协议层 |
| `proto_udp/` | UDP 协议层 |

---

### `db/` — 数据库抽象层

| 文件 | 描述 |
|------|------|
| `db.c/h` | 数据库主接口 |
| `db_pool.c/h` | 连接池管理 |
| `db_query.c/h` | 查询执行 |
| `db_res.c/h` | 结果集处理 |
| `db_row.c/h` | 行处理 |
| `db_val.c/h` | 值转换 |
| `db_id.c/h` | 数据库标识 |
| `db_insertq.c/h` | 插入队列 |
| `schema/` | 数据库表结构定义 |

---

### `mi/` — 管理接口核心

| 文件 | 描述 |
|------|------|
| `mi.c/h` | MI 主接口 |
| `mi_core.c/h` | 核心 MI 函数 |
| `item.c/h` | MI 项处理 |
| `fmt.c/h` | 格式化函数 |
| `mi_trace.c/h` | MI 追踪 |

---

### `evi/` — 事件接口核心

| 文件 | 描述 |
|------|------|
| `event_interface.c/h` | 事件主接口 |
| `event_route.c/h` | 事件路由 |
| `evi_core.c/h` | 核心事件实现 |
| `evi_transport.c/h` | 事件传输 |
| `evi_params.c/h` | 事件参数 |

---

### `cachedb/` — CacheDB 抽象层

| 文件 | 描述 |
|------|------|
| `cachedb.c/h` | CacheDB 主接口 |
| `cachedb_pool.c/h` | 连接池 |
| `cachedb_id.c/h` | 连接标识 |
| `cachedb_dict.c/h` | 字典缓存 |
| `cachedb_types.c/h` | 类型定义 |
| `example/` | 使用示例 |
| `test/` | 测试 |

---

### `utils/` — 辅助工具

| 目录 | 描述 |
|------|------|
| `db_oracle/` | Oracle 数据库工具 |
| `db_berkeley/` | Berkeley DB 工具 |
| `gdb/` | GDB 调试脚本 |
| `vim/` | Vim 语法高亮 |
| `wireshark/` | Wireshark  dissector |
| `profile/` | 性能分析工具 |

---

### `packaging/` — 打包脚本

各 Linux/Unix 发行版的打包配置：

| 目录 | 描述 |
|------|------|
| `debian/` | Debian/Ubuntu 包 |
| `redhat_fedora/` | RHEL/Fedora 包 |
| `suse/` | openSUSE 包 |
| `freebsd/` | FreeBSD 包 |
| `openbsd/` | OpenBSD 包 |
| `netbsd/` | NetBSD 包 |
| `solaris/` | Solaris 包 |
| `gentoo/` | Gentoo ebuild |
| `arch/` | Arch Linux PKGBUILD |

---

### `scripts/` — 辅助脚本

| 目录 | 描述 |
|------|------|
| `build/` | 编译脚本 |
| `mysql/` | MySQL 数据库脚本 |
| `postgres/` | PostgreSQL 脚本 |
| `sqlite/` | SQLite 脚本 |
| `oracle/` | Oracle 脚本 |
| `dbtext/` | 文本数据库脚本 |
| `db_berkeley/` | Berkeley DB 脚本 |
| `pi_http/` | HTTP 配置接口 |

---

### `etc/` — 示例配置

| 文件 | 描述 |
|------|------|
| `opensips.cfg` | 示例主配置文件 |
| `dictionary.opensips` | RADIUS 字典 |
| `tls/` | TLS 证书配置 |

---

### `test/` — 测试代码

| 文件 | 描述 |
|------|------|
| `unit_tests.c/h` | 单元测试框架 |
| `test_ut.c/h` | 测试工具 |
| `test-sdp-ops.cfg` | SDP 操作测试配置 |
| `fuzz/` | 模糊测试 |

---

### `docker/` — Docker 支持

Docker 相关配置和脚本。

---

### `examples/` — 示例代码

各种功能的使用示例。

---

### `docs/` — 文档

| 目录 | 描述 |
|------|------|
| `manual/` | 管理指南（已翻译为中文） |
| `CONTRIBUTING.md` | 贡献指南 |

---

## 模块依赖关系（简化）

```
                    +-------+
                    |  TM   |  事务管理（核心）
                    +---+---+
                        |
    +-------------------+-------------------+
    |                   |                   |
+-------+          +--------+         +---------+
| USRLOC|          |  RR    |         | DIALOG  | 对话管理
+--------+          +--------+         +----+----+
    |                    |                  |
    +--------+-----------+------------------+
             |
     +-------+-------+
     |               |
+-------+      +--------+
|ACC    |      | AUTH   | 认证模块
+--------+      +--------+

PROTO_* 模块负责网络传输
CACHEDB_* 模块负责缓存
DB_* 模块负责数据持久化
EVENT_* 模块负责事件处理
```

---

## 关键配置流程

1. **编译配置**：`Makefile.conf` 或 `make config`
2. **模块编译**：`make modules` 或指定 `include_modules`
3. **配置文件**：`etc/opensips.cfg`
4. **数据库初始化**：使用 `scripts/` 下的数据库脚本
5. **启动服务**：`opensipsctl start`

---

## 更多信息

- 官方网站：https://opensips.org/
- 官方文档：https://docs.opensips.org/
- GitHub：https://github.com/OpenSIPS/opensips
- 用户邮件列表：users@lists.opensips.org
- 开发邮件列表：devel@lists.opensips.org
