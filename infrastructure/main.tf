terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "aws-cloud-resume-remote-backend"
    key = "terraform.tfstate"
    region = "ap-south-1"
    encrypt = true
    dynamodb_table = "aws-cloud-resume-state-lock"
  }
}

provider "aws" {
  region = "ap-south-1"
}
