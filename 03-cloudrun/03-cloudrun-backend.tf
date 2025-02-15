terraform {
  backend "gcs" {
    bucket = "terraform-state-qatprr"
    prefix = "terraform/03-cloudrun/state"
  }
}
