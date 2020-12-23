provider "aws" {
    region = var.aws_region
}

# Additional provider configuration for west coast region
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

terraform {
  required_providers {
    aws = "~> 2.7"
  }
}