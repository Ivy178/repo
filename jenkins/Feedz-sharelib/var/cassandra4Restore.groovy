def call(pipelineParams) {
    def C_MY_OBJECT
    final String C_CONFIG_YML_FILE = "${pipelineParams.ENVIRONMENT_NAME.toLowerCase()}.yml"

    node('cm-linux') {
        timeout(time: 2, unit: 'HOURS') {
            // global environment
            env.GOOGLE_APPLICATION_CREDENTIALS = "${env.WORKSPACE}/target_key.json"
            env.NO_PROXY = "127.0.0.1,localhost,hsbc"
            env.KUBECONFIG = "${env.WORKSPACE}/~/.kube/config"

            try {
                stage('Environment Init') {
                    def sourceContent = libraryResource "feedzai/${pipelineParams.BUSINESS_REGION.toLowerCase()}/${C_CONFIG_YML_FILE}"
                    C_MY_OBJECT = readYaml text: "${sourceContent}"
                }

                stage('Deploy helper pod to run backup') {
                    withCredentials([file(credentialsId: pipelineParams.GCP_TERRAFORM_SA_KEY, variable: 'GCP_KEY')]) {
                        sh(script: 'cat $GCP_KEY > /target_key.json', returnStdout: false)
                        def serviceAccountName = sh(script: "jq -r '.client_email' < /target_key.json", returnStdout: true).trim()
                        echo "Using service account: ${serviceAccountName}"
                        sh(returnStdout: true, script: "gcloud config configurations create brett-\${build.id}")
                        sh(returnStdout: true, script: "gcloud config activate configuration brett-\${build.id}")
                        sh(returnStdout: true, script: "gcloud config set proxy/type http.no_tunnel")
                        sh(returnStdout: true, script: "gcloud config set proxy/address ${C_MY_OBJECT.global.gcp_proxy}")
                        sh(returnStdout: true, script: "gcloud config set proxy/port 3128")
                        sh(returnStdout: true, script: "gcloud config set core/project ${C_MY_OBJECT.global.project_id} --configuration brett-\${build.id}")    
                        sh(returnStdout: true, script: "gcloud config set account ${serviceAccountName}@${C_MY_OBJECT.global.project_id}.iam.gserviceaccount.com")

                        echo "Retrieving Cassandra credentials from GCP Secret Manager"
                        def cassUser = sh(returnStdout: true, script: "gcloud secrets versions access latest --secret=CASSANDRA_ADMIN_USERNAME").trim()
                        def cassPass = sh(returnStdout: true, script: "gcloud secrets versions access latest --secret=CASSANDRA_ADMIN_PASSWORD").trim()

                        // Authenticate to GKE (uses the same configuration)
                        sh(returnStdout: true, script: """
                        //获取 GKE 集群的连接信息和认证配置，并写入 kubeconfig
                        gcloud container clusters get-credentials ${C_MY_OBJECT.gke.cluster_name} --region ${C_MY_OBJECT.global.region} --project ${C_MY_OBJECT.global.project_id}
                        kubectl config current-context
                        kubectl config set clusters.gke_${C_MY_OBJECT.global.project_id}_${C_MY_OBJECT.global.region}_${C_MY_OBJECT.gke.cluster_name}.proxy-url http://${C_MY_OBJECT.gke.kubectl_proxy}:3128
                        """)

                        def targetNamespace = pipelineParams.NAMESPACE ?: 'cassandra'

                        // unique label value for this run
                        def runLabel = "brett-\${build.id}"
                        def prefix = sh(returnStdout: true, script: 'date +%Y%m%d-%H%M%S').trim()

                        //delete bridge deployment if existing already
                        sh(returnStdout:true, script: "kubectl delete deployment bridge -n ${targetNamespace} --ignore-not-found=true || echo 'deployment already deleted'")
                        // Render a simple deployment YAML that keeps the container running and exposes env for the pod to act
                        def deploymentYaml = """
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bridge
  namespace: ${targetNamespace}
  labels:
    app: bridge
    run: ${runLabel}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bridge
      run: ${runLabel}
  template:
    metadata:
      labels:
        app: bridge
        run: ${runLabel}
    spec:
      securityContext:
        fsGroup: 1001
        runAsGroup: 1001
        runAsNonRoot: true
        runAsUser: 1001
        seLinuxOptions: {}
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: bridge
          image: ${C_MY_OBJECT.global.region}-docker.pkg.dev/${C_MY_OBJECT.global.project_id}/${pipelineParams.CONTAINER_PREFIX}/feedzai-new-helper:latest
          env:
            - name: BOTO_CONFIG
              value: "/tmp/.boto"
            - name: CLOUDSDK_CONFIG
              value: "/tmp/.config"
            - name: SOURCE_BUCKET
              value: "${pipelineParams.SOURCE_BUCKET}"
            - name: CASSANDRA_USERNAME
              value: "${cassUser}"
            - name: CASSANDRA_PASSWORD
              value: "${cassPass}"
            - name: POD_IP
              value: "\$(POD_IP)"
            - name: PROJECT_ID
              value: "${C_MY_OBJECT.global.project_id}"
            - name: DATA_PREFIX
              value: "${prefix}"
          resources:
            requests:
              cpu: "8"
              memory: "8G"
            limits:
              cpu: "16"
              memory: "16G"
          command:
            - sh
            - -c
            - |
              while true; do sleep 5; done
          volumeMounts:
            - name: new-data
              mountPath: /tmp
      volumes:
        - name: new-data
          persistentVolumeClaim:
            claimName: backup
"""
writeFile file: "./bridge.yaml", text: deploymentYaml
sh(returnStdout: true, script: "kubectl apply -f ./bridge.yaml")
sh(returnStdout: true, script: "kubectl wait --for=condition=ready pod -l app=bridge,run=${runLabel} -n ${targetNamespace} --timeout=20m")    // 等待符合指定标签的 Pod 全部变为 Ready，最长等待 20 分钟

// get the pod name
def podName = sh(returnStdout: true, script: "kubectl get pod -n ${targetNamespace} -l app=bridge,run=${runLabel} -o jsonpath='{.items[0].metadata.name}'").trim()
echo "Helper pod is: ${podName}"

// copy service account key from the Jenkins workspace into the pod
echo "Copying service account key into pod"
sh(returnStdout: true, script: "kubectl cp ${env.WORKSPACE}/target_key.json ${targetNamespace}/${podName}:/tmp/sa.json")

// run dsbulk commands directly inside the pod using a heredoc (no separate script file)
echo "Running dsbulk loads inside pod"
sh(returnStdout: true, script: "kubectl exec -i -n ${targetNamespace} ${podName} -- bash -s <<'EOF'\n" +
        "echo 'Preparing dsbulk in pod'\n" +
        "cp -r /opt/dsbulk-1.11.1 /tmp/dsbulk-1.11.1/\n" +
        "cd /tmp/dsbulk-1.11.1/bin/\n" +
        "gcloud auth activate-service-account --key-file=/tmp/sa.json\n" +      // 使用密钥登录gcp
        "gcloud config set core/project \"\$PROJECT_ID\"\n" +
        "export GOOGLE_APPLICATION_CREDENTIALS=/tmp/sa.json\n" +
        "rm -rf /tmp/rds_data /tmp/profiles_data\n" +
        "mkdir -p /tmp/rds_data /tmp/profiles_data\n" +
        "gcloud storage cp \"gs://\$SOURCE_BUCKET/snapshots/rds/**/*.csv\" /tmp/rds_data/ \n" +
        "gcloud storage cp \"gs://\$SOURCE_BUCKET/snapshots/profiles/**/*.csv\" /tmp/profiles_data/ \n" +
        "./dsbulk load -h \"\$POD_IP\" -k rds -t feedzai_reference_data -url /tmp/rds_data --connector.csv.recursive true --connector.csv.maxCharsPerColumn 65536 -u \"\$CASSANDRA_USERNAME\" -p \"\$CASSANDRA_PASSWORD\"\n" +
        "./dsbulk load -h \"\$POD_IP\" -k profiles -t profiles -url /tmp/profiles_data --connector.csv.recursive true --connector.csv.maxCharsPerColumn 65536 -u \"\$CASSANDRA_USERNAME\" -p \"\$CASSANDRA_PASSWORD\"\n" +
"EOF\n")

currentBuild.result = 'SUCCESS'
                    }
                }
            } catch (err) {
                mail to: "alice.y.wang@hsbc.com", body: "cassandra brett backup failed: ${env.BUILD_URL} for GCP: ${C_MY_OBJECT.global.project_id} Failed.", subject: "cassandra brett backup failed"
                throw err
            } finally {  
                stage('tidy up') {
                    timeout(time: 5, unit: 'MINUTES') {
                        sh(returnStdout: true, script: "gcloud config configurations activate brett-${build.id}")    // 切换到本次构建创建的 gcloud 配置
                        // delete the helper deployment instead of a compute instance
                        def targetNamespace = pipelineParams.NAMESPACE ?: 'cassandra'
                        sh(returnStdout: true, script: "kubectl delete deployment bridge -n ${targetNamespace} --ignore-not-found=true || echo 'deployment already deleted'")
                    }
                }
                stage('post stats') {
                    echo 'Finishing...'
                    deleteDir()
                }
            }
        }
    }
}