# jenkins
> 怎么做安全凭证
把凭证存到到jenkins，定义凭证ID、类型
在pipeline中通过withCredentials引入凭证ID，然后通过variable注入脚本或命令中
 
> jkin遇到问题怎么处理
在console output中定位error位置、查看错误的步骤，比如依赖冲突、命令错误、权限不够
 
> shalib怎么做
填入sharelib文件名，输入参数，引用在sharelib函数，参数通过pipelineparams传入函数
 
> 参数化pipeline
主要通过参数化构建、填上项目名、类型pipeline、定义参数、用scm形式拉远程代码、填上仓库地址、分支、pipeline路径
 
> 怎么测试pipeline
copilot做静态分析、在dev环境中测试、dryrun
 
> 怎么调度
主要用到参数化调度、在parameterizedCron中添加参数，可以根据不同环境、市场等参数去调度pipeline
 
> 怎么维护jenkins
credencial、console_output、构建次数
 
> 如何build pipeline
configuration、the project is parameterized(配置参数)
选 "pipeline script from scm"、在SCM配置下repo URL、CREdentials、branches
在script path选路径
 


# cicd
> CI/CD 工具链和流程
代码提交 → jenkins触发 CI → 编译、单测、构建镜像 → 推nexus仓库 → CD通过helm部署到 K8s。 //工具链一般 Github + Jenkins + Nexus + helm + K8s。

> 声明式和脚本式区别
声明式是结构化语法，固定用 pipeline、agent、stages、steps，规范易读，适合标准 CI/CD，新手友好。
脚本式是基于 Groovy 的自由代码，能写循环、条件、函数，灵活但复杂，容易乱。

> Jenkins Pipeline 怎么写
Jenkins Pipeline 一般用声明式，写一个 Jenkinsfile。
最外层是 pipeline，指定 agent；
里面用 stages 把阶段串起来，比如 Build、Test、Deploy。
每个 stage 里写 steps，具体命令用 sh 执行，比如 sh 'mvn clean package'。
需要条件判断用 when，后置操作用 post，复杂逻辑用 script 块嵌 Groovy。


> 新服务上线流程和沟通
研发提上线单 → 确认依赖和资源 → 建 CI/CD 流水线 → 测试环境验证 → 灰度 → 全量。和研发沟通重点：镜像版本、环境变量、资源配额、健康检查、回滚方案。

> 无损发布怎么做
核心靠探针 + 滚动更新 + PDB。readiness 探针确保 Pod 就绪才接流量，滚动更新 maxUnavailable 设 0，PDB 保最小可用副本，再配合 preStop 优雅停机。

> 灰度发布怎么实现
按比例或按 Header 分流，用 Ingress、Service Mesh 或 Argo Rollouts。比如先 5% 流量，观察错误率和延迟，正常再逐步放大，异常自动回滚。

> 镜像扫描和回滚
helm history <release-name> -n <namespace>   //查看指定release的历史版本
helm rollback <release-name> 2 -n <namespace> --wait --timeout 5m    //回滚到指定版本（如版本号2）


> cicd 过程
打包并上传 ZIP 制品到 Nexus
安全扫描
获取nexus制品
把制品部署到nonprod
生成工单，指定auto release时间
部署到prod



# docker
> dockerfile 会用到哪些命令
FROM
WORKDIR
ARG
COPY
RUN


> 应用是做什么的
从 BigQuery 读取待评分数据，加载 GCS 中的 H2O MOJO 模型，对每条记录进行二分类预测，计算评分，并将结果写回 BigQuery。
二分类预测: 不违约概率是多少，违约概率是多少





# groovy
> 删除过期镜像
从bucket获得列表   
筛选指定环境镜像
如果是非过期镜像就跳过
如果是过期就先验证镜像是否存在，如果存在就重新build镜像，删除旧image
发邮件通知


