---
title: "脚本转换"
description: "直观地讲，转换是应用于变量（脚本变量、伪变量、AVP、静态字符串）以从中获取特殊值的函数。输入值不会被更改..."
---

直观地讲，**转换**是应用于变量（脚本变量、伪变量、AVP、静态字符串）以从中获取特殊值的函数。输入值不会被更改。

在 **OpenSIPS 脚本**中使用不同类型变量的示例：

```bash

# check if username in From header is equal with username in To header
if ($fU == $tU) {
   ...
}

# Request-URI username based processing
switch ($rU) {
   case "1234":
      ...
   break;
   case "5678":
      ...
   break;
   default:
     ...
}

# assign an integer value to an variable
$var(gw_count) = 1;

# assign a string value to an AVP
$avp(server) = "opensips";

# store the Request-URI in a variable
$var(ru_backup) = $ru;

# concat "sip:" + From username + "@" + To domain in a script variable x
$var(x) = "sip:" + $fU + "@" + $td;

```

转换旨在方便访问变量的不同属性（如值的 strlen、值部分、子字符串）或完全不同的变量值（以十六进制编码、md5 值、为 DB 操作转义/反转义值...）。

转换在 `}` 和变量名之间表示。当使用转换时，变量名和转换**必须**括在 `(` 和 `)` 之间。

示例：

```bash

# the length of From URI ($fu is pseudo-variable for From URI)

$(fu{s.len})

```

可以同时对变量应用多个转换。

```bash

# the length of escaped 'Test' header body

$(hdr(Test){s.escape.common}{s.len})

```

除非另有说明，所有转换在错误或不成功操作时返回 NULL（例如在使用 "`{uri.param,name}`" 转换在 URI 中查找不存在的参数时）。此外，NULL 也被接受为转换的输入，以支持与前一个可能返回 NULL 的转换链接。

转换可以在任何地方使用，被视为脚本变量支持的一部分——在 xlog、avpops 或其他模块的函数和参数中，在赋值表达式的右侧或比较中。

> [!IMPORTANT]
> 要了解哪些变量可以与转换一起使用，请参阅[脚本变量列表](Script-CoreVar.md)。

## 字符串转换

这些转换的名称以 's.' 开头。它们旨在对变量应用字符串操作。

此类中可用的转换：

### {s.len}

返回变量值的 strlen

```text

$var(x) = "abc";
if($(var(x){s.len}) == 3)
{
   ...
}

```

### {s.int}

将给定字符串的开头部分转换为整数值。如果没有数字则返回 0。

```bash

$var(dur) = "2868.12 sec";
if ($(var(dur){s.int}) < 3600) {
  ...
}

```

### {s.md5}

返回给定输入的 MD5 哈希值。

```text

xlog("MD5 over From username: $(fU{s.md5})\n");

```

### {s.crc32}

以十进制字符串形式返回值的 CRC-32 校验和。

### {s.reverse}

以逆序返回输入字符串。

```text

$var(forward) = "onetwothree";
$var(reverse) = $(var(forward){s.reverse}); //Contains "eerhtowteno";

```

### {s.substr,offset,length}

返回从 *offset* 开始、长度为 *length* 的子字符串。如果 *offset* 为负数，则从值末尾开始计数，-1 是最后一个字符。如果为正数，*0* 是第一个字符。如果 *length* 为 *0* 或大于字符串长度，则返回到输入字符串末尾的子字符串。如果 *length* 为负数，则子字符串的末尾从值末尾开始计数，-1 排除最后一个字符。offset 和 length 都可以使用变量指定。

示例：
```text

$var(x) = "abcd";
$(var(x){s.substr,1,0}) = "bcd"

```

### {s.select,index,separator}

从变量值中返回一个字段。字段基于分隔符和索引选择。分隔符必须是用于识别字段的字符。索引必须是整数值或变量。如果索引为负数，则从值末尾开始计数字段，-1 是最后一个字段。如果索引为正数，0 是第一个字段。请注意，如果字段为空，将返回空字符串而不是 NULL。

示例：
```text

$var(x) = "12,34,56";
$(var(x){s.select,1,,}) => "34" ;

$var(x) = "12,34,56";
$(var(x){s.select,-2,,}) => "34"

```

### {s.encode.hexa}

返回变量值的十六进制编码

### {s.decode.hexa}

