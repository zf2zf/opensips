---
title: "RATE_CACHER 模块"
description: "*rate_cacher* 模块提供了一种缓存和实时查询分配给客户和/或供应商的费率表的方法。它还允许实时基于成本的路由和基于成本的过滤。"
---

## 管理指南


### 概述


*rate_cacher* 模块提供了一种缓存和实时查询分配给客户和/或供应商的费率表的方法。
	它还允许实时基于成本的路由和基于成本的过滤。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他 OpenSIPS 模块。*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *无*。


### 导出的参数


#### vendors_db_url (str)


用于查询模块使用的供应商的 DB URL


*默认值为 "NULL"。*


```c title="设置 vendors_db_url 参数"
...
modparam("rate_cacher", "vendors_db_url", "mysql://opensips:opensipsrw@localhost/opensips")
...
```


#### vendors_db_table (str)


用于查询模块使用的供应商的 DB 表


*默认值为 "rc_vendors"。*


```c title="设置 vendors_db_table 参数"
...
modparam("rate_cacher", "vendors_db_table", "my_vendors_view")
...
```


#### vendors_hash_size (int)


模块内部用于保存供应商的哈希表的大小。较大的表速度更快但消耗更多内存。哈希大小必须是 2 的幂。


*默认值为 "256"。*


```c title="设置 vendors_hash_size 参数"
...
modparam("rate_cacher", "vendors_hash_size", 1024)
...
```


#### clients_db_url (str)


用于查询模块使用的客户的 DB URL


*默认值为 "NULL"。*


```c title="设置 clients_db_url 参数"
...
modparam("rate_cacher", "clients_db_url", "mysql://opensips:opensipsrw@localhost/opensips")
...
```


#### clients_db_table (str)


用于查询模块使用的客户的 DB 表


*默认值为 "rc_clients"。*


```c title="设置 clients_db_table 参数"
...
modparam("rate_cacher", "clients_db_table", "my_clients_view")
...
```


#### clients_hash_size (int)


模块内部用于保存客户的哈希表的大小。较大的表速度更快但消耗更多内存。哈希大小必须是 2 的幂。


*默认值为 "256"。*


```c title="设置 vendors_hash_size 参数"
...
modparam("rate_cacher", "clients_hash_size", 1024)
...
```


#### rates_db_url (str)


用于查询模块使用的费率表的 DB URL


*默认值为 "NULL"。*


```c title="设置 rates_db_url 参数"
...
modparam("rate_cacher", "rates_db_url", "mysql://opensips:opensipsrw@localhost/opensips")
...
```


#### rates_db_table (str)


用于查询模块使用的费率表的 DB 表


*默认值为 "rc_ratesheets"。*


```c title="设置 rates_db_table 参数"
...
modparam("rate_cacher", "rates_db_table", "my_clients_view")
...
```


### 导出的函数


#### get_client_price(client_id,is_wholesale,dialled_no,prefix_pvar,destination_pvar,price_pvar,minimum_pvar,increment_pvar)


对于从提供的客户 ID 发起的呼叫，以批发或零售质量，拨打 dialled_no，该函数将根据客户的费率表匹配拨打的号码，并返回匹配的前缀、目的地、价格、最小值和增量。


*client_id* 伪变量将保存发起此呼叫的 client_id


*is_wholesale* 伪变量将包含 1 或 0，取决于呼叫是批发还是零售（见客户费率表配置）。


*dialled_no* 伪变量包含 DNIS——当前呼叫的拨叫号码。它需要是 E164 格式，不带前导 +


*prefix* 伪变量将包含从客户费率表匹配的前缀


*destination* 伪变量将包含从客户费率表匹配的目的地


*price* 伪变量将包含从客户费率表匹配的价格


*minimum* 伪变量将包含从客户费率表匹配的最小值


*increment* 伪变量将包含从客户费率表匹配的增量


可能的参数类型


- *所有参数* - 字符串/整数或伪变量


此函数可用于任何路由。


