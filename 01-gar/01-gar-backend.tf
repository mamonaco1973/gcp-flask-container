terraform {
  backend "gcs" {
    bucket = "terraform-state-ehleqa"
    prefix = "terraform/01-gar/state"
  }
}
