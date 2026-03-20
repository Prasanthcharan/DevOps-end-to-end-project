terraform {
  backend "s3" {
    bucket       = "snappaste-terraform-state-884337374668"
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
