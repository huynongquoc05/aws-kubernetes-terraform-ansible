terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Khuyên dùng bản mới ổn định
    }
  }
  backend "s3"{
    bucket = "my-k8s-cluster-tfstate-2026"
    key            = "k8s-cluster/terraform.tfstate"
    region = "ap-southeast-1"
    dynamodb_table = "terraform-state-lock"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}