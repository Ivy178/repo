#!/usr/bin/env groovy
def call(Map stepParams = [:]) {
def label = "gcpActivateServiceAccount"

def mandatoryParams = [
'gcpServiceAccountCredentialsId',
'gcpProjectName',
'gcpProxyEnv',
].find { !stepParams."${it}" }
if (mandatoryParams) throw new Exception("[ERROR] Missing parameter: ${mandatoryParams} is required.")

def gcpProjectName = stepParams.gcpProjectName
def proxyAddress = getGcpProxyAddress(stepParams.gcpProxyEnv)

withCredentials([
file(credentialsId: stepParams.gcpServiceAccountCredentialsId, variable: 'GCP_SERVICEACCOUNT_KEY')
]) {
withEnv([
"GCP_PROXY_ADDRESS=${proxyAddress}",
"GCP_PROJECT_NAME=${gcpProjectName}"
]) {
sh(
label: "$label",
script: '''#!/bin/bash
set -euo pipefail +x

if [ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
echo 'GOOGLE_APPLICATION_CREDENTIALS is not set'
exit 1
fi

mkdir -p -v "$(dirname "${GOOGLE_APPLICATION_CREDENTIALS}")"

gcloud config set proxy/address "$GCP_PROXY_ADDRESS"
gcloud config set proxy/port 3128
gcloud config set proxy/type http

gcloud auth activate-service-account --key-file "$GCP_SERVICEACCOUNT_KEY"
# Temporary commented out - causing issues
# if gcloud auth activate-service-account --key-file "$GCP_SERVICEACCOUNT_KEY"; then
# mapfile -t projects_array <<< $(gcloud projects list --format="value(projectId)")
# if [[ "${#projects_array[@]}" < 1 ]]; then
# echo "It seems that you have no access to any project. Authentication failed!"
# exit 101
# else
# echo "It seems that you have access to following projects: ${projects_array[@]}. Authentication succeded!"
# fi
# else
# echo "An error occured during authentication. Authentication failed, credentials may be invalid, see please error above!"
# exit 102
# fi

gcloud config set core/project "$GCP_PROJECT_NAME"

cp -f "$GCP_SERVICEACCOUNT_KEY" "${GOOGLE_APPLICATION_CREDENTIALS}"
'''
)
}
}
}