---
title: "cfgutils 模块"
description: "服务器配置的有用扩展。"
---

## 管理指南


### 概述


服务器配置的有用扩展。


cfgutils 模块可用于为服务器的行为引入随机性。它提供设置函数和 "rand_event" 函数。该函数根据随机值和指定概率返回 true 或 false。例如，如果您通过 fifo 或脚本将概率值设置为 5%，那么所有对 rand_event 的调用中有 5% 将返回 false。
伪变量 "$RANDOM" 可用于引入随机值，例如到 SIP 回复中。


此模块的好处是决策的概率可以通过外部应用程序（如 Web 界面或命令行工具）进行操作。概率必须指定为百分比值，范围从 0 到 100。


该模块导出发送到 FIFO 服务器的命令，可用于通过 FIFO 接口更改全局设置。FIFO 命令为：
"set_prob"、"reset_prob" 和 "get_prob"。


此模块可用于简单的负载削减，例如以 503 错误和适当的随机 Retry-After 值回复 5% 的 Invite。


该模块还提供延迟服务器执行的函数。"sleep" 和 "usleep" 函数可用于让服务器等待特定的时间间隔。


它还可以在启动时使用（弱）加密哈希函数对服务器使用的配置文件进行哈希处理。此值被保存，以后可以与实际哈希进行比较，以检测服务器启动后此文件的修改。这些函数可作为 FIFO 命令 "check_config_hash" 和 "get_config_hash" 使用。


### 依赖


该模块依赖于以下模块（换句话说，以下列出的模块必须在此模块之前加载）：


- *无*


### 导出的参数


#### initial_probability (string)


概率的初始值。


默认值为 "10"。


```c title="initial_probability 参数使用"
   
modparam("cfgutils", "initial_probability", 15)
   
```


#### hash_file (string)


应在启动时计算哈希值的配置文件名。


如果没有给出参数，默认值为无，即禁用哈希功能。


```c title="hash_file 参数使用"
   
modparam("cfgutils", "hash_file", "/etc/opensips/opensips.cfg")
   
```


#### shv_hash_size (integer)


用于存储共享变量 ($shv) 的哈希表的大小。


默认值为 "64"。


```c title="shv_hash_size 参数使用"
modparam("cfgutils", "shv_hash_size", 1024)
```


#### shvset (string)


设置共享变量 ($shv(name)) 的值。此参数可以设置多次。


参数值的格式为：
	_name_ '=' _type_ ':' _value_


- _name_: 共享变量名
- _type_: 值的类型

  - "i": 整数值
  - "s": 字符串值
- _value_: 要设置的值


默认值为 "NULL"。


```c title="shvset 参数使用"
...
modparam("cfgutils", "shvset", "debug=i:1")
modparam("cfgutils", "shvset", "pstngw=s:sip:10.10.10.10")
...
```


#### varset (string)


设置脚本变量 ($var(name)) 的值。此参数可以设置多次。


参数值的格式为：
	_name_ '=' _type_ ':' _value_


- _name_: 共享变量名
- _type_: 值的类型

  - "i": 整数值
  - "s": 字符串值
- _value_: 要设置的值


默认值为 "NULL"。


```c title="varset 参数使用"
...
modparam("cfgutils", "varset", "init=i:1")
modparam("cfgutils", "varset", "gw=s:sip:11.11.11.11;transport=tcp")
...
```


#### lock_pool_size (integer)


在 OpenSIPS 启动时分配的动力脚本锁数量。此数字必须是 2 的幂。（即 1、2、4、8、16、32、64...）


请注意，*lock_pool_size* 参数仅影响启动时创建的动态锁数量。静态锁池仅取决于在脚本中提供给静态锁函数集的唯 一静态字符串。


默认值为 "32"。


```c title="设置 lock_pool_size 模块参数"
modparam("cfgutils", "lock_pool_size", 64)
```


### 导出的函数


#### rand_event([probability])


