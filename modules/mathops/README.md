---
title: "mathops 模块"
description: "mathops模块提供了一系列函数，使OpenSIPS脚本层面能够执行各种浮点运算。"
---

## 管理指南


### 概述


mathops模块提供了一系列函数，使OpenSIPS脚本层面能够执行各种浮点运算。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他OpenSIPS模块。*。


#### 外部库或应用程序


运行此模块加载的OpenSIPS之前必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### decimal_digits (integer)


所有模块函数返回结果的精度。decimal_digits值越高，结果将具有越多的小数位数。


默认值为"6"。


```c title="设置 decimal_digits 模块参数"
modparam("mathops", "decimal_digits", 10)
```


### 导出的函数


#### math_eval(expression, result_var)


此函数评估给定的表达式并将结果写入输出伪变量。评估使用tinyexpr（见https://github.com/codeplea/tinyexpr）。


当前允许的表达式语法如下：


- 嵌套括号
- 加法(+)、减法/取负(-)、乘法(*)、除法(/)、幂运算(^)和取模(%)，具有正常的运算符优先级（一个例外是幂运算从左到右求值）
- C数学函数：abs（调用fabs）、acos、asin、atan、ceil、cos、cosh、exp、floor、ln（调用log）、log（调用log10）、sin、sinh、sqrt、tan、tanh


参数的含义如下：


- *expression* (string) - 一个数学表达式。
- *result_var* (var) - 将保存评估结果的变量。


此函数可用于任何路由。


```c title="math_eval 使用示例"
...
# 计算一些随机数学表达式

$avp(1) = "3.141592";
$avp(2) = "2.71828";
$avp(3) = "123.45678";

if (math_eval("$avp(1) * ($avp(3) - ($avp(1) - $avp(2))) / $avp(3)", $avp(result))) {
	xlog("表达式结果: $avp(result)\n");
} else {
	xlog("数学评估失败！\n");
}

...
```


#### math_rpn(expression, result_var)


此函数评估给定的RPN表达式并将结果写入输出变量。


表达式以逆波兰表示法指定。值被推入堆栈，而操作在堆栈上执行。支持以下操作：


- 二元运算符：+ - / * mod pow
- 一元函数：neg exp ln log10 abs sqrt cbrt floor ceil round nearbyint trunc
neg将改变堆栈顶部的符号
ln是自然对数；abs是绝对值；其他函数是标准C函数
- 常量：e pi
- 堆栈操作命令：drop dup swap


参数的含义如下：


- *expression* (string) - 一个RPN表达式。
- *result_var* (var) - 将保存评估结果的变量。


此函数可用于任何路由。


```c title="math_rpn 使用示例"
$avp(1) = "3";

if (math_rpn("1 $avp(1) swap swap dup drop / exp ln 1 swap /", $avp(result))) {
	xlog("表达式结果: $avp(result)\n");
} else {
	xlog("RPN评估失败！\n");
}

/* 此RPN脚本示例将1然后3推入堆栈，然后做几个空操作
（两次交换两个值，复制其中一个然后删除副本），
计算1除以3，然后再做一次空操作（幂运算然后对数），
最后计算1除以结果，得到3作为结果。 */
```


#### math_trunc(number, result_var)


将数字向零截断。这意味着trunc(3.7) = 3.0，trunc(-2.9) = -2.0。


参数的含义如下：


- *number* (string) - 要截断的数字。
- *result_var* (var) - 将保存评估结果的变量。


此函数可用于任何路由。


```c title="math_trunc 使用示例"
...
# 截断一个随机数

$avp(1) = "3.141492";

if (math_trunc($avp(1), $avp(result))) {
	xlog("截断结果: $avp(result)\n");
} else {
	xlog("截断失败！\n");
}
...
```


#### math_floor(number, result_var)


将数字向下（向负无穷）截断。这意味着floor(3.7) = 3.0，floor(-2.9) = -3.0


参数的含义如下：


- *number* (string) - 要截断的数字。
- *result_var* (var) - 将保存评估结果的变量。


