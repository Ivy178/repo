#!/bin/bash

function help() {
  echo
  echo "This script copies latest GCE image of given family from source project to destination project"
  echo
  echo "Syntax: $0 -p <source project> -s <source image family> -d <destination project> -k <kms key project> [-h]"
  echo "Options:"
  echo "  -h                Prints this message."
  echo "  -s <source image project> Source GCP project."
  echo "  -i <source image family>  Name of the GCE image family of the image to be copied"
  echo "  -d <destination project>  Name of the GCP destination project."
  echo "  -k <kms key project>      KMS key project."
  echo
}

function process() {
  echo "Execution start."

  echo " Getting latest image of family: [${INPUT_IMAGE_FAMILY}] from [${INPUT_SOURCE_PROJECT}] project."

  latestImagefromFamily=$(gcloud compute images list --filter="family='${INPUT_IMAGE_FAMILY}'" \
  --sort-by=creationTimestamp \
  --limit=1 --format="value(name)" \
  --project=${INPUT_SOURCE_PROJECT} \
  --verbosity=error || exit)

  echo " Got following image: [${latestImagefromFamily}]"
  echo " Checking if this image exists in [${INPUT_DESTINATION_PROJECT}] project."

  if [[ $(gcloud compute images list --filter="name='${latestImagefromFamily}'" --project=${INPUT_DESTINATION_PROJECT} --verbosity=error || exit) ]];
  then
    # image exists
    echo " Latest image already exists in destination project. Exiting..."
    echo " Bye bye!"
  else
    echo " Copying image [${latestImagefromFamily}] to destination project [${INPUT_DESTINATION_PROJECT}]."
    gcloud compute images create ${latestImagefromFamily} \
    --source-image=${latestImagefromFamily} \
    --source-image-project=${INPUT_SOURCE_PROJECT} \
    --family=${INPUT_IMAGE_FAMILY} \
    --kms-key=${INPUT_KMS_KEY} \
    --verbosity=error || exit
  fi

  echo "Processing done."
}

###########################
##### Main program #####
###########################

INPUT_SOURCE_PROJECT=""
INPUT_IMAGE_FAMILY=""
INPUT_DESTINATION_PROJECT=""
INPUT_KMS_KEY=""

while getopts ":hi:s:d:k:" opt; do
case $opt in
h) # display help
  help
  exit;;
s)
  INPUT_SOURCE_PROJECT=$OPTARG
  ;;
i)
  INPUT_IMAGE_FAMILY=$OPTARG
  ;;
d)
  INPUT_DESTINATION_PROJECT=$OPTARG
  ;;
k)
  INPUT_KMS_KEY=$OPTARG
  ;;
\?) # invalid option
  echo "Error: Invalid option!"
  exit;;
esac
done

if [ -z $INPUT_DESTINATION_PROJECT ] && [ -z $INPUT_SOURCE_PROJECT ] && [ -z $INPUT_IMAGE_FAMILY ] && [ -z $INPUT_KMS_KEY ]; then
  echo "[ERROR] Missing required parameters!"
  help
  exit
fi

if [ -z $INPUT_DESTINATION_PROJECT ]; then
  echo "[ERROR] Destination project (-d) input paramter missing!"
  exit -1
fi

if [ -z $INPUT_SOURCE_PROJECT ]; then
  echo "[ERROR] Source project (-s) input paramter missing!"
  exit -1
fi

if [ -z $INPUT_IMAGE_FAMILY ]; then
  echo "[ERROR] Image family (-i) input paramter missing!"
  exit -1
fi

if [ -z $INPUT_KMS_KEY ]; then
  echo "[ERROR] KMS project (-k) input paramter missing!"
  exit -1
fi

process


