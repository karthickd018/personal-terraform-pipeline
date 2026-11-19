terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.REGION
}

provider "awscc" {
  region = var.REGION
}
