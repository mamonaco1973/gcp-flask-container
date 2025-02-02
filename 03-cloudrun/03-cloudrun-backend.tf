terraform {
  backend "gcs" {
    bucket = "terraform-state-tmonoy"
    prefix = "terraform/03-cloudrun/state"
  }
}
