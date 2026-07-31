# OpenSIPS GB28181 集群部署指南

本文档描述如何部署 OpenSIPS GB28181 信令代理的单机模式和双机集群模式。

---

## 1. 概述

### 1.1 部署模式

| 模式 | 说明 | 适用场景 |
|------|------|----------|
| `single` | 单机部署，OpenSIPS 单独运行 | 开发测试、小规模部署 |
| `node_a` | 集群节点 A（MASTER），与 node_b 组成双机热备 | 生产环境主节点 |
| `node_b` | 集群节点 B（BACKUP），与 node_a 组成双机热备 | 生产环境备节点 |

### 1.2 集群架构

```
设备 → [VIP 20.20.136.100:5060] → OpenSIPS-A (MASTER) ─┐
                            └─ OpenSIPS-B (BACKUP)       │
                                                         ↓
                                                    [SQLite] ← 各自独立
                                                         ↓
                                                    监控平台
```

Keepalived 实现 VIP 漂移，保证设备侧连接高可用。OpenSIPS 集群间通过 bin 端口同步注册和 Catalog 数据。

---

## 2. 硬件与网络要求

### 2.1 硬件要求

| 项目 | 单机模式 | 集群模式（每节点） |
|------|----------|-------------------|
| CPU | 2 核+ | 4 核+ |
| 内存 | 4 GB+ | 8 GB+ |
| 磁盘 | 20 GB+ | 40 GB+ |
| 网卡 | 1 个 | 2 个（建议）+ |

### 2.2 网络要求

集群模式需要：
- **节点 A IP**: 例如 `20.20.136.66`
- **节点 B IP**: 例如 `20.20.136.67`
- **虚拟 IP (VIP)**: 例如 `20.20.136.100`，两节点间漂移
- **端口**: SIP `5060/UDP`，BIN `5566/TCP`（集群同步）
- **防火墙**: 放行上述端口及 VIP

---

## 3. 目录结构

部署产物位于 `/opt/zfnproxy/opensips/`：

```
/opt/zfnproxy/opensips/
├── etc/opensips/
│   ├── opensips_proxy.cfg   # 主配置（m4 模板生成）
│   ├── local.cfg            # 本机配置（节点 ID、IP 等）
│   ├── ha.cfg               # HA 模式（single/cluster）
│   ├── cluster/
│   │   ├── node_a.cfg       # 节点 A 集群参数
│   │   └── node_b.cfg       # 节点 B 集群参数
│   └── dbtext/dispatcher/   # dispatcher 表
├── data/opensips/           # SQLite 数据目录
└── log/opensips/            # 日志目录
```

---

## 4. 编译 OpenSIPS

### 4.1 使用统一配置编译

```bash
cd /root/work/zf2zf/opensips/opensips

# 使用项目提供的 Makefile.conf
make -f deploy/Makefile.conf config
make -f deploy/Makefile.conf
```

`deploy/Makefile.conf` 包含所有 GB28181 所需模块（usrloc、clusterer、sqlops、dispatcher 等）。

### 4.2 安装

```bash
make -f deploy/Makefile.conf install
```

---

## 5. 单机模式部署

### 5.1 生成配置

```bash
./deploy/scripts/gen-cfg.sh single

# 或手动指定参数
./deploy/scripts/gen-cfg.sh single 127.0.0.1 127.0.0.1 127.0.0.1 5060 5566
```

### 5.2 部署

```bash
./deploy/scripts/deploy.sh single
```

### 5.3 验证

```bash
/opt/zfnproxy/opensips/sbin/opensips -c /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg
```

---

## 6. 集群模式部署

### 6.1 节点 A 部署（MASTER）

在节点 A 服务器上执行：

```bash
./deploy/scripts/gen-cfg.sh node_a 20.20.136.66 20.20.136.67 20.20.136.100 5060 5566
./deploy/scripts/deploy.sh node_a 20.20.136.66 20.20.136.67 20.20.136.100 5060 5566
```

