# 基础概念
> tf是什么？
IaC 工具，用声明式配置管理云资源。
 
> Terraform 的工作流程是什么？
init + plan + apply + destroy
// init：初始化 backend、下载 provider、下载 module（源码）、检查依赖和插件版本（是否兼容）
// 当前代码配置、当前 state 文件、实际云资源状态
 
> 什么是 provider?
Terraform 通过 provider 和外部平台交互，比如 AWS、Azure、GCP。
 
> 什么是 resource?
被 Terraform 管理的具体对象，如 VM、VPC、Bucket。
 
> 什么是 data source?
读取已存在资源信息，不负责创建。

 
> Terraform 是声明式还是命令式？
声明式
//tf会自动算出需要创建、更新、删除的操作，不需要逐步写出“怎么执行”


核心文件与语法
> main.tf、variables.tf、outputs.tf 有什么作用？
main.tf: 资源定义
variables.tf: 输入变量
outputs.tf: 输出值
// 通过output查看结果，给其他模块用，子模块把值输出出来,父模块拿来继续使用


> 变量有哪几种赋值方式？
默认值
terraform.tfvars
*.auto.tfvars
CLI -var
环境变量 TF_VAR_xxx

//terraform plan -var="region=ap-southeast-1" -var="instance_count=3"
 
> locals 和 variable 的区别？
variable 用于接收外部输入，实现配置的灵活性
locals 用于模块内部，它根据逻辑处理去拼接变量，简化代码
 
> output 有什么用？
导出资源属性给人看或给其他模块引用
 


# 状态管理
> Terraform state 是什么？
记录当前基础设施实际映射关系的状态文件。
 
> 为什么 terraform.tfstate 很重要？
没有它，Terraform 不知道哪些资源已存在、需变更什么。
 
> 本地 state 和远程 state 区别？
本地：单机，不适合团队
远程: 共享、可加锁、适合协作

> 为什么要启用 state locking？
防止多人同时 apply，避免状态冲突。
 
> state 文件里可能有什么风险？
可能包含敏感信息，如密码、连接串。要做好访问控制。
 


# Plan / Apply / Drift
> terraform plan 的作用？
预览变更，不真正执行。
 
> 什么是 drift？
实际云资源和 Terraform state / 代码不一致。
 
> 如何处理 drift？/ 遇到的问题
plan 检查
refresh
更新代码或重新导入资源

// terraform refresh
// terraform refresh同步 已管理资源状态	资源已在 state 中
// terraform import	把现有资源纳入 state 资源不在 state 中



# 安全与最佳实践
> 如何安全认证
将凭证相关变量定义在 .tfvars，在 Provider 块引用该变量，完成云身份凭证注入。

> 用 secrets manager、CI/CD secret、环境变量，避免硬编码。
 
> 为什么不建议把凭据写进 .tf 文件？
易泄露、难轮换、审计差。
 
> Terraform 最佳实践有哪些？
使用 module
使用 remote tate
开启 locking
代码分层
命名规范统一
CI 跑 fmt / validate / plan




# 环境隔离
> 如何做环境隔离
在inputfiles这个folder中定义不同env的tfvars文件，以隔离不同的环境

> Terraform workspace 是什么？
用同一套代码维护多套状态，如 dev/test/prod。
 
> workspace 是否适合复杂多环境？
小型场景可以，复杂企业环境通常更常用目录分层或独立 state。
//workspace 适合小规模多环境，因为它简单、低成本、同一套代码可切换多个 state。
但大规模场景通常环境差异大、权限和审计要求高、状态管理复杂，workspace 容易出现混用和治理困难，因此更推荐目录分层、独立 backend 和独立 state。

# provider是做什么的
Terraform = 项目经理（编排、规划、依赖管理）
Provider = 分包施工队（真正干活，调用云厂商 API 创建机器、网络）
HCL 代码 = 施工图纸



 

# 模块
> 什么是 module？
一组可复用 Terraform 配置。
 
> 为什么使用 module？
复用、标准化、降低重复代码。
 
> root module 和 child module 区别？
root 是执行入口
child 是被调用模块
 
> module 输入输出怎么传递？
输入通过 variables
输出通过 outputs
 

# 依赖与生命周期
> Terraform 如何判断资源依赖？
通过引用自动推断
必要时用 depends_on
 
> 什么时候用 depends_on？
隐式依赖不足时再用，别滥用。
 
> lifecycle 常见参数有哪些？
create_before_destroy
prevent_destroy
ignore_changes
 
> ignore_changes 的作用？
忽略某些字段变更，避免不必要更新。



# 循环与条件
> count 和 for_each 区别？
count 适合简单数量
for_each 适合按 key 管理对象，更稳定
 
> 什么时候用 for_each 优于 count？
资源有明确唯一标识时。
 
