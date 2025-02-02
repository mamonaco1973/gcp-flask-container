terraform {
  backend "gcs" {
    bucket = "terraform-state-hpxjnr"
    prefix = "terraform/03-cloudrun/state"
  }
}
