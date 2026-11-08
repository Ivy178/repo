project            = "hsbc-11505776-ddshk-dev"
namespace          = "ddshk"
env                = "dev3"
region             = "asia-east2"
compact_project_name = ""

bucket = {
  "bucket_purpose" : "airflow-log",
  "location" : "asia-east2",
  "storage_class" : "REGIONAL",
  "bucket_policy_only" : true,
  "force_destroy" : true,
  "kms_key_name" : "projects/hsbc-6320774-kms-dev/locations/asia-east2/keyRings/hsbc-11505776-ddshk-dev/cryptoKeys/HSMcloudStorage",
  "retention_policy_rules" : [],
  "iam_binding" : [
    {
      "role" : "roles/storage.objectViewer",
      "members" : [
        "group:gcp.hsbc-11505776-ddshk-dev.devops-team@hsbc.com"
      ]
    }
  ]
}

labels = {
  "data_classification" : "restricted",
  "bia" : "major",
  "resource" : "cloud_storage",
  "terraform" : true,
  "service_tier" : "tier1"
}