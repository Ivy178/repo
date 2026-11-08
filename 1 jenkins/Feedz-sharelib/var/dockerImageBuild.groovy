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
            GOOGLE_APPLICATION_CREDENTIALS = "${env.WORKSPACE}/target_key.json"
            NO_PROXY                       = "127.0.0.1,localhost,hsbc"
            DOCKER_CONFIG_DIR              = "/kaniko/.docker"
            DOCKER_DIR                     = "${pipelineParams.IMAGE}"
        }

        stages {
            stage('Environment Init') {
                steps {
                    script {
                        def scriptcontent = libraryResource "feedzai/${pipelineParams.BUSINESS_REGION.toLowerCase()}/${C_CONFIG_YML_FILE_PATH}"
                        C_MY_OBJECT = readYaml text: "${scriptcontent}"
                    }
                }
            }

            stage('Clone Docker Repository') {
                steps {
                    git branch: "${pipelineParams.BRANCH}",
                        credentialsId: pipelineParams.GIT_CREDENTIALS,
                        url: C_MY_OBJECT.repositories.docker
                }
            }

            stage('Prepare GCP Configs') {
                steps {
                    withCredentials([file(credentialsId: pipelineParams.GCP_TERRAFORM_SA_KEY, variable: 'GCP_KEY')]) {
                        sh(script: 'cp $GCP_KEY ./target_key.json', returnStdout: false)
                        connections(build_id: "${C_CONFIG_ID}", project_id: "${C_MY_OBJECT.global.project_id}", proxy: "${C_MY_OBJECT.global.gcp_proxy}")
                    }
                }
            }

            stage('Pip Config Init') {
                steps {
                    script {
                        withCredentials([usernamePassword(credentialsId: "${pipelineParams.NEXUS302_CREDENTIALS}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                            def pipConfContent = """
                                [global]
                                index = https://${USERNAME}:${PASSWORD}@${C_MY_OBJECT.global.nexus302}/nexus/repository/pypi-group/pypi
                                index-url = https://${USERNAME}:${PASSWORD}@${C_MY_OBJECT.global.nexus302}/nexus/repository/pypi-group/simple
                                trusted-host = ${C_MY_OBJECT.global.nexus302}
                                """.stripIndent()
                            writeFile file: "${env.WORKSPACE}/${DOCKER_DIR}/pip.conf", text: pipConfContent
                            sh(script: 'curl -L -X GET https://${USERNAME}:${PASSWORD}@nexus302.systems.uk.hsbc:8081/nexus/repository/raw-alm-prod_n3p/com/hsbc/devopstooling/nexus/HSBC_Root_CA.crt --output ${DOCKER_DIR}/HSBC_Root_CA.crt')
                        }     // Pip Config Init 是 Jenkins 流水线中的一个阶段，用来准备 Docker 构建时 pip 下载 Python 依赖所需的配置：
                    }
                }
            }   

            stage('Nexus Init') {
                steps {
                    script {
                        withCredentials([usernamePassword(credentialsId: "${pipelineParams.NEXUS302_CREDENTIALS}", usernameVariable: "USERNAME", passwordVariable: "PASSWORD")]) {
                            def netrcContent = """
                                    machine ${C_MY_OBJECT.global.nexus302}
                                    login ${USERNAME}
                                    password ${PASSWORD}
                                """.stripIndent()
                            writeFile file: "${DOCKER_DIR}/.netrc", text: netrcContent    // 这段代码会把 Jenkins 中保存的 Nexus 用户名和密码写入 Docker 构建目录下的 .netrc 文件，供后续构建步骤访问 Nexus
                        }
                    }
                }
            }

            stage('Kaniko Preparation') {
                steps {
                    script {
                        withCredentials([
                            file(credentialsId: pipelineParams.GCP_TERRAFORM_SA_KEY, variable: 'GCP_KEY'),
                            file(credentialsId: 'docker_config', variable: 'DOCKER_CONFIG_JSON_FILE'),
                            file(credentialsId: 'pip_pem', variable: 'PIP_CERT_FILE'),
                            file(credentialsId: 'docker_pem', variable: 'DOCKER_CERT_FILE'),
                            usernamePassword(credentialsId: 'NEXUS302_SA_TOKEN', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                                GCP_TOKEN = sh(script: 'set +x; echo "\'json_key\':$(cat ${GCP_KEY})" | base64 -w 0; set -x', returnStdout: true).trim()
                                sh """
                                set +x
                                cp \${PIP_CERT_FILE} \${WORKSPACE}/\${DOCKER_DIR}/pip.pem
                                chmod 644 \${WORKSPACE}/\${DOCKER_DIR}/pip.pem
                                cp \${DOCKER_CERT_FILE} \${WORKSPACE}/\${DOCKER_DIR}/cert.pem
                                chmod 644 \${WORKSPACE}/\${DOCKER_DIR}/cert.pem
                                jq '.auths |= {"${C_MY_OBJECT.global.region}-docker.pkg.dev": {"auth": "${GCP_TOKEN}"}}' < \${DOCKER_CONFIG_JSON_FILE} > docker-config.json
                                set -x
                                """
                            }
                    }
                }
            }

            stage('Kaniko Build and Push') {
                environment {
                    HTTPS_PROXY="${C_MY_OBJECT.global.gcp_proxy}:3128"
                    DOCKER_CONFIG="/kaniko/.docker"
                }
                steps {
                    script {
                        def TAGS = pipelineParams.TAGS.tokenize(',')
                        def DESTINATIONS = []
                        if (pipelineParams.PUSH_TO_GCR == "true") {
                            TAGS.each { tag ->
                                DESTINATIONS.add("${C_MY_OBJECT.global.region}-docker.pkg.dev/${C_MY_OBJECT.global.project_id}/ar-container-repo/${pipelineParams.IMAGE}:${tag}")
                            }
                        }
                        if (pipelineParams.PUSH_TO_NEXUS == "true") {
                            DESTINATIONS.add("${C_MY_OBJECT.global.nexus3_hk}/${C_MY_OBJECT.global.nexus3_hk_group}/${pipelineParams.IMAGE}:${TAGS[0]}")
                        }
                        // ls current build env files
                        sh(script: "echo Listing build directory; ls -la \"\$WORKSPACE/\${DOCKER_DIR}\" || true; echo Listing workspace root:; ls -la \"\$WORKSPACE/\" || true", returnStdout: false)
                        container(name: 'kaniko', shell: '/busybox/sh') {
                            sh """
                            cp docker-config.json \${DOCKER_CONFIG_DIR}/config.json
                            cp ./\${DOCKER_DIR}/.netrc /kaniko/.netrc
                            /kaniko/executor --context \$WORKSPACE/\${DOCKER_DIR} -f \$WORKSPACE/\${DOCKER_DIR}/Dockerfile --skip-tls-verify \${DESTINATIONS.collect { "-d \$it" }.join(' ')}
                            """           //构建docker镜像，并推送到GCR和Nexus3
                        }
                    }
                }
            }

            stage('Run Docker Image Scan') {
                when {
                    expression { pipelineParams.RUN_DOCKER_IMAGE_SCAN == "true" }
                }
                steps {
                    script {
                        build job: '../Utils/dockerImageScan',
                            propagate: true,
                            wait: true,
                            parameters: [string(name: "ENVIRONMENT_NAME", value: pipelineParams.ENVIRONMENT_NAME),
                                         string(name: "BUSINESS_REGION", value: pipelineParams.BUSINESS_REGION),
                                         string(name: "IMAGE", value: pipelineParams.IMAGE),
                                         string(name: "TAG", value: pipelineParams.TAGS.tokenize(',')[0]),
                                         string(name: "SEND_SCAN_REPORT_TO", value: pipelineParams.SEND_SCAN_REPORT_TO),
                                        ]
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