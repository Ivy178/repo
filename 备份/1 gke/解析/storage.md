
# GCE Persistent Disk     //GCE Persistent Disk 是 GKE 中常用的块存储，适合：
数据库
单个 Pod 使用的持久化磁盘
StatefulSet

# Filestore        //Filestore 是 Google Cloud 提供的托管 NFS 文件存储，适合：
多个 Pod 共享文件
需要 ReadWriteMany 的场景
共享配置、文件或数据目录

# 关系
Pod -> PVC -> PV -> 云存储



# StorageClass是什么
使集群能够根据 PVC的请求自动创建 PV,而无需管理员手动预先配置底层存储。


> StorageClass配置
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: pd.csi.storage.gke.io
parameters:
  type: pd-ssd
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true


> PVC关联StorageClass
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: fast-ssd