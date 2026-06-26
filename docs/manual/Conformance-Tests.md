---
title: "一致性测试"
description: "一致性/合规性测试用于验证 OpenSIPS 在特定场景下的行为。目标是确保对 OpenSIPS 代码的任何更改（无论是由于错误修复还是新功能）都按照预期规范运行，且没有回归。"
---

一致性/合规性测试用于验证 OpenSIPS 在特定场景下的行为。目标是确保对 OpenSIPS 代码的任何更改（无论是由于错误修复还是新功能）都按照预期规范运行，且没有回归。

为此，我们开发了一套测试集，在不同场景下使用不同的 SIP 流程执行 OpenSIPS，并验证所有相关组件（OpenSIPS 以及数据库、配置、SIP UA）都能正确互操作，其行为符合预期。

---

## 设置

第一个要求是安装 [SIPssert](https://github.com/OpenSIPS/SIPssert)——一个能够编排复杂一致性场景并验证其执行的测试框架。你可以按照项目页面上的[安装说明](https://github.com/OpenSIPS/SIPssert#installation)进行操作。

接下来，我们需要获取可用的测试。对于初始设置，我们需要克隆仓库：
```text

git clone git@github.com:OpenSIPS/sipssert-opensips-tests.git

```

如果你要针对稳定版本，请确保指定你需要的 OpenSIPS 分支/版本：
```text

git clone -b 4.1 git@github.com:OpenSIPS/sipssert-opensips-tests.git

```

导航到测试目录。如果仓库之前已克隆，请确保通过运行以下命令保持更新：
```text

git pull --rebase

```

---

## 测试

一旦 SIPssert 就位且测试仓库已克隆，你需要导航到测试仓库并运行：
```text

sipssert *

```

此命令将使用默认配置运行所有可用的测试集。如果你想仅测试特定的测试集或特定的测试，可以向 `sipssert` 工具提供额外的参数。更多信息请参阅[说明](https://github.com/OpenSIPS/SIPssert#usage)页面。

---

## 开发

开发新测试总是有空间的，无论是确保旧代码行为正确，还是证明它不正确——任何贡献都欢迎。因此，如果你有想要包含的新测试，请随时在项目的[追踪器](https://github.com/OpenSIPS/sipssert-opensips-tests/pulls)上打开拉取请求。