返回变量值的十六进制解码

### {s.escape.common}

返回变量值的转义字符串。转义的字符有 '、"、反斜杠和 0。在进行 DB 查询时很有用（应注意非拉丁字符集）。

### {s.unescape.common}

返回变量值的反转义字符串上述转换的反向操作。

### {s.escape.user}

返回变量值的转义字符串，将 RFC 要求中 SIP URI 用户部分不允许的字符更改为 '%hexa'。

### {s.unescape.user}

返回变量值的反转义字符串，将 '%hexa' 更改为字符代码。上述转换的反向操作。

### {s.escape.param}

返回变量值的转义字符串，将 RFC 要求中 SIP URI 参数部分不允许的字符更改为 '%hexa'。

### {s.unescape.param}

返回变量值的反转义字符串，将 '%hexa' 更改为字符代码。上述转换的反向操作。

### {s.tolower}

返回小写 ASCII 字母的字符串。

### {s.toupper}

返回大写 ASCII 字母的字符串。

### {s.index}

从第一个字符串开头开始搜索另一个字符串。返回找到的字符串的起始索引，如果未找到则返回 NULL。
可选索引指定在字符串中开始搜索的偏移量。支持负偏移量并会环绕。

```bash

$var(strtosearch) = 'onetwothreeone';
$var(str) = 'one';

# Search the string starting at 0 index
$(var(strtosearch){s.index, $var(str)}) # will return 0
$(var(strtosearch){s.index, $var(str), 0}) # Same as above
$(var(strtosearch){s.index, $var(str), 3}) # returns 11

# Negative offset
$(var(strtosearch){s.index, $var(str), -11}) # Same as above

# Negative wrapping offset
$(var(strtosearch){s.index, $var(str), -25}) # Same as above

#Test for existence of string in another
if ($(var(strtosearch){s.index, $var(str)}) != NULL)
    xlog("found $var(str) in $var(strtosearch)\n");

```

### {s.rindex}

从第一个字符串末尾开始搜索另一个字符串。返回找到的字符串的起始索引，如果未找到则返回 NULL。
可选索引指定开始搜索的偏移量，即找到的字符串开头将在提供的偏移量之前。支持负偏移量并会环绕。

```text

$(var(strtosearch){s.rindex, $var(str)}) # will return 11
$(var(strtosearch){s.rindex, $var(str), -3}) # will return 11
$(var(strtosearch){s.rindex, $var(str), 11}) # will return 11
$(var(strtosearch){s.rindex, $var(str), -4}) # will return 0

```

### {s.fill.left, tok, len}

用字符/字符串填充字符串左侧，直到达到给定的最终长度。如果初始字符串长度大于或等于给定的最终长度，则返回初始字符串。

```text

$var(in) = "485"; (also works for integer PVs)

$(var(in){s.fill.left, 0, 3})    => 485    
$(var(in){s.fill.left, 0, 6})    => 000485
$(var(in){s.fill.left, abc, 8})  => bcabc485

```

> [!NOTE]
> currently optimized for speed. Does not support pseudo-variable parameters or successive "s.fill" cascading.

### {s.fill.right, tok, len}

用字符/字符串填充字符串右侧，直到达到给定的最终长度。如果初始字符串长度大于或等于给定的最终长度，则返回初始字符串。

```text

$var(in) = 485; (also works for string PVs)

$(var(in){s.fill.right, 0, 3})   => 485
$(var(in){s.fill.right, 0, 6})   => 485000
$(var(in){s.fill.right, abc, 8}) => 485abcab

```

### {s.width, len}

将输入截断或扩展到给定的 *len*。扩展在右侧用空格字符 ' ' 进行。截断以类似方式从右侧进行。示例：

将输入截断或扩展到给定的 *len*。扩展在右侧用空格字符 ' ' 进行。截断以类似方式从右侧进行。如果用于包含整数的伪变量，它们将被转换为字符串。

```text

$var(in) = "transformation";

$(var(in){s.width, 14})   => "transformation"
$(var(in){s.width, 16})  => "transformation  "
$(var(in){s.width, 9})   => "transform"

```

### {s.trim}

从输入字符串中剥离任何前导或尾随空白。修剪的字符有 " "（空格）、\t（制表符）、\n（换行符）和 \r（回车符）。

```text

$var(in) = "\t \n input string  \r  ";

$(var(in){s.trim})   => "input string"

```

