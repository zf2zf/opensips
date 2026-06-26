---
title: "mmgeoip 模块"
description: "此模块是MaxMind GeoIP API的轻量级包装器。它为OpenSIPS脚本添加了IP地址到位置的查询功能。"
---

## 管理指南


### 概述


此模块是MaxMind GeoIP API的轻量级包装器。它为OpenSIPS脚本添加了IP地址到位置的查询功能。


查询针对免费提供的GeoLite City数据库执行；付费的GeoIP City数据库可兼容使用。所有API提供的查询字段都可以通过脚本访问。更多信息请访问MaxMind网站了解位置数据库。


该模块兼容旧的GeoIP和更新的GeoIP2 API及数据库。


### 依赖


#### OpenSIPS 模块


以下模块必须在此模块之前加载：


- *不依赖其他OpenSIPS模块*。


#### 外部库或应用程序


运行此模块加载的OpenSIPS之前必须安装以下库或应用程序：


- *libGeoIP* - 用于旧的GeoIP API和数据库；
- *libmaxminddb* - 用于GeoIP2 API和数据库。


您可以通过在编译模块之前设置GEOIP环境变量来选择要使用的GeoIP库，设置为以下值之一：


- *GEOIPLEGACY **** 将使用libGeoIP库
- *GEOIP2 **** 将使用libmaxminddb库；


重要提示：如果未安装选定的库，模块将无法编译。
注意：如果未设置GEOIP环境变量，模块将尝试查找已安装的GeoIP库，优先选择libmaxminddb。


### 导出的参数


#### mmgeoip_city_db_path (string)


GeoLite或GeoIP City数据库文件的路径。


*必选参数。*


```c title="设置 'mmgeoip_city_db_path' 参数"
...
modparam("mmgeoip", "mmgeoip_city_db_path",
  "/usr/share/GeoIP/GeoLiteCity.dat")
...
		
```


#### cache_type (string)


数据库内存缓存选项。以下选项可用：


- *STANDARD* - 从文件系统读取数据库；
			最少内存使用；
- *MMAP_CACHE* - 将数据库加载到mmap分配的内存中；
			*警告：如果数据库文件在运行时更改，此选项将导致分段错误！*
- *MEM_CACHE_CHECK* - 将数据库加载到内存中；
			此模式检查数据库更新；如果数据库被修改，文件将在60秒后重新加载；它比*MMAP_CACHE*慢，但允许重新加载；


此参数的默认值为*MMAP_CACHE*。


注意：如果使用libmaxminddb，此参数将被忽略，因为该库只支持将数据库加载到mmap分配的内存中。


```c title="设置 'cache_type' 参数"
...
modparam("mmgeoip", "cache_type","MEM_CACHE_CHECK")
...
		
```


### 导出的函数


#### mmg_lookup([fields,]src,dst)


查找与`field`指定的与IP地址`src`关联的信息。结果数据以*反向*顺序加载到`dst` AVP中。


参数：


- *fields* (string, 可选) - 由以下分隔符之一分隔的元素列表：':'、'|'、','、'/'或' '（空格）。接受以下token：
		  
			 *lat* - 纬度
			 *lon* - 经度
			 *cont* - 大陆
			 *cc* - 国家代码
			 *reg* - 地区
			 *city* - 城市
			 *pc* - 邮政编码
			 *dma* - DMA代码
			 *ac* - 区号，仅在旧的GeoIP数据库中可用
			 *tz* - 时区
- *src* (string) - IP地址
- *dst* (var) - AVP，用于返回与IP关联的信息。


使用GeoIP2库时，给定`fields`参数中的每个token都可以作为与IP关联的数据结构中特定键的路径。因此，token格式为'*key_name*.*key_name*[*.key_name*]*'。如果键的值是数组而不是子键名称，应提供索引以选择适当的值。


示例token：'*country.names.en*'、'*continent.names.en*'、'*subdivisions.0.iso_code*'。有关数据库中可用字段以及用于检索它们的键名称的更多详细信息，请参阅MaxMind GeoIP2文档。


此函数可用于REQUEST_ROUTE、FAILURE_ROUTE、ONREPLY_ROUTE、BRANCH_ROUTE、ERROR_ROUTE和LOCAL_ROUTE。


```c title="mmg_lookup 使用示例"
...
if(mmg_lookup("lon:lat",$si,$avp(lat_lon))) {
  xlog("L_INFO","源IP纬度:$(avp(lat_lon)[0])\n");
  xlog("L_INFO","源IP经度:$(avp(lat_lon)[1])\n");
};
...
# 仅GeoIP2支持的字段格式
if(mmg_lookup("continent.names.en:country.iso_code,",$si,$avp(geodata))) {
  xlog("L_INFO","源IP国家代码:$(avp(geodata)[0])\n");
  xlog("L_INFO","源IP大陆:$(avp(geodata)[1])\n");
};
...
		
```


### 已知问题


目前无法在不首先停止服务器的情况下加载更新的位置数据库。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即.md扩展名）均采用知识共享署名4.0许可证。
