
def call(pipelineParams) {

def C_MY_OBJECT

static final String C_CONFIG_ID = "${env.BUILD_TAG}".toLowerCase().replace("jenkins-", "").replace("_", "-").replace(" ", "-")
static final String C_CONFIG_YML_FILE_PATH = "${pipelineParams.ENVIRONMENT_NAME.toLowerCase()}.yml"

pipeline {
    agent {
        node { label 'cm-linux' }
    }

    options {
        timeout(time: 1, unit: 'HOURS')
    }

    environment {
        NO_PROXY = "127.0.0.1,localhost,.hsbc"
    }

    stages {
        stage('Environment Init') {
            steps {
                script {
                    // run /vars/loadConfigFile.groovy script to download configuration file from shared libraries
                    def scriptcontent = libraryResource "feedzai/${pipelineParams.BUSINESS_REGION.toLowerCase()}/${C_CONFIG_YML_FILE_PATH}"
                    // Load config.json into myObject parameter
                    // readJsonFile -> name of the method, createFileJSONObject -> name of function to run from that method
                    // if we provide only def call inside readJsonFile -> name of the method, we dont need to use function name jenkins will assume you want to call def call.
                    C_MY_OBJECT = readYaml text: "${scriptcontent}"
                }
            }
        }

        stage('Get Bearer Token') {
            steps {
                script {
                    cyberflows.getBearerToken("${pipelineParams.CYBERFLOWS_CREDENTIALS}")
                    print(env.BEARER_TOKEN)
                }
            }
        }

        stage('Create Configuration For Container Scanning') {
            steps {
                script {
                    cyberflows.createConfigurationForContainerScanning(C_MY_OBJECT, env.BEARER_TOKEN, pipelineParams)
                    print(env.CONFIGURATION_ID)
                }
            }
        }

        stage('Launch Scan') {
            steps {
                script {
                    print(env.CONFIGURATION_ID)
                    cyberflows.launchScan(C_MY_OBJECT, env.BEARER_TOKEN, env.CONFIGURATION_ID)
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '*.log', fingerprint: true, allowEmptyArchive: true
        }
    }
}
}