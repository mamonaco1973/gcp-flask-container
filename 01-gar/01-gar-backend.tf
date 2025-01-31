terraform {
  backend "gcs" {
    bucket = "terraform-state-tmonoy"
    prefix = "terraform/01-gar/state"
  }
}