此函数可用于任何路由。


```c title="math_floor 使用示例"
...
# 截断一个随机数

$avp(1) = "3.141492";

if (math_floor($avp(1), $avp(result))) {
	xlog("Floor结果: $avp(result)\n");
} else {
	xlog("Floor操作失败！\n");
}
...
```


#### math_ceil(number, result_var)


将数字向上（向正无穷）截断。这意味着ceil(3.2) = 4.0，ceil(-2.9) = -2.0


参数的含义如下：


- *number* (string) - 要截断的数字。
- *result_var* (var) - 将保存评估结果的变量。


此函数可用于任何路由。


```c title="math_ceil 使用示例"
...
# 截断一个随机数

$avp(1) = "3.141492";

if (math_ceil($avp(1), $avp(result))) {
	xlog("Ceil结果: $avp(result)\n");
} else {
	xlog("Ceil操作失败！\n");
}
...
```


#### math_round(number, result_var[, decimals])


四舍五入函数返回最接近的整数，平局时向远离零的方向取舍。示例：round(1.2) = 1.0，round(0.5) = 1.0，round(-0.5) = -1.0


默认情况下，函数返回一个整数。附加参数控制将保留的初始数字的小数位数。然后使用剩余的小数位数进行舍入，结果将是一个浮点值，表示为字符串。


参数的含义如下：


- *number* (string) - 要四舍五入的数字。
- *result_var* - 将保存评估结果的变量。
- *decimals* (int, 可选) - 进一步提高舍入精度。


此函数可用于任何路由。


```c title="math_round 使用示例"
...
# 对PI进行四舍五入

$avp(1) = "3.141492";

if (math_round($avp(1), $avp(result))) {

	# 结果应为：3
	xlog("舍入结果: $avp(result)\n");
} else {
	xlog("舍入操作失败！\n");
}

...

if (math_round($avp(1), $avp(result), 4)) {

	# 结果应为："3.1415"
	xlog("舍入结果: $avp(result)\n");
} else {
	xlog("舍入操作失败！\n");
}
...
```


#### math_round_sf(number, result_var, figures)


简单解释一下，舍入到N位有效数字的方法是首先保留N位有效数字（必要时补零），然后如果第N+1位数字大于或等于5则进行调整。


一些示例：


- round_sf(17892.987, 1) = 20000
round_sf(17892.987, 2) = 18000
round_sf(17892.987, 3) = 17900
round_sf(17892.987, 4) = 17890
round_sf(17892.987, 5) = 17893
round_sf(17892.987, 6) = 17893.0
round_sf(17892.987, 7) = 17892.99


参数的含义如下：


- *number* (string) - 要四舍五入的数字。
- *result_var* (var) - 将保存评估结果的变量。
- *figures* - 进一步提高舍入精度。


此函数可用于任何路由。


```c title="math_round_sf 使用示例"
...
# 对PI进行四舍五入

$avp(1) = "3.141492";

if (math_round_sf($avp(1), $avp(result), 4)) {

	# 结果应为："3.141"
	xlog("舍入结果: $avp(result)\n");
} else {
	xlog("舍入操作失败！\n");
}

...
```


#### math_compare(exp1, exp2, result_var)


比较exp1和exp2，并将比较结果返回到result_var。标准比较返回码：如果exp1 > exp2，result_var = 1；如果exp2 > exp1，result_var = -1；如果相等，result_var = 0。


参数的含义如下：


- *exp1* (string) - 第一个要评估并用于比较的表达式。
- *exp2* (string) - 第二个要评估并用于比较的表达式。
- *result_var* (var) - 将保存比较结果的变量。


此函数可用于任何路由。


```c title="math_compare 使用示例"
...
# 对PI进行四舍五入

$var(exp1) = "1 + 8";
$var(exp2) = "7/2";

if (math_compare($var(exp1), $var(exp2), $var(result))) {

	# $var(result)将为1，因为9 > 3.5
}

...
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即.md扩展名）均采用知识共享署名4.0许可证。
