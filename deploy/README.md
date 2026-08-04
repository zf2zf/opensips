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

**单机模式（指定本机 IP）：**
```bash
./deploy/scripts/gen-cfg.sh single 192.168.1.100
/opt/zfnproxy/opensips/sbin/opensips -f /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg
```

**集群模式 - 节点 A：**
```bash
./deploy/scripts/gen-cfg.sh node_a 20.20.136.66 20.20.136.67 20.20.136.100 5060 5566
/opt/zfnproxy/opensips/sbin/opensips -f /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg
```

**集群模式 - 节点 B：**
```bash
./deploy/scripts/gen-cfg.sh node_b 20.20.136.67 20.20.136.66 20.20.136.100 5060 5566
/opt/zfnproxy/opensips/sbin/opensips -f /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg
```

---

## 目录结构

```
deploy/
├── Makefile.conf           # 编译模块配置（复制到源码根目录）
├── env.m4                 # m4 环境变量（gen-cfg.sh 自动生成）
├── cfg/
│   ├── opensips_proxy.cfg.m4   # 主配置模板
│   ├── local.cfg.m4            # 本机配置模板
│   ├── ha.cfg.m4               # HA 模式模板
│   └── cluster/
│       ├── node_a.cfg.m4       # 节点 A 拓扑
│       └── node_b.cfg.m4       # 节点 B 拓扑
├── scripts/
│   ├── build.sh          # 编译脚本
│   ├── gen-cfg.sh        # 配置生成脚本（m4 预处理）
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

### 编译

```bash
cd /root/work/zf2zf/opensips/opensips
./deploy/scripts/build.sh build
./deploy/scripts/build.sh install
```

`build.sh` 会自动复制 `deploy/Makefile.conf` 到源码根目录，执行 `make config` 和 `make -j$(nproc)`，最后 `make install`。

---

## 配置生成

`gen-cfg.sh` 使用 m4 预处理器生成最终配置。

### 用法

```bash
./deploy/scripts/gen-cfg.sh <模式> [LOCAL_IP] [PEER_IP] [VIP] [SOCKET_PORT] [BIN_PORT]
```

| 模式 | 说明 | 节点 ID |
|------|------|---------|
| `single` | 单机部署 | 1 |
| `node_a` | 集群节点 A | 1 |
| `node_b` | 集群节点 B | 2 |

### 示例

```bash
# 单机模式
./deploy/scripts/gen-cfg.sh single

# 集群节点 A（20.20.136.66，对端 20.20.136.67，VIP 20.20.136.100）
./deploy/scripts/gen-cfg.sh node_a 20.20.136.66 20.20.136.67 20.20.136.100 5060 5566

# 集群节点 B（20.20.136.67，对端 20.20.136.66，VIP 20.20.136.100）
./deploy/scripts/gen-cfg.sh node_b 20.20.136.67 20.20.136.66 20.20.136.100 5060 5566
```

### 生成的文件

```
/opt/zfnproxy/opensips/etc/opensips/
├── opensips_proxy.cfg   # 主配置
├── local.cfg            # 本机配置
├── ha.cfg               # HA 配置
└── cluster/
    ├── node_a.cfg       # 节点 A 拓扑（仅 node_a 模式）
    └── node_b.cfg       # 节点 B 拓扑（仅 node_b 模式）
```

---

## m4 模板参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `MODE` | 部署模式：`single` 或 `cluster` | `single` |
| `NODE_ID` | 节点 ID：1 或 2 | `1` |
| `LOCAL_IP` | 本机 IP | `127.0.0.1` |
| `PEER_IP` | 对端 IP | `127.0.0.1` |
| `VIP` | 虚拟 IP（Keepalived） | `127.0.0.1` |
| `SOCKET_PORT` | SIP 监听端口 | `5060` |
| `BIN_PORT` | 集群通信端口（MODE=cluster 时） | `5566` |

---

## 一键部署

`deploy.sh` 封装了备份、配置生成、目录创建、权限设置、配置验证的全流程。

```bash
# 单机模式
./deploy/scripts/deploy.sh single -l 192.168.1.100 -u 192.168.1.200:15060

