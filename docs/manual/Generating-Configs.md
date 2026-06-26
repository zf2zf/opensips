---
title: "生成配置文件"
description: "使用 OpenSIPS GNU M4 模板创建住宅、中继和负载均衡器配置。"
---

OpenSIPS 在 `examples/templates/` 下提供随时可用的 GNU M4 配置模板：

* `residential.m4`
* `trunking.m4`
* `loadbalancer.m4`

它们作为共享示例安装在下：`$PREFIX/share/opensips/examples/templates/`。发行版包通常使用 `/usr/share/opensips/examples/templates/`。

每个模板以监听接口、数据库 URL、可选端点和功能开关的定义开始。使用模板前请编辑这些定义。功能开关接受 `yes` 或 `no`。

## 直接运行模板

使用 `-f` 选择模板，使用 `-p m4` 在 OpenSIPS 解析前对其进行预处理：

```bash
opensips -C -f examples/templates/residential.m4 -p m4
opensips -f examples/templates/residential.m4 -p m4
```

第一个命令检查生成的配置。第二个命令启动 OpenSIPS。GNU M4 必须安装并在 `PATH` 中可用。

对于已安装的发行版包，请从共享示例目录中使用模板：

```bash
opensips -f /usr/share/opensips/examples/templates/residential.m4 -p m4
```

## 创建独立配置文件

您可以将模板渲染到常规配置文件：

```bash
m4 examples/templates/residential.m4 > opensips.cfg
```

生成的文件不再需要预处理。根据需要编辑它，然后正常检查或启动它：

```bash
opensips -C -f opensips.cfg
opensips -f opensips.cfg
```

其他示例请参阅 `examples/templates/README.md`。
