---
title: "XCAP_Client 模块"
description: "该模块是 OpenSIPS 的 XCAP 客户端，可供其他模块使用。它通过发送 HTTP GET 请求来获取 XCAP 元素（文档或部分内容）。它还提供条件查询支持。它使用 libcurl 库作为客户端 HTTP 传输库。"
---

## 管理指南


### 概述


该模块是 OpenSIPS 的 XCAP 客户端，可供其他模块使用。
	它通过发送 HTTP GET 请求来获取 XCAP 元素（文档或部分内容）。
	它还提供条件查询支持。
	它使用 libcurl 库作为客户端 HTTP 传输库。


该模块提供通用的 xcap 客户端接口函数，
	允许从 xcap 服务器请求特定元素。
	此外，它还提供接收文档后将其存储和更新到数据库的服务。
	在这种情况下，只需对模块发出初始请求 - xcapGetNewDoc - 这相当于
	请求模块从那时起处理所引用的文档，
	以确保数据库中始终存在最新版本。


更新方法也是可配置的，
	可以是周期性查询（适用于任何类型的 xcap
	服务器），也可以是服务器在更新时发送的 MI 命令。


该模块目前被 presence_xml 模块使用，
	前提是未设置 'integrated_xcap_server' 参数。


### 依赖


#### OpenSIPS 模块


以下模块必须在加载此模块之前加载：


- *xcap*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *libxml-dev*。
- *libcurl-dev*。


### 导出的参数


#### periodical_query(int)


一个标志，用于禁用周期性查询作为该模块负责的文档的更新方法。
	当 xcap 服务器能够在发生更改时发送导出的
	MI 命令，或者当 OpenSIPS 中的另一个模块处理更新时，
	可以禁用它。


要禁用它，将此参数设置为 0。


*默认值为 "1"。*


```c title="设置 periodical_query 参数"
...
modparam("xcap_client", "periodical_query", 0)
...
```


#### query_period(int)


如果未禁用周期性查询，则应设置此项。
	表示应查询 xcap 服务器更新的时间间隔


要禁用它，将此参数设置为 0。


*默认值为 "100"。*


```c title="设置 query_period 参数"
...
modparam("xcap_client", "query_period", 50)
...
```


### 导出的函数


配置文件中无需使用的函数。


### 导出的 MI 函数


#### refreshXcapDoc


当存储的文档发生更改时，xcap 服务器应发送的 MI 命令。


名称：*refreshXcapDoc*


参数：


- doc_uri: 文档的 URI
- port: xcap 服务器的端口


MI FIFO 命令格式：


```c
...
opensips-cli -x mi refreshXcapDoc /xcap-root/resource-lists/users/eyebeam/buddies-resource-list.xml 8000
...
		
```


## 开发者指南


该模块导出的函数允许从 xcap 服务器选择和检索元素，
	以及注册一个回调函数，当收到 MI 命令 refreshXcapDoc
	并检索到相关文档时调用。


### bind_xcap_client_api(xcap_client_api_t* api)


此函数用于绑定所需的函数。


```c title="xcap_client_api 结构"
...
typedef struct xcap_client_api {
	
	/* xcap 节点选择和检索函数*/
	xcap_get_elem_t get_elem;
	xcap_nodeSel_init_t int_node_sel;
	xcap_nodeSel_add_step_t add_step;
	xcap_nodeSel_add_terminal_t add_terminal;
	xcap_nodeSel_free_t free_node_sel;
	xcapGetNewDoc_t getNewDoc; /* 对模块的初始请求，
	用于获取不存在于 xcap 数据库表中的文档
	并处理其更新*/

	/* 注册文档更改回调的函数*/
	register_xcapcb_t register_xcb;
}xcap_client_api_t;
...
			
```


### get_elem


字段类型：


```c
...
typedef char* (*xcap_get_elem_t)(char* xcap_root,
xcap_doc_sel_t* doc_sel, xcap_node_sel_t* node_sel);
...
					
```


此函数发送 HTTP 请求并从 xcap 服务器获取指定信息。


参数含义：


- *xcap_root*-
				XCAP 服务器地址；
- *doc_sel*-
				包含文档选择信息的结构体；

  ```
  参数类型：
  ...
  typedef struct xcap_doc_sel
  {
  	str auid; /* 应用程序定义的唯一 ID*/
  	int type; /* AUID 之后路径段的类型
  				必须是 GLOBAL_TYPE（"global"）或
  				USERS_TYPE（"users"）*/ 
  	str xid; /* XCAP 用户标识符
  				（如果类型是 USERS_TYPE）*/
  	str filename; 
  }xcap_doc_sel_t;
  ...
  ```
- *node_sel*-
结构体，包含节点选择信息；

  ```
  参数类型：
  ...
  typedef struct xcap_node_sel
  {
  	step_t* steps;
  	step_t* last_step;
  	int size;
  	ns_list_t* ns_list;
  	ns_list_t* last_ns;
  	int ns_no;
  
  }xcap_node_sel_t;
  
  typedef struct step
  {
  	str val;
  	struct step* next;
  }step_t;
  
  typedef struct ns_list
  {
  	int name;
  	str value;
  	struct ns_list* next;
  }ns_list_t;
  ...
  ```
节点选择器表示为一个步骤列表，在路径字符串中用 '/' 分隔。
	节点的命名空间也存储在一个列表中，作为名称和值的关联，
	其中值包含在步骤各自的字符串 val 字段中。
要构建节点结构，应使用 xcap_api 中的以下函数：
	'int_node_sel'、'add_step'，如果需要还可以使用 'add_terminal'。
如果意图是检索整个文档，此参数必须为 NULL。


### register_xcb


字段类型：


```c
...
typedef int (*register_xcapcb_t)(int types, xcap_cb f);
...
	
```


- 'types' 参数可以是 PRES_RULES、RESOURCE_LISTS、
	RLS_SERVICES、OMA_PRES_RULES 和 PIDF_MANIPULATION 的组合值。


- 回调函数的类型为：


```c
...
typedef int (xcap_cb)(int doc_type, str xid, char* doc);
...
	
```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0
