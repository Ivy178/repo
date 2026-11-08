import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.Domain
import org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl
import com.cloudbees.hudson.plugins.folder.*
import com.cloudbees.hudson.plugins.folder.properties.*
import com.cloudbees.hudson.plugins.folder.properties.FolderCredentialsProperty
import com.cloudbees.model.Jenkins

def call(pipelineParams) {
    def C_MY_OBJECT

    static final String C_CONFIG_ID = "${env.BUILD_TAG}".toLowerCase().replace('jenkins-', '').replace('_', '-').replace(' ', '-')
    static final String C_CONFIG_YML_FILE_PATH = "${pipelineParams.ENVIRONMENT_NAME.toLowerCase()}.yml"

    //GCP Service Account
    def sa_Name = ''

    //Jenkins Credential Ids
    def jenkins_cred_id = null
    def jenkins_cred_desc = null

    //Old SA Creds File Name
    def old_file_name = null

// ---- USAGE ----
// WARNING - ONLY SCHEDULE KEY ROTATION WHEN NO OTHER JENKINS JOBS ARE RUNNING THAT ARE RELYING ON THE STORED GCP SERVICE ACCOUNT KEY TO OBTAIN AUTHORISATION INTO GCP
// THAT'S WHY THIS JOB CONTENTS MUST NOT BE EMBEDDED INTO NORMAL PIPELINE RUNS. IF PIPELINES RUN IN PARALLEL, AND THEY SHOULD, THEN THERE IS A SIGNIFICANT RISK OF SA KEY BEING DELETED ON GCP WHILST
// A PARALLEL PIPELINE IS RUNNING

    pipeline {
        agent {
            label 'cm-linux'
        }

        stages {
            stage('Environment Init') {
                steps {
                    script {
                        // run /vars/loadConfigFile.groovy script to download configuration file from shared libraries
                        def scriptContent = libraryResource "feedzai/${pipelineParams.BUSINESS_REGION.toLowerCase()}/${C_CONFIG_YML_FILE_PATH}"

                        // load config.json into myObject parameter
                        // readYamlFile -> name of the method, createFileJSONObject -> name of function to run from that method
                        // if we provide only call inside readYamlFile -> name of the method, we dont need to use function name jenkins will assume you want to call def call.
                        C_MY_OBJECT = readYaml text: "${scriptContent}"
                    }
                }
            }

            stage('Prepare GCP Configs') {
                steps {
                    script {
                        withCredentials([file(credentialsId: pipelineParams.cred_Id, variable: 'GCP_KEY')])
                        {
                            sh(returnStdout: false, script: 'cp $GCP_KEY ./target_key.json && chmod 700 ./target_key.json')
                            connections(build_id: "${C_CONFIG_ID}", project_id: "${C_MY_OBJECT.global.project_id}", proxy: "${C_MY_OBJECT.global.gcp_proxy}")
                        }
                    }
                }
            }

            stage('Delete GCP SA Key except the one in use by Jenkins') {
                steps {
                    script {
                        sa_Name = C_MY_OBJECT.sa_rotation[pipelineParams.cred_Id]
                        def current_sa_key_json = readJSON file: './target_key.json'

                        def currentKeyId = current_sa_key_json.private_key_id

                        sh """
                            gcloud iam service-accounts keys list \
                            --iam-account ${sa_Name}@${C_MY_OBJECT.global.project_id}.iam.gserviceaccount.com \
                            --format="value(KEY_ID)" \
                            --filter="CREATED_AT.date('%Y-%m-%d', Z)<\$(date --date='-60 days' +'%Y-%m-%d')" > allKeys.txt
                        """

                        def allKeys = readFile('allKeys.txt').split('\n').findAll { it?.trim() }

                        if (allKeys.size() == 0) {
                            echo "No keys to delete for service account ${sa_Name}."
                        } else {
                            echo "Keys to delete for service account ${sa_Name}: ${allKeys.join(', ')}"

                            allKeys.each { keyId ->
                                if (keyId != currentKeyId) {
                                    try {
                                        sh """
                                            gcloud iam service-accounts keys delete ${keyId} \
                                            --iam-account ${sa_Name}@${C_MY_OBJECT.global.project_id}.iam.gserviceaccount.com \
                                            --quiet
                                        """
                                    } catch (Exception e) {
                                        echo "Skipping deletion for keyId ${keyId} due to error: ${e.message}"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        post {
            failure {
                mail to: 'fdzdevopsteam@noexternalmail.hsbc.com',
                body: "SA Key delete job: ${env.BUILD_URL} for service account ${sa_Name} in project: ${C_MY_OBJECT.global.project_id} Failed.\nError Log:\n${currentBuild.rawBuild.getLog(100).join('\n')}",
                subject: "Jenkins Automation Key Delete Failed for ${sa_Name}"
            }
        }
    }
}