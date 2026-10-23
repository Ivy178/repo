# kibana

> 创建索引模式
访问 Kibana → Stack Management → Index Patterns
创建索引模式：k8s-*
选择时间字段：@timestamp
保存



> ES 优化
- 节点主从分离
- 索引生命周期管理，冷热分离
- 快照备份，定期备份到s3


> Fluent Bit 性能优化
- Flush 5                    # 增大刷新间隔
- Log_Level warning          # 减少日志
- Refresh_Interval 10        # 增大刷新间隔,减少目录扫描开销
- Mem_Buf_Limit 100MB        # 增大缓冲区
- storage.type filesystem    # 持久化缓冲



> ES高可用配置
- ES 多副本，保证数据有多份
- Pod 反亲和性，pod分散到不同节点，避免单节点故障，数据同时丢失
- 节点亲和性,调度到高性能节点

