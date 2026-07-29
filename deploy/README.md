# OpenSIPS GB28181 HA 部署指南

## 概述

基于 OpenSIPS 4.1 + clusterer 的 2 节点 active/standby 高可用方案，无 MySQL/PostgreSQL/Redis 依赖。

- **架构**：节点 1 active（绑 VIP）、节点 2 standby（平时不接 SIP）
- **数据同步**：usrloc + dispatcher 走 clusterer BIN；Catalog 子通道走 HTTP JSON 重放
- **VIP 漂移**：Keepalived + iptables DNAT
- **详细设计**：`docs/superpowers/specs/2026-07-28-opensips-gb28181-ha-design.md`

## 目录结构

```
deploy/
├── README.md              本文档
├── env.sh.example        环境变量模板（复制为 env.sh 后填入）
├── bootstrap.sh            安装系统依赖（两节点各跑一次）
├── build.sh               从源码 build OpenSIPS（可选，已装则跳过）
├── deploy_node1.sh        节点 1 部署（active）
├── deploy_node2.sh        节点 2 部署（standby）
├── sync_to_node2.sh       把配置 scp 到节点 2（节点 1 上跑）
├── verify.sh              端到端验收
└── files/
    ├── opensips/
    │   ├── opensips_proxy_ha.cfg   主入口
    │   ├── opensips_ha_routes.cfg 业务路由（节点共用）
    │   ├── local.cfg.node1        节点 1 私有
    │   └── local.cfg.node2         节点 2 私有
    ├── keepalived/
    │   ├── keepalived.conf.master  节点 1 用
    │   ├── keepalived.conf.backup 节点 2 用
    │   ├── chk_opensips.sh        健康检查脚本
    │   └── notify.sh               状态切换钩子
    ├── systemd/
    │   └── opensips.service
    └── dbtext/
        └── dispatcher             dispatcher 表
```

## 部署顺序

### 0. 准备环境

```bash
# 节点 1 / 节点 2：各装一台 Ubuntu 22.04

# 在节点 1 上 clone 配置仓库
git clone <repo-url>
cd deploy/
cp env.sh.example env.sh
vim env.sh   # 按实际环境填入 IP/VIP/接口名
```

### 1. 安装依赖（两节点各跑一次）

```bash
sudo bash bootstrap.sh
```

### 2. 源码 build OpenSIPS（可选，跳过如已装）

```bash
# 在 env.sh 中设 SRC_DIR 指向 OpenSIPS 源码目录
# 确保源码已 make menuconfig 选好模块
bash build.sh
```

### 3. 节点 1 部署

```bash
# 节点 1（active）
sudo bash deploy_node1.sh
```

### 4. 推送配置到节点 2

```bash
# 在节点 1 上
bash sync_to_node2.sh
```

### 5. 节点 2 部署

```bash
# 节点 2（standby）
sudo bash deploy_node2.sh
```

### 6. 端到端验收

```bash
# 在节点 1 上
sudo bash verify.sh
```

## 环境变量说明

| 变量 | 默认值 | 说明 |
|---|---|---|
| `ROLE` | `node1` | 本机角色 |
| `NODE1_IP` | `20.20.136.66` | 节点 1 物理 IP |
| `NODE2_IP` | `20.20.136.67` | 节点 2 物理 IP |
| `VIP` | `20.20.136.100` | 虚拟 IP |
| `NODE1_IF` / `NODE2_IF` | `eth0` | 网络接口名 |
| `SIP_PORT` | `5060` | SIP UDP 端口 |
| `BIN_PORT` | `5566` | clusterer BIN 端口 |
| `HTTP_PORT` | `8080` | HTTP 重放端口 |
| `CLUSTER_ID` | `1` | clusterer 集群号 |
| `SHTAG` | `sip_active` | sharing tag |
| `OPEN_SIPS_BIN` | `/usr/local/sbin/opensips` | opensips 二进制路径 |

## 关键行为

### VIP 漂移
- 节点 1 active → 节点 2 standby
- 节点 1 故障 → Keepalived 降 priority → 节点 2 抢主 → VIP 漂移 → notify.sh 去掉 local.cfg SIP listen 注释 → opensips restart
- 节点 1 恢复 → VIP 漂回 → 节点 2 退回 standby

### 数据同步
| 事件 | 同步路径 |
|---|---|
| 设备 REGISTER | usrloc → clusterer BIN |
| Catalog 子通道写入 | sql_query(本地) → HTTP JSON 重放 |
| 设备注销级联删除 | sql_query(本地) → HTTP JSON 重放 |
| dispatcher 探测 | by-shtag（仅 active 节点） |

### 故障切换后恢复
- 主注册（设备）：BIN 已同步，lookup 直接命中
- 子通道：可能 404 → 平台重查 → 设备重发 Catalog → HTTP 重放恢复
- Keepalive：节点 2 无记录 → 401 → 设备重注册

## 故障排查

```bash
# 服务状态
systemctl status opensips
systemctl status keepalived

# 日志
journalctl -u opensips -f
journalctl -u keepalived -f
tail -f /var/log/keepalived.log

# VIP 绑定
ip addr show eth0 | grep 20.20.136.100

# clusterer 邻居
opensips -f /etc/opensips/opensips_proxy_ha.cfg -x "clusterer:list"

# location 表
sqlite3 /var/lib/opensips/opensips.db "SELECT username,expires FROM location LIMIT 10;"

# dispatcher 表
cat /etc/opensips/dbtext/dispatcher/dispatcher

# HTTP 重放（手动测）
curl -X POST -H "Content-Type: application/json" \
  -d '{"op":"insert","row":{"username":"test","domain":"t","contact":"sip:test@x","user_agent":"t","socket":"udp:x","attr":"t","callid":"t"}}' \
  http://20.20.136.67:8080/replay/channel
```

## 已知限制

1. **子通道 404**：故障切换后节点 2 可能缺子通道记录，需平台重查恢复
2. **HTTP 重放单向**：仅 active → standby，故障切换瞬间可能有少量记录未同步
3. **IPv4 only**：本方案不支持 IPv6
