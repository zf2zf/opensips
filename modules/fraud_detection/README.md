---
title: "欺诈检测模块"
description: "本模块提供了一种防止某些基本欺诈攻击的方法。警报通过返回码和事件提供。"
---

## 管理指南


### 概述


本模块提供了一种防止某些基本欺诈攻击的方法。
		警报通过返回码和事件提供。


#### 监控的统计信息


基本上,本模块监控以下参数：


- 总呼叫数
- 每分钟呼叫数
- 并发呼叫数
- 顺序呼叫数
- 呼叫持续时间


上述每个参数都针对每个用户和每个被叫前缀分别监控。
			每当调用 *check_fraud* 函数时都会更改统计信息。
			该函数假定进行了一次新呼叫,并根据提供的配置文件检查被叫号码。
			规则的前缀被视为被叫前缀,它与提供的用户一起,
			将用于监控这 5 个参数的值。


#### 欺诈规则


规则是五个参数（如下所述）每个参数的两个阈值（警告阈值和临界阈值）的集合,
			仅对指定的前缀有效。此外,规则仅在指定的一周中的指定小时内匹配
			（与 dr 规则类似）。欺诈配置文件只是一组欺诈规则,
			其作用仅是在调用 check_fraud 函数时限制要匹配的规则列表。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- drouting
- dialog


#### 外部库或应用程序


以下库或应用程序必须在运行
		加载本模块的 OpenSIPS 之前安装：


- *无*。


### 导出的参数


#### db_url (string)


要加载规则的数据库。


*默认值为 "NULL"。至少应定义一个 db_url
			才能使 fraud_detection 模块工作。*


```c title="设置 'db_url' 参数"
...
modparam("fraud_detection", "db_url", "mysql://user:passwb@localhost/database")
...
```


#### use_utc_time (integer)


将此参数设置为非零值可以启用基于 UTC 的间隔匹配和统计重置,
		而不是基于本地时间。


*默认值为 "0"（使用本地时间）。*


```c title="设置 'use_utc_time' 参数"
...
modparam("fraud_detection", "use_utc_time", 1)
...
```


#### table_name (string)


如果要从此数据库加载规则,必须将此参数设置为数据库名称。


*默认值为 "fraud_detection"。*


```c title="设置 'table_name' 参数"
...
modparam("fraud_detection", "table_name", "my_fraud")
...
```


#### rid_col (string)


数据库中存储欺诈规则 ID 的列名。


*默认值为 "ruleid"。*


```c title="设置 'rid_col' 参数"
...
modparam("fraud_detection", "rid_col", "theruleid")
...
```


#### pid_col (string)


数据库中存储欺诈配置文件 ID 的列名。


请注意,配置文件只是一组规则。


*默认值为 "profileid"。*


```c title="设置 'pid_col' 参数"
...
modparam("fraud_detection", "pid_col", "profile")
...
```


#### prefix_col (string)


数据库中存储欺诈规则匹配前缀的列名。


*默认值为 "prefix"。*


```c title="设置 'prefix_col' 参数"
...
modparam("fraud_detection", "prefix_col", "myprefix")
...
```


#### start_h (string)


数据库中存储规则匹配间隔开始时间的列名。


时间需要使用格式 "HH:MM" 指定为字符串。


*默认值为 "start_hour"。*


```c title="设置 'start_h' 参数"
...
modparam("fraud_detection", "start_h", "the_start_time")
...
```


#### end_h (string)


数据库中存储规则匹配间隔结束时间的列名。


时间需要使用格式 "HH:MM" 指定为字符串。


*默认值为 "end_hour"。*


```c title="设置 'end_h' 参数"
...
modparam("fraud_detection", "end_h", "the_end_time")
...
```


#### days_col (string)


数据库中存储欺诈规则间隔可用的一周中的天的列名。


daysoftheweek 需要指定为包含天列表或间隔的字符串。
			每天必须使用其名称的前三个字母指定。
			有效字符串例如："Fri-Mon, Wed, Thu"。


*默认值为 "daysoftheweek"。*


```c title="设置 'days_col' 参数"
...
modparam("fraud_detection", "days_col", "days")
...
```


#### cpm_thresh_warn_col (string)


数据库中存储每分钟呼叫警告阈值值的列名。


*默认值为 "cpm_warning"。*


```c title="设置 'cpm_thresh_warn_col' 参数"
...
modparam("fraud_detection", "cpm_thresh_warn_col", "cpm_warn_thresh")
...
```


#### cpm_thresh_crit_col (string)


数据库中存储每分钟呼叫临界阈值值的列名。


*默认值为 "cpm_critical"。*


```c title="设置 'cpm_thresh_crit_col' 参数"
...
modparam("fraud_detection", "cpm_thresh_crit_col", "cpm_crit_thresh")
...
```


#### calldur_thresh_warn_col (string)


数据库中存储呼叫持续时间警告阈值值的列名。


*默认值为 "call_duration_warning"。*


```c title="设置 'calldur_thresh_warn_col' 参数"
...
modparam("fraud_detection", "calldur_thresh_warn_col", "calldur_warn_thresh")
...
```


#### calldur_thresh_crit_col (string)


