terraform {
  backend "gcs" {
    bucket = "terraform-state-ehleqa"
    prefix = "terraform/03-cloudrun/state"
  }
}
