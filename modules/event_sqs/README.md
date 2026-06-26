---
title: "event_sqs 模块"
description: "event_sqs 模块是 Amazon SQS 生产者的实现。它作为 Event Interface 的传输后端，同时也提供了一个独立连接器，可从 OpenSIPS 脚本中使用以向 SQS 队列发布消息。[https://aws.amazon.com/sqs/](https://aws.a..."
---

## 管理指南


### 概述


event_sqs 模块是 Amazon SQS 生产者的实现。它作为 Event Interface 的传输后端，同时也提供了一个独立连接器，可从 OpenSIPS 脚本中使用以向 SQS 队列发布消息。
		[https://aws.amazon.com/sqs/](https://aws.amazon.com/sqs/)


### 依赖


#### OpenSIPS 模块


此模块之前不需要加载任何模块。


#### 外部库或应用程序


运行加载此模块的 OpenSIPS 之前，必须安装以下库或应用程序：


- *AWS SDK for C++:*
按照以下步骤，您将在 Linux 系统上安装和配置 AWS SDK for C++，从而与 SQS 集成：
				[AWS SDK for C++ 安装指南](https://docs.aws.amazon.com/sdk-for-cpp/v1/developer-guide/setup-linux.html)
其他安装说明可以在以下位置找到：
				[AWS SDK for C++ GitHub 仓库](https://github.com/aws/aws-sdk-cpp)


#### 在本地计算机上部署 Amazon SQS


出于测试目的，您可以在计算机上本地运行 SQS。为此，请在计算机上启动 localstack：


```c
pip install localstack
localstack start
		
```


别忘了设置测试所需的环境变量，例如：


```c
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
		
```


您可以在此处找到一些 cli 命令，例如 create-queue、send/receive-message 等：
		[https://docs.aws.amazon.com/cli/latest/reference/sqs/](https://docs.aws.amazon.com/cli/latest/reference/sqs/)


### 导出的参数


#### queue_url (string)


此参数指定可用于直接从脚本发布消息的 SQS 队列配置，使用 sqs_publish_message() 函数或使用 raise_event 函数发送消息。


参数格式为：[ID]sqs_url，其中 ID 是此 SQS 队列实例的标识符，sqs_url 是队列的完整 URL。


queue_url 包含：


- *endpoint*
- *region*


此参数可以设置多次。


```c title="设置 queue_url 参数"
...

modparam("event_sqs", "queue_url",
	  "[q1]https://sqs.us-west-2.amazonaws.com/123456789012/Queue1")

modparam("event_sqs", "queue_url",
	  "[q2]http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/Queue2")

...
		
```


### 导出的函数


#### sqs_publish_message(queue_id, message)


向 SQS 队列发布消息。由于实际发送操作是异步完成的，此函数不会阻塞，并在排队发送消息后立即返回。


此函数可用于任何路由。


函数具有以下参数：


- *queue_id (string)* SQS 队列的 ID。必须是通过 `queue_url` modparam 定义的 ID 之一。
- *message (string)* - 要发布的消息的有效负载。


```c title="sqs_publish_message() 函数使用示例"
...

$var(msg) = "你好，这是一条发往 SQS 的消息！";
sqs_publish_message("q1", $var(msg));

...
		
```


### 示例


#### 使用 *Event Interface* 的事件驱动消息传递


OpenSIPS 的事件接口可用于通过订阅事件并在需要时引发它来向 SQS 发送消息。


步骤：


- *事件订阅：*
首先在 OpenSIPS 配置文件的 `startup_route` 中注册事件订阅：

  ```
  subscribe_event("MY_EVENT",
  	"sqs:http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/Queue2");
  		
  ```
- *通过 CLI 订阅事件：*
启动 OpenSIPS 后，您可以使用 OpenSIPS CLI 从另一个终端订阅事件：

  ```
  opensips-cli -x mi event_subscribe MY_EVENT \
  	  sqs:http://sqs.us-east-1.localhost.localstack.cloud:4566/000000000000/Queue2
  		
  ```
- *引发事件并发送消息：*
最后，要发送消息，请使用所需的消息内容引发订阅的事件：

  ```
  opensips-cli -x mi raise_event MY_EVENT 'OpenSIPS Message'
  		
  ```
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）采用 Creative Common License 4.0 许可证
