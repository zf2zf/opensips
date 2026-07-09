# OpenSIPS 脚本变量参考手册

本文档整理了 `opensips_proxy.cfg` 配置文件中可以使用的所有变量，包括伪变量、AVP、头域访问、XML 解析等。

---

## 目录

1. [核心伪变量（Pseudovariables）](#一核心伪变量pseudovariables)
2. [头域访问](#二头域访问-hdrname)
3. [AVP 变量](#三avp-变量attribute-value-pair)
4. [临时变量](#四临时变量-varname)
5. [XML 解析变量](#五xml-解析变量-xmlname)
6. [转换与变换](#六转换与变换transformations)
7. [特殊变量](#七特殊变量)
8. [典型使用场景](#八典型使用场景)
9. [常用判断条件](#九常用判断条件)
10. [模块返回值](#十模块返回值)

---

## 一、核心伪变量（Pseudovariables）

伪变量是 OpenSIPS 脚本中最常用的变量类型，用于访问 SIP 消息的各个组成部分。

### 1.1 SIP 消息基本元素

| 变量 | 含义 | 示例值 |
|:-----|:-----|:-------|
| `$rm` | 当前请求方法 | `INVITE`, `REGISTER`, `MESSAGE`, `ACK`, `BYE`, `CANCEL` |
| `$ru` | 请求 URI (RURI)，完整的目标 SIP 地址 | `sip:123456@20.20.136.66:5060` |
| `$rd` | RURI 中的域名/主机部分 | `20.20.136.66` 或 `example.com` |
| `$rU` | RURI 中的用户名部分 | `123456` |
| `$tu` | To 头域 URI | `sip:device_id@platform.com` |
| `$td` | To 头域的域名 | `platform.com` |
| `$tU` | To 头域的用户名 | `device_id` |
| `$fu` | From 头域 URI | `sip:platform.com` |
| `$fd` | From 头域的域名 | `platform.com` |
| `$fU` | From 头域的用户名 | `platform` |
| `$cs` | CSeq 序列号 | `1`, `9999` |
| `$ci` | Call-ID 标识符 | `a1b2c3d4e5f6@192.168.1.1` |

### 1.2 网络地址变量

| 变量 | 含义 | 示例值 |
|:-----|:-----|:-------|
| `$si` | 消息源 IP 地址（发送方） | `192.168.1.100` |
| `$sp` | 消息源端口 | `5060`, `5080` |
| `$di` | 消息目的 IP 地址 | `20.20.136.66` |
| `$dp` | 消息目的端口 | `5060` |
| `$socket_in(ip)` | 接收消息的网卡 IP | `20.20.136.66` |
| `$socket_in(port)` | 接收消息的端口 | `5060` |

### 1.3 响应/状态变量

| 变量 | 含义 | 示例值 |
|:-----|:-----|:-------|
| `$rs` | 响应状态码（reply status） | `200`, `404`, `503` |
| `$rc` | 上一个操作/函数的返回码（0=失败，1=成功，-1=错误） | `0`, `1`, `-1` |

### 1.4 消息体变量

| 变量 | 含义 |
|:-----|:-----|
| `$mb` | 完整消息缓冲区（包含头和体） |
| `$rb` | 请求体或响应体（SDP/XML 内容） |
| `$ct` | Contact 头域的 URI |

### 1.5 对话/事务相关

| 变量 | 含义 |
|:-----|:-----|
| `$T_branch_idx` | 当前分支索引 |
| `$T_reply_code` | 事务的响应码 |

---

## 二、头域访问 `$hdr(name)`

使用 `$hdr(Header-Name)` 语法访问任意 SIP 头字段。

### 2.1 常用头域

| 用法 | 含义 |
|:-----|:-----|
| `$hdr(From)` | From 头域完整内容 |
| `$hdr(To)` | To 头域完整内容 |
| `$hdr(Via)` | Via 头域完整内容 |
| `$hdr(Call-ID)` | Call-ID 头域 |
| `$hdr(Contact)` | Contact 头域 |
| `$hdr(Expires)` | Expires 头域（注册有效期） |
| `$hdr(CSeq)` | CSeq 头域 |
| `$hdr(Record-Route)` | Record-Route 头域 |
| `$hdr(Route)` | Route 头域 |
| `$hdr(Content-Type)` | Content-Type 头域 |

### 2.2 示例

```opensips
xlog("L_INFO", "Contact: $hdr(Contact)\n");
xlog("L_INFO", "Expires: $hdr(Expires)\n");
xlog("L_INFO", "Call-ID: $hdr(Call-ID)\n");
```

---

## 三、AVP 变量（Attribute-Value Pair）

AVP 用于存储临时数据，贯穿整个 SIP 事务生命周期。格式为 `$avp(name)`。

### 3.1 本脚本中使用的 AVP 变量

| AVP 变量 | 用途 | 存储内容示例 |
|:---------|:-----|:-------------|
| `$avp(src_ip)` | 保存 REGISTER 来源 IP | `192.168.1.100` |
| `$avp(src_port)` | 保存 REGISTER 来源端口 | `5060` |
| `$avp(expires_hdr)` | 保存 Expires 头值（判断注销） | `0`（注销）, `3600`（注册） |
| `$avp(tmp_id)` | 临时设备 ID | Catalog 解析中的 DeviceID |
| `$avp(tmp_parent)` | 临时父 ID | Catalog 解析中的 ParentID |
| `$avp(chan_id)` | 通道 ID | `34010000001320000001` |
| `$avp(parent_id)` | 父设备 ID | `34010000001110000001` |
| `$avp(chan_name)` | 通道名称 | `Camera-01` |
| `$avp(chan_manufacturer)` | 通道厂商 | `Hikvision` |
| `$avp(chan_model)` | 通道型号 | `DS-2CD3T86` |
| `$avp(recorder_domain)` | 录像机域名（lookup 用） | `platform.com` |
| `$avp(recorder_contact)` | 录像机 SIP Contact | `sip:34010000001110000001@192.168.1.100:5060` |
| `$avp(channel_ua)` | 通道 User-Agent 字符串 | `Hikvision DS-2CD3T86 (Camera-01)` |
| `$avp(channel_attr)` | 通道属性（存储父设备 AOR） | `parent=sip:parent_id@domain` |
| `$avp(orig_ruri)` | 保存原始 RURI | 设备 INVITE 的原始 RURI |
| `$avp(d_c)` | SDP 连接地址 | `192.168.1.100` |
| `$avp(d_m)` | SDP 媒体端口 | `3288` |
| `$avp(d_set)` | SDP setup 属性 | `active` |
| `$avp(d_con)` | SDP connection 属性 | `new` |
| `$avp(d_dir)` | SDP 方向属性 | `sendonly`, `sendrecv` |

### 3.2 使用示例

```opensips
# 保存源地址
$avp(src_ip) = $si;
$avp(src_port) = $sp;

# 读取 AVP
xlog("L_INFO", "src_ip=$avp(src_ip) src_port=$avp(src_port)\n");

# 判断条件中使用
if ($avp(expires_hdr) == "0") {
    # 设备注销处理
}
```

---

## 四、临时变量 `$var(name)`

用于数值计算和临时存储，**仅在当前脚本执行期间有效**，事务结束即销毁。

| 变量 | 用途 | 示例 |
|:-----|:-----|:-----|
| `$var(i)` | 循环计数器 | `$var(i) = $var(i) + 1` |
| `$var(cnt)` | 数量统计 | `$var(cnt) = $var(cnt) + 1` |
| `$var(result)` | 存储计算结果 | - |

### 示例

```opensips
$var(i) = 0;
$var(cnt) = 0;

while ($var(i) < 256) {
    # 处理逻辑
    $var(i) = $var(i) + 1;
}
```

---

## 五、XML 解析变量 `$xml(name)`

用于解析 SIP 消息体中的 XML 内容（GB28181 Catalog 响应）。

### 5.1 基本用法

| 用法 | 含义 |
|:-----|:-----|
| `$xml(cat)` | 设置/获取 XML 文档 |
| `$xml(path)` | 访问 XML 节点 |

### 5.2 XPath 路径示例

| 路径 | 含义 |
|:-----|:-----|
| `$xml(cat/Response/DeviceList/Item[0]/DeviceID.val)` | 第1个设备的 DeviceID |
| `$xml(cat/Response/DeviceList/Item[$var(i)]/DeviceID.val)` | 第 i 个设备的 DeviceID |
| `$xml(cat/Response/DeviceList/Item[$var(i)]/Name.val)` | 第 i 个设备的名称 |

### 5.3 示例

```opensips
# 加载 XML 文档
$xml(cat) = $rb;

# 读取节点值
$avp(chan_id) = $xml(cat/Response/DeviceList/Item[$var(i)]/DeviceID.val);
$avp(chan_name) = $xml(cat/Response/DeviceList/Item[$var(i)]/Name.val);
$avp(parent_id) = $xml(cat/Response/DeviceList/Item[$var(i)]/ParentID.val);

# 释放 XML 变量
$xml(cat) = NULL;
```

---

## 六、转换与变换（Transformations）

使用 `$(var{transform})` 语法对变量值进行转换。

### 6.1 字符串变换

| 变换 | 含义 | 示例结果 |
|:-----|:-----|:---------|
| `{s.len}` | 获取字符串长度 | `$(avp(chan_id){s.len})` → `20` |
| `{s.select,i,j}` | 选择子字符串（逗号分隔） | `$(mb{s.select,0,60})` 取前60字符 |
| `{s.encode.hexa}` | 转换为十六进制 | - |
| `{s.decode.hexa}` | 十六进制解码 | - |
| `{s.int}` | 转换为整数 | - |

### 6.2 正则替换变换

使用 `{re.subst, /pattern/replacement/}` 进行正则替换。

| 示例 | 含义 |
|:-----|:-----|
| `$(rb{re.subst, /c=IN IP4 ([0-9.]+)/\1/})` | 从 SDP 提取 IP 地址 |
| `$(rb{re.subst, /m=video ([0-9]+)/\1/})` | 从 SDP 提取视频端口 |
| `$(rb{re.subst, /a=setup:([a-z]+)/\1/})` | 从 SDP 提取 setup 属性 |
| `$(rb{re.subst, /a=connection:([a-z]+)/\1/})` | 从 SDP 提取 connection 属性 |

### 6.3 正则匹配测试

使用 `=~` 进行正则匹配测试。

```opensips
# 判断 From 是否为 IP:Port 格式
if (!($fu =~ "@[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+")) {
    # 不是 IP:Port 格式
}

# 判断用户名是否为纯数字
if ($rU =~ "^[0-9]+$") {
    # 是纯数字
}
```

---

## 七、特殊变量

| 变量 | 含义 | 取值 |
|:-----|:-----|:-----|
| `$rc` | 上一个条件/函数执行结果 | `1`=真/成功, `0`=假/失败, `-1`=错误 |
| `$T_branch_idx` | 当前分支索引 | `0`, `1`, `2`, ... |
| `$br` | Branch URI（分支目标） | - |

---

## 八、典型使用场景

### 8.1 注册处理

```opensips
route[register_handler] {
    # 保存源地址
    $avp(src_ip) = $si;
    $avp(src_port) = $sp;

    # 判断是否是注销请求
    $avp(expires_hdr) = $hdr(Expires);
    if ($avp(expires_hdr) == "0") {
        xlog("L_INFO", "REGISTER: device unregistering\n");
        sql_query("DELETE FROM location WHERE attr LIKE '%' || '$tu' || '%'");
    }

    # 保存到 usrloc
    save("location", "no-reply");

    # 转发
    if (ds_select_dst(1, 0, "f")) {
        t_relay();
    }
}
```

### 8.2 INVITE 处理日志

```opensips
route[invite_handler] {
    xlog("L_INFO", "INVITE-IN: method=$rm callid=$ci\n");
    xlog("L_INFO", "INVITE-IN: From=$fu To=$tu\n");
    xlog("L_INFO", "INVITE-IN: src_ip=$si:$sp dst_ip=$di:$dp\n");
    xlog("L_INFO", "INVITE-IN: ruri=$ru ruri_user=$rU ruri_host=$rd\n");
    xlog("L_INFO", "INVITE-IN SDP:\n$rb\n");
}
```

### 8.3 GB28181 通道解析

```opensips
route[process_catalog_response] {
    $xml(cat) = $rb;
    $var(i) = 0;

    while ($var(i) < 256) {
        $avp(chan_id) = $xml(cat/Response/DeviceList/Item[$var(i)]/DeviceID.val);
        if ($avp(chan_id) == NULL)
            break;

        $avp(chan_name) = $xml(cat/Response/DeviceList/Item[$var(i)]/Name.val);
        $avp(parent_id) = $xml(cat/Response/DeviceList/Item[$var(i)]/ParentID.val);

        # 插入 location 表
        sql_query("INSERT INTO location (...)");
        $var(i) = $var(i) + 1;
    }
}
```

### 8.4 SDP 处理

```opensips
onreply_route[handle_nat] {
    if (t_check_status("200") && $mb =~ "application/sdp") {
        # 提取 SDP 字段
        $avp(d_c) = $(rb{re.subst, /c=IN IP4 ([0-9.]+)/\1/});
        $avp(d_m) = $(rb{re.subst, /m=video ([0-9]+)/\1/});

        # 修改 SDP
        fix_nated_sdp("add-no-rtpproxy", "$socket_in(ip)", "\r\na=setup:active\r\na=connection:new");
    }
}
```

### 8.5 字符串拼接

```opensips
# 构建 Contact URI
$avp(recorder_contact) = "sip:" + $avp(chan_id) + "@" + $si + ":" + $sp;

# 构建 Channel UA
$avp(channel_ua) = $avp(chan_manufacturer) + " " + $avp(chan_model) + " (" + $avp(chan_name) + ")";

# 构建 RURI
$ru = "sip:" + $rU + "@" + $avp(recorder_domain);
```

---

## 九、常用判断条件

| 条件 | 含义 |
|:-----|:-----|
| `is_method("REGISTER")` | 判断是否为 REGISTER 方法 |
| `is_method("INVITE\|MESSAGE")` | 判断是否为 INVITE 或 MESSAGE 方法 |
| `is_myself("$rd")` | 判断 RURI 域名是否本机 |
| `is_myself("$fd")` | 判断 From 域名是否本机 |
| `has_totag()` | 判断 To 头是否有 tag（对话中请求） |
| `loose_route()` | 判断是否松散路由 |
| `t_check_trans()` | 检查重复请求 |
| `t_check_status("200")` | 检查响应状态码 |
| `lookup("location")` | 查询 usrloc |
| `t_was_cancelled()` | 检查呼叫是否被取消 |

---

## 十、模块返回值

| 返回值 | 含义 |
|:-------|:-----|
| `return 1` | 成功，继续执行 |
| `return 0` | 失败，停止执行 |
| `return -1` | 错误，停止执行 |

---

## 附录：变量速查表

### A.1 消息元素

```
$rm    - 请求方法
$ru    - 请求 URI
$rd    - RURI 域名
$rU    - RURI 用户名
$tu    - To URI
$td    - To 域名
$tU    - To 用户名
$fu    - From URI
$fd    - From 域名
$fU    - From 用户名
$cs    - CSeq 序列号
$ci    - Call-ID
```

### A.2 网络信息

```
$si    - 源 IP
$sp    - 源端口
$di    - 目的 IP
$dp    - 目的端口
$socket_in(ip)    - 接收 IP
$socket_in(port)  - 接收端口
```

### A.3 消息体

```
$mb    - 完整消息
$rb    - 消息体（SDP/XML）
$ct    - Contact URI
$hdr() - 头域访问
```

### A.4 响应状态

```
$rs    - 响应状态码
$rc    - 函数返回码
```

### A.5 存储变量

```
$avp(name)  - AVP 变量
$var(name)  - 临时变量
$xml(name)  - XML 解析变量
```

---

## 参考资料

- [OpenSIPS 官方文档](https://opensips.org/Documentation/Manuals)
- [OpenSIPS Pseudo-Variables](https://opensips.org/html/docs/modules/3.3.x/pv)
- [OpenSIPS Transformations](https://opensips.org/html/docs/modules/3.3.x/textops#idp transformations)

---

*文档生成日期：2026-07-09*
*适用版本：OpenSIPS 3.x*
