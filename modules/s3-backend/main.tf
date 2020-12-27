## ========================================================================== ##
#  Provider                                                                    #
## ========================================================================== ##
provider "aws" {
  region = var.region
}

## ========================================================================== ##
#  Declare Variables                                                           #
## ========================================================================== ##
variable "region" {
  default = "us-east-2"
}

variable "bucket_name" {
    default = "nova-s3-tfstate-use2"
}

variable "db_name" {
    default = "tfstate-lock"
}

## ========================================================================== ##
#  Resource Configuration                                                      #
## ========================================================================== ##
# Create  S3 bucket for storing state file
resource "aws_s3_bucket" "bucket" {
    bucket = var.bucket_name
 
    versioning {
      enabled = true
    }
 
 # Don't use for testing/exam study purposes
   # lifecycle {
   #   prevent_destroy = true
   # }
 
  tags = {
    Name = var.bucket_name
    env        = "test"
    managed-by = "terraform"
  }  
}

# Create a DynamoDB table for state file locking
resource "aws_dynamodb_table" "tfstate-lock" {
  name = var.db_name
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20
 
  attribute {
    name = "LockID"
    type = "S"
  }
 
  tags = {
    Name = var.db_name
    env        = "test"
    managed-by = "terraform"
  }