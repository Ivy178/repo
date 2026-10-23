# VPC-native 是什么？
在 VPC-native 集群中：
节点使用 VPC 子网中的主 IP 地址
Pod 从子网的 secondary range 获取 IP
Service ClusterIP 通常从单独的 Service secondary range 获取
Pod 和节点可以直接参与 VPC 路由通信

VPC
├── 主子网范围       -> 节点 IP
├── Pod secondary range
└── Service secondary range



# Alias IP 的作用
Alias IP 是 Google Cloud VPC 为网卡分配的附加 IP 范围。GKE 利用它为 Pod 分配地址，因此 Pod IP 可以直接在 VPC 网络中被识别和路由。
相比传统路由模式,VPC-native 的优点是：

网络路径更简单
Pod 可以直接访问 VPC 资源
更容易连接 Cloud SQL、GCS、on-prem 等服务
减少额外路由配置
更容易结合 VPC 防火墙和 Cloud NAT


> Ingress介绍
如果是生产环境的 HTTP/HTTPS 服务，通常推荐用 Ingress 统一管理入口,链路如下
用户 → Google Cloud Load Balancer → Ingress 规则 → ClusterIP Service → Pod
所以不是再手动额外叠一个 LoadBalancer；Ingress 本身就会使用负载均衡器
生产 HTTP/HTTPS 流量通常通过一个 Ingress 入口按域名或路径路由到多个内部 Service；
其他服务保持 ClusterIP

> ingress规则落实规程
Ingress：你声明“请求应该怎么路由”的规则。
Ingress Controller：读取规则并执行配置的组件。
Load Balancer / 反向代理：真正接收并转发请求的设施。

> 在gke 为什么Load Balancer 在 ingress前面
在 GKE 中,Ingress 主要定义路由,Ingress Controller 将其转换为 Google Cloud Load Balancer 配置,Load Balancer 作为公网入口,再把请求转发到 Service 和 Pod。



> 如何配置DNS api.example.com
api.example.com 是企业自己的业务域名,需要在 DNS 服务商或 Cloud DNS 中配置 A 记录,将它解析到Ingress 创建的 Google Cloud Load Balancer 公网 IP;
同时在 Ingress 的 spec.rules.host 中配置相同域名,Load Balancer 才能根据 Host 转发到对应 Service。

spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /users
        backend:
          service:
            name: user-service
            port:
              number: 80


> networkpolicy配置
两种方向
Ingress: 控制进入 Pod 的流量
Egress: 控制 Pod 发出的流量

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 8080

含义是：只有带有 app: frontend 标签的 Pod,才能访问后端 Pod 的 8080 端口。



# Ingress 跟 LoadBalancer 区别
LoadBalancer 是 Service 的一种类型,主要用于直接对外暴露单个服务,通常工作在四层;Ingress 是七层 HTTP/HTTPS 入口,可以根据域名和路径将请求转发到多个 Service,并支持集中处理 TLS。在 GKE 中,Ingress 通常使用 Google Cloud HTTP(S) Load Balancer,而 LoadBalancer Service 通常为单个服务创建云负载均衡器



> ingress配置
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cafe-ingress
spec:
  ingressClassName: nginx          # 指定 Ingress Controller
  tls:                             # TLS 终止配置
  - hosts:
    - cafe.example.com
    secretName: cafe-secret        # 引用存证书的 Secret
  rules:
  - host: cafe.example.com
    http:
      paths:
      - path: /tea
        pathType: Prefix
        backend:
          service:
            name: tea-svc          # 后端 Service 名字
            port:
              number: 80
      - path: /coffee
        pathType: Prefix
        backend:
          service:
            name: coffee-svc
            port:
              number: 80

· ingressClassName：指定用哪个 Ingress Controller。Nginx 写 nginx；GKE 默认 Controller 可以不加这个字段。
· tls：配置 HTTPS。hosts 写域名，secretName 引用一个 kubernetes.io/tls 类型的 Secret，里面存 tls.crt 和 tls.key。


> 创建 Secret 的命令（自管理证书时用）：
kubectl create secret tls cafe-secret --key tls.key --cert tls.crt