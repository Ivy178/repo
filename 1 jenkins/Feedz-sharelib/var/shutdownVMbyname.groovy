
def call(pipelineParams) {
    def C_MY_OBJECT

    static final String C_CONFIG_ID = "${env.BUILD_TAG}".toLowerCase().replace('jenkins-', '').replace('_', '-').replace(' ', '-')
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
            NO_PROXY                       = '127.0.0.1,localhost,hsbc'
        }

        stages {
            stage('Environment Init') {
                steps {
                    script {
                        // run /vars/loadConfigFile.groovy script to download configuration file from shared libraries
                        def sourceContent = libraryResource "feedzai/${pipelineParams.BUSINESS_REGION.toLowerCase()}/${C_CONFIG_YML_FILE}"

                        // load config.json into myObject parameter
                        // readYamlFile -> name of the method, createFileJSONObject -> name of function to run from that method
                        // if we provide only def call inside readYamlFile -> name of the method, we dont need to use function name jenkins will assume you want to call def call.
                        C_MY_OBJECT = readYaml text: "${sourceContent}"
                    }
                }
            }

            stage('Prepare GCP Configs') {
                steps {
                    withCredentials([file(credentialsId: pipelineParams.GCP_TERRAFORM_SA_KEY, variable: 'GCP_KEY')])
                    {
                        sh(script: 'cat $GCP_KEY > ./target_key.json', returnStdout: false)

                        connections(build_id: "${C_CONFIG_ID}", project_id: "${C_MY_OBJECT.global.gcp_project_id}", proxy: "${C_MY_OBJECT.global.gcp_proxy}")
                    }
                }
            }

            stage('Shutdown given VM') {
                environment {
                    HTTPS_PROXY = "${C_MY_OBJECT.global.gcp_proxy}:3128"
                }
                steps {
                    script {
                        sh '''
                            gcloud compute instances delete ${pipelineParams.TARGET_VM_TO_DESTROY} \\
                            --project=${C_MY_OBJECT.global.project_id} \\
                            --zone=${C_MY_OBJECT.global.zone} \\
                            --quiet
                        '''
                    }
                }
            }
        }

        post {
            failure {
                mail to: env.BUILD_USER_EMAIL,
                body: "VM shutdown job: ${env.BUILD_URL} for VM ${pipelineParams.TARGET_VM_TO_DESTROY} in project: ${C_MY_OBJECT.global.project_id} Failed.\nError log:\n${currentBuild.rawBuild.getLog(100).join('\n')}",
                subject: "VM Shutdown Failed for ${pipelineParams.TARGET_VM_TO_DESTROY}"
            }
        }
    }
}