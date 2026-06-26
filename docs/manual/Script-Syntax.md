---
title: "脚本语法"
description: "OpenSIPS 配置脚本有三个主要的逻辑部分："
---

## 脚本格式

OpenSIPS 配置脚本有三个主要的逻辑部分：

* 全局参数
* 模块部分
* 路由逻辑

---

### 全局参数

通常，在第一部分，您声明 [OpenSIPS 全局参数](Script-CoreParameters.md) - 这些全局或核心参数影响 OpenSIPS 核心和可能的模块。

通过这些全局参数配置网络监听器、可用的传输协议、分叉（和进程数）、日志记录和其他全局设置。

示例：

```c

disable_tcp = yes
listen = udp:192.168.4.10:5060
listen = udp:192.168.4.10:5070
fork = yes
children = 4
log_stderror = no

```

---

#### 模块部分

关于 OpenSIPS 模块，要加载的模块（默认没有加载模块）使用 **loadmodule** 指令指定。模块由名称和可选路径（到 *.so* 文件）指定。如果未提供路径（只有模块名称），将使用默认路径来定位和加载模块（如果没有在[编译时](Install-CompileAndInstall.md)配置其他路径，默认路径为 */usr/lib/opensips/modules*）。要配置不同路径，可以直接将路径与模块名称一起推送（以获得每个模块的控制），或者可以通过 **mpath** 全局参数全局配置（针对所有模块）。  
\
加载模块后，可以使用 **modparam** 指令设置模块参数 - 要获取每个模块可用参数的列表、参数值类型（整数或字符串），请参阅[模块文档](Modules.md)中的 *参数* 部分。

示例：
```c

loadmodule "modules/mi_datagram/mi_datagram.so"
modparam("mi_datagram", "socket_name", "udp:127.0.0.1:4343")
modparam("mi_datagram", "children_count", 3)

```

或

```c

mpath="/usr/local/opensips_proxy/lib/modules"
loadmodule "mi_datagram.so"
modparam("mi_datagram", "socket_name", "udp:127.0.0.1:4343")
modparam("mi_datagram", "children_count", 3)
loadmodule "mi_fifo.so"
modparam("mi_fifo", "fifo_name", "/tmp/opensips_fifo")

```

---

#### 路由逻辑

路由逻辑实际上是包含 OpenSIPS 路由 SIP 流量逻辑的路由（脚本路由）的总和。通过这些路由完成 **OpenSIPS 与 SIP 流量相关行为的描述**。  
\
有不同类型的路由：
* **顶级路由** - 当某些事件发生时（如收到 SIP 请求、收到 SIP 回复、事务失败等）由 OpenSIPS 直接触发的路由
* **子路由** - 在脚本中从其他路由触发/使用的路由


现有的 **顶级路由**、它们何时触发、处理何种 SIP 消息、允许何种 SIP 操作等都在[路由类型部分](Script-Routes.md)中有文档说明。  
\
**子路由**有名称，可通过脚本中任何其他路由（顶级或子路由）以其名称调用。**子路由**在调用时可以接受参数（或返回数值代码——避免返回 0 值，因为这将终止整个脚本）。**子路由**类似于任何编程语言中的函数/过程。
请参阅 [*route* 指令](Script-CoreFunctions.md#setuser)的描述。

## 数据类型

OpenSIPS 脚本语言支持以下数据类型：

### 基本类型

* *integer*（32 位，有符号）。
  * 最大值：+2,147,483,647 == 2 ^ 31 - 1
  * 最小值：-2,147,483,648 == - 2 ^ 31
* *string*（无限制大小）
  * 注意，某些使用字符串的函数可能有内部缓冲区，限制字符串的最大大小（例如，[xlog()](https://docs.opensips.org/manual/devel/script-corefunctions#socket_belongs_to_bond) 函数的输出缓冲区可通过 [xlog_buf_size](https://docs.opensips.org/manual/devel/script-coreparameters#udp_workers) 配置）
* *double*（打包为字符串），通过 **[mathops](../../modules/mathops/README.md)** 模块

### 复杂类型

* *list* 通过 **[`$avp` 变量](https://docs.opensips.org/manual/devel/script-corevar#avp_variables)**
* *map* 通过 **[`$json`](../../modules/json/README.md#pv_json)** 和 **[`$xml`](../../modules/xml/README.md#pv_xml)** 变量

## 函数调用约定

所有 OpenSIPS [核心](https://docs.opensips.org/manual/devel/script-corefunctions) 和[模块](https://docs.opensips.org/manual/devel/function-index) 函数在内部共享相同的函数接口，因此受益于以下调用约定：

  

* **任何整数或字符串函数参数也可以使用"holder"变量传递**

```text

ds_select_dst(1, 1); 

```

...等效于：

```text

$var(x) = 1;
ds_select_dst($var(x), $var(x));

```

  

* **任何字符串函数参数都可以作为格式字符串传递**

```text

set_dlg_profile("caller", "$var(country_code)_$var(area)_$fU");

```

  

字面 **"$"** 字符可以使用 **"$$"** 转义序列包含在格式字符串中

  

> [!NOTE]
> 由于性能优化，上述约定在字符串参数情况下仍有少数例外，因为某些函数仍需要一些参数是纯静态字符串（例如 *save("location")*）。此类情况将在函数的文档中注明。

  

* **传递给函数的输入或输出变量不能加引号**：

```text

ds_count(1, "a", $var(out_result));

```

  

* **整数不再需要作为双引号字符串传递**：

```text del={2-2}
# this is deprecated
ds_select_dst("1", "1");
```

```text

ds_select_dst(1, 1);

```
