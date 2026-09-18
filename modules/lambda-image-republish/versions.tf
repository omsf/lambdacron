terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    # Remove this once the AWS provider is >= 6.19 and can read public ECR
    # image metadata directly.
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.5"
    }
  }
}
