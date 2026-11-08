
import groovy.json.JsonOutput

def call(pipelineParams) {
    final String centralTerraformDeploymentJob = 'Deploy/non-prod/terraform_deploy'
    def C_MY_OBJECT
    final String C_CONFIG_ID = "${env.BUILD_TAG}".toLowerCase().replace('jenkins-', '').replace('_', '-').replace(' ', '-')
    def new_image_name_nonprod
    def new_image_name_prod
    def target_env
    def builderEmail

    pipeline {
        agent {
            node { label 'cm-linux' }
        }

        options {
            timeout(time: 4, unit: 'HOURS')
        }

        environment {
            GOOGLE_APPLICATION_CREDENTIALS = "${env.WORKSPACE}/target_key.json"
            NO_PROXY                        = '127.0.0.1,localhost,.hsbc'
            SKIP_BUILD                      = false  //only for debug purpose
        }

        stages {
            stage('Environment Init') {
                steps {
                    script {
                        def sourceContent = libraryResource "feedzai/${pipelineParams.BUSINESS_REGION.toLowerCase()}/${pipelineParams.ENVIRONMENT_NAME.toLowerCase()}.yml"
                        C_MY_OBJECT = readYaml text: "${sourceContent}"

                        wrap([$class: 'BuildUser']) {
                            def builder = env.BUILD_USER ?: env.BUILD_USER_ID ?: 'CICD Build'
                            builderEmail = env.BUILD_USER_EMAIL
                            addBadge(text: "Build by - ${builder}", cssClass: 'badge-text--background jenkins-!-color-purple')
                            addBadge(text: "Env - ${pipelineParams.ENVIRONMENT_NAME}", cssClass: 'badge-text--background jenkins-!-color-teal')
                            addBadge(text: "Region - ${pipelineParams.BUSINESS_REGION}", cssClass: 'badge-text--background jenkins-!-color-indigo')
                            addBadge(text: "Component - ${pipelineParams.FEEDZAI_COMPONENT}", cssClass: 'badge-text--background jenkins-!-color-orange')
                            addBadge(text: "Version - ${pipelineParams.INSTALLER_ASSEMBLY_VER}", cssClass: 'badge-text--background jenkins-!-color-yellow')
                        }
                    }
                }
            }

            stage('Image Build') {
                environment {
                    HTTPS_PROXY = "${C_MY_OBJECT.global.gcp_proxy}:3128"
                }
                when { expression { env.SKIP_BUILD != 'true' } }
                steps {
                    script {
                        def buildResult
                        echo "Triggering image refresh pipeline for project: ${C_MY_OBJECT.global.project_id}"

                        if (pipelineParams.ENVIRONMENT_NAME.toLowerCase() in ['dev', 'qa']) {
                            target_env = pipelineParams.ENVIRONMENT_NAME
                        } else {
                            target_env = C_MY_OBJECT.imageFactory.base_env
                        }

                        buildResult = build job: 'Build/packer_gce_image_build',
                            propagate: true,
                            wait: true,
                            parameters: [
                                string(name: 'ENVIRONMENT_NAME', value: "${target_env}"),
                                string(name: 'BUSINESS_REGION', value: "${pipelineParams.BUSINESS_REGION}"),
                                string(name: 'FEEDZAI_COMPONENT', value: "${pipelineParams.FEEDZAI_COMPONENT}"),
                                string(name: 'INSTALLER_ASSEMBLY_VER', value: "${pipelineParams.INSTALLER_ASSEMBLY_VER}"),
                                string(name: 'GIT_BRANCH', value: "${pipelineParams.GIT_BRANCH}")
                            ]

                        if (buildResult.result == 'SUCCESS') {
                            echo 'Image build succeeded, continuing...'
                            new_image_name_nonprod = buildResult.description
                            echo "New image name: ${new_image_name_nonprod}"

                            if (pipelineParams.BUSINESS_REGION.toLowerCase() in ['ap', 'uk'] && pipelineParams.ENVIRONMENT_NAME.toLowerCase() in ['pre-prod', 'prod']) {
                                echo 'extra step for UK/AP as their image are in dev, transferring to QA for G3 deployment '
                                build job: 'Build/gcp_image_dev_transfer',
                                propagate: true,
                                wait: false,
                                parameters: [
                                    string(name: 'FROM_ENVIRONMENT', value: "Dev"),
                                    string(name: 'TO_ENVIRONMENT', value: "Qa"),
                                    string(name: 'BUSINESS_REGION_SOURCE', value: "${pipelineParams.BUSINESS_REGION}"),
                                    string(name: 'BUSINESS_REGION_TARGET', value: "${pipelineParams.BUSINESS_REGION}"),
                                    string(name: 'SOURCE_IMAGE', value: "${new_image_name_nonprod}")
                                ]
                            }
                        } else {
                            echo 'Image build failed, exiting...'
                        }
                    } // end of script
                }
            }

            stage('Build Immutable Image') {
                when { expression { pipelineParams.ENVIRONMENT_NAME.toLowerCase() in ['pre-prod', 'prod'] } }
                steps {
                    script {
                        // trigger image lockdown job
                        if (new_image_name_nonprod) {
                            echo "Triggering image lockdown for image: ${new_image_name_nonprod}"
                            def lockdownResult = build job: 'Build/gcp_image_lockdown_auto_promotion',
                                propagate: true,
                                wait: true,
                                parameters: [
                                    booleanParam(name: 'CREATE_GMTEST_VM', value: true),
                                    string(name: 'ENVIRONMENT_NAME', value: "${target_env}"),
                                    string(name: 'BUSINESS_REGION', value: "${pipelineParams.BUSINESS_REGION}"),
                                    string(name: 'FEEDZAI_COMPONENT', value: "${pipelineParams.FEEDZAI_COMPONENT}"),
                                    string(name: 'SOURCE_IMAGE_TO_LOCK', value: "${new_image_name_nonprod}"),
                                    string(name: 'GIT_BRANCH', value: "${pipelineParams.GIT_BRANCH}")
                                ]

                            if (lockdownResult.result == 'SUCCESS') {
                                new_image_name_prod = new_image_name_nonprod + '-immutable'
                                echo 'Image lockdown succeeded, continuing...'
                                echo "locked imagename is ${new_image_name_prod}"
                            } else {
                                echo 'Image lockdown failed, exiting...'
                            }
                        } else {
                            echo 'No new image name found, skipping image lockdown.'
                        }
                    }
                }
            }

            stage('Deploy image by HDPv2') {
                when { expression { new_image_name_nonprod != null && new_image_name_nonprod != '' && (pipelineParams.ENVIRONMENT_NAME.toLowerCase() in ['qa']) } }
                steps {
                    script {
                        def currentDate = new Date()

                        // change format to this one 2025-09-10 12:00:00
                        def crStartTime = new Date(currentDate.time + (360 * 60 * 1000)).format('yyyy-MM-dd HH:mm:ss', TimeZone.getTimeZone('UTC'))
                        def crStartTime2Min = new Date(currentDate.time + (362 * 60 * 1000)).format('yyyy-MM-dd HH:mm:ss', TimeZone.getTimeZone('UTC'))
                        def crEndDateTime = new Date(currentDate.time + (720 * 60 * 1000)).format('yyyy-MM-dd HH:mm:ss', TimeZone.getTimeZone('UTC'))

                        def lastJobId = env.BUILD_TAG.split('-').last()
                        echo "New QA image name is ${new_image_name_nonprod}" +
                                "| Last Job ID: ${lastJobId} crStartDateTime: ${crStartTime} crStartTime2Min: ${crStartTime2Min} crEndDateTime: ${crEndDateTime}"

                        if (new_image_name_nonprod) {
                            def component_name
                            if (pipelineParams.FEEDZAI_COMPONENT == 'pulse-dsf') {
                                component_name = 'skip_pulse_data_science'
                                if (pipelineParams.BUSINESS_REGION == 'HASE') {
                                    component_name = 'skip_pulse_data_science_hase'
                                }
                            } else if (pipelineParams.FEEDZAI_COMPONENT == 'reference-data') {
                                component_name = 'skip_reference_data_service'
                                if (pipelineParams.BUSINESS_REGION == 'HASE') {
                                    component_name = 'skip_reference_data_service_hase'
                                }
                            } else if (pipelineParams.FEEDZAI_COMPONENT == 'spcoe-rhel-proxy-server') {
                                // due to difference of proxy-in/out terraform script, we should pass empty string for image name there
                                new_image_name_nonprod = ''
                                new_image_name_prod = ''
                                component_name = 'skip_foss'
                                if (pipelineParams.BUSINESS_REGION == 'HASE') {
                                    component_name = 'skip_foss_hase'
                                }
                            } else {
                                component_name = "skip_${pipelineParams.FEEDZAI_COMPONENT.replace('-', '_')}"
                                if (pipelineParams.BUSINESS_REGION == 'HASE') {
                                    component_name = "skip_${pipelineParams.FEEDZAI_COMPONENT.replace('-', '_')}_hase"
                                }
                            }

                            def buildResult = build job: "Deploy/infra-HDPv2/release%2F${pipelineParams.BUSINESS_REGION}",
                                wait: false,
                                parameters: [
                                    string(name: 'target_env_non-prod', value: 'QA'),
                                    string(name: 'target_env-prod', value: 'PREPROD'),
                                    string(name: 'component_name', value: "${component_name}"),
                                    string(name: 'tg_action', value: 'apply'), //default action for image refresh is apply
                                    string(name: 'image_name_nonprod', value: "${new_image_name_nonprod}"),
                                    string(name: 'image_name_prod', value: ''),
                                    booleanParam(name: 'deploy_production', value: false),
                                    string(name: 'pwi_artefact_version', value: "${new Date().format('yyyyMMddHHmmss')}"),
                                    string(name: 'git_branch', value: 'main'),
                                    string(name: 'reference_cr_start_time_utc', value: "${crStartTime}"),
                                    string(name: 'auto_release_time_utc', value: "${crStartTime2Min}"),
                                    string(name: 'reference_cr_end_time_utc', value: "${crEndDateTime}")
                                ]
                        } else {
                            echo 'No new image name found, skipping infra deploy.'
                        }
                    }
                }
            }
        }

        post {
            failure {
                script {
                    if (builderEmail?.trim()) {
                        mail(
                            to: builderEmail,
                            body: "image build failed: ${env.BUILD_URL} for GCP: ${C_MY_OBJECT.global.project_id} Failed.",
                            subject: 'Feedzai Image Build Failed'
                        )
                    } else {
                        echo 'Skipping failure email: no email address is available for the build user.'
                    }
                }
            }
        }
    }
}