> 删除无用镜像
遍历mig
形成template列表，一个个遍历，取出template在用image
形成image列表
形成helper image列表
遍历image
image在指定删除前缀列表中？  删除   返回
image是template使用的镜像？ 保存    返回
image是helper前缀镜像？     保存    返回
image是大于7天的无用镜像？  删除     返回


> C4DsbulkLoad & C4DsbulkUnload
配置cluster，写入kubefig,方便后续操作
创建临时pod
在pod执行命令：
把凭证复制到pod内
登录gcp
把bucket文件复制到指定路径
这行是在 Pod 内执行 dsbulk load，把 CSV 数据导入 Cassandra 表。 //C4DsbulkLoad
这行是在 Pod 内执行 dsbulk unload，把Cassandra 表 导出到 bucket。

> g3CredRotation
使用 Jenkins 凭证登录 G3 系统，获取Cookie，保存到 g3Cookie
遍历所有 G3 应用，
查询旧凭证，获取过期时间，然后删除旧 Secret
遍历所有 G3 应用，
把 GCP Service Account 凭证编码后上传到 G3，轮换凭证，并设置 90 天后过期

> KEY_ROTATION
根据新凭证路径，生成新凭证
创建新和旧的文件对象，放入变量，包含creid、json、凭证文件名
获取 Folder 凭证存储，把轮换旧凭证
删除旧凭证



> feedzaiCleanupGmiVM
通过sa登录gcp
得到vm列表
遍历vm列表，得到运行时间大于6小时的vm
执行遍历，删除vm


> feedzaiImageFactory
通过sa登录gcp，会触发三个jenkins job
通过分支制作image,把image转移到指定环境
执行lockdown,不让外面访问
根据传入的镜像，部署到vm


> feedzaiImageRefresh
通过sa登录gcp，进入指定环境
检查COMPONENT是否在指定列表中
如果在触发image build



> gcsAutoclass
通过sa登录gcp
列出buket
通过if判断,如果bucket没有规则，没有auto,则启动autoclass


> keyDelete.groovy
通过sa登录gcp
通过命令列出过期镜像
如果列表为空不执行删除
如果不为空，遍历列表，执行删除


> shutdownVMbyname
通过sa登录gcp
删除指定project、zone中的vm

> auto shut down
k8s
通过sa登录gcp
列出指定环境所有cluster,进行each遍历
列出该cluster所有nodePools
给出if判断，如果nodepools为零则启动autoscaling进行scaleup

sql
通过sa登录gcp
列出指定环境sql instances，进行for遍历
给出if,判断instance,是否为stop
如果是 不动作，如果否 关闭instance

log
通过sa登录gcp
列出指定环境log sink，进行for遍历
给出if判断，如果是需要的sink则跳过
if 判断log sink 状态,如果没disable,则disable log





> packer image
baking：
通过sa登录gcp
clone repo 到本地
cd到app目录，在packer build命令传入var文件，进行baking

promote：
通过sa登录gcp
if判断源环境是否不存在image 或 目标环境是否已存在image,如果存在就退出
if判断源image是否留空，如果留空，把family中最新image复制到目标环境，如果不留空则在目标环境buid该image,

deploy：
通过sa登录gcp
clone repo 到本地
cd到app目录，把inputfile、backen参数传入terraform命令，进行ini、plan、apply
链路：生成镜像 > 复制到部署环境 > 在terraform中部署


> docker Image
dockerImageBuild：
把docker-config.json 传入kaniko folder 进行 Artifact Registry 认证
构建docker镜像，并推送到GCR和Nexus3
对镜像扫描

dockerImagePromoFromNexus：
校验SRC_IMAGE_URI、DST_IMAGE_URI格式
通过sa登录gcp
通过gcrane登录nexus
Push image to Artifact Registry // 输入校验后的地址
触发jenkins job 进行扫描

dockerImageScan：
调用共享库生成一个token, 后续调用 API 时使用这个 Token。
通过token生成configid
根据token、configid进行扫描

