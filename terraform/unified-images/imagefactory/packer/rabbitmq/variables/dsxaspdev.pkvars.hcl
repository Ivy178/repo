image_description = "rabbitmq mutable image for asp dev environment"
project_id = "hsbc-12614250-dsxasp-dev"
region = "asia-east2"
zone = "asia-east2-c"
network_project_id = "hsbc-6320774-vpchost-asia-dev"
subnetwork = "cinternal-vpc1-asia-east2"
ssh_username = "root"
machine_type = "e2-standard-2"
tags = ["fwtag-all-dev-out-efx-nexus-3-production",
        "tt-6320774-vpchost-asia-cinternal-drn-a-i-ssh",
        "fwtag-all-dev-out-alm-github",
        "fwtag-all-dev-out-alm-nexus-3-uat",
        "fwtag-all-dev-out-alm-nexus-3-production",
        "fwtag-all-dev-out-gl-repo",
        "tt-10795520-amgesgds-onprem-a-i-esgsql",
        "t-all-dev-all-in-ilb-healthcheck",
        "fwtag-6320774-dev-in-google-clouddns",
        "fwtag-6320774-dev-out-google-clouddns",
        "fwtag-6320774-dev-out-hsbc-dns",
        "fwtag-all-dev-in-nessus-scanner",
        "fwtag-cloudsql-access",
        "fwtag-all-dev-out-adlds-ldap",
        "tt-6320774-dev-a-i-128-0-0-0-2-all-ssh",
        "tt-10116889-coe-drn-a-i-all",
        "linux-pets"]
image_encryption_key = "projects/hsbc-6320774-kms-dev/locations/asia-east2/keyRings/computeEngine/cryptoKeys/HSMcomputeEngine"
service_account_email = "dsx-gce-sa@hsbc-12614250-dsxasp-dev.iam.gserviceaccount.com"
disk_size = "100"
scopes = "https://www.googleapis.com/auth/cloud-platform"
env_type = "dev"
environment = "dev"