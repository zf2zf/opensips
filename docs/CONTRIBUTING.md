<!-- AUTO-GENERATED from Makefile and INSTALL - DO NOT EDIT MANUALLY -->

# 参与 OpenSIPS 开发

感谢您对 OpenSIPS 项目的关注！本指南涵盖开发工作流程、构建命令和测试流程。

## 开发环境搭建

### 前置要求

| 依赖项 | 版本 | 备注 |
|--------|------|------|
| GCC/Clang | >= 4.x | 现代 C 编译器 |
| GNU Make | >= 3.79 | 构建工具 |
| Bison/Flex | - | 解析器生成 |
| OpenSSL | - | TLS 支持 |
| libsctp | - | SCTP 支持 |

### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/OpenSIPS/opensips.git
cd opensips

# 初始化（将 Makefile.conf.template 复制为 Makefile.conf）
make all

# 默认构建
make

# 启用 TLS 支持
make TLS=1 all

# 启用 SCTP 支持
make SCTP=1 all

# 调试模式构建
make mode=debug all

# 构建指定模块
make modules=modules/textops modules

# 跳过特定模块
make skip_modules="textops db_mysql" modules

# 包含额外模块
make include_modules="uri_radius" modules
```

## Makefile 目标参考

<!-- AUTO-GENERATED from Makefile -->

| 命令 | 说明 |
|------|------|
| `make all` | 构建 OpenSIPS 核心和所有模块 |
| `make modules` | 构建所有模块 |
| `make clean` | 清理构建产物 |
| `make proper` | 清理依赖项 |
| `make distclean` | 完全清理（与 proper 相同） |
| `make maintainer-clean` | 清理包括自动生成文件的所有内容 |
| `make install` | 安装 OpenSIPS 和模块 |
| `make install-cfg` | 安装配置文件 |
| `make modules-readme` | 为所有模块生成 README |
| `make modules-docbook` | 生成 DocBook 文档 |
| `make doxygen` | 生成 API 文档 |
| `make tar` | 创建源码压缩包 |
| `make bin` | 创建二进制分发包 |
| `make deb` | 创建 Debian 安装包 |
| `make TAGS` | 生成 etags/ctags |
| `make dbg` | 构建调试版本 |

<!-- END AUTO-GENERATED -->

## 测试

### 运行测试

```bash
# 运行单元测试（如已配置）
make test

# 使用 Coverity Scan 检查代码
#（需要 Coverity 集成）

# 静态分析
make ccover
```

### 代码质量门禁

- 所有代码必须通过静态分析（Coverity Scan）
- 编译器警告：`-Wall -Werror` 无警告
- 核心模块单元测试覆盖率：>= 80%

## 代码风格

OpenSIPS 使用标准 C 代码风格：

- C99 标准
- 4 空格缩进
- K&R 大括号风格
- 最大行长度：约 80 字符

## 提交变更

1. Fork 仓库
2. 创建功能分支：`git checkout -b feature/my-feature`
3. 编写测试后修改代码
4. 清晰描述提交信息：`git commit -m "模块: 简短描述"`
5. 推送并创建 Pull Request

### Pull Request 要求

- 至少一名维护者审核
- CI 必须通过（单元测试、静态分析）
- 核心修改：需要两名维护者审核

## 模块开发

每个模块应包含：

- README.md 使用文档
- 单元测试
- 示例配置（如适用）

```bash
# 为模块生成 README
make modules=modules/textops modules-readme
```

## 文档

- 用户文档：`docs/manual/`
- 模块文档：各模块的 `README.md`
- API 文档：通过 `make doxygen` 生成

## 获取帮助

- 用户邮件列表：users@lists.opensips.org
- 开发者邮件列表：devel@lists.opensips.org
- 问题追踪：GitHub Issues

## 许可证

OpenSIPS 采用 GPL v2 许可证。所有贡献必须与此许可证兼容。