deploy:
通过sa登录gcp
从Artifact拿到要部署的镜像
传入release名称、chart路径、namespace、values 文件等参数进helm 
读取 override-prod.yaml
从 Google Artifact Registry 拉取镜像
进行helm部署




# python
> 用python做过什么
我用过python去动态生成 kubeconfig，连 EKS，创建 Job
流程是：先用 boto3 调 describe_cluster，拿到集群 endpoint 和 CA 证书；再在内存里拼一个 kubeconfig，
认证用 aws eks get-token 换 token；
然后用 Kubernetes 客户端加载这个配置，拿到 BatchV1Api，构造一个 Job，在镜像里，执行 echo Hello Kubernetes。


> Python面向编程的概念 （Citi）
Python 面向对象编程，核心就是把数据和操作数据的方法封装成“类”，再通过类创建“对象”。它四大特性：封装、继承、多态、抽象。

> Shell/Python 会写吗？循环打印 1 到 100
会。Python 就 for i in range(1, 101): print(i)；Shell 就 for i in $(seq 1 100); do echo $i; done。

> awk 统计某个接口平均响应时间
假设日志格式是 时间 接口 状态码 响应时间，比如 /api/user 200 0.123，就用：
awk '$2=="/api/user" {sum+=$4; count++} END {if(count>0) print sum/count}' access.log
字段位置按实际日志调，核心就是按接口过滤，累加响应时间，最后除以次数。


# shell
> 用shell做过什么
我用shell写了一个脚本，功能是把源 GCP 项目里某个 image family 的最新 GCE 镜像，复制到目标项目。
传入源项目、镜像 family、目标项目和 KMS key。然后去源项目查这个 family 的最新镜像，按创建时间排序取第一条。
接着if判断 检查目标项目里有没有同名镜像，有就跳过；
没有就用 gcloud compute images create 把iamge复制到目标环境过去，核心就是：取最新、判重、复制。


我用shell脚本写了一个无人值守的补丁更新调度器
它先发企业微信通知，然后if判断 金丝雀批次是否成功，只更新 1 台，失败就直接终止并告警。
成功就等 10 分钟观察。之后用for in遍历让每个批次滚动更新，每批之间等 5 分钟。
每批都用 Ansible 执行补丁 playbook，结果写进日志，并通过企业微信通知成功或失败。
任何一批失败都会立刻停止后续更新。全部跑完再发完成通知。
// 核心就是：金丝雀验证 + 分批滚动 + 失败熔断 + 全程通知。







# image 
7、怎么制作packer image
定义一个临时用vm,用某个基础镜像为模板，会在里面build镜像
在main定义步骤，包括复制必要文件、install、configure
--------------------------------- -------------------
用 dnf install 安装环境，比如gcc、java python编译器之类
用 dnf install 安装python相关的软件
用 pip install 安装python基本库
用 pip install 安装Apache Airflow 及其运行依赖和集成组件
在configure 把相关配置或脚本写入到启动文件
systemctl启动相关服务
大致步骤: 定义install、configure、启动过程

> 写入什么配置
获取airflow凭证
把路径挂到相应存储桶，获取dag

> dockerfile怎么写
用FROM编译镜像
登录nexus,安装mvn
生成配置，RUN mvn 编译,打包代码

再用FROM指定其他镜像，比如启动器、运行环境
把镜像文件copy到docker目录
再登录nexus，安装JDK环境
通过ENTRYPOINT启动
docker build 构建镜像   //估计有docker build jenkins

> join-cluster.py
通过sort排序，选举出seed节点
通过append追加candidates候选节点
判断是否seed节点，如果是等待其他节点启动完成
通过for in 遍历主机检查主节点、从节点是否就绪
把节点加入集群，如果失败就reset节点，重新retry
启动rabbitmq确保运行
进行状态检查，失败就退出