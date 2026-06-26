---
title: "XCAP 模块"
description: "该模块包含多个参数和函数，可供所有使用 XCAP 功能的模块共用。"
---

## 管理指南


### 概述


该模块包含多个参数和函数，可供所有使用 XCAP 功能的模块共用。


目前以下模块正在使用该模块：presence_xml、rls 和 xcap_client。


### 依赖


#### OpenSIPS 模块


以下模块必须在加载此模块之前加载：


- *数据库模块*。


#### 外部库或应用程序


运行加载了此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *libxml-dev*。


### 导出的参数


#### db_url(str)


数据库 URL。


*默认值为 "mysql://opensips:opensipsrw@localhost/opensips"。*


```c title="设置 db_url 参数"
...
modparam("xcap", "db_url", "dbdriver://username:password@dbhost/dbname")
...
                
```


#### xcap_table(str)


存储 XCAP 文档的数据库表名称。


*默认值为 "xcap"。*


```c title="设置 xcap_table 参数"
...
modparam("xcap", "xcap_table", "xcap")
...
                
```


#### integrated_xcap_server (int)


此参数是所用 XCAP 服务器类型的标志。如果是集成的服务器（如 AG Projects 的 OpenXCAP），
可以直接访问数据库表，该参数应设置为正值。除更新 xcap 表外，
集成服务器在用户修改规则文档时必须发送 MI 命令 refreshWatchers 
[pres_uri] [event]。


*默认值为 "0"。*


```c title="设置 integrated_xcap_server 参数"
...
modparam("xcap", "integrated_xcap_server", 1)
...
                
```


### 导出的函数


配置文件中无需使用的函数。


## 开发者指南


该模块导出的参数和函数可供其他多个模块使用。


### bind_xcap_api(xcap_api_t* api)


此函数用于绑定所需的函数。


```c title="xcap_api 结构"
...
typedef struct xcap_api {
        int integrated_server;
        str db_url;
        str xcap_table;
        normalize_sip_uri_t normalize_sip_uri;
        parse_xcap_uri_t parse_xcap_uri;
        get_xcap_doc_t get_xcap_doc;
} xcap_api_t;
...
			
```


### normalize_xcap_uri


此函数对 XCAP 文档中发现的 SIP URI 进行规范化。它会对其取消转义，
并在缺少 SIP scheme 时添加该 scheme。返回一个静态分配的字符串
缓冲区，其中包含规范化后的形式。


参数：


- *uri*-
				需要规范化的 URI


### parse_xcap_uri


此函数解析给定的 XCAP URI。


参数：


- *uri*-
				需要解析的 URI（字符串格式）
- *xcap_uri*-
				xcap_uri_t 结构体，将用解析后的信息填充

  ```
  参数类型：
  ...
  typedef struct {
      char buf[MAX_URI_SIZE];
      str uri;
      str root;
      str auid;
      str tree;
      str xui;
      str filename;
      str selector;
  } xcap_uri_t;
  ...
                          
  ```


### get_xcap_doc


此函数从本地 DB 查询所需的 XCAP 文档。它将返回文档及其
对应的 etag。


参数：


- *user*-
				文档所有者的 URI 用户部分
- *domain*-
				文档所有者的 URI 域部分
- *type*-
                                请求的文档类型，代表 AUID，可以是 PRES_RULES、RESOURCE_LISTS、
                                RLS_SERVICES、PIDF_MANIPULATION、OMA_PRES_RULES 之一
- *filename*-
				如果指定，将用于匹配文档文件名，默认为 'index'
- *match_etag*-
				如果指定，则仅在 etag 匹配时才返回文档
- *doc*-
				返回文档的存储引用
- *etag*-
				返回文档 etag 的存储引用


### db_url


XCAP 模块将要连接的数据库 URL。


### xcap_table


用于存储 XCAP 文档的表名。默认为 'xcap'。


### integrated_server


布尔标志，指示 XCAP 服务器是否可以访问本地数据库，或者
是否使用 xcap_client 来获取文档。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享许可协议 4.0