> Terraform 支持条件创建吗？
支持，可用 count 或 for_each 实现。
//通常用 count 或 for_each 配合布尔变量/条件表达式来控制资源是否创建，比如 var.enable_x ? 1 : 0 或 var.enable_x ? { key = value } : {}。
 


# 导入与迁移
> 如何把已存在资源纳入 Terraform 管理？
用 terraform import
 
> import 后是否自动生成代码？
通常不会，仍需手写/补齐配置。
//import只是导入资源，配置需要补齐代码plan/apply
 
> 迁移 state 常用什么命令？
terraform state mv
terraform state rm
 
> 为什么要terraform state mv， 重新apply 可以？ 
如果只是配置有差异，直接 apply 就可以；但如果资源地址、模块路径、资源名发生变化，Terraform 会认为这是“旧资源删了、新资源加了”。
terraform state mv 的作用是把旧 state 记录迁移到新资源地址，避免误删重建，然后再执行 apply。


> 处理 drift 先看是“state 多了”还是“state 少了”。
如果真实资源少于 state，就用 terraform state rm 清理多余状态；
如果真实资源多于 state，就用 terraform import 补回缺失的资源；
最后再 plan 和 apply，确认最终与代码和真实环境一致。










# 常见进阶题
> terraform init 做了什么？
初始化 backend、下载 provider、下载 module。
 
> terraform validate 和 plan 区别？
validate 检查语法与配置合法性
plan 检查实际变更
 

> 如何避免误删生产资源？
prevent_destroy
审批流程
分离权限
先 plan 再 apply
 
> 如何在团队中落地 Terraform？
Git 管理代码     //版本可控
PR 审核
CI 自动 plan     //发现语法错误，fmt/validate
远程 state
环境隔离    //共享 state 导致冲突、生产误删
 


面试官还常问：
如何设计一套多环境 Terraform 目录结构？
不同目录管理不同环境，比如说inputfile,有不同环境dev、prod
如何管理 dev / uat / prod 的变量差异？
如何处理多人同时改同一个 state？
如何回滚一次错误的 apply？
找到上一个可用版本的代码,重新plan/apply
如何导入已有云资源？
如何做模块版本管理？
Terraform 和 Ansible 的区别是什么？
Terraform 和 CloudFormation / Deployment Manager / ARM / Bicep 有什么区别？
 

一个高频对比题
面试准备建议，建议至少准备这 5 类答案：
state 原理
module 设计
count vs for_each
remote backend + locking
实际项目里如何做多环境管理




# 准备建议
第一，state file是三家共同的底线。 HSBC问到了“state删了怎么办”和“团队协作怎么管”，Citi问到了“敏感数据存哪里”。准备时不要只背“state文件记录资源映射”，要能说清remote backend（S3/GCS + DynamoDB锁）、state锁定、state版本化、state恢复这一整套生产实践。
第二，module是Citi明确问到的方向。 要能讲清楚module的输入输出、复用逻辑，以及在CI/CD流水线中怎么调module。
第三，Terraform和Ansible的边界要能一句话说清。 Citi问了这个对比，答案的核心是：Terraform管provisioning（创建基础设施），Ansible管configuration（配置已有机器） 。
第四，如果简历写了Terraform，SCB和Citi都会围绕“你在项目里怎么用的”追问细节。 准备一个2分钟能讲完的真实场景：用什么backend、state怎么管、module怎么拆、和CI/CD怎么集成、遇到过什么坑。


# HSBC
> state file作用
state file 是 记录你写的代码和云上真实资源之间的映射关系的文件，
没有它，Terraform 不知道哪些资源已存在、需变更什么。
这个账本里可能明文存着数据库密码、私钥这类敏感信息，必须用加密的远程后端（如 S3 + KMS）并开启状态锁，防止团队协作时把账本写坏或泄露。


> 怎么用state追踪资源?
用 state 追踪资源，不是靠肉眼看 JSON，而是用 terraform state 系列命令来安全操作。
最常用的是 terraform state list，列出 state 里记录的所有资源地址，一眼看清 Terraform 当前在管什么。想看某个资源的详细属性，用 terraform state show <资源地址>。
重构时用 terraform state mv 改资源地址，避免误删重建；用 terraform state rm 把资源移出 state（云上资源不删），terraform import 则把已存在的存量资源纳管进来。
一句话：list 看全貌，show 看细节，mv 改地址，rm 移出，import 纳管。

> state丢了怎么办？
查远程后端版本：如果用了 S3 或 GCS 并开了版本控制，直接回滚到上一个正常版本，几分钟就能搞定，这是最优解。