生成 0-100 之间的随机浮点值，如果值小于或等于当前设置的概率则返回 true。如果给定了 "probability" 参数，它将覆盖由 [rand set prob](#func_rand_set_prob) 设置的全局参数。


参数：


- probability (int, optional) - 概率覆盖


```c title="rand_event() 使用"
...
if (rand_event()) {
  append_to_reply("Retry-After: 120\n");
  sl_send_reply(503, "Try later");
  exit;
}
# 正常的消息处理继续
...
```


#### rand_set_prob(probability)


设置决策的 "概率"。


参数：


- probability (int) - 范围为 0-99（含）的数字


```c title="rand_set_prob() 使用"
...
rand_set_prob(4);
...
```


#### rand_reset_prob()


将概率重置回 [初始概率](#param_initial_probability) 值。


```c title="rand_reset_prob() 使用"
...
rand_reset_prob();
...
```


#### rand_get_prob()


返回当前概率设置，例如用于日志记录。


```c title="rand_get_prob() 使用"
...
rand_get_prob();
   
```


#### sleep(time)


等待 "time" 秒。


参数的含义如下：


- *time (int)* - 等待秒数


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE。


```c title="sleep 使用"
...
sleep(1);
...
$var(secs) = 10;
sleep($var(secs));
...
			
```


#### usleep(time)


等待 "time" 微秒。


参数的含义如下：


- *time (int)* - 等待微秒数


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE。


```c title="usleep 使用"
...
usleep(500000); # 睡眠半秒
...
			
```


#### abort()


中止服务器的调试函数。根据服务器的配置，将创建核心转储。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE。


```c title="abort 使用"
...
abort();
...
			
```


#### pkg_status()


转储私有 (PKG) 内存状态的调试函数。此信息根据常规日志级别和 memlog 设置记录到默认日志工具。您需要使用激活的内存调试编译服务器以获取详细信息。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE。


```c title="pkg_status 使用"
...
pkg_status();
...
			
```


#### shm_status()


转储共享 (SHM) 内存状态的调试函数。此信息根据常规日志级别和 memlog 设置记录到默认日志工具。您需要使用激活的内存调试编译服务器以获取详细信息。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE。


```c title="shm_status 使用"
...
shm_status();
...
			
```


#### set_count(var_to_count, ret_var)


计算给定变量的值数量。对于可以获取多个值的变量（AVP、头部）调用此函数才有意义。


结果在第二个参数中返回。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE。


```c title="set_count 使用"
...
set_count($avp(dids), $var(num_dids));
...
			
```


#### set_select_weight(int_list_var)


此函数从给定 "int_list_var" 变量的整数值形成的集合中选择一个元素。它应用遗传算法 - 轮盘赌选择从集合中选择元素。选择某个元素的概率与其权重成正比。它将返回所选元素的索引。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE。


```c title="set_select_weight 使用"
...
$var(next_gw_idx) = set_select_weight($avp(gw_success_rates));
...
			
```


#### ts_usec_delta(t1_sec, t1_usec, t2_sec, t2_usec, [delta_str], [delta_int])


此函数返回两个给定时间戳之间的绝对差。结果以 *微秒* 表示，可以作为字符串或整数返回。


**警告：**当使用 *delta_int* 时，如果差值溢出有符号整数容器（即约 35 分钟或更大的差值），函数将返回错误代码 **-1*。


此函数可用于 REQUEST_ROUTE、ONREPLY_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE。


```c title="ts_usec_delta 使用"
...
ts_usec_delta($var(t1s), 300, 10, $var(t2us), $var(diff_str));
...
			
```


#### check_time_rec(time_string, [timestamp])


如果指定的时间 recurrences 字符串与当前时间匹配，函数返回正值，否则返回负值。


对于检查当前时间以外的其他 Unix 时间戳，第二个参数将包含要检查的预期时间戳。


每个字段的语法与 RFC 2445 中的对应字段相同。


此函数可用于任何路由。成功时返回 1，失败、解析或内部错误时分别返回 -1、-2 或 -3。


参数的含义如下：


- *time_string (string)* - 将与当前时间匹配的时间 recurrences 字符串。其字段用 "|" 分隔，给出的顺序为："timezone | dtstart | dtend | duration | freq | until | interval | byday | bymday | byyday | byweekno | bymonth"。
除非定义了 "freq"，否则不使用 "freq" 之后的任何字段。如果字符串以多个空字段结尾，可以全部省略。
"timezone" 字段是可选的。它表示解释时间 recurrences 元素时使用的时区（例如 dtstart、dtend、until）。默认使用系统时区。
- *timestamp (string, optional)* - 要检查的特定 Unix 时间。函数只需在此处提供实际的 Unix 时间，无需进行任何时区调整。


此外，更复杂的时间 recurrences 字符串可以通过使用逻辑与（"&"）、或（"/"）和非（"!"）运算符连接多个时间 recurrences 字符串（上述）来构建。此外，表达式可以用括号括起来。一些示例：


- 20210104T080000|20211231T180000||WEEKLY|||MO,TU,WE,TH,FR
					&
				!20210104T120000|20211231T140000||WEEKLY|||MO,TU,WE,TH,FR
此多 recurrences 示例表达了公司 X 在 2021 年的工作日 schedule：工作日 8-18 except 12-14 间隔，此时所有人外出午餐，企业关闭。由于每个 schedule 都省略了时区，因此使用操作系统时区。
- America/New_York|20210104T090000|20210104T170000||WEEKLY|||MO,TU,WE,TH,FR
					&
				!(Europe/Amsterdam|20210427T000000|20210428T000000 / Europe/London|20211227T000000|20211228T000000)
此多 recurrences 示例表达了公司 Y 在 2021 年的工作日 schedule：工作日 9-17（纽约时区），except 欧洲节假日如国王日（4 月 27 日，荷兰）或春季银行假日（5 月 31 日，英国），此时大部分员工已飞回欧洲。


```c title="check_time_rec 使用"
...
# 仅在仍处于 2012 年且时区与布加勒斯特兼容时通过
if (check_time_rec("Europe/Bucharest|20120101T000000|20130101T000000"))
	xlog("Current system time matches the given Romanian time interval\n");
...
# 仅在 "dtstart" 起不到 30 天时通过，系统时区
if (check_time_rec("20121101T000000||p30d"))
	xlog("Current time matches the given interval\n");
...
			
```


#### get_static_lock(key)


获取与 "key" 对应的静态锁。如果锁被另一个进程占用，脚本执行将暂停直到锁被释放。如果不先释放锁就尝试再次由同一进程获取锁，将导致死锁。


静态锁函数保证两个不同的字符串永远不会指向同一个锁，从而避免在进程之间引入不必要的（和透明的！）同步。它们的缺点是参数的性质（静态字符串），这在某些场景中不合适。


参数的含义如下：


- *key (static string)* - 要被哈希以获取静态锁索引的键


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE、STARTUP_ROUTE、TIMER_ROUTE、EVENT_ROUTE。


```c title="get_static_lock 使用"
# 获取并释放静态锁 
...
get_static_lock("Zone_1");
...
release_static_lock("Zone_1");
...
```


#### release_static_lock(key)


释放与 "key" 对应的静态锁。如果锁未被获取，则什么也不会发生。


参数的含义如下：


- *key (static string)* - 要被哈希以获取静态锁索引的键。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE、STARTUP_ROUTE、TIMER_ROUTE|EVENT_ROUTE。


```c title="release_static_lock 使用"
# 获取并释放静态锁 
...
get_static_lock("Zone_1");
...
release_static_lock("Zone_1");
...
```


#### get_dynamic_lock(key)


获取与 "key" 对应的动态锁。如果锁被另一个进程占用，脚本执行将暂停直到锁被释放。如果不先释放锁就尝试由同一进程再次获取锁，将导致死锁。


动态锁函数的优点是允许将字符串变量作为参数，但缺点是两个字符串可能具有相同的哈希值，从而指向同一个锁。因此，要么脚本的两个完全不同区域被同步（它们不会并行执行），要么一个进程可能在两个不同的（但哈希相同的）字符串上连续获取两个锁时最终陷入死锁。要解决后一个问题，使用 [strings share lock](#func_strings_share_lock) 函数测试两个字符串是否哈希到同一个动态锁。


参数的含义如下：


- *key (var)* - 要被哈希以从池中获取动态锁索引的键


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE、STARTUP_ROUTE、TIMER_ROUTE|EVENT_ROUTE。


```c title="get_dynamic_lock 使用"
...
# 在 "Call-ID" 头部字段值上获取并释放动态锁
if (!get_dynamic_lock($ci)) {
	xlog("Error while getting dynamic lock!\n");
}
...
if (!release_dynamic_lock($ci) {
	xlog("Error while releasing dynamic lock!\n");
}
...
```


#### release_dynamic_lock(key)


释放与 "key" 对应的动态锁。如果锁未被获取，则什么也不会发生。


参数的含义如下：


- *key (var)* - 要被哈希以从池中获取动态锁索引的键


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE、STARTUP_ROUTE、TIMER_ROUTE|EVENT_ROUTE。


```c title="release_dynamic_lock 使用"
...
# 在 "Call-ID" 头部字段值上获取并释放动态锁
if (!get_dynamic_lock($ci)) {
	xlog("Error while getting dynamic lock!\n");
}
...
if (!release_dynamic_lock($ci) {
	xlog("Error while releasing dynamic lock!\n");
}
...
```


#### strings_share_lock(key1, key2)


一个用于测试两个字符串是否会产生相同哈希值的函数。其目的是防止当一个进程在两个恰好指向同一个锁的字符串上连续获取两个动态锁时产生的死锁。


理论上，两个字符串产生相同哈希值的几率随着 [lock pool size](#param_lock_pool_size) 参数的增加而降低。
换句话说，您为模块配置的动态锁越多，您的脚本所有单独受保护区域并行运行而无需相互等待的机会就越大。


参数的含义如下：


- *key1, key2 (string)* - 将比较其哈希值的字符串


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE、STARTUP_ROUTE、TIMER_ROUTE|EVENT_ROUTE。


```c title="strings_share_lock 使用"
...
# 连续获取两个动态锁的正确方式
if (!get_dynamic_lock($avp(foo))) {
	xlog("Error while getting dynamic lock!\n");
}

if (!strings_share_lock($avp(foo), $avp(bar)) {
	if (!get_dynamic_lock($avp(bar))) {
		xlog("Error while getting dynamic lock!\n");
	}
}
...
if (!strings_share_lock($avp(foo), $avp(bar)) {
	if (!release_dynamic_lock($avp(bar)) {
		xlog("Error while releasing dynamic lock!\n");
	}
}

if (!release_dynamic_lock($avp(foo)) {
	xlog("Error while releasing dynamic lock!\n");
}
...
```


#### get_accurate_time(sec, usec, [str_sec_usec])


获取具有微秒精度的当前 Unix 时间戳。可选地，将此值打印为浮点数（第三个参数）。


参数的含义如下：


- *sec (int)* - 当前 Unix 时间戳（整数部分）
- *usec (int)* - 当前 Unix 时间戳（小数部分）
- *str_sec_usec (string, optional)* - 作为浮点数的当前 Unix 时间戳（6 位精度）


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE、STARTUP_ROUTE、TIMER_ROUTE、EVENT_ROUTE。


```c title="get_accurate_time 使用"
...
get_accurate_time($var(sec), $var(usec));
xlog("Current Unix timestamp: $var(sec) s, $var(usec) us\n");
...
```


#### shuffle_avps(name)


随机洗牌带有 *name* 的 AVP。


参数的含义如下：


- *name (variable)* - 要洗牌的 AVP 名称。


此函数可用于 REQUEST_ROUTE、FAILURE_ROUTE、BRANCH_ROUTE、LOCAL_ROUTE 和 ONREPLY_ROUTE。


```c title="shuffle_avps 使用"
...
$avp(foo) := "str1";
$avp(foo)  = "str2";
$avp(foo)  = "str3";
xlog("Initial AVP list is: $(avp(foo)[*])\n");       # str3 str2 str1
if(shuffle_avps( $avp(foo) ))
    xlog("Shuffled AVP list is: $(avp(foo)[*])\n");  # str1, str3, str2 (例如)
...
					
```


### 导出的异步函数


#### sleep(seconds)


等待一定秒数。此函数与 [sleep](#func_sleep) 完全相同，但以异步方式执行。脚本执行被暂停直到等待完成；然后 OpenSIPS 通过 resume 路由恢复脚本执行。


要阅读和理解异步函数、如何使用它们及其优势，请参阅 OpenSIPS 在线手册。


```c title="async sleep 使用"
{
...
async( sleep("5"), after_sleep );
}

route[after_sleep] {
...
}
```


#### usleep(seconds)


等待一定微秒数。此函数与 [usleep](#func_usleep) 完全相同，但以异步方式执行。脚本执行被暂停直到等待完成；然后 OpenSIPS 通过 resume 路由恢复脚本执行。


要阅读和理解异步函数、如何使用它们及其优势，请参阅 OpenSIPS 在线手册。


```c title="async usleep 使用"
{
...
async( usleep("1000"), after_usleep );
}

route[after_usleep] {
...
}
```


### 导出的 MI 函数


#### rand_set_prop


将概率值设置为给定参数。


参数：


- *prob_proc* - 参数应为百分比值（0 到 99 的数字）。


```c title="rand_set_prob 使用"
...
$ opensips-cli -x mi rand_set_prob 10
...
```


#### rand_reset_prob


将概率值重置为初始开始值。


此命令不需要参数。


```c title="rand_reset_prob 使用"
...
$ opensips-cli -x mi rand_reset_prob
...
```


#### rand_get_prob


返回当前概率设置。


函数返回当前概率值。


```c title="rand_get_prob 使用"
...
$ opensips-cli -x mi get_prob
The actual probability is 50 percent.
...
```


#### check_config_hash


检查当前配置文件哈希是否与存储的哈希相同。


如果哈希值相同，函数返回 200 OK，如果不相同则返回 400，如果没有配置哈希文件则返回 404，错误时返回 500。另外会打印简短的文本消息。


```c title="check_config_hash 使用"
...
$ opensips-cli -x mi check_config_hash
The actual config file hash is identical to the stored one.
...
```


#### get_config_hash


返回存储的配置文件哈希。


成功时函数返回 200 OK 和哈希值；如果没有配置哈希文件则返回 404。


```c title="get_config_hash 使用"
...
$ opensips-cli -x mi get_config_hash
1580a37104eb4de69ab9f31ce8d6e3e0
...
```


#### shv_set


设置共享变量 ($shv(name)) 的值。


参数：


- *name* : 共享变量名
- *type* : 值的类型

  - "int": 整数值
  - "str": 字符串值
- *value* : 要设置的值


```c title="shv_set 使用"
...
$ opensips-cli -x mi shv_set debug int 0
...
```


#### shv_get


获取共享变量 ($shv(name)) 的值。


参数：


- *name* : 共享变量名。如果此参数缺失，则返回所有共享变量。


```c title="shv_get 使用"
...
$ opensips-cli -x mi shv_get debug
$ opensips-cli -x mi shv_get
...
```


### 导出的伪变量


#### $env(name)


此 PV 提供对环境变量 'name' 的访问。


```c title="env(name) 伪变量使用"
...
xlog("PATH environment variable is $env(PATH)\n");
...
				 
```


#### $RANDOM


返回 [0 - 2^31) 范围内的随机值。


```c title="RANDOM 伪变量使用"
...
$avp(10) = ($RANDOM / 16777216); # 2^24
if ($avp(10) < 10) {
   $avp(10) = 10;
}
append_to_reply("Retry-After: $avp(10)\n");
sl_send_reply(503, "Try later");
exit;
# 正常的消息处理继续
   
				 
```


#### $ctime(name)


PV 提供对分解时间属性的访问。


"name" 可以是：


- *sec* - 返回秒数（int 0-59）
- *min* - 返回分钟数（int 0-59）
- *hour* - 返回小时数（int 0-23）
- *mday* - 返回日期（int 0-59）
- *mon* - 返回月份（int 1-12）
- *year* - 返回年份（int，例如 2008）
- *wday* - 返回星期几（int，1=周日 - 7=周六）
- *yday* - 返回一年中的第几天（int，1-366）
- *isdst* - 返回夏令时状态（int，0 - DST 关闭，>0 DST 开启）


```c title="ctime(name) 伪变量使用"
...
if ($ctime(year) == 2008) {
	xlog("request: $rm from $fu to $ru in year 2008\n");
}
...
				 
```


#### $shv(name)


这是存储在共享内存中的伪变量类。$shv(name) 的值在所有 opensips 进程中可见。每个 "shv" 有单个值，初始化为整数 0。您可以使用 "shvset" 参数初始化共享变量。模块导出一组 MI 函数来获取/设置共享变量的值。


```c title="shv(name) 伪变量使用"
...
modparam("cfgutils", "shvset", "debug=i:1")
...
if ($shv(debug) == 1) {
	xlog("request: $rm from $fu to $ru\n");
}
...
				 
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0 版授权
