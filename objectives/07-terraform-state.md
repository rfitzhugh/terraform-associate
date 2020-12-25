# 7. Implement and Maintain State

Terraform stores state about managed infrastructure and configuration to map real world resources to configuration, keep track of metadata, and to improve performance for large infrastructures. This state is stored by default in a local file named `terraform.tfstate`, but can also be stored remotely for team collaboration.

## Backends

A Terraform “backend” determines how the state is loaded and how operations, such as `terraform apply`, are executed. This abstraction enables users to store sensitive state information in a different, secured location. Backends are configured with a nested `backend` block within the top-level `terraform` block. Only one backend block can be provided in a configuration. Backend configurations cannot have any interpolations or use any variables, thus must be hardcoded.

### Local 

By default, Terraform uses the "local" backend. The local backend stores state on the local filesystem, locks that state using the system, and performs operations locally.

```
terraform {
  backend "local" {
    path = "relative/path/to/terraform.tfstate"
  }
}
```

Users do not need to declare a local state block unless it is desired for the backend to be a different location than the working directory. The backend defaults to `terraform.tfstate` relative to the root module.

### Remote

Remote backends enable Terraform to use shared storage space for state data, so the same infrastructure can be managed across a team. Remote state is loaded in memory when it is used. This security consideration ensures that there is nothing persistent on disk. 

The remote backend can store Terraform state in Terraform Cloud. An example of this would resemble: 

```
terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "technicloud"

    workspaces {
      name = "scaling-compute"
    }
  }
}
```

This assumes a workspace called `scaling compute` has been created for this use. 

Other types of backends, such as JFrog Artifactory, Azure, and Amazon S3, are supported. A commonly used configuration is to store the state as a key in an Amazon S3 bucket. This backend type supports state locking and consistency checking by using Amazon DynamoDB. This can be enabled by setting the `dynamodb_table` field to an existing DynamoDB table name that can be used to lock multiple remote state files. Terraform generates key names that include the values of the `bucket` and `key` variables. This would resemble the following: 

```
terraform {
  backend "s3" {
    bucket = "technicloud-bucket-tfstate"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}
```

This assumes we have a bucket created called `technicloud-bucket-tfstate`. The Terraform state is written to the key `dev/terraform.tfstate`.

If a local state is then changed to an Amazon S3 backend, users will be prompted whether to copy existing state to the new backend when `terraform init` is executed. Similarly, if a remote backend configuration is removed, users will be prompted to migrate state back to local when `terraform init` is executed.

### Partial

When some or all of the arguments are omitted, it is called a partial configuration. Users do not have to specify every argument for the backend configuration. In some cases, omitting certain arguments may be desirable, such as to avoid storing secrets like access keys, within the main configuration. To provide the remaining arguments, users can do this using one of the following methods:

*   **Interactively** - Terraform will interactively prompt for the required values
*   **File** - a configuration file may be specified using the `init` command line. To specify a file, use the `-backend-config=PATH` option when running `terraform init` 
    *   Secrets files must be downloaded to local disk before running Terraform, this applies to those secrets kept in secure datastores such as Vault
*   **Command-line key/value pairs** - key/value pairs can be specified using the `init` command line. To specify a single key/value pair, use the `-backend-config="KEY=VALUE"` option when running `terraform init` 

When using partial configuration, it is required to specify an empty backend configuration in a Terraform configuration file. This specifies the backend type, such as:

```
terraform {
 backend "artifactory" {}
}
```

An example of passing partial configuration with command-line key/value pairs:

```
terraform init \
   -backend-config="url=https://custom.artifactoryonline.com/artifactory" \
   -backend-config="repo=foo" \
   -backend-config="subpath=terraform_state" \
   -backend-config="username=example" \
   -backend-config="password=P@$$w0rd"
```

However, keep in mind that this is not recommended for secrets because many shells retain command-line flags in a history file.

## State Operations

Terraform updates state automatically during plans and applies. However, it's sometimes necessary to make deliberate adjustments to Terraform's state data, usually to compensate for changes to the configuration or the real managed infrastructure. It is recommended to take extreme caution when manipulating the state. 

Users can manage state operations using the CLI, these commands include:

*   `terraform state list` - shows the resource addresses for every resource Terraform knows about in a configuration
*   `terraform state show` - displays detailed state data about one resource
*   `terraform state mv` - changes which resource address in the configuration is associated with a particular real-world object; this is used to preserve an object when renaming a resource or when moving a resource into or out of a child module
*   `terraform state rm` - tells Terraform to stop managing a resource as part of the current working directory and workspace but does not destroy the corresponding real-world object

As always, take great precaution when manipulating Terraform state.

### Locking

When supported by the backend type (e.g. Azurerm, S3, Consul), Terraform locks the state for all operations that could write state. This prevents others from acquiring the lock and potentially corrupting the state by attempting to write changes. Locking happens automatically on all applicable operations. If state locking fails, Terraform will not continue.

State locking can be disabled for most commands using the `-lock` flag, however, this is not recommended. The `terraform force-unlock` command will manually unlock the state for the defined configuration. While this command does not modify the infrastructure resources, it does remove the lock on the state for the current configuration. Be very careful with this command, unlocking the state when another user holds the lock could cause multiple writers.

```
terraform force-unlock LOCK_ID [DIR]
```

The `force-unlock` command should only be used in the scenario that automatic unlocking failed. As a means of protection, the `force-unlock` command requires a unique `LOCK_ID`. Terraform will output a `LOCK_ID` if automatic unlocking fails.

### Refresh

The `terraform refresh` command is used to reconcile the state Terraform knows about (via its state file) with the real-world infrastructure. This can be used to detect any drift from the last-known state or to update the state file. While this command does not change the infrastructure, the state file is modified. This could cause changes to occur during the next `plan` or `apply` due to the modified state. 

This does not modify infrastructure, but does modify the state file. If the state is changed, this may cause changes to occur during the next plan or apply.

### Push / Pull

The `terraform state push` command is used to manually upload a local state file to remote state. The `terraform state pull` command is used to manually download and output the state from remote state. 

Both commands also work with local state.

## Security

Terraform Cloud always encrypts state at rest and protects it with TLS in transit. Terraform Cloud also knows the identity of the user requesting state and maintains a history of state changes. This is useful for restricting access and tracking activity. Terraform Enterprise also supports detailed audit logging.

The S3 backend supports encryption at rest when the encrypt option is enabled. IAM policies and logging can be used to identify any invalid access. Requests for the state go over a TLS connection.