---
title: "Web3 Auth 模块"
---

## 概述


*auth_web3* 模块为 OpenSIPS 提供基于 Web3 的认证，
            通过区块链技术和 ENS（以太坊名称服务）解析实现 SIP 认证。


此模块与 Oasis Sapphire 区块链网络集成，
            以验证 SIP 摘要认证响应并将 ENS 名称解析为钱包地址。


### 依赖


以下模块必须在此模块之前加载：


- *无* - 不依赖其他 OpenSIPS 模块


外部库或应用程序：


- *libcurl* - 用于对区块链网络的 HTTP RPC 调用
- *OpenSSL* - 用于加密操作


### ENS 技术细节


该模块支持以下功能的 ENS（以太坊名称服务）认证：


- *Namehash 解析* - 将 ENS 名称转换为 namehash 以进行合约调用
- *多网络支持* - 以太坊主网上的 ENS 解析，在 Oasis Sapphire 上认证
- *包装域名支持* - 处理 .eth 域名和自定义 TLD
- *解析器路径* - 遵循标准 ENS 解析器合约模式


### 认证函数比较


下表比较了认证函数：


| 函数 | 头域类型 | 使用场景 | 挑战函数 |
| --- | --- | --- | --- |
| web3_www_authenticate | Authorization | 最终用户认证 | www_challenge |
| web3_proxy_authenticate | Proxy-Authorization | 代理认证 | proxy_challenge |


## 多网络配置


auth_web3 模块支持双网络认证，
            允许 ENS 解析和认证在不同区块链网络上运行。
            这使得生产部署能够：
            ENS 解析在以太坊主网上进行，而认证在 Oasis Sapphire 上进行。


### 网络操作模式


#### 单网络模式（后备）


当 web3_ens_rpc_url 未配置时，
                    所有区块链操作都使用 web3_authentication_rpc_url 中指定的相同 RPC 端点。
                    此模式适用于 ENS 和认证合约部署在同一网络上的情况。


```c
# 单网络配置
modparam("auth_web3", "web3_authentication_rpc_url", "https://ethereum-sepolia-rpc.publicnode.com")
modparam("auth_web3", "web3_authentication_contract_address", "0xYourContract")
# ens_rpc_url 未设置 - 将使用 authentication_rpc_url 进行 ENS
                
```


#### 双网络模式


当 web3_ens_rpc_url 已配置时，
                    ENS 解析查询使用指定的以太坊 RPC 端点，
                    而认证查询使用 Oasis Sapphire RPC 端点。
                    这是推荐的生产配置。


```c
# 双网络配置
# 在 Oasis Sapphire 上认证
modparam("auth_web3", "web3_authentication_rpc_url", "https://testnet.sapphire.oasis.dev")
modparam("auth_web3", "web3_authentication_contract_address", "0xYourOasisContract")

# 在以太坊上进行 ENS 解析
modparam("auth_web3", "web3_ens_rpc_url", "https://eth.drpc.org")
modparam("auth_web3", "web3_ens_registry_address", "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e")
                
```


### 常见网络配置


#### 生产设置


生产部署通常使用以太坊主网进行 ENS，
                    使用 Oasis Sapphire 主网进行认证：


```c
loadmodule "auth_web3.so"

# Oasis Sapphire 主网
modparam("auth_web3", "web3_authentication_rpc_url", "https://sapphire.oasis.io")
modparam("auth_web3", "web3_authentication_contract_address", "0xYourProductionContract")

# 用于 ENS 的以太坊主网
modparam("auth_web3", "web3_ens_rpc_url", "https://eth.drpc.org")
modparam("auth_web3", "web3_ens_registry_address", "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e")

# 可选：启用调试日志
modparam("auth_web3", "web3_contract_debug_mode", 0)
                
```


#### 测试设置


对于测试和开发，使用 Sepolia 测试网进行 ENS，
                    使用 Oasis Sapphire 测试网进行认证：


```c
loadmodule "auth_web3.so"

# Oasis Sapphire 测试网
modparam("auth_web3", "web3_authentication_rpc_url", "https://testnet.sapphire.oasis.dev")
modparam("auth_web3", "web3_authentication_contract_address", "0xYourTestContract")

# 用于 ENS 的以太坊 Sepolia
modparam("auth_web3", "web3_ens_rpc_url", "https://ethereum-sepolia-rpc.publicnode.com")
modparam("auth_web3", "web3_ens_registry_address", "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e")

# 启用调试日志进行测试
modparam("auth_web3", "web3_contract_debug_mode", 1)
                
```


### ENS 解析过程


该模块实现标准的 ENS 解析，自动检测 Name Wrapper：


