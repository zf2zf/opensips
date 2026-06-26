---
title: "二进制内部接口"
description: "二进制内部接口是 OpenSIPS 核心接口，提供了一种高效的 OpenSIPS 实例间通信方式。这尤其适用于需要实时数据（如 dialog）不能再简单存储在数据库中的场景，因为故障转移可能需要整整几分钟才能完成。通过新的内部二进制接口，可以将运行时数据（创建/更新/删除）的所有事件复制到备份 OpenSIPS 实例来解决此问题。"
---

**二进制内部接口**是 OpenSIPS 核心接口，提供了一种高效的 OpenSIPS 实例间通信方式。这尤其适用于需要实时数据（如 dialog）不能再简单存储在数据库中的场景，因为故障转移可能需要整整几分钟才能完成。通过新的内部二进制接口，可以将运行时数据（创建/更新/删除）的所有事件复制到备份 OpenSIPS 实例来解决此问题。

---

## 配置二进制内部接口监听器

为了监听传入的二进制数据包，必须指定 **bin:** 接口。其监听进程数量可通过 *[tcp_workers](https://docs.opensips.org/manual/devel/script-coreparameters#tcp_workers)* 核心参数进行调整。

```c

   listen = bin:10.0.0.150:5062
   ...
   loadmodule "proto_bin.so"

```

使用二进制接口的集群启用模块示例有 **dialog** 和 **usrloc**，因为它们现在可以将所有运行时事件（dialog/contact 的创建/更新/删除）复制到一个或多个 OpenSIPS 实例。配置如下:

```c

   modparam("dialog", "dialog_replication_cluster", 1)
   modparam("dialog", "profile_replication_cluster", 2)
   ...
   modparam("usrloc", "location_cluster", 2)

```

更多详细信息请参阅 [dialog](../../modules/dialog/README.md#dialog_clustering) 和 [usrloc](../../modules/usrloc/README.md#distributed_sip_user_location) 文档页面。

---

## C 接口概述（面向模块开发者）

该接口允许模块编写者以直观的方式构建和发送紧凑的**二进制数据包**。

为了**发送数据包**，接口提供以下原语:
* *int bin_init(str *mod_name, int packet_type)* - 开始构建新的二进制数据包
* *int bin_push_str(const str *info)* - 将字符串添加到当前正在构建的二进制数据包
* *int bin_push_int(int info)* - 将整数添加到当前正在构建的二进制数据包
* *int bin_send(union sockaddr_union *de*[tcp_workers](https://docs.opensips.org/manual/devel/script-coreparameters#tcp_workers) *core parameter.st)* - 通过 UDP 将二进制数据包发送到给定目的地

  

为了**接收数据包**，模块必须首先向接口注册回调函数:
* *int bin_register_cb(char *mod_name, void (*)(int packet_type))*

  

每次触发此回调时，可以使用与写入时相同的顺序检索信息:
* *int bin_pop_str(str *info)* - 从接收的二进制数据包中检索字符串
* *int bin_pop_int(void *info)* - 从接收的二进制数据包中检索整数