> object versioning是什么，有什么用？
Object versioning 就是云存储的文件历史快照：每次写入或删除都保留旧版本，不会覆盖。
用处是防误删、防写坏，出问题能一键回滚；对 Terraform 来说，就是给 state 文件上保险。



> 团队协作中state怎么管
- 用 S3 + DynamoDB 把 state 锁在远程后端里，保证同一时刻只有一个人能改 state，避免并发写坏。
- 通过 PR评审 和 CI/CD 间接操作,比如apply，绝不手动碰它。

// 变更走 PR，看 plan diff 不看 state 文件,
// 生产环境的 apply 只从 CI/CD 跑，就是让 state 只从一个受控入口写，不让人手碰。   --避免用过期state
。



# SCB
> Terraform provisioning 有什么用
Terraform provisioning 是用代码定义基础设施。你写一份声明式的配置文件，描述想要什么资源，Terraform 自动算出并执行创建或变更

> Terraform provisioning 怎么做
日常用 Terraform 做 provisioning，就是写 .tf 声明资源，比如创建ec2,先声明Provider，再声明ec2实例
然后走 init → plan → apply 三步：init 拉 provider，plan 预览要建什么，apply 真正把资源建出来。


# Citi
> Terraform 和 Ansible 的区别是什么？
Terraform 从无到有建资源，Ansible 在已有机器上配环境。 实际常配合用：Terraform 建好机器，Ansible 再上去配置。

> 怎么存敏感数据
把tf敏感数据存在像GCP Secret Manager 这样的 密钥管理服务中

> module有什么用
Terraform module 就是把一组资源打包成可复用的组件，像函数一样，传参就能用。
作用是复用、标准化、少写重复代码，避免每套环境重新配一遍。














//HSBC
> 部署过什么资源
mig、scret、bucket、sql、bigquery


1、terraform包括哪些文件
config、remote_state、provide、tfvars、variable、main、output、module

2、怎么引用moduel
在main文件，通过source引入moduel路径

3、怎么set sql
instance、遍历配置、user、db
---------------------------------
instance：定义数据库基本信息 name、project、zone
遍历配置：打开pgaudit、用于记录客户端连接数据库的日志
user: 判断是否为sa,如果是把type改为CLOUD_IAM_SERVICE_ACCOUNT, 绑定sa到intance
db： 关联instabce


4、怎么set bigquerry
创建数据集、打label、授权     //通过for_each,逐个创建datasetid, gant 权限给指定member去读写
--------------
创建数据集：定义project、location等基本信息
打label: 在 GCP 控制台中筛选和查找资源
授权：给member赋值数据集的view权限



5、怎么set bucket
指定location、lifecycle_rule， 给member授予bucket的view 权限



5、怎么set secret
创建secret：定义project、expire_time等基本信息，用for_each逐个创建secret
授权：对每个secretid，逐个授权给对应member






6、怎么set mig
instance_template、health_check、instance_group_manager、autoscaler、backend_service、forwarding_rule、dns
----------------------------------------------------
instance_template：         定义 machine_type、subnetwork、firewall_tags、lifecycle（先创建新instance,再destroy旧ins,无缝更新）
instance_group_manager：    定义instance_template、base_instance_name、update_policy 保证更新过程中不会出现不可用实例；最多额外创建 3 个新实例做平滑切换
autoscaler、                定义instance_group_manager、最大最小副本、target
health_check：              定义成功次数阈值、timeout、等待时间，  如果超过一定时间未health check成功，则重启vm
backend_service、           定义instance_group_manager，把前面的 MIG（Instance Group Manager）挂到一个后端服务里，让负载均衡器/转发规则可以把流量发到这些实例
forwarding_rule             backend_service、subnetwork，  定义流量从指定子网（内网）进入后端服务
dns                         用for_each遍历appname、IP，形成一份A记录列表，然后遍历列表生成DNS
(! Client > Forwarding Rule > Backend Service > Instance Group / MIG > VM Instances)








# cloud
gcloud操作过什么资源1
mig、gcs、gke、vm
 
操作过什么资源2
IAM、vpc、subnet、sa、firewall
 
安全管理
Secret Manager & kms
vpc\route\subnet
 

sql
关键：允许在 public schema 里建对象
GRANT USAGE, CREATE ON SCHEMA public TO "dds‑airflow‑gce‑uat‑sa@hsbc‑11505776‑ddsasquat‑dev.iam";
如果已有对象，给读写（避免后续迁移/读取授权）
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "dds‑airflow‑gce‑uat‑sa@hsbc‑11505776‑ddsasquat‑dev.iam";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "dds‑airflow‑gce‑uat‑sa@hsbc‑11505776‑ddsasquat‑dev.iam";
 
vm与sql instance不在同一个vpc，导致vm连不上sql
防火墙标签打错，导致health流量进不去vm
secret过期，导致连不上url