```c title="get_client_price 使用示例"
...
if (get_client_price("my_client",1,"4072794242",$var(prefix),$var(dest),$var(price),$var(min),$var(inc))) {
                        xlog("我们匹配到了 $var(prefix) , $var(dest) , $var(price) , $var(min) , $var(inc) 用于客户的费率表\n");
                }

...
```


#### get_vendor_price(vendor_id,dialled_no,prefix_pvar,destination_pvar,price_pvar,minimum_pvar,increment_pvar)


对于发送到提供的供应商 ID 的呼叫，拨打 dialled_no，该函数将根据供应商的费率表匹配拨打的号码，并返回匹配的前缀、目的地、价格、最小值和增量。


*vendor_id* 伪变量将保存 vendor_id


*dialled_no* 伪变量包含 DNIS——当前呼叫的拨叫号码。它需要是 E164 格式，不带前导 +


*prefix* 伪变量将包含从供应商费率表匹配的前缀


*destination* 伪变量将包含从供应商费率表匹配的目的地


*price* 伪变量将包含从供应商费率表匹配的价格


*minimum* 伪变量将包含从供应商费率表匹配的最小值


*increment* 伪变量将包含从供应商费率表匹配的增量


可能的参数类型


- *所有参数* - 字符串/整数或伪变量


此函数可用于任何路由。


```c title="get_vendor_price 使用示例"
...
if (get_vendor_price("my_vendor","4072794242",$var(prefix),$var(dest),$var(price),$var(min),$var(inc))) {
                        xlog("我们匹配到了 $var(prefix) , $var(dest) , $var(price) , $var(min) , $var(inc) 用于供应商的费率表\n");
                }

...
```


#### cost_based_filtering(client_id,is_wholesale,vendors_csv,dialled_no,desired_margin,out_vendor_csv)


对于从提供的客户 ID 发起的呼叫，以批发或零售质量，拨打 dialled_no，该函数将移除（从 vendor_csv 列表中）不符合 desired_margin 条件的供应商，并将 out_vendor_csv 变量设置为满足 margin 条件的供应商列表，同时保持 vendor_csv 变量中提供的初始顺序。


*client_id* 伪变量将保存发起此呼叫的 client_id


*is_wholesale* 伪变量将包含 1 或 0，取决于呼叫是批发还是零售（见客户费率表配置）。


*vendors_csv* 伪变量包含需要根据所需利润 margin 进行过滤的供应商列表（只保留与此次呼叫所需百分比利润 margin 匹配的供应商）


*dialled_no* 伪变量包含 DNIS——当前呼叫的拨叫号码。它需要是 E164 格式，不带前导 +


*desired_margin* 伪变量包含脚本编写者希望实现的最小整数利润 margin，基于客户的卖出价和供应商的买入价。使用的公式是：vendor_margin=(client_price - results[i])*100/client_price)。如果 vendor_margin 高于 desired_margin，则该供应商可以使用。所需利润 margin 可以是正数（呼叫将盈利）或负数（呼叫将导致亏损）。


*out_vendors_csv* 伪变量是一个输出参数，pvar 将被填充满足 desired_margin 条件的供应商的 CSV 列表


可能的参数类型


- *所有参数* - 字符串/整数或伪变量


此函数可用于 REQUEST 或 FAILURE 路由。


```c title="cost_based_filtering 使用示例"
...


# 如果我们从 testClient 收到一个呼叫，以其批发质量，
# 拨打号码 40720018124，我们必须从供应商列表
# 'testVendor,testVendor2' 中选择，基于 0 的利润 margin
#（我们不想在此次呼叫上亏损），
# 那么 $avp(out_vendor_csv) 将包含我们需要使用的供应商
# 基于上述呼叫特性，$avp(carrierlist) 中提供的供应商顺序
# 和所需的利润 margin
$avp(client_id)="testClient";
$avp(is_ws)=1;  
$avp(carrierlist)="testVendor,testVendor2";
$avp(dnis)="40720018124";
$avp(profit_margin)=0;

if (cost_based_filtering("$avp(client_id)","$avp(is_ws)","$avp(carrierlist)","$avp(dnis)","$avp(profit_margin)","$avp(out_vendor_result)")) {
	xlog("XXX - 在 $avp(carrierlist) 运营商中，我们只应使用 $avp(out_vendor_result) \n");
...
```


