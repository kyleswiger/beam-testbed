terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # Account-wide state bucket + lock table (bootstrapped once; see
  # aws-deployment-tooling/docs/remote-state.md).
  backend "s3" {
    bucket         = "kyleswiger-tfstate-495407107865"
    key            = "beam-testbed/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Project   = var.name_prefix
      ManagedBy = "terraform"
    }
  }
}
