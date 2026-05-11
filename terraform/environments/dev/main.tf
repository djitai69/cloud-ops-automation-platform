terraform {
  required_version = ">= 1.6"

  backend "s3" {
    bucket         = "itai-cloud-ops-tf-state"
    key            = "dev/terraform.tfstate"
    region         = "eu-central-1"
    # dynamodb_table = "terraform-locks"
    use_lockfile = true
    encrypt        = true
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "networking" {
  source = "../../modules/networking"
}