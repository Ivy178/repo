def call(pipelineParams) {

def C_MY_OBJECT

static final String C_CONFIG_ID = "${env.BUILD_TAG}".toLowerCase().replace("jenkins-", "").replace("_", "-").replace(" ", "-")
static final String C_CONFIG_YML_FILE = "${pipelineParams.ENVIRONMENT_NAME.toLowerCase()}.yml"

pipeline {
    agent {
        node { label 'cm-linux' }
    }

    options {
        timeout(time: 1, unit: 'HOURS')
    }

    environment {
        GOOGLE_APPLICATION_CREDENTIALS = "$env.WORKSPACE/target_key.json"
        NO_PROXY                       = "127.0.0.1,localhost,.hsbc"
    }

    stages {
        stage('Environment Init') {
            steps {
                script {
                    // run /vars/LoadConfigFile.groovy script to download configuration file from shared Libraries
                    def sourceContent = libraryResource "feedzai/${pipelineParams.BUSINESS_REGION.toLowerCase()}/${C_CONFIG_YML_FILE}"

                    // Load config.json into myObject parameter
                    // readJsonFile -> name of the method, createFileJSONObject -> name of function to run from that method
                    // if we provide only def call inside readJsonFile -> name of the method, we dont need to use function name jenkins will assume you want to call def call.
                    C_MY_OBJECT = readYaml text: "${sourceContent}"
                }
            }
        }

        stage('Prepare GCP Configs') {
            steps {
                withCredentials([file(credentialsId: pipelineParams.GCP_TERRAFORM_SA_KEY, variable: 'GCP_KEY')])
                {
                    sh(script: 'cat $GCP_KEY > ./target_key.json', returnStdout: false)
                }
                connections(build_id: "${C_CONFIG_ID}", project_id: "${C_MY_OBJECT.global.project_id}", proxy: "${C_MY_OBJECT.global.gcp_proxy}")
            }
        }

        stage('Scaleup GKE Node Pools') {
            environment {
                HTTPS_PROXY="${C_MY_OBJECT.global.gcp_proxy}:3128"
            }
            steps {
                script {
                    def projectId = C_MY_OBJECT.global.project_id

                    def clusterList = sh(
                        script: "gcloud container clusters list --project=$projectId --format='csv[no-heading](name,location)'",
                        returnStdout: true
                    ).trim().readLines()

                    if (clusterList.isEmpty()){
                        echo "No GKE clusters found in project: $projectId"
                        return
                    }

                    clusterList.each {line ->
                        def parts=line.tokenize(',')
                        if(parts.size()<2){
                            echo "\n skipping line: ${line}"
                            //return
                        }

                        def (clusterName, location) = parts
                        def locationType = location ==~ /.*-[a-z]$/ ? "zone" : "region"

                        echo "\n Processing cluster: ${clusterName} ${locationType}: ${location}"

                        def nodePools = sh(
                            script: "gcloud container node-pools list --cluster=${clusterName} " +
                                    "--project=${projectId} --${locationType}=${location} --format='value(name)'",
                            returnStdout:true
                        ).trim().readLines()

                        if (nodePools.isEmpty()){
                            echo "No node pools found for cluster ${clusterName}"
                            return
                        }

                        nodePools.each { nodePool ->
                            if (pipelineParams.STATUS == "UP") {
                                def currentSize = sh(
                                    script: "gcloud container node-pools describe ${nodePool} --cluster=${clusterName} " +
                                            "--project=${projectId} --${locationType}=${location} --format='value(initialNodeCount)'",
                                    returnStdout: true
                                ).trim()
                                echo "current size of nodepool ${currentSize}"
                                if (currentSize == "0" || currentSize == ""){
                                    sh(script: "gcloud container node-pools update ${nodePool} --cluster ${clusterName} --${locationType}=${location} --enable-autoscaling --min-nodes 1 --max-nodes 3 --project=${projectId}")
                                }
                            }else if (pipelineParams.STATUS == "DOWN") {
                                echo "Disabling autoscaling for '${nodePool}'...."
                                sh(script: "gcloud container node-pools update ${nodePool} --cluster=${clusterName} --${locationType}=${location} --project=${projectId} --no-enable-autoscaling")
                                echo "Resizing '${nodePool}' to 0..."
                                sh(script: "gcloud container clusters resize ${clusterName} --node-pool=${nodePool} --num-nodes=0 --${locationType}=${location} --project=${projectId} --quiet --async")
                            }
                        }
                    }
                    echo "\n all clusters processed."
                }
            }
        }
    }

    post {
        failure {
            mail to: "fdzdevopsteam@noextralmail.hsbc.com", body: "Jenkins GKE startup build: ${env.BUILD_URL} for GCP: ${C_MY_OBJECT.global.project_id} Failed.", subject: "Jenkins Automation GKE Startup"
        }
    }
}
}