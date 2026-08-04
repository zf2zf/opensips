# OpenSIPS GB28181 代理集群部署

## 快速开始

### 1. 编译

```bash
cd /root/work/zf2zf/opensips/opensips
./deploy/scripts/build.sh build
```

### 2. 安装

```bash
./deploy/scripts/build.sh install
```

### 3. 部署配置

**单机模式：**
```bash
./deploy/scripts/deploy.sh single -l 20.20.136.66 -u 1.2.3.4:5060
/opt/zfnproxy/opensips/sbin/opensips -f /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg
```

**集群模式 - 节点 A：**
```bash
./deploy/scripts/deploy.sh node_a -l 20.20.136.66 -p 20.20.136.67 -v 20.20.136.100 -u 1.2.3.4:5060
/opt/zfnproxy/opensips/sbin/opensips -f /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg
```

**集群模式 - 节点 B：**
```bash
./deploy/scripts/deploy.sh node_b -l 20.20.136.67 -p 20.20.136.66 -v 20.20.136.100 -u 1.2.3.4:5060
/opt/zfnproxy/opensips/sbin/opensips -f /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg
```

---

## 目录结构

```
deploy/
├── Makefile.conf           # 编译模块配置（复制到源码根目录）
├── env.m4                 # m4 环境变量
├── cfg/
│   ├── opensips_proxy.cfg.m4   # 主配置模板
│   ├── local.cfg.m4            # 本机配置模板
│   ├── ha.cfg.m4               # HA 模式模板
│   └── cluster/
│       ├── node_a.cfg.m4       # 节点 A 拓扑
│       └── node_b.cfg.m4       # 节点 B 拓扑
├── scripts/
│   ├── build.sh          # 编译脚本
│   ├── deploy.sh         # 一键部署脚本
│   └── sync-to-peer.sh   # 节点间配置同步
├── systemd/
│   └── opensips-gb28181.service  # systemd 服务单元
└── keepalived/
    ├── keepalived.conf.node_a   # 节点 A Keepalived 配置
    ├── keepalived.conf.node_b   # 节点 B Keepalived 配置
    ├── notify.sh                # VIP 状态变更通知脚本
    └── chk_opensips.sh          # 健康检查脚本
```

---

## 编译

```bash
cd /root/work/zf2zf/opensips/opensips
./deploy/scripts/build.sh clean
./deploy/scripts/build.sh build
./deploy/scripts/build.sh install
```

`build.sh` 会自动复制 `deploy/Makefile.conf` 到源码根目录，执行 `make config` 和 `make -j$(nproc)`，最后 `make install`。

---

## 单机部署

### 部署

```bash
./deploy/scripts/deploy.sh single -l 20.20.136.66 -u 1.2.3.4:5060
```

### 启动服务

```bash
/opt/zfnproxy/opensips/sbin/opensips -f /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg
```

### 安装 systemd 服务

```bash
cp deploy/systemd/opensips-gb28181.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable opensips-gb28181
systemctl start opensips-gb28181
```

---

## 集群部署

### 部署节点 A

```bash
./deploy/scripts/deploy.sh node_a -l 20.20.136.66 -p 20.20.136.67 -v 20.20.136.100 -u 1.2.3.4:5060
```

### 部署节点 B

```bash
./deploy/scripts/deploy.sh node_b -l 20.20.136.67 -p 20.20.136.66 -v 20.20.136.100 -u 1.2.3.4:5060
```

### 启动服务

```bash
/opt/zfnproxy/opensips/sbin/opensips -f /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg
```

### 安装 systemd 服务

```bash
cp deploy/systemd/opensips-gb28181.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable opensips-gb28181
systemctl start opensips-gb28181
```

### Keepalived HA

#### 节点 A（MASTER）

```bash
cp deploy/keepalived/keepalived.conf.node_a /etc/keepalived/keepalived.conf
cp deploy/keepalived/notify.sh /opt/zfnproxy/opensips/etc/keepalived/
cp deploy/keepalived/chk_opensips.sh /opt/zfnproxy/opensips/etc/keepalived/
chmod +x /opt/zfnproxy/opensips/etc/keepalived/*.sh

systemctl enable keepalived
systemctl start keepalived
```

#### 节点 B（BACKUP）

```bash
cp deploy/keepalived/keepalived.conf.node_b /etc/keepalived/keepalived.conf
# notify.sh 和 chk_opensips.sh 同节点 A
```

> 注意：`keepalived.conf.node_*` 中的 `VIP` 占位符需替换为实际虚拟 IP 地址后再部署。

### 节点间同步

将本地配置同步到对等节点：

```bash
./deploy/scripts/sync-to-peer.sh
```

前提：对端节点已部署且可通过 SSH 访问。

### 集群节点无法通信

确认防火墙开放了 UDP 端口 5566：
```bash
ufw allow 5566/udp
```

---

## 配置验证

### 语法检查

```bash
/opt/zfnproxy/opensips/sbin/opensips -f /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg -c
```

期望输出：`config file ok, exiting...`

### 查看日志

```bash
tail -f /var/log/syslog | grep opensips
```

---

## 常见问题

### 编译失败

确保已安装依赖：
```bash
apt install gcc make libssl-dev libsqlite3-dev flex bison
```

### 端口占用

检查 5060、5566 端口是否被占用：
```bash
netstat -ulnp | grep -E '5060|5566'
```

### 服务启动失败

```bash
# 检查日志
journalctl -u opensips-gb28181 -n 50

# 手动前台运行查看输出
/opt/zfnproxy/opensips/sbin/opensips -D -f /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg
```

### Keepalived VIP 未生效

```bash
# 检查 VRRP 状态
ip addr show | grep VIP
systemctl status keepalived

# 查看日志
journalctl -u keepalived -n 50
```

---

## 架构说明

本项目基于 OpenSIPS 实现 GB28181 视频平台的 SIP 信令代理：

- **单机模式**：单节点部署，适合小规模设备接入
- **集群模式**：双节点热备，通过 Keepalived 实现 VIP 漂移，保证高可用
- **数据存储**：使用 SQLite 存储设备注册信息和位置数据
- **信令处理**：支持设备注册、心跳保活、目录查询（Catalog）、设备信息查询等 GB28181 规定流程

