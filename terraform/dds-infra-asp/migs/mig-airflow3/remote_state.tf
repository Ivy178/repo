//which are common for both the regions or envs mentioning at here
terraform {
  required_version = ">= 1.0.2"
  backend "gcs" {
    //bucket will give in .config file because it's unique or different for each region or env to store state file.
    prefix = "mig/airflow"
  }
}