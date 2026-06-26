---
title: "Prometheus 模块"
description: "此模块为 [Prometheus](https://prometheus.io/) 监控系统提供 HTTP 接口，允许其从 OpenSIPS 获取各种统计数据。"
---

## 管理指南

### 概述

此模块为 [Prometheus](https://prometheus.io/) 监控系统提供 HTTP 接口，允许其从 OpenSIPS 获取各种统计数据。

要使用它，您必须通过[统计](#param_statistics)参数列出要提供的统计数据来明确定义统计数据。

目前该模块仅支持 *counter* 和 *gauge* 指标类型，为特定统计选择其中一种取决于统计的定义方式（内部定义或通过 *statistics* 模块的 *variable* 参数明确定义）。

每个导出的统计信息都带有一个 *group* 标签，指示其所属的组。

### 依赖

#### 外部库或应用程序

无

#### OpenSIPS 模块

以下模块必须在此模块之前加载：

- *httpd* 模块。

### 导出的参数

#### root(string)

指定 Prometheus 用于查询统计信息的根路径：
http://[opensips_IP]:[opensips_httpd_port]/[root]

*默认值为 "metrics"。*

```c title="设置 root 参数"
...
modparam("prometheus", "root", "prometheus")
...
```

#### prefix(string)

为每个导出的统计信息添加前缀。

*默认值为 "opensips"。*

```c title="设置 prefix 参数"
...
modparam("prometheus", "prefix", "opensips_1")
...
```

#### group_prefix(string)

为统计信息所属组的名称添加前缀。

*默认值为 ""（无组前缀）。*

```c title="设置 group_prefix 参数"
...
modparam("prometheus", "group_prefix", "opensips")
...
```

#### delimiter(string)

指定用于分隔 *prefix* 和 *group_prefix* 的分隔符。

*默认值为 "_"。*

```c title="设置 delimiter 参数"
...
modparam("prometheus", "delimiter", "-")
...
```

#### group_label(string)

指定当 *group_mode* 为 2 时用于存储组的标签。

*默认值为 "group"。*

```c title="设置 group_label 参数"
...
modparam("prometheus", "group_label", "grp")
...
```

#### group_mode(int)

指定应如何向 Prometheus 提供统计信息的组。可用模式：

- *0* - 不发送统计信息组。
- *1* - 在统计信息的名称中发送组。
- *2* - 将组作为统计信息的标签发送。

*默认值为 0（不指定组）。*

```c title="设置 group_mode 参数"
...
modparam("prometheus", "group_mode", 1)
...
```

#### statistics(string)

OpenSIPS 导出的统计信息，用空格分隔。该列表也可以包含统计信息组的名称——要做到这一点，您应该在组名称末尾添加冒号（*:*）。

如果使用 *all* 值，则模块将暴露所有可用统计信息——因此此参数的任何其他设置都将无效；

此参数可以定义多次。

*默认值为空：不导出任何指标。*

```c title="设置 statistics 参数"
...
# 导出活跃对话数量和负载统计类
modparam("prometheus", "statistics", "active_dialogs load:")
...
```

#### labels(string)

定义如何将组内统计信息名称转换为在 Prometheus 中推送的名称和标签集的规则。

格式为 *group: regex*，其中 *group* 表示应用正则表达式的统计信息组，*regexp* 是用于匹配统计信息名称并将其转换为所需名称和标签的正则表达式。

*regex* 格式为 */matching_expression/substitution_expression/flags*。替换后得到的 *substitution_expression* 应产生格式为 *name:labels* 的字符串，其中 *name* 表示将推送到 Prometheus 的统计信息名称，*labels* 表示为标签，以 *key=value* 对的形式表示，用逗号分隔，从 Prometheus 接收。

如果声明的组内统计信息名称与正则表达式不匹配，或者结果格式不符合 *name:labels* 格式，则统计信息转换将被忽略，并将按常规统计信息打印，就像未使用该规则一样。

此参数可以定义多次，甚至可以为单个组定义。但是，如果统计信息匹配多个正则表达式，则仅考虑匹配的第一个正则表达式。检查它们的顺序是脚本中声明的顺序。

*默认值为空：提供统计信息名称。*

```c title="设置 statistics 参数"
...
# 将 duration_gateway 转换为以 gateway 为标签的 stat duration
modparam("prometheus", "labels", "group: /^(.*)_(.*)$/\1:gateway=\"\2\"/")
...
```

#### script_route(string)

指定用于添加自定义 prometheus 信息的路由名称。

*默认值为 "" - 不调用自定义路由。*

```c title="设置 script_route 参数"
...
modparam("prometheus", "script_route", "my_custom_prometheus_route")
...
route[my_custom_prometheus_route] {
	# * 返回的 JSON 需要包含一个对象数组
	#   每个对象包含 header 和 values 字段
	# * header 字段包含自定义 prometheus 统计信息头
	# * values 字段本身是一个数组，包含用于单个统计信息发布的 name/value 对象
	return (1, '[{
        "header": "# TYPE opensips_total_cps gauge",
        "values": [
            {
                "name": "opensips_total_cps",
                "value": 3
            }
        ]
    }, {
        "header": "# TYPE opensips_disabled_rtpengine gauge",
        "values": [
            {
                "name": "opensips_disabled_rtpengine",
                "value": 0
            }
        ]
    }]');
}
...
```

### 导出的函数

#### prometheus_declare_stat(name, [type], [help])

*注意：*此函数只能在[脚本路由](#param_script_route)参数声明的路由中使用。

声明要导出到 Prometheus 服务器的自定义统计信息。它指定其类型和可选的帮助字符串。

参数

- *name* (string) - 统计信息的名称
- *type* (string，可选) - 统计信息的类型（即 *counter* 或 *gauge*）。如果缺失，统计信息将被声明为 *gauge*。
- *help* (string，可选) - 用于描述统计信息含义的可选值。如果缺失，则不使用。

此函数只能在[脚本路由](#param_script_route)参数声明的请求路由中使用。

```c title="prometheus_declare_stat 用法"
...
modparam("prometheus", "script_route", "my_custom_prometheus_route")
...
route[my_custom_prometheus_route] {
	...
	prometheus_declare_stat("opensips_cps");
	prometheus_push_stat(3);
	...
}
```

#### prometheus_push_stat(value, [label_name], [label_value])

*注意：*此函数只能在[脚本路由](#param_script_route)参数声明的路由中使用。

将自定义统计信息值和可选的标签集推送到 Prometheus 服务器。

*注意：*统计信息值只能在使用[prometheus declare stat](#func_prometheus_declare_stat)函数声明后才能推送。

参数

- *value* (integer) - 统计信息的值
- *label_name* (string，可选) - 用于为推送的统计信息定义标签。如果 *label_value* 参数缺失，则此参数将附加到统计信息名称——这意味着它应包含值的完整标签集（包括大括号）。如果也提供了 *label_value*，则该参数应仅包含一个标签的名称。
- *label_value* (string，可选) - 应用于 *label_name* 参数标签的值。

此函数只能在[脚本路由](#param_script_route)参数声明的请求路由中使用。

```c title="prometheus_push_stat 用法"
...
modparam("prometheus", "script_route", "my_custom_prometheus_route")
...
route[my_custom_prometheus_route] {
	...
	prometheus_declare_stat("opensips_cps");
	prometheus_push_stat(3); # 未使用标签
	prometheus_declare_stat("opensips_cc");
	# 下面两个是等价的
	prometheus_push_stat(10, "{gateway=\"gw1\"}"); # 未使用标签
	prometheus_push_stat(10, "gateway", "gw1"); # 与上面相同
	...
}
```

### 示例

为了让 Prometheus 查询 OpenSIPS 的统计信息，您需要告诉它从哪里获取统计信息。为此，您应该在 Prometheus 的 *scrape_configs* 配置中定义一个 scrape job，指明您配置 *httpd* 模块监听 IP 和端口（默认：*0.0.0.0:8888*）。

```c title="Prometheus Scrape 配置"
scrape_configs:
  - job_name: opensips

    static_configs:
    - targets: ['localhost:8888']
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