### {s.trimr}

从输入字符串中剥离任何尾随空白。修剪的字符有 " "（空格）、\t（制表符）、\n（换行符）和 \r（回车符）。

```text

$var(in) = "\t \n input string  \r  ";

$(var(in){s.trimr})   => "\t \n input string"

```

### {s.triml}

从输入字符串中剥离任何前导空白。修剪的字符有 " "（空格）、\t（制表符）、\n（换行符）和 \r（回车符）。

```text

$var(in) = "\t \n input string  \r  ";

$(var(in){s.triml})   => "input string  \r  "

```

### {s.dec2hex}

将十进制（基数为 10）数字转换为十六进制（基数为 16），表示为字符串。

### {s.hex2dec}

将以字符串表示的十六进制数字（基数为 16）转换为十进制（基数为 10）。

### {s.b64encode}

将二进制输入数据表示为 ASCII 字符串格式。

```text

$var(in) = "\x2\x3\x4\x5!@#%^&*";
$(var(in){s.b64encode})   => "AgMEBSFAIyVeJio="

```

### {s.b64decode}

假设输入是 Base64 字符串并尽可能多地解码字符。

```text

$var(in) = "AgMEBSFAIyVeJio=";
$(var(in){s.b64decode})   => "\x2\x3\x4\x5!@#%^&*"

```

### {s.xor,secret}

根据两个字符串的长度，对"secret"字符串参数和输入字符串的一部分执行一个或多个逻辑 XOR 操作。

```text

$var(in) = "aaaaaabbbbbb";
$(var(in){s.xor,x})   => "!/>^P!/>^P!^U2^Q!^U2^Q"

```

### {s.eval}

将字符串解释为变量格式化字符串，评估其中声明的所有变量。

```text

$var(in) = "client";
$var(format) = "Hello, $var(in)!";
$(var(format){s.eval})   => "Hello, client!"

```

### {s.date2unix}

假设输入是 RFC-3261 SIP "Date" 头值，并相应地解析它，返回等效的 UNIX 时间戳。

```text

$var(date) = "Thu, 13 Jun 2024 12:48:00 GMT";
$(var(date){s.date2unix})   => "1718282880";

```

### {s.sha1}

返回给定输入的 SHA1 哈希值。
```text

xlog("SHA1 over From username: $(fU{s.sha1})\n");

```

### {s.sha224}

返回给定输入的 SHA224 哈希值。
```text

xlog("SHA224 over From username: $(fU{s.sha224})\n");

```

### {s.sha256}

返回给定输入的 SHA256 哈希值。
```text

xlog("SHA256 over From username: $(fU{s.sha256})\n");

```

### {s.sha384}

返回给定输入的 SHA384 哈希值。
```text

xlog("SHA384 over From username: $(fU{s.sha384})\n");

```

### {s.sha512}

返回给定输入的 SHA512 哈希值。
```text

xlog("SHA512 over From username: $(fU{s.sha512})\n");

```

### {s.sha1_hmac,key}

使用密钥返回给定输入的 SHA1 HMAC 哈希值。
```text

xlog("SHA1 HMAC over From username using key 'secret': $(fU{s.sha1_hmac,secret})\n");

```

### {s.sha224_hmac,key}

使用密钥返回给定输入的 SHA224 HMAC 哈希值。
```text

xlog("SHA224 HMAC over From username using key 'secret': $(fU{s.sha224_hmac,secret})\n");

```

### {s.sha256_hmac,key}

使用密钥返回给定输入的 SHA256 HMAC 哈希值。
```text

xlog("SHA256 HMAC over From username using key 'secret': $(fU{s.sha256_hmac,secret})\n");

```

### {s.sha384_hmac,key}

使用密钥返回给定输入的 SHA384 HMAC 哈希值。
```text

xlog("SHA384 HMAC over From username using key 'secret': $(fU{s.sha384_hmac,secret})\n");

```

### {s.sha512_hmac,key}

使用密钥返回给定输入的 SHA512 HMAC 哈希值。
```text

xlog("SHA512 HMAC over From username using key 'secret': $(fU{s.sha512_hmac,secret})\n");

```

## URI 转换

转换的名称以 'uri.' 开头。变量的值被认为是 SIP URI。此转换返回 SIP URI 的部分（请参阅 struct sip_uri）。如果该部分缺失，返回值为 NULL。

