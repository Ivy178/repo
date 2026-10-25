> 为什么使用ELK
因为日志分散在各机器，排查只能一台台 grep；ELK 把日志集中采集到 ES，Logstash 做解析清洗，Kibana 做统一搜索和可视化，所以排障和监控效率高很多。

> ELK架构
Beats 采集 → Kafka 缓冲解耦 → Logstash 集中处理 → Elasticsearch/Kibana 存储与洞察

> 收集什么日志
Kubernetes集群中的日志主要来自三个层面：容器日志、Pod事件和节点系统日志

> 日志流转过程
Pod输出日志：容器将日志写入stdout，containerd将其捕获并写入节点的/var/log/pods/目录。
Filebeat采集：DaemonSet形式的Filebeat监控上述目录，发现新行后读取，添加K8s元数据（命名空间、Pod名、容器名等）。
传输与缓冲：Filebeat通过HTTP将日志批量发送至Elasticsearch集群（或先发往Kafka）。
ES索引：Elasticsearch对日志进行分词、建立倒排索引，按日期生成索引（如logstash-2026.09.08）。
Kibana检索：用户在Kibana中输入关键词，ES快速返回匹配日志，并以时间线、柱状图等形式呈现

> 你们日志每天增长多少？日志量有多大？每天请求最高 QPS 是多少
面试官，我们日志每天增长大概 20 到 50 GB，保留 7 到 30 天，热数据放 ES/Loki，冷数据归档到 S3。每天请求最高 QPS 大概 1000 到 2000，大促能到 3000。



# kibana
> 创建索引模式
访问 Kibana → Stack Management → Index Patterns
创建索引模式：k8s-*
选择时间字段：@timestamp
保存

> kibana查询
Kibana 查询我分两步：先用 KQL 过滤缩小范围，比如筛出错误请求；status:500 AND response_time:>1000
再基于结果做聚合，按服务分桶算错误率，直接定位问题服务。核心就是先过滤、后聚合。

> 怎么配置ILM
先在建一个 Lifecycle Policy，就是是把 hot、warm、cold、delete 几个阶段的条件定清楚，比如 hot 阶段按大小或时间 rollover，delete 阶段设保留天数。
然后把策略挂到索引模板上，新建的索引就会自动继承。之后 ILM 自己轮询执行，不用手动搬数据。
一句话：策略定义什么时候动，模板保证谁生效，剩下交给 ILM 自动流转。


# ES
> ES 优化
- 节点主从分离
- 索引生命周期管理，冷热分离
- 快照备份，定期备份到s3


> ES高可用配置
- ES 多副本，保证数据有多份
- Pod 反亲和性，pod分散到不同节点，避免单节点故障，数据同时丢失
- 节点亲和性,调度到高性能节点


# 排障
问题现象	    可能原因	             排查与解决
Kibana无数据	Filebeat未正常采集	     检查Filebeat Pod状态: kubectl logs -n logging filebeat-xxx
ES写入拒绝	    分片数超限或队列满	      增加thread_pool.write.queue_size, 检查index的number_of_shards
查询超时	    索引分片过多	         合并小索引, 减少max_num_segments
磁盘空间满	    ILM未生效	             检查ILM策略是否应用, 手动删除过期索引
日志有延迟	    Filebeat背压	         增加bulk_max_size和worker数量, 检查网络带宽


# 部署 & 配置
> 如何部署ELK
用helm repo add 添加Elastic Helm仓
用helm  install 分别部署filebeat、logstash、ES、Kibana
验证pod、svc状态


> 如何配置Logstash 
在input配置 端口 等Beats 发数据过来，
收到后output直接写到 Elasticsearch，
索引名按“beat 类型 + 日期”生成，比如 filebeat-2026.10.23，方便按天管理和查询。
把这个ConfigMap 挂载到pod


> ConfigMa如何挂载pod
ConfigMap 本身不会自动生效，得让 Pod 挂载它。
就是在 Deployment 或 StatefulSet 里定义一个 volume 指向这个 ConfigMap，
再在容器里用 volumeMounts 把它挂到 Logstash 的配置目录



> 如何配置filebeat
就是配置 Filebeat 以 DaemonSet 跑在每个节点上，采集 `/var/log/containers` 下所有容器日志；
用 `add_kubernetes_metadata` 给日志打上 Pod、Namespace 标签；
然后批量输出到 Elasticsearch，配了两个 worker 和 2048 的批量大小来提升吞吐。