#### cost_based_ordering(client_id,is_wholesale,vendors_csv,dialled_no,desired_margin,out_vendor_csv)


对于从提供的客户 ID 发起的呼叫，以批发或零售质量，拨打 dialled_no，该函数将移除（从 vendor_csv 列表中）不符合 desired_margin 条件的供应商，并将 out_vendor_csv 变量设置为满足 margin 条件的供应商列表，按其利润 margin 降序排列（从最盈利的供应商到仍满足 margin 条件的最不盈利的供应商）


*client_id* 伪变量将保存发起此呼叫的 client_id


*is_wholesale* 伪变量将包含 1 或 0，取决于呼叫是批发还是零售（见客户费率表配置）。


*vendors_csv* 伪变量包含需要根据所需利润 margin 进行过滤的供应商列表（只保留与此次呼叫所需百分比利润 margin 匹配的供应商）


*dialled_no* 伪变量包含 DNIS——当前呼叫的拨叫号码。它需要是 E164 格式，不带前导 +


*desired_margin* 伪变量包含脚本编写者希望实现的最小整数利润 margin，基于客户的卖出价和供应商的买入价。使用的公式是：vendor_margin=(client_price - results[i])*100/client_price)。如果 vendor_margin 高于 desired_margin，则该供应商可以使用。所需利润 margin 可以是正数（呼叫将盈利）或负数（呼叫将导致亏损）。


*out_vendors_csv* 伪变量是一个输出参数，pvar 将被填充满足 desired_margin 条件的供应商的 CSV 列表


可能的参数类型


- *所有参数* - 字符串/整数或伪变量


此函数可用于任何路由。


```c title="cost_based_ordering 使用示例"
...
# 如果我们从 testClient 收到一个呼叫，以其批发质量，
# 拨打号码 40720018124，我们必须从供应商列表
# 'testVendor,testVendor2' 中选择，基于 0 的利润 margin
#（我们不想在此次呼叫上亏损），
# 那么 $avp(out_vendor_csv) 将包含我们需要使用的供应商
# 基于上述呼叫特性和所需的利润 margin
# $avp(carrierlist) 中的顺序无关紧要，供应商将
# 从最盈利到最不盈利排序
$avp(client_id)="testClient";
$avp(is_ws)=1;  
$avp(carrierlist)="testVendor,testVendor2";
$avp(dnis)="40720018124";
$avp(profit_margin)=0;

if (cost_based_ordering("$avp(client_id)","$avp(is_ws)","$avp(carrierlist)","$avp(dnis)","$avp(profit_margin)","$avp(out_vendor_result)")) {
	xlog("XXX - 在 $avp(carrierlist) 运营商中，我们只应使用 $avp(out_vendor_result) ，按提供的顺序\n");

...
```


### 导出的 MI 函数


#### rate_cacher:addVendor


替代已废弃的 MI 命令：*rc_addVendor*。


添加新供应商，不为其分配任何费率表。


名称：*rate_cacher:addVendor*


参数：


- *vendorName* - 要添加的供应商名称


MI FIFO 命令格式：


```c
## 添加新供应商
# opensips-cli -x mi rate_cacher:addVendor myNewVendor
		
```


#### rate_cacher:deleteVendor


替代已废弃的 MI 命令：*rc_deleteVendor*。


从内存中删除供应商及其关联的费率表（如果有）


名称：*rate_cacher:deleteVendor*


参数：


- *vendorName* - 要删除的供应商名称


MI FIFO 命令格式：


```c
## 删除供应商
# opensipss-cli -x mi rate_cacher:deleteVendor myNewVendor
		
```


#### rate_cacher:reloadVendorRate


替代已废弃的 MI 命令：*rc_reloadVendorRate*。


重新加载提供的费率表并将其分配给供应商


名称：*rate_cacher:reloadVendorRate*


参数：


- *vendorName* - 供应商名称
- *ratesheet_id* - 要重新加载并分配的费率表 ID


MI FIFO 命令格式：