此类中可用的转换：

### {uri.user}

返回 URI 模式的用户部分。

### {uri.host}

（与 **`{uri.domain}`** 相同）

返回 URI 模式的域部分。

### {uri.passwd}

返回 URI 模式的密码部分。

### {uri.port}

返回 URI 模式的端口。

### {uri.params}

将所有 URI 参数返回为单个字符串。

### {uri.param,name}

返回具有名称 "name" 的 URI 参数的值

### {uri.headers}

返回 URI 头。

### {uri.transport}

返回 transport URI 参数的值。

### {uri.ttl}

返回 ttl URI 参数的值。

### {uri.uparam}

返回 user URI 参数的值

### {uri.maddr}

返回 maddr URI 参数的值。

### {uri.method}

返回 method URI 参数的值。

### {uri.lr}

返回 lr URI 参数的值。

### {uri.r2}

返回 r2 URI 参数的值。

### {uri.schema}

返回给定 URI 的模式部分。

## VIA 转换

这些转换解析 Via 头，都以 `via.` 开头。变量的值被认为是 SIP Via 头。此转换返回 via 头的部分（请参阅 struct via_body）。如果请求的部分缺失，返回值为 NULL。如果持有 Via 头的变量为空，转换将失败（带脚本错误）。除非下面描述中另有说明，否则转换结果是字符串（不是整数）。

示例：
```text
$var(upstreamtransport) = $(hdr(Via)[1]{via.transport}{s.tolower});
$var(upstreamip) = $(hdr(Via)[1]{via.param,received});
$var(clientport) = $(hdr(Via)[-1]{via.param,rport});
```

此类中可用的转换：

### {via.name}

返回 `protocol-name`（RFC3261 BNF），通常是 `SIP`。

### {via.version}

返回 `protocol-version`（RFC3261 BNF），通常是 `2.0`。

### {via.transport}

返回 `transport`（RFC3261 BNF），例如 `UDP`、`TCP`、`TLS`。这是用于发送请求消息的传输协议。

### {via.host}

（与 `{via.domain}` 相同）

返回 `sent-by` 的 `host` 部分（RFC3261 BNF）。通常这是请求消息发送者的 IP 地址，也是响应将被发送到的地址。

### {via.port}

返回 `sent-by` 的 `port` 部分（RFC3261 BNF）。通常这是请求消息发送者的 IP 端口，也是响应将被发送到的地址。转换结果对整数和字符串都有效。

### {via.comment}

与 via 头关联的注释。`struct via_body` 包含此字段，但 RFC3261 是否允许 Via 头中有注释尚不清楚（请参阅第 221 页顶部文本，BNF 没有明确允许 Via 中有注释）。注释是括在括号内的文本。

### {via.params}

以单个字符串返回所有 Via 头参数（RFC3261 BNF 的 `via-param`）。结果可以使用 `{param.*}` 转换处理。这实质上是主机和端口之后的所有内容。

### {via.param,name}

返回具有名称 `name` 的 Via 头参数的值。典型参数包括 `branch`、`rport` 和 `received`。

### {via.branch}

返回 VIA 头中 branch 参数的值。

### {via.received}

返回 VIA 头中 received 参数的值（如果有）。

### {via.rport}

返回 VIA 头中 rport 参数的值（如果有）。

## 参数列表转换

转换的名称以 "param." 开头。变量的值被认为是类似 name1=value1;name2=value2;..." 的字符串。转换返回特定参数的值，或特定索引处参数的名称。

此类中可用的转换：

### {param.value,name}

返回参数 'name' 的值

示例：
```text

"a=1;b=2;c=3"{param.value,c} = "3"

```

'name' 可以是一个变量

### {param.exist,name}

如果参数 `name` 存在（无论是否有值）返回 1，否则返回 0。返回值同时是字符串和整数。`name` 可以是变量。这可用于测试不存在值的参数的存在性。

示例：
```text

"a=0;b=2;ob;c=3"{param.exist,ob};         # returns 1
"a=0;b=2;ob;c=3"{param.exist,a};          # returns 1
"a=0;b=2;ob;c=3"{param.exist,foo};        # returns 0

```

### {param.valueat,index}

返回 'index' 位置参数的值（0-based 索引）。接受负索引，-1 是最后一个参数。