# 集群节点 A
./deploy/scripts/deploy.sh node_a -l 20.20.136.66 -p 20.20.136.123 -v 20.20.136.100 -s 5060 -b 5566 -u 20.20.136.66:15060

# 集群节点 B
./deploy/scripts/deploy.sh node_b -l 20.20.136.123 -p 20.20.136.66 -v 20.20.136.100 -s 5060 -b 5566 -u 20.20.136.66:15060
```

### 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-l, --local-ip` | 本机 IP | 必须指定 |
| `-p, --peer-ip` | 集群对端 IP | 单机模式不需要 |
| `-v, --vip` | 虚拟 IP（Keepalived） | 默认等于 local-ip |
| `-s, --socket-port` | SIP 监听端口 | `5060` |
| `-b, --bin-port` | 集群通信端口 | `5566` |
| `-u, --upstream` | 上游地址，格式 `IP:PORT` | 默认等于 peer-ip:socket-port |

---

## systemd 服务

### 安装服务

```bash
cp deploy/systemd/opensips-gb28181.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable opensips-gb28181
```

### 启动/停止

```bash
systemctl start opensips-gb28181
systemctl stop opensips-gb28181
systemctl reload opensips-gb28181
```

---

## Keepalived HA

### 节点 A（MASTER）

```bash
cp deploy/keepalived/keepalived.conf.node_a /etc/keepalived/keepalived.conf
cp deploy/keepalived/notify.sh /opt/zfnproxy/opensips/etc/keepalived/
cp deploy/keepalived/chk_opensips.sh /opt/zfnproxy/opensips/etc/keepalived/
chmod +x /opt/zfnproxy/opensips/etc/keepalived/*.sh

systemctl enable keepalived
systemctl start keepalived
```

### 节点 B（BACKUP）

```bash
cp deploy/keepalived/keepalived.conf.node_b /etc/keepalived/keepalived.conf
# notify.sh 和 chk_opensips.sh 同节点 A
```

> 注意：`keepalived.conf.node_*` 中的 `VIP` 占位符需替换为实际虚拟 IP 地址后再部署。

---

## 配置验证

生成配置后，使用 `-c` 检查语法：

```bash
/opt/zfnproxy/opensips/sbin/opensips -c /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg
```

期望输出：`config file ok, exiting...`

---

## 节点间同步

将本地配置同步到对等节点：

```bash
./deploy/scripts/sync-to-peer.sh
```

前提：对端节点已部署且可通过 SSH 访问。

---

## 故障排查

### 配置语法错误

```bash
# 查看详细错误
/opt/zfnproxy/opensips/sbin/opensips -c /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg -l 6
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

### 集群同步异常

```bash
# 检查 BIN 端口监听
ss -ulnp | grep 5566

# 检查 clusterer 状态（MI 命令）
/opt/zfnproxy/opensips/sbin/opensipsctl fifo cluster_list
```

---

## 维护操作

### 滚动重启

1. 节点 B 执行 reload
2. 确认同步正常后，节点 A 执行 reload

```bash
systemctl reload opensips-gb28181
```

### 配置更新

1. 在管理节点修改模板或运行 `gen-cfg.sh`
2. 同步到对端：`./sync-to-peer.sh`
3. Reload 服务：`systemctl reload opensips-gb28181`

### 数据备份

```bash
# SQLite 数据
cp /opt/zfnproxy/opensips/data/opensips/opensips.db /opt/zfnproxy/opensips/data/opensips/opensips.db.bak.$(date +%Y%m%d)

# 配置文件
tar czf /opt/zfnproxy/opensips/etc/opensips.bak.$(date +%Y%m%d).tgz /opt/zfnproxy/opensips/etc/opensips/
```
