terraform {
  backend "gcs" {
    bucket = "terraform-state-hpxjnr"
    prefix = "terraform/01-gar/state"
  }
}
