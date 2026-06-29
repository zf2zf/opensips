# OpenSIPS 脚本引擎架构设计解析

> 本文档深入分析 OpenSIPS 配置脚本引擎的设计原理，揭示其"配置即代码"架构的精妙之处。

## 目录

- [1. 概述](#1-概述)
- [2. 核心设计思想](#2-核心设计思想)
- [3. 配置脚本的解析流程](#3-配置脚本的解析流程)
- [4. 语法树节点设计](#4-语法树节点设计)
- [5. 模块函数注册机制](#5-模块函数注册机制)
- [6. 路由块的多态设计](#6-路由块的多态设计)
- [7. 运行时执行引擎](#7-运行时执行引擎)
- [8. 设计优势总结](#8-设计优势总结)

---

## 1. 概述

OpenSIPS 是一个高性能、可扩展的 SIP 代理服务器。其最显著的特性之一是**配置脚本驱动**的设计：

```
# 示例：简单的 SIP 代理配置
route {
    if (!mf_process_maxfwd_header(10)) {
        send_reply(483, "Too Many Hops");
        exit;
    }

    if (is_method("REGISTER")) {
        save("location");
        exit;
    }

    if (!lookup("location")) {
        t_reply(404, "Not Found");
        exit;
    }

    route(relay);
}
```

这种设计允许用户通过配置文件实现复杂的 SIP 路由逻辑，而无需修改核心 C 代码。

---

## 2. 核心设计思想

OpenSIPS 将复杂的 SIP 代理逻辑抽象为 **声明式脚本配置**，采用"配置即代码"的理念。

### 三层分离架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      opensips.cfg (文本配置)                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    cfg.lex (词法分析器)                          │
│                    Flex 词法分析 · 识别 token                    │
│                    状态机: INITIAL_S, COMMENT_S, STRING_S       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    cfg.y (语法分析器)                             │
│                    Bison 语法分析 · 构建语法树                    │
│                    调用 find_cmd_export_t() 解析函数             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    route.c / action.c (运行时引擎)               │
│                    执行语法树中的每个 action                     │
│                    run_top_route() → run_actions() → do_action() │
└─────────────────────────────────────────────────────────────────┘
```

### 设计原则

| 原则 | 说明 |
|------|------|
| **声明式语义** | 用户描述"做什么"而非"怎么做" |
| **松耦合** | 模块独立，通过导出表与核心解耦 |
| **运行时灵活性** | 支持热重载、动态变量、条件分支 |
| **类型安全** | 参数自动类型转换和验证 |

---

## 3. 配置脚本的解析流程

### 3.1 词法分析 (cfg.lex)

Flex 词法分析器识别以下 token 类型：

- **关键字**: `route`, `if`, `else`, `drop`, `exit`, `return`, `while`, `for_each`
- **标识符**: 函数名、模块名、变量名
- **字符串**: `"text"`, `'text'`
- **数字**: 整型、浮点型
- **变量**: `$fu`, `$rd`, `$rU`, `$du`, `$var(name)`, `$avp(name)`
- **操作符**: `==`, `!=`, `=~`, `&&`, `||`, `!`

### 3.2 语法分析 (cfg.y)

Bison 语法分析器将 token 流转换为语法树。

**核心语法规则示例：**

```yacc
// 路由块定义
route_stm:
    ROUTE LBRACE actions RBRACE
    { sroutes->request[DEFAULT_RT].name = "0";
      sroutes->request[DEFAULT_RT].a = $3; }

// 条件语句
if_stm:
    IF LPAREN expr RPAREN LBRACE actions RBRACE
    { $$ = mk_action(IF_T, 3, $3, $6, 0); }
  | IF LPAREN expr RPAREN LBRACE actions RBRACE ELSE LBRACE actions RBRACE
    { $$ = mk_action(IF_T, 3, $3, $6, $10); }

// 模块函数调用
func:
    ID LPAREN func_params RPAREN
    { cmd = find_cmd_export_t($1, current_route_type);
      $$ = mk_action(CMD_T, 1, cmd); }
```

### 3.3 Fixup 阶段

解析后的语法树需要进一步处理：

```c
// 修复阶段工作
fix_rls() {
    // 1. 解析 route() 调用中的路由名称引用
    // 2. 解析表达式中的变量（$var、$avp 等）
    // 3. 验证函数参数个数和类型
    // 4. 建立子路由调用关系
}
```

---

## 4. 语法树节点设计

配置脚本被解析成 `action` 结构链表（`route_struct.h`）：

```c
struct action {
    int type;                           // 动作类型
    action_elem_t elem[MAX_ACTION_ELEMENTS]; // 最多 9 个参数
    int line;                           // 源码行号（用于错误报告）
    char *file;                         // 源文件名
    struct action* next;                // 链表链接
};
```

### 4.1 动作类型枚举

| 类型 | 含义 | 示例 |
|------|------|------|
| `CMD_T` | 模块函数调用 | `save("location")` |
| `IF_T` | 条件分支 | `if (has_totag()) { ... }` |
| `ELSE_T` | 否则分支 | `else { ... }` |
| `ROUTE_T` | 子路由调用 | `route(relay)` |
| `DROP_T` | 丢弃消息 | `drop` |
| `EXIT_T` | 退出路由 | `exit` |
| `RETURN_T` | 返回 | `return` |
| `FOR_T` / `WHILE_T` | 循环结构 | `while() { }` |
| `SWITCH_T` / `CASE_T` | 多分支 | `switch() { case: }` |
| `ASSIGN_T` | 赋值操作 | `$var(x) = 1` |
| `LOG_T` | 日志输出 | `xlog("...")` |
| `ERROR_T` | 错误响应 | `send_reply(500, ...)` |

### 4.2 表达式结构

```c
enum { EXP_T=1, ELEM_T };  // 表达式类型

struct expr {
    int type;       // EXP_T 或 ELEM_T
    int op;         // 操作符
    operand_t left; // 左操作数
    operand_t right; // 右操作数
};

// 支持的操作符
enum {
    AND_OP,          // && 逻辑与
    OR_OP,           // || 逻辑或
    NOT_OP,          // !  逻辑非
    EQUAL_OP,        // == 相等
    DIFF_OP,         // != 不等
    MATCH_OP,        // =~ 正则匹配
    GT_OP,           // >  大于
    LT_OP,           // <  小于
    GTE_OP,          // >= 大于等于
    LTE_OP           // <= 小于等于
};
```

### 4.3 示例：配置到语法树的转换

```
原始配置:
    if (has_totag()) {
        route(relay);
    } else {
        send_reply(404, "Not here");
    }

语法树:
    IF_T
    ├── elem[0]: EXP_T (has_totag() > 0)
    ├── elem[1]: actions
    │   └── ROUTE_T → "relay"
    └── elem[2]: actions
        └── ERROR_T → 404, "Not here"
```

---

## 5. 模块函数注册机制

这是 OpenSIPS 脚本系统最精妙的设计。

### 5.1 模块导出结构

模块通过 `cmd_export_t` 结构导出函数（`cmds.h`）：

```c
struct cmd_export_ {
    const char* name;           // 函数名：如 "save", "lookup", "is_method"
    cmd_function function;      // 函数指针（C 语言函数）
    struct cmd_param params[];  // 参数描述数组
    int flags;                  // 允许使用的路由类型
};

// 参数描述
struct cmd_param {
    param_type_t type;    // 参数类型
    fixup_function_t fixup;   // 参数修复函数（可选）
    free_function_t free;     // 内存释放函数（可选）
};

// 参数类型
#define CMD_PARAM_INT        (1<<0)   // 整型
#define CMD_PARAM_STR        (1<<1)   // 字符串
#define CMD_PARAM_VAR        (1<<2)   // 变量（如 $var）
#define CMD_PARAM_REGEX      (1<<3)   // 正则表达式
#define CMD_PARAM_OPT        (1<<4)   // 可选参数
```

### 5.2 模块加载流程

```c
// 1. dlopen 加载共享库
int load_module(char* name) {
    char path[256];
    void* handle;

    // 构建完整路径
    snprintf(path, sizeof(path), "%s/%s.so", mpath, name);

    // 动态加载共享库
    handle = dlopen(path, RTLD_NOW);
    if (!handle) {
        LM_ERR("failed to load module: %s\n", dlerror());
        return -1;
    }

    // 获取导出符号
    exports = dlsym(handle, DLSYM_PREFIX "exports");
    if (!exports) {
        LM_ERR("module %s does not export 'exports' symbol\n", name);
        dlclose(handle);
        return -1;
    }

    // 注册模块
    return register_module(exports, path, handle);
}
```

### 5.3 函数查找流程

当解析器遇到函数调用时，通过 `find_cmd_export_t()` 查找：

```c
const cmd_export_t* find_cmd_export_t(const char* name, int flags) {
    const cmd_export_t* cmd;

    // 1. 先查核心命令（内置函数）
    cmd = find_core_cmd_export_t(name, flags);
    if (cmd) return cmd;

    // 2. 再查各模块导出的命令
    for (module = modules; module; module = module->next) {
        for (cmd = module->exports->commands; cmd->name; cmd++) {
            if (strcmp(name, cmd->name) == 0 &&
                (cmd->flags & flags) == flags) {
                return cmd;
            }
        }
    }

    return NULL;  // 未找到
}
```

### 5.4 参数 Fixup 机制

参数从配置文本到 C 函数的转换通过 fixup 函数完成：

```c
// registrar 模块导出的 save 函数
static const cmd_export_t commands[] = {
    {"save",       save,      // 函数指针
     {{STR_PARAM, fixup_save_location, free_fixup},  // 第1个参数
      {0, 0, 0}},                                     // 结束
     REQUEST_ROUTE},  // 只能在 request_route 中使用
    {0}
};

// fixup 函数示例：将字符串 "location" 转换为模块内部标识符
int fixup_save_location(void** param) {
    str tab = str_init((char*)*param);

    if (modulename_to_idx(tab, &idx) < 0) {
        LM_ERR("unknown location table '%.*s'\n", tab.len, tab.s);
        return -1;
    }

    // 释放原始字符串，存储转换后的索引
    pkg_free(*param);
    *param = (void*)(long)idx;
    return 0;
}
```

### 5.5 模块注册示例

```c
// registrar 模块实现 (registrar.c)

// 1. 定义导出函数
static int save(struct sip_msg* msg, char* tab_idx) {
    // actual implementation
    return save_to_location(msg, (int)(long)tab_idx);
}

// 2. 导出声明
static const cmd_export_t commands[] = {
    {
        "save",                    // 函数名
        save,                      // 函数指针
        {{STR_PARAM, fixup_save_location, free_fixup}, {0,0,0}},
        REQUEST_ROUTE             // 只允许在请求路由中使用
    },
    {
        "lookup",
        lookup,
        {{STR_PARAM, fixup_lookup_location, free_fixup},
         {CMD_PARAM_OPT, fixup_ignore, 0},
         {0,0,0}},
        REQUEST_ROUTE
    },
    {0}  // 结束标记
};

// 3. 模块信息
const struct module_exports exports = {
    "registrar",      // 模块名
    commands,         // 导出的命令
    params,           // 模块参数
    mod_reg_1,        // 注册回调
    mod_init_1,       // 初始化回调
    0,                // 响应回调
    destroy_function  // 销毁回调
};
```

---

## 6. 路由块的多态设计

### 6.1 路由类型定义

OpenSIPS 定义了多种路由块类型，各有独立的执行时机（`route.h`）：

```c
enum route_types {
    REQUEST_ROUTE = 1,     // 主请求路由
    FAILURE_ROUTE = 2,     // 失败路由
    ONREPLY_ROUTE = 4,     // 响应路由
    BRANCH_ROUTE = 8,      // 分支路由
    ERROR_ROUTE = 16,      // 错误路由
    LOCAL_ROUTE = 32,      // 本地路由
    STARTUP_ROUTE = 64,    // 启动路由
    TIMER_ROUTE = 128,     // 定时器路由
    EVENT_ROUTE = 256      // 事件路由
};
```

### 6.2 路由块类型详解

| 路由类型 | 定义语法 | 执行时机 | 典型用途 |
|---------|---------|---------|---------|
| `request_route` | `route { }` | 收到 SIP 请求消息 | 主业务逻辑、用户认证、呼叫路由 |
| `onreply_route` | `onreply { }` | 收到 SIP 响应消息 | NAT 穿透、媒体协商、状态记录 |
| `failure_route` | `failure_route[name] { }` | 事务失败（3xx/4xx/5xx） | 呼叫失败处理、语音邮件、呼叫转移 |
| `branch_route` | `branch_route[name] { }` | 创建分支前（同时振铃） | 呼叫分发策略、负载均衡 |
| `error_route` | `error_route { }` | 脚本执行错误 | 错误日志、告警通知 |
| `local_route` | `local_route { }` | 生成新请求（如 BYE） | 请求修改、添加自定义头 |
| `startup_route` | `startup_route { }` | OpenSIPS 启动时 | 初始化任务、缓存预热 |
| `timer_route` | `timer_route[name, interval] { }` | 定时器触发 | 定期任务、清理过期数据 |
| `event_route` | `event_route[name] { }` | 事件触发 | 外部集成、实时监控 |

### 6.3 路由块数据结构

```c
struct script_route {
    char *name;           // 路由名称
    struct action *a;      // 动作链表（语法树）
};

struct os_script_routes {
    struct script_route request[100];       // 100 个请求路由
    struct script_route onreply[100];       // 100 个回复路由
    struct script_route failure[100];       // 100 个失败路由
    struct script_route branch[100];        // 100 个分支路由
    struct script_route local;              // 本地路由（单例）
    struct script_route error;              // 错误路由（单例）
    struct script_route startup;            // 启动路由（单例）
    struct script_timer_route timer[16];    // 16 个定时器路由
    struct script_route event[EVENT_RT_NO]; // 事件路由
    unsigned int version;                   // 脚本版本号（reload 用）
};
```

### 6.4 路由执行时机图

```
SIP 请求消息
    │
    ▼
┌─────────────────────────────┐
│    request_route            │ ←── 主入口
│    (route { })              │
└──────────────┬──────────────┘
               │
               ├──→ 正常流程 ───────────────────────┐
               │                                     │
               │    ┌─────────────────────┐          │
               │    │  成功响应 (200 OK)  │          │
               │    └─────────────────────┘          │
               │                                     │
               ├──→ 分支创建时 ───→ branch_route ────┤
               │                                     │
               ├──→ 收到响应时 ───→ onreply_route ──┤
               │                                     │
               └──→ 事务失败 ────→ failure_route ───┘
                               (3xx/4xx/5xx)
```

---

## 7. 运行时执行引擎

### 7.1 执行入口

```c
// route.c
int run_top_route(struct script_route sr, struct sip_msg* msg) {
    int bk_action_flags;
    int ret;

    // 保存当前上下文
    bk_action_flags = action_flags;
    action_flags = 0;

    // 初始化错误信息
    init_err_info();

    // 设置路由栈（用于递归跟踪）
    route_stack[route_stack_start] = sr.name;

    // 执行动作链表
    run_actions(sr.a, msg);

    // 获取执行结果
    ret = action_flags;

    // 恢复上下文
    action_flags = bk_action_flags;

    return ret;
}
```

### 7.2 动作链表执行

```c
// action.c
static int run_actions(struct action* a, struct sip_msg* msg) {
    int ret;

    if (a == NULL)
        return 1;

    for (; a; a = a->next) {
        ret = do_action(a, msg);

        // 检查是否需要终止执行
        if (ret < 0) {
            LM_ERR("error in action #%d\n", a->type);
            return ret;
        }
        if (action_flags & ACT_FL_DROP) {
            // DROP 标志被设置，停止执行
            return 0;
        }
    }

    return 1;
}
```

### 7.3 动作分发核心

```c
// action.c - do_action()
int do_action(struct action* a, struct sip_msg* msg) {
    int ret;
    const cmd_export_t* cmd;

    switch(a->type) {

    // ========== 模块函数调用 ==========
    case CMD_T:
        if (a->elem[0].type != CMD_ST) {
            LM_ALERT("BUG: malformed CMD_T action\n");
            break;
        }

        cmd = (const cmd_export_t*)a->elem[0].u.data_const;

        // 获取 fixup 后的参数
        ret = get_cmd_fixups(msg, cmd->params, a->elem, cmdp, tmp_vals);
        if (ret < 0) {
            LM_ERR("Failed to get fixups for command <%s>\n", cmd->name);
            break;
        }

        // 调用模块函数
        ret = cmd->function(msg, cmdp[0], cmdp[1], cmdp[2],
                           cmdp[3], cmdp[4], cmdp[5], cmdp[6], cmdp[7]);

        // 释放 fixup
        free_cmd_fixups(cmd->params, a->elem, cmdp);
        break;

    // ========== 子路由调用 ==========
    case ROUTE_T:
        {
            str sval;
            int ridx;

            sval = a->elem[0].u.str;
            ridx = get_script_route_ID_by_name_str(&sval,
                sroutes->request, RT_NO);
            if (ridx < 0) {
                LM_ERR("route '%.*s' not found\n", sval.len, sval.s);
                break;
            }

            // 递归执行子路由
            ret = run_actions(sroutes->request[ridx].a, msg);
        }
        break;

    // ========== 条件分支 ==========
    case IF_T:
        {
            long long int v;
            struct action* then_b;
            struct action* else_b;

            // 求值条件表达式
            v = eval_expr((struct expr*)a->elem[0].u.data, msg, 0);

            if (v > 0) {
                // 条件为真，执行 then 分支
                then_b = (struct action*)a->elem[1].u.data;
                ret = run_actions(then_b, msg);
            } else {
                // 条件为假，执行 else 分支（如有）
                else_b = (struct action*)a->elem[2].u.data;
                if (else_b)
                    ret = run_actions(else_b, msg);
            }
        }
        break;

    // ========== 丢弃消息 ==========
    case DROP_T:
        ret = 0;
        action_flags |= ACT_FL_DROP;  // 设置 DROP 标志
        break;

    // ========== 退出路由 ==========
    case EXIT_T:
        ret = 0;
        action_flags |= ACT_FL_DROP;
        break;

    // ========== 返回值 ==========
    case RETURN_T:
        ret = (int)(long)a->elem[0].u.data;
        action_flags |= ACT_FL_RETURN;
        break;

    // ========== 赋值操作 ==========
    case ASSIGN_T:
    case EQ_T:
        ret = do_assign(a, msg);
        break;

    // ========== 日志 ==========
    case LOG_T:
        do_log(a->elem[0].u.data, msg);
        ret = 1;
        break;

    // ========== 错误响应 ==========
    case ERROR_T:
        send_reply(...);
        ret = 0;
        break;

    // ... 其他类型
    }
```

### 7.4 表达式求值

```c
// expr.c - eval_expr()
static long long int eval_expr(struct expr* e, struct sip_msg* msg, int log_level) {
    long long int v1, v2;

    if (e->type == ELEM_T) {
        // 基本元素：变量、常量、函数调用
        return eval_elem(e, msg);
    }

    // 复合表达式
    v1 = eval_expr(e->left, msg, log_level);

    switch(e->op) {
    case AND_OP:
        // 短路求值
        if (v1 == 0) return 0;
        v2 = eval_expr(e->right, msg, log_level);
        return (v2 != 0) ? 1 : 0;

    case OR_OP:
        // 短路求值
        if (v1 != 0) return 1;
        v2 = eval_expr(e->right, msg, log_level);
        return (v2 != 0) ? 1 : 0;

    case EQUAL_OP:
        v2 = eval_expr(e->right, msg, log_level);
        return (v1 == v2) ? 1 : 0;

    case MATCH_OP:
        // 正则匹配
        v2 = eval_expr(e->right, msg, log_level);
        return regex_match(v1, v2);

    // ... 其他操作符
    }
}
```

### 7.5 变量系统

OpenSIPS 支持多种变量类型：

| 变量类型 | 语法 | 说明 | 示例 |
|---------|------|------|------|
| 伪变量 | `$name` | SIP 消息属性 | `$fu` (From URI), `$rd` (RURI Domain) |
| 脚本变量 | `$var(name)` | 用户定义 | `$var(x)`, `$var(dst)` |
| AVP 变量 | `$avp(name)` | 持久化数据 | `$avp(ip)` |
| 章节变量 | `$hdr(name)` | SIP 头域 | `$hdr(CSeq)` |
| 超时变量 | `$T(name)` | 时间相关 | `$T_reply` |

---

## 8. 设计优势总结

### 8.1 松耦合架构

```
┌──────────────────────────────────────────────────────────────┐
│                          核心引擎                            │
│  route.c · action.c · expr.c · route_struct.h              │
└──────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │   cmd_export_t    │  ←── 标准化接口
                    │   模块导出表       │
                    └─────────┬─────────┘
                              │
        ┌─────────┬───────────┼───────────┬─────────┐
        ▼         ▼           ▼           ▼         ▼
    registrar   usrloc      tm.so       acc.so   proto_udp
     模块        模块        事务模块    计费模块   协议模块
```

**优势：**
- 新增模块无需修改核心代码
- 模块可独立编译、加载、卸载
- 模块间无直接依赖，通过核心通信

### 8.2 热重载支持

```c
// opensipsctl 交互
$ opensipsctl fifo debug
$ opensipsctl fifo version
$ opensipsctl fifo ps

// 脚本重载
$ opensipsctl fifo refresh
// 触发：sroutes.version++，新请求使用新脚本
```

### 8.3 性能特性

| 特性 | 说明 |
|------|------|
| **预编译** | 配置在启动时编译为语法树，运行无需解析 |
| **内存池** | 语法树使用共享内存池，高效分配 |
| **批量分发** | `run_actions()` 批量执行减少函数调用开销 |
| **内联优化** | 简单条件表达式内联展开 |

### 8.4 安全性

```c
// 1. 预加载路由检测
if (loose_route()) {
    send_reply(403, "Preload Route denied");
    exit;
}

// 2. 开放中继防护
if (!is_myself("$rd")) {
    send_reply(403, "Relay Forbidden");
    exit;
}

// 3. 最大转发次数限制
if (!mf_process_maxfwd_header(10)) {
    send_reply(483, "Too Many Hops");
    exit;
}
```

---

## 附录：关键源文件索引

| 文件 | 路径 | 功能 |
|------|------|------|
| cfg.lex | `/cfg.lex` | Flex 词法分析器 |
| cfg.y | `/cfg.y` | Bison 语法分析器 |
| cfg_pp.c | `/cfg_pp.c` | 配置预处理器 |
| route.c | `/route.c` | 路由块执行引擎 |
| route.h | `/route.h` | 路由块数据结构 |
| action.c | `/action.c` | 动作执行器 |
| action.h | `/action.h` | 动作类型定义 |
| route_struct.h | `/route_struct.h` | 语法树节点结构 |
| sr_module.c | `/sr_module.c` | 模块加载与注册 |
| sr_module.h | `/sr_module.h` | 模块导出结构 |
| cmds.h | `/cmds.h` | 命令导出定义 |
| mod_fix.c | `/mod_fix.c` | 参数修复函数 |
| modparam.c | `/modparam.c` | 模块参数实现 |
| expr.c | `/expr.c` | 表达式求值 |
| parser/msg_parser.h | `/parser/msg_parser.h` | SIP 消息解析 |

---

*文档版本：1.0*
*最后更新：2026-06-29*
