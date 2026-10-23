def call(pipelineParams) {

final String C_CONFIG_ID = "${env.BUILD_TAG}".toLowerCase().replace("jenkins-", "").replace("_", "-").replace(" ", "")
final String C_CONFIG_YML_FILE_PATH = "${pipelineParams.TARGET_ENVIRONMENT.toLowerCase()}.yml"
def C_GIT_URL_DATA
def C_MY_OBJECT
def debugMode = ""

pipeline {
    agent {label 'cm-linux'}
    options {
        ansiColor('xterm')
    }

    environment {
        NEXUS_CREDS = credentials('NEXUS302-USER-READ')
        GITHUB_CREDS = credentials('GitHub_Cred_Token')
        GOOGLE_APPLICATION_CREDENTIALS = "$env.WORKSPACE/target_key.json"
    }

    stages {
        stage('Environment Init') {
            steps{
                script{
                    if ((pipelineParams.DEBUG_BUILD ?: false).toString().toBoolean()) { debugMode = "-on-error=abort" }
                    // load configuration from shared library resources
                    def scriptcontent = libraryResource "dsx/${pipelineParams.BUSINESS_REGION.toLowerCase()}/${C_CONFIG_YML_FILE_PATH}"

                    // Load config into C_MY_OBJECT parameter
                    C_MY_OBJECT = readYaml text: "${scriptcontent}"

                    wrap([$class: 'BuildUser']) {
                        def builder = env.BUILD_USER ?: env.BUILD_USER_ID ?: 'CICD Build'
                        addBadge(text: "Build by - ${builder}", cssClass: 'badge-text--background jenkins-!-color-purple')
                        addBadge(text: "Env - ${pipelineParams.TARGET_ENVIRONMENT}", cssClass: 'badge-text--background jenkins-!-color-teal')
                        addBadge(text: "Region - ${pipelineParams.BUSINESS_REGION}", cssClass: 'badge-text--background jenkins-!-color-indigo')
                    }
                }
            }
        }

        stage('Clone Repo') {
            steps{
                script{
                    C_GIT_URL_DATA = checkout scmGit(
                        branches: [[name: pipelineParams.GIT_BRANCH]],
                        doGenerateSubmoduleConfigurations: false,
                        userRemoteConfigs: [[credentialsId: pipelineParams.GIT_CREDENTIALS,
                            url: "${pipelineParams.REPO_NAME}"]]
                    )
                }
            }
        }

        stage("GCP Auth") {
            steps {
                script{
                    withCredentials([file(credentialsId: pipelineParams.GCP_TERRAFORM_SA_KEY, variable: 'GCP_KEY')]) {
                        sh(returnStdout: false, script: '''
                                        set -e
                                        cp "$GCP_KEY" ./target_key.json
                                        chmod 600 ./target_key.json
                                        ''')
                        connectionsParallel(jsonFile: "./target_key.json", build_id: "${C_CONFIG_ID}", project_id: "${C_MY_OBJECT.global.project_id}", proxy: "${C_MY_OBJECT.global.gcp_proxy}")
                    }
                    sh '''
                    gcloud config set proxy/type http_no_tunnel
                    gcloud config set proxy/address ${C_MY_OBJECT.global.gcp_proxy}
                    gcloud config set proxy/port 3128
                    OLDEST_KEY=$(gcloud compute os-login ssh-keys list --sort-by=expireTime --limit=1 --format='value(key)' || true)
                    if [ -n "$OLDEST_KEY" ]; then
                    gcloud compute os-login ssh-keys remove --key="$OLDEST_KEY" || true
                    fi
                    '''
                }
            }
        }

        stage("Immutable Image") {
            when {
                expression { pipelineParams.IMAGE_TYPE.trim() in ["immutable"] }
            }
            steps{
                script{
                    echo "Running script for Immutable image!"
                }
            }
        }

        stage("Image Baking"){
            environment {
                HTTPS_PROXY="${C_MY_OBJECT.global.gcp_proxy}:3128"
                NO_PROXY="127.0.0.1,localhost,.hsbc"
            }
            steps{
                dir("imagefactory/packer/${pipelineParams.IMAGE_NAME}") {
                    script{
                        sh """
                            packer version

                            # Label value can only contain lowercase letters, this is to lowercase letter of tagname
                            branch_cleaned=\$(echo "\$BRANCH_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd '[:lower:][:digit:]_-')

                            echo \$branch_cleaned

                            chmod -R a+rw .

                            packer build ${debugMode}\\
                            -var nexus_user=\$NEXUS_CREDS_USR \\
                            -var nexus_pass=\$NEXUS_CREDS_PSW \\
                            -var image_type=\${pipelineParams.IMAGE_TYPE} \\
                            -var-file=./variables/dsxaspdev.pkvars.hcl \\
                            """
                    }
                }
            }
        }

        stage("Create GVNIC Image With Token") {
            when {
                expression { (pipelineParams.MYTOKEN ?: '').trim() }
            }
            steps {
                script {
                    withEnv(["MYTOKEN=${pipelineParams.MYTOKEN ?: ''}"]) {
                        wrap([$class: "MaskPasswordsBuildWrapper", varPasswordPairs: [[password: pipelineParams.MYTOKEN]]]) {
                            sh """
                                set -euo pipefail
                                DATE=\$(date -u +%Y%m%d%H%M%S)
                                TOKEN_FILE=\$(mktemp)
                                printf "%s" "\$MYTOKEN" > "\$TOKEN_FILE"

                                if gcloud --access-token-file="\$TOKEN_FILE" compute images create "gce-rhel8-ver2-stage2-gvnic-\${DATE}" \\
                                --family="gce-rhel8-ver2-stage2" \\
                                --source-image-family="hsbc-rhel-8-java-airflow-immutable" \\
                                --source-image-project="hsbc-12614250-dsxasp-dev" \\
                                --guest-os-features="GVNIC"; then
                                echo "SUCCESS: gce-rhel8-ver2-stage2-gvnic-\${DATE} created"
                                else
                                echo "Warning: image is not created"
                                fi

                                rm -f "\$TOKEN_FILE"
                                """
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}