1. *查询 ENS Registry* - 调用 owner(bytes32) 获取域名所有者
2. *检查合约身份* - 在所有者合约上调用 name() 以检测 Name Wrapper
3. *获取解析器* - 在 ENS Registry 上调用 resolver(bytes32)
4. *解析地址* - 在解析器合约上调用 addr(bytes32)


这遵循标准的 ENS 解析模式（EIP-137），
                并支持所有以太坊网络上的包装和未包装域名。


### 多网络配置的优势


- *网络分离* - 将 ENS 查询保持在以太坊上，同时使用 Oasis 进行认证
- *成本优化* - 在开发期间使用更便宜的测试网进行 ENS
- *性能* - 在 ENS 和认证调用之间分担网络负载
- *灵活性* - 无需代码更改即可轻松地在网络之间迁移
- *向后兼容* - 现有单网络设置继续工作


### 多网络设置故障排除


*常见问题：*


- *网络连接* - 确保 RPC 端点可从您的服务器访问
- *网络不匹配* - 验证合约地址与配置的网络匹配
- *后备行为* - 如果 ens_rpc_url 为空，ENS 使用 authentication_rpc_url
- *速率限制* - 公共 RPC 提供商可能有使用限制


*调试信息：*


启用调试模式以查看每个调用使用的 RPC：


```c
modparam("auth_web3", "web3_contract_debug_mode", 1)
            
```


查找指示网络使用情况的日志消息：


- ENS call using RPC: [url] (ENS-specific: yes/no)
- Oasis call using main RPC: [url]


## 函数


### web3_www_authenticate(realm, method)


对 WWW-Authenticate 挑战执行基于 Web3 的认证。
                通过区块链合约和 ENS 解析验证 SIP 摘要认证。


此函数从 Authorization 头域提取摘要参数，
                将 ENS 名称解析为钱包地址，
                并在区块链上验证摘要响应。


*参数：*


- *realm* (字符串，必需) - 认证领域（通常为域名）
- *method* (字符串，可选) - SIP 方法（REGISTER、INVITE 等）。如果未提供，使用请求中的实际 SIP 方法


*返回值：*


- *1 (AUTHORIZED)* - 认证成功
- *-1 (ERROR)* - 认证失败或发生错误


*示例：*


```c
# REGISTER 认证
if (is_method("REGISTER")) {
    if (!$hdr(Authorization)) {
        www_challenge("$td", "0");
        exit;
    }
    if (web3_www_authenticate("$td", "REGISTER")) {
        # 认证成功
        save("location");
        exit;
    } else {
        send_reply(401, "Unauthorized");
        exit;
    }
}
            
```


### web3_proxy_authenticate(realm, method)


对 Proxy-Authenticate 挑战执行基于 Web3 的认证。
                类似于 web3_www_authenticate，但用于代理认证场景。


此函数的工作方式与 web3_www_authenticate 完全相同，
                但专为使用 Proxy-Authorization 头域的代理认证流程设计。


*参数：*


- *realm* (字符串，必需) - 认证领域（通常为域名）
- *method* (字符串，可选) - SIP 方法（REGISTER、INVITE 等）。如果未提供，使用请求中的实际 SIP 方法


*返回值：*


- *1 (AUTHORIZED)* - 认证成功
- *-1 (ERROR)* - 认证失败或发生错误


*示例：*


```c
# 使用代理认证的 INVITE 认证
if (is_method("INVITE")) {
    if (!$hdr(Authorization)) {
        www_challenge("$fd", "0");
        exit;
    }
    if (web3_proxy_authenticate("$fd", "INVITE")) {
        # 认证成功
    } else {
        send_reply(407, "Proxy Authentication Required");
        exit;
    }
}
            
```


## 参数


### authentication_rpc_url (字符串)


区块链网络的 RPC URL（例如 Oasis Sapphire 测试网或主网）。
                此参数指定区块链通信的端点。


*默认值：* 无（必须配置）


*示例：*


```c
modparam("auth_web3", "authentication_rpc_url", "https://testnet.sapphire.oasis.dev")
            
```


### authentication_contract_address (字符串)


处理认证验证的智能合约地址。
                此合约必须实现 authenticateUser 函数进行摘要验证。


*默认值：* 无（必须配置）


*示例：*


```c
modparam("auth_web3", "authentication_contract_address", "0xE773BB79689379d32Ad1Db839868b6756B493aea")
            
```


### ens_rpc_url (字符串)


用于 ENS 解析的以太坊网络 RPC URL。
                这应指向用于 ENS 名称解析的以太坊主网 RPC 端点。


*默认值：* 无（必须配置）


*示例：*


