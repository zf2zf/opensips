---
title: "opensips.cfg 文件模板化"
description: "OpenSIPS 3.0+ 版本为脚本编写者提供了通过通用预处理器传递 opensips.cfg 文件（包括它导入的任何其他文件）的完整支持。"
---

## 通用预处理支持

OpenSIPS 3.0+ 版本为脚本编写者提供了通过通用预处理器传递 *opensips.cfg* 文件（包括它导入的任何其他文件）的完整支持。这在 *opensips.cfg* 必须参数化（例如监听接口、端口、DB 连接器等）并以自动化方式部署到多个服务器的场景中非常有用。系统管理员可以使用 "-p `<cmdline>`"（预处理器）选项来实现这一点。例如：

```text

opensips -f opensips.cfg -p /bin/cat

```

... 这是 "-p" 选项的基本用法，通过向 "echo" 预处理器提供输入，该预处理器通过**标准输入**接收输入并通过**标准输出**镜像输出。从这里开始，选择适合部署需求的模板语言就足够了。一些基本的替换可以使用 *sed* 来完成：

```bash

opensips -f opensips.cfg -p "/bin/sed s/PRIVATE_IP/10.0.0.10/g"

```

## 常用模板语言及示例

以下是使用更高级模板语言处理 opensips.cfg 的示例，适用于目标环境需要复杂决策（启用/禁用功能的 if 语句、多个监听接口的 for 循环等）的场景。

### GNU m4

[GNU m4](https://www.gnu.org/software/m4/) 是一个简单的预处理器，学习曲线平缓，具有文本替换、if 语句和文件包含等最显著的功能。下面是一个与 *opensips.cfg* 集成的示例：

```c

listen = udp:PRIVATE_IP:5060
loadmodule "proto_udp.so"

```
**opensips.cfg.m4**

  

```text

divert(-1)
define(`PRIVATE_IP', `127.0.0.1')
divert(0)dnl

```
**env.m4**

  

... 我们使用以下命令启动 OpenSIPS，它会将 *opensips.cfg.m4* 管道传输到 **m4** 的标准输入，然后从其标准输出读取生成的文件：**

```text

opensips -f opensips.cfg.m4 -p "m4 env.m4 -"

```

### Jinja2

[Jinja2](http://jinja.pocoo.org/docs/2.10) 是一种现代模板语言，具有丰富的功能集，包括文本替换、if 语句、for 循环、大量过滤器、文件包含等。与 *m4* 不同，Jinja2 目前没有独立的二进制文件，而是通过 Python 包提供。下面是一种将其与 *opensips.cfg* 集成的方法：

  

首先，安装 **jinja2** Python 模块：**"pip install jinja2"**。接下来，准备文件：

  

```c

listen = udp:{{ private_ip }}:5060
loadmodule "proto_udp.so"

```
**opensips.cfg.j2**

  

```text

import sys
import json
from jinja2 import Template

t = Template("".join(sys.stdin.readlines()))

with open('env.json') as f:
    print(t.render(json.load(f)))

```
**opensips-preproc.py**

  

```text

{
    "private_ip": "127.0.0.1"
}

```
**env.json**

  

... 我们使用以下命令启动 OpenSIPS：

```text

opensips -f opensips.cfg.j2 -p "python opensips-preproc.py"

```

### Embedded Ruby

[Embedded Ruby (ERB)](https://ruby-doc.org/stdlib-2.6.1/libdoc/erb/rdoc/ERB.html) 为 Ruby 提供了一个易于使用、功能强大的模板系统。使用 ERB，可以将实际 Ruby 代码添加到任何纯文本文档中，以生成文档信息详情和/或流程控制。让我们看看它如何与 *opensips.cfg* 集成！

  

首先，安装 ERB 包（对于 Debian/Ubuntu：**"apt install ruby-ejs"**）。接下来，准备文件：

  

```c

listen = udp:<%= private_ip %>:5060
loadmodule "proto_udp.so"

```
**opensips.cfg.erb**

  

```text

#!/usr/bin/env ruby
require 'erb'
require './env.rb'

template = ERB.new($stdin.read, nil, '-')
$stdout.write template.result($erb_context)

```
**~/src/opensips-preproc.rb**

  

```text

$erb_context = binding
private_ip   = '127.0.0.1'

```
**env.rb**

  

... 现在使用以下命令启动 OpenSIPS：

```text

opensips -f opensips.cfg.erb -p "ruby opensips-preproc.rb"

```

## 调试预处理器输出

由于预处理的输出从不写入任何文件，而只是在每次运行时被 OpenSIPS 消费，脚本开发人员仍然可以通过使用预处理命令的包装脚本来可视化和调试生成的文件，如下所示：

```bash

#!/bin/bash
  
m4 env.m4 - | tee >(grep -v __OSSPP_ >/tmp/opensips.cfg)

```
**~/src/preprocessor.sh**

  

... 现在我们使用以下命令启动 OpenSIPS：

```text

opensips -f opensips.cfg.m4 -p ~/src/preprocessor.sh

```

  

相同的技巧可用于任何其他预处理器。
