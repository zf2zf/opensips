---
title: "脚本标志"
---

## 什么是标志？

标志是一个 TRUE 或 FALSE 的实体。每种类型有 32 个标志（见下文）。标志通过其名称标识 - 同样，您不能拥有超过 32 个不同的名称/标志。您无需声明或定义标志的名称，直接使用即可。
标志可用于任何目的，没有任何预定义的内容。

## 标志的类型

* **消息标志**（或事务标志）这些标志附加到当前 SIP 消息或当前事务（如果存在事务）。因此这些标志是事务持久的。它们在所有事务或 SIP 消息上下文可见的路由和情况下都可见。
* **分支标志** 这些标志也在事务级别，但每个 SIP 分支都有自己的标志集 - 每个时间在特定 SIP 分支的上下文中（如在 `branch_route` 或 `reply_route` 中），您将看到匹配的分支标志。这些标志可以从脚本级别或各种模块函数操作（如 usrloc 为每个注册的 contact 保存分支标志）。

---

## 脚本标志函数

有一系列函数帮助从脚本级别处理标志 - 设置、重置和检查。

### 消息/事务标志

* [`setflag`](Script-CoreFunctions.md#setflag)`(FLAG)`
* [`resetflag`](Script-CoreFunctions.md#resetflag)`(FLAG)`
* [`isflagset`](Script-CoreFunctions.md#isflagset)`(FLAG)`

*示例: setflag(accounting), resetflag(DO_NAT) 或 setflag(1942)*

### 分支标志

* [`setbflag`](Script-CoreFunctions.md#setbflag)`(FLAG, branch_idx)`
* [`resetbflag`](Script-CoreFunctions.md#resetbflag)`(FLAG, branch_idx)`
* [`isbflagset`](Script-CoreFunctions.md#isbflagset)`(FLAG, branch_idx)`

  

或更短的格式，适用于默认（分支 0）标志:

* [`setbflag`](Script-CoreFunctions.md#setbflag)`(FLAG)`
* [`resetbflag`](Script-CoreFunctions.md#resetbflag)`(FLAG)`
* [`isbflagset`](Script-CoreFunctions.md#isbflagset)`(FLAG)`

---

## 标志相关变量

### 消息/事务标志

* [`$msg.flag(name)`](Script-CoreVar.md#msg.flag) - 读取/写入特定消息标志

* [`$mf`](Script-CoreVar.md#mf) - 只读; 输出所有已设置标志的列表


### 分支标志

* [`$msg.branch.flag(name)`](Script-CoreVar.md#msg.branch.flag) - 读取/写入特定分支标志

* [`$msg.branch.flags`](Script-CoreVar.md#msg.branch.flags) - 只读; 返回所有已设置分支标志的列表

---

## 标志和路由

### 消息/事务标志

这些标志将显示在处理与初始请求相关的消息的所有路由中。因此，它们在 `onbranch`、`failure` 和 `onreply` 路由中可见并可更改; 标志在所有 `branch` 路由中可见; 如果您在 `branch` 路由中更改标志，后续 `branch` 路由将继承该更改。

### 分支标志

这些标志将显示在处理与初始分支请求相关的消息的所有路由中。因此，在 `branch` 路由中您将看到不同的标志集（因为它们是不同的分支）; 在 `onreply` 路由中，您将看到该回复所属分支的分支标志; 在 `failure` 路由中，将显示与获胜回复所属分支对应的分支标志。
在 `request` 路由中，您可能有多个分支（作为 `lookup()` 的结果等），但至少有一个。始终存在默认分支，索引 0，对应 RURI。任何其他分支将从 1 开始分配索引。

---

## 示例

### NAT 标志处理

```c

 ..........
 modparam("usrloc", "nat_bflag", "NAT_BFLAG")
 ..........
 
 route {
   ..........
   if (nat detected)
      setbflag(NAT_BFLAG); # 为分支 0 设置分支标志 "NAT_BFLAG"

   ..........
   if (is_method("REGISTER")) {
      # 分支标志（包括 "NAT_BFLAG"）将被保存到位置
      save("location");
      exit;
   } else {
      # lookup 将从位置加载分支标志
      if (!lookup("location")) {
         sl_send_reply(404,"Not Found");
         exit;
      }
      t_on_branch("handle_branch")
      t_relay();
   }
 }
 
 branch_route[handle_branch] {
   xlog("-------branch=$T_branch_idx, branch flags=$bf\n");
   if (isbflagset(NAT_BFLAG)) {
      #当前分支被标记为 NATed
      .........
   }
 }

```

如果没有执行并行分叉，您可以放弃分支路由，而将 t_on_branch() 替换为:
```text

   ........
   if (isbflagset(NAT_BFLAG)) {
      #当前分支被标记为 NATed
      .........
   }
   .........

```
