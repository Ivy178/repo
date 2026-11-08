//bucket to store state lock files
bucket = "ddsin-dev-remotestate"

ss_writer_sa = []

eim_id     = "20117935"
project    = "hsbc-20117935-ddsin-dev"
region     = "asia-south1"
env        = "dev"
user_by_email = "dds-bigquery-infra-sa@hsbc-20117935-ddsin-dev.iam.gserviceaccount.com"
kms_key_name  = "projects/hsbc-6320774-kms-dev/locations/asia-south1/keyRings/hsbc-20117935-ddsin-dev/cryptoKeys/HSMbigQuery"
hase_members = [
  "group:gcp.hsbc-20117935-ddsin-dev.hase-bigquery-jobuser@hsbc.com",
  "group:gcp.hsbc-20117935-ddsin-dev.hase-bigquery-admin-priv@hsbc.com"
]

datasets = {
  CDL_IBIS_AUTH_VIEWS_NOPII = [
    {
      views = [
      ]
    }
  ],
  CDL_MYH_CASA = [
    {
      views = [
      ]
    }
  ],
  CDL_MYH_CPD = [
    {
      views = [
      ]
    }
  ],
  CDL_MYH_HML = [
    {
      views = [
      ]
    }
  ],
  CDL_MYH_OD = [
    {
      views = [
      ]
    }
  ],
  CDL_MYH_PIL = [
    {
      views = [
      ]
    }
  ],
  DDS_ASP_STG_REFRESH = [ //
    {
      views = [
      ]
    }
  ],
  DDS_HK_STG_TEMP = [
    {
      views = [
      ]
    }
  ],
  DDS_MYH_CASA = [
    {
      views = [
      ]
    }
  ],
  DDS_MYH_CPD = [
    {
      views = [
      ]
    }
  ],
  DDS_MYH_HML = [
    {
      views = [
      ]
    }
  ],
  DDS_MYH_OD = [
    {
      views = [
      ]
    }
  ],
  DDS_MYH_PIL = [
    {
      views = [
      ]
    }
  ],
  CDL_AUTH_VIEWS_PARTY_HK = [
    {
      views = [
      ]
    }
  ],
  AMH_RDM_CONS_AUTH_VIEW = [
    {
      views = [] //
    }
  ],
  DS_IHUB_DSW_HK_IBIS_WPB_DNA = [
    {
      views = [
      ]
    }
  ],
  DDS_PARTY_HK = [
    {
      views = [
      ]
    }
  ],
  DDS_AMH_RDM = [
    {
      views = [
      ]
    }
  ],
  DDS_IBIS_WPB_DNA = [
    {
      views = [
      ]
    }
  ],
  C48_DDS_ASP_STG_REFRESH = [
    {
      views = [
      ]
    }
  ],
  C48_AGENCY_PLACEMENT_AVS = [
    {
      views = [
      ]
    }
  ],
  # ICSM Related Datasets
  # SDI Datasets
  ICSM_DDS_IBIS_WPB_DNA = [
    {
      views = []
    }
  ],
  ICSM_DDS_AMH_RDM = [
    {
      views = [] //
    }
  ],
  ICSM_DDS_PARTY_HK = [
    {
      views = []
    }
  ],
  # DTD Datasets
  ICSM_DDS_ASP_STG_REFRESH = [
    {
      views = []
    }
  ],
  # HASE AP Datasets
  HASE_AP_SOURCE_DATA = [
    {
      views = []
    }
  ],
  HASE_AP_STAGING_DATA = [
    {
      views = []
    }
  ],
  HASE_AP_FINAL_DATA = [
    {
      views = []
    }
  ],
  DDS_AMH_NC = [
    {
      views = []
    }
  ]
}