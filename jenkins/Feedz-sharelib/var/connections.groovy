def call(Map args) {
    def jsonFile = args.jsonFile ?: "./target_key.json"
    def serviceAccountName = sh(script: "jq -r '.client_email | split(\"@\")[0]' '${jsonFile}'", returnStdout: true).trim()

    try {
        sh(returnStdout: true, script: "gcloud config configurations create ${args.build_id}")
        //Treat gsutil boto independently from gcloud to force the .gsutil directory and the credentials it contains into this build workspace
        sh(returnStdout: true, script: 'gcloud config set proxy/type http_no_tunnel')
        sh(returnStdout: true, script: "gcloud config set proxy/address ${args.proxy}")
        sh(returnStdout: true, script: 'gcloud config set proxy/port 3128')
        sh(returnStdout: true, script: "gcloud auth activate-service-account --key-file=${jsonFile}")
        sh(returnStdout: true, script: "gcloud config set core/project ${args.project_id} --configuration ${args.build_id}")
        sh(returnStdout: true, script: "gcloud config set account ${serviceAccountName}@${args.project_id}.iam.gserviceaccount.com")
    } catch (Exception e) {
        throw new RuntimeException(e.toString())
    }
    //return config id
}