```c
modparam("auth_web3", "ens_rpc_url", "https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY")
            
```


### ens_registry_address (字符串)


以太坊主网上 ENS 注册表合约的地址。
                用于将 ENS 名称解析为钱包地址。


*默认值：* 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e (ENS Registry)


*示例：*


```c
modparam("auth_web3", "ens_registry_address", "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e")
            
```


### contract_debug_mode (整数)


启用区块链合约交互的调试日志。
                启用后，将生成用于调试目的的详细日志。


*默认值：* 0（禁用）


*示例：*


```c
modparam("auth_web3", "contract_debug_mode", 1)
            
```


### rpc_timeout (整数)


区块链 RPC 调用的超时时间（秒）。
                此参数控制等待区块链响应的时间。


*默认值：* 10 秒


*示例：*


```c
modparam("auth_web3", "rpc_timeout", 15)
            
```


## C API


该模块为其他 OpenSIPS 模块提供 C 级 API 以使用 Web3 认证。


### bind_web3_auth(api)


将 Web3 认证 API 绑定到模块接口结构。
                这允许其他模块直接使用 Web3 认证函数。


*参数：*


- *api* (web3_auth_api_t*) - 要绑定的 API 结构指针


*返回值：*


- *0* - 成功
- *-1* - 失败


*示例：*


```c
#include "web3_auth_api.h"

web3_auth_api_t web3_api;

if (bind_web3_auth(&web3_api) < 0) {
    LM_ERR("绑定 Web3 认证 API 失败");
    return -1;
}

// 使用 web3_api.web3_digest_authenticate(...)
            
```


## 常见问题


**问：什么是 Web3 认证，它如何工作？**


Web3 认证使用区块链技术来验证 SIP 摘要认证。
                        不在数据库中存储密码，
                        模块通过部署在 Oasis Sapphire 区块链上的智能合约验证认证响应。
                        ENS（以太坊名称服务）名称解析为钱包地址以进行用户标识。


**问：支持哪些区块链网络？**


目前，该模块支持 Oasis Sapphire 测试网和主网。
                        通过修改 RPC URL 配置，可以扩展该模块以支持其他 EVM 兼容网络。


**问：如何设置用于认证的 ENS 名称？**


用户需要注册 ENS 名称（例如 alice.eth），
                        并确保其钱包地址在 Oasis 合约中正确配置。
                        模块将解析 ENS 名称为钱包地址，
                        并验证钱包所有者与认证请求匹配。


**问：需要哪些智能合约函数？**


智能合约必须实现以下签名的 authenticateUser 函数：
                        authenticateUser(string username, string realm, string method, string uri, string nonce, bytes response)
                        如果摘要认证有效，此函数应返回 true。


**问：这个模块与标准 SIP 客户端兼容吗？**


是的，该模块使用标准 SIP 摘要认证（RFC 3261）。
                        SIP 客户端将正常工作——它们只需要使用 ENS 名称
                        作为用户名，而不是传统用户名。


**问：如何调试认证问题？**


通过将 web3_contract_debug_mode 设置为 1 来启用调试模式。
                        这将提供区块链交互、ENS 解析和摘要验证过程的详细日志。


**问：性能影响是什么？**


每次认证都需要区块链 RPC 调用，
                        这可能比传统数据库认证增加延迟。
                        考虑使用适当的 RPC 超时，
                        并可能缓存 ENS 解析结果以获得更好的性能。


**问：我可以同时使用传统认证吗？**


是的，您可以配置不同的领域或路由使用不同的认证方法。
                        该模块仅处理明确调用 web3_www_authenticate
                        或 web3_proxy_authenticate 函数的请求。


**问：如何处理环境变量覆盖？**


该模块支持容器部署的环境变量覆盖：
                        WEB3_AUTH_RPC_URL、WEB3_AUTH_CONTRACT_ADDRESS、ENS_RPC_URL、ENS_REGISTRY_ADDRESS、
                        CONTRACT_DEBUG_MODE 和 RPC_TIMEOUT。这些会覆盖配置文件设置。


**问：如果 ENS 解析失败会发生什么？**


如果 ENS 解析失败，模块将回退到直接使用用户名作为钱包地址进行 Web3 认证。
                        这允许非 ENS 用户仍然可以直接使用其钱包地址进行认证。


**问：如何监控认证成功率？**


启用调试模式并监控 OpenSIPS 日志中的认证尝试。
                        启用调试模式时，模块会记录有关 ENS 解析、合约调用
                        和认证结果的详细信息。
<!-- CONTRIBUTORS -->

### 许可证

所有文档文件（即 .md 扩展名）均采用知识共享署名 4.0 国际许可协议授权。
