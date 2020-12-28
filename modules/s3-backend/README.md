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

1. Open up a terminal and type `cd modules/s3-backend`
2. Change `terraform.tfvars.example` to `terraform.tfvars` and update the variable values
3. In the terminal, type the command `terraform init` to initialize the configuration
4. Once ready to configure AWS resources for the Terraform backend, type `terraform apply --auto-approve`