### 6.2 节点 B 部署（BACKUP）

在节点 B 服务器上执行：

```bash
./deploy/scripts/gen-cfg.sh node_b 20.20.136.67 20.20.136.66 20.20.136.100 5060 5566
./deploy/scripts/deploy.sh node_b 20.20.136.67 20.20.136.66 20.20.136.100 5060 5566
```

注意：node_b 的 `LOCAL_IP` 和 `PEER_IP` 与 node_a 对调。

### 6.3 同步配置到对端

在节点 A 上执行，将配置同步到节点 B：

```bash
./deploy/scripts/sync-to-peer.sh 20.20.136.67
```

### 6.4 验证配置语法

```bash
/opt/zfnproxy/opensips/sbin/opensips -c /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg
```

---

## 7. Keepalived 配置

Keepalived 负责 VIP 漂移。配置文件位于 `deploy/keepalived/`。

### 7.1 keepalived.conf.node_a（MASTER）

```conf
global_defs {
    router_id opensips_node_a
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    unicast_peer {
        20.20.136.67
    }
    virtual_ipaddress {
        20.20.136.100/24 dev eth0
    }
    track_script {
        chk_opensips
    }
}
```

### 7.2 keepalived.conf.node_b（BACKUP）

```conf
global_defs {
    router_id opensips_node_b
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 90
    advert_int 1
    unicast_peer {
        20.20.136.66
    }
    virtual_ipaddress {
        20.20.136.100/24 dev eth0
    }
    track_script {
        chk_opensips
    }
}
```

### 7.3 健康检查脚本

`deploy/keepalived/chk_opensips.sh` 检查 OpenSIPS 进程是否存活：

```bash
#!/bin/bash
[ -f /var/run/opensips/opensips.pid ] && kill -0 $(cat /var/run/opensips/opensips.pid) 2>/dev/null
```

### 7.4 部署 Keepalived

将对应配置文件复制到 `/etc/keepalived/keepalived.conf`，然后：

```bash
systemctl enable keepalived
systemctl start keepalived
```

---

## 8. systemd 服务配置

服务文件位于 `deploy/systemd/opensips-gb28181.service`：

```ini
[Unit]
Description=OpenSIPS GB28181 SIP Proxy
After=network.target

[Service]
Type=forking
PIDFile=/var/run/opensips/opensips.pid
ExecStart=/opt/zfnproxy/opensips/sbin/opensips -c /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg -P /var/run/opensips/opensips.pid
Restart=always
RestartSec=5
User=opensips
Group=opensips

[Install]
WantedBy=multi-user.target
```

### 部署服务

```bash
cp deploy/systemd/opensips-gb28181.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable opensips-gb28181
systemctl start opensips-gb28181
```

---

## 9. m4 模板配置说明

所有配置文件通过 m4 宏预处理生成，支持参数化定制。

### 9.1 核心参数

| 宏 | 说明 | 示例值 |
|----|------|--------|
| `MODE` | 部署模式 | `single`, `node_a`, `node_b` |
| `NODE_ID` | 节点 ID | `1`, `2` |
| `LOCAL_IP` | 本机 IP | `20.20.136.66` |
| `PEER_IP` | 对端 IP | `20.20.136.67` |
| `VIP` | 虚拟 IP | `20.20.136.100` |
| `SOCKET_PORT` | SIP 监听端口 | `5060` |
| `BIN_PORT` | 集群通信端口 | `5566` |

### 9.2 模板文件

| 文件 | 说明 |
|------|------|
| `deploy/cfg/opensips_proxy.cfg.m4` | 主配置模板 |
| `deploy/cfg/local.cfg.m4` | 本机配置（节点 ID、IP） |
| `deploy/cfg/ha.cfg.m4` | HA 模式（single/cluster） |
| `deploy/cfg/cluster/node_a.cfg.m4` | 节点 A 集群参数 |
| `deploy/cfg/cluster/node_b.cfg.m4` | 节点 B 集群参数 |

