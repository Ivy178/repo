# 通过 kubeconfig 连接 EKS 的 Kubernetes API
以下代码来自 Stack Overflow，展示如何在 Lambda 中连接 EKS 并创建 Job：

import boto3
from kubernetes import client, config

cluster_name = "app1-eks-cluster"

# 获取集群信息
eks_client = boto3.client('eks')
cluster_info = eks_client.describe_cluster(name=cluster_name)
cluster_endpoint = cluster_info['cluster']['endpoint']
cluster_certificate = cluster_info['cluster']['certificateAuthority']['data']

# 构建 kubeconfig
kube_config = {
    'api_version': 'v1',
    'clusters': [{
        'cluster': {
            'server': cluster_endpoint,
            'certificate-authority-data': cluster_certificate
        },
        'name': cluster_name
    }],
    'contexts': [{
        'context': {'cluster': cluster_name, 'user': cluster_name},
        'name': cluster_name
    }],
    'current-context': cluster_name,
    'kind': 'Config',
    'users': [{
        'name': cluster_name,
        'user': {
            'exec': {
                'apiVersion': 'client.authentication.k8s.io/v1beta1',
                'command': 'aws',
                'args': ['eks', 'get-token', '--cluster-name', cluster_name]
            }
        }
    }]
}

config.load_kube_config_from_dict(kube_config)

# 创建 Kubernetes Job
batch_v1 = client.BatchV1Api()
job = client.V1Job(
    metadata=client.V1ObjectMeta(name="example-job"),
    spec=client.V1JobSpec(
        template=client.V1PodTemplateSpec(
            spec=client.V1PodSpec(
                containers=[client.V1Container(
                    name="example-container",
                    image="busybox",
                    command=["/bin/sh", "-c", "echo Hello Kubernetes"]
                )],
                restart_policy="Never"
            )
        ),
        backoff_limit=4
    )
)
api_response = batch_v1.create_namespaced_job(body=job, namespace="default")
print(f"Job created. Status: {api_response.status}")


注意：
该示例要求运行环境中存在 aws 命令行工具（因为 kubeconfig 中 exec.command 为 aws）。
在 Lambda 中直接运行会报 No such file or directory: 'aws' 错误。
在 Lambda 或容器中，应改用 EKS Token 生成类来替代 aws eks get-token。


aws eks get-token 用来为指定的 EKS 集群生成一个短期认证 Token，让Kubernetes 客户端能向集群证明 AWS 身份。
代码用了 import boto3。在 AWS Lambda 的 Python 运行环境中，通常已预装 boto3，所以一般不用单独安装；