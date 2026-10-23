# helm repo update 
不是“更新远程仓库”，而是更新本地缓存的仓库索引。
它做的是：去你添加过的每个 Helm 仓库，下载最新的 index.yaml，存到本地。这样你 helm search repo 或 helm install 时，才能看到新版本。



# Pod输出日志跟Filebeat采集什么关系
Pod 负责“写”，containerd 负责“落盘”，Filebeat 负责“搬走”，三者串成一条日志管道



# read_from_head true：
从头开始补历史数据，因为日志写入很多天，如果fluend没部署，要从头开始补




# <filter kubernetes.**> 
里的 @type kubernetes_metadata，具体干的事是：给每条容器日志自动补上 K8s 元数据，比如命名空间、Pod 名、容器名、Pod UID、节点名、标签。
补了之后，在 Kibana 里才能按 kubernetes.namespace_name、kubernetes.pod_name 这些字段过滤和聚合。不补的话，日志只有原始内容和文件路径，你不知道它来自哪个 Pod。
一句话：filter 是日志的“加工站”，这个 filter 专门给日志贴上 K8s 身份标签。