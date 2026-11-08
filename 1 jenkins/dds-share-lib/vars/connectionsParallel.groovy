groovy
  
def call(Map args) {
    def jsonFile = args.keyFile ?: "./target_key.json"
    def serviceAccountName = sh(script: "jq -r '.client_email' | split(\"@\")[0] '${jsonFile}", returnStdout: true).trim()
    try {
        // Only create gcloud config if not exists, avoid error if already exists
        sh """
        set +e
        if gcloud config configurations list --format="value(name)" | grep -q "\${args.build_id}"; then
        echo "Config \${args.build_id} already exists, skipping create."
        else
        gcloud config configurations create \${args.build_id}
        fi
        gcloud config configurations activate \${args.build_id}
        set -e
        """
        //Treat gsutil boto independently from gcloud to force the .gsutil directory and the credentials it contains into this build workspace
        sh(returnStdout: true, script: "gcloud config set proxy/type http_no_tunnel --configuration \${args.build_id}")
        sh(returnStdout: true, script: "gcloud config set proxy/address \${args.proxy} --configuration \${args.build_id}")
        sh(returnStdout: true, script: "gcloud config set proxy/port 3128 --configuration \${args.build_id}")
        sh(returnStdout: true, script: "gcloud auth activate-service-account --key-file=\${jsonFile} --configuration \${args.build_id}")
        sh(returnStdout: true, script: "gcloud config set core/project \${args.project_id} --configuration \${args.build_id}")
        sh(returnStdout: true, script: "gcloud config set account \${serviceAccountName}@\${args.project_id}.iam.gserviceaccount.com --configuration \${args.build_id}")
    } catch (Exception e) {
        throw new RuntimeException(e.toString())
    }
    //return config id
}