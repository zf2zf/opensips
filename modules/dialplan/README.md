---
title: "拨号计划模块"
description: "此模块实现基于匹配和替换规则的通用字符串转换。它可用于操作 R-URI 或 PV 并转换为新的格式/值。"
---

## 管理指南

### 概述

此模块实现基于匹配和替换规则的通用字符串转换。它可用于操作 R-URI 或 PV 并转换为新的格式/值。

### 工作原理

启动时，模块将从多个拨号计划兼容表加载所有转换规则。每个表的数据将存储在一个*分区*（数据源）中，由 "db_url" 和 "table_name" 属性定义。每一行表数据将作为转换规则存储在内存中。

拨号计划规则可以是两种类型：

- *"字符串匹配" 规则* - 对输入字符串执行字符串相等测试
- *"正则匹配" 规则* - 使用与 Perl 兼容的正则表达式

### 使用场景

- 实现拨号计划 - 自动完成拨号号码（例如从国内到国际）
- 检测映射到服务/案例的数字范围或集合
- 非 SIP 字符串转换 - 如转换国家名称
- 任何其他基于字符串的转换或检测

### 依赖

#### OpenSIPS 模块

无

#### 外部库或应用程序

- *libpcre-dev - PCRE 的开发库*

### 导出的参数

#### partition (string)

指定新的拨号计划分区（数据源）。

```c title="定义 'pstn' 分区"
...
modparam("dialplan", "partition", "
    pstn:
        table_name = dialplan;
        db_url = mysql://opensips:opensipsrw@127.0.0.1/opensips")
...
```

#### db_url (string)

模块的默认数据库连接。

*默认值为 NULL（未设置）*

#### table_name (string)

从中加载转换规则的默认表名。

*默认值为 "dialplan"*

### 导出的函数

#### dp_translate(id, input, [out_var], [attrs_var], [partition])

根据拨号计划 ID 等于 id 的转换规则尝试将 src 字符串转换为 dest 字符串。

```c title="dp_translate 用法"
...
dp_translate(240, $ru, $var(out));
xlog("转换为 '$var(out)' \n");
...
```

### 导出的 MI 函数

#### dialplan:reload

更新转换规则，加载数据库信息。

```c
opensips-cli -x mi dialplan:reload
```

#### dialplan:translate

对输入字符串应用由拨号计划 ID 标识的转换规则。

```c
opensips-cli -x mi dialplan:translate 10 +40123456789
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
