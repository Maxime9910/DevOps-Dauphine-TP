terraform {
  backend "gcs" {
    bucket = "primeval-mark-441708-t2-terraform-state"
    prefix = "terraform/state"
  }
}

