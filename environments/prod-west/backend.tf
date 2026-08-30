terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "notesy-terraform-state-797855613035"
    key            = "prod-west/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "notesy-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      Project     = "notesy"
      Environment = "prod-west"
      ManagedBy   = "terraform"
    }
  }
}
