# 2. Terraform’s Purpose (vs. other IaC)

This section outlines how Terraform simplifies management and orchestration, helping operators build large-scale multi-cloud infrastructures.

## Platform Agnostic

Terraform is cloud-agnostic and allows a single configuration to be used to manage multiple providers and even to handle cross-cloud dependencies. With Terraform, users can manage a heterogeneous environment with the same workflow by creating a configuration file to fit the needs of that platform or project. 

## State Management

Terraform creates a state file (`terraform.tfstate`) when a project is first initialized. This local state is used to create plans and make changes to the infrastructure. 

Prior to any operation, Terraform does a refresh to update the state with the up-to-date infrastructure information. This means that Terraform state is the source of truth by which configuration changes are measured. If a change is made or a resource is appended to a configuration, Terraform compares those changes with the state file to determine what changes result in a new resource or resource modifications.

### Purpose of State

This section outlines the purpose that the state file serves. 

#### Mapping to Real-World Resources

Because functionality and attributes vary per cloud provider, Terraform requires some sort of database to map Terraform configuration to existing resources. Terraform uses its own state structure to map configuration to resources in the real world. 

For example, if a resource `"aws_instance" "example"` exists in the configuration, Terraform uses this map to know that instance `i-abcd1234` is represented by that resource. 

#### Metadata

Terraform builds a graph of the resources and parallelizes creating and modifying any non-dependent resources. Because of this, Terraform builds infrastructure as efficiently as possible, and users get insight into dependencies in their infrastructure.

For example, to delete a resource from a Terraform configuration, Terraform must know how to delete that resource. Terraform can see that a mapping exists for a resource that is no longer in the configuration and plans to destroy. However, since the configuration no longer exists, the order cannot be determined from the configuration alone. To ensure correct operation, Terraform retains a copy of the state's most recent set of dependencies. This way, Terraform can still determine the correct order for destruction from the state when one or more resources are deleted from the configuration.

#### Performance

Terraform stores a cache of the attribute values for all resources in the state. Terraform can query providers and sync the latest attributes from all the resources. This is the default behavior of Terraform: for every plan and apply, Terraform will sync all resources in the state.

For large infrastructures, users might experience rate limiting, so the `-refresh=false` flag as well as the `-target` flag as a workaround. 

#### Syncing

Terraform stores the state in a file in the current working directory where Terraform was run. This is fine for individual use; however, it does not scale when there are multiple users. 

With a fully-featured state backend, Terraform can use remote locking as a measure to avoid two or more different users accidentally running Terraform at the same time, thus ensuring that each Terraform run begins with the most recently updated state.

### Locking

If supported by the backend, Terraform will lock the state for all operations that could write state. This prevents other users from acquiring the lock and potentially corrupting the state.

Terraform has a `force-unlock` command to manually unlock the state if unlocking fails.

### Workspaces

Each Terraform configuration has an associated backend that defines how operations are executed and where persistent data, such as the Terraform state, are stored. The persistent data stored in the backend belongs to a workspace. 

The backend has only one workspace (by default), called "default", and only one Terraform state associated with that configuration. This workspace is unique both because it is the default and also because it cannot ever be deleted. 

Some backends allow for the use of multiple workspaces:

*   To create a workspace, use the command `terraform workspace new`
*   To switch workspaces, use `terraform workspace select`
*   The name of the current workspace can be interpolated using `${terraform.workspace}` formatting

A common use for multiple workspaces is to create a parallel, distinct copy of a set of infrastructure in order to test a set of changes before modifying the main production infrastructure (e.g., dev, staging, prod workspaces within a single module). 

## Operator Confidence

Easily repeatable operations and a planning phase to allow users to ensure the actions taken by Terraform do not cause disruption in their environment. Upon issuing the `terraform apply` command, the user will be prompted to review the proposed changes and must affirm the changes, or else Terraform will not apply the proposed plan. 