---

## deploy.sh 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-l, --local-ip` | 本机 IP | - |
| `-p, --peer-ip` | 集群对端 IP | - |
| `-v, --vip` | 虚拟 IP | 等于 local-ip |
| `-s, --socket-port` | SIP 监听端口 | 5060 |
| `-b, --bin-port` | BIN 监听端口 | 5566 |
| `-u, --upstream` | 上游地址，格式 IP:PORT | 等于 peer-ip:socket-port |

---

## 附录：模块文档索引

| 模块 | 说明 | 文档 |
|------|------|------|
| aaa_diameter | 此模块提供 RFC 6733 Diameter 对等实现，能够充当 Diameter 客户端或服务器，或两者兼而有之。 | [README](modules/aaa_diameter/README.md) |
| aaa_radius | 此模块为核心中的 AAA API 提供 Radius 实现。 | [README](modules/aaa_radius/README.md) |
| acc | ACC 模块用于将事务信息记费到不同的后端，如 syslog、SQL、AAA。 | [README](modules/acc/README.md) |
| aka_av_diameter | 此模块是 *AKA_AUTH* 模块的扩展，提供 Diameter AKA AV Manager，实现了 *Cx* 接口的 *ETSI TS 129 229* 规范中定义的多媒体认证请求和多媒体认证答案 Diameter 命令，以获取一组认证向量并将其馈送到 AKA 认证过程。 | [README](modules/aka_av_diameter/README.md) |
| alias_db | ALIAS_DB 模块可用作用户别名的替代方案，通过 usrloc 实现。其主要特点是不会像用户位置那样存储所有相关数据，并且始终使用数据库进行搜索（无内存缓存）。 | [README](modules/alias_db/README.md) |
| auth_aaa | 此模块包含用于执行摘要认证和针对 AAA 服务器进行某些 URI 检查的函数。为了执行认证，代理将把凭据传递给 AAA 服务器，然后 AAA 服务器将发送包含认证结果的回复。 | [README](modules/auth_aaa/README.md) |
| auth_aka | 此模块包含用于使用 AKA（认证和密钥协商）安全协议执行摘要认证的函数。该机制在 IMS 网络中使用，用于在 UE（设备）和 3G/4G/5G 网络之间提供双向认证。 | [README](modules/auth_aka/README.md) |
| auth_db | 此模块包含所有需要访问数据库的认证相关函数。此模块应与 auth 模块一起使用，不能独立使用，因为它依赖于该模块。如果要使用数据库存储认证信息（如订户用户名和密码），请选择此模块。 | [README](modules/auth_db/README.md) |
| auth_jwt | 该模块实现基于 JSON Web Tokens 的认证。在某些情况下（即 WebRTC），用户在另一层（而不是 SIP）进行认证，因此在 SIP 层重复认证没有意义。 | [README](modules/auth_jwt/README.md) |
| auth_web3 | Web3 Auth 模块 | [README](modules/auth_web3/README.md) |
| auth | 这是一个提供其他认证相关模块所需通用函数的模块。此外，它还可以从伪变量中获取用户名和密码进行认证。 | [README](modules/auth/README.md) |
| b2b_entities | OpenSIPS 中的 B2BUA 实现分为两层：下层（在此模块中实现）实现了 UAS 和 UAC 的基本功能；上层 - 代表 B2BUA 的逻辑引擎，负责使用下层提供的功能实际实现 B2BUA 服务。 | [README](modules/b2b_entities/README.md) |
| b2b_logic | OpenSIPS 中的 B2BUA 实现分为两层：下层（在 b2b_entities 模块中实现）- UAS 和 UAC 的基本功能；上层（在 b2b_logic 模块中实现）- 代表 B2BUA 的逻辑引擎，负责使用下层提供的功能实际实现 B2BUA 服务。 | [README](modules/b2b_logic/README.md) |
| b2b_sca | 此模块为 OpenSIPS 提供核心 SCA（Shared Call Appearance，共享呼叫外观）功能。它旨在与 presence_callinfo 模块协同工作。 | [README](modules/b2b_sca/README.md) |
| b2b_sdp_demux | 此模块提供将多流 SDP 呼叫转换为多个呼叫的逻辑，每个呼叫包含初始呼叫中流的子集。该模块仅处理呼叫的 SIP 信令部分，不干扰呼叫的媒体，媒体将端到端流动。它唯一做的操作是在 SDP 层面禁用下游未使用的媒体流。 | [README](modules/b2b_sdp_demux/README.md) |
| benchmark | 此模块帮助开发人员对模块函数进行基准测试。通过通过配置文件或其 API 添加此模块的函数，OpenSIPS 可以为每个函数记录性能分析信息。 | [README](modules/benchmark/README.md) |
| cachedb_cassandra | 本模块是缓存系统的实现，旨在与 Cassandra 服务器配合工作。它使用了 OpenSIPS 核心导出的 Key-Value 接口。 | [README](modules/cachedb_cassandra/README.md) |
| cachedb_couchbase | 本模块是缓存系统的实现，旨在与 Couchbase 服务器配合工作。它使用 libcouchbase 客户端库连接到服务器实例。它使用了 OpenSIPS 核心导出的 Key-Value 接口。 | [README](modules/cachedb_couchbase/README.md) |
| cachedb_dynamodb | 本模块是与 Amazon DynamoDB 配合工作的缓存系统实现。它使用 AWS SDK for C++ 库连接到 DynamoDB 实例。它利用 OpenSIPS 核心导出的 Key-Value 接口。 | [README](modules/cachedb_dynamodb/README.md) |
| cachedb_local | 本模块是作为哈希表实现的本地缓存系统。它使用了 OpenSIPS 核心导出的 Key-Value 接口。从版本 2.3 开始，该模块可以有多个哈希表，称为集合。cachedb_local 模块的每个 URL 指向一个集合。 | [README](modules/cachedb_local/README.md) |
| cachedb_memcached | 本模块是缓存系统的实现，旨在与 memcached 服务器配合工作。它使用 libmemcached 客户端库连接到多个存储数据的 memcached 服务器。它使用了 OpenSIPS 核心导出的 Key-Value 接口。 | [README](modules/cachedb_memcached/README.md) |
| cachedb_mongodb | 本模块是缓存系统的实现，旨在与 MongoDB 服务器配合工作。它实现了 OpenSIPS 核心公开的 Key-Value 接口。 | [README](modules/cachedb_mongodb/README.md) |
| cachedb_redis | 本模块是缓存系统的实现，旨在与 Redis 服务器配合工作。它使用 hiredis 客户端库连接到单个 Redis 服务器实例或 Redis 集群中的 Redis 服务器。它使用了 OpenSIPS 核心导出的 Key-Value 接口。 | [README](modules/cachedb_redis/README.md) |
| cachedb_sql | 本模块是缓存系统的实现，旨在与常规基于 SQL 的服务器配合工作。它使用内部 DB 接口连接到后端，并实现了 OpenSIPS 核心导出的 Key-Value 接口。 | [README](modules/cachedb_sql/README.md) |
| call_center | 呼叫中心模块实现了一个呼入呼叫中心系统，具有呼叫流程（用于对接收的呼叫进行排队）和坐席（用于接听呼叫）。 | [README](modules/call_center/README.md) |
| call_control | 此模块允许限制呼叫的持续时间并在呼叫超过设定限制时自动结束它们。它的主要用例是实现预付费系统，但也可用于对代理处理的所有呼叫施加全局限制。 | [README](modules/call_control/README.md) |
| callops | 此模块提供一组允许用户控制正在进行的呼叫的函数。它可用于触发呼叫（盲转或 attended 转）转移，或从代理端而非终端设备端将呼叫置于保持状态。该模块绑定在 OpenSIPS Dialog 模块之上以获取有关正在进行的呼叫的信息，以及存储有关将启动的新呼叫的信息。 | [README](modules/callops/README.md) |
| carrierroute | 提供路由、负载均衡和黑名单功能的模块。 | [README](modules/carrierroute/README.md) |
| cfgutils | 服务器配置的有用扩展。 | [README](modules/cfgutils/README.md) |
| cgrates | *CGRateS* 是一个开源的计费引擎，用于运营商级的多租户实时计费。它能够对具有不同余额单位（如货币、短信、网络流量）的多个并发会话进行后付费和预付费计费。 | [README](modules/cgrates/README.md) |
| clusterer | *clusterer* 模块用于将多个 OpenSIPS 实例组织成组（集群），集群中的节点可以相互通信以复制、共享信息或执行分布式任务。分布式逻辑由使用 *clusterer* 接口的不同模块执行（即 *dialog* 模块可以复制对话框/概要，*ratelimit* 模块可以跨多个实例共享管道等），或在脚本级别执行。*clusterer* 模块本身仅提供发送/接收 BIN 数据包的接口以及获取节点可用性通知。 | [README](modules/clusterer/README.md) |
| compression | 该模块使用 deflate 和 gzip 算法/头实现 SIP 消息的压缩/解压缩和 base64 编码。该模块的另一个功能是根据 SIP RFC 规范将头压缩为紧凑形式，移除 SDP body codec 中不必要的描述（对于 0-97 编解码器），以及用于不被移除的头部的白名单。 | [README](modules/compression/README.md) |
| config | *config* 模块通过在启动时从持久存储加载配置参数并在脚本级别通过伪变量公开，从而实现 OpenSIPS 参数的动态运行时配置。 | [README](modules/config/README.md) |
| cpl_c | cpl_c 模块实现了一个 CPL（Call Processing Language，呼叫处理语言）解释器。支持通过 SIP REGISTER 方法上传/下载/删除脚本。 | [README](modules/cpl_c/README.md) |
| db_berkeley | 这是一个将 Berkeley DB 集成到 OpenSIPS 的模块。它实现了 OpenSIPS 中定义的 DB API。 | [README](modules/db_berkeley/README.md) |
| db_cachedb | db_cachedb 模块 | [README](modules/db_cachedb/README.md) |
| db_flatstore | Flatstore 是所谓的 OpenSIPS 数据库模块之一。它不导出任何可从配置脚本执行的函数，但它导出了数据库 API 的一个子集，因此其他模块可以使用它来替代，例如 mysql 模块。 | [README](modules/db_flatstore/README.md) |
| db_http | 该模块提供对实现为 HTTP 服务器的数据库的访问。当穿越防火墙成为问题或需要数据加密时，可使用此模块。 | [README](modules/db_http/README.md) |
| db_mysql | 这是一个为 OpenSIPS 提供 MySQL 连接功能的模块。它实现了 OpenSIPS 中定义的 DB API。 | [README](modules/db_mysql/README.md) |
| db_oracle | 这是一个为 OpenSIPS 提供 Oracle 连接功能的模块。它实现了 OpenSIPS 中定义的 DB API。 | [README](modules/db_oracle/README.md) |
| db_perlvdb | Perl 虚拟数据库（VDB）为 OpenSIPS 的数据库访问提供了一个虚拟化框架。它本身不处理特定的数据库引擎，而是让用户将数据库请求中继到任意 Perl 函数。 | [README](modules/db_perlvdb/README.md) |
| db_postgres | 模块描述 | [README](modules/db_postgres/README.md) |
| db_sqlite | 这是为 OpenSIPS 提供 SQLite 支持的模块。它实现了 OpenSIPS 中定义的 DB API。 | [README](modules/db_sqlite/README.md) |
| db_text | 该模块实现了一个基于文本文件的简化数据库引擎。它可以用于 OpenSIPS DB 接口来替代其他数据库模块（如 MySQL）。 | [README](modules/db_text/README.md) |
| db_unixodbc | 此模块允许在 OpenSIPS 中使用 unixodbc 包。它已使用 mysql 和 odbc 连接器进行了测试，但应该也适用于其他数据库。auth_db 模块可以工作。 | [README](modules/db_unixodbc/README.md) |
| db_virtual | db_virtual 模块 | [README](modules/db_virtual/README.md) |
| dialog | dialog 模块为 OpenSIPS 代理提供对话感知功能。其功能是跟踪当前对话，提供关于对话的信息(如当前有多少活跃对话)。 | [README](modules/dialog/README.md) |
| dialplan | 此模块实现基于匹配和替换规则的通用字符串转换。它可用于操作 R-URI 或 PV 并转换为新的格式/值。 | [README](modules/dialplan/README.md) |
| dispatcher | 此模块实现目标地址的调度器。它对请求的各个部分计算哈希值，并从目标集中选择一个地址。所选地址可以覆盖 SIP 请求的 R-URI 或用作出站代理。 | [README](modules/dispatcher/README.md) |
| diversion | 该模块实现了 draft-levy-sip-diversion-08 中规定的 Diversion 扩展。Diversion 扩展在各种呼叫转发场景中很有用。 | [README](modules/diversion/README.md) |
| dns_cache | 该模块是专为 DNS 记录设计的缓存系统的实现。对于所有类型的成功 DNS 查询，模块将在缓存/数据库后端存储映射，有效期为 DNS 回答中收到的 TTL 秒数。 | [README](modules/dns_cache/README.md) |
| domain | Domain 模块实现检查功能，基于 domain 表确定 URI 的主机部分是否是"本地的"。"本地"域名是代理服务器负责的域名。 | [README](modules/domain/README.md) |
| domainpolicy | Domain Policy 模块实现了 draft-lendl-domain-policy-ddds-02 以及 draft-lendl-speermint-federations-02 和 draft-lendl-speermint-technical-policy-00 的组合。这些草案定义了 DNS 记录，域可以通过它公布其联盟成员身份。 | [README](modules/domainpolicy/README.md) |
| drouting | drouting 模块提供动态路由功能，用于根据可配置的目标模式匹配将呼叫路由到不同的目的地。 | [README](modules/drouting/README.md) |
| emergency | 紧急呼叫模块为 OpenSIPS 提供紧急呼叫处理功能，遵循美国 NENA（National Emergency Number Association，国家紧急号码协会）的 i2 架构规范。 | [README](modules/emergency/README.md) |
| enum | Enum 模块实现了 [i_]enum_query 函数，该函数基于当前 Request-URI 的用户部分执行 enum 查询。这些函数假定用户部分由 +十进制数字形式的国际电话号码组成。 | [README](modules/enum/README.md) |
| event_datagram | 这是为 Event Interface 提供 UNIX/UDP SOCKET 传输层实现的模块。 | [README](modules/event_datagram/README.md) |
| event_flatstore | *event_flatstore* 模块提供了一种日志记录功能，用于记录通过 OpenSIPS Event Interface 从 OpenSIPS 脚本触发的不同事件。该模块将事件及其参数以纯文本文件形式记录。 | [README](modules/event_flatstore/README.md) |
| event_kafka | 此模块实现了一个事件接口消费者，可将 OpenSIPS 事件发布到 Kafka 消息队列。 | [README](modules/event_kafka/README.md) |
| event_rabbitmq | *RabbitMQ* 是一个开源消息服务器。其目的是通过灵活的 AMQP 协议管理队列中收到的消息。 | [README](modules/event_rabbitmq/README.md) |
| event_routing | 基于事件的路由模块（或简称 EBR 模块）提供了一种机制，允许通过 OpenSIPS Events 实现脚本中不同 SIP 处理之间的通信和同步。 | [README](modules/event_routing/README.md) |
| event_sqs | event_sqs 模块是 Amazon SQS 生产者的实现。它作为 Event Interface 的传输后端，同时也提供了一个独立连接器，可从 OpenSIPS 脚本中使用以向 SQS 队列发布消息。 | [README](modules/event_sqs/README.md) |
| event_stream | 此模块为 Event Interface 提供 TCP 传输层实现。该模块可以发送 JSON-RPC 通知或标准请求并等待响应。 | [README](modules/event_stream/README.md) |
| event_virtual | *event_virtual* 模块提供了将多个使用不同传输协议的外部应用程序作为单个虚拟订阅者订阅到 OpenSIPS Event Interface 的功能，用于特定事件。当事件被触发时，event_virtual 模块通知指定的传输模块。 | [README](modules/event_virtual/README.md) |
| event_xmlrpc | 此模块是 XMLRPC 客户端的实现，用于在 OpenSIPS 引发某些通知时通知 XMLRPC 服务器。它充当 Event Notification Interface 的传输层。 | [README](modules/event_xmlrpc/README.md) |
| example | 本模块作为如何在 OpenSIPS 中编写模块的示例。其主要目的是简化新模块的开发，为新手提供清晰易懂的起点。 | [README](modules/example/README.md) |
| exec | Exec 模块支持从 OpenSIPS 脚本执行外部命令。接受任何有效的 shell 命令。最终输入字符串通过 "/bin/sh" 符号链接/二进制进行评估和执行。 | [README](modules/exec/README.md) |
| fraud_detection | 本模块提供了一种防止某些基本欺诈攻击的方法。警报通过返回码和事件提供。 | [README](modules/fraud_detection/README.md) |
| freeswitch | *\"freeswitch\"* 模块是 FreeSWITCH Event Socket Layer 接口的 C 驱动程序。它可以通过向 FreeSWITCH 服务器发送命令或从其接收事件来与一个或多个 FreeSWITCH 服务器交互。 | [README](modules/freeswitch/README.md) |
| freeswitch_scripting | *freeswitch_scripting* 是一个辅助模块，将 FreeSWITCH ESL 接口的完全控制权暴露给 OpenSIPS 脚本。 | [README](modules/freeswitch_scripting/README.md) |
| gflags | gflags 模块（全局标志）在共享内存中维护一个位图，可用于根据标志的值更改服务器行为。 | [README](modules/gflags/README.md) |
| group | 本模块提供多种用户组成员资格检查功能。 | [README](modules/group/README.md) |
| h350 | OpenSIPS H350 模块使 OpenSIPS SIP 代理服务器能够访问存储在包含 H.350 commObjects 的 LDAP 目录中的 SIP 账户数据。 | [README](modules/h350/README.md) |
| http2d | 此模块提供了一个基于 **nghttp2** 库的 RFC 7540/9113 HTTP/2 服务器实现，支持 "h2" ALPN。 | [README](modules/http2d/README.md) |
| httpd | 本模块为 OpenSIPS 提供 HTTP 传输层。 | [README](modules/httpd/README.md) |
| identity | 此模块添加对 SIP Identity（参见 RFC 4474）的支持。 | [README](modules/identity/README.md) |
| imc | 此模块提供即时消息会议支持。它遵循 IRC 频道的架构。 | [README](modules/imc/README.md) |
| jabber | 这是集成 XODE XML 解析器用于解析 Jabber 消息的新版本 Jabber 模块。 | [README](modules/jabber/README.md) |
| janus | *\"janus\"* 模块是 Janus WebSocket 协议的 C 驱动程序。它可以通过向一个或多个 Janus 服务器发送命令或从它们接收事件来与它们交互。 | [README](modules/janus/README.md) |
| jsonrpc | 此模块是 JSON-RPC v2.0 客户端的实现，可以通过 TCP 连接向 JSON-RPC 服务器发送调用。 | [README](modules/jsonrpc/README.md) |
| json | 此模块引入了一种新型变量，提供 JSON 格式的序列化和反序列化功能。 | [README](modules/json/README.md) |
| launch_darkly | 此模块实现对 [Launch Darkly](https://launchdarkly.com/) 功能管理云的支持。该模块提供到云端的连接以及查询功能标志的能力。 | [README](modules/launch_darkly/README.md) |
| ldap | LDAP 模块为 OpenSIPS 实现了 LDAP 搜索接口。它导出脚本函数来执行 LDAP 搜索操作，并将搜索结果存储为 OpenSIPS AVP。 | [README](modules/ldap/README.md) |
| load_balancer | 负载均衡器模块提供基于负载的流量路由功能。简而言之，当 OpenSIPS 将呼叫路由到一组目标时，它能够跟踪每个目标的负载状态（当前通话数），并选择负载最轻的目标进行路由。 | [README](modules/load_balancer/README.md) |
| lua | 编写新的 OpenSIPS 模块所需的时间不幸地相当高，而配置文件提供的选项仅限于模块中实现的功能。 | [README](modules/lua/README.md) |
| mangler | 这是一个用于SDP mangling的模块。注意：此模块已弃用，将在1.5.0版本中移除。 | [README](modules/mangler/README.md) |
| mathops | mathops模块提供了一系列函数，使OpenSIPS脚本层面能够执行各种浮点运算。 | [README](modules/mathops/README.md) |
| maxfwd | 该模块实现了与 MaX-Forward 头字段相关的所有操作，如添加（如果不存在）或递减和检查现有值。 | [README](modules/maxfwd/README.md) |
| media_exchange | 此模块提供了在不同SIP代理呼叫以及从媒体服务器发起或接收的呼叫之间交换媒体SDP的方法。 | [README](modules/media_exchange/README.md) |
| mediaproxy | Mediaproxy是一个OpenSIPS模块，旨在为大多数现有SIP客户端提供自动NAT穿透。这意味着使用mediaproxy模块时，不需要在NAT设备上进行任何特殊配置即可让这些客户端在NAT后面正常工作。 | [README](modules/mediaproxy/README.md) |
| mi_datagram | 这是一个为管理接口提供UNIX/UDP SOCKET传输层实现的模块。 | [README](modules/mi_datagram/README.md) |
| mid_registrar | mid_registrar 是 SIP 平台的中间组件，设计位于最终用户与平台主注册组件之间。它开辟了利用现有基础设施持续增长的新可能性，同时保持一个现有的低资源 registrar 服务器。 | [README](modules/mid_registrar/README.md) |
| mi_fifo | 这是一个为管理接口提供 FIFO 传输层实现的模块。它通过 FIFO 文件接收命令，并通过指定的 reply_fifo 返回输出。 | [README](modules/mi_fifo/README.md) |
| mi_html | 此模块为OpenSIPS的管理接口提供了一个极简的Web用户界面。 | [README](modules/mi_html/README.md) |
| mi_http | 本模块为 OpenSIPS 的管理接口提供 HTTP 传输层实现。 | [README](modules/mi_http/README.md) |
| mi_script | 此模块提供了多个钩子，用于直接从OpenSIPS脚本运行管理接口命令。它支持运行同步和异步命令。 | [README](modules/mi_script/README.md) |
| mi_xmlrpc | 本模块实现了一个 xmlrpc 服务器，用于处理 xmlrpc 请求并生成 xmlrpc 响应。当收到 xmlrpc 消息时，将执行默认方法。 | [README](modules/mi_xmlrpc/README.md) |
| mmgeoip | 此模块是MaxMind GeoIP API的轻量级包装器。它为OpenSIPS脚本添加了IP地址到位置的查询功能。 | [README](modules/mmgeoip/README.md) |
| mqueue | mqueue模块在共享内存中提供了一个通用的消息队列系统，用于使用配置文件进行进程间通信。 | [README](modules/mqueue/README.md) |
| msilo | 此模块为Open SIP Server提供离线消息存储。它为离线用户存储接收到的消息，并在用户上线时发送。 | [README](modules/msilo/README.md) |
| msrp_gateway | 本模块实现了一个网关，用于在页面模式(SIP MESSAGE 方法)和会话模式(MSRP)即时消息之间进行转换。 | [README](modules/msrp_gateway/README.md) |
| msrp_relay | MSRP 中继模块提供 MSRP（会话发起协议请求通道）消息的中继功能，用于在 NAT 环境下中继 SIP 消息。 | [README](modules/msrp_relay/README.md) |
| msrp_ua | 本模块实现了一个用户代理，能够使用 MSRP(RFC 4976)协议建立消息会话。 | [README](modules/msrp_ua/README.md) |
| nathelper | 这是一个帮助 NAT 穿越的模块。特别地，它帮助那些没有宣告自己是对称 UA、无法确定自己公网地址的对称 UA。fix_nated_contact 使用请求的源地址:端口对重写 Contact 头字段。fix_nated_sdp 向 SDP 添加活动方向指示并更新源 IP 地址。 | [README](modules/nathelper/README.md) |
| nat_traversal | nat_traversal 模块提供处理 SIP 信令远端 NAT 穿越的支持。该模块包括检测 NAT 后面的用户代理、修改 SIP 头以使用户代理透明地在 NAT 后面工作以及向 NAT 后面的用户代理发送保活消息以保持其在网络中的可见性等功能。 | [README](modules/nat_traversal/README.md) |
| opentelemetry | *opentelemetry* 模块为 OpenSIPS 路由执行提供 OpenTelemetry 追踪。它为每个处理的 SIP 消息创建一个根跨度，为每个路由条目创建一个子跨度。 | [README](modules/opentelemetry/README.md) |
| options | 本模块提供一个函数来应答直接发送给服务器本身的 OPTIONS 请求。这意味着 OPTIONS 请求的请求 URI 中包含服务器地址，且 URI 中没有用户名。请求将以 200 OK 应答，其中包含服务器的功能。 | [README](modules/options/README.md) |
| osp | OSP 模块使 OpenSIPS 能够支持使用 ETSI 定义的 OSP 标准进行安全的多边对等。本模块将使您的 OpenSIPS 能够接收、路由和授权 SIP 呼叫。 | [README](modules/osp/README.md) |
| path | 本模块设计用于在注册商和代理前面的中间 sip 代理(如负载均衡器)中使用。它提供插入 Path 头的函数，包括用于将注册的 received-URI 转发到下一跳的参数。 | [README](modules/path/README.md) |
| peering | 对等模块允许 SIP 提供商(运营商或组织)从代理验证 SIP 请求的源或目标是否为可信对等方。 | [README](modules/peering/README.md) |
| perl | 编写新的 OpenSIPS 模块所需的时间非常高，而配置文件提供的选项仅限于模块中实现的功能。 | [README](modules/perl/README.md) |
| permissions | permissions Module | [README](modules/permissions/README.md) |
| pi_http | 此模块为 OpenSIPS 提供 HTTP 配置接口。它使用 OpenSIPS 的内部数据库 API 提供了一种操作 OpenSIPS 表中记录的简单方法。 | [README](modules/pi_http/README.md) |
| pike | 该模块提供了一种简单的 DOS 防护机制——基于网络层 flood 攻击的 DOS 防护。该模块跟踪所有（或选定的）传入 SIP 流量的 IP（作为源 IP），并阻止超过限制的 IP。 | [README](modules/pike/README.md) |
| presence_callinfo | 该模块为 OpenSIPS 提供共享呼叫外观（SCA）支持，如 BroadWorks SIP Access Side Extensions Interface 规范所定义。 | [README](modules/presence_callinfo/README.md) |
| presence_dfks | 该模块支持通过 presence 模块处理 "as-feature-event" 事件包（如 Broadsoft 的 Device Feature Key Synchronization 协议所定义）。这可用于在 SIP 端点上同步功能键。 | [README](modules/presence_dfks/README.md) |
| presence_dialoginfo | 该模块在 presence 模块内启用对 "Event: dialog"（RFC 4235 中定义）的处理。这可用于将 dialog-info 状态分发给订阅的 watchers。 | [README](modules/presence_dialoginfo/README.md) |
| presence_mwi | 该模块对 notify-subscribe message-summary（消息等待指示）事件进行特定处理，如 RFC 3842 中所规定。它与通用事件处理模块 presence 一起使用。 | [README](modules/presence_mwi/README.md) |
| presence_reginfo | 该模块支持在 presence 模块中处理 "Event: reg"（如 RFC 3680 中所定义）。这可用于将注册信息状态分发给订阅的 watcher。 | [README](modules/presence_reginfo/README.md) |
| presence_xcapdiff | presence_xcapdiff 是一个 OpenSIPS 模块，它为 presence 和 pua 添加了对 "xcap-diff" 事件的支持。目前，该模块只是注册事件，不进行任何特定于事件的处理。 | [README](modules/presence_xcapdiff/README.md) |
| presence_xml | 该模块对使用 xml body 的 notify-subscribe 事件进行特定处理。它与通用事件处理模块 presence 一起使用。它向其中构造并添加 3 个事件：presence、presence.winfo、dialog;sla。 | [README](modules/presence_xml/README.md) |
| presence | 该模块处理 PUBLISH 和 SUBSCRIBE 消息，并以通用的、事件无关的方式生成 NOTIFY 消息。它允许从其他 OpenSIPS 模块注册事件。 | [README](modules/presence/README.md) |
| prometheus | 此模块为 [Prometheus](https://prometheus.io/) 监控系统提供 HTTP 接口，允许其从 OpenSIPS 获取各种统计数据。 | [README](modules/prometheus/README.md) |
| proto_bin | **proto_bin** 模块是一个传输模块，实现了基于 TCP 的 Binary Interface 通信。它不处理 TCP 连接管理，只是提供高级原语来通过 TCP 读取和写入 BIN 消息。 | [README](modules/proto_bin/README.md) |
| proto_bins | 该模块实现了通过 TLS 的安全 Binary 通信协议，供 clusterer 模块提供的 OpenSIPS 集群引擎使用。 | [README](modules/proto_bins/README.md) |
| proto_hep | **proto_hep** 模块是一个传输模块，实现了 hepV1 和 hepV2 基于 UDP 的通信以及 hepV3 基于 TCP 的通信。 | [README](modules/proto_hep/README.md) |
| proto_ipsec | **proto_ipsec** 模块提供用于建立安全通信通道的 IPSec 套接字。它依赖 RFC 3329 来建立创建动态安全关联(SA)所需的 IPSec 参数，用于每个连接。 | [README](modules/proto_ipsec/README.md) |
| proto_msrp | **proto_msrp** 模块提供 MSRP 协议栈，即网络读/写(明文和 TLS)、消息解析和组装、事务层以及基本信令操作。 | [README](modules/proto_msrp/README.md) |
| proto_sctp | **proto_sctp** 模块是一个可选的传输模块，导出处理基于 SCTP 通信所需的逻辑。 | [README](modules/proto_sctp/README.md) |
| proto_smpp | 该模块提供 SIP 和 SMPP(Short Message Peer-to-Peer)协议之间的互操作性。它提供了在这两个协议之间构建消息网关/桥接的方法。 | [README](modules/proto_smpp/README.md) |
| proto_tls | TLS，如 SIP RFC 3261 所定义，是代理的必备功能，可用于保护逐跳(非端到端)的 SIP 信令。TLS 在 TCP 之上工作。 | [README](modules/proto_tls/README.md) |
| proto_ws | WebSocket 协议在两个基于 Web 的应用程序之间提供端到端全双工通信通道。这允许支持 WebSocket 的浏览器连接到 WebSocket 服务器并交换任何类型的数据。 | [README](modules/proto_ws/README.md) |
| proto_wss | WSS(Secure WebSocket)模块提供了通过安全(TLS 加密)通道与 WebSocket 客户端或服务器通信的能力。 | [README](modules/proto_wss/README.md) |
| pua | 本模块为 OpenSIPS 提供内部支持，使其能够作为 Presence User Agent（呈现代理）客户端使用，通过发送 Subscribe 和 Publish 消息。 | [README](modules/pua/README.md) |
| pua_bla | pua_bla 模块根据 draft-anil-sipping-bla-03.txt 规范提供桥接线外观（Bridged Line Appearances）支持。 | [README](modules/pua_bla/README.md) |
| pua_dialoginfo | pua_dialoginfo 从 dialog 模块检索 dialog 状态信息，并使用 pua 模块 PUBLISH 对话信息。 | [README](modules/pua_dialoginfo/README.md) |
| pua_mi | pua_mi 提供通过 MI 传输发布和订阅 presence 信息的功能。 | [README](modules/pua_mi/README.md) |
| pua_reginfo | 本模块根据 RFC 3680 发布关于"reg"事件的信息。这可用于将注册信息状态分发给订阅的 watchers。 | [README](modules/pua_reginfo/README.md) |
| pua_usrloc | pua_usrloc 是 usrloc 和 pua 模块之间的连接器。它创建环境以便在特定事件发生时为用户位置记录发送 PUBLISH 请求。 | [README](modules/pua_usrloc/README.md) |
| pua_xmpp | 此模块是 SIP 和 XMPP 之间的 presence 网关。 | [README](modules/pua_xmpp/README.md) |
| python | 此模块可用于直接从 OpenSIPS 脚本高效运行 Python 代码，而无需执行 *python* 解释器。 | [README](modules/python/README.md) |
| qos | qos 模块提供了一种跟踪每个对话 SDP 会话的方法。 | [README](modules/qos/README.md) |
| qrouting | *qrouting* 是一个构建在 drouting、dialog 和 tm 之上的模块，用于实时跟踪一系列重要的网关信令质量指标。 | [README](modules/qrouting/README.md) |
| rabbitmq_consumer | *RabbitMQ Consumer* 是一个开源消息服务器。其目的是管理队列中接收到的消息，利用灵活的 AMQP 协议。 | [README](modules/rabbitmq_consumer/README.md) |
| rate_cacher | *rate_cacher* 模块提供了一种缓存和实时查询分配给客户和/或供应商的费率表的方法。 | [README](modules/rate_cacher/README.md) |
| ratelimit | 此模块实现 SIP 请求的速率限制。与 PIKE 模块不同，它基于每个 SIP 请求类型而不是每个源 IP 进行流量限制。 | [README](modules/ratelimit/README.md) |
| regex | 此模块使用强大的 PCRE 库提供正则表达式匹配操作。 | [README](modules/regex/README.md) |
| registrar | registrar 模块包含 SIP REGISTER 请求处理逻辑，按照 RFC 3261 标准。在此基础上，还提供了多个扩展功能。 | [README](modules/registrar/README.md) |
| rest_client | *rest_client* 模块提供了与 HTTP 服务器交互的方式，通过执行 RESTful 查询（如 GET、POST 和 PUT）来与 HTTP 服务器进行交互。 | [README](modules/rest_client/README.md) |
| rls | 该模块是 RFC 4662 和 RFC 4826 规范的资源列表服务器实现。 | [README](modules/rls/README.md) |
| rr | 该模块包含记录路由逻辑 | [README](modules/rr/README.md) |
| rtpengine | 这是一个通过 RTP 代理代理媒体流的模块。rtpengine 模块是原始 rtpproxy 模块的修改版本，使用了新的控制协议。 | [README](modules/rtpengine/README.md) |
| rtp.io | RTP.io 模块提供了在 OpenSIPS 内部处理 RTP 流量的集成解决方案，支持直接在 OpenSIPS 进程中进行 RTP 中继和处理。 | [README](modules/rtp.io/README.md) |
| rtpproxy | 此模块用于 OpenSIPS 与 RTPProxy 通信，RTPProxy 是一个媒体中继代理，用于使 NAT 背后的用户代理之间的通信成为可能。 | [README](modules/rtpproxy/README.md) |
| rtp_relay | 此模块的目的是简化在 OpenSIPS 脚本中使用不同 RTP 中继服务器（如 RTPProxy、RTPEngine、Media Proxy）的操作，并提供依赖于 RTP 中继使用的各种复杂功能。 | [README](modules/rtp_relay/README.md) |
| script_helper | **脚本助手模块**的目的是简化在 OpenSIPS 中进行基本场景时的脚本编写过程。 | [README](modules/script_helper/README.md) |
| signaling | SIGNALING 模块作为 tm 和 sl 模块的包装器，提供一个由想要发送回复的模块调用的函数。 | [README](modules/signaling/README.md) |
| sipcapture | 提供将传入/传出的 SIP 消息存储到数据库的功能。 | [README](modules/sipcapture/README.md) |
| sip_i | 该模块提供处理封装在 SIP 中的 ISDN 用户部分(ISUP)消息的功能。可用的操作包括：从 ISUP 消息中读取和修改参数、删除或添加新的可选参数。 | [README](modules/sip_i/README.md) |
| sipmsgops | 该模块实现了对 OpenSIPS 处理的消息进行基于 SIP 的操作。SIP 是一个基于文本的协议，该模块提供了一组非常有用的函数来在 SIP 级别操作消息。 | [README](modules/sipmsgops/README.md) |
| siprec | 该模块提供了使用外部录音设备进行通话录音的手段——录音实体不在通话双方之间的媒体路径中，而是完全独立的，因此不会以任何方式影响通话质量。 | [README](modules/siprec/README.md) |
| sl | SL 模块允许 OpenSIPS 作为无状态 UA 服务器生成对 SIP 请求的回复而不保持状态。这在许多场景中是有益的。 | [README](modules/sl/README.md) |
| sngtc | **Sangoma 转码模块** 提供了使用 Sangoma 制造的 D 系列转码卡执行语音转码的可能性。 | [README](modules/sngtc/README.md) |
| snmpstats | SNMPStats 模块提供到 OpenSIPS 的 SNMP 管理接口。具体来说，它提供通用的 SNMP 可查询标量统计、更复杂数据（如用户和联系人信息）的表表示，以及告警监控功能。 | [README](modules/snmpstats/README.md) |
| sockets_mgm | 该模块提供了在运行时为 OpenSIPS 配置和管理动态套接字的方法。套接字的定义存储在 SQL 数据库中，可以在运行时动态更改。 | [README](modules/sockets_mgm/README.md) |
| speeddial | 此模块提供服务器端快速拨号功能。用户可以将由短号码（2位数字）和 SIP 地址组成的记录存储到 OpenSIPS 的表中。 | [README](modules/speeddial/README.md) |
| sql_cacher | sql_cacher 模块引入了将数据从基于 SQL 的数据库缓存到通过 CacheDB Interface 在 OpenSIPS 中实现的缓存系统中的可能性。 | [README](modules/sql_cacher/README.md) |
| sqlops | SQLops（SQL-operations）模块实现了一组用于通用 SQL 标准查询（原始查询或结构化查询）的脚本函数。 | [README](modules/sqlops/README.md) |
| sst | sst 模块提供了一种根据 SIP INVITE/200 OK Session-Expires 头值更新对话过期计时器的方法。 | [README](modules/sst/README.md) |
| statistics | 统计模块是内部统计管理器的包装器，允许脚本编写者动态定义和使用统计变量。 | [README](modules/statistics/README.md) |
| status_report | 状态/报告模块是内部状态/报告框架的包装器，允许脚本编写者动态定义和使用 SR 组。 | [README](modules/status_report/README.md) |
| stir_shaken | 此模块为 OpenSIPS 添加了实现 STIR/SHAKEN（RFC 8224、RFC 8588）认证和验证服务的支持。 | [README](modules/stir_shaken/README.md) |
| stun | STUN 模块 | [README](modules/stun/README.md) |
| tcp_mgm | 此模块提供可选的、基于 SQL 的支持，用于对 OpenSIPS 上发生的所有 TCP 连接进行细粒度管理。 | [README](modules/tcp_mgm/README.md) |
| test |  | [README](modules/test/README.md) |
| textops | 该模块实现对 OpenSIPS 处理的 SIP 消息的基于文本的操作。SIP 是一个基于文本的协议，该模块提供了一组丰富的非常有用的函数来在文本级别上操作消息。 | [README](modules/textops/README.md) |
| tls_mgm | TLS_MGM 模块是 TLS 证书和参数的管理模块。它为所有使用 TLS 协议的模块提供接口。 | [README](modules/tls_mgm/README.md) |
| tls_openssl | 此模块使用 openSSL 库实现 TLS 操作。它提供 *tls_mgm* 模块所需的原语。 | [README](modules/tls_openssl/README.md) |
| tls_wolfssl | 此模块使用 wolfSSL 库实现 TLS 操作。它提供 *tls_mgm* 模块所需的原语。 | [README](modules/tls_wolfssl/README.md) |
| tm | TM 模块启用 SIP 事务的有状态处理。有状态逻辑的主要用途（代价高昂的内存和 CPU）是某些服务本身需要状态。例如，基于事务的计费（acc 模块）需要处理事务状态而不是单个消息，任何类型的分叉都必须以有状态方式实现。 | [README](modules/tm/README.md) |
| topology_hiding | 这是一个提供拓扑隐藏功能的模块。该模块可以在 dialog 模块之上工作，也可以作为独立模块工作。 | [README](modules/topology_hiding/README.md) |
| tracer | 提供将传入/传出的 SIP 消息存储在数据库中的可能性。自 2.2 版本起，需要加载 proto_hep 模块才能进行 hep 复制。 | [README](modules/tracer/README.md) |
| trie | Trie 模块 | [README](modules/trie/README.md) |
| uac | UAC（User Agent Client，用户代理客户端）模块提供一些基本的 UAC 功能，如 FROM/TO 头域 manipulation（匿名化）或客户端认证。 | [README](modules/uac/README.md) |
| uac_auth | UAC AUTH（用户代理客户端认证）模块提供构建认证头的通用 API。 | [README](modules/uac_auth/README.md) |
| uac_redirect | UAC REDIRECT - 用户代理客户端重定向 - 模块增强了 OpenSIPS 处理（解释、过滤、记录和跟随）重定向响应（3xx 回复类）的功能。 | [README](modules/uac_redirect/README.md) |
| uac_registrant | 该模块使 OpenSIPS 能够在远程 SIP registrar 上注册自己。 | [README](modules/uac_registrant/README.md) |
| userblacklist | userblacklist 模块允许 OpenSIPS 按用户处理黑名单。此信息存储在数据库表中，通过查询该表来决定号码是否在黑名单上。 | [README](modules/userblacklist/README.md) |
| usrloc | SIP 用户位置实现。其主要目的是为其他模块(例如 registrar、mid-registrar、nathelper 等)存储、管理和提供 SIP 注册绑定(contact)的访问。该模块不导出可从 OpenSIPS 脚本直接使用的函数。 | [README](modules/usrloc/README.md) |
| uuid | 此模块提供了一种生成通用唯一标识符（UUID）的方法，如 RFC 4122 中所指定。 | [README](modules/uuid/README.md) |
| xcap | 该模块包含多个参数和函数，可供所有使用 XCAP 功能的模块共用。 | [README](modules/xcap/README.md) |
| xcap_client | 该模块是 OpenSIPS 的 XCAP 客户端，可供其他模块使用。它通过发送 HTTP GET 请求来获取 XCAP 元素。 | [README](modules/xcap_client/README.md) |
| xml | 该模块提供了一个脚本变量，可对 XML 文档或 XML 数据块进行基本的解析和操作。 | [README](modules/xml/README.md) |
| xmpp | 该模块是 OpenSIPS 与 jabber 服务器之间的网关。它支持 SIP 客户端和 XMPP(jabber) 客户端之间即时消息的交换。 | [README](modules/xmpp/README.md) |
