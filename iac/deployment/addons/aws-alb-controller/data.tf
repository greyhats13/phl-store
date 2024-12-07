# Terraform state data kms cryptokey
data "google_project" "current" {}
data "terraform_remote_state" "cloud_deployment" {
  backend = "gcs"

  config = {
    bucket = "fta-mstr-gcs-tfstate"
    prefix = "fta/cloud/deployment"
  }
}