### 9.3 生成过程

`gen-cfg.sh` 执行以下步骤：

1. 根据模式设置 `NODE_ID`
2. 生成 `env.m4` 宏定义文件
3. 执行 `m4` 预处理，生成各配置文件到 `/opt/zfnproxy/opensips/etc/opensips/`

---

## 10. 故障排查

### 10.1 OpenSIPS 无法启动

```bash
# 检查配置语法
/opt/zfnproxy/opensips/sbin/opensips -c /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg

# 查看日志
tail -f /opt/zfnproxy/opensips/log/opensips/opensips.log
```

### 10.2 设备无法注册

- 确认设备配置的 SIP 服务器地址为 VIP（不是单个节点 IP）
- 确认防火墙放行了 UDP 5060
- 确认 `usrloc` 模块正常加载

### 10.3 VIP 不漂移

- 检查 Keepalived 服务状态：`systemctl status keepalived`
- 检查 `chk_opensips.sh` 脚本权限
- 查看 Keepalived 日志：`tail -f /var/log/messages | grep keepalived`

### 10.4 集群数据不同步

- 确认 bin 端口 5566 在两节点间可达
- 检查 `clusterer` 模块配置：`grep clusterer /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg`
- 查看集群状态：`/opt/zfnproxy/opensips/sbin/opensipsctl cluster list`

### 10.5 Catalog 同步失败

- 确认设备支持 Catalog 查询（GB28181 2016+）
- 检查 `mi_script` 模块是否正确解析 Catalog XML
- 查看 mi_script 日志

---

## 11. 维护操作

### 11.1 滚动重启（零丢包）

1. 先在 BACKUP 节点执行更新
2. 等待 Keepalived VIP 漂移到更新后的节点
3. 再在原 MASTER 节点执行更新

### 11.2 配置更新

```bash
# 备份
./deploy/scripts/deploy.sh node_a 20.20.136.66 20.20.136.67 20.20.136.100 5060 5566

# 验证
/opt/zfnproxy/opensips/sbin/opensips -c /opt/zfnproxy/opensips/etc/opensips/opensips_proxy.cfg

# 重载（无需重启）
/opt/zfnproxy/opensips/sbin/opensipsctl reload
```

### 11.3 数据备份

SQLite 数据位于 `/opt/zfnproxy/opensips/data/opensips/`，建议定期备份：

```bash
tar czf opensips_data_backup.tar.gz /opt/zfnproxy/opensips/data/
```

### 11.4 监控指标

建议监控：
- OpenSIPS 进程存活
- VIP 漂移次数
- SIP 注册成功率
- BIN 端口连通性
- SQLite 磁盘使用

---

## 12. 参考文件索引

| 文件 | 路径 |
|------|------|
| 主配置模板 | `deploy/cfg/opensips_proxy.cfg.m4` |
| 本机配置模板 | `deploy/cfg/local.cfg.m4` |
| HA 配置模板 | `deploy/cfg/ha.cfg.m4` |
| 节点 A 集群配置 | `deploy/cfg/cluster/node_a.cfg.m4` |
| 节点 B 集群配置 | `deploy/cfg/cluster/node_b.cfg.m4` |
| 配置生成脚本 | `deploy/scripts/gen-cfg.sh` |
| 部署脚本 | `deploy/scripts/deploy.sh` |
| 同步脚本 | `deploy/scripts/sync-to-peer.sh` |
| systemd 服务文件 | `deploy/systemd/opensips-gb28181.service` |
| Keepalived 主节点配置 | `deploy/keepalived/keepalived.conf.node_a` |
| Keepalived 备节点配置 | `deploy/keepalived/keepalived.conf.node_b` |
| Keepalived 健康检查 | `deploy/keepalived/chk_opensips.sh` |
| Keepalived 通知脚本 | `deploy/keepalived/notify.sh` |
| 编译配置 | `deploy/Makefile.conf` |
| 环境宏定义 | `deploy/env.m4` |
