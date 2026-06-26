---
title: "XML 模块"
description: "该模块提供了一个脚本变量，可对 XML 文档或 XML 数据块进行基本的解析和操作。该变量提供访问整个 XML 元素、其文本内容或属性的方法。您可以修改内容和属性，也可以在 XML 树中添加或删除节点..."
---

## 管理指南


### 概述


该模块提供了一个脚本变量，可对 XML 文档或 XML 数据块进行基本的解析和操作。
该变量提供访问整个 XML 元素、其文本内容或属性的方法。
您可以修改内容和属性，也可以在 XML 树中添加或删除节点。


该处理不会根据任何 DTD 或模式进行验证。


### 依赖


#### OpenSIPS 模块


该模块不依赖其他模块。


#### 外部库或应用程序


- *libxml2* 大多数 Linux 和 BSD 发行版都包含 libxml，但也可以从 xmlsoft.org 下载该库。


### 导出的参数


该模块不导出任何参数。


### 导出的伪变量


#### $xml(path)


该模块导出 *$xml(path)* 变量。


##### 变量生命周期


xml 变量从初始化时起将对创建它的进程可用。
它们不会在每个消息或每个事务时重置。
如果您想在每个消息的基础上使用它们，应该每次都初始化它们。


##### 访问 $xml(path) 变量


对元素和属性的访问基于 XML 文档的树表示形式，
因此需要从根节点开始的完整路径。
XML 文档的内存等效形式是一个"XML 对象"，
该对象必须在使用前用格式良好的 XML 数据块进行初始化。
因此，路径必须以对象名称开头，后跟任意数量的节点，
直到到达所需的元素。


描述路径的语法如下：


path = name | name(identifier)+(access)?


identifier = element(index)?


element = /string | /$var


index = [integer] | [$var]


access = .val | .attr/string | .attr/$var


为了在同一树层级选择具有相同名称的节点，
可以提供一个索引，从 0 开始。


路径中节点的序列后面可以跟 *.val* 以访问最后一个节点的文本内容，
或跟 *.attr/attr_name* 以访问其名为 *attr_name* 的属性。
否则将访问整个元素（包括开始标签、结束标签、子元素和内容）。


为变量分配 NULL 将根据访问模式删除整个元素、其文本内容或属性。


如果要插入元素，必须为父节点分配一个字符串值
（包含具有根节点的格式良好的 XML 数据块）。
请注意，直接为节点分配值不会用该值替换它。


重要提示：XML 中文档内容的所有字符都是有效的，包括空格和格式化的换行符。
元素及其内容将保留所有空白字符和换行符返回，
当在现有节点下添加新节点时，
如果希望用缩进插入它，必须在分配的字符串中包含所需的字符。


其他脚本变量可以用作路径中的元素名称、属性名称和索引。
用作索引的变量必须包含整数值。
用作元素或属性名称的变量应包含字符串值。


```c title="创建文档"
...
$xml(my_doc) = "<doc></doc>";        # 初始化对象

$xml(my_doc/doc) = "<list></list>";  # 添加一个 "list" 节点

$xml(my_doc/doc/list) = "<item>some_value</item>";    # 向列表添加一个 "item" 节点

$xml(my_doc/doc/list) = "<item>another_value</item>"; # 向列表添加另一个 item

$xml(my_doc/doc/list/item[1].val) = "new_val";        # 设置前一个 item 的文本内容

$xml(my_doc/doc/list.attr/sort) = "asc";              # 向 list 节点添加 "sort" 属性

$xml(my_doc/doc/list.attr/sort) = NULL;               # 删除前一个属性

$xml(my_doc/doc/list/item[1]) = NULL;                 # 删除第二个 item

$xml(my_doc/doc/list.val) = "end";                    # 向列表添加文本内容，现在列表有
                                                      # 混合内容

$xml(my_doc/doc/list.val) = NULL;                     # 删除文本内容

xlog("$xml(my_doc/doc/list)\n");                      # 显示整个列表

xlog("$xml(my_doc)\n");                               # 显示整个文档

$xml(my_doc) = NULL;                                  # 清除整个文档
...
					
```


```c title="用缩进插入节点"
...
$xml(my_doc) = "<doc>\n</doc>";
$xml(my_doc/doc) = "\t<list></list>\n";
$xml(my_doc/doc/list) = "\n\t\t<item></item>\n\t";

# 这将创建以下文档：
# <doc>
#	<list>
#		<item></item>
#	</list>
# </doc>
#
# 没有显式格式化字符的文档将是：
# <doc><list><item></item></list></doc>
...
					
```


```c title="在路径中使用脚本变量"
...
# 访问列表中第二个 item 的属性
$var(my_list) = "list";
$var(my_idx) = 1;
$var(my_attr) = "sort";
xlog("$xml(my_doc/doc/$var(my_list)/item[$var(my_idx)].attr/$var(my_attr))\n");
...
					
```


### 导出的函数


该模块不导出任何脚本函数。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0
