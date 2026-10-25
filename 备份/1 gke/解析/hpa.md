# VPA
CPU 升高 -> Pod 数量增加
CPU 降低 -> Pod 数量减少

# 三者的关系
业务负载增加 -> HPA 增加 Pod -> 节点资源不足 -> Cluster Autoscaler 增加节点


# HPA定义
HPA是 k8s 水平 Pod 自动扩缩容组件，根据自定义指标自动调整工作负载的 Pod 副本数。

# 怎么配置
- 集群必须提前部署 metrics-server,否则无法获取资源指标,HPA 不生效
- 定义scaleTargetRef、scaleTargetRef、最大最小副本数, metrics: CPU / 内存资源使用率
apply之后,根据自定义指标自动调整工作负载的 Pod 副本数。


# metrics-server
HPA 控制器周期性从 metrics-server 获取 Pod 指标，对比目标阈值计算期望副本数，调用工作负载的 scale 接口调整副本数。

# 怎么部署metrics-server
直接 apply 官方 components.yaml,一键创建所有关联资源


# 怎么知道pod 需要多少资源
通过Prometheus 采集一周以上的运行数据，取高峰时段的 P95/P99 指标值，加上冗余后作为最终配



# HPA 配置示例
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: demo-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80




> PodDisruptionBudget配置
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: my-app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: my-app

· selector 选中所有带 app: my-app 标签的 Pod。
· minAvailable: 2 表示任何时候至少保留 2 个 Pod 可用。节点维护、drain 时，如果只剩 2 个，K8s 就不会再驱逐，保证服务不挂。
· 如果副本数是 3，那最多只能驱逐 1 个。
