terraform {
  backend "s3" {
    bucket = "terraform-state-jordandcbarreto-clc16-939802180353-us-east-1-an"
    key    = "terraform/state"
    region = "us-east-1"
    use_lockfile = true
    encrypt = true
  }
}