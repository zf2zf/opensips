---
title: "JSON 模块"
description: "此模块引入了一种新型变量，提供 JSON 格式的序列化和反序列化功能。"
---

## 管理指南

### 概述

此模块引入了一种新型变量，提供 JSON 格式的序列化和反序列化功能。

该变量提供了访问对象和数组的方法，可在脚本中添加、替换或删除值。

正确的方法是将 json 对象视为哈希表（您可以放入（键，值）对，并可以通过键删除和获取值）和 json 数组（您可以追加、删除和替换值）。

由于 JSON 格式可以在其他对象内部包含对象，因此您可以拥有多个嵌套的哈希表或数组，并可以使用路径访问它们。

### 依赖

#### OpenSIPS 模块

此模块不依赖其他模块。

#### 外部库或应用程序

- *libjson* - libjson C 库可从以下地址下载：http://oss.metaparadigm.com/json-c/

### 导出的参数

#### enable_long_quoting (boolean)

如果您的输入 JSON 包含超出 4 字节的有符号整数（例如大于 2147483647 等），请启用此参数。如果启用该参数，4 字节整数将继续作为整数返回，而更大的值将作为字符串返回，以避免整数溢出。

*默认值为 *false*。*

```c title="设置 enable_long_quoting 参数"
...
modparam("json", "enable_long_quoting", true)
...
# 规范化 "gateway_id" int/string 值，使其始终为字符串
$var(gateway_id) = "" + $json(body/gateway_id);
...
```

### 导出的伪变量

#### $json(id)

`json` 变量提供了访问 json 对象中的字段和 json 数组中的索引的方法。

##### 变量生命周期

json 变量将在创建它们的进程从初始化时起可用。它们不会在每个消息或每个事务时重置。如果要按消息使用它们，您应该每次都初始化它们。

##### 访问 $json(id) 变量

描述 id 的语法是：

```
id = name(identifier)*

identifier = key | index

key = /string | /$var

index = [integer] | [$var] | []
```

"[]" 索引表示追加到数组。它仅在尝试设置值时使用，而不是在尝试获取值时使用。

可以使用负索引从末尾开始访问数组。所以 "[-1]" 表示最后一个元素。

重要提示：id 严格遵守此语法。使用空格时要小心，因为它们不会被忽略。这样做是为了允许包含空格的键。

变量可以用作索引或键。用作索引的变量必须包含整数值。用作键的变量应包含字符串值。

尝试从不存在的路径（键或值）获取值将返回 NULL 值，并在日志中放置描述 json 值和所用路径的通知消息。

尝试在不存在的路径中替换或插入值将导致设置值错误，并在日志中打印描述 json 值和所用路径的通知消息。

```c title="访问 $json 变量"
...
$json(obj1/key) = "value"; #替换或插入（key,value）对到 json 对象；
				   
$json(matrix1[1][2]) = 1;  #替换索引 2 处元素在索引 1 处元素中的元素

xlog("$json(name/key1[0][-1]/key2)"); #一个更复杂的示例

...
```

##### 遍历

可以通过使用 for each 语句对 JSON 对象或数组进行动态遍历，类似于索引伪变量迭代。但是，请注意，不支持在其他任何语句中对 $json 变量进行索引（这是指索引整个变量，而不是 *id* 语法中接受的索引）。

为了显式遍历 JSON 对象键或值，您可以对 *id* 中指定的路径使用 *.keys* 或 *.values* 后缀。

```c title="遍历 $json 对象键"
...
$json(foo) := "{\"a\": 1, \"b\": 2, \"c\": 3}";
for ($var(k) in $(json(foo.keys)[*]))
    xlog("$var(k) ");
...
```

##### $json(id) 返回值

如果 id 指定的值为整数，它将作为整数值返回。

如果 id 指定的值为字符串，它将作为字符串返回。

如果 id 指定的值为任何其他 json 类型（null、boolean、object、array），对象的序列化版本将作为字符串值返回。使用此功能和 ":=" 操作符，您可以复制 json 对象并将它们放到其他 json 对象中（对于字符串或整数，您可以使用 "=" 操作符）。

如果 id 不存在，将返回 NULL 值。

##### $json(id) 变量的操作符

此变量有两个可用的操作符。

###### "=" 操作符

这将导致值被原样获取并添加到 json 对象（例如字符串值或整数值）。

将值设置为 NULL 将导致其被删除。

```c title="向数组追加整数"
...
$json(array1[]) = 1;
...
```

```c title="删除数组中最后一个元素"
...
$json(array1[-1]) = NULL;
...
```

```c title="向 json 对象添加字符串值"
...
$json(object1/some_key) = "some_value";
...
```

###### ":=" 操作符

这将导致值被获取并解释为 json 对象（例如，此操作符应用于解析 json 输入）。

```c title="初始化数组"
...
$json(array1) := "[]";
...
```

```c title="设置布尔值或空值"
...
$json(array1[]) := "null";
$json(array1[]) := "true";
$json(array1[]) := "false";
...
```

```c title="将 json 添加到另一个 json"
...

$json(array) := "[1,2,3]";
$json(object) := "{}";
$json(object/array) := $json(array) ;
...
```

#### $json_pretty(id)

`json_pretty` 变量与 [json](#pv_json) 变量有相同用途，但以更漂亮的格式打印 JSON 对象，添加空格和制表符使输出更易读。

#### $json_compact(id)

`json_compact` 变量与 [json](#pv_json) 变量有相同用途，但以更紧凑的形式打印 JSON 对象，不格式化空格。

#### $json_compact_noescape(id)

`json_compact_noescape` 变量与 [json compact](#pv_json_compact) 变量有相同用途，以紧凑形式打印 JSON 对象，但不转义斜杠。

*注意：*由于 libjson-c 库限制，此变量仅从版本 *0.13* 开始跳过斜杠转义——旧版本的库使该变量的行为与 [json compact](#pv_json_compact) 变量完全相同。

### 导出的函数

#### json_link($json(dest_id), $json(source_id))

此函数可用于将 json 对象链接在一起。这类似于将值设置到对象，唯一的区别是第二个对象不被复制，仅创建引用。

对任何一个对象的更改都将在两者中可见。

### 示例

```c title="创建引用"
...

$json(b) := "[{},{},{}]";

json_link($json(stub), $json(b[0]));

$json(stub/ana) = "are"; #添加到 stub
$json(stub/ar) := "[]";
$json(stub/ar[]) = 1;
$json(stub/ar[]) = 2;
$json(stub/ar[]) = 3;

$json(b[0]/ar[0]) = NULL; #从源对象删除

xlog("\n测试链接:\n$json(stub)\n$json(b)\n\n");
...
```

#### json_merge(main_json_var,patch_json_var,output_var))

该函数可用于将 patch_json_var 修补合并到 main_json_var，输出将填充到 output_var。

```c title="使用 json_merge"
...

$json(val1) := "{}";
$json(val1/test1) = "test_val1";
$json(val1/common_val) = "val_from1";

$json(val2) := "{}";
$json(val2/test2) = "test_val2";
$json(val1/common_val) = "val_from2";

json_merge($json(val1),$json(val2),$var(merged_json));
xlog("我们合并后得到 $var(merged_json) \n");
# 将打印：
# 我们合并后得到 {"test1":"test_val1","common_val":"val_from2","test2":"test_val2"}
...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
