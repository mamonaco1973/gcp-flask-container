terraform {
  backend "gcs" {
    bucket = "terraform-state-qatprr"
    prefix = "terraform/01-gar/state"
  }
}
