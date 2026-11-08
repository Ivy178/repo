terraform {
  required_version = ">= 1.0.2"
  backend "gcs" {
    //bucket will give in .config file because it's unique or different for each region or env to store state file.
    prefix = "gcs3/gcs-airflow-log"
  }
}