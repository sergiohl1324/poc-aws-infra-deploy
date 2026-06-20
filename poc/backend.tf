terraform {
  backend "s3" {
    bucket       = "chebogime-s3-states"
    key          = "poc/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
    profile      = "personal-poc"
  }
}
