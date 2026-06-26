---
title: "cachedb_dynamodb 模块"
description: "本模块是与 Amazon DynamoDB 配合工作的缓存系统实现。它使用 AWS SDK for C++ 库连接到 DynamoDB 实例。它利用 OpenSIPS 核心导出的 Key-Value 接口。[https://aws.amazon.com/pm/dynamodb/](https://aws.amazon.com/pm/d..."
---

## 管理指南


### 概述


本模块是与 Amazon DynamoDB 配合工作的缓存系统实现。它使用 AWS SDK for C++ 库连接到 DynamoDB 实例。
它利用 OpenSIPS 核心导出的 Key-Value 接口。
[https://aws.amazon.com/pm/dynamodb/](https://aws.amazon.com/pm/dynamodb/)


#### 功能


- *set* - 使用 *cachedb_store* 函数在 DynamoDB 中设置键
- *get* - 使用 *cachedb_fetch* 函数从 DynamoDB 查询键
- *remove* - 使用 *cachedb_remove* 函数从 DynamoDB 删除键
- *get_counter* - 使用 *cachedb_counter_fetch* 函数从 DynamoDB 查询具有数值的键
- *add* - 使用 *cachedb_add* 函数将给定值递增到特定项的值
- *sub* - 使用 *cachedb_sub* 函数将给定值递减到特定项的值


以下功能由 OpenSIPS 内部使用：


- *map_get*
- *map_set*
- *map_remove*


#### 表格式和 TTL 选项


与 DynamoDB 一起使用的表必须遵循特定格式。
以下是创建表的示例：


```c
aws dynamodb create-table \
--table-name TableName \
--attribute-definitions \
	AttributeName=KeyName,AttributeType=S \
--key-schema \
	AttributeName=KeyName,KeyType=HASH \
--provisioned-throughput \
	ReadCapacityUnits=5,WriteCapacityUnits=5 \
--table-class STANDARD
			
```


如果您使用上述命令创建表，则必须在 cachedb_url 中指定键：*modparam("cachedb_dynamodb", "cachedb_url", 
"dynamodb://localhost:8000/TableName?key=KeyName;val=ValName")*


有关 cachedb_url 格式的更多示例，请参阅 [cachedb_url (字符串)](#param_cachedb_url) 部分。


要为表启用 TTL（生存时间）选项（可用于 set、add 和 subtract 操作），您可以使用 TTL 选项更新表：


```c
aws dynamodb update-time-to-live --table-name TableName --time-to-live-specification
"Enabled=true, AttributeName=ttl"
			
```


有关表格式和 TTL 选项的更多信息，请访问以下链接：


[创建表](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/getting-started-step-1.html)


[生存时间 (TTL)](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/time-to-live-ttl-how-to.html)


### 优势


- *可扩展且完全托管的 NoSQL 数据库服务，由 AWS 提供*
- *与其他 AWS 服务集成，提供强大的安全性和可扩展性功能*
- *高可用性和持久性，数据跨多个 AWS 可用区复制*
- *无服务器架构，减少运营开销*
- *提供单位数响应时间，配备 DynamoDB Accelerator (DAX) 可实现更低的延迟*


### 限制


- *严重依赖索引；没有索引，查询将涉及昂贵的全表扫描*
- *不支持表连接，限制了涉及多个表的复杂查询*
- *项大小限制：每个项的大小限制为 400KB，无法增加。*


### 依赖


#### OpenSIPS 模块


加载本模块之前无需加载任何模块。


#### 外部库或应用程序


运行 OpenSIPS 并加载本模块之前，必须安装以下库或应用程序：


- *AWS SDK for C++:*
按照以下步骤，您将能够在 Linux 系统上安装和配置 AWS SDK for C++，以便与 DynamoDB 集成：
[AWS SDK for C++ 安装指南](https://docs.aws.amazon.com/sdk-for-cpp/v1/developer-guide/setup-linux.html)
其他安装说明可在此处找到：
[AWS SDK for C++ GitHub 仓库](https://github.com/aws/aws-sdk-cpp)


#### 在本地计算机上部署 DynamoDB


出于测试目的，您可以在本地运行 DynamoDB。为此，您应该按照
[这些](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.DownloadingAndRunning.html) 步骤在本地部署 DynamoDB。


别忘了始终使用以下命令运行服务器：
	
`java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -sharedDb`
在您提取 *DynamoDBLocal.jar* 的目录中运行。


### 导出的参数


#### cachedb_url (字符串)


OpenSIPS 将连接到的服务器组 URL，以便在脚本中使用 cache_store()、cache_fetch() 等操作。
可以多次设置。URL 的前缀部分将是脚本中使用的标识符。


URL 中可以出现一些默认参数：


- *region* - 指定 DynamoDB 表所在的 AWS 区域
- *key* - 指定表的 Key 列；默认值为 *"opensipskey"*
- *val* - 指定表的 Value 列，缓存操作（如 cache_store、cache_fetch 等）将在其上执行；
			默认值为 *"opensipsval"*


*cachedb_url* 的语法


- 使用先前创建的表（必须指定 key 和 value）：

  - 主机和端口
*"dynamodb://id_host:id_port/tableName?key=key1;val=val1"*
  - 区域
*"dynamodb:///tableName?region=regionName;key=key2;val=val2"*
- 使用默认 key 和 value：

  - 主机和端口
*"dynamodb://id_host:id_port/tableName"*
  - 区域
*"dynamodb:///tableName?region=regionName"*


```c title="设置 cachedb_url 参数"
...

# 单实例 URL
modparam("cachedb_dynamodb", "cachedb_url", "dynamodb://localhost:8000/table1")
modparam("cachedb_dynamodb", "cachedb_url", "dynamodb:///table2?region=central-1")


# 多实例 URL（将执行循环）
```


```c title="使用 DynamoDB 服务器"
...

cache_store("dynamodb", "call1", "10");
cache_store("dynamodb", "call2", "25", 150) // expires = 150s -可选
cache_fetch("dynamodb", "call1", $var(total));
cache_remove("dynamodb", "call1");


cache_store("dynamodb", "counter1", "200");
cache_sub("dynamodb", "counter1", 4, 1000); // expires = 1000s -必填参数
cache_add("dynamodb", "call2", 5, 0) // -此更新不会过期 -必填参数
cache_remove("dynamodb", "counter1");

...
		
```


### 导出的函数


本模块不导出在配置脚本中使用的函数。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用知识共享许可证 4.0 版授权
