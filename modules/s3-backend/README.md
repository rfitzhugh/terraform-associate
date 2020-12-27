To use, rename the `terraform.tfvars.example` file to simply `terraform.tfvars` and update variable values.

Once the resources are provisioned, the S3 bucket can be used to store the state file and ensure locking through use of DynamoDB. 

The Terraform configuration block should resemble the following:

```
terraform {
 backend “s3” {
 encrypt = true
 bucket = "technicloud-s3-tfstate-use2"
 dynamodb_table = "tfstate-lock"
 region = us-east-2
 key = path/to/state/file
 }
}
```