示例：
```text

"a=1;b=2;c=3"{param.valueat,1} = "2"

```

'index' 可以是一个变量

### {param.name,index}

返回 'index' 位置参数的名称。接受负索引，-1 是最后一个参数。'index' 可以是一个变量。

示例：
```text

"a=1;b=2;c=3"{param.name,1} = "b"

```

### {param.count}

返回列表中参数的数量。

示例：
```text

"a=1;b=2;c=3"{param.count} = 3

```

## 名称地址转换

转换的名称以 'nameaddr.' 开头。变量的值被认为是类似 '[display_name] uri' 的字符串。转换返回特定字段的值。

每个转换支持可选的 'index'。这在传递 nameaddr specs 列表时使用，表示在提取值时应考虑的 spec 索引。索引从 0 开始（缺失时的默认值），并且可以接受负值（-1 表示最后一个 nameaddr spec）。

示例：
```text

'"first" <first@opensips.org>, "second" <second@opensips.org>' {nameaddr.0.name} = "first"
'"first" <first@opensips.org>, "second" <second@opensips.org>' {nameaddr.1.name} = "second"
'"first" <first@opensips.org>, "second" <second@opensips.org>' {nameaddr.-1.name} = "second"

```

此类中可用的转换：

### {nameaddr.name}

返回显示名称的值

示例：
```text

'"test" <sip:test@opensips.org>' {nameaddr.name} = "test"

```

### {nameaddr.uri}

返回 URI 的值

示例：
```text

'"test" <sip:test@opensips.org>' {nameaddr.uri} = sip:test@opensips.org

```

### {nameaddr.len}

返回值中整个 name-addr 部分的长度。

### {nameaddr.param,param_name}

返回名称为 param_name 的参数的值。
示例：
```text

'"test" <sip:test@opensips.org>;tag=dat43h' {nameaddr.param,tag} = dat43h

```

### {nameaddr.params}

返回所有参数及其对应值。
示例：
```text

'"test" <sip:test@opensips.org>;tag=dat43h;private=yes' {nameaddr.params} = "tag=dat43h;private=yes"

```

## IP 转换

转换的名称以 'ip.' 开头。此类中可用的转换：

### {ip.pton}

返回字符串表示 IP 的二进制表示形式。
示例：
```text

"194.168.4.134" {ip.pton} returns a 4 byte binary representation of the IP provided

```

### {ip.ntop}

返回所提供二进制 IP 的字符串表示形式
示例：
```text

"194.168.4.134"{ip.pton}{ip.ntop} = "194.168.4.134"

```

### {ip.isip}

如果提供的字符串是有效的 IPv4 或 IPv6 地址，则返回 `1`，否则返回 `0`。
示例：
```text

"194.168.4.134" {ip.isip} = 1
"194.168.4.134.1" {ip.isip} = 0

```

### {ip.isip4}

如果提供的字符串是有效的 IPv4，则返回 `1`，否则返回 `0`。
示例：
```text

"194.168.4.134" {ip.isip4} = 1

```

### {ip.isip6}

如果提供的字符串是有效的 IPv6，则返回 `1`，否则返回 `0`。
示例：
```text

"194.168.4.134" {ip.isip6} = 0
"2001:0db8:85a3:0000:0000:8a2e:0370:7334" {ip.isip6} = 1

```

### {ip.family}
如果提供的二进制 IP 表示形式是 IPv4 或 IPv6，则分别返回 INET 或 INET6。
示例：
```text

"194.168.4.134" {ip.pton}{ip.family} = "INET"

```

### {ip.resolve}
返回与提供的字符串域对应的解析 IP 地址。如果提供字符串 IP，转换无效。
示例：
```text

"opensips.org" {ip.resolve} = "78.46.64.50"

```

### {ip.matches}
检查输入 IP 地址是否匹配以 IP/masklen（短格式）给出的网络掩码。如果匹配返回 1，否则返回 0。错误时返回 NULL（无效输入、无效参数、AF 不匹配）。参数支持变量。
示例：
```bash

if ( $(si{ip.matches,10.10.0.1/24})==1 )
	xlog("It DOES match \n");
else
	xlog("It DOES NOT match \n");

```

