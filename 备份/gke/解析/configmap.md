最常用模式：ConfigMap 存配置模板 → init 容器渲染模板 → 写入 emptyDir → 主容器挂载使用。

例子：启动前替换数据库地址、端口、日志级别

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-template
data:
  app.conf.tmpl: |
    server.port=8080
    db.host=${DB_HOST}
    db.port=${DB_PORT}
    log.level=${LOG_LEVEL}

---
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  volumes:
    - name: config-template
      configMap:
        name: app-config-template
    - name: config-out
      emptyDir: {}

  initContainers:
    - name: render-config
      image: busybox:1.36
      command: ["/bin/sh", "-c"]
      args:
        - |
          sed -e "s/\${DB_HOST}/${DB_HOST}/g" \
              -e "s/\${DB_PORT}/${DB_PORT}/g" \
              -e "s/\${LOG_LEVEL}/${LOG_LEVEL}/g" \
              /config-template/app.conf.tmpl > /config-out/app.conf
          echo "生成后的配置："
          cat /config-out/app.conf
      env:
        - name: DB_HOST
          value: "mysql.default.svc.cluster.local"
        - name: DB_PORT
          value: "3306"
        - name: LOG_LEVEL
          value: "debug"
      volumeMounts:
        - name: config-template
          mountPath: /config-template
        - name: config-out
          mountPath: /config-out

  containers:
    - name: myapp
      image: myapp:1.0
      volumeMounts:
        - name: config-out
          mountPath: /etc/myapp
      # 主容器启动时读取 /etc/myapp/app.conf
```

执行流程

1. ConfigMap 里放的是模板，占位符如 ${DB_HOST}。
2. init 容器先启动，挂载 ConfigMap 到 /config-template。
3. init 容器用 sed 把环境变量替换进模板，生成 /config-out/app.conf。
4. config-out 是 emptyDir，生命周期跟 Pod 一致，能在 init 和主容器间共享。
5. init 容器跑完退出，主容器才启动，挂载同一个 emptyDir 到 /etc/myapp，读到最终配置。

关键点

· 主容器完全不用改，启动时配置已就绪。
· 配置模板和运行时环境解耦，不同环境改 env 即可。
· 如果镜像有 envsubst，可简化为：
    envsubst < /config-template/app.conf.tmpl > /config-out/app.conf
· 注意：init 只跑一次，ConfigMap 后续更新不会自动重新渲染，需要重启 Pod 或配合 sidecar/operator。





> ConfigMap 例子：
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_MODE: production
  timeout: "30"


> Secret 例子（stringData 写明文，创建时自动转 base64）：
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
stringData:
  DB_PASSWORD: mypassword


> pod里引用
spec:
  containers:
  - name: app
    image: myapp
    envFrom:
    - configMapRef:
        name: app-config
    - secretRef:
        name: db-secret


// ConfigMap 管配置，Secret 管密码，YAML 创建，Pod 里 envFrom 或挂卷引用