```c
## 重新加载供应商费率表
# opensips-cli -x mi rate_cacher:reloadVendorRate myVendor 3
		
```


#### rate_cacher:deleteVendorRate


替代已废弃的 MI 命令：*rc_deleteVendorRate*。


从供应商中删除分配的费率表


名称：*rate_cacher:deleteVendorRate*


参数：


- *vendorName* - 供应商名称


MI FIFO 命令格式：


```c
## 重新加载供应商费率表
# opensips-cli -x mi rate_cacher:deleteVendorRate myVendor
		
```


#### rate_cacher:getVendorPrice


替代已废弃的 MI 命令：*rc_getVendorPrice*。


获取提供供应商和拨叫号码的所有费率表信息（目的地名称、价格、最小值、增量）


名称：*rate_cacher:getVendorPrice*


参数：


- *vendorName* - 供应商名称
- *dialledNumber* - 在上述供应商费率表中匹配的号码


MI FIFO 命令格式：


```c
## 查询 myVendor 拨打 4072731825 号码的价格
#/usr/local/bin/opensips-cli -x mi rate_cacher:getVendorPrice myVendor 4072731825
{
    "prefix": "40727",
    "destination": "ROMANIA MOBILE VODAFONE",
    "price": 0.05,
    "minimum": 1,
    "increment": 1,
    "currency": "USD"
}
		
```


#### rate_cacher:addClient


替代已废弃的 MI 命令：*rc_addClient*。


添加新客户，不为其分配任何费率表。


名称：*rate_cacher:addClient*


参数：


- *clientName* - 要添加的客户名称


MI FIFO 命令格式：


```c
## 添加新客户
# opensips-cli -x mi fifo rate_cacher:addClient myNewClient
		
```


#### rate_cacher:deleteClient


替代已废弃的 MI 命令：*rc_deleteClient*。


从内存中删除客户及其关联的费率表（如果有）


名称：*rate_cacher:deleteClient*


参数：


- *clientName* - 要删除的客户名称


MI FIFO 命令格式：


```c
## 删除客户
# opensips-cli -x mi rate_cacher:deleteClient myClient
		
```


#### rate_cacher:reloadClientRate


替代已废弃的 MI 命令：*rc_reloadClientRate*。


重新加载提供的费率表并将其分配给客户


名称：*rate_cacher:reloadClientRate*


参数：


- *clientName* - 客户名称
- *isWholesale* - 费率表是分配在批发还是零售质量上
- *ratesheet_id* - 要重新加载并分配的费率表 ID


MI FIFO 命令格式：


```c
## 重新加载客户的批发费率表，分配费率 ID 3
# opensips-cli -x mi rate_cacher:reloadClientRate myClient 1 3
		
```


#### rate_cacher:deleteClientRate


替代已废弃的 MI 命令：*rc_deleteClientRate*。


从客户中删除分配的费率表


名称：*rate_cacher:deleteClientRate*


参数：


- *ClientName* - 客户名称
- *isWholesale* - 删除批发还是零售费率表


MI FIFO 命令格式：


```c
## 删除客户费率表
# opensips-cli -x mi rate_cacher:deleteClientRate myClient 1
		
```


#### rate_cacher:getClientPrice


替代已废弃的 MI 命令：*rc_getClientPrice*。


获取提供客户在指定质量（批发 vs 零售）和拨叫号码上的所有费率表信息（目的地名称、价格、最小值、增量）


名称：*rate_cacher:getClientPrice*


参数：


- *ClientName* - 客户名称
- *isWholesale* - 批发 = 1，零售 = 0
- *dialledNumber* - 在上述客户费率表中匹配的号码


MI FIFO 命令格式：


```c
## 查询 myClient 在零售质量上拨打 4072731825 号码的价格
#/usr/local/bin/opensips-cli -x mi rate_cacher:getClientPrice myClient 0 4072731825
{
    "prefix": "40727",
    "destination": "ROMANIA MOBILE VODAFONE",
    "price": 0.03,
    "minimum": 1,
    "increment": 1,
    "currency": "USD"
}

		
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0（Creative Common License 4.0）授权。