数据库中存储呼叫持续时间临界阈值值的列名。


*默认值为 "call_duration_critical"。*


```c title="设置 'calldur_thresh_crit_col' 参数"
...
modparam("fraud_detection", "calldur_thresh_crit_col", "calldur_crit_thresh")
...
```


#### totalc_thresh_warn_col (string)


数据库中存储总呼叫数警告阈值值的列名。


*默认值为 "total_calls_warning"。*


```c title="设置 'totalc_thresh_warn_col' 参数"
...
modparam("fraud_detection", "totalc_thresh_warn_col", "totalc_warn_thresh")
...
```


#### totalc_thresh_crit_col (string)


数据库中存储总呼叫数临界阈值值的列名。


*默认值为 "total_calls_critical"。*


```c title="设置 'totalc_thresh_crit_col' 参数"
...
modparam("fraud_detection", "totalc_thresh_crit_col", "totalc_crit_thresh")
...
```


#### concalls_thresh_warn_col (string)


数据库中存储并发呼叫数警告阈值值的列名。


*默认值为 "concurrent_calls_warning"。*


```c title="设置 'concalls_thresh_warn_col' 参数"
...
modparam("fraud_detection", "concalls_thresh_warn_col", "concalls_warn_thresh")
...
```


#### concalls_thresh_crit_col (string)


数据库中存储并发呼叫数临界阈值值的列名。


*默认值为 "concurrent_calls_critical"。*


```c title="设置 'concalls_thresh_crit_col' 参数"
...
modparam("fraud_detection", "concalls_thresh_crit_col", "concalls_crit_thresh")
...
```


#### seqcalls_thresh_warn_col (string)


数据库中存储顺序呼叫数警告阈值值的列名。


*默认值为 "sequential_calls_warning"。*


```c title="设置 'seqcalls_thresh_warn_col' 参数"
...
modparam("fraud_detection", "seqcalls_thresh_warn_col", "seqcalls_warn_thresh")
...
```


#### seqcalls_thresh_crit_col (string)


数据库中存储顺序呼叫数临界阈值值的列名。


*默认值为 "sequential_calls_critical"。*


```c title="设置 'seqcalls_thresh_crit_col' 参数"
...
modparam("fraud_detection", "seqcalls_thresh_crit_col", "seqcalls_crit_thresh")
...
```


### 导出的函数


#### check_fraud(user, number, profile_id)


每次给定 *user* 呼叫给定 *number* 时应调用此方法。
		它将尝试在给定欺诈配置文件中匹配欺诈规则并更新统计信息（见上文）。
		此外,统计信息将根据规则的阈值进行检查。
		如果任何统计信息超过其阈值值,也将引发相应的事件
		（见下文了解更多详情）。


专为初始 INVITE 消息设计！如果不存在对话,
			将创建一个（相当于 create_dialog()）。


参数含义如下：


- *user* (string) - 进行呼叫的用户。请注意,
				用户不必已注册。此字符串仅用于为不同的注册用户保持不同的统计信息。
- *number* (string) - 用户呼叫的号码。
- *profile_id* (int) - 欺诈配置文件 ID（即欺诈规则子集）,
				在其中尝试查找匹配的欺诈规则。


返回码的含义如下：


- *2* - 未找到匹配的欺诈规则
- *1* - 找到匹配规则,但没有参数超过规则的阈值,即一切正常
- *-1* - 有参数超过警告阈值值。请查看引发的事件了解更多详情
- *-2* - 有参数超过临界阈值值。请查看引发的事件了解更多详情
- *-3* - 出现问题（内部机制失败）


此函数可用于 REQUEST_ROUTE 和 ONREPLY_ROUTE。


### 导出的 MI 函数


#### fraud_detection:show_stats


替换已废弃的 MI 命令：*show_fraud_stats*。


显示用户对前缀的所有拨号当前统计信息。


注意：由于欺诈统计信息是实时刷新的,
		随着 check_fraud() 被调用,**如果 check_fraud()
		在新匹配的 时间间隔内尚未为（用户,前缀）对至少调用过一次,
		此函数将返回过时数据！**


名称：*fraud_detection:show_stats*


参数：


- user
- prefix


#### fraud_detection:reload


替换已废弃的 MI 命令：*fraud_reload*。


重新加载所有欺诈规则。


名称：*fraud_detection:reload*


参数：*无*


### 导出的事件


#### E_FRD_WARNING


每当五个监控参数之一超过警告阈值时引发此事件。


参数：


- *param* - 参数名称。
- *value* - 参数当前值。
- *threshold* - 警告阈值值。
- *user* - 发起呼叫的用户。
- *called_number* - 被叫号码。
- *rule_id* - 呼叫发起时匹配的欺诈规则 ID。
- *profile_id* - 使用的配置文件 ID。


#### E_FRD_CRITICAL


每当五个监控参数之一超过警告阈值时引发此事件。


参数：


- *param* - 参数名称。
- *value* - 参数当前值。
- *threshold* - 警告阈值值。
- *user* - 发起呼叫的用户。
- *called_number* - 被叫号码。
- *rule_id* - 呼叫发起时匹配的欺诈规则 ID。
- *profile_id* - 使用的配置文件 ID。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权