### {ip.isprivate}
检查输入 IP 地址是否是 RFC 1918 和 RFC 6598 定义的 IPv4 私有 IP，或者是回环 IP (127.0.0.0/8)。如果是私有 IP 返回 1，否则返回 0。
示例：
```bash

if ( $(si{ip.isprivate})==1 )
	xlog("source ip is private\n");
else
	xlog("source ip is not private\n");

```

## CSV 转换

转换的名称以 "csv." 开头。变量的值被认为是类似 "field1,field2,..." 的字符串。转换返回所提供 CSV 中的条目数，或 CSV 中指定位置的字段。

此类中可用的转换：

### {csv.count}
返回所提供 CSV 中的条目数。
示例：
```text

"a,b,c" {csv.count} = 3

```

### {csv.value,index}
返回指定位置的条目。索引从 0 开始。接受负索引，-1 是最后一个条目。'index' 可以是一个变量。
示例：
```text

"a,b,c" {csv.value,2} = c

```

## SDP 转换

转换的名称以 "sdp." 开头。变量的值被认为是有效的 SDP 正文。转换返回 SDP 正文中的特定行。

此类中可用的转换：

### {sdp.line}
返回 SDP 正文中的指定行。转换也接受第二个参数，指定从 SDP 正文获取的第一个参数类型的行号。索引从 0 开始。如果第二个参数缺失，假定为 0。
示例：
```bash

if (is_method("INVITE"))
   {
      $var(aline) = $(rb{sdp.line,a,1});
      xlog("The second a line in the SDP body is $var(aline)\n");
   }

if (is_method("INVITE"))
   {
      $var(mline) = $(rb{sdp.line,m});
      xlog("The first m line in the SDP body is $var(mline)\n");
   }

```

### {sdp.stream}
从 SDP 正文中返回特定流（从 m= 行开始）。要返回的流可以使用其在正文中的索引指定，或者使用其媒体类型。如果指定为索引，从 `0` 开始，但也可以是负数，`-1` 是最后一个流。如果指定为媒体类型，**仅**返回其类型的第一个流。如果媒体类型或索引不存在，返回 NULL。

示例：
```bash

if (is_method("INVITE"))
   {
      $var(first_stream) = $(rb{sdp.stream,0});
      xlog("First stream is $var(first_stream)\n");
   }

if (is_method("INVITE"))
   {
      $var(audio_stream) = $(rb{sdp.stream,audio});
      xlog("Audio stream is $var(audio_stream)\n");
   }

```

### {sdp.stream-delete}
返回删除了某些流的指定 SDP 正文。要删除的流可以使用其索引指定，或者使用其媒体类型。如果指定为索引，从 `0` 开始，但也可以是负数，`-1` 是最后一个流。如果指定为媒体类型，**所有**匹配的流都将被删除！如果媒体类型或索引不存在，返回 NULL。

示例：
```bash

if (is_method("INVITE"))
   {
      $var(new_body) = $(rb{sdp.stream-delete,0});
      xlog("SDP body without first stream is $var(new_body)\n");
   }

if (is_method("INVITE"))
   {
      $var(new_body) = $(rb{sdp.stream-delete,video});
      xlog("SDP body without video stream is $var(new_body)\n");
   }

```

## 正则表达式转换

转换的名称以 "re." 开头。输入可以是任何字符串。

### {re.subst,reg_exp}

reg_exp 参数可以是纯字符串或变量。
reg_exp 格式为：
```text
/posix_match_expression/replacement_expression/flags
```

标志可以是：
```text
i - 忽略大小写匹配
s - 在多行字符串中匹配
g - 替换所有匹配
```

示例：
```text

$var(reg_input)="abc";
$var(reg) = "/a/A/g";
xlog("Applying reg exp $var(reg) to $var(reg_input) : $(var(reg_input){re.subst,$var(reg)})\n");

...
...
xlog("Applying reg /b/B/g to $var(reg_input) : $(var(reg_input){re.subst,/b/B/g})\n");

```

## 示例

在变量内可以应用许多转换，从左到右执行。

* 位置 1 处参数值的长度（记住 0 是第一位置，1 是第二位置）

```text

$var(x) = "a=1;b=22;c=333";
$(var(x){param.value,$(var(x){param.name,1})}{s.len}) = 2

```

* 测试是否为注销

```text

if(is_method("REGISTER") && is_present_hf("Expires") && $(hdr(Expires){s.int})==0)
    xlog("This is a de-registration\n");

```
